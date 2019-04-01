#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <yapl.h>
#include <ast.h>

#define BUFFER_SZ 1024

/* Skeleton for the dot file generated for an AST. */
static char dot_format[] =
	"/*\n"
	" * This file is auto generated by the compiler for the language YAPL.\n"
	" * Copyright (C) 2019 Pratyush Yadav\n"
	" */\n"
	"\n"
	"digraph AST {\n"
	"%s\n"
	"%s"
	"}\n";
static char dot_label_format[] = "\t%d [label=\"%s\"];\n";
static char dot_body_format[] = "\t%d -> %d;\n";

static char *dot_labels, *dot_body;
static int dot_labels_idx, dot_labels_sz, dot_body_idx, dot_body_sz;
static int dot_node_idx;

struct ast_node *
ast_node_create(enum ast_type type, char *label, unsigned int num_children)
{
	struct ast_node *n;

	n = malloc(sizeof(*n));
	if (n == NULL) {
		printf("Failed to allocate AST node\n");
		return NULL;
	}

	/* Allocate an array for the children. The calling procedure will fill it. */
	n->children = malloc(sizeof(*n->children) * num_children);
	if (n->children == NULL) {
		printf("Failed to allocate AST buffer\n");
		free(n);
		return NULL;
	}

	n->type = type;
	n->label = label;
	n->num_children = num_children;

	return n;
}

void
ast_dot_traverse(struct ast_node *root)
{
	int i, len, myidx;
	char buf[BUFFER_SZ];

	if (root == NULL) {
		return;
	}

	myidx = dot_node_idx;

	/* First, add its node and label */
	len = snprintf(NULL, 0, dot_label_format, dot_node_idx, root->label);
	if (dot_labels_idx + len >= dot_labels_sz) {
		dot_labels_sz += BUFFER_SZ;
		dot_labels = realloc(dot_labels, dot_labels_sz);
	}

	snprintf(buf, len + 1, dot_label_format, dot_node_idx, root->label);
	dot_labels_idx += len;
	strcat(dot_labels, buf);

	/* Now add connections to all children */
	for (i = 0; i < root->num_children; i++) {
		len = snprintf(NULL, 0, dot_body_format, dot_node_idx,
			dot_node_idx + i + 1);
		if (dot_body_idx + len >= dot_body_sz) {
			dot_body_sz += BUFFER_SZ;
			dot_body = realloc(dot_body, dot_body_sz);
		}

		snprintf(buf, len + 1, dot_body_format, myidx,
			dot_node_idx + 1);
		dot_body_idx += len;
		strcat(dot_body, buf);

		dot_node_idx++;
		ast_dot_traverse(root->children[i]);
	}
}

char *
ast_output_dot(struct ast_node *node)
{
	char *output;
	int len;

	if (dot_body == NULL) {
		dot_body = malloc(sizeof(*dot_body) * BUFFER_SZ);
	}
	if (dot_labels == NULL) {
		dot_labels = malloc(sizeof(*dot_body) * BUFFER_SZ);
	}

	/* Initialize for use with strcat() */
	dot_body[0] = dot_labels[0] = '\0';

	dot_body_sz = BUFFER_SZ;
	dot_labels_sz = BUFFER_SZ;
	dot_labels_idx = dot_body_idx = dot_node_idx = 0;

	ast_dot_traverse(node);

	len = snprintf(NULL, 0, dot_format, dot_labels, dot_body);

	output = malloc(sizeof(*output) * len);
	if (output == NULL) {
		printf("Failed to allocate buffer for dot output\n");
		free(dot_body);
		return NULL;
	}

	snprintf(output, len + 1, dot_format, dot_labels, dot_body);
	free(dot_body);

	return output;
}
