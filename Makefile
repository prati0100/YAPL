CC = gcc
INCLUDES = -I .
CFLAGS = -Wall -Wshadow
DEBUGFLAGS = -D LUAC_DEBUG -g
DEPS = *.h
OBJDIR = objs
BINDIR = bin

OBJS = $(patsubst %.c,$(OBJDIR)/%.o,$(wildcard *.c))

default: debug

.PHONY: default clean all release debug

clean:
	@echo Cleaning...
	rm -f $(OBJDIR)/*.o
	rm -f $(BINDIR)/*

debug: CFLAGS += $(DEBUGFLAGS)
debug: all

release: clean all

all: $(OBJS)
	@mkdir -p ${BINDIR}
	$(CC) -o $(BINDIR)/luac $^ $(CLFAGS) $(INCLUDES) $(LIBS)

# All the headers are a depencency for each C file, even though it might not
# actually include it. This means that if one header changes, all the files
# are re-compiled. The clean way of doing it would be dependency generation
# but the scale of this project is small enough for that to not be a problem.
$(OBJDIR)/%.o : %.c $(DEPS)
	mkdir -p $(OBJDIR)
	@echo Building $<
	$(CC) -c -o $@ $< $(CFLAGS) $(INCLUDES)
