# 01 — Open SQL Essencial

## 📖 Conceito

Open SQL é a camada de acesso a banco de dados do ABAP. Traduz automaticamente para o SQL nativo do banco de dados subjacente. As regras de ouro:

1. **Selecione só o que precisa** — `SELECT *` em tabelas grandes mata a performance
2. **Use WHERE rigoroso** — nunca traga tudo e filtre em ABAP
3. **Prefira SELECT INTO TABLE** a loops com SELECT SINGLE
4. **Tabelas do SAP** — sempre prefixo de cliente (`Z`, `Y`) para customizações

---

## 💻 Código

### SELECT básico

```abap
REPORT z_decoded_db_01.

DATA: lt_kna1 TYPE TABLE OF kna1,
      ls_kna1 TYPE kna1.

" SELECT INTO TABLE — mais eficiente (busca em batch)
SELECT kunnr name1 land1 ktokd
  FROM kna1
  INTO TABLE @DATA(lt_clientes)
  WHERE land1 = 'BR'
    AND ktokd IN ('ZVAR', 'ZIND')
  ORDER BY kunnr.

WRITE: / |Clientes encontrados: { lines( lt_clientes ) }|.

LOOP AT lt_clientes INTO DATA(ls_cli).
  WRITE: / ls_cli-kunnr, ls_cli-name1.
ENDLOOP.
```

---

### SELECT SINGLE — busca um registro específico

```abap
DATA: ls_mara TYPE mara.

SELECT SINGLE matnr maktx mtart meins
  FROM mara
  INTO @DATA(ls_material)
  WHERE matnr = '000000000000000001'.

IF sy-subrc = 0.
  WRITE: / |Material: { ls_material-matnr } — { ls_material-maktx }|.
ELSE.
  WRITE: / 'Material não encontrado.'.
ENDIF.
```

---

### INSERT, UPDATE, DELETE, MODIFY

```abap
" INSERT — insere nova linha (erro se já existe)
DATA: ls_zminha TYPE zminha_tabela.
ls_zminha-id     = '001'.
ls_zminha-status = 'A'.
ls_zminha-data   = sy-datum.

INSERT zminha_tabela FROM ls_zminha.
IF sy-subrc <> 0.
  WRITE: / 'Registro já existe — use UPDATE ou MODIFY'.
ENDIF.

" UPDATE — atualiza linha existente (erro se não existe)
UPDATE zminha_tabela
  SET status = 'F'
      data   = sy-datum
  WHERE id = '001'.

" MODIFY — insert se não existe, update se existe (upsert)
MODIFY zminha_tabela FROM ls_zminha.

" DELETE
DELETE FROM zminha_tabela WHERE status = 'C' AND data < @(sy-datum - 30).

" DELETE via work area
DELETE zminha_tabela FROM ls_zminha.  " usa a chave da work area
```

---

### INSERT / UPDATE em batch (tabela interna)

```abap
DATA: lt_inserts TYPE TABLE OF zminha_tabela.

" Preenche a tabela...
APPEND VALUE #( id = '002' status = 'A' data = sy-datum ) TO lt_inserts.
APPEND VALUE #( id = '003' status = 'A' data = sy-datum ) TO lt_inserts.

" Grava todos de uma vez — muito mais eficiente que loop com INSERT
INSERT zminha_tabela FROM TABLE lt_inserts.
" ou:
MODIFY zminha_tabela FROM TABLE lt_inserts.
```

---

### FOR ALL ENTRIES — busca baseada em tabela interna

```abap
" Situação: tenho lt_pedidos (VBAK) e quero buscar os itens (VBAP)

DATA: lt_vbak TYPE TABLE OF vbak.

SELECT vbeln erdat kunnr
  FROM vbak
  INTO TABLE @lt_vbak
  WHERE erdat >= @(sy-datum - 30).

IF lt_vbak IS NOT INITIAL.  " ← CRÍTICO: sempre verificar antes do FOR ALL ENTRIES
  SELECT vbeln posnr matnr kwmeng vrkme
    FROM vbap
    INTO TABLE @DATA(lt_vbap)
    FOR ALL ENTRIES IN @lt_vbak
    WHERE vbeln = @lt_vbak-vbeln.
ENDIF.
```

> **Regra de ouro:** sempre verifique `IF tabela_driver IS NOT INITIAL` antes de um `FOR ALL ENTRIES`. Se a tabela estiver vazia, o SAP traz **todos** os registros da tabela destino.

---

### Transações de banco de dados

```abap
" Todas as operações DML são transacionais — só são efetivadas com COMMIT
INSERT zminha_tabela FROM ls_registro.
UPDATE zminha_tabela SET status = 'P' WHERE id = ls_registro-id.

COMMIT WORK.      " efetiva as mudanças
" ROLLBACK WORK.  " desfaz tudo desde o último COMMIT
```

---

## ⚠️ Pegadinhas

**1. `SELECT *` em tabelas grandes**
```abap
" NUNCA faça isso em produção:
SELECT * FROM vbap INTO TABLE lt_vbap.
" VBAP pode ter milhões de linhas — dump de memória garantido

" Sempre especifique campos e use WHERE:
SELECT vbeln posnr matnr FROM vbap INTO TABLE @lt_vbap
  WHERE vbeln IN @so_vbeln AND pstyv = 'TAN'.
```

**2. FOR ALL ENTRIES com tabela vazia**
```abap
" Se lt_driver estiver vazia, isso traz TODO o conteúdo de vbap:
SELECT * FROM vbap INTO TABLE @lt_vbap
  FOR ALL ENTRIES IN @lt_driver  " lt_driver vazia = sem filtro = full table scan
  WHERE vbeln = @lt_driver-vbeln.
" Sempre: IF lt_driver IS NOT INITIAL.
```

**3. UPDATE sem WHERE — atualiza tudo**
```abap
UPDATE zminha_tabela SET status = 'X'.
" SEM WHERE → atualiza TODOS os registros da tabela
" Sempre revise o WHERE antes de executar DML sem work area
```

---

## 🏋️ Exercício

Crie o programa `Z_DECODED_DB_01`:

1. Tela de seleção com `SELECT-OPTIONS` para número de cliente (`KUNNR`) e data de criação
2. Busque os clientes da `KNA1` com os filtros
3. Se encontrar clientes, busque os pedidos da `VBAK` usando `FOR ALL ENTRIES`
4. Imprima: cliente | nome | quantidade de pedidos | valor total dos pedidos
5. Use `COMMIT WORK` após gravar um registro de log em uma tabela Z (pode simular com tabela interna)

---

⬅️ [README do módulo](./README.md) | ➡️ [02 — JOINs e Subqueries](./02-joins-subqueries.md)
