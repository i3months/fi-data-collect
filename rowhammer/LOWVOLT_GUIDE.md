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
