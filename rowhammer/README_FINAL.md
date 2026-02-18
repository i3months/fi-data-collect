# RowHammer 실험 가이드

## 수집할 데이터 (12개)

### Attack (4개)
- Attack + Normal
- Attack + Hot
- Attack + LowVolt
- Attack + Hot + LowVolt

### Benign (4개)
- Benign + Normal
- Benign + Hot
- Benign + LowVolt
- Benign + Hot + LowVolt

### Idle (4개)
- Idle + Normal
- Idle + Hot
- Idle + LowVolt
- Idle + Hot + LowVolt

## 실험 순서

### Phase 1: 정상 전압 (재부팅 불필요)

```bash
# 1. Attack
sudo ./run_1_attack_normal.sh
# → attack_normal.csv, attack_hot.csv

# 2. Benign
sudo ./run_2_benign_normal.sh
# → benign_normal.csv, benign_hot.csv

# 3. Idle
sudo ./run_3_idle_normal.sh
# → idle_normal.csv, idle_hot.csv
```

### Phase 2: 저전압 (재부팅 필요)

```bash
# 전압 설정
sudo ./set_voltage.sh
# 입력: -2 (RPi 4) 또는 -4 (RPi Zero 2)
sudo reboot

# 4. Attack (Low Voltage)
sudo ./run_4_attack_lowvolt.sh
# → attack_lowvolt.csv, attack_hot_lowvolt.csv

# 5. Benign (Low Voltage)
sudo ./run_5_benign_lowvolt.sh
# → benign_lowvolt.csv, benign_hot_lowvolt.csv

# 6. Idle (Low Voltage)
sudo ./run_6_idle_lowvolt.sh
# → idle_lowvolt.csv, idle_hot_lowvolt.csv

# 전압 복구
sudo ./set_voltage.sh
# 입력: 0
sudo reboot
```

## 결과 확인

모든 결과는 `results/` 폴더에 저장됩니다:

```bash
ls -lh results/

# 예상 파일 (12개)
attack_normal.csv
attack_hot.csv
attack_lowvolt.csv
attack_hot_lowvolt.csv
benign_normal.csv
benign_hot.csv
benign_lowvolt.csv
benign_hot_lowvolt.csv
idle_normal.csv
idle_hot.csv
idle_lowvolt.csv
idle_hot_lowvolt.csv
```

## 스크립트 요약

| 스크립트 | 수집 데이터 | 소요 시간 |
|---------|------------|----------|
| `run_1_attack_normal.sh` | Attack + Normal, Attack + Hot | 15-20분 |
| `run_2_benign_normal.sh` | Benign + Normal, Benign + Hot | 15-20분 |
| `run_3_idle_normal.sh` | Idle + Normal, Idle + Hot | 15-20분 |
| `run_4_attack_lowvolt.sh` | Attack + LowVolt, Attack + Hot + LowVolt | 15-20분 |
| `run_5_benign_lowvolt.sh` | Benign + LowVolt, Benign + Hot + LowVolt | 15-20분 |
| `run_6_idle_lowvolt.sh` | Idle + LowVolt, Idle + Hot + LowVolt | 15-20분 |

**총 소요 시간: 약 90-120분**

## 준비

```bash
# 패키지 설치
sudo apt update && sudo apt install -y build-essential stress-ng linux-perf
echo -1 | sudo tee /proc/sys/kernel/perf_event_paranoid

# 컴파일
cd rowhammer
make clean
make
```

## 문제 해결

### CRLF 오류
```bash
sed -i 's/\r$//' *.sh *.py
chmod +x *.sh
```

### 컴파일 오류
```bash
make clean
make
```

### 전압 복구 (부팅 실패 시)
1. SD 카드를 Mac에 연결
2. `/Volumes/bootfs/config.txt` 편집
3. `over_voltage=-4` → `over_voltage=0`
4. SD 카드를 라즈베리파이에 다시 삽입
