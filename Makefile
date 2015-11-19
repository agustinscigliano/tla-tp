all:
	yacc -d grammar.y						# create y.tab.h, y.tab.c
	lex pattern.l							# create lex.yy.c
	gcc -o parser lex.yy.c y.tab.c -ly		# compile and link
