/*
 *  cool.y
 *  Parser definition for the COOL language.
 */
%{
#include <iostream>
#include "cool-tree.h"
#include "stringtab.h"
#include "utilities.h"

extern char *curr_filename;

/* Locations */
#define YYLTYPE int
#define cool_yylloc curr_lineno

extern int node_lineno;

#define YYLLOC_DEFAULT(Current, Rhs, N)                  \
  do {                                                  \
    if (N) {                                            \
      (Current) = Rhs[1];                               \
    } else {                                            \
      (Current) = curr_lineno;                          \
    }                                                   \
    node_lineno = (Current);                            \
  } while (0)

#define SET_NODELOC(Current) \
  node_lineno = (Current)

void yyerror(char *s);
extern int yylex();

Program ast_root;
Classes parse_results;
int omerrs = 0;
%}

%union {
  Boolean boolean;
  Symbol symbol;
  Program program;
  Class_ class_;
  Classes classes;
  Feature feature;
  Features features;
  Formal formal;
  Formals formals;
  Case case_;
  Cases cases;
  Expression expression;
  Expressions expressions;
  char *error_msg;
}

%token CLASS 258 ELSE 259 FI 260 IF 261 IN 262
%token INHERITS 263 LET 264 LOOP 265 POOL 266 THEN 267 WHILE 268
%token CASE 269 ESAC 270 OF 271 DARROW 272 NEW 273 ISVOID 274
%token <symbol> STR_CONST 275 INT_CONST 276
%token <boolean> BOOL_CONST 277
%token <symbol> TYPEID 278 OBJECTID 279
%token ASSIGN 280 NOT 281 LE 282 ERROR 283

%type <program> program
%type <classes> class_list
%type <class_> class_def
%type <features> feature_list
%type <feature> feature
%type <formals> formal_list_opt formal_list
%type <formal> formal
%type <cases> case_list
%type <case_> case_branch
%type <expressions> argument_list_opt argument_list
%type <expressions> block_body block_expression_list
%type <expression> expression let_expression let_init

/* Precedence is intentionally restricted to expression syntax. */
%right ASSIGN
%nonassoc NOT
%nonassoc LE '<' '='
%left '+' '-'
%left '*' '/'
%nonassoc ISVOID
%nonassoc '~'
%left '@'
%left '.'

%%

program
  : class_list
    {
      @$ = @1;
      SET_NODELOC(@1);
      ast_root = program($1);
      parse_results = $1;
    }
  ;

class_list
  : class_def
    {
      @$ = @1;
      $$ = single_Classes($1);
    }
  | class_list class_def
    {
      @$ = @1;
      $$ = append_Classes($1, single_Classes($2));
    }
  | error ';'
    {
      $$ = nil_Classes();
      yyerrok;
    }
  | class_list error ';'
    {
      $$ = $1;
      yyerrok;
    }
  ;

class_def
  : CLASS TYPEID '{' feature_list '}' ';'
    {
      @$ = @1;
      SET_NODELOC(@1);
      $$ = class_($2, idtable.add_string("Object"), $4,
                  stringtable.add_string(curr_filename));
    }
  | CLASS TYPEID INHERITS TYPEID '{' feature_list '}' ';'
    {
      @$ = @1;
      SET_NODELOC(@1);
      $$ = class_($2, $4, $6, stringtable.add_string(curr_filename));
    }
  ;

feature_list
  :
    {
      $$ = nil_Features();
    }
  | feature_list feature ';'
    {
      @$ = @1;
      $$ = append_Features($1, single_Features($2));
    }
  | feature_list error ';'
    {
      $$ = $1;
      yyerrok;
    }
  ;

feature
  : OBJECTID '(' formal_list_opt ')' ':' TYPEID '{' expression '}'
    {
      @$ = @1;
      SET_NODELOC(@1);
      $$ = method($1, $3, $6, $8);
    }
  | OBJECTID ':' TYPEID
    {
      @$ = @1;
      SET_NODELOC(@1);
      $$ = attr($1, $3, no_expr());
    }
  | OBJECTID ':' TYPEID ASSIGN expression
    {
      @$ = @1;
      SET_NODELOC(@1);
      $$ = attr($1, $3, $5);
    }
  ;

formal_list_opt
  :
    {
      $$ = nil_Formals();
    }
  | formal_list
    {
      $$ = $1;
    }
  ;

formal_list
  : formal
    {
      @$ = @1;
      $$ = single_Formals($1);
    }
  | formal_list ',' formal
    {
      @$ = @1;
      $$ = append_Formals($1, single_Formals($3));
    }
  ;

formal
  : OBJECTID ':' TYPEID
    {
      @$ = @1;
      SET_NODELOC(@1);
      $$ = formal($1, $3);
    }
  ;

