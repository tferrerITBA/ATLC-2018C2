%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include "symbolTable.h"
	#include <stdarg.h>

	#define TRUE 1
  	#define FALSE 0

	extern FILE *yyin;
	extern char * yytext;
	FILE * fp;

	int yylex();

	Global gscope;
%}

%union {
	double dval;
	bool bval;
	char * sval;
	Node node;
	IntNode intnode;
	OpNode opnode;
	arithmOp aop;
	relationalOp rop;
	logicalOp logop;
}

%token <sval> MAIN_ID
%token <sval> FN_ID
%token ON DO CYCLE
%token <sval> IDENTIFIER
%token <sval> INT_LIT
%token <sval> DBL_LIT
%token <bval> BOOL_LIT
%token <sval> STR_LIT
%token <aop> ARITHM_OP
%token <rop> REL_OP
%token <logop> LOG_OP
%token <sval> RETURN
%token <sval> PRINT

%type<node> Program HeaderSection FunctionPrototypes FunctionPrototype GlobalFunctionList MainFunction FunctionList Function FunctionBody Statement VarDeclaration FunctionCall OnStatement CycleStatement ReturnStatement PrintStatement
%type<intnode> FunctionArguments NonEmptyFunctionArguments FunctionCallArgs NonEmptyFunctionCallArgs Literal
%type<opnode> Operation Condition

%start Program

%%

