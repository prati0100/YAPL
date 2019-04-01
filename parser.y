%{
	#include <stdio.h>
	#include <string.h>
	#include <errno.h>
	#include <stdlib.h>
	#include <stdbool.h>

	#include <yapl.h>
	#include <symbol_table.h>
	#include <ast.h>

	#define BUFFER_SZ 256

	void yyerror(const char *);
	int yylex();
	static struct ast_node *create_binop_node(struct ast_node *,
		struct ast_node *, int);
	static struct ast_node *create_unop_node(struct ast_node *, int);

	bool parse_err = 0;
	extern int currow;

	struct ast_node **block_stats;
	int stat_idx;
%}

%define parse.error verbose
%locations

%union {
	int intval;
	char *strval;
	struct ast_node *nodeval;
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
%token TK_STR

%token TK_PLUS
%token TK_MINUS
%token TK_MUL
%token TK_DIV
%token TK_MOD		/* % */
%token TK_EQ		/* == */
%token TK_GT		/* > */
%token TK_GE		/* >= */
%token TK_LT		/* < */
%token TK_LE		/* <= */
%token TK_NE		/* != */
%token TK_ASSIGN	/* = */
%token TK_COLON
%token TK_LP		/* ( */
%token TK_RP		/* ) */
%token TK_LSB		/* [ */
%token TK_RSB		/* ] */
%token TK_COMMA
%token TK_SEMICOLON
%token TK_NUMBER
%token TK_NAME
%token TK_STRING

%token TK_LONGSTRING
%token TK_SHORTCOMMENT;
%token TK_LONGCOMMENT;
%token TK_WHITESPACE;
%token TK_NEWLINE;
%token TK_BADCHAR;

%left TK_ASSIGN
%left TK_MINUS TK_PLUS
%left TK_MUL TK_DIV TK_MOD
%left TK_GE TK_GT TK_LE TK_LT TK_EQ TK_NE TK_AND TK_OR
%right TK_NOT

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
	blockdash {
		struct ast_node *block;
		int i;

		block = ast_node_create(AST_BLOCK, strdup("Block"), stat_idx);

		for (i = 0; i < stat_idx; i++) {
			block->children[i] = block_stats[i];
		}

		/*
		 * XXX Leaking the AST.
		 */
		if (gen_dot) {
			char *str = ast_output_dot(block);
			printf("%s\n", str);
			free(str);
		}

		free(block_stats);
		block_stats = NULL;
		stat_idx = 0;
	}
	;

blockdash:
	  stat {
		if (block_stats == NULL) {
			/* XXX Max 50 statements supported. */
			block_stats = malloc(sizeof(*block_stats) * 50);
			stat_idx = 0;
		}

		if ($<nodeval>1 != NULL) {
			block_stats[stat_idx] = $<nodeval>1;
			stat_idx++;
		}
	  }
	| blockdash stat {
		ASSERT(block_stats != NULL, "block_stats is NULL");

		if ($<nodeval>2 != NULL) {
			block_stats[stat_idx] = $<nodeval>2;
			stat_idx++;
		}
	}
	;

stat:
	  TK_NEWLINE {
		$<nodeval>$ = NULL;
	}
	| exp TK_NEWLINE {
		$<nodeval>$ = $<nodeval>1;
	}
	| error TK_NEWLINE
	| namedecl TK_NEWLINE
	| conditional TK_NEWLINE
	| forloop TK_NEWLINE
	| whileloop TK_NEWLINE
	| TK_RETURN TK_LSB exp TK_RSB TK_NEWLINE
	| TK_BREAK TK_NEWLINE
	;

optnamelist:
	  %empty
	| namelist
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

forloop:
	TK_FOR optnamelist TK_SEMICOLON optexp TK_SEMICOLON optexplist TK_SEMICOLON TK_START block TK_END
	;

whileloop:
	TK_WHILE exp TK_START block TK_END
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
	| TK_STR
	;

var:
	  TK_NAME {
		char *label = strdup(symbol_table[$<intval>1]->text);

		$<nodeval>$ = ast_node_create(AST_NAME, label, 0);
	}
	| prefixexp TK_LSB exp TK_RSB
	;

prefixexp:
	  var {
		$<nodeval>$ = $<nodeval>1;
	}
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

optexplist:
	  %empty
	| explist
	;

explist:
	  exp
	| explist TK_COMMA exp
	;

optexp:
	  %empty
	| exp
	;

exp:
	  TK_NUMBER {
		char label[BUFFER_SZ];

		snprintf(label, BUFFER_SZ, "%d", $<intval>1);

		$<nodeval>$ = ast_node_create(AST_NUM, strdup(label), 0);
	}
	| TK_NULL {
		$<nodeval>$ = ast_node_create(AST_NULL, strdup("null"), 0);
	}
	| TK_TRUE {
		$<nodeval>$ = ast_node_create(AST_TRUE, strdup("true"), 0);
	}
	| TK_FALSE {
		$<nodeval>$ = ast_node_create(AST_FALSE, strdup("false"), 0);
	}
	| TK_STRING {
		$<nodeval>$ = ast_node_create(AST_STRING, $<strval>1, 0);
	}
	| prefixexp {
		$<nodeval>$ = $<nodeval>1;
	}
	| exp TK_PLUS exp {
		$<nodeval>$ = create_binop_node($<nodeval>1, $<nodeval>3, TK_PLUS);
	}
	| exp TK_MINUS exp {
		$<nodeval>$ = create_binop_node($<nodeval>1, $<nodeval>3, TK_MINUS);
	}
	| exp TK_MUL exp {
		$<nodeval>$ = create_binop_node($<nodeval>1, $<nodeval>3, TK_MUL);
	}
	| exp TK_DIV exp {
		$<nodeval>$ = create_binop_node($<nodeval>1, $<nodeval>3, TK_DIV);
	}
	| exp TK_MOD exp {
		$<nodeval>$ = create_binop_node($<nodeval>1, $<nodeval>3, TK_MOD);
	}
	| exp TK_GT exp {
		$<nodeval>$ = create_binop_node($<nodeval>1, $<nodeval>3, TK_GT);
	}
	| exp TK_LT exp {
		$<nodeval>$ = create_binop_node($<nodeval>1, $<nodeval>3, TK_LT);
	}
	| exp TK_GE exp {
		$<nodeval>$ = create_binop_node($<nodeval>1, $<nodeval>3, TK_GE);
	}
	| exp TK_LE exp {
		$<nodeval>$ = create_binop_node($<nodeval>1, $<nodeval>3, TK_LE);
	}
	| exp TK_EQ exp {
		$<nodeval>$ = create_binop_node($<nodeval>1, $<nodeval>3, TK_EQ);
	}
	| exp TK_NE exp {
		$<nodeval>$ = create_binop_node($<nodeval>1, $<nodeval>3, TK_NE);
	}
	| exp TK_AND exp {
		$<nodeval>$ = create_binop_node($<nodeval>1, $<nodeval>3, TK_AND);
	}
	| exp TK_OR exp {
		$<nodeval>$ = create_binop_node($<nodeval>1, $<nodeval>3, TK_OR);
	}
	| TK_MINUS exp {
		$<nodeval>$ = create_unop_node($<nodeval>2, TK_MINUS);
	}
	| TK_NOT exp {
		$<nodeval>$ = create_unop_node($<nodeval>2, TK_NOT);
	}
	| var TK_ASSIGN exp {
		$<nodeval>$ = ast_node_create(AST_OP, strdup("="), 2);

		$<nodeval>$->children[0] = $<nodeval>1;
		$<nodeval>$->children[1] = $<nodeval>3;
	}
	;
%%

static
struct ast_node *
create_binop_node(struct ast_node *left, struct ast_node *right, int op)
{
	char *label;
	struct ast_node *node;

	switch (op) {
	case TK_PLUS:
		label = "+";
		break;
	case TK_MINUS:
		label = "-";
		break;
	case TK_MUL:
		label = "*";
		break;
	case TK_DIV:
		label = "/";
		break;
	case TK_MOD:
		label = "%%";
		break;
	case TK_GT:
		label = ">";
		break;
	case TK_LT:
		label = "<";
		break;
	case TK_GE:
		label = ">=";
		break;
	case TK_LE:
		label = "<";
		break;
	case TK_EQ:
		label = "==";
		break;
	case TK_NE:
		label = "!=";
		break;
	case TK_AND:
		label = "and";
		break;
	case TK_OR:
		label = "or";
		break;
	default:
		DPRINTF("Unrecognized operation\n");
		return NULL;
	}

	node = ast_node_create(AST_OP, strdup(label), 2);

	node->children[0] = left;
	node->children[1] = right;

	return node;
}

static
struct ast_node *
create_unop_node(struct ast_node *right, int op)
{
	char *label;
	struct ast_node *node;

	switch (op) {
	case TK_NOT:
		label = "not";
		break;
	case TK_MINUS:
		label = "-";
		break;
	default:
		DPRINTF("Unrecognized operation\n");
		return NULL;
	}

	node = ast_node_create(AST_OP, strdup(label), 1);

	node->children[0] = right;

	return node;
}

void
yyerror(const char *msg)
{
	printf("Error at line %d: %s\n", currow, msg);
	parse_err = true;
}
