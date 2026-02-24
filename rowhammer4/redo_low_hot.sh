#!/bin/bash

cd ~/ana/rowhammer4

echo "========================================="
echo "Low Voltage + Hot Temp - Full Collection"
echo "========================================="
echo "15 files will be collected"
echo "Estimated time: 4 hours"
echo ""

BENCHMARKS=("susan" "qsort_large" "bitcount" "dijkstra" "sha" "FFT" "CRC32")

# Attack 7개 (9 cycles each)
for bench in "${BENCHMARKS[@]}"; do
    echo ""
    echo "[Attack] $bench (Low Voltage + Hot Temp)"
    python3 collect_cycle.py Attack "$bench" "results_v3/Low_Hot/Attack_${bench}.csv" --cycles 9 --hot
    sleep 30
done

# Benign 7개 (6 cycles each)
for bench in "${BENCHMARKS[@]}"; do
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
find results_v3/ -name "*.csv" | wc -l
echo ""
ls -lh results_v3/Low_Hot/
