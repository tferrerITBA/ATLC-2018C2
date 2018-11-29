#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define MAX_STR_LENGTH 100

typedef enum { INT, DBL, STR, BOOL } type;

typedef struct VarCDT * Var;

typedef struct VarCDT {
	int i;
	double d;
	char * str;
	bool b;
	type t;
} VarCDT;

Var newVarWithInt(int num);
Var newVarWithDbl(double num);
Var newVarWithStr(char * string);
Var newVarWithBool(bool boolean);
Var varWithInt(Var v, int num);
Var varWithDbl(Var v, double num);
Var varWithStr(Var v, char * string);
Var varWithBool(Var v, bool boolean);

Var newVarWithInt(int num) {
	Var v = malloc(sizeof(VarCDT));
	v->str = malloc(MAX_STR_LENGTH);
	return varWithInt(v, num);
}

Var newVarWithDbl(double num) {
	Var v = malloc(sizeof(VarCDT));
	v->str = malloc(MAX_STR_LENGTH);
	return varWithDbl(v, num);
}

Var newVarWithStr(char * string) {
	Var v = malloc(sizeof(VarCDT));
	v->str = malloc(MAX_STR_LENGTH);
	return varWithStr(v, string);
}

Var newVarWithBool(bool boolean) {
	Var v = malloc(sizeof(VarCDT));
	v->str = malloc(MAX_STR_LENGTH);
	return varWithBool(v, boolean);
}

Var varWithInt(Var v, int num) {
	v->i = num;
	v->d = num;
	sprintf(v->str, "%d", num);
	v->b = (num)? TRUE : FALSE;
	v->t = INT;
	return v;
}

Var varWithDbl(Var v, double num) {
	v->i = (int) num;
	v->d = num;
	sprintf(v->str, "%g", num);
	v->b = ((int) num)? TRUE : FALSE;
	v->t = DBL;
	return v;
}

Var varWithStr(Var v, char * string) {
	v->i = atoi(string);
	v->d = atof(string);
	strcpy(v->str, string);
	v->b = (*string)? TRUE : FALSE;
	v->t = STR;
	return v;
}

Var varWithBool(Var v, bool boolean) {
	if(boolean) {
		v->i = 1;
		v->d = 1.0;
		v->str = "true";
	} else {
		v->i = 0;
		v->d = 0.0;
		v->str = "false";
	}
	v->b = boolean;
	v->t = BOOL;
	return v;
}
