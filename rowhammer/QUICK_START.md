# RowHammer 실험 빠른 시작 가이드

## 전체 실험 한방에 실행

### 1단계: 준비
```bash
cd rowhammer
make clean
make
```

### 2단계: 정상 전압 실험 (자동)
```bash
sudo ./run_all_experiments.sh
```

이 스크립트는 다음을 자동으로 실행합니다:
1. Normal + Attack (1분)
2. 쿨다운 (3분)
3. Hot + Attack (가열 3-5분 + 실험 1분)
4. 쿨다운 (3분)
5. Benign + Normal (1분)
6. 쿨다운 (3분)
7. Benign + Hot (가열 3-5분 + 실험 1분)
8. 쿨다운 (3분)
9. Idle + Normal (1분)
10. 쿨다운 (3분)
11. Idle + Hot (가열 3-5분 + 실험 1분)

**총 소요 시간: 약 60-90분**

결과는 `experiment_results_YYYYMMDD_HHMMSS/` 폴더에 저장됩니다.

### 3단계: 저전압 설정
```bash
sudo ./set_voltage.sh
# 입력: -2 (RPi 4) 또는 -4 (RPi Zero 2)
# 재부팅: y
```

### 4단계: 저전압 실험 (자동)
```bash
# 재부팅 후
cd rowhammer
sudo ./run_lowvolt_only.sh
```

이 스크립트는 다음을 자동으로 실행합니다:
1. LowVolt + Attack (1분)
2. 쿨다운 (3분)
3. LowVolt + Benign (1분)

**총 소요 시간: 약 5분**

결과는 `lowvolt_results_YYYYMMDD_HHMMSS/` 폴더에 저장됩니다.

### 5단계: 전압 복구
```bash
sudo ./set_voltage.sh
# 입력: 0
# 재부팅: y
```

## 개별 실험 실행

원하는 실험만 실행하려면:

### Attack 실험
```bash
# Normal
sudo python3 collect_data.py "Normal_Attack" "normal_attack.csv"

# Hot
sudo python3 collect_data.py "Hot_Attack" "hot_attack.csv" --hot
```

### Benign 실험
```bash
# Normal
sudo python3 collect_benign.py "Benign_Normal" "benign_normal.csv"

# Hot
sudo python3 collect_benign.py "Benign_Hot" "benign_hot.csv" --hot
```

### Idle 실험
```bash
# Normal
sudo python3 collect_idle.py "Idle_Normal" "idle_normal.csv"

# Hot
sudo python3 collect_idle.py "Idle_Hot" "idle_hot.csv" --hot
```

### LowVolt 실험 (전압 설정 후)
```bash
# Attack
sudo python3 collect_data.py "LowVolt_Attack" "lowvolt_attack.csv"

# Benign
sudo python3 collect_benign.py "LowVolt_Benign" "lowvolt_benign.csv"
```

## 결과 확인

### 파일 목록
```bash
ls -lh experiment_results_*/
ls -lh lowvolt_results_*/
```

### Bit-Flip 요약
```bash
for file in experiment_results_*/*.csv lowvolt_results_*/*.csv; do
    FLIPS=$(awk -F',' 'NR>1 {sum+=$9} END {print sum}' "$file")
    echo "$(basename $file): $FLIPS flips"
done
```

### 데이터 행 수 확인
```bash
wc -l experiment_results_*/*.csv lowvolt_results_*/*.csv
```

## 스크립트 요약

| 스크립트 | 용도 | 소요 시간 |
|---------|------|----------|
| `run_all_experiments.sh` | 정상 전압 전체 실험 (6개) | 60-90분 |
| `run_lowvolt_only.sh` | 저전압 실험 (2개) | 5분 |
| `collect_data.py` | Attack 데이터 수집 | 1분 |
| `collect_benign.py` | Benign 데이터 수집 | 1분 |
| `collect_idle.py` | Idle 데이터 수집 | 1분 |
| `set_voltage.sh` | 전압 설정 | 1분 + 재부팅 |

## 문제 해결

### 컴파일 오류
```bash
make clean
make
```

### 권한 오류
```bash
echo -1 | sudo tee /proc/sys/kernel/perf_event_paranoid
```

### CRLF 오류
```bash
sed -i 's/\r$//' *.sh *.py
chmod +x *.sh
```

### 부팅 실패 (저전압)
1. SD 카드를 Mac에 연결
2. `/Volumes/bootfs/config.txt` 편집
3. `over_voltage=-4` → `over_voltage=0`
4. SD 카드를 라즈베리파이에 다시 삽입

## 예상 결과

### 정상 동작 시
- 각 실험: 약 600행 (60초 × 10Hz)
- 파일 크기: 수십 KB
- Bit-Flip: 환경에 따라 0 ~ 수천 개

### CSV 형식
```csv
Timestamp_ns,Label,Temp,CoreVolt,CacheMiss,CacheRef,PageFault,BranchMiss,FlipCount
```

## 전체 프로세스 요약

```bash
# 1. 정상 전압 실험 (자동)
sudo ./run_all_experiments.sh

# 2. 저전압 설정
sudo ./set_voltage.sh  # -2 입력
sudo reboot

# 3. 저전압 실험 (자동)
sudo ./run_lowvolt_only.sh

# 4. 전압 복구
sudo ./set_voltage.sh  # 0 입력
sudo reboot

# 5. 결과 확인
ls -lh experiment_results_*/ lowvolt_results_*/
```

**총 소요 시간: 약 70-100분**
