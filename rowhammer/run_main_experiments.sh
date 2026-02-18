#!/bin/bash

# RowHammer 메인 실험 자동화 스크립트
# 저전압 실험 제외 (1, 2, 4만 실행)

set -e

echo "========================================"
echo "RowHammer Main Experiments"
echo "========================================"
echo ""
echo "This script will collect data for:"
echo ""
echo "1. Attack Experiments"
echo "   - Normal + Attack"
echo "   - Hot + Attack"
echo ""
echo "2. Benign Experiments"
echo "   - Benign + Normal"
echo "   - Benign + Hot"
echo ""
echo "3. Idle Experiments"
echo "   - Idle + Normal"
echo "   - Idle + Hot"
echo ""
echo "Total: 6 experiments"
echo "Estimated time: 60-90 minutes"
echo ""
read -p "Continue? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    exit 0
fi

# 결과 디렉토리 생성
RESULT_DIR="results_$(date +%Y%m%d_%H%M%S)"
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

# ========================================
# 1. Attack Experiments
# ========================================
echo ""
echo "========================================"
echo "STEP 1: Attack Experiments"
echo "========================================"

echo ""
echo "[1/6] Normal + Attack"
python3 collect_data.py "Normal_Attack" "${RESULT_DIR}/normal_attack.csv"
cooldown 180

echo ""
echo "[2/6] Hot + Attack"
python3 collect_data.py "Hot_Attack" "${RESULT_DIR}/hot_attack.csv" --hot
cooldown 180

# ========================================
# 2. Benign Experiments
# ========================================
echo ""
echo "========================================"
echo "STEP 2: Benign Experiments"
echo "========================================"

echo ""
echo "[3/6] Benign + Normal"
python3 collect_benign.py "Benign_Normal" "${RESULT_DIR}/benign_normal.csv"
cooldown 180

echo ""
echo "[4/6] Benign + Hot"
python3 collect_benign.py "Benign_Hot" "${RESULT_DIR}/benign_hot.csv" --hot
cooldown 180

# ========================================
# 3. Idle Experiments
# ========================================
echo ""
echo "========================================"
echo "STEP 3: Idle Experiments"
echo "========================================"

echo ""
echo "[5/6] Idle + Normal"
python3 collect_idle.py "Idle_Normal" "${RESULT_DIR}/idle_normal.csv"
cooldown 180

echo ""
echo "[6/6] Idle + Hot"
python3 collect_idle.py "Idle_Hot" "${RESULT_DIR}/idle_hot.csv" --hot

# ========================================
# 완료
# ========================================
echo ""
echo "========================================"
echo "All Main Experiments Complete!"
echo "========================================"
echo ""
echo "Results directory: $RESULT_DIR"
echo ""
echo "Collected files:"
ls -lh "$RESULT_DIR"/*.csv
echo ""
echo "Summary:"
echo "----------------------------------------"
printf "%-25s %10s %10s\n" "Experiment" "Rows" "Flips"
echo "----------------------------------------"
for file in "$RESULT_DIR"/*.csv; do
    LINES=$(wc -l < "$file")
    FLIPS=$(awk -F',' 'NR>1 {sum+=$9} END {print sum}' "$file")
    printf "%-25s %10d %10d\n" "$(basename $file .csv)" "$LINES" "$FLIPS"
done
echo "----------------------------------------"
echo ""
echo "[+] Main experiments complete!"
echo ""
echo "Next steps (optional):"
echo "  - For low voltage experiments: sudo ./run_lowvolt_only.sh"
echo "  - To analyze results: python3 visualize_results.py"
