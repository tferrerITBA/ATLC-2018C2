all: lex yacc frozone

lex: frozone.l
	lex frozone.l

yacc: frozone.y
	yacc -d frozone.y

frozone: y.tab.c lex.yy.c symbolTable.c
	gcc -o frozone y.tab.c lex.yy.c symbolTable.c -ly -ll

clean:
	rm -f lex.yy.c y.tab.h y.tab.c frozone test1.c test2.c test3.c test4.c test5.c test1 test2 test3 test4 test5

test1:
	./frozone < test1.f > test1.c
	gcc test1.c -o test1

test2:
	./frozone < test2.f > test2.c
	gcc test2.c -o test2

test3:
	./frozone < test3.f > test3.c
	gcc test3.c -o test3

test4:
	./frozone < test4.f > test4.c
	gcc test4.c -o test4

test5:
	./frozone < test5.f > test5.c
	gcc test5.c -o test5