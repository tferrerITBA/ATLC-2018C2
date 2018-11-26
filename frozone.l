%{
	#include <stdio.h>
	#include "y.tab.h"

	void yyerror(const char *s);
%}

Separator 	[\(\)\{\}\[\]\;\,\.]
Delimiter	[\=\>\<\!\~\?\:\+\-\*\/\&\|\^\%]
Escape 		[\\]([r]|[n]|[b]|[f]|[t]|[\\]|[\']|[\"])
Digit		[0-9]
Letter		[a-zA-Z_]
Identifier	{Letter}({Letter}|{Digit})*

AnyStrChar	[^\\"]
String		[\"]({Escape}|{AnyStrChar})*[\"]
Integer		{Digit}+
Float		{Digit}*[\.]{Digit}+

BLANK		[ ]
TAB 		[\t]
NEW_LINE	[\n]

%%

frozone			{ return MAIN_ID; }
"on"			{ return ON; }
"do"			{ return DO; }
"eq"			{ return OP_EQ; }
"lt"			{ return OP_LT; }
"gt"			{ return OP_GT; }
"le"			{ return OP_LE; }
"ge"			{ return OP_GE; }
"ne"			{ return OP_NE; }
"true"			{ return LITERAL; }
"false"			{ return LITERAL; }

{Float}			{ return LITERAL; }
{Separator}		{ return yytext[0]; }
{Delimiter}		{ return yytext[0]; }
{String}		{ return LITERAL; }
{Identifier}	{ return IDENTIFIER; }
{Integer}		{ return LITERAL; }

{BLANK} 		{}
{TAB}			{}
{NEW_LINE}		{ yylineno = yylineno + 1; }
.				{ yyerror("unexpected character"); }

%%

void yyerror(const char *s) {
    printf("%d : %s %s\n", yylineno, s, yytext );
}
