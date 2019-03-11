#ifndef __CODEGEN_H__
#define __CODEGEN_H__

void init_data_sect(void);
int add_to_data_sect(char *name, char *value, enum data_size size);
void init_text_sect(void);
char *gen_exp_arith(int op);
char *gen_exp_num(int number);
char *gen_exp_name(int stent);
char *gen_assign_exp(int stent);
char *gen_exp_val(void);
int gen_exit(void);

int append_to_text(char *);

char *get_gen_data(void);
char *get_gen_text(void);
char *get_gen_header(void);

#ifdef YAPL_DEBUG
void print_gen_data_sect(void);
void print_gen_text_sect(void);
#endif

#endif /* __CODEGEN_H__ */
