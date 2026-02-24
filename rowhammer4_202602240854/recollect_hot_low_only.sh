#!/bin/bash
# Low Voltage 고온(80°C) 데이터만 재수집하는 스크립트
# Normal Voltage 수집이 이미 완료된 경우 사용

set -e

echo "========================================"
echo "Low Voltage 고온 데이터 재수집 (80°C)"
echo "========================================"
echo ""
echo "이 스크립트는 Low Voltage 고온(80°C) 데이터만 수집합니다:"
echo "  - Low Voltage (-6, 1.10V) - Hot Temp: 15 files"
echo ""
echo "총 15개 CSV 파일 수집"
echo "예상 시간: 2-3 시간"
echo ""
echo "벤치마크: susan, qsort_large, bitcount, dijkstra, sha, FFT, CRC32"
echo ""
read -p "계속하시겠습니까? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    exit 0
fi

# 현재 전압 확인
VOLTAGE=$(vcgencmd get_config over_voltage | cut -d= -f2)
MEASURED=$(vcgencmd measure_volts core)
echo ""
echo "[*] 현재 전압 설정: over_voltage=$VOLTAGE"
echo "[*] 측정된 전압: $MEASURED"
echo ""

# 전압이 -6인지 확인
if [[ "$VOLTAGE" != "-6" ]]; then
    echo "[!] 경고: Low Voltage 실험을 위해 over_voltage=-6이 필요합니다"
    echo "[!] 현재 설정: over_voltage=$VOLTAGE"
    echo ""
    echo "전압을 변경하려면:"
    echo "  1. ./set_voltage.sh 실행 (-6 입력)"
    echo "  2. sudo reboot"
    echo "  3. 이 스크립트 다시 실행"
    echo ""
    read -p "현재 전압으로 계속하시겠습니까? (y/N): " CONFIRM2
    if [[ "$CONFIRM2" != "y" ]]; then
        exit 0
    fi
fi

# 결과 디렉토리 생성
RESULT_DIR="results_v3_hot_recollect"
mkdir -p "$RESULT_DIR/Low_Hot"

echo "[*] 결과 저장 위치:"
echo "    - $RESULT_DIR/Low_Hot/ (Low Voltage, Hot Temp)"
echo ""

# 벤치마크 목록
BENCHMARKS=("susan" "qsort_large" "bitcount" "dijkstra" "sha" "FFT" "CRC32")

echo ""
echo "========================================"
echo "Low Voltage - Hot Temperature (80°C)"
echo "========================================"
echo ""

# Attack 실험 (각 9 사이클)
for bench in "${BENCHMARKS[@]}"; do
    echo ""
    echo "[Attack] $bench (Low Voltage, Hot 80°C)"
    python3 collect_cycle.py Attack "$bench" "$RESULT_DIR/Low_Hot/Attack_${bench}.csv" --cycles 9 --hot
    sleep 30
done

# Benign 실험 (각 6 사이클)
for bench in "${BENCHMARKS[@]}"; do
    echo ""
    echo "[Benign] $bench (Low Voltage, Hot 80°C)"
    python3 collect_cycle.py Benign "$bench" "$RESULT_DIR/Low_Hot/Benign_${bench}.csv" --cycles 6 --hot
    sleep 30
done

# Idle 실험 (6 사이클)
echo ""
echo "[Idle] (Low Voltage, Hot 80°C)"
python3 collect_cycle.py Idle "None" "$RESULT_DIR/Low_Hot/Idle.csv" --cycles 6 --hot

echo ""
echo "========================================"
echo "Low Voltage 고온 데이터 수집 완료!"
echo "========================================"
echo ""
echo "수집된 파일:"
ls -lh "$RESULT_DIR/Low_Hot/"
echo ""
echo "총: 15개 CSV 파일"
echo ""
echo "Low Voltage 고온 실험 완료!"
echo ""
