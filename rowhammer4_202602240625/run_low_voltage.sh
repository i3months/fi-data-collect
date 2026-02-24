#!/bin/bash
# Run all experiments with Low Voltage (-6, 1.10V)
# Collects 30 CSV files: 15 for Normal Temp + 15 for Hot Temp

set -e

echo "========================================"
echo "RowHammer Experiments - Low Voltage"
echo "========================================"
echo ""
echo "This will collect 30 CSV files:"
echo "  - Normal Temp: 15 files (7 Attack + 7 Benign + 1 Idle)"
echo "  - Hot Temp: 15 files (7 Attack + 7 Benign + 1 Idle)"
echo ""
echo "Estimated time: 4-6 hours"
echo ""
echo "Benchmarks: susan, qsort_large, bitcount, dijkstra, sha, FFT, CRC32"
echo ""
read -p "Continue? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    exit 0
fi

# Check voltage
VOLTAGE=$(vcgencmd get_config over_voltage | cut -d= -f2)
MEASURED=$(vcgencmd measure_volts core)
echo ""
echo "[*] Current voltage setting: over_voltage=$VOLTAGE"
echo "[*] Measured voltage: $MEASURED"
if [[ "$VOLTAGE" != "-6" ]]; then
    echo "[!] WARNING: Expected over_voltage=-6 for Low Voltage experiments"
    echo "[!] Current setting: over_voltage=$VOLTAGE"
    read -p "Continue anyway? (y/N): " CONFIRM2
    if [[ "$CONFIRM2" != "y" ]]; then
        exit 0
    fi
fi

# Create output directories
RESULT_DIR="results_v3"
mkdir -p "$RESULT_DIR/Low_Normal"
mkdir -p "$RESULT_DIR/Low_Hot"

echo ""
echo "[*] Results will be saved to:"
echo "    - $RESULT_DIR/Low_Normal/ (Normal Temp)"
echo "    - $RESULT_DIR/Low_Hot/ (Hot Temp)"
echo ""

# Benchmarks
BENCHMARKS=("susan" "qsort_large" "bitcount" "dijkstra" "sha" "FFT" "CRC32")

# ============================================
# Part 1: Normal Temperature
# ============================================
echo ""
echo "========================================"
echo "Part 1: Normal Temperature (40-50°C)"
echo "========================================"
echo ""

# Attack experiments (9 cycles each)
for bench in "${BENCHMARKS[@]}"; do
    echo ""
    echo "[Attack] $bench (Normal Temp)"
    python3 collect_cycle.py Attack "$bench" "$RESULT_DIR/Low_Normal/Attack_${bench}.csv" --cycles 9
    sleep 30
done

# Benign experiments (6 cycles each)
for bench in "${BENCHMARKS[@]}"; do
    echo ""
    echo "[Benign] $bench (Normal Temp)"
    python3 collect_cycle.py Benign "$bench" "$RESULT_DIR/Low_Normal/Benign_${bench}.csv" --cycles 6
    sleep 30
done

# Idle experiment (6 cycles)
echo ""
echo "[Idle] (Normal Temp)"
python3 collect_cycle.py Idle "None" "$RESULT_DIR/Low_Normal/Idle.csv" --cycles 6

echo ""
echo "[+] Normal Temperature experiments complete!"
echo ""
ls -lh "$RESULT_DIR/Low_Normal/"
echo ""

# ============================================
# Part 2: Hot Temperature
# ============================================
echo ""
echo "========================================"
echo "Part 2: Hot Temperature (80°C)"
echo "========================================"
echo ""

# Attack experiments (9 cycles each)
for bench in "${BENCHMARKS[@]}"; do
    echo ""
    echo "[Attack] $bench (Hot Temp)"
    python3 collect_cycle.py Attack "$bench" "$RESULT_DIR/Low_Hot/Attack_${bench}.csv" --cycles 9 --hot
    sleep 30
done

# Benign experiments (6 cycles each)
for bench in "${BENCHMARKS[@]}"; do
    echo ""
    echo "[Benign] $bench (Hot Temp)"
    python3 collect_cycle.py Benign "$bench" "$RESULT_DIR/Low_Hot/Benign_${bench}.csv" --cycles 6 --hot
    sleep 30
done

# Idle experiment (6 cycles)
echo ""
echo "[Idle] (Hot Temp)"
python3 collect_cycle.py Idle "None" "$RESULT_DIR/Low_Hot/Idle.csv" --cycles 6 --hot

echo ""
echo "========================================"
echo "Low Voltage Experiments Complete!"
echo "========================================"
echo ""
echo "Collected files:"
ls -lh "$RESULT_DIR/Low_Normal/"
echo ""
ls -lh "$RESULT_DIR/Low_Hot/"
echo ""
echo "Total: 30 CSV files"
echo ""
echo "All experiments complete!"
echo "Total collected: 60 CSV files in results_v3/"
echo ""
