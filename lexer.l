%{
	#include <stdlib.h>
	#include <stdio.h>

	#include <yapl.h>
	#include <symbol_table.h>
	#include <codegen.h>

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

{NUMBER} {yylval.intval = atoi(yytext); return TK_NUMBER;}

{NAME} {
	yylval.intval = st_get(yytext);
	if (yylval.intval == -1) {
		yylval.intval = st_insert(yytext, TK_NAME);
		/* XXX Hacky? */
		add_to_data_sect(yytext, "0", DWORD);
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
