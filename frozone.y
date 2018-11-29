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
	IntNode addIntNode(char * string, int n);
	OpNode addOpNode(int type, char * baseId, char * string);
	char * strcatN(int num, ...);
	char * repeatStr(char * str, int count);
	void freeResources();

	Global gscope;
%}

%union {
	int ival;
	double dval;
	bool bval;
	char * sval;
	Node node;
	IntNode intnode;
	OpNode opnode;
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

%type<node> Program HeaderSection FunctionPrototypes FunctionPrototype GlobalFunctionList MainFunction FunctionList Function FunctionBody Statement VarDeclaration FunctionCall OnStatement CycleStatement ReturnStatement
%type<intnode> FunctionArguments NonEmptyFunctionArguments FunctionCallArgs NonEmptyFunctionCallArgs Literal
%type<opnode> Operation

%left '-' '+'
%left '*' '/'

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
		: IDENTIFIER '(' Literal ')'
				{
					if($3->n != IVAL) {
						yyerror("Number of arguments must be integer");
					}
					insertFunction($1, atoi($3->str));
					$$ = addNode(strcatN(4, "Var ", $1, "(", /*strcat(repeatStr("Var, ", $3 - 1), "Var"),*/ ");\n"));//FALTAN ARGS
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
					if(!ArgcMatchesPrototype(functionName, $3->n)) {
						return ARGC_ERR;
					}
					$$ = addNode(strcatN(8, "Var ", functionName, "(", $3->str, ") {\n", $6->str, $7->str, "}\n\n"));
				}
		;

FunctionArguments
		: NonEmptyFunctionArguments
				{ $$ = addIntNode(strcatN(1, $1->str), $1->n); }
		|		{ $$ = addIntNode("", 0); }
		;

NonEmptyFunctionArguments
		: NonEmptyFunctionArguments ',' IDENTIFIER
				{
					addNewVariable($3);
					$$ = addIntNode(strcatN(3, $1->str, ", Var ", $3), $1->n + 1);
				}
		| IDENTIFIER
				{
					addNewVariable($1);
					$$ = addIntNode(strcatN(2, "Var ", $1), 1);
				}
		;

FunctionBody
		: FunctionBody Statement
				{ $$ = addNode(strcatN(2, $1->str, $2->str)); }
		|
				{ $$ = addNode(""); } //CHEQUEAR
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
		/*: IDENTIFIER '=' INT_LIT
				{
					char int_str[MAX_INT_STR_LENGTH];
          			sprintf(int_str, "%d", $3);
					if(addVariable($1) == VAR_CREATED) {
						$$ = addNode(strcatN(7, "Var ", $1," = malloc(sizeof(VarCDT));\nvarWithInt(", $1, ", ", int_str, ");\n"));
					} else {
						$$ = addNode(strcatN(5, "varWithInt(", $1, ", ", int_str, ");\n"));
					}
				}
		| IDENTIFIER '=' DBL_LIT
				{
					char double_str[MAX_DBL_STR_LENGTH];
          			sprintf(double_str, "%g", $3);
					if(addVariable($1) == VAR_CREATED) {
						$$ = addNode(strcatN(7, "Var ", $1," = malloc(sizeof(VarCDT));\nvarWithDbl(", $1, ", ", double_str, ");\n"));
					} else {
						$$ = addNode(strcatN(5, "varWithDbl(", $1, ", ", double_str, ");\n"));
					}
				}
		| IDENTIFIER '=' STR_LIT
				{
					if(addVariable($1) == VAR_CREATED) {
						$$ = addNode(strcatN(7, "Var ", $1," = malloc(sizeof(VarCDT));\nvarWithStr(", $1, ", ", $3, ");\n"));
					} else {
						$$ = addNode(strcatN(5, "varWithStr(", $1, ", ", $3, ");\n"));
					}
				}
		| IDENTIFIER '=' BOOL_LIT
				{
					if(addVariable($1) == VAR_CREATED) {
						$$ = addNode(strcatN(7, "Var ", $1, " = malloc(sizeof(VarCDT));\nvarWithBool(", $1, ", ", ($3 == TRUE)? "TRUE" : "FALSE", ");\n"));
					} else {
						$$ = addNode(strcatN(5, "varWithBool(", $1, ", ", ($3 == TRUE)? "TRUE" : "FALSE", ");\n"));
					}
				}*/
		: IDENTIFIER '=' Literal
				{
					if(addVariable($1) == VAR_CREATED) {
						if($3->n == IVAL) {
							$$ = addNode(strcatN(7, "Var ", $1," = malloc(sizeof(VarCDT));\nvarWithInt(", $1, ", ", $3->str, ");\n"));
						} else if($3->n == DVAL) {
							$$ = addNode(strcatN(7, "Var ", $1," = malloc(sizeof(VarCDT));\nvarWithDbl(", $1, ", ", $3->str, ");\n"));
						} else if($3->n == SVAL) {
							$$ = addNode(strcatN(7, "Var ", $1," = malloc(sizeof(VarCDT));\nvarWithStr(", $1, ", ", $3->str, ");\n"));
						} else if($3->n == BVAL) {
							$$ = addNode(strcatN(7, "Var ", $1, " = malloc(sizeof(VarCDT));\nvarWithBool(", $1, ", ", $3->str, ");\n"));
						}
					} else {
						if($3->n == IVAL) {
							$$ = addNode(strcatN(5, "varWithInt(", $1, ", ", $3->str, ");\n"));
						} else if($3->n == DVAL) {
							$$ = addNode(strcatN(5, "varWithDbl(", $1, ", ", $3->str, ");\n"));
						} else if($3->n == SVAL) {
							$$ = addNode(strcatN(5, "varWithStr(", $1, ", ", $3->str, ");\n"));
						} else if($3->n == BVAL) {
							$$ = addNode(strcatN(5, "varWithBool(", $1, ", ", $3->str, ");\n"));
						}
					}
				}
		| IDENTIFIER '=' FunctionCall
				{
					if(addVariable($1) == VAR_CREATED) {
						$$ = addNode(strcatN(4, "Var ", $1, " = ", $3->str));
					} else {
						$$ = addNode(strcatN(3, $1, " = ", $3->str));
					}
				}
		| IDENTIFIER '=' Operation
				{
					if(!foundVariable($1)) {
						yyerror("Returned non-existent variable in function");
						return NOT_FOUND;
					}
					if(addVariable($1) == VAR_CREATED) {
						$$ = addNode(strcatN(7, "Var ", $1, "->", ($3->type == IVAL)? "i" : ($3->type == DVAL)? "d" : ($3->type == SVAL)? "s" : ($3->type == BVAL)? "b" : strcatN(4, $1, "->(", $3->baseId, "->t)"), " = ", $3->str, ";\n"));
					} else {
						if($3->type != UNKNOWN) {
							$$ = addNode(strcatN(6, $1, "->", ($3->type == IVAL)? "i" : ($3->type == DVAL)? "d" : ($3->type == SVAL)? "s" : "b", " = ", $3->str, ";\n"));
						} else {
							$$ = addNode(strcatN(17, "((", $3->baseId, "->t == INT)? ", $1, "->i : (", $3->baseId, "->t == DBL)? ", $1, "->d : (", $3->baseId, "->t == STR)? ", $1, "->str : ", $1, "->b) = ", $3->str, ";\n"));
						}
					}
				}
		//| IDENTIFIER '=' '(' Condition ')'
		//		{ $$ = addNode()}
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
				}/*
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
				}*/
		| RETURN Literal
				{
					if($2->n == IVAL) {
						$$ = addNode(strcatN(3, "return newVarWithInt(", $2->str, ");\n"));
					} else if($2->n == DVAL) {
						$$ = addNode(strcatN(3, "return newVarWithDbl(", $2->str, ");\n"));
					} else if($2->n == SVAL) {
						$$ = addNode(strcatN(3, "return newVarWithStr(", $2->str, ");\n"));
					} else if($2->n == BVAL) {
						$$ = addNode(strcatN(3, "return newVarWithBool(", $2->str, ");\n"));
					}
				}
		;

