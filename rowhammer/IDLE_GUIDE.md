# Idle 상태 데이터 수집 가이드

## 개요
아무 작업도 하지 않는 Idle 상태에서 HPC 데이터를 수집합니다.
완전한 베이스라인 데이터로, 정상 상태의 최소 HPC 값을 확인할 수 있습니다.

## Idle 상태란?

### Idle + Normal
- 상온 (~40-50°C)
- CPU 작업 없음
- 메모리 작업 없음
- 시스템 백그라운드 프로세스만 실행

### Idle + Hot
- 고온 (~80°C)
- **중요**: stress-ng는 다른 코어에서 계속 실행 (온도 유지)
- Core 3 (모니터링 대상)만 Idle 상태
- 온도는 80°C 근처 유지

## 다른 상태와 비교

| 상태 | 메모리 작업 | RowHammer 공격 | 온도 | 예상 HPC |
|------|------------|---------------|------|---------|
| Attack + Normal | ✅ (공격) | ✅ | 상온 | 높음 |
| Attack + Hot | ✅ (공격) | ✅ | 고온 | 매우 높음 |
| Benign + Normal | ✅ (정상) | ❌ | 상온 | 중간 |
| Benign + Hot | ✅ (정상) | ❌ | 고온 | 중간 |
| **Idle + Normal** | ❌ | ❌ | 상온 | **매우 낮음** |
| **Idle + Hot** | ❌ | ❌ | 고온 | **매우 낮음** |

## 사용 방법

### 1. 실행
```bash
cd rowhammer
sudo ./run_idle_experiments.sh
```

### 2. 개별 실행
```bash
# Idle + Normal (상온)
sudo python3 collect_idle.py "Idle_Normal" "idle_normal.csv"

# Idle + Hot (고온)
sudo python3 collect_idle.py "Idle_Hot" "idle_hot.csv" --hot
```

## Idle + Hot 동작 방식

1. stress-ng로 CPU 가열 (80°C까지, 4개 코어 모두)
2. 60초 온도 안정화
3. **stress-ng 계속 실행** (온도 유지)
4. Core 3만 모니터링 (다른 코어는 stress 실행 중)
5. Core 3은 Idle 상태 (작업 없음)
6. 온도는 80°C 근처 유지

이렇게 하면 "고온이지만 모니터링 코어는 Idle" 상태를 만들 수 있습니다.

## 출력 파일

- `idle_normal.csv`: Idle + Normal 데이터
- `idle_hot.csv`: Idle + Hot 데이터

## 예상 결과

### HPC 값 비교 (예상)
```
Attack:  CacheMiss=10000+, PageFault=100+
Benign:  CacheMiss=5000+,  PageFault=50+
Idle:    CacheMiss=100-,   PageFault=1-
```

Idle 상태는 거의 모든 HPC 메트릭이 최소값에 가까울 것입니다.

## 주의사항

1. **백그라운드 프로세스**: 완전한 Idle은 불가능 (OS 백그라운드 작업 존재)
2. **온도 유지**: Idle + Hot은 다른 코어에서 stress 실행으로 온도 유지
3. **실험 순서**: Normal → Hot 순서 권장 (쿨다운 시간 절약)
4. **다른 프로그램**: 실험 중 SSH 외 다른 작업 하지 말 것
5. **코어 분리**: Core 3만 모니터링, 다른 코어는 stress 실행 가능

## 데이터 수집 현황

### 완료
- ✅ Hot + Attack (hot.csv)
- ✅ Normal + Attack (normal.csv)
- ✅ Benign + Normal (benign_normal.csv)
- ✅ Benign + Hot (benign_hot.csv)

### 진행 중
- 🔄 Idle + Normal (idle_normal.csv)
- 🔄 Idle + Hot (idle_hot.csv)

### 예정
- ⏳ LowVolt + Attack
- ⏳ LowVolt + Benign

## 문제 해결

### HPC 값이 너무 높음
- 백그라운드 프로세스 확인: `top` 또는 `htop`
- 불필요한 서비스 중지
- 재부팅 후 바로 실험

### Idle + Hot에서 온도가 떨어짐
- 이제는 stress-ng가 계속 실행되므로 온도 유지됨
- 80°C 근처에서 유지되어야 정상
- 만약 떨어진다면 stress-ng 프로세스 확인: `ps aux | grep stress`

### 권한 오류
```bash
echo -1 | sudo tee /proc/sys/kernel/perf_event_paranoid
```
