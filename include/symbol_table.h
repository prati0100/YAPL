#ifndef __SYMBOL_TABLE_H__
#define __SYMBOL_TABLE_H__

#include <stdbool.h>

#include <yapl.h>

struct param {
	enum data_type type;
	int stent;
};

/* The number of parameters for a function and its parameter types. */
struct paramlist {
	int num_params;
	struct param **params;
};

struct st_entry {
	char *text;
	enum data_type type;
	int value;
	bool is_fn;
	struct paramlist *params;
};

extern struct st_entry **symbol_table;

/* TODO: Sloppy design making this public. Try to fix this. */
extern int st_endidx, st_cursz;

void st_init(void);
int st_insert(char *text);
int st_get(char *text);
void st_display(void);
struct paramlist *paramlist_create(int);

#endif /* __SYMBOL_TABLE_H__ */
