%{
	#include <stdio.h>
	#include "y.tab.h"

	void yyerror(const char *s);
%}

Separator 	[\(\)\{\}\[\]\;\,\.]
Digit		[0-9]
Letter		[a-zA-Z_]
Identifier	({Letter}|{Digit})+
On			on
Do			do	
BLANK		[ ]
TAB 		[\t]
NEW_LINE	[\n]

%%

frozone			{ return MAIN_ID; }
{On}			{ return ON; }
{Do}			{ return DO; }
"eq"			{ return OP_EQ; }
"lt"			{ return OP_LT; }
"gt"			{ return OP_GT; }
"le"			{ return OP_LE; }
"ge"			{ return OP_GE; }
"ne"			{ return OP_NE; }
{Identifier}	{ return IDENTIFIER; }
{Separator}		{ return yytext[0]; }
{BLANK} 		{}
{TAB}			{}
{NEW_LINE}		{ yylineno = yylineno + 1; }
.				{ yyerror("unexpected character"); }

%%

void yyerror(const char *s) {
    printf("%d : %s %s\n", yylineno, s, yytext );
}
