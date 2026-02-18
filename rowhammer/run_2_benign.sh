#!/bin/bash

# STEP 2: Benign Experiments
# - Benign + Normal
# - Benign + Hot

set -e

echo "========================================"
echo "STEP 2: Benign Experiments"
echo "========================================"
echo ""
echo "This will run:"
echo "  1. Benign + Normal"
echo "  2. Benign + Hot"
echo ""
echo "Estimated time: 15-20 minutes"
echo ""
read -p "Continue? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    exit 0
fi

# 결과 디렉토리
RESULT_DIR="benign_results"
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

# Benign + Normal
echo ""
echo "[1/2] Benign + Normal"
python3 collect_benign.py "Benign_Normal" "${RESULT_DIR}/benign_normal.csv"
cooldown 180

# Benign + Hot
echo ""
echo "[2/2] Benign + Hot"
python3 collect_benign.py "Benign_Hot" "${RESULT_DIR}/benign_hot.csv" --hot

# 완료
echo ""
echo "========================================"
echo "Benign Experiments Complete!"
echo "========================================"
echo ""
ls -lh "$RESULT_DIR"/*.csv
echo ""
for file in "$RESULT_DIR"/*.csv; do
    FLIPS=$(awk -F',' 'NR>1 {sum+=$9} END {print sum}' "$file")
    echo "$(basename $file): $FLIPS flips"
done
echo ""
echo "[+] Step 2 complete!"
echo "[*] Next: sudo ./run_3_idle.sh"
