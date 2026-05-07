# 04 — Monitoramento e Reprocessamento

## 📖 Conceito

O dia a dia de um Integration Specialist SAP é: **monitorar IDocs, entender erros, corrigir e reprocessar**. Saber navegar rápido pelo WE02, interpretar status codes e reprocessar em massa são habilidades que salvam SLAs.

---

## 💻 Código

### WE02 — Filtros que você mais vai usar

```
WE02 — IDoc List:
  Direction  : 1 (Outbound) ou 2 (Inbound)
  Status     : 51 (erro app), 56 (erro IDoc), 04 (erro envio)
  Message Type: ORDERS, DESADV, INVOIC, MATMAS...
  Partner    : filtrar por parceiro específico
  Date Range : sempre filtrar por data para não explodir a seleção
```

---

### Programa de monitoramento customizado

```abap
REPORT z_decoded_idoc_monitor.

" Monitor mais completo que o WE02 — adaptado à realidade da operação

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS: so_mtype FOR edidc-mestyp,
                  so_partn FOR edidc-sndprn,
                  so_date  FOR edidc-credat DEFAULT sy-datum.
  PARAMETERS:     pa_dir   TYPE edi_direct DEFAULT '2',   " 2=Inbound
                  pa_err   TYPE c LENGTH 1 DEFAULT 'X'.   " só erros
SELECTION-SCREEN END OF BLOCK b1.

START-OF-SELECTION.

  DATA: lt_idocs TYPE TABLE OF edidc.

  " Busca IDocs conforme filtros
  IF pa_err = 'X'.
    " Só IDocs com erro
    SELECT docnum mestyp status direct sndprt sndprn rcvprt rcvprn credat cretim
      FROM edidc
      INTO TABLE @lt_idocs
      WHERE mestyp IN @so_mtype
        AND sndprn IN @so_partn
        AND credat IN @so_date
        AND direct = @pa_dir
        AND status IN ('51', '56', '04', '02', '26').
  ELSE.
    SELECT docnum mestyp status direct sndprt sndprn rcvprt rcvprn credat cretim
      FROM edidc
      INTO TABLE @lt_idocs
      WHERE mestyp IN @so_mtype
        AND sndprn IN @so_partn
        AND credat IN @so_date
        AND direct = @pa_dir.
  ENDIF.

  SORT lt_idocs BY status mestyp sndprn.

  " Exibe com ALV
  DATA: lo_alv  TYPE REF TO cl_salv_table,
        lt_cols TYPE REF TO cl_salv_columns_table.

  cl_salv_table=>factory(
    IMPORTING r_salv_table = lo_alv
    CHANGING  t_table      = lt_idocs ).

  lo_alv->get_columns( )->set_optimize( abap_true ).
  lo_alv->display( ).
```

---

### Reprocessamento individual e em massa

```abap
REPORT z_decoded_idoc_reprocess.

" Reprocessamento em massa de IDocs inbound com erro

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS: so_docnum FOR edidc-docnum,
                  so_mtype  FOR edidc-mestyp,
                  so_date   FOR edidc-credat DEFAULT sy-datum.
  PARAMETERS: pa_sim TYPE c LENGTH 1 DEFAULT 'X'.  " modo simulação
SELECTION-SCREEN END OF BLOCK b1.

START-OF-SELECTION.

  SELECT docnum mestyp status credat sndprn
    FROM edidc
    INTO TABLE @DATA(lt_erros)
    WHERE docnum IN @so_docnum
      AND mestyp IN @so_mtype
      AND credat IN @so_date
      AND direct = '2'
      AND status IN ('51', '56').

  IF lt_erros IS INITIAL.
    WRITE: / 'Nenhum IDoc com erro encontrado.'.
    RETURN.
  ENDIF.

  WRITE: / |{ lines( lt_erros ) } IDocs encontrados.|.

  IF pa_sim = 'X'.
    WRITE: / '=== MODO SIMULAÇÃO — nenhum reprocessamento executado ==='.
    LOOP AT lt_erros INTO DATA(ls).
      WRITE: / |  { ls-docnum } | { ls-mestyp } | Status { ls-status } | { ls-sndprn }|.
    ENDLOOP.
    RETURN.
  ENDIF.

  " Reprocessamento real
  DATA: lv_ok  TYPE i,
        lv_err TYPE i.

  LOOP AT lt_erros INTO DATA(ls_doc).
    CALL FUNCTION 'IDOC_INBOUND_ASYNCHRONOUS'
      EXPORTING
        idoc_number = ls_doc-docnum
      EXCEPTIONS
        OTHERS      = 1.

    IF sy-subrc = 0.
      lv_ok = lv_ok + 1.
    ELSE.
      lv_err = lv_err + 1.
      WRITE: / |⚠️ Falha ao submeter { ls_doc-docnum }|.
    ENDIF.
  ENDLOOP.

  COMMIT WORK.
  WRITE: / |✅ Submetidos: { lv_ok } | ❌ Falhas: { lv_err }|.
```

