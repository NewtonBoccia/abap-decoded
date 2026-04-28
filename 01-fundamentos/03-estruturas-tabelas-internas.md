# 03 — Estruturas e Tabelas Internas

## 📖 Conceito

Se você aprender **uma** coisa em ABAP, que seja tabelas internas.

Tabela interna é uma variável que funciona como uma tabela temporária **em memória** — sem banco de dados, sem SELECT, sem custo de I/O. Você carrega dados, processa, transforma e descarta. É o coração de qualquer programa ABAP real.

Antes disso, precisamos entender **estruturas** — porque tabela interna é basicamente uma coleção de estruturas.

---

## 💻 Código

### Parte 1 — Estruturas (TYPES e DATA)

Uma estrutura é um agrupamento de campos relacionados — equivalente a uma `struct` em C ou uma classe só com atributos.

```abap
REPORT z_decoded_03.

"------------------------------------------------------------
" Definindo um tipo estruturado (blueprint)
"------------------------------------------------------------
TYPES: BEGIN OF ty_funcionario,
         matricula TYPE n LENGTH 6,
         nome      TYPE string,
         cargo     TYPE string,
         salario   TYPE p LENGTH 8 DECIMALS 2,
       END OF ty_funcionario.

"------------------------------------------------------------
" Declarando uma variável do tipo estrutura
"------------------------------------------------------------
DATA: ls_func TYPE ty_funcionario.  " ls_ = local structure

"------------------------------------------------------------
" Preenchendo campos da estrutura
"------------------------------------------------------------
ls_func-matricula = '001234'.
ls_func-nome      = 'Newton Boccia'.
ls_func-cargo     = 'EDI Specialist'.
ls_func-salario   = 12500.00.

WRITE: / 'Matricula:', ls_func-matricula,
       / 'Nome:     ', ls_func-nome,
       / 'Cargo:    ', ls_func-cargo,
       / 'Salario:  ', ls_func-salario.
```

---

### Parte 2 — Tabelas Internas

Três tipos que você vai encontrar no dia a dia:

```abap
"------------------------------------------------------------
" 1. STANDARD TABLE — a mais comum, aceita duplicatas
"    Acesso: por índice ou LOOP
"------------------------------------------------------------
DATA: lt_funcionarios TYPE TABLE OF ty_funcionario.

"------------------------------------------------------------
" 2. SORTED TABLE — mantém ordenação automática pela chave
"    Mais rápida para leituras por chave
"------------------------------------------------------------
DATA: lt_sorted TYPE SORTED TABLE OF ty_funcionario
                WITH UNIQUE KEY matricula.

"------------------------------------------------------------
" 3. HASHED TABLE — acesso ultra-rápido por chave única
"    Use quando vai fazer muitas leituras por chave específica
"------------------------------------------------------------
DATA: lt_hashed TYPE HASHED TABLE OF ty_funcionario
                WITH UNIQUE KEY matricula.
```

> **Regra prática:** use `STANDARD TABLE` por padrão. Migre para `SORTED` ou `HASHED` só quando tiver problema de performance comprovado.

---

### Parte 3 — Operações Essenciais

