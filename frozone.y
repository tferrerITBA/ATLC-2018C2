%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include "symbolTable.h"
	#include <stdarg.h> 
   
  	#define STR_BLOCK 10 
	#define TRUE 1
    #define FALSE 0
	
	#define STR_BLOCK 10
	
	extern FILE *yyin;
	FILE * fp;

	int yylex();
	void yyerror(const char *s);

	void addVariable(char * id, int type, void * value);
	Node * addNode(char * string);
	char * strcatN(int num, ...);
%}

%union {
	int ival;
	float fval;
	int bval;
	char * sval;
	Node * node;
}

%token MAIN_ID ON DO
%token <sval> IDENTIFIER
%token OP_EQ OP_LT OP_GT OP_LE OP_GE OP_NE
%token <ival> INT_LIT
%token <fval> FL_LIT
%token <bval> BOOL_LIT
%token <sval> STR_LIT

%type<node> Program GlobalFunctionList MainFunction FunctionList Function FunctionBody Statement VarDeclaration OnStatement

%start Program

%%

Program
		: GlobalFunctionList
				{ $$ = addNode(strcatN(1, $1->str)); fprintf(fp, "%s", $$->str); }
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
				{ $$ = addNode(strcatN(3, "int main() {\n", $5->str, "}\n")); }
		;

FunctionList
		: FunctionList Function
				{ $$ = addNode(strcatN(2, $1->str, $2->str)); }
		| Function
				{ $$ = addNode(strcatN(1, $1->str)); }
		;

Function
		: IDENTIFIER '(' FunctionArguments ')' '{' FunctionBody '}'
				{ /*printf("FUNCION %s END\n", $1);*/$$ = addNode(strcatN(1, "\n")); }
		;

FunctionArguments
		:
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
		: IDENTIFIER '=' INT_LIT			//{ addVariable($1, IVAL, $3); }
				{ /*printf("%s",$1);*/$$ = addNode(strcatN(3, "int ", $1, ";\n")); }
		| IDENTIFIER '=' FL_LIT				//{ addVariable($1, FVAL, $3); }
				{ $$ = addNode(strcatN(3, "float ", $1, ";\n")); }
		| IDENTIFIER '=' STR_LIT			//{ addVariable($1, SVAL, $3); }
				{ $$ = addNode(strcatN(3, "char * ", $1, ";\n")); }
		| IDENTIFIER '=' BOOL_LIT			//{ addVariable($1, BVAL, $3); }
				{ $$ = addNode(strcatN(5, "int ", $1, " = ", ($3 == TRUE)? "TRUE" : "FALSE", ";\n")); }  //CUT $1
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

   if(!yyparse())
        printf("\nParsing complete\n");
    else
        printf("\nParsing failed\n");

	fclose(fp);

    fclose(yyin);
    return 0;
}

void addVariable(char * id, int type, void * value) {
	
}

Node * addNode(char * string) {
	Node * newNode = malloc(sizeof(Node));
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
