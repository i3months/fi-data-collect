#!/bin/bash

# Benign Experiments - Normal Voltage
# 1. Benign + Normal
# 2. Benign + Hot

set -e

echo "========================================"
echo "Benign Experiments (Normal Voltage)"
echo "========================================"
echo ""
echo "This will collect:"
echo "  1. Benign + Normal"
echo "  2. Benign + Hot"
echo ""
echo "Estimated time: 15-20 minutes"
echo ""
read -p "Continue? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    exit 0
fi

RESULT_DIR="results"
mkdir -p "$RESULT_DIR"
echo ""
echo "[*] Results will be saved to: $RESULT_DIR"
echo ""

cooldown() {
    local DURATION=$1
    echo ""
    echo "[*] Cooling down for ${DURATION} seconds..."
    for i in $(seq $DURATION -1 1); do
        TEMP=$(awk '{print $1/1000}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "N/A")
        echo -ne "\r    Remaining: ${i}s | Temp: ${TEMP}°C   "
        sleep 1
    done
    echo ""
}

echo ""
echo "[1/2] Benign + Normal"
python3 collect_benign.py "Benign_Normal" "${RESULT_DIR}/benign_normal.csv"
cooldown 180

echo ""
echo "[2/2] Benign + Hot"
python3 collect_benign.py "Benign_Hot" "${RESULT_DIR}/benign_hot.csv" --hot
cooldown 180

echo ""
echo "========================================"
echo "Complete!"
echo "========================================"
ls -lh "$RESULT_DIR"/benign_*.csv
echo ""
for file in "$RESULT_DIR"/benign_*.csv; do
    FLIPS=$(awk -F',' 'NR>1 {sum+=$9} END {print sum}' "$file")
    echo "$(basename $file): $FLIPS flips"
done
echo ""
echo "[+] Benign (Normal Voltage) complete!"
echo "[*] Next: sudo ./run_3_idle_normal.sh"
