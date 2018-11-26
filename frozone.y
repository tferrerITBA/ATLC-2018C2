%{
	#include <stdio.h>
	
	extern FILE *yyin;

	int yylex();
	void yyerror(const char *s);
%}

%token IDENTIFIER MAIN_ID ON DO
%token OP_EQ OP_LT OP_GT OP_LE OP_GE OP_NE
%token LITERAL

%start ProgramFunctionList

%%

ProgramFunctionList
		: MainFunction
		| MainFunction FunctionList
		| FunctionList MainFunction
		| FunctionList MainFunction FunctionList
		;

MainFunction
		: MAIN_ID '(' MainArguments ')' '{' FunctionBody '}'
		;

FunctionList
		: FunctionList Function
		| Function
		;

Function
		: IDENTIFIER '(' FunctionArguments ')' '{' FunctionBody '}'
		;

MainArguments
		:
		;

FunctionArguments
		:
		;

FunctionBody
		: VarDeclarationList
		| OnStatement
		|
		;

VarDeclarationList
		: VarDeclarationList VarDeclaration
		| VarDeclaration
		;

VarDeclaration
		: IDENTIFIER '=' LITERAL
		| IDENTIFIER '=' '(' Condition ')'
		;

OnStatement
		: ON '(' Condition ')' DO '{' FunctionBody '}'
		;

Condition
		: IDENTIFIER OP_EQ IDENTIFIER
		| IDENTIFIER OP_LT IDENTIFIER
		| IDENTIFIER OP_GT IDENTIFIER
		| IDENTIFIER OP_LE IDENTIFIER
		| IDENTIFIER OP_GE IDENTIFIER
		| IDENTIFIER OP_NE IDENTIFIER
		;
%%

int main(int argc, char *argv[])
{
	if(argc > 1) {
		FILE *file;

		file = fopen(argv[1], "r");
		if(!file) {
			fprintf(stderr, "could not open %s\n", argv[1]);
			return 1;
		}
		yyin = file;
	}

   if(!yyparse())
        printf("\nParsing complete\n");
    else
        printf("\nParsing failed\n");

    fclose(yyin);
    return 0;
}
