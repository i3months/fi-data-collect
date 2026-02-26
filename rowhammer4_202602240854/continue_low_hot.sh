#!/bin/bash
# Continue Low Voltage Hot Temperature from FFT

set -e

echo "========================================"
echo "Continue: Low Voltage - Hot Temperature"
echo "========================================"
echo ""
echo "Already completed:"
echo "  ✅ Attack_susan"
echo "  ✅ Attack_qsort_large"
echo "  ✅ Attack_bitcount"
echo "  ✅ Attack_dijkstra"
echo "  ✅ Attack_sha"
echo ""
echo "Will collect:"
echo "  - Attack_FFT (9 cycles)"
echo "  - Attack_CRC32 (9 cycles)"
echo "  - Benign 7개 (6 cycles each)"
echo "  - Idle 1개 (6 cycles)"
echo ""
echo "Estimated time: 2 hours"
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

# Create output directory
RESULT_DIR="results_v3"
mkdir -p "$RESULT_DIR/Low_Hot"

echo ""
echo "[*] Results will be saved to:"
echo "    - $RESULT_DIR/Low_Hot/"
echo ""

# Benchmarks
BENCHMARKS=("susan" "qsort_large" "bitcount" "dijkstra" "sha" "FFT" "CRC32")

echo ""
echo "========================================"
echo "Continuing Attack experiments"
echo "========================================"
echo ""

# Attack FFT and CRC32 (remaining)
echo ""
echo "[Attack] FFT (Low Voltage, Hot 80°C)"
python3 collect_cycle.py Attack "FFT" "$RESULT_DIR/Low_Hot/Attack_FFT.csv" --cycles 9 --hot
sleep 30

echo ""
echo "[Attack] CRC32 (Low Voltage, Hot 80°C)"
python3 collect_cycle.py Attack "CRC32" "$RESULT_DIR/Low_Hot/Attack_CRC32.csv" --cycles 9 --hot
sleep 30

echo ""
echo "========================================"
echo "Benign experiments"
echo "========================================"
echo ""

# Benign experiments (6 cycles each)
for bench in "${BENCHMARKS[@]}"; do
    echo ""
    echo "[Benign] $bench (Low Voltage, Hot 80°C)"
    python3 collect_cycle.py Benign "$bench" "$RESULT_DIR/Low_Hot/Benign_${bench}.csv" --cycles 6 --hot
    sleep 30
done

echo ""
echo "========================================"
echo "Idle experiment"
echo "========================================"
echo ""

# Idle experiment (6 cycles)
echo ""
echo "[Idle] (Low Voltage, Hot 80°C)"
python3 collect_cycle.py Idle "None" "$RESULT_DIR/Low_Hot/Idle.csv" --cycles 6 --hot

echo ""
echo "========================================"
echo "Low Voltage Hot Temperature Complete!"
echo "========================================"
echo ""
echo "Collected files:"
ls -lh "$RESULT_DIR/Low_Hot/"
echo ""
echo "Total: 15 CSV files"
echo ""
