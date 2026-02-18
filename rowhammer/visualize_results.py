import pandas as pd
import matplotlib.pyplot as plt
import sys
import os

def visualize(file_paths):
    if not file_paths:
        print("Usage: python3 visualize_results.py <file1.csv> <file2.csv> ...")
        return

    # 데이터 로드 및 통합
    df_list = []
    for path in file_paths:
        if os.path.exists(path):
            temp_df = pd.read_csv(path)
            # 나노초 타임스탬프를 초 단위 상대 시간으로 변환 (보기 편하게)
            start_ts = temp_df['Timestamp_ns'].min()
            temp_df['Time_sec'] = (temp_df['Timestamp_ns'] - start_ts) / 1e9
            df_list.append(temp_df)
        else:
            print(f"[!] File not found: {path}")

    if not df_list:
        return

    # 그래프 설정
    fig, axes = plt.subplots(4, 1, figsize=(12, 20), sharex=False)
    plt.subplots_adjust(hspace=0.4)

    # 1. 온도 추이 (Temperature Trend)
    for df in df_list:
        label = df['Label'].iloc[0]
        axes[0].plot(df['Time_sec'], df['Temp'], label=f"Temp ({label})")
    axes[0].set_title("Temperature Trend during Experiment", fontsize=14)
    axes[0].set_ylabel("Temperature (°C)")
    axes[0].legend()
    axes[0].grid(True, linestyle='--', alpha=0.7)

    # 2. 비트 플립 발생 현황 (Bit Flip Count)
    for df in df_list:
        label = df['Label'].iloc[0]
        axes[1].plot(df['Time_sec'], df['FlipCount'], label=f"Flips ({label})")
    axes[1].set_title("Bit Flip Count per 100ms Interval", fontsize=14)
    axes[1].set_ylabel("Number of Flips")
    axes[1].legend()
    axes[1].grid(True, linestyle='--', alpha=0.7)

    # 3. 캐시 미스 횟수 비교 (Cache Misses Comparison)
    for df in df_list:
        label = df['Label'].iloc[0]
        axes[2].plot(df['Time_sec'], df['CacheMiss'], label=f"Cache Misses ({label})")
    
    axes[2].set_title("Cache Misses Trend across Experiments", fontsize=14)
    axes[2].set_ylabel("Cache Misses")
    axes[2].legend()
    axes[2].grid(True, linestyle='--', alpha=0.7)

    # 4. 전압 추이 (Voltage Trend)
    for df in df_list:
        label = df['Label'].iloc[0]
        # CoreVolt 컬럼이 없으면 이전 버전 호환을 위해 Volt 컬럼 시도
        volt_col = 'CoreVolt' if 'CoreVolt' in df.columns else 'Volt'
        if volt_col in df.columns:
            axes[3].plot(df['Time_sec'], df[volt_col], label=f"Voltage ({label})")
    
    axes[3].set_title("CPU Core Voltage Trend during Experiment", fontsize=14)
    axes[3].set_xlabel("Time (sec)")
    axes[3].set_ylabel("Voltage (V)")
    axes[3].legend()
    axes[3].grid(True, linestyle='--', alpha=0.7)

    # 결과 요약 (Total Flips Comparison)
    summary_data = {df['Label'].iloc[0]: df['FlipCount'].sum() for df in df_list}
    print("\n=== Experiment Summary ===")
    for lbl, total in summary_data.items():
        df = next(d for d in df_list if d['Label'].iloc[0] == lbl)
        avg_temp = df['Temp'].mean()
        volt_col = 'CoreVolt' if 'CoreVolt' in df.columns else 'Volt'
        avg_volt = df[volt_col].mean() if volt_col in df.columns else 0.0
        print(f"Label: {lbl:15} | Total Flips: {total:8d} | Avg Temp: {avg_temp:.2f}°C | Avg Volt: {avg_volt:.4f}V")

    # 그래프 저장 및 출력
    output_img = "experiment_visualization.png"
    plt.savefig(output_img)
    print(f"\n[*] Visualization saved to {output_img}")
    
    # 환경에 따라 창 띄우기 (GUI 지원 시)
    try:
        plt.show()
    except:
        print("[!] Could not display plot window (Headless environment). Check the PNG file.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        # 파일이 지정되지 않은 경우 기본 파일명 시도
        default_files = ["experiment_data_Normal.csv", "experiment_data_Hot.csv"]
        visualize([f for f in default_files if os.path.exists(f)])
    else:
        visualize(sys.argv[1:])
