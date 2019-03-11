%{
	#include <stdio.h>

	#include <luac.h>
	#include <symbol_table.h>
	#include <codegen.h>

	void yyerror(const char *);
	int yylex();
%}

%union {
	int intval;
	char *strval;
}

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
%token TK_ASSIGN
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
	| exp TK_NEWLINE { gen_exp_val(); }
	| assign TK_NEWLINE
	;

assign:
	TK_NAME TK_ASSIGN exp {
		gen_assign_exp($<intval>1);
	}
	;

exp:
	  TK_NUMBER { gen_exp_num($<intval>1); }
	| TK_NAME { gen_exp_name($<intval>1); }
	| exp TK_PLUS exp { gen_exp_arith(TK_PLUS); }
	| exp TK_MINUS exp { gen_exp_arith(TK_MINUS); }
	| exp TK_MUL exp { gen_exp_arith(TK_MUL); }
	| exp TK_DIV exp { gen_exp_arith(TK_DIV); }
	;
%%

void
yyerror(const char *msg)
{
	printf("%s\n", msg);
}
