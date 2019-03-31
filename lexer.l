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

"local" { UPDATE_COL(); return TK_LOCAL; }
"global" { UPDATE_COL(); return TK_GLOBAL; }
"extern" { UPDATE_COL(); return TK_EXTERN; }

"fn" { UPDATE_COL(); return TK_FN; }
"call" { UPDATE_COL(); return TK_CALL; }
"start" { UPDATE_COL(); return TK_START; }
"end" { UPDATE_COL(); return TK_END; }
"if" { UPDATE_COL(); return TK_IF; }
"then" { UPDATE_COL(); return TK_THEN; }
"else" { UPDATE_COL(); return TK_ELSE; }
"elseif" { UPDATE_COL(); return TK_ELSEIF; }
"for" { UPDATE_COL(); return TK_FOR; }
"while" { UPDATE_COL(); return TK_WHILE; }
"return" { UPDATE_COL(); return TK_RETURN; }
"break" { UPDATE_COL(); return TK_BREAK; }

"and" { UPDATE_COL(); return TK_AND; }
"or" { UPDATE_COL(); return TK_OR; }
"not" { UPDATE_COL(); return TK_NOT; }
"true" { UPDATE_COL(); return TK_TRUE; }
"false" { UPDATE_COL(); return TK_FALSE; }
"null" { UPDATE_COL(); return TK_NULL; }

"int" { UPDATE_COL(); return TK_INT; }
"uint" { UPDATE_COL(); return TK_UINT; }
"char" { UPDATE_COL(); return TK_CHAR; }
"uchar" { UPDATE_COL(); return TK_UCHAR; }
"long" { UPDATE_COL(); return TK_LONG; }
"ulong" { UPDATE_COL(); return TK_ULONG; }
"short" { UPDATE_COL(); return TK_SHORT; }
"ushort" { UPDATE_COL(); return TK_USHORT; }


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
"," { UPDATE_COL(); return TK_COMMA; }
"[" { UPDATE_COL(); return TK_LSB; }
"]" { UPDATE_COL(); return TK_RSB; }
";" { UPDATE_COL(); return TK_SEMICOLON; }
">" { UPDATE_COL(); return TK_GT; }
">=" { UPDATE_COL(); return TK_GE; }
"<" { UPDATE_COL(); return TK_LT; }
"<=" { UPDATE_COL(); return TK_LE; }
"==" { UPDATE_COL(); return TK_EQ; }
"!=" { UPDATE_COL(); return TK_NE; }
"%" { UPDATE_COL(); return TK_MOD; }

"\n" { currow++; curcol = 1; return TK_NEWLINE; }

[ \t]+ { UPDATE_COL(); }

"~~".*

. { UPDATE_COL(); return TK_BADCHAR; }
%%

int
yywrap()
{
	return 1;
}
