#!/usr/bin/env python3
"""
Cycle-based data collection for RowHammer experiments
Collects data in 20-second cycles with 60-second cooldown between cycles
"""

import subprocess
import time
import csv
import re
import os
import sys
import argparse

# --- Configuration ---
CYCLE_DURATION = 20  # 20 seconds per cycle
COOLDOWN_DURATION = 60  # 60 seconds cooldown between cycles
PERF_EVENTS = "cache-misses,cache-references,page-faults,branch-misses"
TARGET_CORE = "3"

# Temperature threshold for Hot experiments
TEMP_THRESHOLD = 80.0  # Celsius

# Benchmark list
BENCHMARKS = ['susan', 'qsort_large', 'bitcount', 'dijkstra', 'sha', 'FFT', 'CRC32']

def get_env_data():
    """Get temperature and core voltage"""
    try:
        with open("/sys/class/thermal/thermal_zone0/temp", "r") as f:
            temp = float(f.read().strip()) / 1000.0
        v_core = subprocess.check_output(["vcgencmd", "measure_volts", "core"]).decode().strip()
        volt_core = float(re.findall(r"[\d\.]+", v_core)[0])
        return temp, volt_core
    except Exception:
        return 0.0, 0.0

def heat_to_target(target_temp):
    """Heat CPU to target temperature"""
    print(f"[*] Heating CPU to {target_temp}°C...")
    stress_proc = subprocess.Popen(
        ["stress-ng", "--cpu", "4", "--timeout", "10h"],  # Increased to 10 hours
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )
    
    try:
        while True:
            temp, _ = get_env_data()
            if temp >= target_temp:
                print(f"\n[!] Target temperature reached: {temp:.2f}°C")
                print(f"[*] Stabilizing for 60 seconds...")
                for i in range(60, 0, -1):
                    temp_now, _ = get_env_data()
                    print(f"\r    Stabilizing... {i}s | Temp: {temp_now:.2f}°C", end="", flush=True)
                    time.sleep(1)
                print()
                break
            print(f"\r    Current: {temp:.2f}°C / Target: {target_temp}°C", end="", flush=True)
            time.sleep(2)
    finally:
        stress_proc.terminate()
        try:
            stress_proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            stress_proc.kill()

