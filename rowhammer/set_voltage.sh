#!/bin/bash

# RPi Zero 2 W 전압 조절 간편 스크립트

# 1. 설정 파일 경로 확인 (OS 버전에 따라 다름)
CONFIG_FILE="/boot/firmware/config.txt"
[ ! -f "$CONFIG_FILE" ] && CONFIG_FILE="/boot/config.txt"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[-] 에러: config.txt 파일을 찾을 수 없습니다."
    exit 1
fi

# 2. 현재 상태 표시
echo "------------------------------------------------"
echo "[*] 현재 측정 전압: $(vcgencmd measure_volts core)"
CURRENT_SETTING=$(grep "^over_voltage=" $CONFIG_FILE | cut -d= -f2)
echo "[*] 현재 설정된 over_voltage: ${CURRENT_SETTING:-0 (기본값)}"
echo "------------------------------------------------"

# 3. 새로운 값 입력 받기
echo "[?] 설정할 over_voltage 값을 입력하세요."
echo "    (권장 범위: -4 ~ 4, 최대 안전 범위: -6 ~ 6)"
read -p ">> " NEW_VAL

# 입력값 검증 (정수인지 확인)
if [[ ! "$NEW_VAL" =~ ^-?[0-9]+$ ]]; then
    echo "[-] 에러: 정수를 입력해야 합니다."
    exit 1
fi

# 위험 범위 경고
if [ "$NEW_VAL" -gt 6 ] || [ "$NEW_VAL" -lt -6 ]; then
    echo "[!] 경고: $NEW_VAL 은 위험 범위입니다. 시스템이 손상되거나 부팅되지 않을 수 있습니다."
    read -p "[?] 정말 진행하시겠습니까? (y/N): " CONFIRM
    [[ "$CONFIRM" != "y" ]] && exit 1
fi

# 4. 설정 적용
# 이미 설정이 있으면 치환, 없으면 맨 뒤에 추가
if grep -q "^over_voltage=" "$CONFIG_FILE"; then
    sudo sed -i "s/^over_voltage=.*/over_voltage=$NEW_VAL/" "$CONFIG_FILE"
else
    echo "over_voltage=$NEW_VAL" | sudo tee -a "$CONFIG_FILE" > /dev/null
fi

# 실험의 정확성을 위해 클럭 고정 옵션도 확인/추가
if ! grep -q "^force_turbo=1" "$CONFIG_FILE"; then
    echo "force_turbo=1" | sudo tee -a "$CONFIG_FILE" > /dev/null
    echo "[+] 전압 고정을 위해 force_turbo=1 옵션을 추가했습니다."
fi

echo "------------------------------------------------"
echo "[+] 설정이 완료되었습니다! (over_voltage=$NEW_VAL)"
echo "[!] 변경 사항을 적용하려면 재부팅이 필요합니다."
read -p "[?] 지금 재부팅하시겠습니까? (y/N): " REBOOT_NOW

if [[ "$REBOOT_NOW" == "y" ]]; then
    sudo reboot
fi
