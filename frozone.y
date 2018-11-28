%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include "symbolTable.h"
	#include <stdarg.h>

	#define TRUE 1
  #define FALSE 0
	#define MAX_INT_STR_LENGTH 24
	#define MAX_DBL_STR_LENGTH 24
	#define STR_BLOCK 10

	extern FILE *yyin;
	extern char * yytext;
	FILE * fp;

	int yylex();

	Node addNode(char * string);
	ArgNode addArgNode(char * string, int argc);
	char * strcatN(int num, ...);
	void freeResources();

	Global gscope;
%}

%union {
	int ival;
	double dval;
	bool bval;
	char * sval;
	Node node;
	ArgNode argnode;
}

%token <sval> MAIN_ID
%token <sval> FN_ID
%token ON DO CYCLE
%token <sval> IDENTIFIER
%token OP_EQ OP_LT OP_GT OP_LE OP_GE OP_NE
%token <ival> INT_LIT
%token <dval> DBL_LIT
%token <bval> BOOL_LIT
%token <sval> STR_LIT
%token <sval> RETURN

%type<node> Program HeaderSection FunctionPrototypes FunctionPrototype GlobalFunctionList MainFunction FunctionList Function FunctionBody Statement VarDeclaration FunctionCall OnStatement ReturnStatement IdentifierList
%type<argnode> FunctionArguments NonZeroFunctionArguments

%start Program

%%

Program
		: HeaderSection GlobalFunctionList
				{ $$ = addNode(strcatN(4, "typedef enum { FALSE = 0, TRUE } bool;\n", "typedef struct VarCDT {\n\tchar * str;\n\tint i;\n\tdouble d;\nbool b;\n}\ntypedef struct VarCDT * Var;\n\n", $1->str, $2->str)); fprintf(fp, "%s", $$->str); } // METER EN EL .H
		;

HeaderSection
		: FunctionPrototypes
				{
					$$ = addNode(strcatN(1, $1->str));
				}
		;

FunctionPrototypes
		: FunctionPrototypes FunctionPrototype
				{
					$$ = addNode(strcatN(2, $1->str, $2->str));
				}
		|		{ $$ = addNode(""); }
		;

FunctionPrototype
		: IDENTIFIER '(' INT_LIT ')'
				{
					insertFunction($1, $3);
					$$ = addNode(strcatN(4, "Var ", $1, "(", ");\n"));//FALTAN ARGS
				}
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
		: MAIN_ID '(' ')' '{' FunctionBody ReturnStatement '}'
				{
					$$ = addNode(strcatN(4, "int main() {\n", $5->str, $6->str, "}\n\n"));
				}
		;

FunctionList
		: FunctionList Function
				{ $$ = addNode(strcatN(2, $1->str, $2->str)); }
		| Function
				{ $$ = addNode(strcatN(1, $1->str)); }
		;

Function
		: FN_ID '(' FunctionArguments ')' '{' FunctionBody ReturnStatement '}'
				{
					char * functionName = getFunctionName($1);
					if(!ArgcMatchesPrototype(functionName, $3->argc)) {
						yyerror("Argument count incompatible with prototype declaration");
						return ARGC_ERR;
					}
					$$ = addNode(strcatN(8, "Var ", functionName, "(", $3->str, ") {\n", $6->str, $7->str, "}\n\n"));
				}
		;

FunctionArguments
		: NonZeroFunctionArguments
				{ $$ = addArgNode(strcatN(1, $1->str), $1->argc); }
		|		{ $$ = addArgNode("", 0); }
		;

NonZeroFunctionArguments
		: NonZeroFunctionArguments ',' IDENTIFIER
				{ $$ = addArgNode(strcatN(3, $1->str, ", Var ", $3), $1->argc + 1); }
		| IDENTIFIER
				{ $$ = addArgNode(strcatN(2, "Var ", $1), 1); }
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
		| CycleStatement
				{ $$ = addNode(strcatN(1, $1->str)); }
		| ReturnStatement
				{ $$ = addNode(strcatN(1, $1->str)); }
		;