```abap
REPORT z_decoded_03_operacoes.

TYPES: BEGIN OF ty_pedido,
         numero   TYPE n LENGTH 10,
         cliente  TYPE string,
         valor    TYPE p LENGTH 10 DECIMALS 2,
         status   TYPE c LENGTH 1,  " A=Aberto, F=Fechado, C=Cancelado
       END OF ty_pedido.

DATA: lt_pedidos TYPE TABLE OF ty_pedido,
      ls_pedido  TYPE ty_pedido.

"------------------------------------------------------------
" APPEND — adiciona linha ao final
"------------------------------------------------------------
ls_pedido-numero  = '0000000001'.
ls_pedido-cliente = 'Cliente Alpha'.
ls_pedido-valor   = 1500.00.
ls_pedido-status  = 'A'.
APPEND ls_pedido TO lt_pedidos.

ls_pedido-numero  = '0000000002'.
ls_pedido-cliente = 'Cliente Beta'.
ls_pedido-valor   = 3200.50.
ls_pedido-status  = 'F'.
APPEND ls_pedido TO lt_pedidos.

ls_pedido-numero  = '0000000003'.
ls_pedido-cliente = 'Cliente Gamma'.
ls_pedido-valor   = 800.00.
ls_pedido-status  = 'C'.
APPEND ls_pedido TO lt_pedidos.

"------------------------------------------------------------
" LOOP AT — percorre todas as linhas
"------------------------------------------------------------
WRITE: / '=== Todos os pedidos ==='.
LOOP AT lt_pedidos INTO ls_pedido.
  WRITE: / ls_pedido-numero, ls_pedido-cliente, ls_pedido-valor.
ENDLOOP.

"------------------------------------------------------------
" LOOP AT WHERE — filtra durante o loop (evite em tabelas grandes)
"------------------------------------------------------------
WRITE: / '=== Apenas Abertos ==='.
LOOP AT lt_pedidos INTO ls_pedido WHERE status = 'A'.
  WRITE: / ls_pedido-numero, ls_pedido-cliente.
ENDLOOP.

"------------------------------------------------------------
" READ TABLE — busca uma linha específica
"------------------------------------------------------------
READ TABLE lt_pedidos INTO ls_pedido
  WITH KEY numero = '0000000002'.

IF sy-subrc = 0.  " sy-subrc = 0 significa que encontrou
  WRITE: / 'Pedido encontrado:', ls_pedido-cliente.
ELSE.
  WRITE: / 'Pedido nao encontrado'.
ENDIF.

"------------------------------------------------------------
" DESCRIBE TABLE — informações sobre a tabela
"------------------------------------------------------------
DATA: lv_linhas TYPE i.
DESCRIBE TABLE lt_pedidos LINES lv_linhas.
WRITE: / 'Total de pedidos:', lv_linhas.

"------------------------------------------------------------
" DELETE — remove linhas
"------------------------------------------------------------
DELETE lt_pedidos WHERE status = 'C'.

"------------------------------------------------------------
" CLEAR vs FREE — diferença importante!
"------------------------------------------------------------
CLEAR ls_pedido.      " Limpa conteúdo da estrutura, mantém memória
CLEAR lt_pedidos.     " Limpa conteúdo da tabela, mantém memória alocada
FREE lt_pedidos.      " Limpa E libera memória — use no fim do processamento
```

---

### Parte 4 — Field Symbols (o nível acima)

Field symbols são como ponteiros — em vez de copiar a linha pro `ls_`, você trabalha **diretamente** na memória da tabela. Mais rápido, menos memória.

```abap
"------------------------------------------------------------
" Com ls_ (cópia) — jeito comum, funciona mas faz cópia
"------------------------------------------------------------
LOOP AT lt_pedidos INTO ls_pedido.
  IF ls_pedido-status = 'A'.
    ls_pedido-valor = ls_pedido-valor * '1.1'.  " 10% de acréscimo
    MODIFY lt_pedidos FROM ls_pedido.           " precisa gravar de volta!
  ENDIF.
ENDLOOP.

"------------------------------------------------------------
" Com Field Symbol (referência direta) — mais eficiente
"------------------------------------------------------------
FIELD-SYMBOLS: <fs_pedido> TYPE ty_pedido.

LOOP AT lt_pedidos ASSIGNING <fs_pedido>.
  IF <fs_pedido>-status = 'A'.
    <fs_pedido>-valor = <fs_pedido>-valor * '1.1'.  " altera direto na tabela!
  ENDIF.
ENDLOOP.
" Não precisa de MODIFY — a alteração já está na tabela
```

> **Quando usar field symbols:** sempre que for modificar dados dentro de um LOOP. Para leitura simples, `INTO ls_` é suficiente.

---

### Parte 5 — Trabalhando com Tabelas do Dicionário (LIKE)

Na prática você raramente define seus próprios `TYPES` do zero — você referencia estruturas que já existem no SAP:

