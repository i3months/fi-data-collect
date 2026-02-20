import subprocess
import time
import csv
import re
import os
import sys

# --- 설정 ---
DURATION = 90  # 수집 시간 (초) - Attack은 더 많은 데이터 필요
TARGET_CORE = "3"
# perf output에 나오는 이름과 정확히 일치해야 매핑됩니다.
PERF_EVENTS = "cache-misses,cache-references,page-faults,branch-misses"

# RowHammer 설정 (기본값)
ATTACK_MODE = "3"  # 3: DC ZVA

# 가열 설정
TEMP_THRESHOLD = 80.0  # 가열 목표 온도 (Celsius)

def get_env_data():
    """온도와 CPU 코어 전압을 측정하는 함수"""
    try:
        # 온도 측정: /sys/class/thermal/thermal_zone0/temp (millicelsius -> celsius)
        with open("/sys/class/thermal/thermal_zone0/temp", "r") as f:
            temp = float(f.read().strip()) / 1000.0
            
        # 전압 측정 (Core Voltage)
        v_core = subprocess.check_output(["vcgencmd", "measure_volts", "core"]).decode().strip()
        volt_core = float(re.findall(r"[\d\.]+", v_core)[0])
        return temp, volt_core
    except Exception:
        return 0.0, 0.0

