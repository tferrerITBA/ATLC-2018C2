%{
    #include <stdio.h>
    #include <string.h>
    #include "symbolTable.h"
    #include "y.tab.h"

    extern FILE * fp;
    extern Global gscope;
%}

Separator   [\(\)\{\}\[\]\;\,\.]
Delimiter   [\=\>\<\!\~\?\:\&\|\^\%]
Escape      [\\]([r]|[n]|[b]|[f]|[t]|[\\]|[\']|[\"])
Digit       [0-9]
Letter      [a-zA-Z_]
Identifier  {Letter}({Letter}|{Digit})*

FunctionDec function[ ]+{Identifier}
AnyStrChar  [^\\"]
String      [\"]({Escape}|{AnyStrChar})*[\"]
Integer     {Digit}+
Double       {Digit}*[\.]{Digit}+

BLANK       [ ]
TAB         [\t]
NEW_LINE    [\n]

%%

frozone         {
                    yylval.sval = strdup(yytext);
                    if(insertFunction(yylval.sval, 0) != SUCCESS) {
                        fclose(fp);
                        remove("./test.c");
                        exit(1);                // SACAR ESTO, PONER INFO EN NODOS
                    }
                    return MAIN_ID;
                }
"on"            { return ON; }
"do"            { return DO; }
"cycle"         { return CYCLE; }
"eq"            { return OP_EQ; }
"lt"            { return OP_LT; }
"gt"            { return OP_GT; }
"le"            { return OP_LE; }
"ge"            { return OP_GE; }
"ne"            { return OP_NE; }
"true"          {
                    yylval.bval = TRUE;
                    return BOOL_LIT;
                }
"false"         {
                    yylval.bval = FALSE;
                    return BOOL_LIT;
                }
"+"             {
                    yylval.aop = PLUS;
                    return ARITHM_OP;
                }
"-"             {
                    yylval.aop = MINUS;
                    return ARITHM_OP;
                }
"*"             {
                    yylval.aop = MULT;
                    return ARITHM_OP;
                }
"/"             {
                    yylval.aop = DIV;
                    return ARITHM_OP;
                }
"return"        {
                    yylval.sval = strdup(yytext);
                    return RETURN;
                }
"print"         {
                    yylval.sval = strdup(yytext);
                    return PRINT;
                }

{Double}         {
                    yylval.sval = strdup(yytext);;
                    return DBL_LIT;
                }
{Integer}       {
                    yylval.sval = strdup(yytext);
                    return INT_LIT;
                }
{Separator}     { return yytext[0]; }
{Delimiter}     { return yytext[0]; }
{String}        {
                    yylval.sval = strdup(yytext); // ELIMINAR COMILLAS
                    return STR_LIT;
                }
{FunctionDec}   {
                    yylval.sval = strdup(yytext);
                    if(foundFunction(yylval.sval) != SUCCESS) {
                        fclose(fp);
                        remove("./test.c");
                        exit(1);                // SACAR ESTO
                    }
                    return FN_ID;
}
{Identifier}    {
                    yylval.sval = strdup(yytext);
                    return IDENTIFIER;
                }

{BLANK}         {}
{TAB}           {}
{NEW_LINE}      { yylineno = yylineno + 1; }
.               { yyerror("unexpected character"); }

%%

void yyerror(const char *s) {
    printf("%d : %s : %s\n", yylineno, s, yytext );
}