Operation
		: IDENTIFIER '+' IDENTIFIER
					{
						if(!(variableInCurrentFunction($1) && variableInCurrentFunction($3))) { // && NOT GLOBAL VAR
							return NOT_FOUND;
						}
						$$ = addOpNode(UNKNOWN, $1, strcatN(17, "switch(", $1, "->t) {\ncase INT: ", $1, "->i + ", $3, "->i;\nbreak;\ncase DBL: ", $1, "->d + ", $3, "->d;\nbreak;\ncase STR: strcat(", $1, "->str, ", $3, "->str);\nbreak;\ncase BOOL: ", $1, "->b\nbreak;\n}\n"));
					}
		| IDENTIFIER '+' Literal
					{
						if(!variableInCurrentFunction($1)) { // && NOT GLOBAL VAR
							return NOT_FOUND;
						}
						if($3->n == IVAL || $3->n == DVAL) {
							$$ = addOpNode(UNKNOWN, $1, strcatN(17, "switch(", $1, "->t) {\ncase INT: ", $1, "->i + ", $3->str, ";\nbreak;\ncase DBL: ", $1, "->d + ", $3->str, ";\nbreak;\ncase STR: strcat(", $1, "->str, \"", $3->str, "\");\nbreak;\ncase BOOL: ", $1, "->b\nbreak;\n}\n"));
						} else if($3->n == SVAL) {
							$$ = addOpNode(UNKNOWN, $1, strcatN(13, "switch(", $1, "->t) {\ncase INT: ", $1, "->i;\nbreak;\ncase DBL: ", $1, "->d;\nbreak;\ncase STR: strcat(", $1, "->str, ", $3->str, ");\nbreak;\ncase BOOL: ", $1, "->b\nbreak;\n}\n"));
						} else {
							$$ = addOpNode(UNKNOWN, $1, strcatN(11, "switch(", $1, "->t) {\ncase INT: ", $1, "->i;\nbreak;\ncase DBL: ", $1, "->d;\nbreak;\ncase STR: ", $1, "->str;\nbreak;\ncase BOOL: ", $1, "->b\nbreak;\n}\n"));
						}
					}
		| Literal '+' IDENTIFIER
					{
						if(!variableInCurrentFunction($3)) { // && NOT GLOBAL VAR
							return NOT_FOUND;
						}
						if($1->n == IVAL) {
							$$ = addOpNode(IVAL, NULL, strcatN(4, $1->str, " + ", $3, "->i"));
						} else if($1->n == DVAL) {
							$$ = addOpNode(DVAL, NULL, strcatN(4, $1->str, " + ", $3, "->d"));
						} else if($1->n == SVAL) {
							$$ = addOpNode(SVAL, NULL, strcatN(5, "strcat(", $1->str, ", ", $3, "->str)"));
						} else {
							$$ = addOpNode(BVAL, NULL, $1->str);
						}
					}
		| Literal '+' Literal
					{
						if($1->n == IVAL) {
							if($3->n == IVAL) {
								$$ = addOpNode(IVAL, NULL, strcatN(3, $1->str, " + ", $3->str));
							} else if($3->n == DVAL) {
								$$ = addOpNode(IVAL, NULL, strcatN(3, $1->str, " + (int)", $3->str));
							} else {
								$$ = addOpNode(IVAL, NULL, $1->str);
							}
						} else if($1->n == DVAL) {
							if($3->n == IVAL || $3->n == DVAL) {
								$$ = addOpNode(DVAL, NULL, strcatN(3, $1->str, " + ", $3->str));
							} else {
								$$ = addOpNode(DVAL, NULL, $1->str);
							}
						} else if($1->n == SVAL) {
							if($3->n == IVAL || $3->n == DVAL) {
								$$ = addOpNode(SVAL, NULL, strcatN(5, "strcat(", $1->str, ", \"", $3->str, "\")"));
							} else if($3->n == SVAL) {
								$$ = addOpNode(SVAL, NULL, strcatN(5, "strcat(", $1->str, ", ", $3->str, ")"));
							} else {
								$$ = addOpNode(SVAL, NULL, strcatN(5, "strcat(", $1->str, ", \"", ($3->str == "TRUE")? "true" : "false", "\")"));
							}
						} else {
							$$ = addOpNode(BVAL, NULL, $1->str);
						}
					}
		;

