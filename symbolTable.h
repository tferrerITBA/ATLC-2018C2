typedef enum { IVAL, FVAL, SVAL, BVAL } types;

typedef struct Node {
	char * str;
} Node;

/*typedef struct {
	Variable varGlobal[MAX_GLOBAL_VARIABLES]
	Function functions[MAX_FUNCTION_NUMBER]
} Global;

typedef struct {
  	char * name;
  	Variable varLocal[MAX_LOCAL_VARIABLES];
  	
} Function;

typedef struct {
	Variable varTab[MAX_VARIABLE_NUMBER];
	int      varNumb;
} Variable;
*/