def run_single_cycle(workload, benchmark, cycle_num, is_hot, experiment_start_ns):
    """Run a single 20-second collection cycle"""
    print(f"\n[Cycle {cycle_num}] {workload} + {benchmark}")
    
    # Start MiBench
    mibench_proc = None
    if benchmark != "None":
        print(f"[*] Starting MiBench ({benchmark})...")
        mibench_proc = subprocess.Popen(
            ["./run_mibench_loop.sh", str(CYCLE_DURATION), benchmark],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        time.sleep(1)
    
    # Start workload
    workload_proc = None
    flip_log_file = None
    
    if workload == "Attack":
        flip_log_path = f"flips_temp_{cycle_num}.log"
        flip_log_file = open(flip_log_path, "w")
        workload_cmd = ["sudo", "taskset", "-c", TARGET_CORE, "./rowhammer", str(CYCLE_DURATION), "3", "3"]
        workload_proc = subprocess.Popen(workload_cmd, stdout=flip_log_file, stderr=subprocess.STDOUT, text=True)
    # Benign: MiBench only (no additional workload)
    # Idle: no workload
    
    # Start perf monitoring
    perf_cmd = ["sudo", "perf", "stat", "-a", "-e", PERF_EVENTS, "-I", "100"]
    perf_proc = subprocess.Popen(perf_cmd, stderr=subprocess.PIPE, text=True)
    
    # Collect data for CYCLE_DURATION
    start_time = time.time()
    cycle_start_ns = time.time_ns()
    perf_rows = []
    current_metrics = {}
    last_perf_timestamp = None
    
    print(f"[*] Collecting for {CYCLE_DURATION} seconds...")
    
    try:
        while time.time() - start_time < CYCLE_DURATION:
            line = perf_proc.stderr.readline()
            if not line:
                break
            
            clean_line = line.strip()
            if not clean_line or clean_line.startswith("#"):
                continue
            
            parts = clean_line.split()
            if len(parts) < 3:
                continue
            
            try:
                perf_ts_rel = float(parts[0])
                count_val = 0 if "<" in parts[1] else int(parts[1].replace(',', ''))
                event_name = parts[2]
                
                if last_perf_timestamp is not None and perf_ts_rel != last_perf_timestamp:
                    t_env, v_core = get_env_data()
                    ts_ns = time.time_ns()
                    relative_time_ms = (ts_ns - experiment_start_ns) / 1_000_000
                    cycle_relative_ms = (ts_ns - cycle_start_ns) / 1_000_000
                    
                    perf_rows.append({
                        "Timestamp_ns": ts_ns,
                        "RelativeTime_ms": relative_time_ms,
                        "CycleTime_ms": cycle_relative_ms,
                        "Cycle": cycle_num,
                        "Temp": t_env,
                        "CoreVolt": v_core,
                        "cache-misses": current_metrics.get("cache-misses", 0),
                        "cache-references": current_metrics.get("cache-references", 0),
                        "page-faults": current_metrics.get("page-faults", 0),
                        "branch-misses": current_metrics.get("branch-misses", 0)
                    })
                    
                    current_metrics = {}
                
                current_metrics[event_name] = count_val
                last_perf_timestamp = perf_ts_rel
            
            except (ValueError, IndexError):
                continue
    
    except KeyboardInterrupt:
        print("\n[*] Interrupted!")
    
    finally:
        # Cleanup
        perf_proc.terminate()
        try:
            perf_proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            perf_proc.kill()
        
        if workload_proc:
            workload_proc.terminate()
            try:
                workload_proc.wait(timeout=10)
            except subprocess.TimeoutExpired:
                workload_proc.kill()
        
        if flip_log_file:
            flip_log_file.close()
        
        if mibench_proc:
            mibench_proc.terminate()
            try:
                mibench_proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                mibench_proc.kill()
        
        # Cleanup zombie processes
        # Cleanup all processes
        subprocess.run(["sudo", "pkill", "-9", "rowhammer"], stderr=subprocess.DEVNULL)
        subprocess.run(["sudo", "pkill", "-9", "taskset"], stderr=subprocess.DEVNULL)
        
        # Cleanup all MiBench processes
        subprocess.run(["sudo", "pkill", "-9", "susan"], stderr=subprocess.DEVNULL)
        subprocess.run(["sudo", "pkill", "-9", "qsort_large"], stderr=subprocess.DEVNULL)
        subprocess.run(["sudo", "pkill", "-9", "qsort_small"], stderr=subprocess.DEVNULL)
        subprocess.run(["sudo", "pkill", "-9", "bitcnts"], stderr=subprocess.DEVNULL)
        subprocess.run(["sudo", "pkill", "-9", "dijkstra_small"], stderr=subprocess.DEVNULL)
        subprocess.run(["sudo", "pkill", "-9", "sha"], stderr=subprocess.DEVNULL)
        subprocess.run(["sudo", "pkill", "-9", "fft"], stderr=subprocess.DEVNULL)
        subprocess.run(["sudo", "pkill", "-9", "crc"], stderr=subprocess.DEVNULL)
        
        # Cleanup shell script
        subprocess.run(["sudo", "pkill", "-9", "-f", "run_mibench_loop.sh"], stderr=subprocess.DEVNULL)
    
    # Process flips for Attack
    flip_count = 0
    if workload == "Attack":
        try:
            with open(flip_log_path, "r") as f:
                for line in f:
                    if line.startswith("FLIP,"):
                        flip_count += 1
            os.remove(flip_log_path)
        except FileNotFoundError:
            pass
    
    print(f"[*] Cycle {cycle_num} complete. Collected {len(perf_rows)} samples. Flips: {flip_count}")
    
    return perf_rows, flip_count

def cooldown(duration, is_hot=False, max_temp=55.0):
    """Cooldown between cycles with temperature monitoring"""
    if is_hot:
        # Hot experiments: wait until temp drops below 75°C or minimum 60s
        print(f"\n[*] Cooling down (Hot mode)...")
        min_duration = duration
        elapsed = 0
        
        for i in range(min_duration, 0, -1):
            temp, _ = get_env_data()
            print(f"\r    Remaining: {i}s | Temp: {temp:.2f}°C   ", end="", flush=True)
            time.sleep(1)
            elapsed += 1
        
        # Continue cooling if still above 75°C
        while True:
            temp, _ = get_env_data()
            if temp < 75.0:
                print(f"\n[+] Temperature OK: {temp:.2f}°C < 75°C")
                break
            if elapsed > 300:  # Max 5 minutes total
                print(f"\n[!] WARNING: Cooldown timeout. Current temp: {temp:.2f}°C")
                break
            print(f"\r    Extended cooling... {elapsed}s | Temp: {temp:.2f}°C (waiting for < 75°C)   ", end="", flush=True)
            time.sleep(1)
            elapsed += 1
        print()
    else:
        # Normal Temp experiments: wait until temp drops below max_temp
        print(f"\n[*] Cooling down until temp < {max_temp}°C...")
        elapsed = 0
        while True:
            temp, _ = get_env_data()
            if temp < max_temp:
                print(f"\n[+] Temperature OK: {temp:.2f}°C < {max_temp}°C")
                break
            print(f"\r    Elapsed: {elapsed}s | Temp: {temp:.2f}°C (waiting for < {max_temp}°C)   ", end="", flush=True)
            time.sleep(1)
            elapsed += 1
            
            # Safety: max 5 minutes
            if elapsed > 300:
                print(f"\n[!] WARNING: Cooldown timeout (5 min). Current temp: {temp:.2f}°C")
                break
        print()

def collect_experiment(workload, benchmark, output_file, num_cycles, is_hot=False):
    """Collect data for one experiment (multiple cycles)"""
    print(f"\n{'='*60}")
    print(f"Experiment: {workload} + {benchmark}")
    print(f"Cycles: {num_cycles} × {CYCLE_DURATION}s")
    print(f"Hot mode: {is_hot}")
    print(f"Output: {output_file}")
    print(f"{'='*60}\n")
    
    # Experiment start time for relative timestamps
    experiment_start_ns = time.time_ns()
    
    # Heat if needed
    if is_hot:
        heat_to_target(TEMP_THRESHOLD)
    
    # Collect cycles
    all_rows = []
    cycle_flips = {}  # Track flips per cycle
    label = f"{workload}_{benchmark}" if benchmark != "None" else workload
    
    # Initialize CSV file with header
    with open(output_file, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["Timestamp_ns", "RelativeTime_ms", "CycleTime_ms", "Label", "Benchmark", 
                        "Cycle", "Temp", "CoreVolt", 
                        "CacheMiss", "CacheRef", "PageFault", "BranchMiss", "FlipCount"])
    
    for cycle in range(1, num_cycles + 1):
        # Heat to target temperature before each cycle if in hot mode
        if is_hot:
            heat_to_target(TEMP_THRESHOLD)
        
        rows, flips = run_single_cycle(workload, benchmark, cycle, is_hot, experiment_start_ns)
        cycle_flips[cycle] = flips
        all_rows.extend(rows)
        
        # SAVE IMMEDIATELY after each cycle (append mode)
        with open(output_file, "a", newline="") as f:
            writer = csv.writer(f)
            for row in rows:
                writer.writerow([
                    row["Timestamp_ns"],
                    row["RelativeTime_ms"],
                    row["CycleTime_ms"],
                    label,
                    benchmark,
                    cycle,
                    row["Temp"],
                    row["CoreVolt"],
                    row["cache-misses"],
                    row["cache-references"],
                    row["page-faults"],
                    row["branch-misses"],
                    flips if workload == "Attack" else 0
                ])
        
        print(f"[+] Cycle {cycle} data saved to {output_file}")
        
        if cycle < num_cycles:
            cooldown(COOLDOWN_DURATION, is_hot=is_hot, max_temp=55.0)
    
    total_flips = sum(cycle_flips.values())
    print(f"\n[+] Experiment complete!")
    print(f"    Total samples: {len(all_rows)}")
    print(f"    Total flips: {total_flips}")
    if workload == "Attack":
        print(f"    Flips per cycle: {cycle_flips}")
    print(f"    Saved to: {output_file}\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Cycle-based RowHammer data collector")
    parser.add_argument("workload", choices=["Attack", "Benign", "Idle"], help="Workload type")
    parser.add_argument("benchmark", help="Benchmark name (or 'None' for Idle)")
    parser.add_argument("output", help="Output CSV file")
    parser.add_argument("--cycles", type=int, help="Number of cycles (default: 9 for Attack, 6 for others)")
    parser.add_argument("--hot", action="store_true", help="Heat to 80C before starting")
    
    args = parser.parse_args()
    
    # Determine number of cycles
    if args.cycles:
        num_cycles = args.cycles
    else:
        num_cycles = 9 if args.workload == "Attack" else 6
    
    collect_experiment(args.workload, args.benchmark, args.output, num_cycles, args.hot)
