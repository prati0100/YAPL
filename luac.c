#include <stdio.h>
#include <errno.h>
#include <err.h>
#include <unistd.h>

#include <luac.h>

extern FILE *yyin;

FILE *outfile;

/* Bison declarations. */
int yyparse();

/* Flex declarations. */
int yylex();

int
main(int argc, char *argv[]) {
	char *outfilename, *infilename;
	int opt;

	outfilename = infilename = NULL;

	while ((opt = getopt(argc, argv, "o:")) != -1) {
		switch (opt) {
		case 'o':
			outfilename = optarg;
			break;
		default:
			printf("Couldn't recognize option -%c\n", opt);
			break;
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

	if (outfilename == NULL) {
		outfilename = "a.out";
	}

	outfile = fopen(outfilename, "w+");
	if (outfile == NULL) {
		perror("Failed to open output file");
		return 1;
	}

	yyparse();

	return 0;
}
