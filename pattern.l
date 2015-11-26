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
[ \t]       ;
.           yyerror("invalid character");
%%

int
yywrap(void){
    return 1;
}