---

### Decodificando o erro de um IDoc

```abap
REPORT z_decoded_idoc_erro_detail.

" Exibe o detalhe completo do erro de um IDoc para análise

PARAMETERS: pa_docnum TYPE edi_docnum OBLIGATORY.

START-OF-SELECTION.

  " Status records (histórico de processamento)
  SELECT *
    FROM edids
    INTO TABLE @DATA(lt_status)
    WHERE docnum = @pa_docnum
    ORDER BY logdat DESCENDING logti DESCENDING.

  WRITE: / |=== Histórico de Status — IDoc { pa_docnum } ===|.
  LOOP AT lt_status INTO DATA(ls_st).
    WRITE: / |{ ls_st-logdat } { ls_st-logti } | Status { ls_st-status } | { ls_st-statxt }|.
    IF ls_st-stamid IS NOT INITIAL.
      WRITE: / |  Mensagem: { ls_st-stamid }/{ ls_st-stamno } - { ls_st-statyp }|.
    ENDIF.
  ENDLOOP.

  " Exibe o texto completo das mensagens de erro
  READ TABLE lt_status INTO DATA(ls_ultimo) INDEX 1.
  IF ls_ultimo-stamid IS NOT INITIAL.
    DATA: lv_texto TYPE string.
    CALL FUNCTION 'FORMAT_MESSAGE'
      EXPORTING
        id   = ls_ultimo-stamid
        lang = sy-langu
        no   = ls_ultimo-stamno
        v1   = ls_ultimo-stapa1
        v2   = ls_ultimo-stapa2
        v3   = ls_ultimo-stapa3
        v4   = ls_ultimo-stapa4
      IMPORTING
        msg  = lv_texto.
    WRITE: / |Mensagem de erro: { lv_texto }|.
  ENDIF.
```

---

### Status codes — referência rápida

```abap
" OUTBOUND:
" 01 — IDoc gerado no sistema emissor
" 02 — Erro na transmissão para o sistema de comunicação
" 03 — IDoc enviado com dados (Outbound to port)
" 04 — Erro no processamento pelo subsistema EDI
" 06 — Tradução EDI OK
" 07 — Erro na tradução EDI
" 08 — Erro sintático no arquivo EDI
" 09 — IDoc recebido pelo subsistema EDI
" 10 — Intercâmbio recebido pelo parceiro
" 12 — Despachado para o parceiro (confirmação recebida)
" 26 — Erro na comunicação via RFC
" 29 — Erro no controle ALE

" INBOUND:
" 50 — IDoc adicionado para processamento (aguardando)
" 51 — Application error — erro na lógica de negócio
" 52 — Aplicação processada parcialmente
" 53 — Processado com sucesso — documento SAP criado
" 54 — Erro em ALE Service
" 55 — IDocs processados tecnicamente
" 56 — IDoc com exceção — erro grave de configuração/estrutura
" 61 — Processamento manual
" 64 — IDoc pronto para transferência ao R/2
" 65 — Erro na transferência ao R/2
" 66 — IDoc aguardando retorno do R/2
" 68 — Erro — nenhuma função de processamento encontrada
" 70 — Original IDoc OK — existem IDocs filhos
" 73 — IDoc arquivado
```

---

## ⚠️ Pegadinhas

**1. Reprocessar status 56 sem corrigir a configuração**
```abap
" Status 56 = problema de configuração (WE20/WE21/mapeamento)
" Reprocessar sem corrigir = criar mais IDocs 56
" Diagnóstico primeiro: verificar WE20 do parceiro, WE21 do port, WE82 do message type
```

**2. BD87 vs WE14 — não confunda os fluxos**
```abap
" BD87 = reprocessamento INBOUND (IDocs que chegaram ao SAP)
" WE14 = reprocessamento OUTBOUND (IDocs que o SAP precisa enviar)
```

**3. Reprocessar em produção sem teste em QA**
```abap
" Um IDoc com status 51 pode ter falhado por dados incorretos
" Se o dado ainda está errado, reprocessar vai gerar 51 de novo
" Sempre entenda O MOTIVO do erro antes de reprocessar em massa
```

---

## 🏋️ Exercício

Construa o programa `Z_DECODED_IDOC_DASHBOARD`:

1. **Visão geral**: conta IDocs por status (agrupando por message type + status) dos últimos 7 dias
2. **Detalhes de erro**: para IDocs com status 51/56, exibe o texto do último status record
3. **Ação de reprocessamento**: com double-click no ALV, oferece opção de reprocessar o IDoc selecionado (com confirmação via POPUP_TO_CONFIRM)
4. **Exportação**: botão no ALV toolbar para exportar para Excel

Este programa é o tipo de ferramenta que todo Integration Specialist SAP usa no dia a dia — e que impressiona recrutadores quando você descreve no CV.

---

⬅️ [03 — Parceiros EDI](./03-parceiros-edi.md) | ➡️ [Módulo 06 — BAPI & RFC](../06-bapi-rfc/README.md)
