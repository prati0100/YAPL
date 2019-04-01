CC = gcc
INCLUDES = -I include
CFLAGS = -Wall -Wshadow
DEBUGFLAGS = -D YAPL_DEBUG -g
DEPS = include/*.h
OBJDIR = objs
BINDIR = bin

CFILES = yapl.c lex.yy.c parser.tab.c symbol_table.c ast.c

OBJS = $(patsubst %.c,$(OBJDIR)/%.o,$(CFILES))

default: debug

.PHONY: default clean all release debug

clean:
	@echo Cleaning...
	rm -f $(OBJDIR)/*.o
	rm -f $(BINDIR)/yapl
	rm -f lex.yy.c
	rm -f parser.tab.c
	rm -f parser.tab.h

debug: CFLAGS += $(DEBUGFLAGS)
debug: all

release: clean all

all: parser.tab.c lex.yy.c $(OBJS)
	@mkdir -p ${BINDIR}
	$(CC) -o $(BINDIR)/yapl $(OBJS) $(CLFAGS) $(INCLUDES) $(LIBS)

# Rule for the flex file
lex.yy.c: lexer.l
	@echo Generating lexer from $<
	flex $<

# Rule for the bison file
parser.tab.c: parser.y
	@echo Generating parser from $<
	bison -d $<

# All the headers are a depencency for each C file, even though it might not
# actually include it. This means that if one header changes, all the files
# are re-compiled. The clean way of doing it would be dependency generation
# but the scale of this project is small enough for that to not be a problem.
$(OBJDIR)/%.o : %.c $(DEPS)
	@mkdir -p $(OBJDIR)
	@echo Building $<
	$(CC) -c -o $@ $< $(CFLAGS) $(INCLUDES)
