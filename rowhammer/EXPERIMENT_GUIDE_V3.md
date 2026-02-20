# RowHammer 실험 가이드 v3

## 📋 실험 개요

### 목표
HPC 메트릭 기반 RowHammer 공격 탐지를 위한 데이터 수집

### 수집 방식
- **샘플링**: 100ms (10Hz)
- **사이클**: 20초
- **반복**: Attack 9회, Benign/Idle 6회
- **쿨다운**: 
  - Normal Temp: 온도가 55°C 이하로 떨어질 때까지 대기 (최대 5분)
  - Hot Temp: 60초 고정

### 벤치마크 (7개)
1. susan - 이미지 엣지 감지
2. qsort_large - 3D 벡터 정렬
3. bitcount - 비트 연산
4. dijkstra - 최단 경로 알고리즘
5. sha - SHA 해시
6. FFT - 고속 푸리에 변환
7. CRC32 - CRC 체크섬

### RowHammer 강도
- **HAMMER_CYCLES**: 10,000 (원래 1,000,000의 1/100)
- 약한 공격으로 설정하여 탐지 난이도 증가

### 환경 조건
- **온도**: Normal (40-50°C) / Hot (80°C)
- **전압**: Normal (0, 1.25V) / Low (-6, 1.10V)

### 워크로드
- **Attack**: MiBench + RowHammer (9 사이클 × 20초 = 180초)
- **Benign**: MiBench only (6 사이클 × 20초 = 120초)
- **Idle**: 아무것도 안함 (6 사이클 × 20초 = 120초)

### 총 데이터셋
```
(7 Attack + 7 Benign + 1 Idle) × 2 온도 × 2 전압 = 60개 CSV
```

---

## 🚀 실험 절차

### 준비 단계

#### 1. 파일 전송 (로컬 → 라즈베리파이)
```bash
# 로컬 맥에서
scp -r rowhammer ana@ana.local:~/ana/rowhammer3
scp -r mibench ana@ana.local:~/ana/
```

#### 2. 컴파일 (라즈베리파이)
```bash
cd ~/ana/rowhammer3

# RowHammer 컴파일
make clean && make

# MiBench 컴파일
cd ~/ana/mibench/automotive/susan && make
cd ~/ana/mibench/automotive/qsort && make
cd ~/ana/mibench/automotive/bitcount && make
cd ~/ana/mibench/network/dijkstra && make
cd ~/ana/mibench/security/sha && make
cd ~/ana/mibench/telecomm/FFT && make
cd ~/ana/mibench/telecomm/CRC32 && make
```

#### 3. 스크립트 권한 설정
```bash
cd ~/ana/rowhammer3
chmod +x *.sh *.py
sed -i 's/\r$//' *.sh  # CRLF 문제 해결
```

#### 4. 전압 확인
```bash
vcgencmd measure_volts core
vcgencmd get_config over_voltage
# over_voltage=0 확인 (Normal Voltage)
```

---

### 실험 1: Normal Voltage (0, 1.25V)

#### Screen 세션 시작
```bash
screen -S experiment
cd ~/ana/rowhammer3
```

#### 실행
```bash
./run_normal_voltage.sh
```

**예상 소요 시간**: 4-6시간

**생성 파일**: 30개 CSV
- `results_v3/Normal_Normal/` - 15개
- `results_v3/Normal_Hot/` - 15개

#### Screen 분리
```
Ctrl+A, D
```

#### 재접속
```bash
screen -r experiment
```

---

### 실험 2: Low Voltage (-6, 1.10V)

#### 전압 변경
```bash
./set_voltage.sh
# -6 입력
# y 입력 (재부팅)
```

#### 재부팅 후 전압 확인
```bash
vcgencmd measure_volts core  # 1.10V 확인
vcgencmd get_config over_voltage  # -6 확인
```

#### Screen 세션 시작
```bash
screen -S experiment
cd ~/ana/rowhammer3
```

#### 실행
```bash
./run_low_voltage.sh
```

**예상 소요 시간**: 4-6시간

**생성 파일**: 30개 CSV
- `results_v3/Low_Normal/` - 15개
- `results_v3/Low_Hot/` - 15개

---

## 📊 데이터 구조

### CSV 파일 구조
```csv
Timestamp_ns,Label,Benchmark,Cycle,Temp,CoreVolt,CacheMiss,CacheRef,PageFault,BranchMiss,FlipCount
```

