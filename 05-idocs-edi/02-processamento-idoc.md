# 02 — Processamento de IDocs

## 📖 Conceito

O processamento de IDocs tem dois fluxos:

```
OUTBOUND (SAP → Externo)
  Evento de negócio (post de NF, criação de pedido)
    → User Exit/BAdI popula segmentos
    → Dispatch para Port (arquivo, RFC, XI/PI)
    → Tradução EDI (EDIFACT/X12) se necessário
    → Envio ao parceiro

INBOUND (Externo → SAP)
  Arquivo EDI chega
    → Tradução EDI para IDoc (se necessário)
    → IDoc criado com status 50
    → Function Module de processamento chamado
    → Documento SAP criado (pedido, entrega, NF...)
    → Status 53 (OK) ou 51/56 (erro)
```

A SAP fornece **Function Modules padrão** para processar cada Message Type. Você customiza via **User Exits** ou **BAdIs**, nunca modificando o código SAP diretamente.

---

## 💻 Código

### Criando um IDoc Outbound programaticamente

```abap
REPORT z_decoded_idoc_outbound.

" Enviando um MATMAS (mestre de materiais) para um parceiro

DATA: ls_edidc    TYPE edidc,
      lt_edidd    TYPE TABLE OF edidd,
      ls_edidd    TYPE edidd,
      ls_e1maram  TYPE e1maram,
      ls_e1makt   TYPE e1makt,
      lv_docnum   TYPE edi_docnum.

PARAMETERS: pa_matnr TYPE matnr OBLIGATORY.

START-OF-SELECTION.

  " 1. Preenche o control record
  ls_edidc-mestyp = 'MATMAS'.       " Message Type
  ls_edidc-idoctp = 'MATMAS05'.     " Basic Type
  ls_edidc-direct = '1'.            " Outbound
  ls_edidc-rcvprt = 'LS'.           " Receiver type: Logical System
  ls_edidc-rcvprn = 'PARCEIRO_EDI'. " Receiver name

  " 2. Monta o segmento E1MARAM (dados do material)
  CLEAR ls_e1maram.
  ls_e1maram-matnr = pa_matnr.
  " ... preenche demais campos do segmento

  " 3. Adiciona o segmento ao IDoc
  CLEAR ls_edidd.
  ls_edidd-segnam = 'E1MARAM'.
  ls_edidd-sdata  = ls_e1maram.    " dados do segmento no SDATA
  APPEND ls_edidd TO lt_edidd.

  " 4. Monta segmento de texto E1MAKT
  CLEAR ls_e1makt.
  ls_e1makt-spras = sy-langu.
  ls_e1makt-maktx = 'Descrição do Material'.

  CLEAR ls_edidd.
  ls_edidd-segnam = 'E1MAKT'.
  ls_edidd-sdata  = ls_e1makt.
  APPEND ls_edidd TO lt_edidd.

  " 5. Chama o FM para criar e despachar o IDoc
  CALL FUNCTION 'MASTER_IDOC_DISTRIBUTE'
    EXPORTING
      master_idoc_control    = ls_edidc
    TABLES
      communication_idoc_set = lt_edidd
    EXCEPTIONS
      error_in_idoc_control  = 1
      OTHERS                 = 2.

  IF sy-subrc = 0.
    COMMIT WORK.
    WRITE: / 'IDoc criado e despachado com sucesso.'.
  ELSE.
    WRITE: / 'Erro ao criar IDoc.'.
  ENDIF.
```

---

### Processamento Inbound — Function Module padrão

```abap
" O SAP chama automaticamente o FM configurado no Message Type
" Exemplo: ORDERS → IDOC_INPUT_ORDERS

" Estrutura de um FM de processamento inbound:
FUNCTION z_idoc_input_customizado.
*"----------------------------------------------------------------------
*"  TABLES
*"     IDOC_CONTRL STRUCTURE EDIDC
*"     IDOC_DATA   STRUCTURE EDID4
*"     IDOC_STATUS STRUCTURE BDIDOCSTAT
*"     RETURN_VARIABLES STRUCTURE BDWFRETVAR
*"     SERIALIZATION_INFO STRUCTURE BDI_SER
*"----------------------------------------------------------------------

  DATA: ls_edidc TYPE edidc,
        ls_edid4 TYPE edid4.

  " Pega o control record
  READ TABLE idoc_contrl INTO ls_edidc INDEX 1.

  " Processa os segmentos
  LOOP AT idoc_data INTO ls_edid4.
    CASE ls_edid4-segnam.
      WHEN 'E1EDK01'.
        DATA: ls_cabeçalho TYPE e1edk01.
        MOVE ls_edid4-sdata TO ls_cabeçalho.
        " ... processa cabeçalho

      WHEN 'E1EDP01'.
        DATA: ls_item TYPE e1edp01.
        MOVE ls_edid4-sdata TO ls_item.
        " ... processa item
    ENDCASE.
  ENDLOOP.

  " Reporta sucesso
  CALL FUNCTION 'IDOC_STATUS_WRITE_TO_DATABASE'
    EXPORTING
      idoc_number   = ls_edidc-docnum
      status        = '53'    " processado com sucesso
      statistics    = space.

ENDFUNCTION.
```

