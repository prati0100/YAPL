%{
	#include <stdlib.h>
	#include <stdio.h>

	#include <yapl.h>
	#include <symbol_table.h>

	#include "parser.tab.h"

	/*
	 * yyunput() and input() are in the generated file but are unused. Disable
	 * the compiler warnings for them.
	 */
	#pragma GCC diagnostic ignored "-Wunused-function"

	int currow = 1, curcol = 1;

	#define UPDATE_COL() do {						\
		yylloc.first_column = curcol;					\
		curcol += strlen(yytext);						\
		yylloc.last_column = curcol;					\
		yylloc.first_line = yylloc.last_line = currow;	\
	} while (0)
%}

DIGIT [0-9]
NUMBER {DIGIT}+
NAME [_A-Za-z][_A-Za-z0-9]*

%%

{NUMBER} {yylval.intval = atoi(yytext); UPDATE_COL(); return TK_NUMBER;}

{NAME} {
	yylval.intval = st_get(yytext);
	if (yylval.intval == -1) {
		yylval.intval = st_insert(yytext, TK_NAME);
	}

	UPDATE_COL();

	return TK_NAME;
}

"+" { UPDATE_COL(); return TK_PLUS; }
"-" { UPDATE_COL(); return TK_MINUS; }
"*" { UPDATE_COL(); return TK_MUL; }
"/" { UPDATE_COL(); return TK_DIV; }
"=" { UPDATE_COL(); return TK_ASSIGN; }
":" { UPDATE_COL(); return TK_COLON; }
"(" { UPDATE_COL(); return TK_LP; }
")" { UPDATE_COL(); return TK_RP; }

"\n" { currow++; curcol = 1; return TK_NEWLINE; }

[ \t]+ { UPDATE_COL(); }

. { UPDATE_COL(); return TK_BADCHAR; }
%%

int
yywrap()
{
	return 1;
}
