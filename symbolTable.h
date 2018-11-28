#define MAX_GLOBAL_VARIABLES 1113
#define MAX_FUNCTION_NUMBER 1113
#define MAX_LOCAL_VARIABLES 1113
#define MAX_FUNCTION_NAME 50
#define FROZONE "frozone"

typedef enum { FALSE = 0, TRUE } bool;
typedef enum { IVAL, DVAL, SVAL, BVAL } types;
typedef enum { SUCCESS = 0, MAIN_DUP, FUNC_DUP, NOT_FOUND, ARGC_ERR } errors;
typedef enum { VAR_CREATED, VAR_MODIFIED } varStatus;

typedef struct NodeCDT * Node;

typedef struct NodeCDT {
	char * str;
} NodeCDT;

typedef struct ArgNodeCDT * ArgNode;

typedef struct ArgNodeCDT {
	char * str;
	int argc;
} ArgNodeCDT;

typedef struct VariableCDT * Variable;

typedef struct VariableCDT {
	char * name;
} VariableCDT;

typedef struct FunctionCDT * Function;

typedef struct FunctionCDT {
  	char name[MAX_FUNCTION_NAME];
  	int argc;
  	int variableIndex;
  	bool defined;
  	Variable varLocal[MAX_LOCAL_VARIABLES];
} FunctionCDT;

typedef struct GlobalCDT * Global;

typedef struct GlobalCDT {
	int variableIndex;
	Variable varGlobal[MAX_GLOBAL_VARIABLES];
	int functionIndex;
	Function functions[MAX_FUNCTION_NUMBER];
	int currentFunction;
	bool mainFound;
} GlobalCDT;

void yyerror(const char *s);

int insertFunction(char * name, int argc);
char * getFunctionName(char * str);
int foundFunction(char * name);
varStatus addVariable(char * varName);
bool foundVariable(char * varName);
int ArgcMatchesPrototype(char * name, int argc);
Function getFunction(char * name);
int variableInCurrentFunction(char * name);
void addNewVariable(char * name);
