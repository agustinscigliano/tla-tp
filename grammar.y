%token <intval> INTEGER
%token <stindex> VARIABLE
%token <string>    STRING
%token <doubleval> FLOAT64
%token <varType> TYPE
%token MAIN WHILE IF SHOW ADDEQ SUBEQ INC DEC
%nonassoc IFX
%nonassoc ELSE

%left GE LE EQ NE '>' '<'
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS INC DEC

%type <np> fn stmt expr stmt_list prestmt main
%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include "util.h"
#include "symtab.h"
#include "objects.h"

void     yyerror(const char *errstr, ...);
int      yylex(void);
Node     *newIntNode(int value);
Node     *newFloat64Node(double value);
Node     *newStringNode(char *s);
void     freeNode(Node *np);
Node     *newIdNode(const char *id);
Node     *newOpNode(int operator, int nops, ...);
Node     *newTypeNode(VarTypeEnum type);
void     execute(Node *np);
void     declareVariable(VarTypeEnum varType, char *varName);
Variable *newVariable(VarTypeEnum varType);
char     *getTypeString(VarTypeEnum type);

static int *auxint;
static Variable *auxvar;
static Symtab *st;
%}

%union {
    char *stindex;      /* symbol table index */
    int intval;         /* integer value */
    double doubleval;
    char *string;
    enum VarTypeEnum varType;
    struct Node *np;
};
%%
/*--------------------------------------------------------*/
program: 
       fn {exit(0);}
       ;

fn:
    prestmt fn  {execute($1); execute($2); freeNode($1); freeNode($2);}
    | main      {execute($1); freeNode($1);}
    ;

prestmt:
    TYPE VARIABLE ';'                    {$$ = newOpNode(TYPE, 2, newTypeNode($1), newIdNode($2));}
    | VARIABLE '=' expr ';'              {$$ = newOpNode('=', 2, newIdNode($1), $3);}
    ;

main:
    MAIN '(' ')' stmt     {$$ = newOpNode(MAIN, 1, $4);}
    ;

stmt:
    ';'                                {$$ = newOpNode(';', 2, NULL, NULL);}
    | expr ';'                         {$$ = newOpNode(';', 1, $1);}
    | VARIABLE '=' expr ';'            {$$ = newOpNode('=', 2, newIdNode($1), $3);}
    | VARIABLE ADDEQ expr ';'          {$$ = newOpNode(ADDEQ, 2, newIdNode($1), $3);}
    | VARIABLE SUBEQ expr ';'          {$$ = newOpNode(SUBEQ, 2, newIdNode($1), $3);}
    | WHILE '(' expr ')' stmt          {$$ = newOpNode(WHILE, 2, $3, $5);}
    | IF '(' expr ')' stmt %prec IFX   {$$ = newOpNode(IF, 2, $3, $5);}
    | IF '(' expr ')' stmt ELSE stmt   {$$ = newOpNode(IF, 3, $3, $5, $7);}
    | '{' stmt_list '}'                {$$ = newOpNode('{', 1, $2);}
    | SHOW expr ';'                    {$$ = newOpNode(SHOW, 1, $2);}
    ;

stmt_list:
         stmt                   {$$ = $1;}
         | stmt stmt_list       {$$ = newOpNode(';', 2, $1, $2);}
         ;

expr:
    INTEGER             {$$ = newIntNode($1);}
    | FLOAT64           {$$ = newFloat64Node($1);}
    | STRING            {$$ = newStringNode($1);}
    | VARIABLE          {$$ = newIdNode($1);}
    | TYPE VARIABLE     {$$ = newOpNode(TYPE, 2, newTypeNode($1), newIdNode($2));}
    | '-' expr %prec UMINUS     {$$ = newOpNode(UMINUS, 1, $2);}
    | INC expr %prec INC        {$$ = newOpNode(INC, 1, $2);}
    | DEC expr %prec DEC        {$$ = newOpNode(DEC, 1, $2);}
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
newTypeNode(VarTypeEnum type){
    Node *np     = xmalloc(sizeof(*np));
    np->type     = TYPE_NODE;
    np->tn.type  = type;

    return np;
}

