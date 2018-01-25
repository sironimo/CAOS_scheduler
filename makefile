CC = gcc
LIBS = -lsimgrid
CFLAGS = $(LIBS) -O2

all: round_robin min_min critical_path decreasing_time critical_path_energy decreasing_time_energy

round_robin: round_robin.c util.c util.h
	$(CC) -o round_robin util.c round_robin.c $(CFLAGS)

min_min: min_min.c util.c util.h
	$(CC) -o min_min min_min.c util.c $(CFLAGS)

critical_path: critical_path.c util.c util.h
	$(CC) -o critical_path critical_path.c util.c $(CFLAGS)

critical_path_energy: critical_path.c util.c util.h
	$(CC) -o critical_path_energy critical_path.c util.c $(CFLAGS) -DENERGY_SCHEDULER

decreasing_time: decreasing_time.c util.c util.h
	$(CC) -o decreasing_time decreasing_time.c util.c $(CFLAGS)

decreasing_time_energy: decreasing_time.c util.c util.h
	$(CC) -o decreasing_time_energy decreasing_time.c util.c $(CFLAGS) -DENERGY_SCHEDULER
