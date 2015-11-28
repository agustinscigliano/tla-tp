typedef enum {
	ID_NODE, OPER_NODE, TYPE_NODE, INT_NODE, FLOAT64_NODE, STRING_NODE
} NodeTypeEnum;

typedef struct Node Node;
typedef enum VarTypeEnum VarTypeEnum;

enum VarTypeEnum {INTEGER_T, FLOAT64_T, STRING_T};

typedef struct {
	VarTypeEnum type;

	union {
		int integer;
		double float64;
		char *string;
	};
} Variable;

typedef struct {
	int oper;
	int nops;
	Node **ops;
} OpNode;

typedef struct {
	int integer;
} IntNode;

typedef struct {
	double float64;
} Float64Node;

typedef struct {
	char *string;
} StringNode;

typedef struct {
	char *name;
} IdNode;

typedef struct {
	VarTypeEnum type;
} TypeNode;

struct Node {
	NodeTypeEnum type;

    union {
        IntNode in;
		Float64Node f64n;
		StringNode sn;
		TypeNode tn;
        IdNode idn;
        OpNode opn;
    };
};
