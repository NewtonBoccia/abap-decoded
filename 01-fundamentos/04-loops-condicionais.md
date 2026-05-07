# 04 — Loops e Condicionais

## 📖 Conceito

ABAP tem um conjunto de estruturas de controle que cobrem todos os cenários: condicionais simples, encadeadas, e três tipos de loop. A sintaxe é verbosa por design — código ABAP precisa ser legível até por consultores funcionais.

---

## 💻 Código

### Condicionais — IF / ELSEIF / ELSE

```abap
REPORT z_decoded_04.

DATA: lv_status TYPE c LENGTH 1 VALUE 'A',
      lv_valor  TYPE p DECIMALS 2 VALUE '5000.00'.

IF lv_status = 'A'.
  WRITE: / 'Pedido Aberto'.
ELSEIF lv_status = 'F'.
  WRITE: / 'Pedido Fechado'.
ELSEIF lv_status = 'C'.
  WRITE: / 'Pedido Cancelado'.
ELSE.
  WRITE: / 'Status desconhecido'.
ENDIF.

" Operadores de comparação
IF lv_valor > 1000 AND lv_valor < 10000.
  WRITE: / 'Valor médio'.
ENDIF.

IF lv_valor >= 5000 OR lv_status = 'F'.
  WRITE: / 'Condição atendida'.
ENDIF.

IF NOT lv_status = 'C'.
  WRITE: / 'Pedido não cancelado'.
ENDIF.
```

---

### CASE — para múltiplos valores do mesmo campo

```abap
DATA: lv_tipo_doc TYPE string VALUE 'NF'.

CASE lv_tipo_doc.
  WHEN 'NF'.
    WRITE: / 'Nota Fiscal'.
  WHEN 'NFS'.
    WRITE: / 'Nota de Serviço'.
  WHEN 'CT'.
    WRITE: / 'Conhecimento de Transporte'.
  WHEN OTHERS.
    WRITE: / |Tipo desconhecido: { lv_tipo_doc }|.
ENDCASE.
```

> `CASE` é mais limpo que vários `ELSEIF` quando você testa o mesmo campo. Use CASE para tipos, status, códigos — use IF para condições complexas.

---

### DO — loop contado

```abap
DATA: lv_i TYPE i.

" Loop simples com contador implícito (sy-index)
DO 5 TIMES.
  WRITE: / |Iteração { sy-index } de 5|.
ENDDO.

" Com saída antecipada
DO.
  lv_i = lv_i + 1.
  IF lv_i >= 3.
    EXIT.  " sai do loop
  ENDIF.
  WRITE: / |lv_i = { lv_i }|.
ENDDO.
```

---

### WHILE — loop condicional

```abap
DATA: lv_contador TYPE i VALUE 1,
      lv_soma     TYPE i VALUE 0.

WHILE lv_contador <= 10.
  lv_soma = lv_soma + lv_contador.
  lv_contador = lv_contador + 1.
ENDWHILE.

WRITE: / |Soma de 1 a 10 = { lv_soma }|.  " 55
```

---

### LOOP AT — percorrendo tabelas internas

```abap
TYPES: BEGIN OF ty_item,
         pos    TYPE i,
         mat    TYPE matnr,
         qtd    TYPE i,
         preco  TYPE p DECIMALS 2,
       END OF ty_item.

DATA: lt_itens TYPE TABLE OF ty_item,
      ls_item  TYPE ty_item,
      lv_total TYPE p DECIMALS 2.

" Popula a tabela
DO 4 TIMES.
  ls_item-pos   = sy-index.
  ls_item-mat   = |MAT-{ sy-index }|.
  ls_item-qtd   = sy-index * 2.
  ls_item-preco = sy-index * '25.50'.
  APPEND ls_item TO lt_itens.
ENDDO.

" Loop com acumulador
LOOP AT lt_itens INTO ls_item.
  lv_total = lv_total + ( ls_item-qtd * ls_item-preco ).
  WRITE: / |Pos { ls_item-pos }: { ls_item-mat } | Qtd: { ls_item-qtd } | Preço: { ls_item-preco }|.
ENDLOOP.

WRITE: / |─────────────────────────────|.
WRITE: / |Total: R$ { lv_total }|.
```

---

