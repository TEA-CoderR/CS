CC			= gcc
CFLAGS	   += -std=c99 -Wall -pedantic -I ./includes
TARGETS		= farm

SRC 		= src
OBJ 		= obj
INCLUDE		= includes
BIN 		= bin
TEST   		= test
TESTFILES	= testfiles
SRCS 		= $(wildcard $(SRC)/*.c)
INCLUDES	= $(wildcard $(INCLUDE)/*.h)
OBJECTS 	= $(patsubst $(SRC)/%.c, $(OBJ)/%.o, $(SRCS))

TARGETS2	= generafile
SRCS2 		= generafile.c

.PHONY: maketest test clean cleanall

$(BIN)/$(TARGETS):$(OBJECTS)
	$(CC) $(CFLAGS) $^ -o $@
	@-make maketest

$(OBJ)/%.o:$(SRC)/%.c $(INCLUDES)
	$(CC) $(CFLAGS) $< -c -o $@

maketest:
	@-mkdir -p $(TEST)
	@echo "> created dir test"

	@$(CC) $(CFLAGS) $(TESTFILES)/$(SRCS2) -o $(TEST)/$(TARGETS2)
	@echo "> created generafile in test"

	@-cp $(TESTFILES)/test.sh $(TESTFILES)/Makefile $(TEST)
	@echo "> copied test.sh and Makefile in test"

	@-cp $(BIN)/$(TARGETS) $(TEST)
	@echo "> copied farm in test"
	@echo "> you can run \"make test\" now"

test:
	@-make -C test

clean:
	-rm -f $(BIN)/$(TARGETS) $(OBJECTS)
	-rm -rf $(TEST)

cleanall:
	-rm -f $(BIN)/$(TARGETS) $(OBJECTS) core *.~
	-rm -rf $(TEST)