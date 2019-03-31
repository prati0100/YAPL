#ifndef __SYMBOL_TABLE_H__
#define __SYMBOL_TABLE_H__

#include <yapl.h>

/* The number of parameters for a function and its parameter types. */
struct paramlist {
	int num_params;
	enum data_type *types;
};

struct st_entry {
	char *text;
	int tk_type;
	int value;
	bool is_fn;
	struct paramlist *params;
};

extern struct st_entry **symbol_table;

/* TODO: Sloppy design making this public. Try to fix this. */
extern int st_endidx, st_cursz;

void st_init(void);
int st_insert(char *text, int type);
int st_get(char *text);
void st_display(void);

#endif /* __SYMBOL_TABLE_H__ */
