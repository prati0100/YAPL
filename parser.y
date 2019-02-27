%{
	#include <stdio.h>
	void yyerror(const char *);
	int yylex();
%}

%token TK_EOF 0

%token TK_AND 257
%token TK_BREAK
%token TK_DO
%token TK_ELSE
%token TK_ELSEIF
%token TK_END
%token TK_FALSE
%token TK_FOR
%token TK_FUNCTION
%token TK_IF
%token TK_IN
%token TK_LOCAL
%token TK_NIL
%token TK_NOT
%token TK_OR
%token TK_REPEAT
%token TK_RETURN
%token TK_THEN
%token TK_TRUE
%token TK_UNTIL
%token TK_WHILE

%token TK_CONCAT
%token TK_DOTS
%token TK_PLUS
%token TK_MINUS
%token TK_MUL
%token TK_DIV
%token TK_EQ
%token TK_GE
%token TK_LE
%token TK_NE
%token TK_NUMBER
%token TK_NAME
%token TK_STRING

%token TK_LONGSTRING
%token TK_SHORTCOMMENT;
%token TK_LONGCOMMENT;
%token TK_WHITESPACE;
%token TK_NEWLINE;
%token TK_BADCHAR;

%left TK_MINUS TK_PLUS
%left TK_MUL TK_DIV

%%
input:
	  %empty
	| input line
	;

line:
	  TK_NEWLINE
	| exp TK_NEWLINE { printf("exp = %d\n", $1); }
	;

exp:
	  TK_NUMBER
	| exp TK_PLUS exp { $$ = $1 + $3; }
	| exp TK_MINUS exp { $$ = $1 - $3; }
	| exp TK_MUL exp { $$ = $1 * $3; }
	| exp TK_DIV exp { $$ = $1 / $3; }
	;
%%

void
yyerror(const char *msg)
{
	printf("%s\n", msg);
}