### 파일명 규칙
```
{Temp}_{Volt}/{Workload}_{Benchmark}.csv

예시:
Normal_Normal/Attack_susan.csv
Normal_Hot/Benign_qsort_large.csv
Low_Normal/Idle.csv
```

### 폴더 구조
```
results_v3/
├── Normal_Normal/    # Normal Temp + Normal Volt (15 files)
│   ├── Attack_susan.csv
│   ├── Attack_qsort_large.csv
│   ├── Attack_bitcount.csv
│   ├── Attack_dijkstra.csv
│   ├── Attack_sha.csv
│   ├── Attack_FFT.csv
│   ├── Attack_CRC32.csv
│   ├── Benign_susan.csv
│   ├── Benign_qsort_large.csv
│   ├── Benign_bitcount.csv
│   ├── Benign_dijkstra.csv
│   ├── Benign_sha.csv
│   ├── Benign_FFT.csv
│   ├── Benign_CRC32.csv
│   └── Idle.csv
│
├── Normal_Hot/       # Normal Temp + Hot (15 files)
├── Low_Normal/       # Low Volt + Normal Temp (15 files)
└── Low_Hot/          # Low Volt + Hot (15 files)
```

---

## 📥 데이터 다운로드

### 로컬 맥에서 실행
```bash
# 전체 다운로드
scp -r ana@ana.local:~/ana/rowhammer3/results_v3 ./

# 확인
ls -lh results_v3/*/
```

---

## 🔧 트러블슈팅

### 좀비 프로세스
```bash
ps aux | grep -E "rowhammer|benign|susan|taskset"
sudo pkill -9 rowhammer
sudo pkill -9 benign_workload
sudo pkill -9 taskset
```

### WiFi 불안정 (Low Voltage)
- Screen 세션 필수
- 모니터/키보드 직접 연결 권장
- 또는 -4 (1.15V)로 변경

### 온도가 안 내려갈 때
```bash
watch -n 1 vcgencmd measure_temp
# 5-10분 대기
```

### 벤치마크 컴파일 에러
```bash
# susan CRLF 문제
cd ~/ana/mibench/automotive/susan
gcc -O3 -Wno-implicit-int -Wno-implicit-function-declaration -o susan susan.c -lm
```

---

## 📈 예상 데이터 양

### 각 CSV 파일당
- **Attack**: 9 사이클 × 200 샘플 = 1,800 샘플
- **Benign**: 6 사이클 × 200 샘플 = 1,200 샘플
- **Idle**: 6 사이클 × 200 샘플 = 1,200 샘플

### 총 샘플 수
```
Attack: 7 × 1,800 × 4 환경 = 50,400 샘플
Benign: 7 × 1,200 × 4 환경 = 33,600 샘플
Idle: 1 × 1,200 × 4 환경 = 4,800 샘플

총: 88,800 샘플
```

---

## ⏱️ 예상 소요 시간

### Normal Voltage (run_normal_voltage.sh)
- Attack: 7 × (180초 수집 + 480초 쿨다운) = 77분
- Benign: 7 × (120초 수집 + 300초 쿨다운) = 49분
- Idle: 1 × (120초 수집 + 300초 쿨다운) = 7분
- Normal Temp 소계: 133분 (약 2.2시간)
- Hot Temp 소계: 133분 + 가열 시간 (약 3시간)
- **총: 약 5-6시간**

### Low Voltage (run_low_voltage.sh)
- **총: 약 5-6시간**

### 전체 실험
- **총 소요 시간: 10-12시간**

---

## ✅ 체크리스트

### 실험 전
- [ ] rowhammer3 폴더 전송
- [ ] mibench 폴더 전송
- [ ] 모든 벤치마크 컴파일 완료
- [ ] 스크립트 권한 설정
- [ ] CRLF 문제 해결
- [ ] 전압 확인 (over_voltage=0)

### Normal Voltage 실험
- [ ] Screen 세션 시작
- [ ] run_normal_voltage.sh 실행
- [ ] 30개 CSV 파일 생성 확인

### Low Voltage 실험
- [ ] 전압 변경 (over_voltage=-6)
- [ ] 재부팅
- [ ] 전압 확인 (1.10V)
- [ ] Screen 세션 시작
- [ ] run_low_voltage.sh 실행
- [ ] 30개 CSV 파일 생성 확인

### 실험 후
- [ ] 총 60개 CSV 파일 확인
- [ ] 로컬로 다운로드
- [ ] 전압 원복 (over_voltage=0)
- [ ] 재부팅

---

## 🎯 다음 단계

1. 데이터 시각화
2. AI 모델 학습
3. 성능 평가
