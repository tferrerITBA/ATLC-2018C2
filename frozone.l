%{
    #include <stdio.h>
    #include "y.tab.h"

    #define TRUE 1;
    #define FALSE 0;

    void yyerror(const char *s);
%}

Separator   [\(\)\{\}\[\]\;\,\.]
Delimiter   [\=\>\<\!\~\?\:\+\-\*\/\&\|\^\%]
Escape      [\\]([r]|[n]|[b]|[f]|[t]|[\\]|[\']|[\"])
Digit       [0-9]
Letter      [a-zA-Z_]
Identifier  {Letter}({Letter}|{Digit})*

AnyStrChar  [^\\"]
String      [\"]({Escape}|{AnyStrChar})*[\"]
Integer     {Digit}+
Float       {Digit}*[\.]{Digit}+

BLANK       [ ]
TAB         [\t]
NEW_LINE    [\n]

%%

frozone         { return MAIN_ID; }
"on"            { return ON; }
"do"            { return DO; }
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

{Float}         {   
                    yylval.fval = atof(yytext); 
                    return FL_LIT;
                }
{Separator}     { return yytext[0]; }
{Delimiter}     { return yytext[0]; }
{String}        {   
                    yylval.sval = yytext; // ELIMINAR COMILLAS 
                    return STR_LIT;
                }
{Identifier}    {   
                    yylval.sval = yytext;
                    return IDENTIFIER;
                }
{Integer}       {
                    yylval.ival = atoi(yytext);
                    return INT_LIT;
                }

{BLANK}         {}
{TAB}           {}
{NEW_LINE}      { yylineno = yylineno + 1; }
.               { yyerror("unexpected character"); }

%%

void yyerror(const char *s) {
    printf("%d : %s %s\n", yylineno, s, yytext );
}
