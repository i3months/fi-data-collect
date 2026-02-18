# RowHammer 실험 단계별 가이드

## 실험 순서

### 준비
```bash
cd rowhammer
make clean
make
```

### Step 1: Attack 실험
```bash
sudo ./run_1_attack.sh
```
- Normal + Attack
- Hot + Attack
- 결과: `attack_results/`

### Step 2: Benign 실험
```bash
sudo ./run_2_benign.sh
```
- Benign + Normal
- Benign + Hot
- 결과: `benign_results/`

### Step 3: Idle 실험
```bash
sudo ./run_3_idle.sh
```
- Idle + Normal
- Idle + Hot
- 결과: `idle_results/`

### Step 4: 저전압 실험 (선택사항)
```bash
# 1. 전압 설정
sudo ./set_voltage.sh
# 입력: -2 (RPi 4) 또는 -4 (RPi Zero 2)
sudo reboot

# 2. 실험 실행
sudo ./run_4_lowvolt.sh
# 결과: lowvolt_results/

# 3. 전압 복구
sudo ./set_voltage.sh
# 입력: 0
sudo reboot
```

## 결과 확인

```bash
# 모든 결과 확인
ls -lh attack_results/ benign_results/ idle_results/ lowvolt_results/

# Bit-Flip 요약
for dir in attack_results benign_results idle_results lowvolt_results; do
    echo "=== $dir ==="
    for file in $dir/*.csv 2>/dev/null; do
        FLIPS=$(awk -F',' 'NR>1 {sum+=$9} END {print sum}' "$file")
        echo "  $(basename $file): $FLIPS flips"
    done
done
```

## 스크립트 요약

| 스크립트 | 실험 | 소요 시간 | 결과 폴더 |
|---------|------|----------|----------|
| `run_1_attack.sh` | Normal + Attack, Hot + Attack | 15-20분 | `attack_results/` |
| `run_2_benign.sh` | Benign + Normal, Benign + Hot | 15-20분 | `benign_results/` |
| `run_3_idle.sh` | Idle + Normal, Idle + Hot | 15-20분 | `idle_results/` |
| `run_4_lowvolt.sh` | LowVolt + Attack, LowVolt + Benign | 5-10분 | `lowvolt_results/` |

## 각 단계별 상세

### Step 1: Attack (공격)
- RowHammer 공격 실행
- Bit-Flip 발생 예상
- HPC 메트릭 높음

### Step 2: Benign (정상 메모리 작업)
- 공격 없이 메모리 작업만
- Bit-Flip 없음
- HPC 메트릭 중간

### Step 3: Idle (아무것도 안함)
- 작업 없음
- Bit-Flip 없음
- HPC 메트릭 낮음

### Step 4: LowVolt (저전압)
- 저전압 환경에서 공격
- Bit-Flip 감소 예상
- 전압 설정 필요

## 문제 해결

### CRLF 오류
```bash
sed -i 's/\r$//' *.sh
chmod +x *.sh
```

### 권한 오류
```bash
echo -1 | sudo tee /proc/sys/kernel/perf_event_paranoid
```

### 컴파일 오류
```bash
make clean
make
```
