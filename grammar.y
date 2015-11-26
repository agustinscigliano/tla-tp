%token <intval> INTEGER
%token <stindex> VARIABLE
%token WHILE IF PRINT
%left '+' '-'
%left '*' '/'
%{
#include <stdio.h>
void yyerror(char *);
int yylex(void);
int sym[26];

%union {
    char stindex; /* symbol table index */
    int intval;   /* integer value */
    Node *np;
};

typedef struct {
    union {
        ConstNode cn;
        IdNode idn;
        OpNode opn;
    }
} Node;

%}
%%
/*--------------------------------------------------------*/
program: 
       program statement '\n'
       |
       ;

statement:
         expr                   {printf("%d\n", $1);}
         | VARIABLE '=' expr    {sym[$1] = $3;}

expr:
    INTEGER
    | VARIABLE                  {$$ = sym[$1];}
    | expr '+' expr             {$$ = $1 + $3;}
    | expr '-' expr             {$$ = $1 - $3;}
    | expr '*' expr             {$$ = $1 * $3;}
    | expr '/' expr             {$$ = $1 / $3;}
    | '(' expr ')'
    ;
%%
/*--------------------------------------------------------*/

void 
yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
    return 0;
}

int 
main(void) {
    yyparse();
    return 0;
}
