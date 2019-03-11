#include <stdio.h>
#include <errno.h>
#include <err.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>

#include <yapl.h>
#include <codegen.h>

extern FILE *yyin;

FILE *outfile;

#ifdef YAPL_DEBUG
char nasm_cmd[] = "nasm -f elf64 -F dwarf -g -o \"%s\" \"%s\"";
#else
char nasm_cmd[] = "bash -c nasm -f elf64 -o \"%s\" \"%s\"";
#endif /* YAPL_DEBUG */

char ld_cmd[] = "ld -dynamic-linker /lib64/ld-linux-x86-64.so.2 -lc -o \"%s\" \"%s\"";

/* Bison declarations. */
int yyparse();

/* Flex declarations. */
int yylex();

void
call_linker(char *objfilename, char *outfilename)
{
	FILE *linker_output;
	char *cmd_buf, print_buf[512];
	int buflen, exit_status;

	buflen = snprintf(NULL, 0, ld_cmd, outfilename, objfilename, objfilename);
	buflen++; /* To account for the NULL-terminator. */
	cmd_buf = malloc(sizeof(*cmd_buf) * buflen);
	if (cmd_buf == NULL) {
		printf("%s: Failed to allocate internal buffer", __func__);
		exit(1);
	}

	snprintf(cmd_buf, buflen, ld_cmd, outfilename, objfilename, objfilename);
	DPRINTF("%s\n", cmd_buf);

	linker_output = popen(cmd_buf, "r");
	if (linker_output == NULL) {
		printf("%s: Failed to execute the assembler", __func__);
		exit(1);
	}

	while (fgets(print_buf, 512, linker_output) != NULL) {
		printf("%s", print_buf);
	}

	exit_status = pclose(linker_output);
	if (WEXITSTATUS(exit_status) != 0) {
		printf("Linking failed! Terminating\n");
		exit(1);
	}
}

char *
assemble(char *asmfilename, char *objfilename)
{
	FILE *nasm_output;
	char *cmd_buf, print_buf[512];
	int buflen, exit_status;

	if (objfilename == NULL) {
		objfilename = malloc(sizeof(*objfilename) * (strlen(asmfilename) + 3));
		if (objfilename == NULL) {
			printf("%s: Failed to allocate internal buffer", __func__);
			exit(1);
		}

		/* Append .o to asmfilename. */
		strcpy(objfilename, asmfilename);
		strcat(objfilename, ".o");
	}

	buflen = snprintf(NULL, 0, nasm_cmd, objfilename, asmfilename);
	buflen++; /* To account for the NULL-terminator. */
	cmd_buf = malloc(sizeof(*cmd_buf) * buflen);
	if (cmd_buf == NULL) {
		printf("%s: Failed to allocate internal buffer", __func__);
		exit(1);
	}

	snprintf(cmd_buf, buflen, nasm_cmd, objfilename, asmfilename);
	DPRINTF("%s\n", cmd_buf);

	nasm_output = popen(cmd_buf, "r");
	if (nasm_output == NULL) {
		printf("%s: Failed to execute the assembler", __func__);
		exit(1);
	}

	while (fgets(print_buf, 512, nasm_output) != NULL) {
		printf("%s", print_buf);
	}

	exit_status = pclose(nasm_output);
	if (WEXITSTATUS(exit_status) != 0) {
		printf("Assembler failed! Terminating\n");
		exit(1);
	}

	return objfilename;
}

void
output_asm(FILE *asmfile)
{
	fprintf(asmfile, "%s", get_gen_header());
	fprintf(asmfile, "%s", get_gen_data());
	fprintf(asmfile, "%s", get_gen_text());
	fflush(asmfile);
}

int
main(int argc, char *argv[]) {
	char *outfilename, *infilename, *objfilename, *asmfilename;
	FILE *asmfile;
	int opt, keep_asm = 0, keep_obj = 0;

	outfilename = infilename = NULL;

	while ((opt = getopt(argc, argv, "o:s")) != -1) {
		switch (opt) {
		case 'o':
			outfilename = optarg;
			break;
		case 's':
			keep_asm = 1;
			keep_obj = 1;
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

	if (outfilename == NULL) {
		outfilename = "a.out";
	}

	asmfilename = malloc(sizeof(*asmfilename) * strlen(infilename) + 5);
	if (asmfilename == NULL) {
		printf("%s: Failed to allocate internal buffer\n", __func__);
		exit(1);
	}

	strcpy(asmfilename, infilename);
	strcat(asmfilename, ".asm");

	asmfile = fopen(asmfilename, "w+");
	if (asmfile == NULL) {
		perror("Failed to open file stream for generating assembly");
		exit(1);
	}

	init_text_sect();
	init_data_sect();

	yyparse();

	gen_exit();

	output_asm(asmfile);
	objfilename = assemble(asmfilename, NULL);
	call_linker(objfilename, outfilename);

	fclose(yyin);
	fclose(asmfile);

	if (!keep_asm) {
		remove(asmfilename);
	}

	if (!keep_obj) {
		remove(objfilename);
	}

	return 0;
}
