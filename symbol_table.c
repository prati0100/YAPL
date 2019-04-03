#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <symbol_table.h>
#include <errno.h>

#include <yapl.h>

/* TODO: Maybe use a hash table? */

/* Not the max size. Instead, this is how many slots we allocate at a time. */
#define ST_SIZE 30

struct st_entry **symbol_table = NULL;
int st_endidx = 0;
int st_cursz = 0;

static
char *
data_type_to_str(enum data_type type)
{
	switch (type) {
	case INT:
		return "int";
	case UINT:
		return "uint";
	case CHAR:
		return "char";
	case UCHAR:
		return "uchar";
	case LONG:
		return "long";
	case ULONG:
		return "ulong";
	case SHORT:
		return "short";
	case USHORT:
		return "ushort";
	case STR:
		return "str";
	default:
		DPRINTF("Unknown data type\n");
		return "unknown";
	}
}

static
int
type_size(enum data_type type) {
	switch (type) {
	case INT:
		return 4;
	case UINT:
		return 4;
	case CHAR:
		return 1;
	case UCHAR:
		return 1;
	case LONG:
		return 8;
	case ULONG:
		return 8;
	case SHORT:
		return 2;
	case USHORT:
		return 2;
	case STR:
		return 1;
	default:
		DPRINTF("Unknown data type\n");
		return -1;
	}
}

struct st_entry *
st_entry_create(char *text, int scope)
{
	struct st_entry *s;

	s = malloc(sizeof(*s));
	if (s == NULL) {
		return NULL;
	}

	s->text = strdup(text);
	s->is_fn = false;
	s->is_declared = false;
	s->params = NULL;
	s->is_arr = false;
	s->arrsz = 0;

	s->scope = scope;

	return s;
}

int
st_grow()
{
	int i;

	symbol_table = realloc(symbol_table, sizeof(*symbol_table) *
		(st_cursz + ST_SIZE));
	if (errno) {
		printf("Failed to grow the symbol table: %s\n", strerror(errno));
		return errno;
	}

	for (i = st_cursz; i < st_cursz + ST_SIZE; i++) {
		symbol_table[i] = NULL;
	}

	st_cursz += ST_SIZE;

	return 0;
}

void
st_init()
{
	if (st_grow()) {
		exit(1);
	}
}

int
st_insert(char *text, int scope)
{
	if (st_endidx == st_cursz) {
		if (st_grow()) {
			printf("Failed to grow symbol table\n");
			exit(1);
		}
	}

	symbol_table[st_endidx++] = st_entry_create(text, scope);

	return st_endidx - 1;
}

int
st_get(char *text, int scope)
{
	int i;

	for (i = 0; i < st_endidx; i++) {
		if (strcmp(text, symbol_table[i]->text) == 0 &&
			symbol_table[i]->scope == scope) {
			return i;
		}
	}

	return -1;
}

void
st_display()
{
	int i, j;
	struct st_entry *stent;

	printf("Name\tType\tIs fn\tNum params\tscope\tIs arr\tSize\n");

	for (i = 0; i < st_endidx; i++) {
		stent = symbol_table[i];
		printf("%s\t%s\t%s",
			stent->text,
			data_type_to_str(stent->type),
			stent->is_fn ? "true" : "false"
		);

		if (stent->is_fn) {
			printf("\t\t%d", stent->params->num_params);
		} else {
			/* Not a function, so don't really have anything to print. */
			printf("\t\t-");
		}

		/* Get the name of the function this entry belongs to. */
		if (stent->is_fn) {
			printf("\t-");
		} else if (stent->scope != -1) {
			printf("\t%s", symbol_table[stent->scope]->text);
		} else {
			printf("\tglobal");
		}

		/* Is arr? */
		printf("\t%s", stent->is_arr ? "true" : "false");

		/* Size */
		if (stent->is_arr) {
			printf("\t%d", type_size(stent->type) * stent->arrsz);
		} else {
			printf("\t%d", type_size(stent->type));
		}

		printf("\n");
	}

	printf("\nFunction parameters:\n");

	for (i = 0; i < st_endidx; i++) {
		stent = symbol_table[i];

		if (stent->is_fn) {
			printf("%s: <", stent->text);

			/*
			 * Print the names and types of the parameters in format
			 * <type:name, ...>
			 */
			for (j = 0; j < stent->params->num_params; j++) {
				printf("%s:%s", data_type_to_str(stent->params->params[j]->type),
					symbol_table[stent->params->params[j]->stent]->text);

				/* Print comma for all but the last item. */
				if (j != stent->params->num_params - 1) {
					printf(", ");
				}
			}

			/* Print the closing > */
			printf(">\n");
		}
	}
}

struct paramlist *
paramlist_create(int num_params)
{
	struct paramlist *list;

	list = malloc(sizeof(*list));
	if (list == NULL) {
		printf("Failed to create a parameter list\n");
		return NULL;
	}

	list->num_params = num_params;
	list->params = malloc(sizeof(*list->params) * num_params);
	if (list->params == NULL) {
		printf("Failed to allocate parameter list\n");
		free(list);
		return NULL;
	}

	return list;
}
