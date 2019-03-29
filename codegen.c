/*
 * This contains the templates for the assembly we will generate, along with the
 * logic used to convert the templates into the needed assembly. NASM is the
 * target assembler. The assembly is for x64 and uses the Linux-x64 calling
 * convention.
 *
 * There is a placeholder system used. These placeholders will be
 * replaced by whatever values needed during generation and represent the
 * "arguments" for the template. A printf-like syntax is used, to make them
 * easier to work with snprintf(). Since % is a special character in printf
 * and NASM uses % in its syntax, always remember to escape the percents used
 * in NASM syntax.
 *
 * Reminder: since the string literals are non-mutable, you need to allocate
 * memory for them and copy the template before working with them.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <yapl.h>
#include <symbol_table.h>
#include <codegen.h>

#include "parser.tab.h"

#define BUFFER_SZ 1500

/* ---------------------------- Templates ------------------------------- */

/* XXX: temporaryily here. Needs to improve. */
char *header =
	"global _start\n"
	"extern printf\n"
	"\n";

/* Starts of varions sections like text, data, bss, etc. */
char *section_text = "section .text\n";
char *section_data = "section .data\n";

char *start = "_start:\n";

/* Placeholders are variable name and value.*/
char *data_byte = "%s db %s\n";
char *data_word = "%s dw %s\n";
char *data_dword = "%s dd %s\n";
char *data_qword = "%s dq %s\n";

/*
 * The two operand values are on the stack. Pop them, make the operation and
 * put the result back on the stack.
 */
char *exp_setup =
	"pop rbx\n"
	"pop rax\n";
char *eval_exp_add = "add rax, rbx\n";	/* exp TK_PLUS exp */
char *eval_exp_sub = "sub rax, rbx\n";	/* exp TK_MINUS exp */
char *eval_exp_mul = "mul rbx\n";		/* exp TK_MUL exp */
char *eval_exp_div = "div rbx\n";		/* exp TK_DIV exp */
char *exp_finish = "push rax\n";

/*
 * exp: TK_NUMBER
 *
 * Here, we can directly push the number to stack, because that itself is the
 * result of the expression.
 */
char *eval_exp_num =
	"mov eax, %d\n"
	"push rax\n";
/* TODO: This assumes all variables to be global. Make it handle locals. */
/*
 * exp: TK_NAME
 *
 * Move the variable from memory to register. Then push it to stack because the
 * value of the variable is the result of the expression.
 */
char *eval_exp_name =
	"mov %s, [%s]\n"
	"push rax\n";

/*
 * assign: TK_NAME TK_ASSIGN exp
 *
 * The top of the stack contains the result of exp. Pop it and set the value
 * of TK_NAME to the result.
 */
char *assign_exp =
	"pop rax\n"
	"mov [%s], %s\n";

/*
 * Get the expression value into rax. Usually called from the root of the
 * expression tree to get the final computed value of the expression. Only works
 * when the top of the stack has the result of exp, which should be the case
 * when evaluating expressions.
 */
char *exp_val = "pop rax\n";

char *exit_asm =
	"mov rax, 60\n"
	"mov rdi, 0\n"
	"syscall\n";

/* ---------------------------------------------------------------------- */

/* Generated code buffers. These will be sent to the assembler. */
char *gen_data_sect = NULL;
int gen_data_sz;
char *gen_text_sect = NULL;
int gen_text_sz;

/*
 * Get the corresponding register for the data size. Returns only the varions
 * of the a registers.
 */
static
char *
get_reg_from_sz(enum data_size size)
{
	switch (size) {
	case BYTE:
		return "al";
	case WORD:
		return "ax";
	case DWORD:
		return "eax";
	case QWORD:
		return "rax";
	default:
		ASSERT(0, "Reached unreachable section");
		return NULL;
	}
}

/*
 * Currently this assumes all the variables are global and puts them in the
 * data section. Later, I will add scopes to variables and then we will only
 * put the globals here.
 */

/* TODO: Make this more flexible to larger data sections by using realloc. */
void
init_data_sect()
{
	gen_data_sect = malloc(sizeof(*gen_data_sect) * BUFFER_SZ);
	if (gen_data_sect == NULL) {
		printf("Failed to allocate buffer for data section generation: %s\n",
			strerror(errno));
		exit(1);
	}

	gen_data_sz = BUFFER_SZ;

	*gen_data_sect = '\0'; /* For use with strcat. */
	strcat(gen_data_sect, section_data);
}

