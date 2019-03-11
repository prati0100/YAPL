#ifndef __SYMBOL_TABLE_H__
#define __SYMBOL_TABLE_H__

#include <yapl.h>

struct st_entry {
	char *text;
	int tk_type;
	enum data_size size;
	int value;
};

extern struct st_entry **symbol_table;

/* TODO: Sloppy design making this public. Try to fix this. */
extern int st_endidx, st_cursz;

void st_init(void);
int st_insert(char *text, int type);
int st_get(char *text);
void st_display(void);

#endif /* __SYMBOL_TABLE_H__ */
