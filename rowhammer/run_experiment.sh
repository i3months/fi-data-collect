#!/bin/bash

# Configuration
DURATION=120           # Duration of RowHammer attack in seconds (Default: 2 minutes)
MODE=3                 # 3 = DC ZVA (Most effective on ARMv8)
HAMMER_TYPE=3          # 3 = Half-Double (Targeting Distance-2 rows)
OUTPUT_NORMAL="result_normal.csv"
OUTPUT_HIGH="result_high.csv"
TEMP_THRESHOLD=84.0    # Target temperature for high-temp experiment (Celsius)

# Usage Check
if [ "$#" -ne 1 ]; then
    echo "Usage: sudo ./run_experiment.sh [normal|hot]"
    exit 1
fi

TEST_TYPE=$1

# Helper function to get temperature
get_temp() {
    awk '{print $1/1000}' /sys/class/thermal/thermal_zone0/temp
}

# 1. Check Root Privileges
if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run as root (sudo ./run_experiment.sh $TEST_TYPE)"
  exit 1
fi

# 2. Check dependencies (stress-ng)
if ! command -v stress-ng &> /dev/null; then
    echo "[-] stress-ng could not be found."
    echo "[*] Installing stress-ng..."
    apt-get update && apt-get install -y stress-ng
fi

# 3. Compile
echo "[*] Compiling RowHammer tool..."
make clean > /dev/null 2>&1
make > /dev/null 2>&1
if [ ! -f "./rowhammer" ]; then
    echo "[-] Compilation failed."
    exit 1
fi
echo "[+] Compilation successful."

if [ "$TEST_TYPE" == "normal" ]; then
    # --- EXPERIMENT: NORMAL TEMP ---
    CURRENT_TEMP=$(get_temp)
    echo "========================================"
    echo "[*] Running Normal Temperature Experiment"
    echo "[*] Current Temperature: ${CURRENT_TEMP}°C"
    echo "[*] Running Half-Double RowHammer for ${DURATION} seconds..."
    echo "========================================"

    ./rowhammer $DURATION $MODE $HAMMER_TYPE > $OUTPUT_NORMAL

    FLIPS_NORMAL=$(grep -c "FLIP" $OUTPUT_NORMAL)
    echo "[+] Normal Experiment Complete. Total Flips: $FLIPS_NORMAL"
    echo "[*] Data saved to $OUTPUT_NORMAL"

elif [ "$TEST_TYPE" == "hot" ]; then
    # --- EXPERIMENT: HIGH TEMP ---
    echo "========================================"
    echo "[*] Running High Temperature Experiment"
    echo "[*] Starting stress-ng to heat up CPU..."
    echo "========================================"

    # Start stress-ng in background (load all 4 cores)
    stress-ng --cpu 4 --timeout 600s &
    STRESS_PID=$!

    # Wait for temperature to rise
    echo "[*] Waiting for temperature to exceed ${TEMP_THRESHOLD}°C..."
    while true; do
        CURRENT_TEMP=$(get_temp)
        IS_HOT=$(echo "$CURRENT_TEMP > $TEMP_THRESHOLD" | bc -l)
        
        if [ "$IS_HOT" -eq 1 ]; then
            echo "[!] Threshold reached! Current Temperature: ${CURRENT_TEMP}°C"
            break
        fi
        
        echo -ne "    Current: ${CURRENT_TEMP}°C... \r"
        sleep 2
    done
    echo ""

    # Run RowHammer while hot
    echo "[*] Running Half-Double RowHammer for ${DURATION} seconds (under load)..."
    ./rowhammer $DURATION $MODE $HAMMER_TYPE > $OUTPUT_HIGH

    # Stop stress-ng
    kill $STRESS_PID > /dev/null 2>&1
    wait $STRESS_PID 2>/dev/null

    FLIPS_HIGH=$(grep -c "FLIP" $OUTPUT_HIGH)
    FINAL_TEMP=$(get_temp)

    echo "[+] High Temp Experiment Complete. Total Flips: $FLIPS_HIGH"
    echo "[*] Final Temperature: ${FINAL_TEMP}°C"
    echo "[*] Data saved to $OUTPUT_HIGH"

else
    echo "[-] Invalid argument. Usage: sudo ./run_experiment.sh [normal|hot]"
    exit 1
fi
