CC = gcc
CFLAGS += -std=c99 -Wall -I .

text: text.o threadpool.o utils.o
	gcc $^ -o $@
text.o: text.c threadpool.h utils.h

threadpool.o: threadpool.c utils.h

utils.o: utils.c
