%{
    #include <stdlib.h>
    #include "objects.h"
    #include "y.tab.h"
    
    void yyerror(const char *errstr, ...);
    VarTypeEnum getType(char *s);
%}

varname [a-zA-Z][a-zA-Z0-9]*
number [1-9][0-9]*
float64 [0-9]+\.[0-9]+
type "int"|"float64"|"string"

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
\".*\"          {
                    yylval.string = calloc(strlen(yytext)-1, sizeof(char));
                    strncpy(yylval.string, &yytext[1], strlen(yytext)-2);
                    return STRING;
                }
{type}          {
                    yylval.varType = getType(yytext);
                    return TYPE;
                }
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

VarTypeEnum
getType(char *s){
    if (!strcmp(s, "int")) {
        return INTEGER_T;
    }
    if (!strcmp(s, "float64")) {
        return FLOAT64_T;
    }
    if (!strcmp(s, "string")) {
        return STRING_T;
    }
    return -1;
}
