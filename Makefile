all:
	yacc -d --debug --verbose grammar.y							# create y.tab.h, y.tab.c
	lex -d pattern.l							# create lex.yy.c
	gcc -o parser lex.yy.c y.tab.c symtab.c util.c -g -lm -ly	# compile and link