---

### Reprocessamento em massa — programático

```abap
REPORT z_decoded_idoc_reprocess.

" Reprocessa todos os IDocs inbound com status 51 do dia

DATA: lt_idocs   TYPE TABLE OF edidc,
      lt_docnums TYPE TABLE OF edi_docnum.

SELECT docnum
  FROM edidc
  INTO TABLE @DATA(lt_docs_51)
  WHERE status  = '51'
    AND direct  = '2'              " inbound
    AND credat >= @(sy-datum - 1)
    AND mestyp  IN ('ORDERS', 'DESADV', 'INVOIC').

IF lt_docs_51 IS INITIAL.
  WRITE: / 'Nenhum IDoc com erro encontrado.'.
  RETURN.
ENDIF.

LOOP AT lt_docs_51 INTO DATA(ls_doc).
  CALL FUNCTION 'IDOC_INBOUND_ASYNCHRONOUS'
    EXPORTING
      idoc_number = ls_doc-docnum.
ENDLOOP.

COMMIT WORK.
WRITE: / |{ lines( lt_docs_51 ) } IDocs submetidos para reprocessamento.|.
```

---

### User Exit para enriquecer IDoc Outbound

```abap
" User Exit padrão: EXIT_SAPLEINM_001 (para MATMAS)
" O nome do exit depende do Message Type — consulte o WE60 ou SPRO

FUNCTION exit_sapleinm_001.
*"-----------------------------------------------------------
*"  TABLES
*"     T_EDIDD STRUCTURE EDIDD
*"  CHANGING
*"     C_EDIDC STRUCTURE EDIDC
*"-----------------------------------------------------------

  " Adiciona um segmento Z (extensão customizada)
  DATA: ls_ze1maram TYPE ze1maram,   " seu segmento custom
        ls_edidd    TYPE edidd.

  " Lê dados adicionais e popula o segmento Z
  SELECT SINGLE campo_z INTO @ls_ze1maram-campo_z
    FROM zminha_tabela
    WHERE matnr = @c_edidc-mandt.  " usar chave do IDoc

  ls_edidd-segnam = 'ZE1MARAM'.
  ls_edidd-sdata  = ls_ze1maram.
  APPEND ls_edidd TO t_edidd.

ENDFUNCTION.
```

---

## ⚠️ Pegadinhas

**1. COMMIT WORK é obrigatório para persistir o IDoc**
```abap
" MASTER_IDOC_DISTRIBUTE cria o IDoc em memória
" Sem COMMIT WORK, o IDoc não vai para o banco
CALL FUNCTION 'MASTER_IDOC_DISTRIBUTE' ...
COMMIT WORK.  " ← NUNCA esqueça
```

**2. Status 51 x 56 — o reprocessamento é diferente**
```abap
" Status 51 (Application Error) → BD87 ou IDOC_INBOUND_ASYNCHRONOUS
" Status 56 (IDoc exception) → verificar configuração em WE20/WE21 antes de reprocessar
" Reprocessar 56 sem corrigir a config só gera mais 56
```

**3. Verificar segmentos obrigatórios antes de despachar**
```abap
" O IDoc pode ser criado com sucesso mas falhar no parceiro
" se segmentos obrigatórios estiverem vazios.
" Use WE19 para testar manualmente antes de ir para produção.
```

---

## 🏋️ Exercício

1. No WE19, selecione um IDoc ORDERS existente e faça um teste simulado (não envia de verdade)
2. Crie um programa `Z_DECODED_IDOC_MONITOR` que:
   - Liste IDocs com erro (status 51 ou 56) dos últimos 3 dias
   - Para cada um, mostre: número, message type, parceiro, data, texto do erro
   - Ofereça uma opção de reprocessamento individual via ALV com double-click
3. Teste o reprocessamento com um IDoc real de status 51

---

⬅️ [01 — Estrutura do IDoc](./01-estrutura-idoc.md) | ➡️ [03 — Parceiros EDI](./03-parceiros-edi.md)