Node *
newOpNode(int operator, int nops, ...){
    va_list ap;

    Node *np     = xmalloc(sizeof(*np));
    np->opn.ops  = xmalloc(nops * sizeof(np->opn.ops));
    np->type     = OPER_NODE;
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

void 
execute(Node *np) {
    if (!np) 
        return;
    switch(np->type){
    case INT_NODE: 
                printf("%d", np->in.integer);
            break;
    case FLOAT64_NODE: 
                printf("%f", np->f64n.float64);
            break;
    case STRING_NODE: 
                printf("\"%s\"", np->sn.string);
            break;
    case ID_NODE:    
            auxint = lookup(st, 0, np->idn.name, NULL);
            if(auxint == NULL){
                printf("int %s ", np->idn.name);
            } else {
                printf("%s ", np->idn.name);
            }
        break;
    case OPER_NODE:
        switch(np->opn.oper) {
        case MAIN:
            printf("int\nmain(void)");
            execute(np->opn.ops[0]);
            printf("\n");
            break;
        case WHILE:
            printf("while (");
            execute(np->opn.ops[0]);
            printf(")\n");
            execute(np->opn.ops[1]);
            break;
        case IF:
            printf("if (");
            execute(np->opn.ops[0]);
            printf(")");
            execute(np->opn.ops[1]);
            if(np->opn.nops > 2) {
                printf("else ");
                execute(np->opn.ops[2]);
            } 
            break;
        case TYPE:
            declareVariable(np->opn.ops[0]->tn.type, np->opn.ops[1]->idn.name);
            printf("%s %s", getTypeString(np->opn.ops[0]->tn.type), np->opn.ops[1]->idn.name);
            break;
        case SHOW:
            ; /* mandatory empty statement because declarations aren't statements */
            Node *nodetoshow = np->opn.ops[0];
            if(nodetoshow->type == STRING_NODE){
                printf("printf(\"%s\\n\")", nodetoshow->sn.string);
            }
            else if(nodetoshow->type == ID_NODE){
                Variable *v = lookup(st, 0, nodetoshow->idn.name, NULL);
                if(!v)
                    die("variable %s not in symtab\n", nodetoshow->idn.name);
                switch(v->type){
                case INTEGER_T:
                    printf("printf(\"%%d\\n\", %s)", nodetoshow->idn.name);
                    break;
                case FLOAT64_T:
                    printf("printf(\"%%f\\n\", %s)", nodetoshow->idn.name);
                    break;
                case STRING_T:
                    printf("printf(\"%%s\\n\", %s)", nodetoshow->idn.name);
                    break;
                }
            }
            break;
        case '=':
            auxvar = (Variable *) lookup(st, 0, np->opn.ops[0]->idn.name, NULL);
            if(auxvar == NULL)
                die("variable %s undeclared\n", np->opn.ops[0]->idn.name);
            execute(np->opn.ops[0]);
            printf(" = ");
            execute(np->opn.ops[1]);
            break;
        case UMINUS:
            printf("-");
            execute(np->opn.ops[0]);   
            break;
        case '{':
            printf("{\n");
            execute(np->opn.ops[0]);
            printf("}");
            break;
        case ';':
            for(int i = 0; i < np->opn.nops; i++){
                execute(np->opn.ops[i]);
                //printf("El caracter es %c\n", (np->opn.ops[i]->opn.oper)-'a');
                if (np->opn.ops[i]->opn.oper != ';') {
                    printf(";\n");
                }
            }
            break;
        case '+':
            execute(np->opn.ops[0]);
            printf(" + ");
            execute(np->opn.ops[1]);
            break;
        case '-':
        execute(np->opn.ops[0]);
            printf(" - ");
            execute(np->opn.ops[1]);
            break;
        case '*': 
            execute(np->opn.ops[0]);
            printf(" * ");
            execute(np->opn.ops[1]);
            break;
        case '/':
            execute(np->opn.ops[0]);
            printf(" / ");
            execute(np->opn.ops[1]);
            break;
        case '<':
            execute(np->opn.ops[0]);
            printf(" < ");
            execute(np->opn.ops[1]);
            break;
        case '>':
        execute(np->opn.ops[0]);
            printf(" > ");
            execute(np->opn.ops[1]);
            break;
        case GE:
        execute(np->opn.ops[0]);
            printf(" >= ");
            execute(np->opn.ops[1]);
            break;
        case LE:
        execute(np->opn.ops[0]);
            printf(" <= ");
            execute(np->opn.ops[1]);
            break;
        case NE:
        execute(np->opn.ops[0]);
            printf(" != ");
            execute(np->opn.ops[1]);
            break;
        case EQ:
        execute(np->opn.ops[0]);
            printf(" == ");
            execute(np->opn.ops[1]);
            break;
        case ADDEQ:
            execute(np->opn.ops[0]);
            printf(" += ");
            execute(np->opn.ops[1]);
            break;
        case SUBEQ:
            execute(np->opn.ops[0]);
            printf(" -= ");
            execute(np->opn.ops[1]);
            break;
        case INC:
            printf("++");
            execute(np->opn.ops[0]);   
            break;
        case DEC: 
            printf("--");
            execute(np->opn.ops[0]);   
            break;
        default:
            break;
            }
        }
}

char *
getTypeString(VarTypeEnum type) {
    if (type == INTEGER_T)
        return "int";
    if (type == FLOAT64_T)
        return "double";
    if (type == STRING_T)
        return "char*";
    return NULL;
}

void
declareVariable(VarTypeEnum varType, char *varName) {
    Variable *vp = (Variable *)lookup(st, 0, varName, NULL);
    if (vp != NULL)
        die("Error: variable ya definida");

    lookup(st, 1, varName, newVariable(varType));
}

Variable *
newVariable(VarTypeEnum varType) {
    Variable *vp = xmalloc(sizeof(*vp));
    vp->type = varType;
    return vp;
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