def run_collection(label, output_file, is_hot=False, attack_type="3"):
    stress_proc = None
    
    # 1. 고온 환경 조성 (Hot 옵션 시)
    if is_hot:
        print(f"[*] Hot mode enabled. Heating up CPU to {TEMP_THRESHOLD}°C...")
        stress_proc = subprocess.Popen(
            ["stress-ng", "--cpu", "4", "--timeout", "2h"], 
            stdout=subprocess.DEVNULL, 
            stderr=subprocess.DEVNULL
        )
        try:
            while True:
                temp, _ = get_env_data()
                if temp >= TEMP_THRESHOLD:
                    print(f"\n[!] Target temperature reached: {temp:.2f}°C")
                    print(f"[*] Waiting additional 60 seconds to stabilize temperature...")
                    # 온도 안정화 대기 (60초)
                    for i in range(60, 0, -1):
                        temp_now, _ = get_env_data()
                        print(f"\r    Stabilizing... {i}s remaining | Current: {temp_now:.2f}°C", end="", flush=True)
                        time.sleep(1)
                    print()
                    break
                print(f"\r    Current Temp: {temp:.2f}°C / Target: {TEMP_THRESHOLD}°C", end="", flush=True)
                time.sleep(2)
        except KeyboardInterrupt:
            print("\n[-] Heating cancelled.")
            stress_proc.terminate()
            return

    print(f"[*] Starting Data Collection: {label}")
    print(f"[*] Monitoring ALL CPUs for {DURATION} seconds...")
    print(f"[*] Attack Config: Mode {ATTACK_MODE}, Type {attack_type}")
    
    # MiBench 백그라운드 실행 (현실적인 노이즈 추가)
    print(f"[*] Starting MiBench (susan) in background (realistic workload)...")
    mibench_proc = subprocess.Popen(
        ["./run_mibench_loop.sh", str(DURATION), "susan"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )
    time.sleep(1)  # MiBench 시작 대기
    
    # 공격 결과를 저장할 임시 로그 파일 (버퍼링 문제 해결을 위해 파이프 대신 파일 사용)
    flip_log_path = f"flips_{label}.log"
    flip_log_file = open(flip_log_path, "w")

    # 1. RowHammer 공격 코드 실행 (결과를 파일로 직접 리다이렉션)
    attacker_cmd = [
        "sudo", "taskset", "-c", TARGET_CORE,
        "./rowhammer", str(DURATION), ATTACK_MODE, str(attack_type)
    ]
    attacker = subprocess.Popen(attacker_cmd, stdout=flip_log_file, stderr=subprocess.STDOUT, text=True)

    # 2. Perf 명령어 실행 (-I 100: 100ms 간격)
    # -a: 전체 시스템 모니터링 (Core 3만이 아닌 모든 메모리 접근 포함)
    perf_cmd = [
        "sudo", "perf", "stat",
        "-a",  # All CPUs
        "-e", PERF_EVENTS,
        "-I", "100"
    ]
    process = subprocess.Popen(perf_cmd, stderr=subprocess.PIPE, text=True)
    
    start_time = time.time()
    perf_rows = [] # 실시간 데이터를 임시 저장할 버퍼
    current_metrics = {}
    last_perf_timestamp = None

    print("[*] Collecting hardware metrics...")
    try:
        # 실험 시간 동안 대기하며 Perf 지표 수집
        while time.time() - start_time < DURATION + 2: # RowHammer보다 약간 더 길게 수집
            line = process.stderr.readline()
            if not line: break

            clean_line = line.strip()
            if not clean_line or clean_line.startswith("#"):
                continue

            parts = clean_line.split()
            if len(parts) < 3: continue

            try:
                perf_ts_rel = float(parts[0])
                count_val = 0 if "<" in parts[1] else int(parts[1].replace(',', ''))
                event_name = parts[2]

                if last_perf_timestamp is not None and perf_ts_rel != last_perf_timestamp:
                    t_env, v_core = get_env_data()
                    ts_ns = time.time_ns()
                    
                    perf_rows.append({
                        "Timestamp_ns": ts_ns,
                        "Label": label,
                        "Temp": t_env,
                        "CoreVolt": v_core,
                        "cache-misses": current_metrics.get("cache-misses", 0),
                        "cache-references": current_metrics.get("cache-references", 0),
                        "page-faults": current_metrics.get("page-faults", 0),
                        "branch-misses": current_metrics.get("branch-misses", 0)
                    })
                    
                    if int(perf_ts_rel * 10) % 10 == 0:
                        print(f"\r[{label}] {ts_ns} | Temp: {t_env:.2f}°C | Volt: {v_core:.4f}V | Elapsed: {int(perf_ts_rel)}s", end="", flush=True)

                    current_metrics = {}

                current_metrics[event_name] = count_val
                last_perf_timestamp = perf_ts_rel

            except (ValueError, IndexError):
                continue

    except KeyboardInterrupt:
        print("\n[*] Stopping collection...")
    finally:
        print("\n[*] Finalizing processes and cleaning up...")
        
        # Perf 종료
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
        
        # RowHammer 프로세스 종료 (좀비 방지)
        try:
            attacker.terminate()
            attacker.wait(timeout=10)
        except subprocess.TimeoutExpired:
            print("[!] RowHammer process timeout, force killing...")
            attacker.kill()
            attacker.wait()
        
        flip_log_file.flush()
        flip_log_file.close()
        
        # Stress 종료
        if stress_proc:
            stress_proc.terminate()
            try:
                stress_proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                stress_proc.kill()
        
        # MiBench 종료
        if mibench_proc:
            mibench_proc.terminate()
            try:
                mibench_proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                mibench_proc.kill()
        
        # 좀비 프로세스 정리
        subprocess.run(["sudo", "pkill", "-9", "rowhammer"], stderr=subprocess.DEVNULL)
        subprocess.run(["sudo", "pkill", "-9", "taskset"], stderr=subprocess.DEVNULL)
        subprocess.run(["sudo", "pkill", "-9", "susan"], stderr=subprocess.DEVNULL)

        # 3. 저장된 플립 로그 파일 다시 읽기 및 병합
        print(f"[*] Processing flips from {flip_log_path}...")
        flip_timestamps = []
        try:
            with open(flip_log_path, "r") as log_r:
                for line in log_r:
                    if line.startswith("FLIP,"):
                        try:
                            ts_flip = int(line.split(',')[1])
                            flip_timestamps.append(ts_flip)
                        except (ValueError, IndexError):
                            continue
        except FileNotFoundError:
            print(f"[!] Log file {flip_log_path} not found.")

        print(f"[*] Total Flips detected: {len(flip_timestamps)}. Merging with metrics...")
        flip_timestamps.sort()

        # 4. 데이터 병합 및 CSV 작성
        file_exists = os.path.isfile(output_file)
        with open(output_file, "a", newline="") as f:
            writer = csv.writer(f)
            if not file_exists:
                writer.writerow(["Timestamp_ns", "Label", "Temp", "CoreVolt", "CacheMiss", "CacheRef", "PageFault", "BranchMiss", "FlipCount"])
            
            last_ts = 0
            for row in perf_rows:
                curr_ts = row["Timestamp_ns"]
                # 인터벌 설정: (last_ts < flip_ts <= curr_ts)
                interval_start = last_ts if last_ts != 0 else curr_ts - 100_000_000
                
                # 효율적인 카운팅을 위한 필터링 (이미 정렬됨)
                flips_in_interval = 0
                # 이 방식은 플립이 아주 많을 때 최적화가 필요할 수 있으나, 10만개 정도는 무난함
                flips_in_interval = sum(1 for ts in flip_timestamps if interval_start < ts <= curr_ts)
                
                writer.writerow([
                    curr_ts,
                    row["Label"],
                    row["Temp"],
                    row["CoreVolt"],
                    row["cache-misses"],
                    row["cache-references"],
                    row["page-faults"],
                    row["branch-misses"],
                    flips_in_interval
                ])
                last_ts = curr_ts
                
        print(f"[*] Merging complete. Result saved to {output_file}")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="RowHammer Data Collector")
    parser.add_argument("label", help="Label for the experiment (e.g., Benign, Normal, HighTemp)")
    parser.add_argument("output", nargs="?", help="Output CSV file path")
    parser.add_argument("--hot", action="store_true", help="Heat up CPU before starting")
    parser.add_argument("--type", default="3", help="RowHammer attack type (default: 3 for Half-Double)")
    
    args = parser.parse_args()
    
    out_file = args.output if args.output else f"experiment_data_{args.label}.csv"
    run_collection(args.label, out_file, is_hot=args.hot, attack_type=args.type)
