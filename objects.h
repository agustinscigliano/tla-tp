typedef enum {ID_NODE, OPER_NODE, INT_NODE, FLOAT64_NODE, STRING_NODE} NodeTypeEnum;

typedef struct Node Node;

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

struct Node {
	NodeTypeEnum type;

    union {
        IntNode in;
		Float64Node f64n;
		StringNode sn;
        IdNode idn;
        OpNode opn;
    };
};
