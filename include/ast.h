#ifndef __AST_H__
#define __AST_H__

enum ast_type {
	AST_NUM,
	AST_NAME,
	AST_NULL,
	AST_TRUE,
	AST_FALSE,
	AST_STRING,
	AST_OP
};

struct ast_node {
	enum ast_type type;
	char *label;
	unsigned int num_children;
	struct ast_node **children;
};

struct ast_node *ast_node_create(enum ast_type, char *, unsigned int);
char *ast_output_dot(struct ast_node *);

#endif /* __AST_H__ */
