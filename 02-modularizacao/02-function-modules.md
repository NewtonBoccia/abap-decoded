# 02 — Function Modules

## 📖 Conceito

Function Modules (FMs) são o padrão de reutilização de código em ABAP há décadas. Diferente das FORMs, eles:

- Vivem em **Function Groups** (bibliotecas reutilizáveis entre programas)
- Têm **interface formal**: IMPORTING, EXPORTING, CHANGING, TABLES, EXCEPTIONS
- Podem ser chamados **remotamente** via RFC (Remote Function Call)
- São **testáveis** diretamente pela transação SE37

Você vai chamar FMs o tempo todo — para validar materiais, clientes, ler dados do SAP, gerar PDFs, enviar e-mails. Criar os seus próprios é menos comum, mas essencial para módulos reutilizáveis.

**Transação principal:** `SE37` (Function Builder)

---

## 💻 Código

### Chamando um Function Module existente

```abap
REPORT z_decoded_fm_01.

" Exemplo: CONVERSION_EXIT_ALPHA_INPUT — remove zeros à esquerda de códigos
DATA: lv_matnr_raw    TYPE string VALUE 'MAT-001',
      lv_matnr_intern TYPE matnr.

CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
  EXPORTING
    input  = lv_matnr_raw
  IMPORTING
    output = lv_matnr_intern.

WRITE: / |Input:  { lv_matnr_raw }|,
       / |Output: { lv_matnr_intern }|.
```

---

### Tratando exceções de Function Module

```abap
DATA: lv_plant   TYPE werks_d VALUE '1000',
      ls_t001w   TYPE t001w.

CALL FUNCTION 'PLANT_GET_DATA'
  EXPORTING
    plant           = lv_plant
  IMPORTING
    plant_data      = ls_t001w
  EXCEPTIONS
    plant_not_found = 1
    OTHERS          = 2.

CASE sy-subrc.
  WHEN 0.
    WRITE: / |Planta: { ls_t001w-name1 }|.
  WHEN 1.
    WRITE: / |Planta { lv_plant } não encontrada.|.
  WHEN OTHERS.
    WRITE: / |Erro inesperado ao buscar planta. SY-SUBRC: { sy-subrc }|.
ENDCASE.
```

---

### Function Module com TABLES (tabelas internas)

```abap
DATA: lt_return TYPE TABLE OF bapiret2,
      ls_return TYPE bapiret2,
      lv_matnr  TYPE matnr VALUE '000000000000000001'.

" BAPI para ler dados de material
CALL FUNCTION 'BAPI_MATERIAL_GET_DETAIL'
  EXPORTING
    material         = lv_matnr
    plant            = '1000'
  TABLES
    return           = lt_return.

" Verificar se houve erro nas mensagens de retorno
LOOP AT lt_return INTO ls_return WHERE type = 'E' OR type = 'A'.
  WRITE: / |Erro: { ls_return-message }|.
ENDLOOP.
```

---

### Criando seu próprio Function Module

No SE37, crie o FM `Z_CALCULAR_DESCONTO` com:

```
IMPORTING: iv_valor TYPE p
           iv_pct   TYPE p
EXPORTING: ev_total TYPE p
EXCEPTIONS: desconto_invalido = 1
```

Código do FM:

```abap
FUNCTION z_calcular_desconto.
*"----------------------------------------------------------------------
*"*"Interface local:
*"  IMPORTING
*"     VALUE(IV_VALOR) TYPE  P
*"     VALUE(IV_PCT)   TYPE  P
*"  EXPORTING
*"     VALUE(EV_TOTAL) TYPE  P
*"  EXCEPTIONS
*"      DESCONTO_INVALIDO
*"----------------------------------------------------------------------

  IF iv_pct < 0 OR iv_pct > 100.
    RAISE desconto_invalido.
  ENDIF.

  ev_total = iv_valor - ( iv_valor * iv_pct / 100 ).

ENDFUNCTION.
```

Chamada:

```abap
DATA: lv_total TYPE p DECIMALS 2.

CALL FUNCTION 'Z_CALCULAR_DESCONTO'
  EXPORTING
    iv_valor = '1000.00'
    iv_pct   = 15
  IMPORTING
    ev_total = lv_total
  EXCEPTIONS
    desconto_invalido = 1
    OTHERS            = 2.

IF sy-subrc = 0.
  WRITE: / |Total após desconto: R$ { lv_total }|.
ENDIF.
```

---

### FMs úteis do SAP — memorize esses

```abap
" Conversão de data para texto
CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
  EXPORTING  date_internal = sy-datum
  IMPORTING  date_external = lv_data_texto.

" Popup de confirmação
CALL FUNCTION 'POPUP_TO_CONFIRM'
  EXPORTING  titlebar = 'Confirmar'
             text_question = 'Deseja continuar?'
  IMPORTING  answer = lv_resposta.  " 'J' = sim, 'N' = não

" Enviar e-mail interno SAP
CALL FUNCTION 'SO_NEW_DOCUMENT_SEND_API1'
  EXPORTING  document_data = ls_doc_data
  TABLES     object_content = lt_body
             receivers      = lt_receivers.

" Gravar arquivo no servidor (arquivo local: GUI_DOWNLOAD)
CALL FUNCTION 'GUI_UPLOAD'
  EXPORTING  filename = 'C:\dados.csv'
             filetype = 'ASC'
  TABLES     data_tab = lt_dados.
```

---

## ⚠️ Pegadinhas

**1. Sempre trate EXCEPTIONS — sem isso o programa aborta com dump**
```abap
" ERRADO — sem tratamento de exceção
CALL FUNCTION 'Z_MEU_FM'
  EXPORTING iv_param = lv_valor.
" Se o FM der raise, o programa trava com CALL_FUNCTION_NOT_FOUND ou dump

" CORRETO
CALL FUNCTION 'Z_MEU_FM'
  EXPORTING iv_param = lv_valor
  EXCEPTIONS
    meu_erro = 1
    OTHERS   = 2.
IF sy-subrc <> 0.
  MESSAGE 'Erro no processamento' TYPE 'E'.
ENDIF.
```

**2. VALUE vs. REFERENCE nos parâmetros**
```abap
" VALUE(IV_PARAM) — cria uma cópia (mais seguro, mais memória)
" IV_PARAM sem VALUE — passa referência (mais rápido, o FM pode alterar o original)
" Para tabelas grandes, use referência. Para valores simples, VALUE é ok.
```

**3. FM não atualiza EXPORTING se der RAISE**
```abap
" Se o FM fizer RAISE antes de preencher EV_RESULTADO,
" a variável do chamador fica com o valor que tinha antes
CALL FUNCTION 'Z_MEU_FM'
  EXPORTING iv_x = lv_x
  IMPORTING ev_resultado = lv_resultado  " pode estar vazio/antigo
  EXCEPTIONS erro = 1.
" Sempre verifique sy-subrc antes de usar lv_resultado
```

---

## 🏋️ Exercício

1. Use o SE37 para testar o FM `CONVERSION_EXIT_MATN1_OUTPUT` — insira um número de material interno e veja o formato externo
2. Crie um FM `Z_VALIDAR_EMAIL` que receba um endereço de e-mail e:
   - Valide se contém `@` e `.`
   - Retorne `EV_VALIDO = 'X'` se válido
   - Faça `RAISE email_invalido` se não for válido
3. Chame o FM criado a partir de um programa de teste

---

⬅️ [01 — Subroutines](./01-subroutines-form.md) | ➡️ [03 — Include Programs](./03-include-programs.md)
