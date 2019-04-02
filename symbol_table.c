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

struct st_entry *
st_entry_create(char *text, int scope)
{
	struct st_entry *s;

	s = malloc(sizeof(*s));
	if (s == NULL) {
		return NULL;
	}

	s->text = strdup(text);
	s->value = 0;
	s->is_fn = false;
	s->params = NULL;

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
	int i;

	printf("Text\tType\n");

	for (i = 0; i < st_endidx; i++) {
		printf("%s\t%d\n",
			symbol_table[i]->text,
			symbol_table[i]->type);
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
