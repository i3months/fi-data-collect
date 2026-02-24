#!/bin/bash
# 고온(80°C) 데이터만 재수집하는 스크립트
# Normal Voltage와 Low Voltage 모두 고온 데이터만 수집

set -e

echo "========================================"
echo "RowHammer 고온 데이터 재수집 (80°C)"
echo "========================================"
echo ""
echo "이 스크립트는 고온(80°C) 데이터만 재수집합니다:"
echo "  - Normal Voltage (0, 1.25V) - Hot Temp: 15 files"
echo "  - Low Voltage (-6, 1.10V) - Hot Temp: 15 files"
echo ""
echo "총 30개 CSV 파일 수집"
echo "예상 시간: 4-6 시간"
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

# 결과 디렉토리 생성
RESULT_DIR="results_v3_hot_recollect"
mkdir -p "$RESULT_DIR/Normal_Hot"
mkdir -p "$RESULT_DIR/Low_Hot"

echo "[*] 결과 저장 위치:"
echo "    - $RESULT_DIR/Normal_Hot/ (Normal Voltage, Hot Temp)"
echo "    - $RESULT_DIR/Low_Hot/ (Low Voltage, Hot Temp)"
echo ""

# 벤치마크 목록
BENCHMARKS=("susan" "qsort_large" "bitcount" "dijkstra" "sha" "FFT" "CRC32")

# ============================================
# Part 1: Normal Voltage (0) - Hot Temperature
# ============================================
echo ""
echo "========================================"
echo "Part 1: Normal Voltage - Hot (80°C)"
echo "========================================"
echo ""

# 전압이 0인지 확인
if [[ "$VOLTAGE" != "0" ]]; then
    echo "[!] 경고: Normal Voltage 실험을 위해 over_voltage=0이 필요합니다"
    echo "[!] 현재 설정: over_voltage=$VOLTAGE"
    echo ""
    echo "전압을 변경하려면:"
    echo "  1. ./set_voltage.sh 실행 (0 입력)"
    echo "  2. sudo reboot"
    echo "  3. 이 스크립트 다시 실행"
    echo ""
    read -p "현재 전압으로 계속하시겠습니까? (y/N): " CONFIRM2
    if [[ "$CONFIRM2" != "y" ]]; then
        exit 0
    fi
fi

echo "[*] Normal Voltage (over_voltage=$VOLTAGE) - Hot Temperature 수집 시작"
echo ""

# Attack 실험 (각 9 사이클)
for bench in "${BENCHMARKS[@]}"; do
    echo ""
    echo "[Attack] $bench (Normal Voltage, Hot 80°C)"
    python3 collect_cycle.py Attack "$bench" "$RESULT_DIR/Normal_Hot/Attack_${bench}.csv" --cycles 9 --hot
    sleep 30
done

# Benign 실험 (각 6 사이클)
for bench in "${BENCHMARKS[@]}"; do
    echo ""
    echo "[Benign] $bench (Normal Voltage, Hot 80°C)"
    python3 collect_cycle.py Benign "$bench" "$RESULT_DIR/Normal_Hot/Benign_${bench}.csv" --cycles 6 --hot
    sleep 30
done

# Idle 실험 (6 사이클)
echo ""
echo "[Idle] (Normal Voltage, Hot 80°C)"
python3 collect_cycle.py Idle "None" "$RESULT_DIR/Normal_Hot/Idle.csv" --cycles 6 --hot

echo ""
echo "[+] Normal Voltage - Hot Temperature 수집 완료!"
echo ""
ls -lh "$RESULT_DIR/Normal_Hot/"
echo ""

# ============================================
# Part 2: Low Voltage (-6) - Hot Temperature
# ============================================
echo ""
echo "========================================"
echo "Part 2: Low Voltage - Hot (80°C)"
echo "========================================"
echo ""
echo "[!] 이제 Low Voltage 실험을 위해 전압을 변경해야 합니다"
echo ""
echo "다음 단계:"
echo "  1. Ctrl+C로 이 스크립트 중단"
echo "  2. ./set_voltage.sh 실행 (enter -6)"
echo "  3. sudo reboot"
echo "  4. ./recollect_hot_only.sh --low-only 실행"
echo ""
read -p "전압이 이미 -6로 설정되어 있습니까? (y/N): " VOLTAGE_OK
if [[ "$VOLTAGE_OK" != "y" ]]; then
    echo ""
    echo "[*] 전압 변경 후 다음 명령으로 Low Voltage 수집을 계속하세요:"
    echo "    ./recollect_hot_only.sh --low-only"
    echo ""
    exit 0
fi

# 전압이 -6인지 확인
VOLTAGE=$(vcgencmd get_config over_voltage | cut -d= -f2)
if [[ "$VOLTAGE" != "-6" ]]; then
    echo "[!] 경고: Low Voltage 실험을 위해 over_voltage=-6이 필요합니다"
    echo "[!] 현재 설정: over_voltage=$VOLTAGE"
    read -p "현재 전압으로 계속하시겠습니까? (y/N): " CONFIRM3
    if [[ "$CONFIRM3" != "y" ]]; then
        exit 0
    fi
fi

echo "[*] Low Voltage (over_voltage=$VOLTAGE) - Hot Temperature 수집 시작"
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
echo "고온 데이터 재수집 완료!"
echo "========================================"
echo ""
echo "수집된 파일:"
echo ""
echo "Normal Voltage - Hot:"
ls -lh "$RESULT_DIR/Normal_Hot/"
echo ""
echo "Low Voltage - Hot:"
ls -lh "$RESULT_DIR/Low_Hot/"
echo ""
echo "총: 30개 CSV 파일"
echo ""
echo "모든 고온 실험 완료!"
echo ""
