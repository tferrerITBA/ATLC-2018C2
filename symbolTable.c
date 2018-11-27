#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "symbolTable.h"

extern Global gscope;

int insertFunction(char * name) {
	if(strcmp(name, FROZONE) == 0) {
		if(gscope->mainFound == TRUE) {
			yyerror("No todos somos super");
			return MAIN_DUP;
		}
		Function f = malloc(sizeof(FunctionCDT));
		strcpy(f->name, name);
		f->variableIndex = 0;
		gscope->functions[0] = f;
		gscope->currentFunction = 0;
		return SUCCESS;
	}
	name = getFunctionName(name);
	int i;
	for(i = 1; i < gscope->functionIndex; i++) {
		if(strcmp(name, gscope->functions[i]->name) == 0) {
			//yytext = $1;
			yyerror("No todos somos super 2");
			return FUNC_DUP;
		}
	}
	Function f = malloc(sizeof(FunctionCDT));
	strcpy(f->name, name);
	f->variableIndex = 0;
	gscope->functions[gscope->functionIndex] = f;
	gscope->currentFunction = gscope->functionIndex++;
	return SUCCESS;
}

char * getFunctionName(char * str) {
	str += strlen("function");
	while(isspace(*str))
		str++;
	return str;
}
