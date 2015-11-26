typedef enum {ID, OPER, CONST} TypeEnum;

typedef struct Node Node;

typedef struct {
	int oper;
	int nops;
	Node **ops;
} OpNode;

typedef struct {
	int value;
} ConstNode;

typedef struct {
	int i;
} IdNode;

struct Node {
	TypeEnum type;

    union {
        ConstNode cn;
        IdNode idn;
        OpNode opn;
    };
};

extern int sym[26];
