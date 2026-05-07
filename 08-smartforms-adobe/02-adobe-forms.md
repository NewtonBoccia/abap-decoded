# 02 — Adobe Forms

## 📖 Conceito

Adobe Forms (transação `SFP`) é o padrão moderno para formulários SAP. Usa Adobe LiveCycle Designer como editor visual e permite formulários interativos (preenchíveis pelo usuário) além de PDFs estáticos.

Estrutura:
- **Interface** — define os parâmetros de entrada/saída (similar ao Smartform)
- **Form** — o layout visual criado no Adobe LiveCycle Designer
- **Context** — mapeamento entre os dados ABAP e os campos do PDF

---

## 💻 Código

### Chamando um Adobe Form via ABAP

```abap
REPORT z_decoded_adobe.

DATA: lo_fp      TYPE REF TO if_fp,
      lo_form    TYPE REF TO if_fp_form,
      lv_pdf     TYPE xstring.

PARAMETERS: pa_vbeln TYPE vbeln_vf.

START-OF-SELECTION.

  " Busca os dados
  SELECT SINGLE * FROM vbrk INTO @DATA(ls_vbrk) WHERE vbeln = @pa_vbeln.

  " Obtém a instância do Adobe Forms Service
  lo_fp = cl_fp=>get_reference( ).

  " Obtém referência ao formulário
  TRY.
    lo_form = lo_fp->get_form(
      i_name   = 'Z_ADOBE_NOTA_FISCAL'   " nome do form no SFP
    ).

    " Configura a chamada (sem diálogo, retorna PDF)
    lo_form->execute(
      EXPORTING
        is_vbrk  = ls_vbrk              " parâmetro definido na interface
      IMPORTING
        e_pdf    = lv_pdf               " PDF gerado como xstring
    ).

    " Salva o PDF no diretório local
    DATA: lt_pdf_bin TYPE TABLE OF x255.
    " Converte xstring para tabela binária para GUI_DOWNLOAD
    " ... (conversão xstring → lt_pdf_bin via SPLIT ou FM)
    WRITE: / |PDF gerado — { xstrlen( lv_pdf ) } bytes|.

  CATCH cx_fp_api_repository INTO DATA(lo_err).
    WRITE: / |Formulário não encontrado: { lo_err->get_text( ) }|.
  CATCH cx_fp_api_usage INTO lo_err.
    WRITE: / |Erro de uso: { lo_err->get_text( ) }|.
  CATCH cx_fp_api_internal INTO lo_err.
    WRITE: / |Erro interno Adobe Forms: { lo_err->get_text( ) }|.
  ENDTRY.
```

---

### Configurações de output (impressão vs. preview vs. e-mail)

```abap
DATA: ls_docparams TYPE sfpdocparams,
      ls_outputpar TYPE sfpoutputparams.

" Preview na tela
ls_outputpar-preview = abap_true.

" Ou: enviar diretamente para impressora
ls_outputpar-pdltype   = 'PDF'.
ls_outputpar-dest      = 'LP01'.   " nome da impressora

" Ou: retornar como xstring (para e-mail ou armazenamento)
ls_outputpar-getpdf    = abap_true.
ls_outputpar-pdfspoolid = space.

lo_form->execute(
  EXPORTING
    is_docparams    = ls_docparams
    is_outputparams = ls_outputpar
    is_vbrk         = ls_vbrk
  IMPORTING
    e_pdf           = lv_pdf
).
```

---

## ⚠️ Pegadinhas

**1. Adobe Forms requer Adobe Document Services configurado**
```abap
" Em sistemas sem ADS configurado (SM59 → ADS destino),
" qualquer chamada ao SFP resulta em CX_FP_API_REPOSITORY.
" Verifique: SM59 → ADS → Connection Test
```

**2. Interface e Form precisam ter o mesmo nome de objeto de contexto**
```abap
" Se a Interface define o parâmetro IS_CABECALHO,
" o Form precisa ter esse mesmo nó no context.
" Descasamento entre Interface e Form = erro em runtime.
```

---

## 🏋️ Exercício

1. No SFP, abra um Adobe Form existente no sistema e observe:
   - Aba Interface: quais parâmetros ele aceita?
   - Aba Form: como o context mapeia os dados para os campos PDF?
2. Crie o Adobe Form `Z_DECODED_RECIBO` com:
   - Interface: `IS_PAGAMENTO TYPE ty_pagamento` (valor, data, beneficiário)
   - Form: um PDF de recibo simples com logo, dados e assinatura
3. Chame o form via ABAP e exiba o preview

---

⬅️ [01 — Smartforms](./01-smartforms-basico.md) | ➡️ [Módulo 09 — Fiori & RAP](../09-fiori-rap/README.md)
