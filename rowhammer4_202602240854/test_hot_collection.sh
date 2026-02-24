#!/bin/bash
# 고온 수집 테스트 스크립트 - 온도 유지 확인

set -e

echo "========================================"
echo "고온 수집 테스트 (온도 유지 확인)"
echo "========================================"
echo ""
echo "이 테스트는 1개 사이클만 실행하여 온도 유지를 확인합니다."
echo "예상 시간: 약 3-4분"
echo ""
read -p "계속하시겠습니까? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    exit 0
fi

# 테스트 디렉토리 생성
TEST_DIR="test_hot_results"
mkdir -p "$TEST_DIR"

echo ""
echo "[*] 테스트 시작..."
echo ""

# 1 사이클 테스트
python3 collect_cycle.py Attack susan "$TEST_DIR/test_hot.csv" --cycles 1 --hot

echo ""
echo "========================================"
echo "테스트 완료!"
echo "========================================"
echo ""

# 온도 분석
if command -v python3 &> /dev/null; then
    echo "[*] 온도 분석 중..."
    python3 << 'EOF'
import pandas as pd
import sys

try:
    df = pd.read_csv("test_hot_results/test_hot.csv")
    
    print("\n온도 통계:")
    print(f"  평균 온도: {df['Temp'].mean():.2f}°C")
    print(f"  최소 온도: {df['Temp'].min():.2f}°C")
    print(f"  최대 온도: {df['Temp'].max():.2f}°C")
    print(f"  표준편차: {df['Temp'].std():.2f}°C")
    print(f"  샘플 수: {len(df)}")
    
    # 온도 범위 체크
    min_temp = df['Temp'].min()
    max_temp = df['Temp'].max()
    avg_temp = df['Temp'].mean()
    
    print("\n평가:")
    if avg_temp >= 78 and avg_temp <= 82:
        print("  ✓ 평균 온도 양호 (78-82°C 범위)")
    else:
        print(f"  ✗ 평균 온도 범위 벗어남 (목표: 78-82°C, 실제: {avg_temp:.2f}°C)")
    
    if min_temp >= 75:
        print("  ✓ 최소 온도 양호 (75°C 이상)")
    else:
        print(f"  ✗ 최소 온도 낮음 (목표: 75°C 이상, 실제: {min_temp:.2f}°C)")
    
    if max_temp <= 85:
        print("  ✓ 최대 온도 안전 (85°C 이하)")
    else:
        print(f"  ⚠ 최대 온도 높음 (목표: 85°C 이하, 실제: {max_temp:.2f}°C)")
    
    if df['Temp'].std() <= 3:
        print("  ✓ 온도 안정성 양호 (표준편차 3°C 이하)")
    else:
        print(f"  ✗ 온도 변동 큼 (목표: 3°C 이하, 실제: {df['Temp'].std():.2f}°C)")
    
    print("\n시간별 온도 변화:")
    # 5초 간격으로 온도 출력
    time_points = [0, 5, 10, 15, 20]
    for t in time_points:
        subset = df[df['CycleTime_ms'] >= t*1000]
        if len(subset) > 0:
            temp_at_t = subset.iloc[0]['Temp']
            print(f"  {t:2d}초: {temp_at_t:.2f}°C")
    
except FileNotFoundError:
    print("\n[!] 테스트 파일을 찾을 수 없습니다.")
    sys.exit(1)
except Exception as e:
    print(f"\n[!] 분석 중 오류: {e}")
    sys.exit(1)
EOF
fi

echo ""
echo "테스트 파일: $TEST_DIR/test_hot.csv"
echo ""
echo "다음 단계:"
echo "  - 온도가 80°C 근처에서 안정적이면 전체 수집 시작"
echo "  - 온도가 낮으면 주변 온도 확인 또는 냉각 팬 조정"
echo "  - 온도가 너무 높으면 냉각 시간 증가 필요"
echo ""
