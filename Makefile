CXX ?= g++
CXXFLAGS = -g -Wall -Wno-unused -Wno-deprecated -Wno-write-strings -DDEBUG -I.

ifeq ($(OS),Windows_NT)
FLEX ?= win_flex
BISON ?= win_bison
RM_CMD = powershell -NoProfile -Command "Get-ChildItem -Force -ErrorAction SilentlyContinue | Where-Object { $$_.Name -in @('parser','parser.exe','lexer','lexer.exe','cool-parse.cc','cool-parse.h','cool-lex.cc','cool.output','good.output','bad.output','cool.tab.h') -or $$_.Name -like '*.o' -or $$_.Name -like '*.d' } | ForEach-Object { Remove-Item -Force -ErrorAction SilentlyContinue $$_.FullName }"
SUBMIT_CLEAN_CMD = powershell -NoProfile -Command "Get-ChildItem -Force -ErrorAction SilentlyContinue | Where-Object { $$_.Name -in @('parser','parser.exe','lexer','lexer.exe','cool-parse.cc','cool-parse.h','cool-lex.cc','cool.output','good.output','bad.output','cool.tab.h','core') -or $$_.Name -like '*.o' -or $$_.Name -like '*.d' -or $$_.Name -like '*.stackdump' -or $$_.Name -like 'core.*' } | ForEach-Object { Remove-Item -Force -ErrorAction SilentlyContinue $$_.FullName }"
else
FLEX ?= flex
BISON ?= bison
RM_CMD = rm -f parser lexer *.o *.d cool-parse.cc cool-parse.h cool-lex.cc cool.output good.output bad.output cool.tab.h
SUBMIT_CLEAN_CMD = rm -f parser lexer *.o *.d *.stackdump core core.* cool-parse.cc cool-parse.h cool-lex.cc cool.output good.output bad.output cool.tab.h
endif

PARSER_SRCS = parser-phase.cc utilities.cc stringtab.cc dumptype.cc tree.cc cool-tree.cc tokens-lex.cc handle_flags.cc cool-parse.cc
LEXER_SRCS = lextest.cc utilities.cc stringtab.cc handle_flags.cc cool-lex.cc

PARSER_OBJS = $(PARSER_SRCS:.cc=.o)
LEXER_OBJS = $(LEXER_SRCS:.cc=.o)

.PHONY: all parser lexer clean dotest submit-clean

all: parser lexer

parser: cool-parse.cc cool-parse.h cool.tab.h $(PARSER_OBJS)
	$(CXX) $(CXXFLAGS) $(PARSER_OBJS) -o $@

lexer: cool-parse.h cool.tab.h cool-lex.cc $(LEXER_OBJS)
	$(CXX) $(CXXFLAGS) $(LEXER_OBJS) -o $@

ifeq ($(OS),Windows_NT)
cool-parse.cc cool-parse.h cool.tab.h: cool.y cool-parse.base.h
	$(BISON) -d -v -y -b cool --debug -p cool_yy cool.y
	powershell -NoProfile -Command "Move-Item -Force 'cool.tab.c' 'cool-parse.cc'; Copy-Item -Force 'cool-parse.base.h' 'cool-parse.h'; Copy-Item -Force 'cool-parse.base.h' 'cool.tab.h'"
else
cool-parse.cc cool-parse.h cool.tab.h: cool.y cool-parse.base.h
	$(BISON) -d -v -y -b cool --debug -p cool_yy cool.y
	mv -f cool.tab.c cool-parse.cc
	cp cool-parse.base.h cool-parse.h
	cp cool-parse.base.h cool.tab.h
endif

cool-parse.o: cool.tab.h

cool-lex.cc: cool.flex cool-parse.h
	$(FLEX) -d -o cool-lex.cc cool.flex

dotest: parser lexer
	./myparser good.cl > good.output 2>&1
	./myparser bad.cl > bad.output 2>&1 || true

clean:
	$(RM_CMD)

submit-clean:
	$(SUBMIT_CLEAN_CMD)
