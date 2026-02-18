# Raspberry Pi 4 RowHammer & Temperature Experiment

이 디렉토리는 Raspberry Pi 4 (BCM2711) 환경에서 RowHammer를 발생시키고, 온도 변화에 따른 비트 플립(Bit Flip) 성공률을 측정하기 위한 도구를 포함하고 있습니다.

## 1. 사전 준비 (Prerequisites)

이 코드는 Raspberry Pi 4에서 직접 컴파일하고 실행해야 합니다.
다음 패키지가 필요할 수 있습니다 (대부분 기본 설치되어 있음):
```bash
sudo apt update
sudo apt install build-essential git
```

## 2. 컴파일 방법 (Compilation)

`rowhammer_rpi4` 디렉토리로 이동한 후 `make` 명령어를 실행하세요.

```bash
cd rowhammer_rpi4
make
```
컴파일이 완료되면 `rowhammer` 실행 파일이 생성됩니다.

## 3. 실행 방법 (Usage)

RowHammer 공격은 물리 메모리 주소에 직접 접근해야 하므로 **반드시 root 권한(sudo)**으로 실행해야 합니다.

```bash
sudo ./rowhammer [Duration] [Mode] [HammerType]
```

- **Duration**: 실행 시간 (초 단위). 기본값 60초.
- **Mode**: 캐시 관리 명령어 선택.
  - `1`: DC CVAC (Clean to PoC)
  - `2`: DC CIVAC (Clean & Invalidate to PoC)
  - `3`: DC ZVA (Zero Virtual Address) - **추천 (가장 효과적일 수 있음)**
- **HammerType**: 공격 유형.
  - `1`: One-sided
  - `2`: Double-sided - **추천**
  - `3`: Half-Double (Quad Pattern) - **고급**: LPDDR4/DDR4의 보호 기법(TRR)을 우회하기 위해 2행 간격(Distance-2)의 Row를 공격합니다.

**실행 예시:**
```bash
# 2분(120초) 동안, DC ZVA 모드로, Double-sided 공격 수행
sudo ./rowhammer 120 3 2

# Half-Double 공격 수행 (TRR 우회 시도)
sudo ./rowhammer 120 3 3
```

## 4. 온도에 따른 성공률 비교 실험 가이드 (Experiment)

연구 목적(온도가 RowHammer 성공률에 미치는 영향 확인)을 위해 다음과 같은 절차로 실험을 진행하는 것을 권장합니다.

### 실험 1: 정상 온도 (Normal Temperature)
1. 라즈베리파이를 부팅하고 유휴 상태에서 충분히 식힙니다 (약 40~50도 예상).
2. 현재 온도를 확인합니다: `vcgencmd measure_temp`
3. RowHammer를 5분간 실행하고 결과를 로그로 저장합니다.
   ```bash
   sudo ./rowhammer 300 3 2 > normal_temp.csv
   ```
4. 생성된 `normal_temp.csv` 파일에서 `Total Flips` 값을 확인합니다.

### 실험 2: 고온 환경 (High Temperature)
1. CPU 부하를 주어 온도를 높입니다. `stress-ng` 등의 도구를 사용하거나, MIBench를 백그라운드에서 실행합니다.
   ```bash
   # 예: 4코어에 부하를 주어 온도 상승 (별도 터미널에서 실행)
   sudo apt install stress
   stress --cpu 4 &
   ```
2. 온도가 충분히 상승했는지 확인합니다 (60~70도 이상 권장): `vcgencmd measure_temp`
3. 온도가 유지되는 상태에서 동일하게 5분간 RowHammer를 실행합니다.
   ```bash
   sudo ./rowhammer 300 3 2 > high_temp.csv
   ```
4. 실험이 끝나면 `stress` 프로세스를 종료합니다: `killall stress`

### 5. 데이터 분석
두 CSV 파일을 비교하여 `Total Flips`의 차이를 분석합니다. Spyhammer 논문에 따르면 고온에서 비트 플립 성공률이 달라질 수 있습니다 (일반적으로 온도가 높을수록 커패시터 누설 전류가 증가하여 RowHammer에 더 취약해질 가능성이 높음).

## 주의사항
- **시스템 불안정**: RowHammer 공격은 메모리 내용을 변조하므로 시스템이 멈추거나 재부팅될 수 있습니다. 중요한 데이터가 없는 상태에서 실험하세요.

## 5. 자동화된 실험 (Automated Experiment)

복잡한 수동 절차 없이, **`run_experiment.sh`** 스크립트를 통해 각 실험 단계(`normal` 또는 `hot`)를 개별적으로 수행할 수 있습니다.
이 스크립트는 `stress-ng` 설치 및 `rowhammer` 도구 컴파일을 자동으로 처리합니다.

**사용 방법:**

1. **스크립트 권한 설정 및 수정 (최초 1회)**:
   윈도우에서 복사했을 경우 줄바꿈 문자를 수정하고 실행 권한을 부여합니다.
   ```bash
   sed -i 's/\r$//' run_experiment.sh
   chmod +x run_experiment.sh
   ```

2. **실험 실행 (Root 권한 필요)**:

   *   **정상 온도 실험 (Normal Temperature)**:
       ```bash
       sudo ./run_experiment.sh normal
       ```
       현재 온도에서 실험을 수행하고 결과를 `result_normal.csv`에 저장합니다.

   *   **고온 환경 실험 (High Temperature)**:
       ```bash
       sudo ./run_experiment.sh hot
       ```
       `stress-ng`로 CPU 온도를 84도 이상으로 높인 후 실험을 수행하고 결과를 `result_high.csv`에 저장합니다.

스크립트 내부의 `DURATION` 변수를 수정하여 실험 시간을 조절할 수 있습니다 (기본값: 120초).


...


# Phase 1: 정상 전압
sudo ./run_1_attack_normal.sh
sudo ./run_2_benign_normal.sh
sudo ./run_3_idle_normal.sh

# Phase 2: 저전압 설정
sudo ./set_voltage.sh  # -2 입력
sudo reboot

# Phase 3: 저전압 실험
sudo ./run_4_attack_lowvolt.sh
sudo ./run_5_benign_lowvolt.sh
sudo ./run_6_idle_lowvolt.sh

# Phase 4: 전압 복구
sudo ./set_voltage.sh  # 0 입력
sudo reboot
