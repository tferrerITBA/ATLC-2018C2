%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <stdarg.h>
	
	#define STR_BLOCK 10
	
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

%token MAIN_ID ON DO
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


char * strconcat(int num, ...) {
	va_list valist;
	char * ret = NULL;
	int len = 0;
	int i;

	va_start(valist, num);
	for(i = 0; i < num; i++) {
		char * param = va_arg(valist, char *);
		if(param != NULL) {
			while(*param != '\0') {
				if(len % STR_BLOCK == 0) {
					ret = realloc(ret, len + STR_BLOCK);
				}
				ret[len++] = *param++;
			}
		}
	}
	if(len % STR_BLOCK == 0) {
		ret = realloc(ret, len + 1);
	}
	ret[len] = '\0';
	
	va_end(valist);
	return ret;
}
