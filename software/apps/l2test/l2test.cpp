#include <nyuzi.h>
#include <stdio.h>
#include <stdint.h>
#include <schedule.h>
#include <performance_counters.h>

void lock(int addr)
{
    asm volatile("lock s5, (%0)" : : "r" (addr) : "s5");
}

void load(int addr)
{
    asm volatile("load_32 s5, (%0)" : : "r" (addr) : "s5");
}

volatile int gThreadId = 0;

int main()
{
    uint8_t memory[3000][64];       // enough to force eviction with 8-way cache.
//    int l1hits_i, l1misses_i, l2hits_i, l2misses_i; 
//    int l1hits_f, l1misses_f, l2hits_f, l2misses_f;
//    int i;
    
    int tid = __sync_fetch_and_add(&gThreadId, 1);

    if(tid == 0) {

        lock((int)&memory[0][0]);
        lock((int)&memory[31][0]);
        lock((int)&memory[63][0]);

    }
//    lock((int)&memory[0][5]);

/*
    set_perf_counter_event(0,PERF_DCACHE_HIT);
    set_perf_counter_event(1,PERF_DCACHE_MISS);
    set_perf_counter_event(2,PERF_L2_HIT);
    set_perf_counter_event(3,PERF_L2_MISS);
#define LOCK

#ifdef LOCK
    lock((int)&memory[0][0]);
    lock((int)&memory[1][0]);
    lock((int)&memory[2][0]);
    lock((int)&memory[3][0]);
#else
    load((int)&memory[0][0]);
    load((int)&memory[1][0]);
    load((int)&memory[2][0]);
    load((int)&memory[3][0]);
#endif

    for(i=0; i<3000; i+=8) {
        memory[i][0]=i;
        memory[i+1][0]=i;
        memory[i+2][0]=i;
        memory[i+3][0]=i;
    }

//    l1hits_i= l1misses_i= l2hits_i= l2misses_i=0; 
  //  l1hits_f= l1misses_f= l2hits_f= l2misses_f=0;

    l1hits_i = read_perf_counter(0);
    l1misses_i = read_perf_counter(1);
    l2hits_i = read_perf_counter(2);
    l2misses_i = read_perf_counter(3);

    load((int)&memory[0][0]);
    load((int)&memory[1][0]);
    load((int)&memory[2][0]);
    load((int)&memory[3][0]);

    l1hits_f = read_perf_counter(0);
    l1misses_f = read_perf_counter(1);
    l2hits_f= read_perf_counter(2);
    l2misses_f = read_perf_counter(3);

#ifdef LOCK
    printf("Lock\n");
#else
    printf("No lock\n");
#endif
    
    printf("%d %d %d %d\n%d %d %d %d\n\n",
        l1hits_i, l1misses_i, l2hits_i, l2misses_i,
        l1hits_f, l1misses_f, l2hits_f, l2misses_f);

    printf("%d hits (%d + %d), %d misses (%d + %d)\n", 
            l1hits_f+l2hits_f-(l1hits_i+l2hits_i), l1hits_f-l1hits_i, l2hits_f-l2hits_i,
            l1misses_f+l2misses_f-(l1misses_i+l2misses_i), l1misses_f-l1misses_i, l2misses_f-l2misses_i);
*/
    return 0;
}
