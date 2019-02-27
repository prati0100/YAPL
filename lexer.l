%{
	#include <luac.h>
	#include <stdlib.h>
	#include <stdio.h>

	#include "parser.tab.h"

	/*
	 * yyunput() and input() are in the generated file but are unused. Disable
	 * the compiler warnings for them.
	 */
	#pragma GCC diagnostic ignored "-Wunused-function"
%}

DIGIT [0-9]
NUMBER {DIGIT}+

%%

{NUMBER} {yylval = atoi(yytext); return TK_NUMBER;}

"+" { return TK_PLUS; }
"-" { return TK_MINUS; }
"*" { return TK_MUL; }
"/" { return TK_DIV; }

"\n" { return TK_NEWLINE; }

[ \t]+ {}
%%

int
yywrap()
{
	return 1;
}
