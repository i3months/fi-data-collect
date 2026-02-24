#!/bin/bash

echo "========================================="
echo "Final Low_Hot Collection"
echo "========================================="
echo "Remaining: Benign CRC32 + Idle"
echo "Estimated time: 20 minutes"
echo ""

# Benign CRC32 (6 cycles)
echo ""
echo "[Benign] CRC32 (Low Voltage + Hot Temp)"
python3 collect_cycle.py Benign "CRC32" "results_v3/Low_Hot/Benign_CRC32.csv" --cycles 6 --hot
sleep 30

# Idle (6 cycles)
echo ""
echo "[Idle] (Low Voltage + Hot Temp)"
python3 collect_cycle.py Idle "None" "results_v3/Low_Hot/Idle.csv" --cycles 6 --hot

echo ""
echo "========================================="
echo "Low_Hot Collection COMPLETE!"
echo "========================================="
echo ""
ls -lh results_v3/Low_Hot/
