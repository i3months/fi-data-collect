#!/bin/bash

# Idle 상태 실험 스크립트
# 아무 작업도 하지 않는 상태에서 HPC 데이터 수집

echo "========================================"
echo "Idle State Data Collection"
echo "========================================"
echo ""
echo "Available experiments:"
echo "  1. Idle + Normal (상온에서 아무것도 안함)"
echo "  2. Idle + Hot (고온 도달 후 아무것도 안함)"
echo "  3. Both (순차 실행)"
echo ""
read -p "Select experiment [1/2/3]: " choice

case $choice in
    1)
        echo "[*] Running Idle + Normal..."
        sudo python3 collect_idle.py "Idle_Normal" "idle_normal.csv"
        ;;
    2)
        echo "[*] Running Idle + Hot..."
        echo "[!] Note: System will heat up, then stress will stop for true idle state"
        sudo python3 collect_idle.py "Idle_Hot" "idle_hot.csv" --hot
        ;;
    3)
        echo "[*] Running both experiments sequentially..."
        echo ""
        echo "=== Experiment 1/2: Idle + Normal ==="
        sudo python3 collect_idle.py "Idle_Normal" "idle_normal.csv"
        
        echo ""
        echo "=== Cooling down for 180 seconds (3 minutes)... ==="
        echo "[*] Please wait for the system to cool down"
        for i in {180..1}; do
            temp=$(awk '{print $1/1000}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "N/A")
            echo -ne "\r    Remaining: ${i}s | Current Temp: ${temp}°C   "
            sleep 1
        done
        echo ""
        
        echo ""
        echo "=== Experiment 2/2: Idle + Hot ==="
        echo "[!] Note: System will heat up, then stress will stop for true idle state"
        sudo python3 collect_idle.py "Idle_Hot" "idle_hot.csv" --hot
        ;;
    *)
        echo "[-] Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "[+] Experiment(s) complete!"
echo "[*] Check the generated CSV files for results"
