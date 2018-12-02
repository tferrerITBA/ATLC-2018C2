# ATLC-2018C2
### Trabajo Práctico Especial - ATLC - Segundo Cuatrimestre 2018

To build the compiler simply run the following commands:
```
git clone git@github.com:tferrerITBA/ATLC-2018C2.git # or via HTTPS
cd ATLC-2018C2
make
```

The command `make clean` is also supported.

To compile a frozone file:
```
make frozone_bin SRC=<the frozone file> TGT=<the output binary name>
```

To compile without using the Makefile:

``` 
# Build the compiler
lex frozone.l
yacc -d frozone.y 
gcc -o frozone y.tab.c lex.yy.c -ly -ll

# Build a custom file
./frozone your_code.f intermediate_code.c
gcc intermediate_code.c -o output_binary
```

Note that running `frozone` with one or less arguments will result in the compiler reading from `stdin` and writing to `stdout`.

For more information, please refer to the pdf document located in the repository's root (in spanish).
