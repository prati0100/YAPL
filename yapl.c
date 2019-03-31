#include <stdio.h>
#include <errno.h>
#include <err.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#include <yapl.h>

extern FILE *yyin;
extern bool parse_err;


/* Bison declarations. */
int yyparse();

/* Flex declarations. */
int yylex();

int
main(int argc, char *argv[]) {
	char *infilename;
	int opt;


	infilename = NULL;

	while ((opt = getopt(argc, argv, "")) != -1) {
		switch (opt) {
			break;
		default:
			return 1;
		}
	}

	if (optind == argc) {
		printf("No input file specified\n");
		return 1;
	}

	infilename = argv[optind];

	/*
	 * For now, I am only working with one source file. I don't know how I
	 * would need to change the architecture when there is a need to handle
	 * multiple files, so ignoring that problem for now.
	 */

	yyin = fopen(infilename, "r");
	if (yyin == NULL) {
		perror("Failed to open source file");
		return 1;
	}

	yyparse();

	if (parse_err) {
		printf("Parsing failed\n");
	} else {
		printf("Parsed successfully\n");
	}

	return 0;
}
