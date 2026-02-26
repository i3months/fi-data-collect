#!/usr/bin/env python3
"""
RowHammer 실험 결과 시각화
45개 CSV 파일 분석 및 시각화
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')

# 한글 폰트 설정
plt.rcParams['font.family'] = 'DejaVu Sans'
plt.rcParams['axes.unicode_minus'] = False

# 스타일 설정
sns.set_style("whitegrid")
sns.set_palette("husl")

def load_all_data(base_path='rowhammer4/results_02240615'):
    """모든 CSV 파일 로드"""
    all_data = []
    
    folders = ['Normal_Normal', 'Normal_Hot', 'Low_Normal', 'Low_Hot']
    
    for folder in folders:
        folder_path = Path(base_path) / folder
        if not folder_path.exists():
            continue
            
        for csv_file in folder_path.glob('*.csv'):
            try:
                df = pd.read_csv(csv_file)
                
                # 메타데이터 추가
                parts = folder.split('_')
                df['Voltage'] = parts[0]  # Normal or Low
                df['Temperature'] = parts[1]  # Normal or Hot
                df['Filename'] = csv_file.name
                
                all_data.append(df)
                print(f"✓ Loaded: {csv_file.name} ({len(df)} rows)")
            except Exception as e:
                print(f"✗ Error loading {csv_file.name}: {e}")
    
    if not all_data:
        raise ValueError("No data loaded!")
    
    combined = pd.concat(all_data, ignore_index=True)
    print(f"\n총 {len(combined):,} 샘플 로드됨")
    return combined

def plot_overview(df):
    """전체 데이터 개요"""
    fig, axes = plt.subplots(2, 2, figsize=(15, 10))
    fig.suptitle('RowHammer Experiment Overview (60 Files)', fontsize=16, fontweight='bold')
    
    # 1. 파일 개수
    file_counts = df.groupby(['Voltage', 'Temperature', 'Label']).size().unstack(fill_value=0)
    file_counts.plot(kind='bar', ax=axes[0, 0], stacked=True)
    axes[0, 0].set_title('Files by Condition')
    axes[0, 0].set_xlabel('Voltage_Temperature')
    axes[0, 0].set_ylabel('Number of Files')
    axes[0, 0].legend(title='Workload')
    axes[0, 0].tick_params(axis='x', rotation=45)
    
    # 2. 샘플 개수
    sample_counts = df.groupby(['Voltage', 'Temperature']).size()
    sample_counts.plot(kind='bar', ax=axes[0, 1], color='skyblue')
    axes[0, 1].set_title('Samples by Condition')
    axes[0, 1].set_xlabel('Voltage_Temperature')
    axes[0, 1].set_ylabel('Number of Samples')
    axes[0, 1].tick_params(axis='x', rotation=45)
    
    # 3. 온도 분포
    for label in df['Label'].unique():
        subset = df[df['Label'] == label]
        axes[1, 0].hist(subset['Temp'], alpha=0.5, label=label, bins=30)
    axes[1, 0].set_title('Temperature Distribution')
    axes[1, 0].set_xlabel('Temperature (°C)')
    axes[1, 0].set_ylabel('Frequency')
    axes[1, 0].legend()
    
    # 4. 전압 분포
    for label in df['Label'].unique():
        subset = df[df['Label'] == label]
        axes[1, 1].hist(subset['CoreVolt'], alpha=0.5, label=label, bins=30)
    axes[1, 1].set_title('Voltage Distribution')
    axes[1, 1].set_xlabel('Core Voltage (V)')
    axes[1, 1].set_ylabel('Frequency')
    axes[1, 1].legend()
    
    plt.tight_layout()
    plt.savefig('overview.png', dpi=300, bbox_inches='tight')
    print("✓ Saved: overview.png")
    plt.close()

def plot_hpc_comparison(df):
    """HPC 메트릭 비교"""
    fig, axes = plt.subplots(2, 2, figsize=(15, 10))
    fig.suptitle('HPC Metrics Comparison', fontsize=16, fontweight='bold')
    
    metrics = ['CacheMiss', 'CacheRef', 'PageFault', 'BranchMiss']
    
    for idx, metric in enumerate(metrics):
        ax = axes[idx // 2, idx % 2]
        
        # Attack vs Benign vs Idle
        data_to_plot = []
        labels_to_plot = []
        
        for label in ['Attack', 'Benign', 'Idle']:
            label_data = df[df['Label'].str.startswith(label)]
            if len(label_data) > 0:
                data_to_plot.append(label_data[metric].dropna())
                labels_to_plot.append(label)
        
        if data_to_plot:
            bp = ax.boxplot(data_to_plot, labels=labels_to_plot, patch_artist=True)
            for patch, color in zip(bp['boxes'], ['red', 'blue', 'green']):
                patch.set_facecolor(color)
                patch.set_alpha(0.6)
        
        ax.set_title(f'{metric} Distribution')
        ax.set_ylabel(metric)
        ax.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('hpc_comparison.png', dpi=300, bbox_inches='tight')
    print("✓ Saved: hpc_comparison.png")
    plt.close()

def plot_time_series(df):
    """시계열 분석"""
    fig, axes = plt.subplots(2, 2, figsize=(15, 10))
    fig.suptitle('Time Series Analysis (Sample File)', fontsize=16, fontweight='bold')
    
    # Attack_susan 파일 하나만 샘플로
    sample = df[df['Filename'] == 'Attack_susan.csv'].head(1000)
    
    if len(sample) == 0:
        print("⚠ No Attack_susan.csv found for time series")
        return
    
    # 1. Cache Miss over time
    axes[0, 0].plot(sample['CycleTime_ms'], sample['CacheMiss'], alpha=0.7)
    axes[0, 0].set_title('Cache Miss over Time')
    axes[0, 0].set_xlabel('Time (ms)')
    axes[0, 0].set_ylabel('Cache Miss')
    axes[0, 0].grid(True, alpha=0.3)
    
    # 2. Temperature over time
    axes[0, 1].plot(sample['CycleTime_ms'], sample['Temp'], color='red', alpha=0.7)
    axes[0, 1].set_title('Temperature over Time')
    axes[0, 1].set_xlabel('Time (ms)')
    axes[0, 1].set_ylabel('Temperature (°C)')
    axes[0, 1].grid(True, alpha=0.3)
    
    # 3. Page Fault over time
    axes[1, 0].plot(sample['CycleTime_ms'], sample['PageFault'], color='green', alpha=0.7)
    axes[1, 0].set_title('Page Fault over Time')
    axes[1, 0].set_xlabel('Time (ms)')
    axes[1, 0].set_ylabel('Page Fault')
    axes[1, 0].grid(True, alpha=0.3)
    
    # 4. Cycle별 구분
    for cycle in sample['Cycle'].unique():
        cycle_data = sample[sample['Cycle'] == cycle]
        axes[1, 1].scatter(cycle_data['CycleTime_ms'], cycle_data['CacheMiss'], 
                          label=f'Cycle {cycle}', alpha=0.5, s=10)
    axes[1, 1].set_title('Cache Miss by Cycle')
    axes[1, 1].set_xlabel('Time (ms)')
    axes[1, 1].set_ylabel('Cache Miss')
    axes[1, 1].legend()
    axes[1, 1].grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('time_series.png', dpi=300, bbox_inches='tight')
    print("✓ Saved: time_series.png")
    plt.close()

def plot_correlation(df):
    """상관관계 분석"""
    fig, axes = plt.subplots(1, 2, figsize=(15, 6))
    fig.suptitle('Feature Correlation Analysis', fontsize=16, fontweight='bold')
    
    # Attack 데이터만
    attack_data = df[df['Label'].str.startswith('Attack')]
    benign_data = df[df['Label'].str.startswith('Benign')]
    
    features = ['CacheMiss', 'CacheRef', 'PageFault', 'BranchMiss', 'Temp']
    
    # Attack 상관관계
    if len(attack_data) > 0:
        corr_attack = attack_data[features].corr()
        sns.heatmap(corr_attack, annot=True, fmt='.2f', cmap='coolwarm', 
                   center=0, ax=axes[0], square=True)
        axes[0].set_title('Attack Workload Correlation')
    
    # Benign 상관관계
    if len(benign_data) > 0:
        corr_benign = benign_data[features].corr()
        sns.heatmap(corr_benign, annot=True, fmt='.2f', cmap='coolwarm', 
                   center=0, ax=axes[1], square=True)
        axes[1].set_title('Benign Workload Correlation')
    
    plt.tight_layout()
    plt.savefig('correlation.png', dpi=300, bbox_inches='tight')
    print("✓ Saved: correlation.png")
    plt.close()

def generate_summary_stats(df):
    """통계 요약"""
    print("\n" + "="*60)
    print("데이터 요약 통계")
    print("="*60)
    
    print(f"\n총 샘플 수: {len(df):,}")
    print(f"총 파일 수: {df['Filename'].nunique()}")
    
    print("\n[Workload별 분포]")
    print(df['Label'].value_counts())
    
    print("\n[Voltage별 분포]")
    print(df['Voltage'].value_counts())
    
    print("\n[Temperature별 분포]")
    print(df['Temperature'].value_counts())
    
    print("\n[HPC 메트릭 통계]")
    metrics = ['CacheMiss', 'CacheRef', 'PageFault', 'BranchMiss']
    print(df[metrics].describe())
    
    print("\n[온도/전압 통계]")
    print(df[['Temp', 'CoreVolt']].describe())
    
    # CSV로 저장
    summary = df.groupby(['Voltage', 'Temperature', 'Label'])[metrics + ['Temp', 'CoreVolt']].mean()
    summary.to_csv('summary_stats.csv')
    print("\n✓ Saved: summary_stats.csv")

def main():
    print("="*60)
    print("RowHammer 실험 결과 시각화")
    print("="*60)
    
    # 데이터 로드
    print("\n[1/5] 데이터 로드 중...")
    df = load_all_data()
    
    # 시각화
    print("\n[2/5] 전체 개요 생성 중...")
    plot_overview(df)
    
    print("\n[3/5] HPC 메트릭 비교 중...")
    plot_hpc_comparison(df)
    
    print("\n[4/5] 시계열 분석 중...")
    plot_time_series(df)
    
    print("\n[5/5] 상관관계 분석 중...")
    plot_correlation(df)
    
    # 통계 요약
    generate_summary_stats(df)
    
    print("\n" + "="*60)
    print("✓ 시각화 완료!")
    print("="*60)
    print("\n생성된 파일:")
    print("  - overview.png")
    print("  - hpc_comparison.png")
    print("  - time_series.png")
    print("  - correlation.png")
    print("  - summary_stats.csv")

if __name__ == "__main__":
    main()
