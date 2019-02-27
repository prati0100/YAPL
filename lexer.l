%{
	#include <stdlib.h>
	#include <stdio.h>

	#include <luac.h>
	#include <symbol_table.h>

	/*
	 * yyunput() and input() are in the generated file but are unused. Disable
	 * the compiler warnings for them.
	 */
	#pragma GCC diagnostic ignored "-Wunused-function"
%}

DIGIT [0-9]
NUMBER {DIGIT}+
NAME [_A-Za-z][_A-Za-z0-9]*

%%

{NUMBER} {yylval = atoi(yytext); return TK_NUMBER;}

{NAME} {
	yylval = st_get(yytext);
	if (yylval == -1) {
		yylval = st_insert(yytext, TK_NAME);
	}

	return TK_NAME;
}

"+" { return TK_PLUS; }
"-" { return TK_MINUS; }
"*" { return TK_MUL; }
"/" { return TK_DIV; }
"=" { return TK_ASSIGN; }

"\n" { return TK_NEWLINE; }

[ \t]+ {}
%%

int
yywrap()
{
	return 1;
}
