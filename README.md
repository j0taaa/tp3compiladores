README - Trabalho Prático 03 - Compiladores
======================================================

Este projeto implementa a etapa de análise sintática da linguagem Cool em C++,
usando Bison e o pacote padrão de árvores da linguagem. A árvore sintática
abstrata é construída durante o parsing, e o fluxo geral continua sendo o
esperado: o scanner gera uma sequência de tokens e o parser consome essa
sequência. A organização do repositório segue a estrutura principal do
trabalho, com a gramática em `cool.y`, o scanner em `cool.flex`, os testes
principais em `good.cl` e `bad.cl`, e o script `myparser` mantendo a execução
no formato `lexer | parser`.

O parser constrói a AST oficial de Cool, com `program` como raiz para entradas
válidas. A gramática cobre programas com uma ou mais classes, classes com e sem
herança, listas vazias ou não vazias de features, atributos com e sem
inicialização, métodos com diferentes quantidades de parâmetros formais e as
formas centrais de expressão da linguagem, incluindo atribuição, dispatch
dinâmico e estático, dispatch implícito em `self`, condicionais, laços,
blocos, `let`, `case`, criação de objetos, operadores unários, operadores
aritméticos, operadores relacionais, expressões entre parênteses,
identificadores e constantes.

As ações semânticas em `cool.y` criam diretamente os nós da árvore por meio dos
construtores oficiais, como `program`, `class_`, `method`, `attr`, `formal`,
`branch`, `assign`, `dispatch`, `static_dispatch`, `cond`, `loop`, `block`,
`let`, `typcase`, `new_`, `isvoid`, `plus`, `sub`, `mul`, `divide`, `neg`,
`lt`, `leq`, `eq`, `comp`, `int_const`, `string_const`, `bool_const`,
`object` e `no_expr`. Fora da parte de expressões, a gramática foi mantida de
forma estrutural, com não-terminais separados para listas de classes, features,
formais, argumentos, expressões de bloco e ramos de `case`. Isso deixa a
gramática mais clara e evita resolver coisas que não são expressões com regras
de precedência.

A precedência de operadores foi usada apenas na parte de expressões. A gramática
declara precedência para atribuição, operadores unários, operadores
relacionais, operadores aritméticos e operadores de dispatch. A única produção
com sobrescrita explícita de precedência é a de `let`, usando `%prec ASSIGN`,
para dar à construção a interpretação correta para a direita. Assim, a
precedência foi usada como uma solução localizada para ambiguidades reais de
expressão, e não como um recurso genérico para esconder conflitos da gramática.
Na validação local, o arquivo `cool.output` gerado pelo Bison não apresentou
conflitos residuais do tipo `shift/reduce` ou `reduce/reduce`.

O scanner desenvolvido foi o mesmo utilizado na elaboração to TP02, ele foi usado nas execuções de validação por meio do executável local `lexer`,
gerado a partir de `cool.flex`. Esse scanner lê arquivos-fonte de Cool e emite
o fluxo textual de tokens consumido pelo parser. Isso aparece em `lextest.cc`,
que imprime o cabeçalho `#name "arquivo"` e depois escreve os tokens por meio
de `dump_cool_token(...)`. O driver do parser, em `parser-phase.cc`, lê esse
fluxo de tokens pela entrada padrão com suporte de `tokens-lex.cc`, mantendo o
modelo de integração `lexer | parser`. O repositório, portanto, contém e
valida uma pipeline léxica e sintática completa em execução local.

O tratamento de erros foi implementado com o pseudo-não-terminal `error` nos
principais pontos de recuperação da gramática. Há recuperação em definições de
classe, features de classe, bindings de `let` e expressões dentro de blocos. Em
`class_list`, classes malformadas são descartadas até `;`, permitindo retomar a
análise na classe seguinte. Em `feature_list`, features inválidas são
descartadas até o próximo `;`. Em `let_expression`, bindings malformados são
descartados até `,` ou `in`, permitindo continuar no próximo binding ou no
corpo do `let`. Em blocos, `block_expression_list` recupera em `;`, enquanto
`block_body` permite sincronização em `}`. A rotina padrão de erro do parser
foi mantida, e as ações semânticas não fazem chamadas manuais a ela.

Os principais testes estão em `good.cl` e `bad.cl`. O arquivo `good.cl`
exercita as construções válidas mais importantes da gramática, incluindo
herança, classes com e sem features, atributos com e sem inicialização,
métodos com diferentes aridades, atribuição, os três tipos de dispatch, `if`,
`while`, blocos, `let` com múltiplos bindings, `case`, `new`, `new SELF_TYPE`,
`isvoid`, `not`, `~`, expressões aritméticas, expressões relacionais e as
formas básicas de constantes. O arquivo `bad.cl` concentra vários erros
sintáticos recuperáveis em uma única entrada, cobrindo cabeçalhos de classe
malformados, atributos malformados, métodos malformados, bindings inválidos de
`let` e expressões inválidas em blocos, inclusive em cenários em que a análise
continua depois de um ponto de recuperação.

Dois arquivos menores foram incluídos como apoio didático para validação rápida.
O arquivo `expr_precedence_mul_parens_let_demo.cl` mostra exemplos curtos para
inspecionar precedência entre `+` e `*`, uso de parênteses e comportamento de
`let`. O arquivo `expr_precedence_dispatch_unary_assign_demo.cl` foi usado para
observar atribuição, negação unária, `not`, `isvoid`, dispatch estático e
dispatch dinâmico. Eles não substituem os testes principais, mas ajudam quando
o objetivo é verificar um ponto específico da gramática de forma rápida e com
uma AST mais fácil de ler.

A metodologia de testes foi dividida em duas partes. A primeira foi uma
validação mais ampla com `good.cl` e `bad.cl`. Em `good.cl`, a ideia foi
confirmar que a análise sintática aceitava corretamente um conjunto
representativo de construções válidas e produzia uma AST bem formada. Em
`bad.cl`, a ideia foi verificar que entradas inválidas produziam mensagens de
erro consistentes e, ao mesmo tempo, passavam pelos pontos de recuperação
implementados na gramática. A segunda parte foi uma validação mais rápida e
direta com os arquivos menores de apoio, usados para conferir precedência,
parênteses, `let`, operadores unários e formas de dispatch de um jeito mais
fácil de inspecionar.

A validação foi feita por compilação e execução diretas. O parser e o lexer
foram compilados com sucesso, entradas válidas produziram AST, entradas
inválidas produziram mensagens de erro com status de falha, e o modo de debug
do parser gerou o rastreamento esperado do Bison. Em ambiente Unix ou WSL, o
projeto pode ser exercitado com:

```
  make clean
  make
  ./lexer good.cl | ./parser
  ./lexer bad.cl | ./parser
  ./lexer good.cl | ./parser -p
```

No ambiente Windows usado na validação local, a sequência equivalente foi:
```
  mingw32-make clean
  mingw32-make
  lexer.exe good.cl | parser.exe
  lexer.exe bad.cl | parser.exe
  lexer.exe good.cl | parser.exe -p
```

No Windows, o runtime do MinGW/WinLibs pode precisar estar presente no `PATH`
antes da execução dos binários gerados.

De modo geral, a implementação é consistente pois as entradas válidas geram AST,
entradas inválidas falham de forma
clara, os principais pontos de recuperação estão implementados, as fases léxica
e sintática funcionam em conjunto por meio da interface esperada de fluxo de
tokens, a precedência se comporta corretamente no parsing de expressões, e o
processo de build produz os artefatos usuais do parser com alvos de limpeza
apropriados.