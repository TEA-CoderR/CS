#define _POSIX_C_SOURCE 200112L
CC			= gcc
CFLAGS	   += -std=c99 -Wall -g -pedantic -I .
# TARGETS		= farm
# OBJECTS		= farm2_main.o master.o collector.o threadpool.o countfile.o container.o addresult.o utils.o

# $(TARGETS):$(OBJECTS)
# 	$(CC) $(CFLAGS) $^ -o $@

farm: farm2_main.o master.o collector.o threadpool.o countfile.o container.o addresult.o utils.o
	$(CC) $(CFLAGS) $^ -o $@
	
farm2_main.o: farm2_main.c master.h collector.h
# 	$(CC) $(CFLAGS) $< -o $@

master.o: master.c master.h utils.h threadpool.h countfile.h
# 	$(CC) $(CFLAGS) $< -o $@

collector.o: collector.c collector.h utils.h threadpool.h addresult.h container.h
# 	$(CC) $(CFLAGS) $< -o $@

utils.o: utils.c utils.h
# 	$(CC) $(CFLAGS) $< -o $@

threadpool.o: threadpool.c utils.h
# 	$(CC) $(CFLAGS) $< -o $@

container.o: container.c container.h utils.h
# 	$(CC) $(CFLAGS) $< -o $@

addresult.o: addresult.c container.h utils.h
# 	$(CC) $(CFLAGS) $< -o $@

countfile.o: countfile.c utils.h
# 	$(CC) $(CFLAGS) $< -o $@






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