int
add_to_data_sect(char *name, char *value, enum data_size size)
{
	char buf[BUFFER_SZ];

	switch (size) {
	case BYTE:
		if (snprintf(buf, BUFFER_SZ, data_byte, name, value) == BUFFER_SZ) {
			return ENOMEM;
		}
	case WORD:
		if (snprintf(buf, BUFFER_SZ, data_word, name, value) == BUFFER_SZ) {
			return ENOMEM;
		}
		break;
	case DWORD:
		if (snprintf(buf, BUFFER_SZ, data_dword, name, value) == BUFFER_SZ) {
			return ENOMEM;
		}
		break;
	case QWORD:
		if (snprintf(buf, BUFFER_SZ, data_qword, name, value) == BUFFER_SZ) {
			return ENOMEM;
		}
		break;
	default:
		return EINVAL;
	}

	while ((strlen(gen_data_sect) + strlen(buf)) >= gen_data_sz) {
		gen_data_sect = realloc(gen_data_sect, gen_data_sz + BUFFER_SZ);
		if (gen_data_sect == NULL) {
			printf("Failed to allocate internal buffer: %s\n", strerror(errno));
			exit(1);
		}

		gen_data_sz += BUFFER_SZ;
	}

	strcat(gen_data_sect, buf);

	return 0;
}

#ifdef YAPL_DEBUG
void
print_gen_data_sect()
{
	printf("%s", gen_data_sect);
}
#endif /* YAPL_DEBUG */

void
init_text_sect()
{
	gen_text_sect = malloc(sizeof(*gen_text_sect) * BUFFER_SZ);
	if (gen_text_sect == NULL) {
		printf("Failed to allocate buffer for text section generation: %s\n",
			strerror(errno));
		exit(1);
	}

	gen_text_sz = BUFFER_SZ;

	*gen_text_sect = '\0'; /* For use with strcat. */
	strcat(gen_text_sect, section_text);
	strcat(gen_text_sect, start);
}

char *
gen_exp_arith(int op)
{
	char buf[BUFFER_SZ];

	buf[0] = 0;

	strcpy(buf, exp_setup);

	switch (op) {
	case TK_PLUS:
		strcat(buf, eval_exp_add);
		break;
	case TK_MINUS:
		strcat(buf, eval_exp_sub);
		break;
	case TK_MUL:
		strcat(buf, eval_exp_mul);
		break;
	case TK_DIV:
		strcat(buf, eval_exp_div);
		break;
	default:
		printf("%s: Unrecongized arithmetic operator: %d\n", __func__, op);
		return NULL;
	}

	strcat(buf, exp_finish);

	return strdup(buf);
}

char *
gen_exp_num(int number)
{
	char buf[BUFFER_SZ];

	snprintf(buf, BUFFER_SZ, eval_exp_num, number);

	return strdup(buf);
}

char *
gen_exp_name(int stent)
{
	char buf[BUFFER_SZ];

	ASSERT(symbol_table[stent]->tk_type == TK_NAME, "st entry is not a name");

	snprintf(buf, BUFFER_SZ, eval_exp_name,
		get_reg_from_sz(symbol_table[stent]->size),
		symbol_table[stent]->text);

	return strdup(buf);
}

char *
gen_assign_exp(int stent)
{
	char buf[BUFFER_SZ];

	ASSERT(symbol_table[stent]->tk_type == TK_NAME, "st entry is not a name");

	snprintf(buf, BUFFER_SZ, assign_exp, symbol_table[stent]->text,
		get_reg_from_sz(symbol_table[stent]->size));

	return strdup(buf);
}

int
append_to_text(char *str)
{
	while ((strlen(gen_text_sect) + strlen(str)) >= gen_text_sz) {
		gen_text_sect = realloc(gen_text_sect, gen_text_sz + BUFFER_SZ);
		if (gen_text_sect == NULL) {
			printf("Failed to allocate internal buffer: %s\n", strerror(errno));
			exit(1);
		}

		gen_text_sz += BUFFER_SZ;
	}

	strcat(gen_text_sect, str);

	return 0;
}

char *
gen_exp_val()
{
	return strdup(exp_val);
}

int
gen_exit()
{
	strcat(gen_text_sect, exit_asm);

	return 0;
}

#ifdef YAPL_DEBUG
void
print_gen_text_sect()
{
	printf("%s", gen_text_sect);
}
#endif /* YAPL_DEBUG */

char *
get_gen_data()
{
	return gen_data_sect;
}

char *
get_gen_text()
{
	return gen_text_sect;
}

char *
get_gen_header()
{
	return header;
}
