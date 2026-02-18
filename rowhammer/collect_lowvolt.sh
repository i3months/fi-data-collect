#!/bin/bash

# 저전압 데이터 수집 스크립트
# 사용법: sudo ./collect_lowvolt.sh

set -e

DURATION=60
TARGET_CORE="3"
ATTACK_MODE="3"
ATTACK_TYPE="3"

echo "========================================"
echo "Low Voltage Data Collection"
echo "========================================"
echo ""

# 1. 전압 확인
CURRENT_VOLT=$(vcgencmd measure_volts core)
OVER_VOLT=$(vcgencmd get_config over_voltage)
echo "[*] Current voltage: $CURRENT_VOLT"
echo "[*] over_voltage setting: $OVER_VOLT"
echo ""

# 2. rowhammer 실행 파일 확인
if [ ! -f "./rowhammer" ]; then
    echo "[-] rowhammer executable not found. Compiling..."
    make clean
    make
fi

if [ ! -x "./rowhammer" ]; then
    chmod +x ./rowhammer
fi

echo "[*] Testing rowhammer executable..."
timeout 2 ./rowhammer 1 3 3 > /dev/null 2>&1 || echo "[*] rowhammer test complete"
echo ""

# 3. 실험 선택
echo "Select experiment:"
echo "  1. LowVolt + Attack"
echo "  2. LowVolt + Benign"
echo "  3. Both"
read -p "Choice [1/2/3]: " CHOICE

run_attack() {
    local LABEL=$1
    local OUTPUT=$2
    
    echo ""
    echo "=== Running: $LABEL ==="
    echo "[*] Duration: ${DURATION}s"
    echo "[*] Core: $TARGET_CORE"
    echo ""
    
    # Python 스크립트 사용
    python3 collect_data.py "$LABEL" "$OUTPUT" --type "$ATTACK_TYPE"
    
    echo "[+] Complete: $OUTPUT"
}

run_benign() {
    local LABEL=$1
    local OUTPUT=$2
    
    echo ""
    echo "=== Running: $LABEL ==="
    echo "[*] Duration: ${DURATION}s"
    echo "[*] Core: $TARGET_CORE"
    echo ""
    
    # Python 스크립트 사용
    python3 collect_benign.py "$LABEL" "$OUTPUT"
    
    echo "[+] Complete: $OUTPUT"
}

cooldown() {
    echo ""
    echo "[*] Cooling down for 180 seconds..."
    for i in {180..1}; do
        TEMP=$(awk '{print $1/1000}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "N/A")
        echo -ne "\r    Remaining: ${i}s | Temp: ${TEMP}°C   "
        sleep 1
    done
    echo ""
}

case $CHOICE in
    1)
        run_attack "LowVolt_Attack" "lowvolt_attack.csv"
        ;;
    2)
        run_benign "LowVolt_Benign" "lowvolt_benign.csv"
        ;;
    3)
        run_attack "LowVolt_Attack" "lowvolt_attack.csv"
        cooldown
        run_benign "LowVolt_Benign" "lowvolt_benign.csv"
        ;;
    *)
        echo "[-] Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "========================================"
echo "[+] Data collection complete!"
echo "========================================"
echo ""
echo "Generated files:"
ls -lh lowvolt_*.csv 2>/dev/null || echo "  (no files generated)"
echo ""
echo "To restore normal voltage:"
echo "  1. sudo ./set_voltage.sh"
echo "  2. Enter 0"
echo "  3. Reboot"
