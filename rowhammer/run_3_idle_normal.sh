#!/bin/bash

# Idle Experiments - Normal Voltage
# 1. Idle + Normal
# 2. Idle + Hot

set -e

echo "========================================"
echo "Idle Experiments (Normal Voltage)"
echo "========================================"
echo ""
echo "This will collect:"
echo "  1. Idle + Normal"
echo "  2. Idle + Hot"
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
echo "[1/2] Idle + Normal"
python3 collect_idle.py "Idle_Normal" "${RESULT_DIR}/idle_normal.csv"
cooldown 180

echo ""
echo "[2/2] Idle + Hot"
python3 collect_idle.py "Idle_Hot" "${RESULT_DIR}/idle_hot.csv" --hot
cooldown 180

echo ""
echo "========================================"
echo "Complete!"
echo "========================================"
ls -lh "$RESULT_DIR"/idle_*.csv
echo ""
for file in "$RESULT_DIR"/idle_*.csv; do
    FLIPS=$(awk -F',' 'NR>1 {sum+=$9} END {print sum}' "$file")
    echo "$(basename $file): $FLIPS flips"
done
echo ""
echo "[+] Idle (Normal Voltage) complete!"
echo ""
echo "========================================"
echo "Normal Voltage Experiments Done!"
echo "========================================"
echo ""
echo "Next: Low Voltage Experiments"
echo "  1. sudo ./set_voltage.sh (enter -2)"
echo "  2. sudo reboot"
echo "  3. sudo ./run_4_attack_lowvolt.sh"
