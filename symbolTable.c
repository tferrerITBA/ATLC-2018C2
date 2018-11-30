#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdio.h>
#include <stdarg.h>
#include "symbolTable.h"

extern FILE *yyin;
extern char * yytext;
FILE * fp;

int yylex();

extern Global gscope;


/*
 * InsertFunction will add a function to the global scope once its prototype was found.
 * The defined boolean is set to false (unless the function being inserted is main) because
 * it will be set to true once the function definition is found. If the prototype is present,
 * but the function is never defined, nothing will happen unless the undefined function is called.
 * CurrentFunction defines the scope to protect variables that will be added inside of the function
 * against changes made from another function.
 */

int insertFunction(char * name, int argc) {
	if(strcmp(name, FROZONE) == 0) {
		if(gscope->mainFound == TRUE) {
			yyerror("Not all of us are super");
			return MAIN_DUP;
		}
		gscope->mainFound = TRUE;
		Function f = malloc(sizeof(FunctionCDT));
		strcpy(f->name, name);
		f->argc = argc;
		f->variableIndex = 0;
		f->defined = TRUE;
		gscope->functions[0] = f;
		gscope->currentFunction = 0;
		return SUCCESS;
	}
	//name = getFunctionName(name);
	int i;
	for(i = 1; i < gscope->functionIndex; i++) {
		if(strcmp(name, gscope->functions[i]->name) == 0) {
			//yytext = $1;
			yyerror("Function already declared");
			return FUNC_DUP;
		}
	}
	Function f = malloc(sizeof(FunctionCDT));
	strcpy(f->name, name);
	f->argc = argc;
	f->variableIndex = 0;
	f->defined = FALSE;
	gscope->functions[gscope->functionIndex] = f;
	gscope->currentFunction = gscope->functionIndex++;
	return SUCCESS;
}


/*
 * Ignores the function prefix.
 */
char * getFunctionName(char * str) {
	str += strlen("function");
	while(isspace(*str))
		str++;
	return str;
}


/*
 * This function is called when a function definition is found by lex. If the prototype for that function
 * is missing, the program will not compile. Also, the function's arguments will be compared to those declared above.
 *
 */

int foundFunction(char * name) {
	name = getFunctionName(name);
	int i;
	for(i = 1; i < gscope->functionIndex; i++) {
		if(strcmp(name, gscope->functions[i]->name) == 0) {
			Function f = gscope->functions[i];
			if(f->defined == TRUE) {
				yyerror("Function already defined");
				return FUNC_DUP;
			} else {
				f->defined = TRUE;
				gscope->currentFunction = i;
				return SUCCESS;
			}
			/*if(strcmp(args, f->args) != 0) {
				yyerror("Argument count incompatible with prototype declaration");
				return FUNC_DUP;
			}*/
			//return i;
		}
	}
	yyerror("Defined function missing prototype");
	return NOT_FOUND;
}

int ArgcMatchesPrototype(char * name, int argc) {
	if(gscope->functions[gscope->currentFunction]->argc != argc) {
		yyerror("Argument count incompatible with prototype declaration");
		return FALSE;
	} else {
		return TRUE;
	}
}

Function getFunction(char * name) {
	int i;
	for(i = 0; i < gscope->functionIndex; i++) {
		if(strcmp(name, gscope->functions[i]->name) == 0) {
			return gscope->functions[i];
		}
	}
	return NULL;
}

int variableInCurrentFunction(char * name) {
	int i;
	for(i = 0; i < gscope->functions[gscope->currentFunction]->variableIndex; i++) {
		if(strcmp(name, gscope->functions[gscope->currentFunction]->varLocal[i]->name) == 0) {
			return TRUE;
		}
	}
	yyerror("Unknown variable");
	return FALSE;
}

void addNewVariable(char * varName) {
	Function f = gscope->functions[gscope->currentFunction];
	f->varLocal[f->variableIndex] = malloc(sizeof(VariableCDT));
	f->varLocal[f->variableIndex++]->name = varName;
	return;
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

OpNode addOpNode(int type, char * baseId, char * intStr, char * dblStr, char * strStr, char * boolStr) {
	OpNode newNode = malloc(sizeof(OpNodeCDT));
	newNode->type = type;
	newNode->baseId = baseId;
	newNode->firstArgIntStr = intStr;
	newNode->firstArgDblStr = dblStr;
	newNode->firstArgStrStr = strStr;
	newNode->firstArgBoolStr = boolStr;
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

char * repeatStr(char * str, int count, int final) {
	if(count == 0)
		return NULL;
	int auxCount = count;
	char * ret = malloc(strlen(str) * count);
	while(count > 0) {
		strcat(ret, str);
		count--;
	}
	ret[strlen(str) * auxCount - final] = '\0';
	return ret;
}

char * strFromIntArithmOp(arithmOp op) {
	if(op == PLUS) {
		return " + ";
	} else if(op == MINUS) {
		return " - ";
	} else if(op == MULT) {
		return " * ";
	} else if(op == DIV) {
		return " / ";
	}
}

char * strFromIntRelOp(relationalOp op) {
	if(op == EQ) {
		return " == ";
	} else if(op == LT) {
		return " < ";
	} else if(op == GT) {
		return " > ";
	} else if(op == NE) {
		return " != ";
	}
}

char * strFromIntLogOp(logicalOp op) {
	if(op == AND) {
		return " && ";
	} else if(op == OR) {
		return " || ";
	}
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

int string_ends_with(const char * str, const char * suffix)
{
  int str_len = strlen(str);
  int suffix_len = strlen(suffix);

  return
    (str_len >= suffix_len) &&
    (0 == strcmp(str + (str_len-suffix_len), suffix));
}
