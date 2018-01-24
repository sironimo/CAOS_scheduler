CC = gcc
LIBS = -lsimgrid
CFLAGS = $(LIBS) -O2

all: round_robin minmin critical_path decreasing_time

round_robin: round_robin.c util.c util.h
	$(CC) -o round_robin util.c round_robin.c $(CFLAGS)

minmin: minmin.c util.c util.h
	$(CC) -o minmin minmin.c util.c $(CFLAGS)

critical_path: critical_path.c util.c util.h
	$(CC) -o critical_path critical_path.c util.c $(CFLAGS)

decreasing_time: decreasing_time.c util.c util.h
	$(CC) -o decreasing_time decreasing_time.c util.c $(CFLAGS)
