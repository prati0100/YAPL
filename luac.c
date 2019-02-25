#include <luac.h>
#include <stdio.h>
#include <errno.h>
#include <err.h>

extern FILE *yyin;

/* Bison declarations. */
int yyparse();

/* Flex declarations. */
int yylex();

int
main(int argc, char const *argv[]) {
	if (argc != 2) {
		printf("Expected 2 arguments, got %d\n", argc);
		return 1;
	}

	/*
	 * For now, I am only working with one source file. I don't know how I
	 * would need to change the architecture when there is a need to handle
	 * multiple files, so ignoring that problem for now.
	 */

	yyin = fopen(argv[1], "r");
	if (yyin == NULL) {
		perror("Failed to open source file");
		return 1;
	}

	yyparse();

	return 0;
}
