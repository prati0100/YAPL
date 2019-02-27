#ifndef __SYMBOL_TABLE_H__
#define __SYMBOL_TABLE_H__

struct st_entry {
	char *text;
	int tk_type;
	int value;
};

extern struct st_entry **symbol_table;

void st_init(void);
int st_insert(char *text, int type);
int st_get(char *text);
void st_display(void);

#endif /* __SYMBOL_TABLE_H__ */
