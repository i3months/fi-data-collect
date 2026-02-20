#!/bin/bash
# MiBench 컴파일 스크립트
# 오래된 코드라 Makefile이 안 될 수 있어서 직접 컴파일

set -e

# 절대 경로로 변경
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIBENCH_DIR="$(cd "$SCRIPT_DIR/../mibench" && pwd)"

echo "========================================"
echo "MiBench 컴파일 스크립트"
echo "========================================"
echo ""
echo "MiBench 경로: $MIBENCH_DIR"
echo ""

# 1. susan
echo "[1/7] Compiling susan..."
cd "$MIBENCH_DIR/automotive/susan"
gcc -O3 -Wno-implicit-int -Wno-implicit-function-declaration -o susan susan.c -lm 2>&1 | grep -v "warning:" || true
if [ -f susan ]; then
    echo "  ✓ susan compiled successfully"
    ./susan 2>&1 | head -3
else
    echo "  ✗ susan compilation failed"
    exit 1
fi

# 2. qsort_large
echo ""
echo "[2/7] Compiling qsort_large..."
cd "$MIBENCH_DIR/automotive/qsort"
gcc -O3 -o qsort_large qsort_large.c -lm 2>&1 | grep -v "warning:" || true
if [ -f qsort_large ]; then
    echo "  ✓ qsort_large compiled successfully"
else
    echo "  ✗ qsort_large compilation failed"
    exit 1
fi

# 3. bitcount
echo ""
echo "[3/7] Compiling bitcount..."
cd "$MIBENCH_DIR/automotive/bitcount"
gcc -O3 -o bitcnts bitcnts.c bitcnt_1.c bitcnt_2.c bitcnt_3.c bitcnt_4.c bitarray.c bitstrng.c bstr_i.c 2>&1 | grep -v "warning:" || true
if [ -f bitcnts ]; then
    echo "  ✓ bitcnts compiled successfully"
else
    echo "  ✗ bitcnts compilation failed"
    exit 1
fi

# 4. dijkstra
echo ""
echo "[4/7] Compiling dijkstra..."
cd "$MIBENCH_DIR/network/dijkstra"
if [ -f dijkstra.c ]; then
    gcc -O3 -Wno-implicit-int -Wno-implicit-function-declaration -o dijkstra_small dijkstra.c 2>&1 | grep -v "warning:" || true
elif [ -f dijkstra_small.c ]; then
    gcc -O3 -Wno-implicit-int -Wno-implicit-function-declaration -o dijkstra_small dijkstra_small.c 2>&1 | grep -v "warning:" || true
else
    echo "  ✗ dijkstra source not found"
    exit 1
fi
if [ -f dijkstra_small ]; then
    echo "  ✓ dijkstra_small compiled successfully"
else
    echo "  ✗ dijkstra_small compilation failed"
    exit 1
fi

# 5. sha
echo ""
echo "[5/7] Compiling sha..."
cd "$MIBENCH_DIR/security/sha"
if [ -f sha_driver.c ]; then
    gcc -O3 -Wno-implicit-int -Wno-implicit-function-declaration -o sha sha.c sha_driver.c 2>&1 | grep -v "warning:" || true
else
    gcc -O3 -Wno-implicit-int -Wno-implicit-function-declaration -o sha sha.c 2>&1 | grep -v "warning:" || true
fi
if [ -f sha ]; then
    echo "  ✓ sha compiled successfully"
else
    echo "  ✗ sha compilation failed"
    exit 1
fi

# 6. FFT
echo ""
echo "[6/7] Compiling FFT..."
cd "$MIBENCH_DIR/telecomm/FFT"
# FFT는 여러 파일을 함께 컴파일
gcc -O3 -Wno-implicit-int -Wno-implicit-function-declaration -o fft main.c fftmisc.c fourierf.c -lm 2>&1 | grep -v "warning:" || true
if [ -f fft ]; then
    echo "  ✓ fft compiled successfully"
else
    echo "  ✗ fft compilation failed"
    exit 1
fi

# 7. CRC32
echo ""
echo "[7/7] Compiling CRC32..."
cd "$MIBENCH_DIR/telecomm/CRC32"
# CRC32는 crc_32.c에 main이 포함되어 있음
gcc -O3 -Wno-implicit-int -Wno-implicit-function-declaration -o crc crc_32.c 2>&1 | grep -v "warning:" || true
if [ -f crc ]; then
    echo "  ✓ crc compiled successfully"
else
    echo "  ✗ crc compilation failed"
    exit 1
fi

echo ""
echo "========================================"
echo "모든 벤치마크 컴파일 완료!"
echo "========================================"
echo ""
echo "컴파일된 파일:"
echo "  1. $MIBENCH_DIR/automotive/susan/susan"
echo "  2. $MIBENCH_DIR/automotive/qsort/qsort_large"
echo "  3. $MIBENCH_DIR/automotive/bitcount/bitcnts"
echo "  4. $MIBENCH_DIR/network/dijkstra/dijkstra_small"
echo "  5. $MIBENCH_DIR/security/sha/sha"
echo "  6. $MIBENCH_DIR/telecomm/FFT/fft"
echo "  7. $MIBENCH_DIR/telecomm/CRC32/crc"
echo ""
