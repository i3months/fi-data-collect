#!/bin/bash

echo "========================================="
echo "Resume Low_Hot Collection"
echo "========================================="
echo "Remaining: Benign sha, FFT, CRC32 + Idle"
echo "Estimated time: 1.5 hours"
echo ""

REMAINING_BENIGN=("sha" "FFT" "CRC32")

# Benign 3개 (6 cycles each)
for bench in "${REMAINING_BENIGN[@]}"; do
    echo ""
    echo "[Benign] $bench (Low Voltage + Hot Temp)"
    python3 collect_cycle.py Benign "$bench" "results_v3/Low_Hot/Benign_${bench}.csv" --cycles 6 --hot
    sleep 30
done

# Idle 1개 (6 cycles)
echo ""
echo "[Idle] (Low Voltage + Hot Temp)"
python3 collect_cycle.py Idle "None" "results_v3/Low_Hot/Idle.csv" --cycles 6 --hot

echo ""
echo "========================================="
echo "Low_Hot Collection Complete!"
echo "========================================="
echo ""
echo "Total files:"
find results_v3/Low_Hot/ -name "*.csv" | wc -l
echo ""
ls -lh results_v3/Low_Hot/
