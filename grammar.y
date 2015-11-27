%token <intval>    INTEGER
%token <stindex>   VARIABLE
%token <string>    STRING
%token <doubleval> FLOAT64
%token WHILE IF SHOW
%nonassoc IFX
%nonassoc ELSE

%left GE LE EQ NE '>' '<'
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

%type <np> stmt expr stmt_list
%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <math.h>
#include "util.h"
#include "symtab.h"
#include "objects.h"

void yyerror(const char *errstr, ...);
int yylex(void);
Node *newIntNode(int value);
Node *newFloat64Node(double value);
Node *newStringNode(char *s);
void freeNode(Node *np);
Node *newIdNode(const char *id);
Node *newOpNode(int operator, int nops, ...);
int execute(Node *np);

int *aux;
int auxint;
Symtab *st;
%}

%union {
    char *stindex;      /* symbol table index */
    int intval;         /* integer value */
    double doubleval;
    char *string;
    struct Node *np;
};
%%
/*--------------------------------------------------------*/
program: 
       fn {exit(0);}
       ;

fn:
  fn stmt { execute($2); freeNode($2); }
  | /* LAMBDA */
  ;

stmt:
    ';'                                {$$ = newOpNode(';', 2, NULL, NULL);}
    | expr ';'                         {$$ = $1;}
    | VARIABLE '=' expr ';'            {$$ = newOpNode('=', 2, newIdNode($1), $3);}
    | WHILE '(' expr ')' stmt          {$$ = newOpNode(WHILE, 2, $3, $5);}
    | IF '(' expr ')' stmt %prec IFX   {$$ = newOpNode(IF, 2, $3, $5);}
    | IF '(' expr ')' stmt ELSE stmt   {$$ = newOpNode(IF, 3, $3, $5, $7);}
    | '{' stmt_list '}'                {$$ = $2;}
    | SHOW expr ';'                    {$$ = newOpNode(SHOW, 1, $2);}
    ;

stmt_list:
         stmt                   {$$ = $1;}
         | stmt_list stmt       {$$ = newOpNode(';', 2, $1, $2);}
         ;

expr:
    INTEGER             {$$ = newIntNode($1);}
    | FLOAT64           {$$ = newFloat64Node($1);}
    | STRING            {$$ = newStringNode($1);}
    | VARIABLE          {$$ = newIdNode($1);}
    | '-' expr %prec UMINUS {$$ = newOpNode(UMINUS, 1, $2);}
    | expr '+' expr             {$$ = newOpNode('+', 2, $1, $3);}
    | expr '-' expr             {$$ = newOpNode('-', 2, $1, $3);}
    | expr '*' expr             {$$ = newOpNode('*', 2, $1, $3);}
    | expr '/' expr             {$$ = newOpNode('/', 2, $1, $3);}
    | expr '>' expr             {$$ = newOpNode('>', 2, $1, $3);}
    | expr '<' expr             {$$ = newOpNode('<', 2, $1, $3);}
    | expr GE expr              {$$ = newOpNode(GE, 2, $1, $3);}
    | expr LE expr              {$$ = newOpNode(LE, 2, $1, $3);}
    | expr NE expr              {$$ = newOpNode(NE, 2, $1, $3);}
    | expr EQ expr              {$$ = newOpNode(EQ, 2, $1, $3);}
    | '(' expr ')'              {$$ = $2;}
    ;
%%
/*--------------------------------------------------------*/

Node *
newIntNode(int value){
    Node *np       = xmalloc(sizeof(*np));
    np->type       = INT_NODE;
    np->in.integer = value;

    return np;
}

Node *
newFloat64Node(double value){
    Node *np         = xmalloc(sizeof(*np));
    np->type         = FLOAT64_NODE;
    np->f64n.float64 = value;

    return np;
}

Node *
newStringNode(char *s){
    Node *np      = xmalloc(sizeof(*np));
    np->type      = STRING_NODE;
    np->sn.string = s;

    return np;
}

Node *
newIdNode(const char *id){
    Node *np     = xmalloc(sizeof(*np));
    np->type     = ID_NODE;
    np->idn.name = strdup(id);

    return np;
}

Node *
newOpNode(int operator, int nops, ...){
    va_list ap;

    Node *np = xmalloc(sizeof(*np));
    np->opn.ops = xmalloc(nops * sizeof(np->opn.ops));
    np->type = OPER_NODE;
    np->opn.oper = operator;
    np->opn.nops = nops;
    va_start(ap, nops);
    for(int i = 0; i < nops; i++)
        np->opn.ops[i] = va_arg(ap, Node*);
    va_end(ap);

    return np;
}

void
freeNode(Node *np){
    if(!np)
        return;

    if(np->type == OPER_NODE){
        for(int i = 0; i < np->opn.nops; i++)
            freeNode(np->opn.ops[i]);
        free(np->opn.ops);
    } else if(np->type == ID_NODE){
        free(np->idn.name);
    }
    free(np);
}

int
execute(Node *np){
    if(!np)
        return 0;

switch(np->type){
    case INT_NODE: return np->in.integer;
    case FLOAT64_NODE: 
            return ceil(np->f64n.float64);
    case STRING_NODE: return *np->sn.string;
    case ID_NODE:    
            aux = lookup(st, 0, np->idn.name, NULL);
            if(aux == NULL){
                printf("aux = NULL1\n");
                return 0;
            }
            return *aux;
    case OPER_NODE:
        switch(np->opn.oper){
        case WHILE:     while(execute(np->opn.ops[0]))
                        execute(np->opn.ops[1]); 
                        return 0;
        case IF:        if(execute(np->opn.ops[0]))
                            execute(np->opn.ops[1]);
                        else if(np->opn.nops > 2)
                            execute(np->opn.ops[2]);
                        return 0;
        case ';':       execute(np->opn.ops[0]);
                        return execute(np->opn.ops[1]);
        case SHOW:      
                        printf("%d\n", execute(np->opn.ops[0]));
                        return 0;
        case '=':       
                        auxint = execute(np->opn.ops[1]);
                        aux = lookup(st, 1, np->opn.ops[0]->idn.name, &auxint);
                        if(aux == NULL){
                            printf("aux = NULL2\n");
                            return 0;
                        }
                        return *aux;
        case UMINUS:    return -execute(np->opn.ops[0]);
        case '+':       return execute(np->opn.ops[0]) + execute(np->opn.ops[1]);
        case '-':       return execute(np->opn.ops[0]) - execute(np->opn.ops[1]);
        case '*':       return execute(np->opn.ops[0]) * execute(np->opn.ops[1]);
        case '/':       return execute(np->opn.ops[0]) / execute(np->opn.ops[1]);
        case '<':       return execute(np->opn.ops[0]) < execute(np->opn.ops[1]);
        case '>':       return execute(np->opn.ops[0]) > execute(np->opn.ops[1]);
        case GE:        return execute(np->opn.ops[0]) >= execute(np->opn.ops[1]);
        case LE:        return execute(np->opn.ops[0]) <= execute(np->opn.ops[1]);
        case NE:        return execute(np->opn.ops[0]) != execute(np->opn.ops[1]);
        case EQ:        return execute(np->opn.ops[0]) == execute(np->opn.ops[1]);
        }
    }
    return 0;
}

void 
yyerror(const char *errstr, ...) {
	va_list ap;

	va_start(ap, errstr);
	vfprintf(stderr, errstr, ap);
	fprintf(stderr, "\n");
	va_end(ap);
}

int 
main(void) {
    st = newsymboltable();
    yyparse();
    return 0;
}
