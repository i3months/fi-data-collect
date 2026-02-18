# Benign 워크로드 데이터 수집 가이드

## 개요
RowHammer 공격 없이 메모리 집약적 작업만 수행하면서 HPC 데이터를 수집합니다.
오탐(False Positive) 방지를 위한 베이스라인 데이터 수집용입니다.

## 메모리 작업 구현

### benign_workload.c
- RowHammer와 유사한 메모리 접근 패턴 사용
- 256MB 메모리 할당 (rowhammer.c와 동일)
- 반복적인 메모리 읽기/쓰기 수행
- 공격 패턴(cache flush, hammering)은 제외
- 단순히 정상적인 메모리 집약적 작업만 수행

### 차이점
| 항목 | RowHammer (rowhammer.c) | Benign (benign_workload.c) |
|------|------------------------|---------------------------|
| 메모리 할당 | 256MB | 256MB (동일) |
| 메모리 접근 | Cache flush + Hammering | 일반 읽기/쓰기 |
| 목적 | Bit-Flip 유도 | 정상 메모리 작업 |
| Bit-Flip | 발생 가능 | 발생 안함 |

## 데이터 수집 형태

### collect_benign.py
기존 `collect_data.py`와 동일한 구조:
- Perf 이벤트: cache-misses, cache-references, page-faults, branch-misses
- 샘플링 간격: 100ms
- CSV 포맷: 동일 (FlipCount는 항상 0)
- 온도/전압 모니터링: 동일

### CSV 출력 형식
```csv
Timestamp_ns,Label,Temp,CoreVolt,CacheMiss,CacheRef,PageFault,BranchMiss,FlipCount
1234567890,Benign_Normal,45.2,0.85,1234,5678,10,234,0
```

## 사용 방법

### 1. 컴파일
```bash
cd rowhammer
make
```

### 2. 실험 실행

#### 방법 A: 대화형 스크립트 (권장)
```bash
sudo ./run_benign_experiments.sh
```
- 옵션 1: Benign + Normal만
- 옵션 2: Benign + Hot만
- 옵션 3: 둘 다 순차 실행 (120초 쿨다운 포함)

#### 방법 B: 개별 실행
```bash
# Benign + Normal (상온)
sudo python3 collect_benign.py "Benign_Normal" "benign_normal.csv"

# Benign + Hot (고온)
sudo python3 collect_benign.py "Benign_Hot" "benign_hot.csv" --hot
```

## 온도 관리

### Hot 모드 동작
1. stress-ng로 CPU 4코어 풀로드
2. 80°C 도달까지 대기 (실시간 온도 표시)
3. **60초 추가 대기** (온도 안정화, 실시간 온도 표시)
4. 실험 시작
5. 실험 중에도 stress-ng 계속 실행 (온도 유지)

### 예상 소요 시간
- 상온(~40°C) → 80°C: 약 3-5분
- 온도 안정화: 60초
- 실험 시간: 60초 (기본값)
- **쿨다운: 180초 (3분)** - 순차 실행 시

### 온도 모니터링
```bash
# 실시간 온도 확인
watch -n 1 'echo "scale=2; $(cat /sys/class/thermal/thermal_zone0/temp) / 1000" | bc'
```

### 권장 사항
- 연속 실험 시 최소 3분 쿨다운 권장
- Hot 실험 후 충분히 식힌 후 다음 실험 진행
- 라즈베리파이 케이스가 있다면 열기 권장

## 출력 파일

- `benign_normal.csv`: Benign + Normal 데이터
- `benign_hot.csv`: Benign + Hot 데이터

## 주의사항

1. **Root 권한 필요**: perf, taskset 사용을 위해 sudo 필요
2. **온도 관리**: Hot 모드는 라즈베리파이에 부담을 줄 수 있으니 주의
3. **실험 간격**: 연속 실험 시 최소 3분 쿨다운 권장 (자동 적용됨)
4. **메모리**: 256MB 여유 메모리 필요
5. **충분한 시간**: Hot 모드는 가열(3-5분) + 안정화(1분) + 실험(1분) = 약 5-7분 소요

## 기존 데이터와 비교

### 수집 완료
- ✅ Hot + Attack (hot.csv)
- ✅ Normal + Attack (normal.csv)

### 수집 예정
- 🔄 Benign + Normal (benign_normal.csv)
- 🔄 Benign + Hot (benign_hot.csv)
- ⏳ LowVolt + Attack
- ⏳ LowVolt + Benign
- ⏳ Idle + Normal
- ⏳ Idle + Hot

## 문제 해결

### benign_workload 실행 안됨
```bash
make clean
make
sudo chmod +x benign_workload
```

### 온도가 안 올라감
- stress-ng 설치 확인: `sudo apt install stress-ng`
- 목표 온도 낮추기: `collect_benign.py`에서 `TEMP_THRESHOLD` 수정

### Perf 권한 오류
```bash
echo -1 | sudo tee /proc/sys/kernel/perf_event_paranoid
```
