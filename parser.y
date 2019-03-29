%{
	#include <stdio.h>
	#include <string.h>
	#include <errno.h>
	#include <stdlib.h>
	#include <stdbool.h>

	#include <yapl.h>
	#include <symbol_table.h>
	#include <codegen.h>

	void yyerror(const char *);
	int yylex();
	static char *parse_exp(char *, char *, int);

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
	block {
		/*
		 * Append the entire block to the text section for now. Later this rule
		 * will change to a combinations of declarations and definitions.
		 */
		append_to_text($<strval>1);

		free($<strval>1);
	}
	;

block:
	  stat { $<strval>$ = $<strval>1; }
	| block stat {
		char *stat, *block, *buf;

		block = $<strval>1;
		stat = $<strval>2;

		buf = malloc(sizeof(*buf) * (strlen(block) + strlen(stat) + 1));
		if (buf == NULL) {
			printf("Failed to allocate internal buffer: %s", strerror(errno));
			exit(1);
		}

		strcpy(buf, block);
		strcat(buf, stat);

		free(block);
		free(stat);

		$<strval>$ = buf;
	}
	;

stat:
	  TK_NEWLINE
	| exp TK_NEWLINE {
		char *exp, *expval, *buf;

		exp = $<strval>1;
		expval = gen_exp_val();

		buf = malloc(sizeof(*buf) * (strlen(exp) + strlen(expval) + 1));
		if (buf == NULL) {
			printf("Failed to allocate internal buffer: %s", strerror(errno));
			exit(1);
		}

		strcpy(buf, exp);
		strcat(buf, expval);

		free(exp);
		free(expval);

		$<strval>$ = buf;
	}
	| assign TK_NEWLINE {
		$<strval>$ = $<strval>1;
	}
	| error TK_NEWLINE
	;

assign:
	TK_NAME TK_ASSIGN exp {
		char *exp, *buf, *assign;

		exp = $<strval>3;
		assign = gen_assign_exp($<intval>1);

		buf = malloc(sizeof(*buf) * (strlen(exp) + strlen(assign) + 1));
		if (buf == NULL) {
			printf("Failed to allocate internal buffer: %s", strerror(errno));
			exit(1);
		}

		strcpy(buf, exp);
		strcat(buf, assign);

		free(exp);
		free(assign);

		$<strval>$ = buf;
	}
	;

/*
 * TODO: The code generated for expressions has too many memory operations. Try
 * to reduce them, and use more registers.
 */
exp:
	  TK_NUMBER { $<strval>$ = gen_exp_num($<intval>1); }
	| TK_NAME { $<strval>$ = gen_exp_name($<intval>1); }
	| exp TK_PLUS exp { $<strval>$ = parse_exp($<strval>1, $<strval>3, TK_PLUS); }
	| exp TK_MINUS exp { $<strval>$ = parse_exp($<strval>1, $<strval>3, TK_MINUS); }
	| exp TK_MUL exp { $<strval>$ = parse_exp($<strval>1, $<strval>3, TK_MUL); }
	| exp TK_DIV exp { $<strval>$ = parse_exp($<strval>1, $<strval>3, TK_DIV); }
	;
%%

/*
 * Concatenate the code for exp1 and exp2, and then the code generated for op.
 * Clean up all the previous buffers and return the expression evaluation code
 * generated so far.
 */
static
char *
parse_exp(char *exp1, char *exp2, int op)
{
	char *buf, *genop;

	genop = gen_exp_arith(op);

	buf = malloc(sizeof(*buf) *
		(strlen(exp1) + strlen(exp2) + strlen(genop) + 1));
	if (buf == NULL) {
		printf("Failed to allocate internal buffer: %s", strerror(errno));
		exit(1);
	}

	strcpy(buf, exp1);
	strcat(buf, exp2);
	strcat(buf, genop);

	free(exp1);
	free(exp2);
	free(genop);

	return buf;
}

void
yyerror(const char *msg)
{
	printf("Line %d: %s\n", currow, msg);
	parse_err = true;
}