Program
		: HeaderSection GlobalFunctionList
				{ $$ = addNode(strcatN(2, $1->str, $2->str)); fprintf(fp, "%s", $$->str); } // METER EN EL .H
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
					$$ = addNode(strcatN(5, "Var ", $1, "(", repeatStr("Var, ", atoi($3->str), 2), ");\n"));//FALTAN ARGS
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
		: MAIN_ID '(' ')' '{' FunctionBody '}'
				{
					$$ = addNode(strcatN(3, "int main() {\n", $5->str, "return 0;\n}\n\n"));
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
				{ $$ = addNode($1->str); }
		| OnStatement
				{ $$ = addNode($1->str); }
		| CycleStatement
				{ $$ = addNode($1->str); }
		| ReturnStatement
				{ $$ = addNode($1->str); }
		| PrintStatement
				{ $$ = addNode($1->str); }
		;

VarDeclaration
		: IDENTIFIER '=' Literal
				{
					if(addVariable($1) == VAR_CREATED) {
						if($3->n == IVAL) {
							$$ = addNode(strcatN(5, "Var ", $1, " = newVarWithInt(", $3->str, ");\n"));
						} else if($3->n == DVAL) {
							$$ = addNode(strcatN(5, "Var ", $1, " = newVarWithDbl(", $3->str, ");\n"));
						} else if($3->n == SVAL) {
							$$ = addNode(strcatN(5, "Var ", $1, " = newVarWithStr(", $3->str, ");\n"));
						} else if($3->n == BVAL) {
							$$ = addNode(strcatN(5, "Var ", $1, " = newVarWithBool(", $3->str, ");\n"));
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
					if(addVariable($1) == VAR_CREATED) {
						if($3->type == IVAL) {
							$$ = addNode(strcatN(5, "Var ", $1, " = newVarWithInt(", $3->firstArgIntStr, ");\n"));
						} else if($3->type == DVAL) {
							$$ = addNode(strcatN(5, "Var ", $1, " = newVarWithDbl(", $3->firstArgDblStr, ");\n"));
						} else if($3->type == SVAL) {
							$$ = addNode(strcatN(5, "Var ", $1, " = newVarWithStr(", $3->firstArgStrStr, ");\n"));
						} else if($3->type == BVAL) {
							$$ = addNode(strcatN(5, "Var ", $1, " = newVarWithBool(", $3->firstArgBoolStr, ");\n"));
						} else if($3->type == UNKNOWN) {
							$$ = addNode(strcatN(23, "if(", $3->baseId, "->t == INT) {\nVar ", $1, " = newVarWithInt(", $3->firstArgIntStr, ");\n} else if(", $3->baseId, "->t == DBL) {\nVar ", $1, " = newVarWithDbl(", $3->firstArgDblStr, ");\n} else if(", $3->baseId, "->t == STR) {\nVar ", $1, " = newVarWithStr(", $3->firstArgStrStr, ");\n} else {\nVar ", $1, " = newVarWithBool(", $3->firstArgBoolStr, ");\n}\n"));
						}
					} else {
						if($3->type == IVAL) {
							$$ = addNode(strcatN(6, $1, " = varWithInt(", $1, ", ", $3->firstArgIntStr, ");\n"));
						} else if($3->type == DVAL) {
							$$ = addNode(strcatN(6, $1, " = varWithDbl(", $1, ", ", $3->firstArgDblStr, ");\n"));
						} else if($3->type == SVAL) {
							$$ = addNode(strcatN(6, $1, " = varWithStr(", $1, ", ", $3->firstArgStrStr, ");\n"));
						} else if($3->type == BVAL) {
							$$ = addNode(strcatN(6, $1, " = varWithBool(", $1, ", ", $3->firstArgBoolStr, ");\n"));
						} else if($3->type == UNKNOWN) {
							$$ = addNode(strcatN(31, "if(", $3->baseId, "->t == INT) {\n", $1, " = varWithInt(", $1, ", ", $3->firstArgIntStr, ");\n} else if(", $3->baseId, "->t == DBL) {\n", $1, " = varWithDbl(", $1, ", ", $3->firstArgDblStr, ");\n} else if(", $3->baseId, "->t == STR) {\n", $1, " = varWithStr(", $1, ", ", $3->firstArgStrStr, ");\n} else {\n", $1, " = varWithBool(", $1, ", ", $3->firstArgBoolStr, ");\n}\n"));
						}
					}
				}
		| IDENTIFIER '=' Condition
				{
					if(addVariable($1) == VAR_CREATED) {
						$$ = addNode(strcatN(5, "Var ", $1, " = newVarWithBool(", $3->firstArgBoolStr, ");\n"));
					} else {
						$$ = addNode(strcatN(6, $1, " = varWithBool(", $1, ", ", $3->firstArgBoolStr, ");\n"));
					}
				}
		;

OnStatement
		: ON Condition DO '{' FunctionBody '}'
				{
					if($2->type == BVAL) {
						$$ = addNode(strcatN(5, "if(", $2->firstArgBoolStr, ") {\n", $5->str, "}\n")); }
					}
		;

CycleStatement
	: CYCLE '{' FunctionBody '}' ON Condition
				{ $$ = addNode(strcatN(5, "do {\n", $3->str, "} while(", $6->firstArgBoolStr, ");\n")); }
	;

ReturnStatement
		: RETURN IDENTIFIER
				{
					if(gscope->currentFunction == 0) {
						yyerror("Main function cannot have return statement");
						return MAIN_RET;
					}
					if(!foundVariable($2)) {
						yyerror("Returned non-existent variable in function");
						return NOT_FOUND;
					}
					$$ = addNode(strcatN(3, "return ", $2, ";\n"));
				}
		| RETURN Literal
				{
					if(gscope->currentFunction == 0) {
						yyerror("Main function cannot have return statement");
						return MAIN_RET;
					}
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

PrintStatement
		: PRINT '(' IDENTIFIER ')'
				{
					if(!variableInCurrentFunction($3)) { // && NOT GLOBAL VAR
						return NOT_FOUND;
					}
					$$ = addNode(strcatN(17, "if(", $3, "->t == INT) {\nprintf(\"%d\\n\", ", $3, "->i);\n} else if(", $3, "->t == DBL) {\nprintf(\"%g\\n\", ", $3, "->d);\n} else if(", $3, "->t == STR) {\nprintf(\"%s\\n\", ", $3, "->str);\n} else if(", $3, "->t == BOOL) {\nprintf(\"%s\\n\", (", $3, "->b)? \"true\" : \"false\");\n}\n"));
				}
		| PRINT '(' Literal ')'
				{
					if($3->n == IVAL) {
						$$ = addNode(strcatN(3, "printf(\"%d\\n\", ", $3->str, ");\n"));
					} else if($3->n == DVAL) {
						$$ = addNode(strcatN(3, "printf(\"%g\\n\", ", $3->str, ");\n"));
					} else if($3->n == SVAL) {
						$$ = addNode(strcatN(3, "printf(\"%s\\n\", ", $3->str, ");\n"));
					} else if($3->n == BVAL) {
						$$ = addNode(strcatN(3, "printf(\"%s\\n\", (", $3->str, ")? \"true\" : \"false\");\n"));
					}
				}
		;

Operation
		: IDENTIFIER ARITHM_OP IDENTIFIER
					{
						if(!(variableInCurrentFunction($1) && variableInCurrentFunction($3))) { // && NOT GLOBAL VAR
							return NOT_FOUND;
						}
						if($2 == PLUS) {
							$$ = addOpNode(UNKNOWN, $1, strcatN(4, $1, "->i + ", $3, "->i"), strcatN(4, $1, "->d + ", $3, "->d"), strcatN(5, "strcatN(2, ", $1, "->str, ", $3, "->str)"), strcatN(2, $1, "->b"));
						} else {
							$$ = addOpNode(UNKNOWN, $1, strcatN(6, $1, "->i ", strFromIntArithmOp($2), " ", $3, "->i"), strcatN(6, $1, "->d ", strFromIntArithmOp($2), " ", $3, "->d"), strcatN(2, $1, "->str"), strcatN(2, $1, "->b"));
						}
					}
		| IDENTIFIER ARITHM_OP Literal
					{
						if(!variableInCurrentFunction($1)) { // && NOT GLOBAL VAR
							return NOT_FOUND;
						}
						if($3->n == IVAL || $3->n == DVAL) {
							if($2 == PLUS) {
								$$ = addOpNode(UNKNOWN, $1, strcatN(3, $1, "->i + ", $3->str), strcatN(3, $1, "->d + ", $3->str), strcatN(5, "strcatN(2, ", $1, "->str, \"", $3->str, "\")"), strcatN(2, $1, "->b"));
							} else {
								$$ = addOpNode(UNKNOWN, $1, strcatN(5, $1, "->i ", strFromIntArithmOp($2), " ", $3->str), strcatN(5, $1, "->d ", strFromIntArithmOp($2), " ", $3->str), strcatN(2, $1, "->str"), strcatN(2, $1, "->b"));
							}
						} else if($3->n == SVAL) {
							if($2 == PLUS) {
								$$ = addOpNode(UNKNOWN, $1, strcatN(2, $1, "->i"), strcatN(2, $1, "->d"), strcatN(5, "strcatN(2, ", $1, "->str, ", $3->str, ")"), strcatN(2, $1, "->b"));
							} else {
								$$ = addOpNode(UNKNOWN, $1, strcatN(2, $1, "->i"), strcatN(2, $1, "->d"), strcatN(2, $1, "->str"), strcatN(2, $1, "->b"));
							}
						} else if($3->n == BVAL) {
							$$ = addOpNode(UNKNOWN, $1, strcatN(2, $1, "->i"), strcatN(2, $1, "->d"), strcatN(2, $1, "->str"), strcatN(2, $1, "->b"));
						}
					}
		| Literal ARITHM_OP IDENTIFIER
					{
						if(!variableInCurrentFunction($3)) { // && NOT GLOBAL VAR
							return NOT_FOUND;
						}
						if($2 == PLUS) {
							if($1->n == IVAL) {
								$$ = addOpNode(IVAL, NULL, strcatN(4, $1->str, " + ", $3, "->i"), NULL, NULL, NULL);
							} else if($1->n == DVAL) {
								$$ = addOpNode(DVAL, NULL, NULL, strcatN(4, $1->str, " + ", $3, "->d"), NULL, NULL);
							} else if($1->n == SVAL) {
								$$ = addOpNode(SVAL, NULL, NULL, NULL, strcatN(5, "strcatN(2, ", $1->str, ", ", $3, "->str)"), NULL);
							} else {
								$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, $1->str);
							}
						} else if($2 == MINUS) {
							if($1->n == IVAL) {
								$$ = addOpNode(IVAL, NULL, strcatN(4, $1->str, " - ", $3, "->i"), NULL, NULL, NULL);
							} else if($1->n == DVAL) {
								$$ = addOpNode(DVAL, NULL, NULL, strcatN(4, $1->str, " - ", $3, "->d"), NULL, NULL);
							} else if($1->n == SVAL) {
								$$ = addOpNode(SVAL, NULL, NULL, NULL, $1->str, NULL);
							} else {
								$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, $1->str);
							}
						} else if($2 == MULT) {
							if($1->n == IVAL) {
								$$ = addOpNode(IVAL, NULL, strcatN(4, $1->str, " * ", $3, "->i"), NULL, NULL, NULL);
							} else if($1->n == DVAL) {
								$$ = addOpNode(DVAL, NULL, NULL, strcatN(4, $1->str, " * ", $3, "->d"), NULL, NULL);
							} else if($1->n == SVAL) {
								$$ = addOpNode(SVAL, NULL, NULL, NULL, $1->str, NULL);
							} else {
								$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, $1->str);
							}
						} else if($2 == DIV) {
							if($1->n == IVAL) {
								$$ = addOpNode(IVAL, NULL, strcatN(4, $1->str, " / ", $3, "->i"), NULL, NULL, NULL);
							} else if($1->n == DVAL) {
								$$ = addOpNode(DVAL, NULL, NULL, strcatN(4, $1->str, " / ", $3, "->d"), NULL, NULL);
							} else if($1->n == SVAL) {
								$$ = addOpNode(SVAL, NULL, NULL, NULL, $1->str, NULL);
							} else {
								$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, $1->str);
							}
						}
					}
		| Literal ARITHM_OP Literal
					{
						if($2 == PLUS) {
							if($1->n == IVAL) {
								if($3->n == IVAL) {
									$$ = addOpNode(IVAL, NULL, strcatN(3, $1->str, " + ", $3->str), NULL, NULL, NULL);
								} else if($3->n == DVAL) {
									$$ = addOpNode(IVAL, NULL, strcatN(3, $1->str, " + (int)", $3->str), NULL, NULL, NULL);
								} else {
									$$ = addOpNode(IVAL, NULL, $1->str, NULL, NULL, NULL);
								}
							} else if($1->n == DVAL) {
								if($3->n == IVAL || $3->n == DVAL) {
									$$ = addOpNode(DVAL, NULL, NULL, strcatN(3, $1->str, " + ", $3->str), NULL, NULL);
								} else {
									$$ = addOpNode(DVAL, NULL, NULL, $1->str, NULL, NULL);
								}
							} else if($1->n == SVAL) {
								if($3->n == IVAL || $3->n == DVAL) {
									$$ = addOpNode(SVAL, NULL, NULL, NULL, strcatN(5, "strcatN(2, ", $1->str, ", \"", $3->str, "\")"), NULL);
								} else if($3->n == SVAL) {
									$$ = addOpNode(SVAL, NULL, NULL, NULL, strcatN(5, "strcatN(2, ", $1->str, ", ", $3->str, ")"), NULL);
								} else {
									$$ = addOpNode(SVAL, NULL, NULL, NULL, strcatN(5, "strcatN(2, ", $1->str, ", \"", ($3->str == "TRUE")? "true" : "false", "\")"), NULL);
								}
							} else if($1->n == BVAL) {
								$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, $1->str);
							}
						} else {
							if($1->n == IVAL) {
								if($3->n == IVAL) {
									$$ = addOpNode(IVAL, NULL, strcatN(3, $1->str, strFromIntArithmOp($2), $3->str), NULL, NULL, NULL);
								} else if($3->n == DVAL) {
									$$ = addOpNode(IVAL, NULL, strcatN(4, $1->str, strFromIntArithmOp($2), "(int)", $3->str), NULL, NULL, NULL);
								} else {
									$$ = addOpNode(IVAL, NULL, $1->str, NULL, NULL, NULL);
								}
							} else if($1->n == DVAL) {
								if($3->n == IVAL || $3->n == DVAL) {
									$$ = addOpNode(DVAL, NULL, NULL, strcatN(3, $1->str, strFromIntArithmOp($2), $3->str), NULL, NULL);
								} else {
									$$ = addOpNode(DVAL, NULL, NULL, $1->str, NULL, NULL);
								}
							} else if($1->n == SVAL) {
								if($3->n == IVAL || $3->n == DVAL) {
									$$ = addOpNode(SVAL, NULL, NULL, NULL, $1->str, NULL);
								} else if($3->n == SVAL) {
									$$ = addOpNode(SVAL, NULL, NULL, NULL, $1->str, NULL);
								} else {
									$$ = addOpNode(SVAL, NULL, NULL, NULL, $1->str, NULL);
								}
							} else if($1->n == BVAL) {
								$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, $1->str);
							}
						}
					}
		;

