# 01 — Smartforms Básico

## 📖 Conceito

Um Smartform tem três partes principais:

1. **Global Settings** — interface (parâmetros de entrada), inicialização de variáveis
2. **Pages & Windows** — layout visual (página, janelas de texto, tabelas)
3. **Form Nodes** — lógica de preenchimento (loops, condicionais, textos dinâmicos)

O SAP gera automaticamente um **Function Module** para cada Smartform — você chama esse FM passando os dados e ele retorna o PDF ou envia para impressora.

**Transação:** `SE71`

---

## 💻 Código

### Chamando um Smartform existente

```abap
REPORT z_decoded_smartform.

DATA: lv_fm_name TYPE rs38l_fnam,
      ls_control TYPE ssfctrlop,
      ls_output  TYPE ssfcompop.

PARAMETERS: pa_vbeln TYPE vbeln_vf OBLIGATORY.

START-OF-SELECTION.

  " Busca os dados da NF que serão passados ao Smartform
  DATA: ls_vbrk TYPE vbrk,
        lt_vbrp TYPE TABLE OF vbrp.

  SELECT SINGLE * FROM vbrk INTO @ls_vbrk WHERE vbeln = @pa_vbeln.
  SELECT * FROM vbrp INTO TABLE @lt_vbrp WHERE vbeln = @pa_vbeln.

  " Obtém o nome do FM gerado pelo Smartform
  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname           = 'Z_NOTA_FISCAL'  " nome do seu Smartform
    IMPORTING
      fm_name            = lv_fm_name
    EXCEPTIONS
      no_form            = 1
      no_function_module = 2
      OTHERS             = 3.

  IF sy-subrc <> 0.
    MESSAGE 'Smartform não encontrado.' TYPE 'E'.
    RETURN.
  ENDIF.

  " Configuração de saída — preview na tela
  ls_control-no_dialog = abap_true.   " sem diálogo de impressora
  ls_control-preview   = abap_true.   " abre preview PDF
  ls_output-tdnoprev   = space.

  " Chama o FM do Smartform passando os dados
  CALL FUNCTION lv_fm_name
    EXPORTING
      control_parameters = ls_control
      output_options     = ls_output
      " Parâmetros definidos na interface do Smartform:
      is_vbrk            = ls_vbrk
    TABLES
      it_vbrp            = lt_vbrp
    EXCEPTIONS
      formatting_error   = 1
      internal_error     = 2
      send_error         = 3
      user_canceled      = 4
      OTHERS             = 5.

  IF sy-subrc <> 0.
    MESSAGE |Erro ao gerar Smartform: { sy-subrc }| TYPE 'E'.
  ENDIF.
```

---

### Gerando PDF e salvando localmente

```abap
DATA: ls_control TYPE ssfctrlop,
      ls_output  TYPE ssfcompop,
      lt_pdf     TYPE TABLE OF tline,
      lv_pdf_len TYPE i,
      ls_job_out TYPE ssfcrescl.

" Configura para gerar PDF sem exibir
ls_control-no_dialog   = abap_true.
ls_control-preview     = space.    " sem preview
ls_output-tddest       = 'PDF'.
ls_output-tdnoprev     = abap_true.

" Ativa captura do PDF
ls_control-getotf      = abap_true.

CALL FUNCTION lv_fm_name
  EXPORTING
    control_parameters = ls_control
    output_options     = ls_output
    is_vbrk            = ls_vbrk
  IMPORTING
    job_output_info    = ls_job_out
  TABLES
    it_vbrp            = lt_vbrp
  EXCEPTIONS
    OTHERS = 1.

" Converte OTF para PDF
IF ls_job_out-otfdata IS NOT INITIAL.
  CALL FUNCTION 'CONVERT_OTF'
    EXPORTING
      format            = 'PDF'
    IMPORTING
      bin_filesize      = lv_pdf_len
    TABLES
      otf               = ls_job_out-otfdata
      lines             = lt_pdf
    EXCEPTIONS
      OTHERS            = 1.

  " Faz download do PDF
  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
      filename         = 'C:\NF_SAP.pdf'
      filetype         = 'BIN'
      bin_filesize     = lv_pdf_len
    TABLES
      data_tab         = lt_pdf.
ENDIF.
```

---

## ⚠️ Pegadinhas

**1. O FM do Smartform muda quando você ativa o form novamente**
```abap
" Sempre use SSF_FUNCTION_MODULE_NAME para obter o FM atual
" Nunca hardcode o nome do FM gerado — ele pode mudar entre ativações
```

**2. Parâmetros da interface do Smartform DEVEM ser declarados no ABAP**
```abap
" Se o Smartform tem um parâmetro IS_CABECALHO na interface,
" você precisa declarar e passar esse parâmetro ao chamar o FM.
" Parâmetros não preenchidos causam erro de "wrong parameter".
```

**3. Smartform sem conexão de impressora válida em desenvolvimento**
```abap
" Em ambiente de dev, configure ls_control-preview = abap_true
" para ver o resultado sem precisar de impressora física.
```

---

## 🏋️ Exercício

1. No SE71, abra o Smartform `RVORDER01` (pedido de venda padrão SAP) e observe sua estrutura: pages, windows, nodes
2. Crie um Smartform simples `Z_DECODED_ETIQUETA` com:
   - Uma página A4 landscape
   - Janela com número do material e descrição
   - Janela com código de barras (use o elemento BARCODE do SE71)
3. Crie um programa ABAP que chama o Smartform passando um número de material e exibe o preview

---

⬅️ [README](./README.md) | ➡️ [02 — Adobe Forms](./02-adobe-forms.md)
