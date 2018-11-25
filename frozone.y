%{
	#include <stdio.h>
	
	extern FILE *yyin;

	int yylex();
	void yyerror(const char *s);
%}

%token IDENTIFIER MAIN_ID

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
		: 
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
