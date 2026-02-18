#!/bin/bash

# STEP 3: Idle Experiments
# - Idle + Normal
# - Idle + Hot

set -e

echo "========================================"
echo "STEP 3: Idle Experiments"
echo "========================================"
echo ""
echo "This will run:"
echo "  1. Idle + Normal"
echo "  2. Idle + Hot"
echo ""
echo "Estimated time: 15-20 minutes"
echo ""
read -p "Continue? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    exit 0
fi

# 결과 디렉토리
RESULT_DIR="idle_results"
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
        echo -ne "\r    Remaining: ${i}s | Temp: ${TEMP}°C   "
        sleep 1
    done
    echo ""
}

# Idle + Normal
echo ""
echo "[1/2] Idle + Normal"
python3 collect_idle.py "Idle_Normal" "${RESULT_DIR}/idle_normal.csv"
cooldown 180

# Idle + Hot
echo ""
echo "[2/2] Idle + Hot"
python3 collect_idle.py "Idle_Hot" "${RESULT_DIR}/idle_hot.csv" --hot

# 완료
echo ""
echo "========================================"
echo "Idle Experiments Complete!"
echo "========================================"
echo ""
ls -lh "$RESULT_DIR"/*.csv
echo ""
for file in "$RESULT_DIR"/*.csv; do
    FLIPS=$(awk -F',' 'NR>1 {sum+=$9} END {print sum}' "$file")
    echo "$(basename $file): $FLIPS flips"
done
echo ""
echo "[+] Step 3 complete!"
echo "[*] All main experiments done!"
echo ""
echo "Optional: Low voltage experiments"
echo "  1. sudo ./set_voltage.sh (enter -2)"
echo "  2. sudo reboot"
echo "  3. sudo ./run_4_lowvolt.sh"
