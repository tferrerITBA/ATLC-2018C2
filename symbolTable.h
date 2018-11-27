#define MAX_GLOBAL_VARIABLES 1113
#define MAX_FUNCTION_NUMBER 1113
#define MAX_LOCAL_VARIABLES 1113

typedef enum { IVAL, FVAL, SVAL, BVAL } types;

typedef struct NodeCDT * Node;

typedef struct NodeCDT {
	char * str;
} NodeCDT;

typedef struct VariableCDT * Variable;

typedef struct VariableCDT {
	char * name;
	int type;
} VariableCDT;

typedef struct FunctionCDT * Function;

typedef struct FunctionCDT {
  	char * name;
  	Variable varLocal[MAX_LOCAL_VARIABLES];
} FunctionCDT;

typedef struct GlobalCDT * Global;

typedef struct GlobalCDT {
	Variable varGlobal[MAX_GLOBAL_VARIABLES];
	Function functions[MAX_FUNCTION_NUMBER];
} GlobalCDT;
