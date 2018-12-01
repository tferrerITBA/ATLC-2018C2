%{
    #include <stdio.h>
    #include <string.h>
    #include "symbolTable.h"
    #include "y.tab.h"

    extern Global gscope;
    extern void yyerror(const char * s);

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

"frozone"       {
                    yylval.sval = strdup(yytext);
                    insertFunction(yylval.sval, 0);
                    return MAIN_ID;
                }
"on"            {   return ON;      }
"do"            {   return DO;      }
"cycle"         {   return CYCLE;   }
"else"          {   return ELSE;    }
"eq"            {   yylval.rop = EQ; return REL_OP; }
"lt"            {   yylval.rop = LT; return REL_OP; }
"gt"            {   yylval.rop = GT; return REL_OP; }
"ne"            {   yylval.rop = NE; return REL_OP; }
"and"           {   yylval.logop = AND; return LOG_OP;  }
"or"            {   yylval.logop = OR; return LOG_OP;   }
"not"           {   yylval.logop = NOT; return LOG_OP;  }
"true"          {   yylval.bval = TRUE; return BOOL_LIT;    }
"false"         {   yylval.bval = FALSE; return BOOL_LIT;   }
"+"             {   yylval.aop = PLUS; return ARITHM_OP;    }
"-"             {   yylval.aop = MINUS; return ARITHM_OP;   }
"*"             {   yylval.aop = MULT; return ARITHM_OP;    }
"/"             {   yylval.aop = DIV; return ARITHM_OP;     }
"return"        {   yylval.sval = strdup(yytext); return RETURN;    }
"print"         {   yylval.sval = strdup(yytext); return PRINT;     }
"scan"          {   return SCAN;    }

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
                    foundFunction(yylval.sval);
                    return FN_ID;
}
{Identifier}    {
                    yylval.sval = strdup(yytext);
                    return IDENTIFIER;
                }

{BLANK}         {}
{TAB}           {}
{NEW_LINE}      { yylineno++; }
.               { yyerror("Unexpected character"); }

%%
