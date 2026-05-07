# 02 — ALV com Eventos e Toolbar

## 📖 Conceito

Para double-click, hotspot, botões customizados na toolbar e edição de células, você precisa do `CL_GUI_ALV_GRID` com eventos registrados. É mais verboso que o `CL_SALV_TABLE`, mas dá controle total sobre a interação do usuário.

---

## 💻 Código

### CL_SALV_TABLE com double-click (forma mais simples)

```abap
REPORT z_decoded_alv_eventos.

CLASS lcl_events DEFINITION.
  PUBLIC SECTION.
    METHODS on_double_click
      FOR EVENT double_click OF cl_salv_events_table
      IMPORTING row column.
ENDCLASS.

CLASS lcl_events IMPLEMENTATION.
  METHOD on_double_click.
    " row = número da linha clicada
    " column = nome da coluna clicada
    READ TABLE gt_dados INTO DATA(ls_pedido) INDEX row.
    IF sy-subrc = 0.
      " Navega para VA03 com o número do pedido
      SET PARAMETER ID 'AUN' FIELD ls_pedido-vbeln.
      CALL TRANSACTION 'VA03' AND SKIP FIRST SCREEN.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

DATA: gt_dados  TYPE TABLE OF ty_pedido,  " tabela global
      go_alv    TYPE REF TO cl_salv_table,
      go_events TYPE REF TO lcl_events.

START-OF-SELECTION.

  " ... busca dados em gt_dados

  cl_salv_table=>factory( IMPORTING r_salv_table = go_alv
                          CHANGING  t_table      = gt_dados ).

  " Registra o handler de eventos
  go_events = NEW lcl_events( ).
  SET HANDLER go_events->on_double_click
    FOR go_alv->get_event( ).

  go_alv->display( ).
```

---

### Botão customizado na toolbar (CL_SALV_TABLE)

```abap
CLASS lcl_events DEFINITION.
  PUBLIC SECTION.
    METHODS on_user_command
      FOR EVENT added_function OF cl_salv_events
      IMPORTING e_salv_function.
ENDCLASS.

CLASS lcl_events IMPLEMENTATION.
  METHOD on_user_command.
    CASE e_salv_function.
      WHEN 'REPROCESSAR'.
        " Lógica de reprocessamento
        PERFORM reprocessar_selecionados.
      WHEN 'EXPORTAR_PDF'.
        PERFORM exportar_pdf.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.

" Adiciona botão à toolbar
DATA: lo_funcs TYPE REF TO cl_salv_functions_list.
lo_funcs = go_alv->get_functions( ).
lo_funcs->set_all( abap_true ).  " ativa botões padrão (sort, filter, export)

" Adiciona botão customizado
lo_funcs->add_function(
  name     = 'REPROCESSAR'
  icon     = '@0Y@'             " ícone de refresh (use SE11 → ICON para ver todos)
  text     = 'Reprocessar'
  tooltip  = 'Reprocessar IDocs selecionados'
  position = if_salv_c_function_position=>right_of_salvo ).
```

---

### Hotspot — campo clicável (como link)

```abap
" Configura uma coluna como hotspot
TRY.
  CAST cl_salv_column_table(
    lo_cols->get_column( 'VBELN' )
  )->set_cell_type( if_salv_c_cell_type=>hotspot ).
CATCH cx_salv_not_found.
ENDTRY.

" No handler de link_click:
CLASS lcl_events DEFINITION.
  PUBLIC SECTION.
    METHODS on_link_click
      FOR EVENT link_click OF cl_salv_events_table
      IMPORTING row column.
ENDCLASS.

CLASS lcl_events IMPLEMENTATION.
  METHOD on_link_click.
    READ TABLE gt_dados INTO DATA(ls) INDEX row.
    IF sy-subrc = 0 AND column = 'VBELN'.
      SET PARAMETER ID 'AUN' FIELD ls-vbeln.
      CALL TRANSACTION 'VA03' AND SKIP FIRST SCREEN.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
```

---

## ⚠️ Pegadinhas

**1. Tabela de dados precisa ser global para o handler acessar**
```abap
" O handler on_double_click precisa acessar a tabela de dados
" para saber qual linha foi clicada. Se a tabela for LOCAL ao
" START-OF-SELECTION, o handler não consegue acessar.
" Use variável global (gt_) ou atributo de classe.
```

**2. SET HANDLER precisa ser chamado ANTES do display**
```abap
" Registre todos os handlers antes de go_alv->display()
" Após o display, o ALV está no controle e não aceita novos registros
```

---

## 🏋️ Exercício

Evolua o relatório `Z_DECODED_ALV_PEDIDOS` (aula anterior):

1. Adicione double-click na coluna de número do pedido para navegar ao VA03
2. Adicione um botão "Exportar PDF" na toolbar (pode simular com MESSAGE)
3. Adicione uma coluna de checkbox para seleção múltipla
4. **Desafio:** crie um botão "Reprocessar Selecionados" que chama o reprocessamento BAPI para os pedidos marcados

---

⬅️ [01 — ALV Grid](./01-alv-grid.md) | ➡️ [Módulo 08 — Smartforms](../08-smartforms-adobe/README.md)
