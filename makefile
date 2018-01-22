#CC = gcc
#LIBS = -lsimgrid
#CFLAGS = $(LIBS) 

#all: round_robin

#round_robin: round_robin.c
#	$(CC) -o round_robin round_robin.c $(CFLAGS)

#CC = gcc
#LIBS = -lsimgrid
#CFLAGS = $(LIBS) 

#all: sd_scheduling

#sd_scheduling: sd_scheduling.c
#	$(CC) -o sd_scheduling sd_scheduling.c $(CFLAGS)
	
CC = gcc
LIBS = -lsimgrid
CFLAGS = $(LIBS) 

all: minmin

sd_scheduling: minmin.c
	$(CC) -o minmin minmin.c $(CFLAGS)