Literal
		: INT_LIT
				{
					char int_str[MAX_INT_STR_LENGTH];
          			sprintf(int_str, "%d", $1);
          			$$ = addIntNode(int_str, IVAL);
          		}
		| DBL_LIT
				{
					char double_str[MAX_DBL_STR_LENGTH];
          			sprintf(double_str, "%g", $1);
          			$$ = addIntNode(double_str, DVAL);
          		}
		| STR_LIT
				{
					$$ = addIntNode($1, SVAL);
				}
		| BOOL_LIT
				{
					$$ = addIntNode(($1 == TRUE)? "TRUE" : "FALSE", BVAL);
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

FunctionCall
		: IDENTIFIER '(' FunctionCallArgs ')'
				{
					Function f = getFunction($1);
					if(f == NULL) {
						yyerror("Function does not exist");
						return NOT_FOUND;
					}
					if(f->argc != $3->n) {
						yyerror("Argument count incompatible with prototype declaration");
						return ARGC_ERR;
					}
					$$ = addNode(strcatN(4, $1, "(", $3->str, ");\n"));
				}
		;

FunctionCallArgs
		: NonEmptyFunctionCallArgs
				{ $$ = addIntNode($1->str, $1->n); }
		|		{ $$ = addIntNode("", 0); }
		;

NonEmptyFunctionCallArgs
		: NonEmptyFunctionCallArgs ',' IDENTIFIER
				{
					if(!variableInCurrentFunction($3)) { // && NOT GLOBAL VAR
						return NOT_FOUND;
					}
					$$ = addIntNode(strcatN(3, $1->str, ", ", $3), $1->n + 1);
				}
		| IDENTIFIER
				{
					if(!variableInCurrentFunction($1)) {
						return NOT_FOUND;
					}
					$$ = addIntNode($1, 1);
				}
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

varStatus addVariable(char * varName) {
	Function func = gscope->functions[gscope->currentFunction];
	int i;
	for(i = 0; i < func->variableIndex; i++) {
		if(strcmp(varName, func->varLocal[i]->name) == 0) {
			return VAR_MODIFIED;
		}
	}
	if(i >= func->variableIndex) {
		func->varLocal[func->variableIndex] = malloc(sizeof(VariableCDT));
		func->varLocal[func->variableIndex++]->name = varName;
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

IntNode addIntNode(char * string, int n) {
	IntNode newNode = malloc(sizeof(IntNodeCDT));
	newNode->str = string;
	newNode->n = n;
	return newNode;
}

OpNode addOpNode(int type, char * baseId, char * string) {
	OpNode newNode = malloc(sizeof(OpNodeCDT));
	newNode->type = type;
	newNode->baseId = baseId;
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

char * repeatStr(char * str, int count) {
	if(count == 0)
		return NULL;
	char * ret = malloc(strlen(str) * count);
	while(count > 0) {
		strcat(ret, str);
		count--;
	}
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
