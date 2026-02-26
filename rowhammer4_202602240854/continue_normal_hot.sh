#!/bin/bash
# Continue Normal Voltage Hot Temperature experiments

set -e

echo "========================================"
echo "Continue: Normal Voltage - Hot Temperature"
echo "========================================"
echo ""
echo "Already completed:"
echo "  ✅ Attack_susan"
echo "  ✅ Attack_qsort_large"
echo "  ✅ Attack_bitcount"
echo "  ✅ Attack_dijkstra"
echo "  ✅ Attack_sha"
echo "  ✅ Attack_FFT"
echo "  ✅ Attack_CRC32"
echo "  ✅ Benign_bitcount"
echo "  ✅ Benign_qsort_large"
echo "  ✅ Benign_susan"
echo ""
echo "Will collect:"
echo "  - Benign_CRC32 (6 cycles)"
echo "  - Benign_dijkstra (6 cycles)"
echo "  - Benign_FFT (6 cycles)"
echo "  - Benign_sha (6 cycles)"
echo "  - Idle (6 cycles)"
echo ""
echo "Estimated time: 45 minutes"
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
mkdir -p "$RESULT_DIR/Normal_Hot"

echo ""
echo "[*] Results will be saved to:"
echo "    - $RESULT_DIR/Normal_Hot/"
echo ""

# Remaining benchmarks for Benign
REMAINING_BENIGN=("CRC32" "dijkstra" "FFT" "sha")

echo ""
echo "========================================"
echo "Continuing Benign experiments"
echo "========================================"
echo ""

# Benign experiments (6 cycles each)
for bench in "${REMAINING_BENIGN[@]}"; do
    echo ""
    echo "[Benign] $bench (Normal Voltage, Hot 80°C)"
    python3 collect_cycle.py Benign "$bench" "$RESULT_DIR/Normal_Hot/Benign_${bench}.csv" --cycles 6 --hot
    sleep 30
done

echo ""
echo "========================================"
echo "Idle experiment"
echo "========================================"
echo ""

# Idle experiment (6 cycles)
echo ""
echo "[Idle] (Normal Voltage, Hot 80°C)"
python3 collect_cycle.py Idle "None" "$RESULT_DIR/Normal_Hot/Idle.csv" --cycles 6 --hot

echo ""
echo "========================================"
echo "Normal Voltage Hot Temperature Complete!"
echo "========================================"
echo ""
echo "Collected files:"
ls -lh "$RESULT_DIR/Normal_Hot/"
echo ""
echo "Total: 15 CSV files"
echo ""
