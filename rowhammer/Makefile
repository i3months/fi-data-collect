CC = gcc
CFLAGS = -O2 -Wall -g
TARGETS = rowhammer benign_workload

all: $(TARGETS)

rowhammer: rowhammer.c
	$(CC) $(CFLAGS) -o rowhammer rowhammer.c

benign_workload: benign_workload.c
	$(CC) $(CFLAGS) -o benign_workload benign_workload.c

clean:
	rm -f $(TARGETS)
