# 01 — ALV Grid com CL_SALV_TABLE

## 📖 Conceito

`CL_SALV_TABLE` é a forma mais moderna e simples de criar um ALV. Com poucas linhas você tem ordenação, filtros, agrupamento e export Excel automáticos. Para customizações mais avançadas (toolbar, eventos de clique, edição), use `CL_GUI_ALV_GRID` (próxima aula).

---

## 💻 Código

### ALV mínimo — 10 linhas de código

```abap
REPORT z_decoded_alv_01.

TYPES: BEGIN OF ty_pedido,
         vbeln TYPE vbeln,
         kunnr TYPE kunnr,
         name1 TYPE name1,
         netwr TYPE netwr,
         waerk TYPE waerk,
         erdat TYPE erdat,
       END OF ty_pedido.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME.
  SELECT-OPTIONS: so_kunnr FOR ( '' ) NO INTERVALS.
SELECTION-SCREEN END OF BLOCK b1.

START-OF-SELECTION.

  SELECT v~vbeln v~kunnr k~name1 v~netwr v~waerk v~erdat
    FROM vbak AS v
    INNER JOIN kna1 AS k ON k~kunnr = v~kunnr
    INTO TABLE @DATA(lt_dados)
    WHERE v~kunnr IN @so_kunnr
      AND v~vbtyp = 'C'
    ORDER BY v~erdat DESCENDING.

  " ALV em 3 linhas
  DATA: lo_alv TYPE REF TO cl_salv_table.
  cl_salv_table=>factory( IMPORTING r_salv_table = lo_alv
                          CHANGING  t_table      = lt_dados ).
  lo_alv->display( ).
```

---

### Configurando colunas

```abap
REPORT z_decoded_alv_02.

" ... [seleção e busca igual ao anterior]

DATA: lo_alv  TYPE REF TO cl_salv_table,
      lo_cols TYPE REF TO cl_salv_columns_table,
      lo_col  TYPE REF TO cl_salv_column_table.

cl_salv_table=>factory( IMPORTING r_salv_table = lo_alv
                        CHANGING  t_table      = lt_dados ).

lo_cols = lo_alv->get_columns( ).
lo_cols->set_optimize( abap_true ).  " auto-largura

" Configurar coluna específica
TRY.
  lo_col = CAST cl_salv_column_table( lo_cols->get_column( 'NETWR' ) ).
  lo_col->set_long_text( 'Valor Líquido' ).
  lo_col->set_medium_text( 'Valor' ).
  lo_col->set_short_text( 'Vlr' ).
  lo_col->set_currency_column( 'WAERK' ).  " vincula à moeda
CATCH cx_salv_not_found.
  " coluna não existe — ignora
ENDTRY.

" Ocultar coluna
TRY.
  lo_cols->get_column( 'WAERK' )->set_visible( abap_false ).
CATCH cx_salv_not_found.
ENDTRY.

lo_alv->display( ).
```

---

### Totalizadores, ordenação e semáforos

```abap
DATA: lo_alv      TYPE REF TO cl_salv_table,
      lo_aggs     TYPE REF TO cl_salv_aggregations,
      lo_sorts    TYPE REF TO cl_salv_sorts,
      lo_settings TYPE REF TO cl_salv_display_settings.

cl_salv_table=>factory( IMPORTING r_salv_table = lo_alv
                        CHANGING  t_table      = lt_dados ).

" Totalizador na coluna de valor
lo_aggs = lo_alv->get_aggregations( ).
TRY.
  lo_aggs->add_aggregation(
    columnname  = 'NETWR'
    aggregation = if_salv_c_aggregation=>total ).
CATCH cx_salv_not_found cx_salv_existing cx_salv_data_error.
ENDTRY.

" Ordenação padrão
lo_sorts = lo_alv->get_sorts( ).
TRY.
  lo_sorts->add_sort( columnname = 'ERDAT' sortorder = if_salv_c_sort_order=>descending ).
CATCH cx_salv_not_found cx_salv_existing cx_salv_data_error.
ENDTRY.

" Título do ALV
lo_settings = lo_alv->get_display_settings( ).
lo_settings->set_list_header( 'Pedidos de Venda' ).
lo_settings->set_striped_pattern( abap_true ).  " linhas alternadas

lo_alv->display( ).
```

---

### Adicionando semáforo (traffic light)

```abap
" Adicione um campo de semáforo na sua estrutura
TYPES: BEGIN OF ty_pedido_alv,
         vbeln  TYPE vbeln,
         netwr  TYPE netwr,
         status_icon TYPE salv_t_int4_color,  " 1=verde, 2=amarelo, 3=vermelho
       END OF ty_pedido_alv.

" Preenche o ícone baseado no valor
LOOP AT lt_dados ASSIGNING FIELD-SYMBOL(<ls>).
  IF <ls>-netwr > 10000.
    <ls>-status_icon = 1.   " verde — alto valor
  ELSEIF <ls>-netwr > 1000.
    <ls>-status_icon = 2.   " amarelo — médio
  ELSE.
    <ls>-status_icon = 3.   " vermelho — baixo
  ENDIF.
ENDLOOP.

" Configura a coluna como semáforo
TRY.
  lo_cols->get_column( 'STATUS_ICON' )->set_long_text( 'Status' ).
  CAST cl_salv_column_table( lo_cols->get_column( 'STATUS_ICON' ) )->set_icon( abap_true ).
CATCH cx_salv_not_found.
ENDTRY.
```

---

## ⚠️ Pegadinhas

**1. CL_SALV_TABLE não suporta edição — use CL_GUI_ALV_GRID para isso**
```abap
" Se precisar que o usuário edite células no ALV: CL_GUI_ALV_GRID
" CL_SALV_TABLE é read-only — ótimo para relatórios, não para manutenção
```

**2. set_currency_column precisa que a coluna de moeda exista na tabela**
```abap
" Se NETWR tem moeda WAERK, o campo WAERK precisa estar na tabela interna
" Mesmo que você não queira exibir WAERK, ele precisa estar lá (pode ocultar)
```

---

## 🏋️ Exercício

Crie o relatório `Z_DECODED_ALV_PEDIDOS`:

1. Tela de seleção com filtro por cliente e intervalo de datas
2. Busque pedidos de venda (VBAK + VBAP + KNA1) com JOIN
3. Exiba no ALV com:
   - Coluna de semáforo (verde = entregue, amarelo = em processo, vermelho = pendente)
   - Totalização por valor
   - Ordenação padrão por data decrescente
   - Colunas com rótulos em português
4. O ALV deve funcionar mesmo sem nenhum filtro (com aviso de "muitos registros")

---

⬅️ [README](./README.md) | ➡️ [02 — ALV com Eventos](./02-alv-eventos.md)