### CONTINUE e CHECK — pulando iterações

```abap
" CONTINUE — pula para a próxima iteração (equivalente ao 'continue' em outras linguagens)
LOOP AT lt_itens INTO ls_item.
  IF ls_item-qtd = 0.
    CONTINUE.  " pula itens sem quantidade
  ENDIF.
  WRITE: / ls_item-mat.
ENDLOOP.

" CHECK — atalho para IF ... CONTINUE ... ENDIF
LOOP AT lt_itens INTO ls_item.
  CHECK ls_item-qtd > 0.  " se falso, vai para próxima iteração
  WRITE: / ls_item-mat.
ENDLOOP.
```

---

### Loops aninhados e AT ... ENDAT (totalizadores)

```abap
TYPES: BEGIN OF ty_venda,
         regiao  TYPE string,
         produto TYPE string,
         valor   TYPE p DECIMALS 2,
       END OF ty_venda.

DATA: lt_vendas TYPE TABLE OF ty_venda,
      ls_venda  TYPE ty_venda,
      lv_total_regiao TYPE p DECIMALS 2.

" Populate
APPEND VALUE #( regiao = 'SUL' produto = 'A' valor = '100' ) TO lt_vendas.
APPEND VALUE #( regiao = 'SUL' produto = 'B' valor = '200' ) TO lt_vendas.
APPEND VALUE #( regiao = 'NORTE' produto = 'A' valor = '150' ) TO lt_vendas.

SORT lt_vendas BY regiao.

LOOP AT lt_vendas INTO ls_venda.
  AT NEW regiao.                        " quando muda a região
    lv_total_regiao = 0.
    WRITE: / |=== { ls_venda-regiao } ===|.
  ENDAT.

  WRITE: / |  { ls_venda-produto }: R$ { ls_venda-valor }|.
  lv_total_regiao = lv_total_regiao + ls_venda-valor.

  AT END OF regiao.                     " quando termina a região
    WRITE: / |  Total { ls_venda-regiao }: R$ { lv_total_regiao }|.
  ENDAT.
ENDLOOP.
```

---

## ⚠️ Pegadinhas

**1. `EXIT` dentro de LOOP sai do loop, não do programa**
```abap
LOOP AT lt_itens INTO ls_item.
  IF ls_item-qtd = 0.
    EXIT.  " sai do LOOP, não do programa
  ENDIF.
ENDLOOP.
" Execução continua aqui

" Para sair do programa: LEAVE PROGRAM. ou LEAVE TO SCREEN 0.
```

**2. `AT NEW` e `AT END OF` só funcionam dentro de LOOP AT**
```abap
" Esses blocos são específicos de LOOP AT tabela_interna
AT NEW campo.    " ERRO se usado fora de LOOP AT
ENDAT.
```

**3. WHILE sem condição de saída — loop infinito**
```abap
DATA: lv_x TYPE i.
WHILE lv_x < 10.
  " Esqueceu: lv_x = lv_x + 1.
  " LOOP INFINITO — o sistema vai travar (time limit exceeded)
ENDWHILE.
```

**4. CHECK fora de LOOP tem comportamento diferente**
```abap
" Dentro de LOOP: pula para próxima iteração
" Fora de LOOP (em FORM/METHOD): sai da rotina inteira — como EXIT de subrotina
FORM processar.
  CHECK lv_ativo = 'X'.  " se falso, sai da FORM
  " código aqui só executa se lv_ativo = 'X'
ENDFORM.
```

---

## 🏋️ Exercício

Crie o programa `Z_DECODED_04`:

1. Crie uma tabela interna de pedidos com campos: `numero`, `cliente`, `valor`, `status` ('A', 'F', 'C')
2. Popule com 6 pedidos de clientes e status variados
3. Use um `LOOP` para calcular:
   - Quantidade de pedidos abertos, fechados e cancelados
   - Valor total dos pedidos abertos
4. Imprima o resultado usando `CASE` para traduzir os status para texto
5. **Desafio:** Ordene por cliente e use `AT NEW cliente` para imprimir um subtotal por cliente

---

⬅️ [03 — Estruturas e Tabelas Internas](./03-estruturas-tabelas-internas.md) | ➡️ [Módulo 02 — Modularização](../02-modularizacao/README.md)
