import subprocess
import time
import csv
import re
import os
import sys

# --- 설정 ---
DURATION = 60  # 수집 시간 (초)
TARGET_CORE = "3"
PERF_EVENTS = "cache-misses,cache-references,page-faults,branch-misses"

# 가열 설정
TEMP_THRESHOLD = 80.0  # 가열 목표 온도 (Celsius)

def get_env_data():
    """온도와 CPU 코어 전압을 측정하는 함수"""
    try:
        # 온도 측정
        with open("/sys/class/thermal/thermal_zone0/temp", "r") as f:
            temp = float(f.read().strip()) / 1000.0
            
        # 전압 측정
        v_core = subprocess.check_output(["vcgencmd", "measure_volts", "core"]).decode().strip()
        volt_core = float(re.findall(r"[\d\.]+", v_core)[0])
        return temp, volt_core
    except Exception:
        return 0.0, 0.0

def run_benign_collection(label, output_file, is_hot=False):
    """Benign 워크로드 (RowHammer 공격 없이 메모리 집약적 작업만 수행)"""
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

    print(f"[*] Starting Benign Data Collection: {label}")
    print(f"[*] Monitoring Core {TARGET_CORE} for {DURATION} seconds...")
    print(f"[*] Running memory-intensive workload WITHOUT RowHammer attack")
    
    # 2. Benign 메모리 워크로드 실행 (커스텀 C 프로그램 사용)
    # RowHammer와 유사한 메모리 접근 패턴이지만 공격은 하지 않음
    benign_cmd = [
        "sudo", "taskset", "-c", TARGET_CORE,
        "./benign_workload", str(DURATION)
    ]
    benign_proc = subprocess.Popen(
        benign_cmd, 
        stdout=subprocess.PIPE, 
        stderr=subprocess.STDOUT,
        text=True
    )

    # 3. Perf 명령어 실행 (-I 100: 100ms 간격)
    perf_cmd = [
        "sudo", "perf", "stat",
        "-C", TARGET_CORE,
        "-e", PERF_EVENTS,
        "-I", "100"
    ]
    process = subprocess.Popen(perf_cmd, stderr=subprocess.PIPE, text=True)
    
    start_time = time.time()
    perf_rows = []
    current_metrics = {}
    last_perf_timestamp = None

    print("[*] Collecting hardware metrics...")
    try:
        while time.time() - start_time < DURATION + 2:
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
        print("\n[*] Finalizing processes...")
        process.terminate()
        benign_proc.terminate()
        benign_proc.wait()

        if stress_proc:
            stress_proc.terminate()
            stress_proc.wait()

        # 4. CSV 작성 (FlipCount는 항상 0)
        file_exists = os.path.isfile(output_file)
        with open(output_file, "a", newline="") as f:
            writer = csv.writer(f)
            if not file_exists:
                writer.writerow(["Timestamp_ns", "Label", "Temp", "CoreVolt", "CacheMiss", "CacheRef", "PageFault", "BranchMiss", "FlipCount"])
            
            for row in perf_rows:
                writer.writerow([
                    row["Timestamp_ns"],
                    row["Label"],
                    row["Temp"],
                    row["CoreVolt"],
                    row["cache-misses"],
                    row["cache-references"],
                    row["page-faults"],
                    row["branch-misses"],
                    0  # Benign 워크로드이므로 FlipCount는 0
                ])
                
        print(f"[*] Collection complete. Result saved to {output_file}")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Benign Workload Data Collector (No RowHammer)")
    parser.add_argument("label", help="Label for the experiment (e.g., Benign_Normal, Benign_Hot)")
    parser.add_argument("output", nargs="?", help="Output CSV file path")
    parser.add_argument("--hot", action="store_true", help="Heat up CPU before starting")
    
    args = parser.parse_args()
    
    out_file = args.output if args.output else f"benign_{args.label}.csv"
    run_benign_collection(args.label, out_file, is_hot=args.hot)
