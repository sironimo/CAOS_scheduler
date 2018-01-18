CC = gcc
LIBS = -lsimgrid
CFLAGS = $(LIBS) 

all: round_robin

round_robin: round_robin.c
	$(CC) -o round_robin round_robin.c $(CFLAGS)
