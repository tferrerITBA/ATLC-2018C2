CC=gcc
YFLAGS=-d
FROZONEC=./frozone
FROZONEFLAGS=-o $(FROZONEC) -ly -ll
SRC=test1.f
TGT=test1
TGTFLAGS=-o $(TGT)

all: lex yacc frozone

lex: frozone.l
	$(LEX) frozone.l

yacc: frozone.y
	$(YACC) $(YFLAGS) frozone.y

frozone: y.tab.c lex.yy.c symbolTable.c
	$(CC) y.tab.c lex.yy.c symbolTable.c $(FROZONEFLAGS)

frozone_bin:
	$(FROZONEC) $(SRC) intermediate_code.c
	$(CC) intermediate_code.c $(TGTFLAGS)

clean:
	$(RM) lex.yy.c y.tab.h y.tab.c intermediate_code.c test1.c test2.c test3.c test4.c test5.c test1 test2 test3 test4 test5 $(FROZONEC)

test1:
	./frozone < test1.f > test1.c
	gcc test1.c -o test1
