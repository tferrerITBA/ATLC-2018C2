%{
	#include <stdio.h>

	extern FILE *yyin;

	int yylex();
	void yyerror(const char *s);
%}

%union {
	int ival;
	float fval;
	int bval;
	char * sval;
}

%token MAIN_ID ON DO CYCLE
%token <sval> IDENTIFIER
%token OP_EQ OP_LT OP_GT OP_LE OP_GE OP_NE
%token <ival> INT_LIT
%token <fval> FL_LIT
%token <bval> BOOL_LIT
%token <sval> STR_LIT

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
		: FunctionBody Statement
		|
		;

Statement
		: VarDeclaration
		| OnStatement
		;

VarDeclaration
		: IDENTIFIER '=' INT_LIT			{ addVariable($1, IVAL, $3); }
		| IDENTIFIER '=' FL_LIT				{ addVariable($1, FVAL, $3); }
		| IDENTIFIER '=' STR_LIT			{ addVariable($1, SVAL, $3); }
		| IDENTIFIER '=' BOOL_LIT			{ addVariable($1, BVAL, $3); }
		| IDENTIFIER '=' '(' Condition ')'
		;

OnStatement
		: ON '(' Condition ')' DO '{' FunctionBody '}'
		;

CycleStatement
	: CYCLE '{' FunctionBody '}' ON '(' Condition ')'
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

void addVariable(char * id, int type, void * value) {

}
