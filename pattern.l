%{
    #include <stdlib.h>
    #include "y.tab.h"
    #include "objects.h"
    void yyerror(const char *errstr, ...);
%}

varname [a-zA-Z][a-zA-Z0-9]*
number [1-9][0-9]*
float64 [0-9]+\.[0-9]+

%%

"main"          return MAIN;
"show"          return SHOW;
">="            return GE;
"<="            return LE;
"=="            return EQ;
"!="            return NE;
"++"            return INC;
"--"            return DEC;
"+="            return ADDEQ;
"-="            return SUBEQ;
"while"         return WHILE;
"if"            return IF;
"else"          return ELSE;
{varname}       {
                    yylval.stindex = strdup(yytext);
                    return VARIABLE;
                }
0               {
                    yylval.intval = atoi(yytext);
                    return INTEGER;
                }
{number}        {
                    yylval.intval = atoi(yytext);
                    return INTEGER;
                }
{float64}       {
                    yylval.doubleval = atof(yytext);
                    return FLOAT64;
                }
[-+()<>=/*{};.] {return *yytext;}
[ \t\n]         ;
.               yyerror("invalid text: %s", yytext);
%%

int
yywrap(void){
    return 1;
}
