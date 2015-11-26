%{
    #include <stdlib.h>
    #include "y.tab.h"
    void yyerror(char *);
%}
letter [A-Za-z]
digit [0-9]

%%

[a-z]       {
                yylval.stindex = *yytext - 'a';
                return VARIABLE;
            }

[0-9]+      {
                yylval.intval = atoi(yytext);
                return INTEGER;
            }
[-+()=/*\n] {return *yytext;}
">="        return GE;
"<="        return LE;
"=="        return EQ;
"!="        return NE;
"while"     return WHILE;
"if"        return IF;
"else"      return ELSE;
"print"     return PRINT;
[ \t]       ;
.           yyerror("invalid character");
%%

int
yywrap(void){
    return 1;
}