```abap
"------------------------------------------------------------
" LIKE LINE OF — estrutura baseada em tabela interna existente
"------------------------------------------------------------
DATA: lt_mara TYPE TABLE OF mara,    " tabela de materiais do SAP
      ls_mara TYPE mara.             " ou: LIKE LINE OF lt_mara

"------------------------------------------------------------
" Copiando tabelas
"------------------------------------------------------------
DATA: lt_copia TYPE TABLE OF ty_pedido.

lt_copia = lt_pedidos.               " cópia direta, simples assim

"------------------------------------------------------------
" APPEND LINES OF — concatenar tabelas
"------------------------------------------------------------
APPEND LINES OF lt_copia TO lt_pedidos.

"------------------------------------------------------------
" DELETE ADJACENT DUPLICATES — remove duplicatas (tabela deve estar ordenada)
"------------------------------------------------------------
SORT lt_pedidos BY numero.
DELETE ADJACENT DUPLICATES FROM lt_pedidos COMPARING numero.
```

---

## ⚠️ Pegadinhas

**1. Esquecer de checar `sy-subrc` depois do READ TABLE**
```abap
READ TABLE lt_pedidos INTO ls_pedido WITH KEY numero = '9999'.
" Se não checar sy-subrc e tentar usar ls_pedido, vai usar lixo de memória
WRITE: / ls_pedido-cliente.  " ← PERIGOSO se sy-subrc <> 0
```

**2. MODIFY dentro do LOOP sem field symbol**
```abap
" Isso NÃO funciona como esperado:
LOOP AT lt_pedidos INTO ls_pedido.
  ls_pedido-valor = 0.
  " Esqueceu o MODIFY! A tabela original não foi alterada.
ENDLOOP.

" Correto:
LOOP AT lt_pedidos INTO ls_pedido.
  ls_pedido-valor = 0.
  MODIFY lt_pedidos FROM ls_pedido.  " ← obrigatório
ENDLOOP.
" Ou melhor: use ASSIGNING <fs> e esqueça o MODIFY
```

**3. LOOP AT WHERE em tabelas grandes**
```abap
" Isso faz full scan na tabela inteira:
LOOP AT lt_pedidos INTO ls_pedido WHERE status = 'A'.
" Em 10 linhas: ok. Em 500.000 linhas: problema.
" Prefira READ TABLE com chave ou tabela SORTED/HASHED para buscas frequentes.
```

**4. Não limpar a work area entre APPENDs**
```abap
" BUG clássico: campos do registro anterior "contaminam" o próximo
LOOP AT lt_origem INTO ls_origem.
  " ls_destino ainda tem dados da iteração anterior!
  ls_destino-campo_a = ls_origem-campo_a.
  APPEND ls_destino TO lt_destino.
ENDLOOP.

" Correto: limpa antes de preencher
LOOP AT lt_origem INTO ls_origem.
  CLEAR ls_destino.                    " ← sempre!
  ls_destino-campo_a = ls_origem-campo_a.
  APPEND ls_destino TO lt_destino.
ENDLOOP.
```

---

## 🏋️ Exercício

Crie o programa `Z_DECODED_03`:

1. Defina uma estrutura `ty_produto` com: `codigo` (N 8), `descricao` (STRING), `preco` (P 2 decimais), `estoque` (I)

2. Crie uma tabela interna `lt_produtos` e adicione **5 produtos** com APPEND

3. Usando LOOP, imprima apenas os produtos com **estoque > 0**

4. Usando READ TABLE, busque um produto pelo código e imprima seu preço

5. Usando LOOP com field symbol, aplique **15% de desconto** em todos os produtos com estoque > 10

6. Ao final, imprima quantos produtos existem na tabela

**Desafio extra:** ordene a tabela por preço decrescente antes de imprimir (`SORT lt_produtos BY preco DESCENDING.`)

---

⬅️ [02 - Tipos de Dados](./02-tipos-de-dados.md) | ➡️ [04 - Loops e Condicionais](./04-loops-condicionais.md)
