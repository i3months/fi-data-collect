#!/bin/bash

# Benign 워크로드 실험 스크립트
# RowHammer 공격 없이 메모리 집약적 작업만 수행하며 HPC 데이터 수집

echo "========================================"
echo "Benign Workload Data Collection"
echo "========================================"
echo ""
echo "Available experiments:"
echo "  1. Benign + Normal (상온에서 메모리 작업)"
echo "  2. Benign + Hot (고온에서 메모리 작업)"
echo "  3. Both (순차 실행)"
echo ""
read -p "Select experiment [1/2/3]: " choice

case $choice in
    1)
        echo "[*] Running Benign + Normal..."
        sudo python3 collect_benign.py "Benign_Normal" "benign_normal.csv"
        ;;
    2)
        echo "[*] Running Benign + Hot..."
        sudo python3 collect_benign.py "Benign_Hot" "benign_hot.csv" --hot
        ;;
    3)
        echo "[*] Running both experiments sequentially..."
        echo ""
        echo "=== Experiment 1/2: Benign + Normal ==="
        sudo python3 collect_benign.py "Benign_Normal" "benign_normal.csv"
        
        echo ""
        echo "=== Cooling down for 180 seconds (3 minutes)... ==="
        echo "[*] Please wait for the system to cool down before starting hot experiment"
        for i in {180..1}; do
            temp=$(awk '{print $1/1000}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "N/A")
            echo -ne "\r    Remaining: ${i}s | Current Temp: ${temp}°C   "
            sleep 1
        done
        echo ""
        
        echo ""
        echo "=== Experiment 2/2: Benign + Hot ==="
        sudo python3 collect_benign.py "Benign_Hot" "benign_hot.csv" --hot
        ;;
    *)
        echo "[-] Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "[+] Experiment(s) complete!"
echo "[*] Check the generated CSV files for results"
