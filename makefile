CC = gcc
LIBS = -lsimgrid
CFLAGS = $(LIBS) -O2

all: round_robin minmin critical_path decreasing_time critical_path_energy decreasing_time_energy fastest_possible

round_robin: round_robin.c util.c util.h
	$(CC) -o round_robin util.c round_robin.c $(CFLAGS)

minmin: minmin.c util.c util.h
	$(CC) -o minmin minmin.c util.c $(CFLAGS)

critical_path: critical_path.c util.c util.h
	$(CC) -o critical_path critical_path.c util.c $(CFLAGS)

critical_path_energy: critical_path.c util.c util.h
	$(CC) -o critical_path_energy critical_path.c util.c $(CFLAGS) -DENERGY_SCHEDULER

decreasing_time: decreasing_time.c util.c util.h
	$(CC) -o decreasing_time decreasing_time.c util.c $(CFLAGS)

decreasing_time_energy: decreasing_time.c util.c util.h
	$(CC) -o decreasing_time_energy decreasing_time.c util.c $(CFLAGS) -DENERGY_SCHEDULER

fastest_possible: fastest_possible.c
	$(CC) -o fastest_possible fastest_possible.c $(CFLAGS)
