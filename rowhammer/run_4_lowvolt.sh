#!/bin/bash

# STEP 4: Low Voltage Experiments (Optional)
# - LowVolt + Attack
# - LowVolt + Benign

set -e

echo "========================================"
echo "STEP 4: Low Voltage Experiments"
echo "========================================"
echo ""

# 전압 확인
CURRENT_VOLT=$(vcgencmd measure_volts core)
OVER_VOLT=$(vcgencmd get_config over_voltage)
echo "[*] Current voltage: $CURRENT_VOLT"
echo "[*] over_voltage setting: $OVER_VOLT"
echo ""

# 저전압 확인
VOLT_NUM=$(echo "$OVER_VOLT" | grep -oP '(?<=over_voltage=)-?\d+' || echo "0")
if [ "$VOLT_NUM" -ge 0 ]; then
    echo "[!] WARNING: System is NOT in low voltage mode!"
    echo "[!] Current over_voltage = $VOLT_NUM (should be negative)"
    echo ""
    echo "Please set low voltage first:"
    echo "  1. sudo ./set_voltage.sh"
    echo "  2. Enter -2 (RPi 4) or -4 (RPi Zero 2)"
    echo "  3. Reboot"
    echo "  4. Run this script again"
    echo ""
    exit 1
fi

echo "This will run:"
echo "  1. LowVolt + Attack"
echo "  2. LowVolt + Benign"
echo ""
echo "Estimated time: 5-10 minutes"
echo ""
read -p "Continue? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    exit 0
fi

# 결과 디렉토리
RESULT_DIR="lowvolt_results"
mkdir -p "$RESULT_DIR"
echo ""
echo "[*] Results will be saved to: $RESULT_DIR"
echo ""

# 쿨다운 함수
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

# LowVolt + Attack
echo ""
echo "[1/2] LowVolt + Attack"
python3 collect_data.py "LowVolt_Attack" "${RESULT_DIR}/lowvolt_attack.csv"
cooldown 180

# LowVolt + Benign
echo ""
echo "[2/2] LowVolt + Benign"
python3 collect_benign.py "LowVolt_Benign" "${RESULT_DIR}/lowvolt_benign.csv"

# 완료
echo ""
echo "========================================"
echo "Low Voltage Experiments Complete!"
echo "========================================"
echo ""
ls -lh "$RESULT_DIR"/*.csv
echo ""
for file in "$RESULT_DIR"/*.csv; do
    FLIPS=$(awk -F',' 'NR>1 {sum+=$9} END {print sum}' "$file")
    echo "$(basename $file): $FLIPS flips"
done
echo ""
echo "[+] Step 4 complete!"
echo ""
echo "To restore normal voltage:"
echo "  1. sudo ./set_voltage.sh"
echo "  2. Enter 0"
echo "  3. Reboot"
