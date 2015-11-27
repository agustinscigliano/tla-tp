%{
    #include <stdlib.h>
    #include "y.tab.h"
    #include "objects.h"
    void yyerror(const char *errstr, ...);
%}

varname [a-zA-Z][a-zA-Z0-9]*

%%

"show"          return SHOW;
">="            return GE;
"<="            return LE;
"=="            return EQ;
"!="            return NE;
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
[1-9][0-9]*     {
                    yylval.intval = atoi(yytext);
                    return INTEGER;
                }
[-+()<>=/*{};.] {return *yytext;}
[ \t\n]         ;
.               yyerror("invalid text: %s", yytext);
%%

int
yywrap(void){
    return 1;
}
