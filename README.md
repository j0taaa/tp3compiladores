README file for Programming Assignment 3 (C++ edition)
======================================================


Este projeto implementa a etapa de análise sintática da linguagem Cool em C++,
usando Bison e o pacote padrão de árvores da linguagem. A implementação
constrói a árvore sintática abstrata diretamente durante o parsing e preserva o
modelo clássico de integração em que um analisador léxico produz uma sequência
de tokens consumida pelo parser. A organização do repositório acompanha a
estrutura esperada para o trabalho, com a gramática em `cool.y`, o scanner em
`cool.flex`, os casos principais de teste em `good.cl` e `bad.cl`, e o script
`myparser` mantendo a execução no formato `lexer | parser`.

O parser constrói a AST oficial de Cool, com `program` como raiz para entradas
válidas. A gramática cobre programas com uma ou mais classes, classes com e sem
herança, listas vazias ou não vazias de features, atributos com e sem
inicialização, métodos com diferentes quantidades de parâmetros formais e as
formas de expressão centrais da linguagem, incluindo atribuição, dispatch
dinâmico e estático, dispatch implícito em `self`, condicionais, laços,
blocos, `let`, `case`, criação de objetos, operadores unários, operadores
aritméticos, operadores relacionais, expressões parentetizadas,
identificadores e constantes.

As ações semânticas em `cool.y` criam diretamente os nós padrão da árvore por
meio dos construtores oficiais, entre eles `program`, `class_`, `method`,
`attr`, `formal`, `branch`, `assign`, `dispatch`, `static_dispatch`, `cond`,
`loop`, `block`, `let`, `typcase`, `new_`, `isvoid`, `plus`, `sub`, `mul`,
`divide`, `neg`, `lt`, `leq`, `eq`, `comp`, `int_const`, `string_const`,
`bool_const`, `object` e `no_expr`. Fora da camada de expressões, a gramática
foi mantida estrutural, com não-terminais dedicados para listas de classes,
features, formais, argumentos, expressões de bloco e ramos de `case`. Isso
mantém a definição legível e evita resolver questões não relacionadas a
expressões por meio de precedência.

A precedência de operadores foi mantida estritamente no domínio das expressões.
A gramática declara precedência apenas para atribuição, operadores unários,
operadores relacionais, operadores aritméticos e operadores de dispatch. A
única sobrescrita de precedência em nível de produção é `%prec ASSIGN`, usada
na produção de `let` para dar à construção a interpretação convencional
estendida para a direita. Com isso, a precedência permanece como um recurso
local para ambiguidades reais de expressões, em vez de um mecanismo genérico
para suprimir conflitos estruturais da gramática. Na validação local, o arquivo
`cool.output` gerado pelo Bison não apresentou conflitos residuais do tipo
`shift/reduce` ou `reduce/reduce`.

O scanner utilizado nas execuções de validação foi o executável local `lexer`,
gerado a partir de `cool.flex`. Esse scanner lê arquivos-fonte de Cool e emite
o fluxo textual de tokens consumido pelo parser. Esse comportamento aparece em
`lextest.cc`, que imprime o cabeçalho `#name "arquivo"` e depois escreve os
tokens por meio de `dump_cool_token(...)`. O driver do parser, em
`parser-phase.cc`, lê esse fluxo de tokens pela entrada padrão com suporte de
`tokens-lex.cc`, preservando o modelo de integração `lexer | parser`. O
repositório, portanto, contém e valida uma pipeline léxica e sintática completa
em execução local.

O tratamento de erros foi implementado com o pseudo-não-terminal `error` nos
principais pontos de recuperação da gramática. Há recuperação em definições de
classe, features de classe, bindings de `let` e expressões dentro de blocos. Em
`class_list`, classes malformadas são descartadas até `;`, permitindo retomar a
análise na classe seguinte. Em `feature_list`, features inválidas são
descartadas até o próximo `;`. Em `let_expression`, bindings malformados são
descartados até `,` ou `in`, permitindo continuar no próximo binding ou no
corpo do `let`. Em blocos, `block_expression_list` recupera em `;`, enquanto
`block_body` permite sincronização em `}`. A rotina padrão de erro do parser
foi preservada, e as ações semânticas não fazem chamadas manuais a ela.

Os principais casos de validação estão concentrados em `good.cl` e `bad.cl`.
O arquivo `good.cl` exercita as construções válidas centrais da gramática,
incluindo herança, conjuntos vazios e não vazios de features, atributos com e
sem inicialização, métodos com diferentes aridades, atribuição, os três tipos
de dispatch, `if`, `while`, blocos, `let` com múltiplos bindings, `case`,
`new`, `new SELF_TYPE`, `isvoid`, `not`, `~`, expressões aritméticas,
expressões relacionais e as formas básicas de constantes. O arquivo `bad.cl`
concentra vários erros sintáticos recuperáveis em uma única entrada, cobrindo
cabeçalhos de classe malformados, atributos malformados, métodos malformados,
bindings inválidos de `let` e expressões inválidas em blocos, inclusive em
cenários em que a análise continua após um ponto de recuperação.

Dois arquivos adicionais foram incluídos como apoio didático para inspeção de
precedência e formato da árvore. O arquivo
`expr_precedence_mul_parens_let_demo.cl` contrasta expressões como
`1 + 2 * 3`, `(1 + 2) * 3` e um corpo de `let` que combina soma e
multiplicação. O arquivo
`expr_precedence_dispatch_unary_assign_demo.cl` destaca atribuição, negação
unária, `not`, `isvoid`, dispatch estático e dispatch dinâmico. Esses arquivos
não substituem os testes principais, mas são úteis para leitura manual da AST e
para verificação pontual da precedência.

A validação foi feita por compilação e execução diretas. O parser e o lexer
foram compilados com sucesso, entradas válidas produziram AST, entradas
inválidas produziram mensagens de erro com status de falha, e o modo de debug
do parser gerou o rastreamento esperado do Bison. Em ambiente Unix ou WSL, o
projeto pode ser exercitado com:

  make clean
  make
  ./lexer good.cl | ./parser
  ./lexer bad.cl | ./parser
  ./lexer good.cl | ./parser -p

No ambiente Windows usado na validação local, a sequência equivalente foi:

  mingw32-make clean
  mingw32-make
  lexer.exe good.cl | parser.exe
  lexer.exe bad.cl | parser.exe
  lexer.exe good.cl | parser.exe -p

No Windows, o runtime do MinGW/WinLibs pode precisar estar presente no `PATH`
antes da execução dos binários gerados.

Do ponto de vista de qualidade de software, a implementação é consistente com o
escopo do trabalho porque entradas válidas geram AST, entradas inválidas
falham de forma clara, os principais pontos de recuperação estão implementados,
as fases léxica e sintática funcionam em conjunto por meio da interface
esperada de fluxo de tokens, a precedência se comporta corretamente no parsing
de expressões, e o processo de build produz os artefatos usuais do parser com
alvos de limpeza apropriados. O código também contém comentários explicativos
nos pontos em que eles são mais úteis. Os arquivos de suporte e os esqueletos
originais já trazem uma base considerável de comentários, e os trechos
introduzidos ou esclarecidos neste trabalho foram anotados onde a intenção é
menos óbvia, especialmente em torno da precedência de expressões e da
ambiguidade de `let`.

Em conjunto, o projeto entrega uma etapa completa de análise sintática para
Cool, capaz de construir a AST esperada, tratar os principais erros sintáticos
de forma controlada, preservar o modelo de integração entre lexer e parser e
ser reproduzido e inspecionado por meio de execuções locais diretas.
