all: lex yacc frozone

lex: frozone.l
	lex frozone.l

yacc: frozone.y
	yacc -d frozone.y

frozone: y.tab.c lex.yy.c
	gcc -o frozone y.tab.c lex.yy.c -ly -ll

clean:
	rm -f lex.yy.c y.tab.h y.tab.c frozone
