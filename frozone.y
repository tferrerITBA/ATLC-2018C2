%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include "symbolTable.h"
	#include <stdarg.h> 
   	
  	#define STR_BLOCK 10 
  	#define MAX_INT_STR_LENGTH 24
  	#define MAX_DBL_STR_LENGTH 24
	
	#define STR_BLOCK 10
	
	extern FILE *yyin;
	extern char * yytext;
	FILE * fp;

	int yylex();

	Node addNode(char * string);
	char * strcatN(int num, ...);
	void freeResources();

	Global gscope;
%}

%union {
	int ival;
	double dval;
	int bval;
	char * sval;
	Node node;
}

%token <sval> MAIN_ID
%token <sval> FN_ID
%token ON DO
%token <sval> IDENTIFIER
%token OP_EQ OP_LT OP_GT OP_LE OP_GE OP_NE
%token <ival> INT_LIT
%token <dval> DBL_LIT
%token <bval> BOOL_LIT
%token <sval> STR_LIT

%type<node> Program GlobalFunctionList MainFunction FunctionList Function FunctionArguments FunctionBody Statement VarDeclaration OnStatement

%start Program

%%

Program
		: GlobalFunctionList
				{ $$ = addNode(strcatN(3, "typedef enum { FALSE = 0, TRUE } bool;\n", "typedef struct VarCDT {\n\tchar * str;\n\tint i;\n\tdouble d;\n}\n\n", $1->str)); fprintf(fp, "%s", $$->str); } // METER EN EL .H
		;

GlobalFunctionList
		: MainFunction
				{ $$ = addNode(strcatN(1, $1->str)); }
		| MainFunction FunctionList
				{ $$ = addNode(strcatN(2, $1->str, $2->str)); }
		| FunctionList MainFunction
				{ $$ = addNode(strcatN(2, $1->str, $2->str)); }
		| FunctionList MainFunction FunctionList
				{ $$ = addNode(strcatN(3, $1->str, $2->str, $3->str)); }
		;

MainFunction
		: MAIN_ID '(' ')' '{' FunctionBody '}'
				{
					$$ = addNode(strcatN(3, "int main() {\n", $5->str, "}\n\n"));
				}
		;

FunctionList
		: FunctionList Function
				{ $$ = addNode(strcatN(2, $1->str, $2->str)); }
		| Function
				{ $$ = addNode(strcatN(1, $1->str)); }
		;

Function
		: FN_ID '(' FunctionArguments ')' '{' FunctionBody '}'
				{
					$$ = addNode(strcatN(6, getFunctionName($1), "(", $3->str, ") {\n", $6->str, "}\n\n"));
				}
		;

FunctionArguments
		:
				{ $$ = addNode(""); }
		;

FunctionBody
		: FunctionBody Statement
				{ $$ = addNode(strcatN(2, $1->str, $2->str)); }
		|
				{ $$ = addNode(""); } // AGREGAR ; A LINEA VACIA
		;

Statement
		: VarDeclaration
				{ $$ = addNode(strcatN(1, $1->str)); }
		| OnStatement
				{ $$ = addNode(strcatN(1, $1->str)); }
		;

VarDeclaration
		: IDENTIFIER '=' INT_LIT
				{
					char int_str[MAX_INT_STR_LENGTH];
					sprintf(int_str, "%d", $3);
					if(addVariable($1, IVAL) == VAR_CREATED) {
						$$ = addNode(strcatN(7, "VarCDT ", $1,";\n", $1, ".i = ", int_str, ";\n"));
					} else {
						$$ = addNode(strcatN(4, $1, ".i = ", int_str, ";\n"));
					}
				}
		| IDENTIFIER '=' DBL_LIT
				{
					char double_str[MAX_DBL_STR_LENGTH];
					sprintf(double_str, "%g", $3);
					if(addVariable($1, DVAL) == VAR_CREATED) {
						$$ = addNode(strcatN(7, "VarCDT ", $1,";\n", $1, ".d = ", double_str, ";\n"));
					} else {
						$$ = addNode(strcatN(4, $1, ".d = ", double_str, ";\n"));
					}
				}
		| IDENTIFIER '=' STR_LIT
				{
					if(addVariable($1, SVAL) == VAR_CREATED) {
						$$ = addNode(strcatN(7, "VarCDT ", $1,";\n", $1, ".str = ", $3, ";\n"));
					} else {
						$$ = addNode(strcatN(4, $1, ".str = ", $3, ";\n"));
					}
				}
		| IDENTIFIER '=' BOOL_LIT
				{
					if(addVariable($1, BVAL) == VAR_CREATED) {
						$$ = addNode(strcatN(7, "VarCDT ", $1,";\n", $1, ".b = ", ($3 == TRUE)? "TRUE" : "FALSE", ";\n"));
					} else {
						$$ = addNode(strcatN(4, $1, ".b = ", ($3 == TRUE)? "TRUE" : "FALSE", ";\n"));
					}
				}
		//| IDENTIFIER '=' '(' Condition ')'
		//		{ $$ = addNode()}
		;

OnStatement
		: ON '(' Condition ')' DO '{' FunctionBody '}'
				{ $$ = addNode(strcatN(4, "if(", /*$3->str,*/ ") {\n", $7->str, "}\n")); }
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

	fp = fopen("test.c", "w+"); 			//Usar argv[1]
	gscope = malloc(sizeof(GlobalCDT));
	gscope->functionIndex = 1;
	gscope->mainFound = FALSE;

   if(!yyparse())
        printf("\nParsing complete\n");
    else
        printf("\nParsing failed\n");

    freeResources();

	fclose(fp);

    fclose(yyin);
    return 0;
}

varStatus addVariable(char * varName, int type) {
	Function func = gscope->functions[gscope->currentFunction];
	int i;
	for(i = 0; i < func->variableIndex; i++) {
		if(strcmp(varName, func->varLocal[i]->name) == 0) {
			if(func->varLocal[i]->type != type) {
				func->varLocal[i]->type = type;
			}
			return VAR_MODIFIED;
		}
	}
	if(i >= func->variableIndex) {
		func->varLocal[func->variableIndex] = malloc(sizeof(VariableCDT));
		func->varLocal[func->variableIndex]->name = varName;
		func->varLocal[func->variableIndex++]->type = type;
	}
	return VAR_CREATED;
}

Node addNode(char * string) {
	Node newNode = malloc(sizeof(NodeCDT));
	newNode->str = string;
	return newNode;
}

char * strcatN(int num, ...) {
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

void freeResources() {
	int i;
    for(i = 0; i < gscope->variableIndex; i++) {
    	free(gscope->varGlobal[i]);
    }
    for(i = 0; i < gscope->functionIndex; i++) {
    	int j;
    	for(j = 0; j < gscope->functions[i]->variableIndex; j++) {
    		free(gscope->functions[i]->varLocal[j]);
    	}
    	free(gscope->functions[i]);
    }
    free(gscope);
}
