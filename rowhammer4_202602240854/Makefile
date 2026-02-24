CC = gcc
CFLAGS = -O2 -Wall -g
TARGETS = rowhammer

all: $(TARGETS)

rowhammer: rowhammer.c
	$(CC) $(CFLAGS) -o rowhammer rowhammer.c

clean:
	rm -f $(TARGETS)
