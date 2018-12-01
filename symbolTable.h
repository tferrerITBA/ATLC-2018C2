#define MAX_GLOBAL_VARIABLES 1113
#define MAX_FUNCTION_NUMBER 1113
#define MAX_LOCAL_VARIABLES 1113
#define MAX_FUNCTION_NAME 50
#define FROZONE "frozone"
#define EPSILON "0.000001"

#define MAX_INT_STR_LENGTH 24
#define MAX_DBL_STR_LENGTH 24
#define STR_BLOCK 10

typedef enum { FALSE = 0, TRUE } bool;
typedef enum { PLUS, MINUS, MULT, DIV } arithmOp;
typedef enum { EQ, LT, GT, NE } relationalOp;
typedef enum { AND, OR, NOT } logicalOp;
typedef enum { IVAL, DVAL, SVAL, BVAL, UNKNOWN } types;
typedef enum { SUCCESS = 0, MAIN_DUP, FUNC_DUP, NOT_FOUND, ARGC_ERR, MAIN_RET } errors;
typedef enum { VAR_CREATED, VAR_MODIFIED } varStatus;

typedef struct NodeCDT * Node;

typedef struct NodeCDT {
	char * str;
} NodeCDT;

typedef struct IntNodeCDT * IntNode;

typedef struct IntNodeCDT {
	char * str;
	int n;
} IntNodeCDT;

typedef struct OpNodeCDT * OpNode;

typedef struct OpNodeCDT {
	int type;
	char * baseId;
	char * firstArgIntStr;
	char * firstArgDblStr;
	char * firstArgStrStr;
	char * firstArgBoolStr;
} OpNodeCDT;

typedef struct VariableCDT * Variable;

typedef struct VariableCDT {
	char * name;
	int type;
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

Node addNode(char * string);
IntNode addIntNode(char * string, int n);
OpNode addOpNode(int type, char * baseId, char * intStr, char * dblStr, char * strStr, char * boolStr);
char * strcatN(int num, ...);
char * repeatStr(char * str, int count, int final);
void freeResources();

int insertFunction(char * name, int argc);
char * getFunctionName(char * str);
int foundFunction(char * name);
varStatus addVariable(char * varName);
bool foundVariable(char * varName);
int ArgcMatchesPrototype(char * name, int argc);
Function getFunction(char * name);
int variableInCurrentFunction(char * name);
void addNewVariable(char * name);

char * strFromIntArithmOp(arithmOp op);
char * strFromIntRelOp(relationalOp op);
char * strFromIntLogOp(logicalOp op);
