#!/bin/bash

# 저전압 환경에서 데이터 수집 스크립트
# 주의: 전압 변경은 재부팅이 필요합니다

CONFIG_FILE="/boot/firmware/config.txt"
[ ! -f "$CONFIG_FILE" ] && CONFIG_FILE="/boot/config.txt"

echo "========================================"
echo "Low Voltage Data Collection"
echo "========================================"
echo ""

# 현재 전압 확인
CURRENT_VOLT=$(vcgencmd measure_volts core)
CURRENT_SETTING=$(grep "^over_voltage=" $CONFIG_FILE 2>/dev/null | cut -d= -f2)
CURRENT_SETTING=${CURRENT_SETTING:-0}

echo "[*] Current voltage: $CURRENT_VOLT"
echo "[*] Current over_voltage setting: $CURRENT_SETTING"
echo ""

# 저전압 설정 확인
if [ "$CURRENT_SETTING" -ge 0 ]; then
    echo "[!] WARNING: System is NOT in low voltage mode!"
    echo "[!] Current over_voltage = $CURRENT_SETTING (should be negative, e.g., -4)"
    echo ""
    echo "To set low voltage:"
    echo "  1. Run: sudo ./set_voltage.sh"
    echo "  2. Enter negative value (e.g., -4)"
    echo "  3. Reboot"
    echo "  4. Run this script again"
    echo ""
    read -p "Do you want to continue anyway? (y/N): " CONTINUE
    if [[ "$CONTINUE" != "y" ]]; then
        exit 1
    fi
fi

echo ""
echo "Available experiments:"
echo "  1. LowVolt + Attack (저전압 + RowHammer 공격)"
echo "  2. LowVolt + Benign (저전압 + 메모리 작업만)"
echo "  3. Both (순차 실행)"
echo ""
read -p "Select experiment [1/2/3]: " choice

case $choice in
    1)
        echo "[*] Running LowVolt + Attack..."
        echo "[*] Using collect_data.py with attack mode"
        sudo python3 collect_data.py "LowVolt_Attack" "lowvolt_attack.csv"
        ;;
    2)
        echo "[*] Running LowVolt + Benign..."
        echo "[*] Using collect_benign.py (no attack)"
        sudo python3 collect_benign.py "LowVolt_Benign" "lowvolt_benign.csv"
        ;;
    3)
        echo "[*] Running both experiments sequentially..."
        echo ""
        echo "=== Experiment 1/2: LowVolt + Attack ==="
        sudo python3 collect_data.py "LowVolt_Attack" "lowvolt_attack.csv"
        
        echo ""
        echo "=== Cooling down for 180 seconds (3 minutes)... ==="
        for i in {180..1}; do
            temp=$(awk '{print $1/1000}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "N/A")
            volt=$(vcgencmd measure_volts core 2>/dev/null || echo "N/A")
            echo -ne "\r    Remaining: ${i}s | Temp: ${temp}°C | Volt: ${volt}   "
            sleep 1
        done
        echo ""
        
        echo ""
        echo "=== Experiment 2/2: LowVolt + Benign ==="
        sudo python3 collect_benign.py "LowVolt_Benign" "lowvolt_benign.csv"
        ;;
    *)
        echo "[-] Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "[+] Experiment(s) complete!"
echo "[*] Check the generated CSV files for results"
echo ""
echo "To restore normal voltage:"
echo "  1. Run: sudo ./set_voltage.sh"
echo "  2. Enter 0 (default)"
echo "  3. Reboot"
