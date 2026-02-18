#define _GNU_SOURCE
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <time.h>
#include <sys/mman.h>

// RowHammer와 유사한 메모리 접근 패턴이지만 공격은 하지 않음
// 단순히 메모리를 읽고 쓰는 작업만 수행

#define CHUNK_SIZE (256 * 1024 * 1024)  // 256MB
#define PAGE_SIZE 4096
#define ITERATIONS 1000000  // 메모리 접근 반복 횟수

int main(int argc, char **argv) {
    int duration = 60;  // 기본 60초
    if (argc > 1) duration = atoi(argv[1]);

    printf("[*] Benign Memory Workload\n");
    printf("[*] Duration: %d seconds\n", duration);
    printf("[*] Allocating %d MB of memory...\n", CHUNK_SIZE / (1024*1024));

    // 메모리 할당
    unsigned long *chunk;
    if (posix_memalign((void **)&chunk, PAGE_SIZE, CHUNK_SIZE) != 0) {
        perror("Failed to allocate memory");
        return -1;
    }

    // 초기화 (RowHammer와 동일하게 0xFF로)
    memset(chunk, 0xFF, CHUNK_SIZE);
    printf("[*] Memory initialized at %p\n", chunk);

    time_t start_time = time(NULL);
    unsigned long total_ops = 0;

    printf("[*] Starting memory-intensive workload...\n");
    
    // 메모리 집약적 작업 수행
    while (time(NULL) - start_time < duration) {
        // 메모리 전체를 순회하며 읽기/쓰기
        for (size_t i = 0; i < CHUNK_SIZE / sizeof(unsigned long); i += 1024) {
            // 읽기
            volatile unsigned long val = chunk[i];
            
            // 쓰기 (값 변경)
            chunk[i] = val ^ 0xAAAAAAAAAAAAAAAAUL;
            
            // 다시 원래 값으로
            chunk[i] = val;
        }
        
        total_ops++;
        
        // 진행상황 출력 (1초마다)
        if (total_ops % 100 == 0) {
            printf("\r[*] Running... Elapsed: %ld seconds", time(NULL) - start_time);
            fflush(stdout);
        }
    }

    printf("\n[*] Workload complete. Total operations: %lu\n", total_ops);
    
    free(chunk);
    return 0;
}
