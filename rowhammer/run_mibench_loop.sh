#!/bin/bash
# MiBench를 지정된 시간 동안 반복 실행

DURATION=${1:-90}  # 기본 90초
MIBENCH_PROG=${2:-"susan"}  # 기본 프로그램 (susan - 메모리 집약적)

# MiBench 경로 설정
MIBENCH_DIR="../mibench"

echo "[*] Running MiBench ($MIBENCH_PROG) for ${DURATION} seconds..."

START_TIME=$(date +%s)
COUNT=0

while [ $(($(date +%s) - START_TIME)) -lt $DURATION ]; do
    case $MIBENCH_PROG in
        "qsort")
            cd $MIBENCH_DIR/automotive/qsort && ./qsort_small input_small.dat > /dev/null 2>&1
            cd - > /dev/null
            ;;
        "qsort_large")
            cd $MIBENCH_DIR/automotive/qsort && ./qsort_large input_large.dat > /dev/null 2>&1
            cd - > /dev/null
            ;;
        "susan")
            cd $MIBENCH_DIR/automotive/susan && ./susan input_large.pgm output.pgm -e > /dev/null 2>&1
            cd - > /dev/null
            ;;
        "susan_small")
            cd $MIBENCH_DIR/automotive/susan && ./susan input_small.pgm output.pgm -e > /dev/null 2>&1
            cd - > /dev/null
            ;;
        "jpeg")
            cd $MIBENCH_DIR/consumer/jpeg/jpeg-6a && ./djpeg -dct int -ppm -outfile output.ppm input_large.jpg > /dev/null 2>&1
            cd - > /dev/null
            ;;
        "basicmath")
            $MIBENCH_DIR/automotive/basicmath/basicmath_small > /dev/null 2>&1
            ;;
        "bitcount")
            $MIBENCH_DIR/automotive/bitcount/bitcnts 75000 > /dev/null 2>&1
            ;;
        "sha")
            cd $MIBENCH_DIR/security/sha && ./sha input_small.asc > /dev/null 2>&1
            cd - > /dev/null
            ;;
        "dijkstra")
            cd $MIBENCH_DIR/network/dijkstra && ./dijkstra_small input.dat > /dev/null 2>&1
            cd - > /dev/null
            ;;
        "FFT")
            cd $MIBENCH_DIR/telecomm/FFT && ./fft 4 4096 > /dev/null 2>&1
            cd - > /dev/null
            ;;
        "CRC32")
            cd $MIBENCH_DIR/telecomm/CRC32 && ./crc < large.pcm > /dev/null 2>&1
            cd - > /dev/null
            ;;
        *)
            echo "[!] Unknown program: $MIBENCH_PROG"
            exit 1
            ;;
    esac
    COUNT=$((COUNT + 1))
done

echo "[*] MiBench completed. Ran $COUNT iterations in ${DURATION} seconds."
