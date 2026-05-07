# 02 — JOINs e Subqueries

## 📖 Conceito

JOINs em Open SQL permitem cruzar tabelas diretamente no banco — muito mais eficiente do que carregar duas tabelas separadas e cruzar em memória com LOOP/READ.

Tipos disponíveis:
- `INNER JOIN` — só retorna registros que têm par nas duas tabelas
- `LEFT OUTER JOIN` — retorna todos da esquerda, com nulos na direita se não houver par
- Subqueries `EXISTS` / `NOT EXISTS` — filtragem baseada em existência

---

## 💻 Código

### INNER JOIN básico

```abap
REPORT z_decoded_db_02.

" Pedidos com dados do cliente (só pedidos com cliente cadastrado)
SELECT v~vbeln v~kunnr v~netwr v~waerk
       k~name1 k~land1
  FROM vbak AS v
  INNER JOIN kna1 AS k ON k~kunnr = v~kunnr
  INTO TABLE @DATA(lt_pedidos_cli)
  WHERE v~erdat >= @(sy-datum - 90)
    AND v~vbtyp = 'C'
  ORDER BY v~kunnr v~vbeln.

LOOP AT lt_pedidos_cli INTO DATA(ls).
  WRITE: / ls-vbeln, ls-kunnr, ls-name1, ls-netwr, ls-waerk.
ENDLOOP.
```

---

### LEFT OUTER JOIN — todos os clientes, com ou sem pedidos

```abap
SELECT k~kunnr k~name1
       v~vbeln v~netwr
  FROM kna1 AS k
  LEFT OUTER JOIN vbak AS v ON  v~kunnr = k~kunnr
                             AND v~erdat >= @(sy-datum - 30)
  INTO TABLE @DATA(lt_todos)
  WHERE k~ktokd = 'ZVAR'
  ORDER BY k~kunnr.

LOOP AT lt_todos INTO DATA(ls2).
  IF ls2-vbeln IS INITIAL.
    WRITE: / |{ ls2-kunnr } { ls2-name1 } — sem pedidos|.
  ELSE.
    WRITE: / |{ ls2-kunnr } { ls2-name1 } — Pedido: { ls2-vbeln } R$ { ls2-netwr }|.
  ENDIF.
ENDLOOP.
```

---

### JOIN com três tabelas — pedido + item + material

```abap
SELECT a~vbeln  a~kunnr  a~erdat
       p~posnr  p~matnr  p~kwmeng  p~vrkme
       m~maktx
  FROM vbak AS a
  INNER JOIN vbap AS p ON p~vbeln = a~vbeln
  INNER JOIN makt AS m ON  m~matnr = p~matnr
                       AND m~spras = @sy-langu
  INTO TABLE @DATA(lt_itens_desc)
  WHERE a~vbeln IN @so_vbeln
    AND p~pstyv = 'TAN'
  ORDER BY a~vbeln p~posnr.
```

---

### Subquery EXISTS — filtra por existência em outra tabela

```abap
" Clientes que TÊM pelo menos um pedido em aberto
SELECT kunnr name1
  FROM kna1
  INTO TABLE @DATA(lt_com_pedido)
  WHERE EXISTS (
    SELECT vbeln FROM vbak
    WHERE kunnr = kna1~kunnr
      AND gbsta = ' '    " status geral = em aberto
  ).

" Clientes que NÃO têm pedido nos últimos 6 meses
SELECT kunnr name1
  FROM kna1
  INTO TABLE @DATA(lt_inativos)
  WHERE NOT EXISTS (
    SELECT vbeln FROM vbak
    WHERE kunnr = kna1~kunnr
      AND erdat >= @(sy-datum - 180)
  )
  AND ktokd = 'ZVAR'.
```

---

### Aggregações — COUNT, SUM, MAX, MIN, AVG

```abap
" Totais por cliente
SELECT kunnr
       COUNT(*) AS qtd_pedidos
       SUM( netwr ) AS valor_total
       MAX( erdat ) AS ultimo_pedido
  FROM vbak
  INTO TABLE @DATA(lt_totais)
  WHERE vbtyp = 'C'
    AND erdat >= @(sy-datum - 365)
  GROUP BY kunnr
  HAVING SUM( netwr ) > 10000
  ORDER BY valor_total DESCENDING.

LOOP AT lt_totais INTO DATA(ls3).
  WRITE: / ls3-kunnr, ls3-qtd_pedidos, ls3-valor_total.
ENDLOOP.
```

---

## ⚠️ Pegadinhas

**1. LEFT JOIN com condição no WHERE filtra como INNER JOIN**
```abap
" ERRADO — o WHERE na tabela direita transforma em INNER JOIN implícito
SELECT k~kunnr k~name1 v~vbeln
  FROM kna1 AS k
  LEFT OUTER JOIN vbak AS v ON v~kunnr = k~kunnr
  WHERE v~vbtyp = 'C'   " ← filtra nulls, destrói o LEFT JOIN
  INTO TABLE @lt_result.

" CORRETO — coloca a condição da tabela direita no ON
SELECT k~kunnr k~name1 v~vbeln
  FROM kna1 AS k
  LEFT OUTER JOIN vbak AS v ON  v~kunnr = k~kunnr
                             AND v~vbtyp = 'C'
  INTO TABLE @lt_result.
```

**2. JOIN em tabelas buffered — pode retornar dados desatualizados**
```abap
" Algumas tabelas do SAP têm buffer ativo (T001, T001W etc.)
" JOIN nelas pode usar dados do buffer, não do banco real
" Para dados críticos: BYPASSING BUFFER
SELECT * FROM t001 BYPASSING BUFFER INTO TABLE @lt_t001.
```

---

## 🏋️ Exercício

Crie o programa `Z_DECODED_DB_02`:

1. Liste os 10 materiais mais vendidos nos últimos 90 dias:
   - `VBAP` (itens de pedido) → JOIN com `MAKT` (descrição) → JOIN com `VBAK` (pedido, filtrar por data)
   - Agrupar por material, somar `KWMENG` (quantidade)
   - Ordenar por quantidade decrescente, limitar a 10 registros (`UP TO 10 ROWS`)
2. Para cada material, imprima: código | descrição | quantidade total | unidade

---

⬅️ [01 — Open SQL](./01-open-sql.md) | ➡️ [03 — CDS Views](./03-cds-views.md)