VarDeclaration
		: IDENTIFIER '=' INT_LIT
				{
					char int_str[MAX_INT_STR_LENGTH];
          			sprintf(int_str, "%d", $3);
					if(addVariable($1, IVAL) == VAR_CREATED) {
						$$ = addNode(strcatN(7, "Var ", $1," = malloc(sizeof(VarCDT));\nvarWithInt(", $1, ", ", int_str, ");\n"));
					} else {
						$$ = addNode(strcatN(5, "varWithInt(", $1, ", ", int_str, ");\n"));
					}
				}
		| IDENTIFIER '=' DBL_LIT
				{
					char double_str[MAX_DBL_STR_LENGTH];
          			sprintf(double_str, "%g", $3);
					if(addVariable($1, DVAL) == VAR_CREATED) {
						$$ = addNode(strcatN(7, "Var ", $1," = malloc(sizeof(VarCDT));\nvarWithDbl(", $1, ", ", double_str, ");\n"));
					} else {
						$$ = addNode(strcatN(5, "varWithDbl(", $1, ", ", double_str, ");\n"));
					}
				}
		| IDENTIFIER '=' STR_LIT
				{
					if(addVariable($1, SVAL) == VAR_CREATED) {
						$$ = addNode(strcatN(7, "Var ", $1," = malloc(sizeof(VarCDT));\nvarWithStr(", $1, ", ", $3, ");\n"));
					} else {
						$$ = addNode(strcatN(5, "varWithStr(", $1, ", ", $3, ");\n"));
					}
				}
		| IDENTIFIER '=' BOOL_LIT
				{
					if(addVariable($1, BVAL) == VAR_CREATED) {
						$$ = addNode(strcatN(7, "Var ", $1, " = malloc(sizeof(VarCDT));\nvarWithBool(", $1, ", ", ($3 == TRUE)? "TRUE" : "FALSE", ");\n"));
					} else {
						$$ = addNode(strcatN(5, "varWithBool(", $1, ", ", ($3 == TRUE)? "TRUE" : "FALSE", ");\n"));
					}
				}
		| IDENTIFIER '=' FunctionCall
				{
					$$ = addNode(strcatN(1, $1, " = ", $3->str));
				}
		//| IDENTIFIER '=' '(' Condition ')'
		//		{ $$ = addNode()}
		;

FunctionCall
		: IDENTIFIER '(' IdentifierList ')'
				{
					////////////////////////////////////////////////////////
				}
		;

OnStatement
		: ON '(' Condition ')' DO '{' FunctionBody '}'
				{ $$ = addNode(strcatN(4, "if(", /*$3->str,*/ ") {\n", $7->str, "}\n")); }
		;

CycleStatement
	: CYCLE '{' FunctionBody '}' ON '(' Condition ')'
				{ $$ = addNode(strcatN(4, "do {", $3->str, "} while(", /*$7->str,*/ ")\n")); }
	;

ReturnStatement
		: RETURN IDENTIFIER
			{
				if(!foundVariable($2)) {
					yyerror("Returned non-existent variable in function");
					return NOT_FOUND;
				}
				$$ = addNode(strcatN(3, "return ", $2, ";\n"));
			}
		| RETURN INT_LIT
			{
				char int_str[MAX_INT_STR_LENGTH];
          		sprintf(int_str, "%d", $2);
				$$ = addNode(strcatN(5, "return newVarWithInt(", $1, ", ", int_str, ");\n"));
			}
		| RETURN DBL_LIT
			{
				char double_str[MAX_DBL_STR_LENGTH];
          		sprintf(double_str, "%g", $2);
				$$ = addNode(strcatN(5, "return newVarWithDbl(", $1, ", ", double_str, ");\n"));
			}
		| RETURN STR_LIT
			{
				$$ = addNode(strcatN(5, "return newVarWithStr(", $1, ", ", $2, ");\n"));
			}
		| RETURN BOOL_LIT
			{
				$$ = addNode(strcatN(5, "return newVarWithBool(", $1, ", ", ($2 == TRUE)? "TRUE" : "FALSE", ");\n"));
			}
		;

Condition
		: IDENTIFIER OP_EQ IDENTIFIER
		| IDENTIFIER OP_LT IDENTIFIER
		| IDENTIFIER OP_GT IDENTIFIER
		| IDENTIFIER OP_LE IDENTIFIER
		| IDENTIFIER OP_GE IDENTIFIER
		| IDENTIFIER OP_NE IDENTIFIER
		;

IdentifierList
		:
			{ $$ = addNode(strcatN(1, "")); }
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

    //freeResources();

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

bool foundVariable(char * varName) {
	Function func = gscope->functions[gscope->currentFunction];
	int i;
	for(i = 0; i < func->variableIndex; i++) {
		if(strcmp(varName, func->varLocal[i]->name) == 0) {
			return TRUE;
		}
	}
	return FALSE;
}

Node addNode(char * string) {
	Node newNode = malloc(sizeof(NodeCDT));
	newNode->str = string;
	return newNode;
}

ArgNode addArgNode(char * string, int argc) {
	ArgNode newNode = malloc(sizeof(ArgNodeCDT));
	newNode->str = string;
	newNode->argc = argc;
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
