#!/bin/bash

# Attack Experiments - Low Voltage
# 1. Attack + LowVolt
# 2. Attack + Hot + LowVolt

set -e

echo "========================================"
echo "Attack Experiments (Low Voltage)"
echo "========================================"
echo ""

# 전압 확인
CURRENT_VOLT=$(vcgencmd measure_volts core)
OVER_VOLT=$(vcgencmd get_config over_voltage)
echo "[*] Current voltage: $CURRENT_VOLT"
echo "[*] over_voltage setting: $OVER_VOLT"
echo ""

VOLT_NUM=$(echo "$OVER_VOLT" | grep -oP '(?<=over_voltage=)-?\d+' || echo "0")
if [ "$VOLT_NUM" -ge 0 ]; then
    echo "[!] WARNING: System is NOT in low voltage mode!"
    echo "[!] Please set low voltage first:"
    echo "  1. sudo ./set_voltage.sh (enter -2)"
    echo "  2. sudo reboot"
    echo "  3. Run this script again"
    echo ""
    exit 1
fi

echo "This will collect:"
echo "  1. Attack + LowVolt"
echo "  2. Attack + Hot + LowVolt"
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
        VOLT=$(vcgencmd measure_volts core 2>/dev/null || echo "N/A")
        echo -ne "\r    Remaining: ${i}s | Temp: ${TEMP}°C | Volt: ${VOLT}   "
        sleep 1
    done
    echo ""
}

echo ""
echo "[1/2] Attack + LowVolt"
python3 collect_data.py "Attack_LowVolt" "${RESULT_DIR}/attack_lowvolt.csv"
cooldown 180

echo ""
echo "[2/2] Attack + Hot + LowVolt"
python3 collect_data.py "Attack_Hot_LowVolt" "${RESULT_DIR}/attack_hot_lowvolt.csv" --hot
cooldown 180

echo ""
echo "========================================"
echo "Complete!"
echo "========================================"
ls -lh "$RESULT_DIR"/attack_*lowvolt.csv
echo ""
for file in "$RESULT_DIR"/attack_*lowvolt.csv; do
    FLIPS=$(awk -F',' 'NR>1 {sum+=$9} END {print sum}' "$file")
    echo "$(basename $file): $FLIPS flips"
done
echo ""
echo "[+] Attack (Low Voltage) complete!"
echo "[*] Next: sudo ./run_5_benign_lowvolt.sh"
