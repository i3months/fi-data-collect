#!/bin/bash

# Attack Experiments - Normal Voltage
# 1. Attack + Normal
# 2. Attack + Hot

set -e

echo "========================================"
echo "Attack Experiments (Normal Voltage)"
echo "========================================"
echo ""
echo "This will collect:"
echo "  1. Attack + Normal"
echo "  2. Attack + Hot"
echo ""
echo "Estimated time: 15-20 minutes"
echo ""
read -p "Continue? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    exit 0
fi

RESULT_DIR="results_v2"
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
echo "[1/2] Attack + Normal"
python3 collect_data.py "Attack_Normal" "${RESULT_DIR}/attack_normal.csv"
cooldown 180

echo ""
echo "[2/2] Attack + Hot"
python3 collect_data.py "Attack_Hot" "${RESULT_DIR}/attack_hot.csv" --hot
cooldown 180

echo ""
echo "========================================"
echo "Complete!"
echo "========================================"
ls -lh "$RESULT_DIR"/attack_*.csv
echo ""
for file in "$RESULT_DIR"/attack_*.csv; do
    FLIPS=$(awk -F',' 'NR>1 {sum+=$9} END {print sum}' "$file")
    echo "$(basename $file): $FLIPS flips"
done
echo ""
echo "[+] Attack (Normal Voltage) complete!"
echo "[*] Next: sudo ./run_2_benign_normal.sh"
