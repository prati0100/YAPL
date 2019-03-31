%{
	#include <stdio.h>
	#include <string.h>
	#include <errno.h>
	#include <stdlib.h>
	#include <stdbool.h>

	#include <yapl.h>
	#include <symbol_table.h>

	void yyerror(const char *);
	int yylex();

	bool parse_err = 0;
	extern int currow;
%}

%define parse.error verbose
%locations

%union {
	int intval;
	char *strval;
}

%token TK_EOF 0

%token TK_AND 257
%token TK_BREAK
%token TK_START
%token TK_ELSE
%token TK_ELSEIF
%token TK_END
%token TK_FALSE
%token TK_FOR
%token TK_FN
%token TK_IF
%token TK_IN
%token TK_LOCAL
%token TK_NULL
%token TK_NOT
%token TK_OR
%token TK_RETURN
%token TK_THEN
%token TK_TRUE
%token TK_WHILE

%token TK_PLUS
%token TK_MINUS
%token TK_MUL
%token TK_DIV
%token TK_EQ		/* == */
%token TK_GE		/* >= */
%token TK_LE		/* <= */
%token TK_NE		/* != */
%token TK_ASSIGN	/* = */
%token TK_COLON
%token TK_LP		/* ( */
%token TK_RP		/* ) */
%token TK_COMMA
%token TK_TYPE
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
/* TODO: This needs to be changed to input: declaration | function_definition */
input:
	block
	;

funcdecl:
	TK_FN TK_NAME TK_COLON TK_LP parlist TK_RP funcbody
	;

funcbody:
	TK_START block TK_END
	;

param:
	TK_TYPE TK_NAME
	;

parlist:
	  param moreparams
	| param
	;

moreparams:
	  TK_COMMA param
	| TK_COMMA param moreparams
	;

block:
	  stat
	| block stat
	;

stat:
	  TK_NEWLINE
	| exp TK_NEWLINE
	| assign TK_NEWLINE
	| error TK_NEWLINE
	;

assign:
	TK_NAME TK_ASSIGN exp
	;

exp:
	  TK_NUMBER
	| TK_NAME
	| exp TK_PLUS exp
	| exp TK_MINUS exp
	| exp TK_MUL exp
	| exp TK_DIV exp
	;
%%

void
yyerror(const char *msg)
{
	printf("Line %d: %s\n", currow, msg);
	parse_err = true;
}