expression
  : OBJECTID ASSIGN expression
    {
      @$ = @1;
      SET_NODELOC(@1);
      $$ = assign($1, $3);
    }
  | expression '@' TYPEID '.' OBJECTID '(' argument_list_opt ')'
    {
      @$ = @1;
      SET_NODELOC(@1);
      $$ = static_dispatch($1, $3, $5, $7);
    }
  | expression '.' OBJECTID '(' argument_list_opt ')'
    {
      @$ = @1;
      SET_NODELOC(@1);
      $$ = dispatch($1, $3, $5);
    }
  | OBJECTID '(' argument_list_opt ')'
    {
      Expression self_expr;
      @$ = @1;
      SET_NODELOC(@1);
      self_expr = object(idtable.add_string("self"));
      SET_NODELOC(@1);
      $$ = dispatch(self_expr, $1, $3);
    }
  | IF expression THEN expression ELSE expression FI
    {
      @$ = @1;
      SET_NODELOC(@1);
      $$ = cond($2, $4, $6);
    }
  | WHILE expression LOOP expression POOL
    {
      @$ = @1;
      SET_NODELOC(@1);
      $$ = loop($2, $4);
    }
  | '{' block_body '}'
    {
      @$ = @1;
      SET_NODELOC(@1);
      $$ = block($2);
    }
  | LET let_expression
    {
      @$ = @1;
      $$ = $2;
    }
  | CASE expression OF case_list ESAC
    {
      @$ = @1;
      SET_NODELOC(@1);
      $$ = typcase($2, $4);
    }
  | NEW TYPEID
    {
      @$ = @1;
      SET_NODELOC(@1);
      $$ = new_($2);
    }
  | ISVOID expression
    {
      @$ = @1;
      SET_NODELOC(@1);
      $$ = isvoid($2);
    }
  | expression '+' expression
    {
      @$ = @2;
      SET_NODELOC(@2);
      $$ = plus($1, $3);
    }
  | expression '-' expression
    {
      @$ = @2;
      SET_NODELOC(@2);
      $$ = sub($1, $3);
    }
  | expression '*' expression
    {
      @$ = @2;
      SET_NODELOC(@2);
      $$ = mul($1, $3);
    }
  | expression '/' expression
    {
      @$ = @2;
      SET_NODELOC(@2);
      $$ = divide($1, $3);
    }
  | '~' expression
    {
      @$ = @1;
      SET_NODELOC(@1);
      $$ = neg($2);
    }
  | expression '<' expression
    {
      @$ = @2;
      SET_NODELOC(@2);
      $$ = lt($1, $3);
    }
  | expression LE expression
    {
      @$ = @2;
      SET_NODELOC(@2);
      $$ = leq($1, $3);
    }
  | expression '=' expression
    {
      @$ = @2;
      SET_NODELOC(@2);
      $$ = eq($1, $3);
    }
  | NOT expression
    {
      @$ = @1;
      SET_NODELOC(@1);
      $$ = comp($2);
    }
  | '(' expression ')'
    {
      @$ = @2;
      $$ = $2;
    }
  | OBJECTID
    {
      @$ = @1;
      SET_NODELOC(@1);
      $$ = object($1);
    }
  | INT_CONST
    {
      @$ = @1;
      SET_NODELOC(@1);
      $$ = int_const($1);
    }
  | STR_CONST
    {
      @$ = @1;
      SET_NODELOC(@1);
      $$ = string_const($1);
    }
  | BOOL_CONST
    {
      @$ = @1;
      SET_NODELOC(@1);
      $$ = bool_const($1);
    }
  ;

argument_list_opt
  :
    {
      $$ = nil_Expressions();
    }
  | argument_list
    {
      $$ = $1;
    }
  ;

argument_list
  : expression
    {
      @$ = @1;
      $$ = single_Expressions($1);
    }
  | argument_list ',' expression
    {
      @$ = @1;
      $$ = append_Expressions($1, single_Expressions($3));
    }
  ;

block_body
  : block_expression_list
    {
      $$ = $1;
    }
  | block_expression_list error
    {
      $$ = $1;
      yyerrok;
    }
  | error
    {
      $$ = nil_Expressions();
      yyerrok;
    }
  ;

block_expression_list
  : expression ';'
    {
      @$ = @1;
      $$ = single_Expressions($1);
    }
  | block_expression_list expression ';'
    {
      @$ = @1;
      $$ = append_Expressions($1, single_Expressions($2));
    }
  | error ';'
    {
      $$ = nil_Expressions();
      yyerrok;
    }
  | block_expression_list error ';'
    {
      $$ = $1;
      yyerrok;
    }
  ;

case_list
  : case_branch
    {
      @$ = @1;
      $$ = single_Cases($1);
    }
  | case_list case_branch
    {
      @$ = @1;
      $$ = append_Cases($1, single_Cases($2));
    }
  ;

case_branch
  : OBJECTID ':' TYPEID DARROW expression ';'
    {
      @$ = @1;
      SET_NODELOC(@1);
      $$ = branch($1, $3, $5);
    }
  ;

/* `%prec ASSIGN` gives `let` the conventional right-extended interpretation. */
let_expression
  : OBJECTID ':' TYPEID let_init IN expression %prec ASSIGN
    {
      @$ = @1;
      SET_NODELOC(@1);
      $$ = let($1, $3, $4, $6);
    }
  | OBJECTID ':' TYPEID let_init ',' let_expression
    {
      @$ = @1;
      SET_NODELOC(@1);
      $$ = let($1, $3, $4, $6);
    }
  | error ',' let_expression
    {
      $$ = $3;
      yyerrok;
    }
  | error IN expression %prec ASSIGN
    {
      $$ = $3;
      yyerrok;
    }
  ;

let_init
  :
    {
      $$ = no_expr();
    }
  | ASSIGN expression
    {
      @$ = @1;
      $$ = $2;
    }
  ;

%%

void yyerror(char *s)
{
  extern int curr_lineno;

  std::cerr << "\"" << curr_filename << "\", line " << curr_lineno
            << ": " << s << " at or near ";
  print_cool_token(yychar);
  std::cerr << std::endl;
  omerrs++;

  if (omerrs > 50) {
    fprintf(stdout, "More than 50 errors\n");
    exit(1);
  }
}
