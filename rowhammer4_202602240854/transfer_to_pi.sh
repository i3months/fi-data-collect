#!/bin/bash
# 라즈베리 파이로 파일 전송 스크립트

echo "========================================"
echo "라즈베리 파이로 파일 전송"
echo "========================================"
echo ""

# 라즈베리 파이 정보 입력
read -p "라즈베리 파이 IP 주소 (예: 192.168.1.100): " PI_IP
read -p "라즈베리 파이 사용자명 (기본: pi): " PI_USER
PI_USER=${PI_USER:-pi}

echo ""
echo "[*] 전송 대상: $PI_USER@$PI_IP"
echo ""

# 전송할 파일 목록
FILES=(
    "collect_cycle.py"
    "recollect_hot_only.sh"
    "recollect_hot_normal_only.sh"
    "recollect_hot_low_only.sh"
    "test_hot_collection.sh"
    "README_HOT_RECOLLECT.md"
    "CHANGES.md"
    "QUICK_START.md"
)

echo "[*] 전송할 파일:"
for file in "${FILES[@]}"; do
    echo "    - $file"
done
echo ""

read -p "계속하시겠습니까? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    exit 0
fi

echo ""
echo "[*] 파일 전송 중..."
echo ""

# 라즈베리 파이에 디렉토리 생성
ssh "$PI_USER@$PI_IP" "mkdir -p ~/rowhammer4_202602240854"

# 파일 전송
for file in "${FILES[@]}"; do
    echo "  전송: $file"
    scp "$file" "$PI_USER@$PI_IP:~/rowhammer4_202602240854/"
done

# 실행 권한 부여
echo ""
echo "[*] 실행 권한 설정..."
ssh "$PI_USER@$PI_IP" "chmod +x ~/rowhammer4_202602240854/*.sh"

echo ""
echo "========================================"
echo "전송 완료!"
echo "========================================"
echo ""
echo "다음 단계:"
echo "  1. 라즈베리 파이 접속:"
echo "     ssh $PI_USER@$PI_IP"
echo ""
echo "  2. 디렉토리 이동:"
echo "     cd ~/rowhammer4_202602240854"
echo ""
echo "  3. 테스트 실행:"
echo "     ./test_hot_collection.sh"
echo ""
echo "  4. 전체 수집:"
echo "     ./recollect_hot_normal_only.sh  # Normal Voltage"
echo "     또는"
echo "     ./recollect_hot_low_only.sh     # Low Voltage"
echo ""