Literal
		: INT_LIT		{ $$ = addIntNode($1, IVAL); }
		| DBL_LIT		{ $$ = addIntNode($1, DVAL); }
		| STR_LIT		{ $$ = addIntNode($1, SVAL); }
		| BOOL_LIT		{ $$ = addIntNode(($1)? "TRUE" : "FALSE", BVAL); }
		;

Condition
		: '(' IDENTIFIER REL_OP IDENTIFIER ')'
				{
					if(!(variableInCurrentFunction($2) && variableInCurrentFunction($4))) { // && NOT GLOBAL VAR
						return NOT_FOUND;
					}
					if($3 == EQ) {
						$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(6, "fabs(", $2, "->d - ", $4, "->d) < ", EPSILON));
					} else if($3 == NE) {
						$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(6, "fabs(", $2, "->d - ", $4, "->d) > ", EPSILON));
					} else {
						$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(5, $2, "->d", strFromIntRelOp($3), $4, "->d"));
					}
				}
		| '(' IDENTIFIER REL_OP Literal ')'
				{
					if(!(variableInCurrentFunction($2))) { // && NOT GLOBAL VAR
						return NOT_FOUND;
					}
					if($4->n == IVAL) {
						$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(4, $2, "->i", strFromIntRelOp($3), $4->str));
					} else if($4->n == DVAL) {
						if($3 == EQ) {
							$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(6, "fabs(", $2, "->d, ", $4->str, ") < ", EPSILON));
						} else if($3 == NE) {
							$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(6, "fabs(", $2, "->d, ", $4->str, ") > ", EPSILON));
						} else if($3 == LT || $3 == GT) {
							$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(4, $2, "->d", strFromIntRelOp($3), $4->str));
						}
					} else if($4->n == SVAL) {
						$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(7, "strcmp(", $2, "->str, ", $4->str, ")", strFromIntRelOp($3), "0"));
					} else if($4->n == BVAL) {
						$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(4, $2, "->b", strFromIntRelOp($3), $4->str));
					}
				}
		| '(' Literal REL_OP IDENTIFIER ')'
				{
					if(!(variableInCurrentFunction($4))) { // && NOT GLOBAL VAR
						return NOT_FOUND;
					}
					if($2->n == IVAL) {
						$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(4, $2->str, strFromIntRelOp($3), $4, "->i"));
					} else if($2->n == DVAL) {
						if($3 == EQ) {
							$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(6, "fabs(", $2->str, ", ", $4, "->d) < ", EPSILON));
						} else if($3 == NE) {
							$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(6, "fabs(", $2->str, ", ", $4, "->d) > ", EPSILON));
						} else if($3 == LT || $3 == GT) {
							$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(4, $2->str, strFromIntRelOp($3), $4, "->d"));
						}
					} else if($2->n == SVAL) {
						$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(7, "strcmp(", $2->str, ", ", $4, "->str)", strFromIntRelOp($3), "0"));
					} else if($2->n == BVAL) {
						$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(4, $2->str, strFromIntRelOp($3), $4, "->b"));
					}
				}
		| '(' IDENTIFIER ')'
				{
					if(!(variableInCurrentFunction($2))) { // && NOT GLOBAL VAR
						return NOT_FOUND;
					}
					$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(2, $2, "->b"));
				}
		| '(' Literal ')'
				{
					if($2->n == IVAL) {
						$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(3, "newVarWithInt(", $2->str, ")->b"));
					} else if($2->n == DVAL) {
						$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(3, "newVarWithDbl(", $2->str, ")->b"));
					} else if($2->n == SVAL) {
						$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(3, "newVarWithStr(", $2->str, ")->b"));
					} else if($2->n == BVAL) {
						$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, $2->str);
					}
				}
		| '(' Condition LOG_OP Condition ')'
				{
					if($3 == NOT) {
						yyerror("\"Not\" operator is not binary");
					}
					$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(7, "(", $2->firstArgBoolStr, ")", strFromIntLogOp($3), "(", $4->firstArgBoolStr, ")"));
				}
		| '(' Condition LOG_OP IDENTIFIER ')'
				{
					if(!(variableInCurrentFunction($4))) { // && NOT GLOBAL VAR
						return NOT_FOUND;
					}
					if($3 == NOT) {
						yyerror("\"Not\" operator is not binary");
					}
					$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(6, "(", $2->firstArgBoolStr, ")", strFromIntLogOp($3), $4, "->b"));
				}
		| '(' IDENTIFIER LOG_OP Condition ')'
				{
					if(!(variableInCurrentFunction($2))) { // && NOT GLOBAL VAR
						return NOT_FOUND;
					}
					if($3 == NOT) {
						yyerror("\"Not\" operator is not binary");
					}
					$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(6, $2, "->b", strFromIntLogOp($3), "(", $4->firstArgBoolStr, ")"));
				}
		| '(' IDENTIFIER LOG_OP IDENTIFIER ')'
				{
					if(!(variableInCurrentFunction($2) && variableInCurrentFunction($4))) { // && NOT GLOBAL VAR
						return NOT_FOUND;
					}
					if($3 == NOT) {
						yyerror("\"Not\" operator is not binary");
					}
					$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(5, $2, "->b", strFromIntLogOp($3), $4, "->b"));
				}
		| '(' LOG_OP Condition ')'
				{
					if($2 != NOT) {
						yyerror("Logical operator used is not unary");
					}
					$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(3, "!(", $3->firstArgBoolStr, ")"));
				}
		| '(' LOG_OP IDENTIFIER ')'
				{
					if(!(variableInCurrentFunction($3))) { // && NOT GLOBAL VAR
						return NOT_FOUND;
					}
					if($2 != NOT) {
						yyerror("Logical operator used is not unary");
					}
					$$ = addOpNode(BVAL, NULL, NULL, NULL, NULL, strcatN(3, "!", $3, "->b"));
				}
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

		if (!string_ends_with(argv[1],".f")){
			fprintf(stderr, "Input file must have '.f' extension : %s\n", argv[1]);
			return 1;
		}

		file = fopen(argv[1], "r");
		if(!file) {
			fprintf(stderr, "Error while opening input file : %s\n", argv[1]);
			return 1;
		}
		yyin = file;
	}

	fp = fopen("test.c", "w+"); 			//Usar argv[1]

	fprintf(fp, "#include <stdlib.h> \n \
#include <stdio.h> \n \
#include <string.h> \n \
#include <stdarg.h> \n \
#include \"math.h\" \n \
\n \
#define MAX_STR_LENGTH 100 \n \
#define STR_BLOCK 10 \n \
\n \
typedef enum { INT, DBL, STR, BOOL } type; \n \
typedef enum { FALSE = 0 , TRUE } bool;\n\
typedef struct VarCDT * Var; \n \
typedef struct VarCDT {\n \
	int i;\n \
	double d;\n \
	char * str;\n \
	bool b;\n \
	type t;\n \
} VarCDT;\n \
\n \
Var newVarWithInt(int num);\n \
Var newVarWithDbl(double num);\n \
Var newVarWithStr(char * string);\n \
Var newVarWithBool(bool boolean);\n \
Var varWithInt(Var v, int num);\n \
Var varWithDbl(Var v, double num);\n \
Var varWithStr(Var v, char * string);\n \
Var varWithBool(Var v, bool boolean);\n \
char * strcatN(int num, ...);\n \
\n \
Var newVarWithInt(int num) {\n \
	Var v = malloc(sizeof(VarCDT));\n \
	v->str = malloc(MAX_STR_LENGTH);\n \
	return varWithInt(v, num);\n \
}\n \
\n \
Var newVarWithDbl(double num) { \n \
	Var v = malloc(sizeof(VarCDT));\n \
	v->str = malloc(MAX_STR_LENGTH);\n \
	return varWithDbl(v, num);\n \
}\n \
\n \
Var newVarWithStr(char * string) {\n \
	Var v = malloc(sizeof(VarCDT));\n \
	v->str = malloc(MAX_STR_LENGTH);\n \
	return varWithStr(v, string);\n \
}\n \
\n \
Var newVarWithBool(bool boolean) {\n \
	Var v = malloc(sizeof(VarCDT));\n \
	v->str = malloc(MAX_STR_LENGTH);\n \
	return varWithBool(v, boolean);\n \
}\n \
\n \
Var varWithInt(Var v, int num) {\n \
	v->i = num;\n \
	v->d = num;\n \
	sprintf(v->str, \"%%d\", num);\n \
	v->b = (num)? TRUE : FALSE;\n \
	v->t = INT;\n \
	return v;\n \
}\n \
\n \
Var varWithDbl(Var v, double num) {\n \
	v->i = (int) num;\n \
	v->d = num;\n \
	sprintf(v->str, \"%%g\", num);\n \
	v->b = ((int) num)? TRUE : FALSE;\n \
	v->t = DBL;\n \
	return v;\n \
}\n \
\n \
Var varWithStr(Var v, char * string) {\n \
	v->i = atoi(string);\n \
	v->d = atof(string);\n \
	strcpy(v->str, string);\n \
	v->b = (*string)? TRUE : FALSE;\n \
	v->t = STR;\n \
	return v;\n \
}\n \
\n \
Var varWithBool(Var v, bool boolean) {\n \
	if(boolean) {\n \
		v->i = 1;\n \
		v->d = 1.0;\n \
		sprintf(v->str, \"true\");\n \
	} else {\n \
		v->i = 0;\n \
		v->d = 0.0;\n \
		sprintf(v->str, \"false\");\n \
	}\n \
	v->b = boolean;\n \
	v->t = BOOL;\n \
	return v;\n \
} \n \
\n \
char * strcatN(int num, ...) { \n \
	va_list valist; \n \
	char * ret = NULL; \n \
	int len = 0; \n \
	int i; \n \
  	va_start(valist, num); \n \
  	for(i = 0; i < num; i++) { \n \
    	char * param = va_arg(valist, char *); \n \
    	if(param != NULL) { \n \
      		while(*param != '\\0') { \n \
        		if(len %% STR_BLOCK == 0) { \n \
          			ret = realloc(ret, len + STR_BLOCK); \n \
        		} \n \
        		ret[len++] = *param++; \n \
      		} \n \
    	} \n \
  	} \n \
  	if(len %% STR_BLOCK == 0) { \n \
    	ret = realloc(ret, len + 1); \n \
  	} \n \
  	ret[len] = '\\0'; \n \
  	va_end(valist); \n \
  	return ret; \n \
} \n \
\n");

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
