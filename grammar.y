%token <intval> INTEGER
%token <stindex> VARIABLE
%token WHILE IF
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
#include "objects.h"

void yyerror(char *);
int yylex(void);
int sym[26];

void freeNode(Node *np);
Node *newConstNode(int value);
Node *newIdNode(int id);
Node *newOpNode(int operator, int nops, ...);
int execute(Node *np);
%}

%union {
    char stindex; /* symbol table index */
    int intval;   /* integer value */
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
    ;

stmt_list:
         stmt                   {$$ = $1;}
         | stmt_list stmt       {$$ = newOpNode(';', 2, $1, $2);}
         ;

expr:
    INTEGER             {$$ = newConstNode($1);}
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

void
die(const char *errstr, ...) {
    va_list ap;

va_start(ap, errstr);
    vfprintf(stderr, errstr, ap);
    va_end(ap);
    exit(EXIT_FAILURE);
}

void *
xmalloc(size_t size) {
    void *p = malloc(size);

if(!p)
        die("Out of memory: could not malloc() %d bytes\n", size);

return p;
}

Node *
newConstNode(int value){
    Node *np     = xmalloc(sizeof(*np));
    np->type     = CONST;
    np->cn.value = value;

return np;
}

Node *
newIdNode(int id){
    Node *np = xmalloc(sizeof(*np));
    np->type = ID;
    np->idn.i = id;

return np;
}

Node *
newOpNode(int operator, int nops, ...){
    va_list ap;

Node *np = xmalloc(sizeof(*np));
    np->opn.ops = xmalloc(nops * sizeof(np->opn.ops));
    np->type = OPER;
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
    if(np->type == OPER){
        for(int i = 0; i < np->opn.nops; i++)
            freeNode(np->opn.ops[i]);
        free(np->opn.ops);
    }
    free(np);
}

int
execute(Node *np){
    if(!np)
        return 0;

    switch(np->type){
    case CONST: return np->cn.value;
    case ID:    return sym[np->idn.i];
    case OPER:
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
        case '=':       return sym[np->opn.ops[0]->idn.i] = execute(np->opn.ops[1]);
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
yyerror(char *errormessage) {
    fprintf(stderr, "%s\n", errormessage);
}

int 
main(void) {
    yyparse();
    return 0;
}

