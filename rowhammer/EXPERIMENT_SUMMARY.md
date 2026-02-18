# RowHammer 실험 데이터 수집 요약

## 전체 실험 구성

### 수집 완료 / 진행 중
| 실험 | 설명 | 스크립트 | 출력 파일 | 상태 |
|------|------|---------|----------|------|
| Normal + Attack | 상온 + RowHammer | `collect_data.py` | `normal.csv` | ✅ |
| Hot + Attack | 고온 + RowHammer | `collect_data.py --hot` | `hot.csv` | ✅ |
| Benign + Normal | 상온 + 메모리 작업 | `collect_benign.py` | `benign_normal.csv` | 🔄 |
| Benign + Hot | 고온 + 메모리 작업 | `collect_benign.py --hot` | `benign_hot.csv` | 🔄 |
| Idle + Normal | 상온 + 아무것도 안함 | `collect_idle.py` | `idle_normal.csv` | 🔄 |
| Idle + Hot | 고온 + 아무것도 안함 | `collect_idle.py --hot` | `idle_hot.csv` | 🔄 |
| LowVolt + Attack | 저전압 + RowHammer | `collect_data.py` | `lowvolt_attack.csv` | ⏳ |
| LowVolt + Benign | 저전압 + 메모리 작업 | `collect_benign.py` | `lowvolt_benign.csv` | ⏳ |

## 빠른 시작

### 1. 컴파일
```bash
cd rowhammer
make
```

### 2. 실험 실행

#### Benign 워크로드
```bash
sudo ./run_benign_experiments.sh
# 옵션 3 선택 (Both)
```

#### Idle 상태
```bash
sudo ./run_idle_experiments.sh
# 옵션 3 선택 (Both)
```

#### 저전압
```bash
# 1. 전압 설정
sudo ./set_voltage.sh
# -4 입력
sudo reboot

# 2. 데이터 수집
sudo ./run_lowvolt_experiments.sh
# 옵션 3 선택 (Both)

# 3. 전압 복구
sudo ./set_voltage.sh
# 0 입력
sudo reboot
```

## 데이터 형식

모든 CSV 파일은 동일한 형식:
```csv
Timestamp_ns,Label,Temp,CoreVolt,CacheMiss,CacheRef,PageFault,BranchMiss,FlipCount
```

### 컬럼 설명
- `Timestamp_ns`: 나노초 단위 타임스탬프
- `Label`: 실험 라벨 (예: Benign_Normal)
- `Temp`: CPU 온도 (°C)
- `CoreVolt`: 코어 전압 (V)
- `CacheMiss`: LLC 캐시 미스 횟수
- `CacheRef`: LLC 캐시 참조 횟수
- `PageFault`: 페이지 폴트 횟수
- `BranchMiss`: 분기 예측 실패 횟수
- `FlipCount`: 100ms 간격 내 Bit-Flip 횟수

## 예상 결과 비교

### Bit-Flip Count
```
Attack (Normal):     100+
Attack (Hot):        150+  (온도 ↑ → Flip ↑)
Attack (LowVolt):    50-   (전압 ↓ → Flip ↓)
Benign:              0
Idle:                0
```

### Cache Miss
```
Attack:              10000+
Benign:              5000+
Idle:                100-
```

### 온도
```
Normal:              40-50°C
Hot:                 80-85°C
```

### 전압
```
Normal:              0.85V
LowVolt:             0.80V
```

## 실험 목적

### 1. Attack vs Benign vs Idle
- RowHammer 공격 탐지 가능성 확인
- HPC 메트릭으로 공격 구분 가능한지 검증

### 2. Normal vs Hot
- 온도가 Bit-Flip에 미치는 영향
- 고온에서 공격 효과 증가 확인

### 3. Normal Voltage vs Low Voltage
- 전압이 Bit-Flip에 미치는 영향
- 저전압에서 공격 효과 감소 확인

### 4. Benign vs Idle
- False Positive 방지
- 정상 메모리 작업과 공격 구분

## 분석 예시

### Python으로 데이터 로드
```python
import pandas as pd
import matplotlib.pyplot as plt

# 데이터 로드
attack_normal = pd.read_csv('normal.csv')
attack_hot = pd.read_csv('hot.csv')
benign_normal = pd.read_csv('benign_normal.csv')
idle_normal = pd.read_csv('idle_normal.csv')

# Bit-Flip 비교
print(f"Attack (Normal): {attack_normal['FlipCount'].sum()} flips")
print(f"Attack (Hot): {attack_hot['FlipCount'].sum()} flips")
print(f"Benign: {benign_normal['FlipCount'].sum()} flips")
print(f"Idle: {idle_normal['FlipCount'].sum()} flips")

# Cache Miss 비교
print(f"\nCache Miss:")
print(f"Attack: {attack_normal['CacheMiss'].mean():.0f}")
print(f"Benign: {benign_normal['CacheMiss'].mean():.0f}")
print(f"Idle: {idle_normal['CacheMiss'].mean():.0f}")
```

### 시각화
```python
# Bit-Flip over time
plt.figure(figsize=(12, 6))
plt.plot(attack_normal['Timestamp_ns'], attack_normal['FlipCount'], label='Attack')
plt.plot(benign_normal['Timestamp_ns'], benign_normal['FlipCount'], label='Benign')
plt.xlabel('Time (ns)')
plt.ylabel('Flip Count')
plt.legend()
plt.title('Bit-Flip Detection: Attack vs Benign')
plt.show()
```

## 파일 구조

```
rowhammer/
├── rowhammer.c              # RowHammer 공격 코드
├── benign_workload.c        # Benign 메모리 워크로드
├── collect_data.py          # Attack 데이터 수집
├── collect_benign.py        # Benign 데이터 수집
├── collect_idle.py          # Idle 데이터 수집
├── run_benign_experiments.sh
├── run_idle_experiments.sh
├── run_lowvolt_experiments.sh
├── set_voltage.sh           # 전압 설정
├── Makefile
├── BENIGN_GUIDE.md
├── IDLE_GUIDE.md
├── LOWVOLT_GUIDE.md
└── EXPERIMENT_SUMMARY.md    # 이 파일
```

## 주의사항

### 1. Root 권한
모든 데이터 수집 스크립트는 `sudo`로 실행 필요

### 2. 온도 관리
- Hot 모드는 라즈베리파이에 부담
- 연속 실험 시 쿨다운 필수 (3분)

### 3. 저전압 위험
- 부팅 실패 가능
- SD 카드로 복구 방법 숙지 필요

### 4. 실험 시간
- 각 실험: 약 1분
- Hot 모드: 가열 3-5분 추가
- 전체 순차 실행: 약 10-15분

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

### 온도 안 올라감
```bash
sudo apt install stress-ng
```

### 전압 변경 안됨
```bash
sudo nano /boot/firmware/config.txt
# over_voltage=-4 추가
sudo reboot
```

## 다음 단계

1. 모든 데이터 수집 완료
2. CSV 파일들을 하나로 병합
3. 머신러닝 모델 학습
4. RowHammer 공격 탐지 시스템 구축

## 참고 문서

- `BENIGN_GUIDE.md`: Benign 워크로드 상세 가이드
- `IDLE_GUIDE.md`: Idle 상태 상세 가이드
- `LOWVOLT_GUIDE.md`: 저전압 실험 상세 가이드
- `README.md`: 기본 RowHammer 도구 설명
