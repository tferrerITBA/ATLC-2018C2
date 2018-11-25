# ATLC-2018C2
### Trabajo Práctico Especial - ATLC - Segundo Cuatrimestre 2018

To build simply run the following commands:
```
git clone git@github.com:tferrerITBA/ATLC-2018C2.git
cd ATLC-2018C2
make
```

The command `make clean` is also supported.

Makefile commands:

``` 
lex frozone.l
yacc -d frozone.y 
gcc -o frozone y.tab.c lex.yy.c -ly -ll 
```
