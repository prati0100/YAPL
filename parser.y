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
%token TK_CALL
%token TK_IF
%token TK_IN
%token TK_LOCAL
%token TK_GLOBAL
%token TK_EXTERN
%token TK_NULL
%token TK_NOT
%token TK_OR
%token TK_RETURN
%token TK_THEN
%token TK_TRUE
%token TK_WHILE
%token TK_INT
%token TK_UINT
%token TK_CHAR
%token TK_UCHAR
%token TK_SHORT
%token TK_USHORT
%token TK_LONG
%token TK_ULONG

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
%token TK_LSB		/* [ */
%token TK_RSB		/* ] */
%token TK_COMMA
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
%left TK_ELSEIF

%%
input:
	funcdecl | namedecl | input funcdecl | input namedecl | input TK_NEWLINE
	;

funcdecl:
	TK_FN type TK_NAME TK_COLON TK_LP parlist TK_RP funcbody
	;

funcbody:
	TK_START block TK_END
	;

param:
	type TK_NAME
	;

parlist:
	  param
	| parlist TK_COMMA param
	| %empty
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
	| namedecl TK_NEWLINE
	| conditional TK_NEWLINE
	;

namelist:
	  TK_NAME optassign
	| namelist TK_COMMA TK_NAME optassign
	;

namedecl:
	scope type namelist
	;

optassign:
	  %empty
	| TK_ASSIGN exp
	;

assign:
	var TK_ASSIGN exp
	;

conditional:
	TK_IF exp TK_THEN block optelseifs optelse TK_END
	;

optelse:
	  TK_ELSE block
	| %empty
	;

optelseifs:
	  %empty
	| TK_ELSEIF exp TK_THEN block optelseifs
	;

scope:
	  TK_LOCAL
	| TK_GLOBAL
	| TK_EXTERN
	;

type:
	  TK_INT
	| TK_UINT
	| TK_CHAR
	| TK_UCHAR
	| TK_LONG
	| TK_ULONG
	| TK_SHORT
	| TK_USHORT
	;

var:
	  TK_NAME
	| prefixexp TK_LSB exp TK_RSB
	;

prefixexp:
	  var
	| functioncall
	| TK_LP exp TK_RP
	;

functioncall:
	TK_CALL TK_NAME TK_COLON args
	;

args:
	  TK_LP arglist TK_RP
	| TK_LP TK_RP
	;

arglist:
	  exp
	| arglist TK_COMMA exp
	;

exp:
	  TK_NUMBER
	| var
	| exp TK_PLUS exp
	| exp TK_MINUS exp
	| exp TK_MUL exp
	| exp TK_DIV exp
	| functioncall
	;
%%

void
yyerror(const char *msg)
{
	printf("Error at line %d: %s\n", currow, msg);
	parse_err = true;
}
