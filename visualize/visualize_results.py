#!/usr/bin/env python3
"""
RowHammer 실험 결과 시각화
12개 CSV 파일의 주요 지표를 비교 분석
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
from pathlib import Path
import sys

# 한글 폰트 설정 (선택사항)
plt.rcParams['font.family'] = 'DejaVu Sans'
plt.rcParams['figure.figsize'] = (16, 10)
sns.set_style("whitegrid")

def load_all_data(results_dir='results'):
    """모든 CSV 파일 로드"""
    data = {}
    files = [
        'attack_normal.csv', 'attack_hot.csv', 
        'attack_lowvolt.csv', 'attack_hot_lowvolt.csv',
        'benign_normal.csv', 'benign_hot.csv',
        'benign_lowvolt.csv', 'benign_hot_lowvolt.csv',
        'idle_normal.csv', 'idle_hot.csv',
        'idle_lowvolt.csv', 'idle_hot_lowvolt.csv'
    ]
    
    for fname in files:
        fpath = Path(results_dir) / fname
        if fpath.exists():
            df = pd.read_csv(fpath)
            label = fname.replace('.csv', '').replace('_', ' ').title()
            data[label] = df
            print(f"[+] Loaded {fname}: {len(df)} rows")
        else:
            print(f"[!] Missing {fname}")
    
    return data

def plot_summary_statistics(data):
    """주요 통계 요약"""
    fig, axes = plt.subplots(2, 3, figsize=(18, 10))
    fig.suptitle('RowHammer Experiment Summary Statistics', fontsize=16, fontweight='bold')
    
    metrics = ['CacheMiss', 'CacheRef', 'PageFault', 'BranchMiss', 'FlipCount', 'Temp']
    
    for idx, metric in enumerate(metrics):
        ax = axes[idx // 3, idx % 3]
        
        labels = []
        values = []
        colors = []
        
        for name, df in sorted(data.items()):
            if metric in df.columns:
                labels.append(name.replace(' ', '\n'))
                
                if metric == 'FlipCount':
                    values.append(df[metric].sum())  # 총합
                else:
                    values.append(df[metric].mean())  # 평균
                
                # 색상 구분
                if 'Attack' in name:
                    colors.append('red')
                elif 'Benign' in name:
                    colors.append('blue')
                else:
                    colors.append('green')
        
        bars = ax.bar(range(len(labels)), values, color=colors, alpha=0.7)
        ax.set_xticks(range(len(labels)))
        ax.set_xticklabels(labels, rotation=45, ha='right', fontsize=8)
        
        title = f'{metric} (Total)' if metric == 'FlipCount' else f'{metric} (Mean)'
        ax.set_title(title, fontweight='bold')
        ax.set_ylabel('Count' if metric != 'Temp' else '°C')
        ax.grid(axis='y', alpha=0.3)
        
        # 값 표시
        for bar in bars:
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height,
                   f'{int(height)}' if metric != 'Temp' else f'{height:.1f}',
                   ha='center', va='bottom', fontsize=7)
    
    plt.tight_layout()
    plt.savefig('summary_statistics.png', dpi=300, bbox_inches='tight')
    print("[+] Saved: summary_statistics.png")
    plt.close()

def plot_time_series(data):
    """시계열 데이터 비교"""
    fig, axes = plt.subplots(3, 1, figsize=(16, 12))
    fig.suptitle('Time Series Comparison', fontsize=16, fontweight='bold')
    
    # Attack 조건만 선택
    attack_data = {k: v for k, v in data.items() if 'Attack' in k}
    
    metrics = ['CacheMiss', 'FlipCount', 'Temp']
    titles = ['Cache Miss Rate Over Time', 'Bit-Flip Count Over Time', 'Temperature Over Time']
    
    for idx, (metric, title) in enumerate(zip(metrics, titles)):
        ax = axes[idx]
        
        for name, df in sorted(attack_data.items()):
            if metric in df.columns:
                # 시간 축 생성 (100ms 간격)
                time = np.arange(len(df)) * 0.1
                ax.plot(time, df[metric], label=name, linewidth=1.5, alpha=0.8)
        
        ax.set_title(title, fontweight='bold')
        ax.set_xlabel('Time (seconds)')
        ax.set_ylabel('Count' if metric != 'Temp' else '°C')
        ax.legend(loc='best', fontsize=9)
        ax.grid(alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('time_series.png', dpi=300, bbox_inches='tight')
    print("[+] Saved: time_series.png")
    plt.close()

def plot_heatmap_comparison(data):
    """히트맵으로 조건별 비교"""
    # 데이터 준비
    conditions = []
    metrics_data = {
        'CacheMiss': [],
        'CacheRef': [],
        'PageFault': [],
        'BranchMiss': [],
        'FlipCount': [],
        'Temp': []
    }
    
    for name, df in sorted(data.items()):
        conditions.append(name.replace(' ', '\n'))
        for metric in metrics_data.keys():
            if metric in df.columns:
                if metric == 'FlipCount':
                    metrics_data[metric].append(df[metric].sum())
                else:
                    metrics_data[metric].append(df[metric].mean())
            else:
                metrics_data[metric].append(0)
    
    # 정규화 (0-1 스케일)
    heatmap_data = []
    metric_names = []
    for metric, values in metrics_data.items():
        if max(values) > 0:
            normalized = [v / max(values) for v in values]
            heatmap_data.append(normalized)
            metric_names.append(metric)
    
    # 히트맵 생성
    fig, ax = plt.subplots(figsize=(14, 6))
    im = ax.imshow(heatmap_data, cmap='YlOrRd', aspect='auto')
    
    ax.set_xticks(range(len(conditions)))
    ax.set_yticks(range(len(metric_names)))
    ax.set_xticklabels(conditions, rotation=45, ha='right', fontsize=9)
    ax.set_yticklabels(metric_names, fontsize=10)
    
    # 값 표시
    for i in range(len(metric_names)):
        for j in range(len(conditions)):
            text = ax.text(j, i, f'{heatmap_data[i][j]:.2f}',
                          ha="center", va="center", color="black", fontsize=8)
    
    ax.set_title('Normalized Metrics Heatmap (0=Min, 1=Max)', fontweight='bold', fontsize=14)
    plt.colorbar(im, ax=ax, label='Normalized Value')
    plt.tight_layout()
    plt.savefig('heatmap_comparison.png', dpi=300, bbox_inches='tight')
    print("[+] Saved: heatmap_comparison.png")
    plt.close()

def plot_workload_comparison(data):
    """Workload별 비교 (Attack vs Benign vs Idle)"""
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    fig.suptitle('Workload Type Comparison', fontsize=16, fontweight='bold')
    
    # 조건별 그룹화
    workloads = {'Attack': [], 'Benign': [], 'Idle': []}
    for name, df in data.items():
        for wl in workloads.keys():
            if wl in name:
                workloads[wl].append((name, df))
    
    metrics = ['CacheMiss', 'PageFault', 'FlipCount', 'Temp']
    
    for idx, metric in enumerate(metrics):
        ax = axes[idx // 2, idx % 2]
        
        x_pos = 0
        xticks = []
        xlabels = []
        
        for wl_name, wl_data in workloads.items():
            for name, df in wl_data:
                if metric in df.columns:
                    value = df[metric].sum() if metric == 'FlipCount' else df[metric].mean()
                    
                    color = 'red' if 'Attack' in name else ('blue' if 'Benign' in name else 'green')
                    alpha = 0.5 if 'Hot' in name else 0.8
                    
                    bar = ax.bar(x_pos, value, color=color, alpha=alpha, width=0.8)
                    xticks.append(x_pos)
                    xlabels.append(name.split()[-1])  # 마지막 단어만
                    
                    # 값 표시
                    ax.text(x_pos, value, f'{int(value)}' if metric != 'Temp' else f'{value:.1f}',
                           ha='center', va='bottom', fontsize=7)
                    
                    x_pos += 1
            x_pos += 0.5  # 그룹 간 간격
        
        ax.set_xticks(xticks)
        ax.set_xticklabels(xlabels, rotation=45, ha='right', fontsize=8)
        ax.set_title(f'{metric} by Workload', fontweight='bold')
        ax.set_ylabel('Count' if metric != 'Temp' else '°C')
        ax.grid(axis='y', alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('workload_comparison.png', dpi=300, bbox_inches='tight')
    print("[+] Saved: workload_comparison.png")
    plt.close()

def generate_report(data):
    """텍스트 리포트 생성"""
    report = []
    report.append("=" * 80)
    report.append("RowHammer Experiment Analysis Report")
    report.append("=" * 80)
    report.append("")
    
    for name, df in sorted(data.items()):
        report.append(f"\n[{name}]")
        report.append(f"  Samples: {len(df)}")
        report.append(f"  Duration: {len(df) * 0.1:.1f} seconds")
        report.append(f"  Avg Temp: {df['Temp'].mean():.2f}°C")
        report.append(f"  Avg Voltage: {df['CoreVolt'].mean():.4f}V")
        report.append(f"  Total Bit-Flips: {df['FlipCount'].sum()}")
        report.append(f"  Avg Cache Miss: {df['CacheMiss'].mean():.0f}")
        report.append(f"  Avg Page Fault: {df['PageFault'].mean():.2f}")
        report.append("-" * 80)
    
    report_text = "\n".join(report)
    
    with open('analysis_report.txt', 'w') as f:
        f.write(report_text)
    
    print("\n" + report_text)
    print("\n[+] Saved: analysis_report.txt")

def main():
    print("=" * 80)
    print("RowHammer Experiment Visualization")
    print("=" * 80)
    print()
    
    # 데이터 로드
    results_dir = sys.argv[1] if len(sys.argv) > 1 else 'results'
    data = load_all_data(results_dir)
    
    if not data:
        print("[!] No data found. Check results directory.")
        return
    
    print(f"\n[*] Loaded {len(data)} datasets")
    print("[*] Generating visualizations...")
    print()
    
    # 시각화 생성
    plot_summary_statistics(data)
    plot_time_series(data)
    plot_heatmap_comparison(data)
    plot_workload_comparison(data)
    generate_report(data)
    
    print()
    print("=" * 80)
    print("Visualization Complete!")
    print("=" * 80)
    print("\nGenerated files:")
    print("  - summary_statistics.png")
    print("  - time_series.png")
    print("  - heatmap_comparison.png")
    print("  - workload_comparison.png")
    print("  - analysis_report.txt")

if __name__ == "__main__":
    main()
