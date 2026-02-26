## ver1.0

- Attack : Rowhammer 공격 실행
- Benign : 정상 메모리 작업 - 공격의도 없이 메모리 순차 읽고쓰기
- Idle : 아무것도 안함 

---


## ver2.0

- Attack : mibench(susan/백그) + Rowhammer 공격 실행 / 90초 수집
- Benign : mibench(susan/백그) + 정상 메모리 작업 - 공격의도 없이 메모리 순차 읽고쓰기 / 60초 수집
- Idle : mibench(susan/백그) + 아무것도 안함 / 60초 수집 

- LowVoltage : -6  / 1,10V
- NormalVoltage : 0 / 1.25V
- Hot : 80도 언저리
- NormalTemp : 40-55도 사이


---ㅌ
---

## 설치 및 실행

### 1. 파일 전송
```bash
# 로컬에서
scp -r rowhammer/ ana@[파이IP]:~/ana/rowhammer4/
```

### 2. RowHammer 컴파일
```bash
cd ~/ana/rowhammer4
make clean
make
```

### 3. MiBench 컴파일
```bash
chmod +x compile_mibench.sh
sudo ./compile_mibench.sh
```

### 4. 권한 설정
```bash
chmod +x *.sh *.py
```

### 5. 전압 확인
```bash
vcgencmd get_config over_voltage  # 0이어야 함
vcgencmd measure_volts core       # 1.25V 정도
vcgencmd measure_temp              # 40-50°C 정도
```

### 6. Normal Voltage 실험 (약 8시간)
```bash
screen -S experiment
sudo ./run_normal_voltage.sh
# Ctrl+A, D로 detach
# screen -r experiment로 재접속
```

### 7. 전압 변경 및 재부팅
```bash
./set_voltage.sh
# -6 입력
sudo reboot
```

### 8. Low Voltage 실험 (약 8시간)
```bash
screen -S experiment2
sudo ./run_low_voltage.sh
```

---

## 주의사항

### 실험 중
- 최소 8시간 이상 시간 확보
- 전원 끊기지 않도록 주의
- SSH 끊겨도 screen 세션은 유지됨

### 저전압 실험
- 와이파이 불안정할 수 있음
- 모니터 연결해야할수도..

### 온도 관리
- Normal Temp 실험: 55°C 초과 시 자동 대기
- Hot Temp 실험: 80°C까지 가열 후 시작

---

## 결과 확인

```bash
# 생성된 파일 확인
ls -lh results_v3/Normal_Normal/
ls -lh results_v3/Normal_Hot/
ls -lh results_v3/Low_Normal/
ls -lh results_v3/Low_Hot/

# 총 60개 CSV 파일
find results_v3/ -name "*.csv" | wc -l
```

---

## low + hot 만 다시 하려면

```bash
chmod +x redo_low_hot.sh
chmod +x *.py

screen -S final
sudo ./redo_low_hot.sh
# Ctrl+A, D
```