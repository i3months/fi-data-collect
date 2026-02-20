## ver1.0

Attack : Rowhammer 공격 실행
Benign : 정상 메모리 작업 - 공격의도 없이 메모리 순차 읽고쓰기
Idle : 아무것도 안함 

---


## ver2.0

Attack : mibench(susan/백그) + Rowhammer 공격 실행 / 90초 수집
Benign : mibench(susan/백그) + 정상 메모리 작업 - 공격의도 없이 메모리 순차 읽고쓰기 / 60초 수집
Idle : mibench(susan/백그) + 아무것도 안함 / 60초 수집 

LowVoltage : -6  / 1,10V (예정)
NormalVoltage : 0 / 1.25V
Hot : 80도 언저리
NormalTemp : 40-55도 사이


---

## ver3.0 

<수집 시간 관련>
데이터 수집 단위 : 100ms 단위로 수집 
한 번의 수집에서 수집하는 시간 : 20초 

수집 사이클을 여러 번 반복할 것. 
idle과 benign은 20초 사이클을 6번 수집
attack은 20초 사이클을 9번 수집 

사이클마다 유휴시간을 1분정도 설정할 것 

<벤치마크 관련>
최대한 다양한 벤치마크를 활용할 것 
mibench의 여러 가지 벤치마크를 사용 
susan(이미지 엣지 감지) / qsort_large / bitcount / dijkstra / sha / FFT / CRC32(CRC체크섬)

벤치마크는 한 번에 하나만 실행함 

<Rowhammer 공격 관련>
현재는 한 번 실행에 메모리를 100만번 때리고 있음
25만 정도로 줄여서 abnormal 상태를 약하게 설정할 것 (더 줄이는것도 고려. 현재의 1/100 정도로?)

벤치마크와 함께 실행할 때는 서로 다른 메모리를 바라봐도 괜찮음 -> hpc 패턴 인식이 목표 

<외부 환경 관련>
고온 : 80도
평상시 온도 : 40-50도 

저전압 : -6 (1.10V)
평상시 전압 : 0 (1.25V)

<데이터 정의>
Attack : mibench + Rowhammer
Benign : mibench only
Idle : 아무것도 안함 		

<데이터셋 수> 
고온 + 저전압 : 7 + 7 + 1
평상시온도 + 저전압 : 7 + 7 + 1
고온 + 평상시 전압 : 7 + 7 + 1
평상시온도 + 평상시 전압 : 7 + 7 + 1 

60개의 csv 파일이 생성 

---

### Rowhammer 컴파일
```
cd ~/ana/rowhammer3
make clean
make
```
### mibench 컴파일
```
chmod +x compile_mibench.sh
./compile_mibench.sh
```

### 권한설정 
```
cd ~/ana/rowhammer3
chmod +x *.sh *.py
sed -i 's/\r$//' *.sh
```

### 실험
```
screen -S experiment
cd ~/ana/rowhammer3
./run_normal_voltage.sh
```