#!/bin/bash

# STEP 1: Attack Experiments
# - Normal + Attack
# - Hot + Attack

set -e

echo "========================================"
echo "STEP 1: Attack Experiments"
echo "========================================"
echo ""
echo "This will run:"
echo "  1. Normal + Attack"
echo "  2. Hot + Attack"
echo ""
echo "Estimated time: 15-20 minutes"
echo ""
read -p "Continue? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    exit 0
fi

# 결과 디렉토리
RESULT_DIR="attack_results"
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

# Normal + Attack
echo ""
echo "[1/2] Normal + Attack"
python3 collect_data.py "Normal_Attack" "${RESULT_DIR}/normal_attack.csv"
cooldown 180

# Hot + Attack
echo ""
echo "[2/2] Hot + Attack"
python3 collect_data.py "Hot_Attack" "${RESULT_DIR}/hot_attack.csv" --hot

# 완료
echo ""
echo "========================================"
echo "Attack Experiments Complete!"
echo "========================================"
echo ""
ls -lh "$RESULT_DIR"/*.csv
echo ""
for file in "$RESULT_DIR"/*.csv; do
    FLIPS=$(awk -F',' 'NR>1 {sum+=$9} END {print sum}' "$file")
    echo "$(basename $file): $FLIPS flips"
done
echo ""
echo "[+] Step 1 complete!"
echo "[*] Next: sudo ./run_2_benign.sh"
