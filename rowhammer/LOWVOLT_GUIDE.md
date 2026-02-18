# 저전압 데이터 수집 가이드

## 개요
저전압 환경에서 RowHammer 공격 및 Benign 워크로드 데이터를 수집합니다.
논문에 따르면 저전압에서는 Bit-Flip이 덜 발생해야 합니다.

## 이론적 배경

### 전압과 Bit-Flip 관계
- **정상 전압**: Bit-Flip 발생 가능
- **저전압**: 메모리 셀 안정성 증가 → Bit-Flip 감소 예상
- **고전압**: Bit-Flip 증가 가능 (하지만 위험하므로 테스트 안함)

### 라즈베리파이 전압 설정
- `over_voltage=0`: 기본 전압 (약 0.85V)
- `over_voltage=-4`: 저전압 (약 0.80V)
- `over_voltage=4`: 고전압 (약 0.90V) - 위험!

## 수집할 데이터

### 1. LowVolt + Attack
- 저전압 환경
- RowHammer 공격 실행
- 예상: Bit-Flip 감소

### 2. LowVolt + Benign
- 저전압 환경
- 메모리 작업만 (공격 없음)
- 예상: Bit-Flip 없음 (원래도 없음)

## 사용 방법

### 단계 1: 저전압 설정

```bash
cd rowhammer
sudo ./set_voltage.sh
```

입력 예시:
```
>> -4
```

재부팅:
```bash
sudo reboot
```

### 단계 2: 전압 확인

재부팅 후:
```bash
vcgencmd measure_volts core
# 출력: volt=0.8000V (정상 전압보다 낮아야 함)
```

### 단계 3: 데이터 수집

```bash
cd rowhammer
sudo ./run_lowvolt_experiments.sh
```

옵션 선택:
- 1: LowVolt + Attack만
- 2: LowVolt + Benign만
- 3: 둘 다 순차 실행 (권장)

### 단계 4: 전압 복구

실험 완료 후:
```bash
sudo ./set_voltage.sh
# 입력: 0 (기본값)
sudo reboot
```

## 출력 파일

- `lowvolt_attack.csv`: LowVolt + Attack 데이터
- `lowvolt_benign.csv`: LowVolt + Benign 데이터

## 예상 결과

### Bit-Flip 비교 (예상)
```
Normal Voltage + Attack:  FlipCount = 100+
Low Voltage + Attack:     FlipCount = 50- (감소 예상)
Low Voltage + Benign:     FlipCount = 0
```

### HPC 메트릭
- Cache-miss, Page-fault 등은 전압과 무관하게 유사할 것으로 예상
- 주요 차이는 FlipCount

## 전압 설정 권장값

### 안전한 범위
- `over_voltage=-2`: 약간 낮춤 (0.825V)
- `over_voltage=-4`: 저전압 (0.80V) - 권장
- `over_voltage=-6`: 매우 낮음 (0.775V) - 부팅 실패 가능

### 테스트 순서
1. `-2`로 시작 (안전)
2. 정상 작동 확인
3. `-4`로 진행 (권장)
4. 필요시 `-6` (주의!)

## 주의사항

### 1. 부팅 실패 위험
- 전압이 너무 낮으면 부팅 안될 수 있음
- SD 카드를 다른 컴퓨터에 연결해서 config.txt 수정 필요

### 2. 안정성
- 저전압에서는 시스템이 불안정할 수 있음
- 실험 중 크래시 가능성 있음

### 3. 온도
- 저전압에서는 발열이 적음
- Hot 모드 필요 없음 (상온에서만 테스트)

### 4. 복구 방법
부팅 실패 시:
1. SD 카드를 Mac/PC에 연결
2. `/boot/firmware/config.txt` 또는 `/boot/config.txt` 열기
3. `over_voltage=-4` 줄 삭제 또는 `over_voltage=0`으로 변경
4. SD 카드를 라즈베리파이에 다시 삽입
5. 부팅

## 데이터 수집 현황

### 완료
- ✅ Normal + Attack (normal.csv)
- ✅ Hot + Attack (hot.csv)
- ✅ Benign + Normal (benign_normal.csv)
- ✅ Benign + Hot (benign_hot.csv)
- ✅ Idle + Normal (idle_normal.csv)
- ✅ Idle + Hot (idle_hot.csv)

### 진행 중
- 🔄 LowVolt + Attack (lowvolt_attack.csv)
- 🔄 LowVolt + Benign (lowvolt_benign.csv)

## 비교 분석 예시

실험 완료 후 비교:
```python
import pandas as pd

normal_attack = pd.read_csv('normal.csv')
lowvolt_attack = pd.read_csv('lowvolt_attack.csv')

print(f"Normal Voltage Flips: {normal_attack['FlipCount'].sum()}")
print(f"Low Voltage Flips: {lowvolt_attack['FlipCount'].sum()}")
print(f"Reduction: {(1 - lowvolt_attack['FlipCount'].sum() / normal_attack['FlipCount'].sum()) * 100:.1f}%")
```

## 문제 해결

### 전압이 변경 안됨
```bash
# config.txt 확인
cat /boot/firmware/config.txt | grep over_voltage

# 수동 편집
sudo nano /boot/firmware/config.txt
# over_voltage=-4 추가
# Ctrl+X, Y, Enter

sudo reboot
```

### 부팅 후 전압 확인
```bash
vcgencmd measure_volts core
vcgencmd get_config over_voltage
```

### 실험 중 크래시
- 정상입니다 (저전압 불안정)
- 전압을 -2로 올려서 재시도
- 또는 정상 전압으로 복구

## 참고 자료

- 라즈베리파이 공식 문서: https://www.raspberrypi.com/documentation/computers/config_txt.html#overclocking-options
- over_voltage 범위: -16 ~ 8 (하지만 -6 ~ 6 권장)
- 1 단위 = 약 0.025V
