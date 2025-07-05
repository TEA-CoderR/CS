#define _POSIX_C_SOURCE 200112L
CC			= gcc
CFLAGS	   += -std=c99 -Wall -pedantic -I ./includes -I ./src -I ./obj
TARGETS		= ./bin/farm2
OBJECTS		= ./obj/farm2_main.o ./obj/master.o ./obj/collector.o ./obj/utils.o ./obj/threadpool.o ./obj/container.o ./obj/addresult.o ./obj/countfile.o

$(TARGETS):$(OBJECTS)
	$(CC) $(CFLAGS) $^ -o $@

./obj/farm2_main.o: ./src/farm2_main.c ./includes/master.h ./includes/collector.h
	$(CC) $(CFLAGS) $< -o $@

./obj/master.o: ./src/master.c ./includes/master.h ./includes/utils.h ./includes/threadpool.h ./includes/countfile.h
	$(CC) $(CFLAGS) $< -o $@

./obj/collector.o: ./src/collector.c ./includes/collector.h ./includes/utils.h ./includes/threadpool.h ./includes/addresult.h ./includes/container.h
	$(CC) $(CFLAGS) $< -o $@

./obj/utils.o: ./src/utils.c ./includes/utils.h
	$(CC) $(CFLAGS) $< -o $@

./obj/threadpool.o: ./src/threadpool.c ./includes/utils.h
	$(CC) $(CFLAGS) $< -o $@

./obj/container.o: ./src/container.c ./includes/container.h ./includes/utils.h
	$(CC) $(CFLAGS) $< -o $@

./obj/addresult.o: ./src/addresult.c ./includes/container.h ./includes/utils.h
	$(CC) $(CFLAGS) $< -o $@

./obj/countfile.o: ./src/countfile.c ./includes/utils.h
	$(CC) $(CFLAGS) $< -o $@






# TARGETS		= ./bin/farm2
# OBJECTS		= farm2_main.o master.o collector.o utils.o threadpool.o container.o addresult.o countfile.o

#.PHONY: all clean
# .SUFFIXES: .c .h

# $(TARGETS): $(OBJECTS)
# 	$(CC) $(OBJECTS) -o $(TARGETS)
# $(TARGETS):$(OBJECTS)
# 	$(CC) $^ -o $@

# utils.o: utils.c utils.h
# 	$(CC) $(CFLAGS) -c $<

# threadpool.o: threadpool.c utils.h
# 	$(CC) $(CFLAGS) -c $<

# container.o: container.c container.h utils.h
# 	$(CC) $(CFLAGS) -c $<

# addresult.o: addresult.c container.h utils.h
# 	$(CC) $(CFLAGS) -c $<

# countfile.o: countfile.c utils.h
# 	$(CC) $(CFLAGS) -c $<

# master.o: master.c master.h utils.h threadpool.h countfile.h
# 	$(CC) $(CFLAGS) -c $<

# collector.o: collector.c collector.h utils.h threadpool.h addresult.h container.h
# 	$(CC) $(CFLAGS) -c $<

# farm2_main.o: farm2_main.c farm2_main.h master.h collector.h
# 	$(CC) $(CFLAGS) -c $<
