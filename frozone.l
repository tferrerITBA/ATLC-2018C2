%{
	#include <stdio.h>
	#include "y.tab.h"

	void yyerror(const char *s);
%}

Separator 	[\(\)\{\}\[\]\;\,\.]
Digit		[0-9]
Letter		[a-zA-Z_]
Identifier	({Letter}|{Digit})+
BLANK		[ ]
TAB 		[\t]
NEW_LINE	[\n]

%%

frozone			{ return MAIN_ID; }
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
