#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "symbolTable.h"

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

char * strFromIntLogOp(logicalOp op) {
	if(op == AND) {
		return " && ";
	} else if(op == OR) {
		return " || ";
	}
}
