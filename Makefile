CXX = g++
CXXFLAGS = -g -Wall -Wno-unused -Wno-deprecated -Wno-write-strings -DDEBUG -I.
FLEX = flex
BISON = bison

PARSER_SRCS = parser-phase.cc utilities.cc stringtab.cc dumptype.cc tree.cc cool-tree.cc tokens-lex.cc handle_flags.cc cool-parse.cc
LEXER_SRCS = lextest.cc utilities.cc stringtab.cc handle_flags.cc cool-lex.cc

PARSER_OBJS = $(PARSER_SRCS:.cc=.o)
LEXER_OBJS = $(LEXER_SRCS:.cc=.o)

.PHONY: all parser lexer clean dotest

all: parser lexer

parser: cool-parse.cc cool-parse.h $(PARSER_OBJS)
	$(CXX) $(CXXFLAGS) $(PARSER_OBJS) -o $@

lexer: cool-parse.h cool-lex.cc $(LEXER_OBJS)
	$(CXX) $(CXXFLAGS) $(LEXER_OBJS) -o $@

cool-parse.cc cool-parse.h: cool.y cool-parse.base.h
	$(BISON) -d -v -y -b cool --debug -p cool_yy cool.y
	mv -f cool.tab.c cool-parse.cc
	cp cool-parse.base.h cool-parse.h
	rm -f cool.tab.h

cool-lex.cc: cool.flex cool-parse.h
	$(FLEX) -d -ocool-lex.cc cool.flex

dotest: parser lexer
	./myparser good.cl > good.output 2>&1
	./myparser bad.cl > bad.output 2>&1 || true

clean:
	rm -f parser lexer *.o *.d cool-parse.cc cool-parse.h cool-lex.cc cool.output good.output bad.output
