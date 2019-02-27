%{
	#include <luac.h>
	#include <stdlib.h>
	#include <stdio.h>

	#include "parser.tab.h"
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
