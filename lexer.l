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

"+" |
"-" |
"*" |
"/" {return yytext[0];}

"\n" {return '\n';}

[ \t]+ {}
%%

int
yywrap()
{
	return 1;
}
