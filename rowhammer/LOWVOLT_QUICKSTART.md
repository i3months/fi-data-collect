# 저전압 데이터 수집 빠른 시작 가이드

## 전체 프로세스

### 1단계: 저전압 설정
```bash
cd ~/voltage_test/rowhammer
sudo ./set_voltage.sh
# 입력: -4
# 재부팅: y
```

### 2단계: 재부팅 후 확인
```bash
vcgencmd measure_volts core
vcgencmd get_config over_voltage
# over_voltage=-4 확인
```

### 3단계: 컴파일 확인
```bash
cd ~/voltage_test/rowhammer
make clean
make

# 실행 파일 확인
ls -lh rowhammer benign_workload
```

### 4단계: 데이터 수집
```bash
sudo ./collect_lowvolt.sh
# 옵션 3 선택 (Both)
```

### 5단계: 결과 확인
```bash
ls -lh lowvolt_*.csv

# Bit-Flip 확인
echo "LowVolt Attack Flips:"
awk -F',' 'NR>1 {sum+=$9} END {print sum}' lowvolt_attack.csv

echo "LowVolt Benign Flips:"
awk -F',' 'NR>1 {sum+=$9} END {print sum}' lowvolt_benign.csv

# 데이터 행 수 확인 (60초 = 약 600행)
wc -l lowvolt_*.csv
```

### 6단계: 전압 복구
```bash
sudo ./set_voltage.sh
# 입력: 0
# 재부팅: y
```

## 문제 해결

### rowhammer 실행 파일이 없음
```bash
make clean
make
ls -lh rowhammer
```

### 권한 오류
```bash
chmod +x rowhammer benign_workload
chmod +x *.sh
```

### CRLF 오류
```bash
sed -i 's/\r$//' *.sh *.py
```

### 데이터가 너무 적음 (60초 미만)
```bash
# 로그 파일 확인
cat flips_LowVolt_Attack.log

# rowhammer 직접 실행 테스트
sudo ./rowhammer 10 3 3
```

### perf 권한 오류
```bash
echo -1 | sudo tee /proc/sys/kernel/perf_event_paranoid
```

## 예상 결과

### 정상 동작 시
- 수집 시간: 약 60초
- CSV 행 수: 약 600행 (100ms 간격)
- 파일 크기: 수십 KB

### CSV 형식
```csv
Timestamp_ns,Label,Temp,CoreVolt,CacheMiss,CacheRef,PageFault,BranchMiss,FlipCount
1234567890,LowVolt_Attack,45.2,1.25,1234,5678,10,234,0
```

## 비교 분석

### 정상 전압 데이터 수집 (비교용)
```bash
# 전압 복구 후
sudo ./set_voltage.sh  # 0 입력
sudo reboot

# 정상 전압 데이터 수집
cd ~/voltage_test/rowhammer
sudo python3 collect_data.py "Normal_Voltage" "normal_voltage.csv"
sudo python3 collect_benign.py "Normal_Benign" "normal_benign.csv"
```

### Bit-Flip 비교
```bash
echo "=== Bit-Flip Comparison ==="
echo -n "Normal Voltage: "
awk -F',' 'NR>1 {sum+=$9} END {print sum " flips"}' normal_voltage.csv

echo -n "Low Voltage: "
awk -F',' 'NR>1 {sum+=$9} END {print sum " flips"}' lowvolt_attack.csv
```

### HPC 메트릭 비교
```bash
echo "=== Cache Miss Comparison ==="
echo -n "Normal: "
awk -F',' 'NR>1 {sum+=$5} END {print sum}' normal_voltage.csv

echo -n "LowVolt: "
awk -F',' 'NR>1 {sum+=$5} END {print sum}' lowvolt_attack.csv
```

## 주의사항

1. **반드시 sudo로 실행**
2. **전압 설정 후 재부팅 필수**
3. **부팅 실패 시 SD 카드로 복구**
4. **실험 완료 후 전압 복구**
