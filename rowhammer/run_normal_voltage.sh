#!/bin/bash
# Run all experiments with Normal Voltage (0, 1.25V)
# Collects 30 CSV files: 15 for Normal Temp + 15 for Hot Temp

set -e

echo "========================================"
echo "RowHammer Experiments - Normal Voltage"
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
echo ""
echo "[*] Current voltage setting: over_voltage=$VOLTAGE"
if [[ "$VOLTAGE" != "0" ]]; then
    echo "[!] WARNING: Expected over_voltage=0 for Normal Voltage experiments"
    read -p "Continue anyway? (y/N): " CONFIRM2
    if [[ "$CONFIRM2" != "y" ]]; then
        exit 0
    fi
fi

# Create output directories
RESULT_DIR="results_v3"
mkdir -p "$RESULT_DIR/Normal_Normal"
mkdir -p "$RESULT_DIR/Normal_Hot"

echo ""
echo "[*] Results will be saved to:"
echo "    - $RESULT_DIR/Normal_Normal/ (Normal Temp)"
echo "    - $RESULT_DIR/Normal_Hot/ (Hot Temp)"
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
    python3 collect_cycle.py Attack "$bench" "$RESULT_DIR/Normal_Normal/Attack_${bench}.csv" --cycles 9
    sleep 30
done

# Benign experiments (6 cycles each)
for bench in "${BENCHMARKS[@]}"; do
    echo ""
    echo "[Benign] $bench (Normal Temp)"
    python3 collect_cycle.py Benign "$bench" "$RESULT_DIR/Normal_Normal/Benign_${bench}.csv" --cycles 6
    sleep 30
done

# Idle experiment (6 cycles)
echo ""
echo "[Idle] (Normal Temp)"
python3 collect_cycle.py Idle "None" "$RESULT_DIR/Normal_Normal/Idle.csv" --cycles 6

echo ""
echo "[+] Normal Temperature experiments complete!"
echo ""
ls -lh "$RESULT_DIR/Normal_Normal/"
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
    python3 collect_cycle.py Attack "$bench" "$RESULT_DIR/Normal_Hot/Attack_${bench}.csv" --cycles 9 --hot
    sleep 30
done

# Benign experiments (6 cycles each)
for bench in "${BENCHMARKS[@]}"; do
    echo ""
    echo "[Benign] $bench (Hot Temp)"
    python3 collect_cycle.py Benign "$bench" "$RESULT_DIR/Normal_Hot/Benign_${bench}.csv" --cycles 6 --hot
    sleep 30
done

# Idle experiment (6 cycles)
echo ""
echo "[Idle] (Hot Temp)"
python3 collect_cycle.py Idle "None" "$RESULT_DIR/Normal_Hot/Idle.csv" --cycles 6 --hot

echo ""
echo "========================================"
echo "Normal Voltage Experiments Complete!"
echo "========================================"
echo ""
echo "Collected files:"
ls -lh "$RESULT_DIR/Normal_Normal/"
echo ""
ls -lh "$RESULT_DIR/Normal_Hot/"
echo ""
echo "Total: 30 CSV files"
echo ""
echo "Next steps:"
echo "  1. Change voltage: ./set_voltage.sh (enter -6)"
echo "  2. Reboot: sudo reboot"
echo "  3. Run: ./run_low_voltage.sh"
echo ""
