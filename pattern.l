%{
    #include <stdlib.h>
    #include "y.tab.h"
    #include "objects.h"
    void yyerror(char *);
%}

letter [A-Za-z]
digit [0-9]
varname [_|{letter}|{digit}]+

%%

[a-z]           {
                    yylval.stindex = *yytext - 'a';
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
">="            return GE;
"<="            return LE;
"=="            return EQ;
"!="            return NE;
"while"         return WHILE;
"if"            return IF;
"else"          return ELSE;
"show"          return SHOW;
[ \t\n]         ;
.               yyerror("invalid character");
%%

int
yywrap(void){
    return 1;
}
