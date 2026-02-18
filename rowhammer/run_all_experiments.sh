#!/bin/bash

# RowHammer 전체 실험 자동화 스크립트
# 모든 실험을 순차적으로 실행

set -e

echo "========================================"
echo "RowHammer Complete Experiment Suite"
echo "========================================"
echo ""
echo "This script will collect data for:"
echo "  1. Normal + Attack"
echo "  2. Hot + Attack"
echo "  3. Benign + Normal"
echo "  4. Benign + Hot"
echo "  5. Idle + Normal"
echo "  6. Idle + Hot"
echo "  7. LowVolt + Attack (requires manual voltage setting)"
echo "  8. LowVolt + Benign (requires manual voltage setting)"
echo ""
echo "Total estimated time: ~60-90 minutes"
echo ""
read -p "Continue? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    exit 0
fi

# 결과 디렉토리 생성
RESULT_DIR="experiment_results_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULT_DIR"
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

# 실험 카운터
CURRENT=0
TOTAL=6

# ========================================
# 1. Normal + Attack
# ========================================
CURRENT=$((CURRENT+1))
echo ""
echo "========================================"
echo "[$CURRENT/$TOTAL] Normal + Attack"
echo "========================================"
python3 collect_data.py "Normal_Attack" "${RESULT_DIR}/normal_attack.csv"
cooldown 180

# ========================================
# 2. Hot + Attack
# ========================================
CURRENT=$((CURRENT+1))
echo ""
echo "========================================"
echo "[$CURRENT/$TOTAL] Hot + Attack"
echo "========================================"
python3 collect_data.py "Hot_Attack" "${RESULT_DIR}/hot_attack.csv" --hot
cooldown 180

# ========================================
# 3. Benign + Normal
# ========================================
CURRENT=$((CURRENT+1))
echo ""
echo "========================================"
echo "[$CURRENT/$TOTAL] Benign + Normal"
echo "========================================"
python3 collect_benign.py "Benign_Normal" "${RESULT_DIR}/benign_normal.csv"
cooldown 180

# ========================================
# 4. Benign + Hot
# ========================================
CURRENT=$((CURRENT+1))
echo ""
echo "========================================"
echo "[$CURRENT/$TOTAL] Benign + Hot"
echo "========================================"
python3 collect_benign.py "Benign_Hot" "${RESULT_DIR}/benign_hot.csv" --hot
cooldown 180

# ========================================
# 5. Idle + Normal
# ========================================
CURRENT=$((CURRENT+1))
echo ""
echo "========================================"
echo "[$CURRENT/$TOTAL] Idle + Normal"
echo "========================================"
python3 collect_idle.py "Idle_Normal" "${RESULT_DIR}/idle_normal.csv"
cooldown 180

# ========================================
# 6. Idle + Hot
# ========================================
CURRENT=$((CURRENT+1))
echo ""
echo "========================================"
echo "[$CURRENT/$TOTAL] Idle + Hot"
echo "========================================"
python3 collect_idle.py "Idle_Hot" "${RESULT_DIR}/idle_hot.csv" --hot
cooldown 180

# ========================================
# 완료
# ========================================
echo ""
echo "========================================"
echo "Normal Voltage Experiments Complete!"
echo "========================================"
echo ""
echo "Collected files:"
ls -lh "$RESULT_DIR"/*.csv
echo ""
echo "Summary:"
for file in "$RESULT_DIR"/*.csv; do
    LINES=$(wc -l < "$file")
    FLIPS=$(awk -F',' 'NR>1 {sum+=$9} END {print sum}' "$file")
    echo "  $(basename $file): ${LINES} rows, ${FLIPS} flips"
done
echo ""
echo "========================================"
echo "Low Voltage Experiments (Manual)"
echo "========================================"
echo ""
echo "To collect low voltage data:"
echo "  1. sudo ./set_voltage.sh"
echo "  2. Enter -2 (for RPi 4) or -4 (for RPi Zero 2)"
echo "  3. Reboot"
echo "  4. sudo ./run_lowvolt_only.sh"
echo "  5. sudo ./set_voltage.sh (enter 0 to restore)"
echo "  6. Reboot"
echo ""
echo "[+] All automated experiments complete!"
