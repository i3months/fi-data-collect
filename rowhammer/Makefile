CC = gcc
CFLAGS = -O2 -Wall -g
TARGET = rowhammer

all: $(TARGET)

$(TARGET): rowhammer.c
	$(CC) $(CFLAGS) -o $(TARGET) rowhammer.c

clean:
	rm -f $(TARGET)
