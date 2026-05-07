# 01 — Estrutura do IDoc

## 📖 Conceito

Um IDoc (Intermediate Document) é um contêiner padronizado para dados de negócio. Pense nele como um envelope com três camadas:

```
┌─────────────────────────────────────────────────────┐
│  EDIDC (Control Record) — 1 por IDoc                │
│  Quem enviou, quem recebe, qual mensagem, status    │
├─────────────────────────────────────────────────────┤
│  EDID4 (Data Records) — N por IDoc                  │
│  Segmentos com os dados reais do documento          │
│  ├── E1EDK01 (cabeçalho do pedido)                  │
│  ├── E1EDP01 (item 1)                               │
│  ├── E1EDP01 (item 2)                               │
│  └── E1EDKT1 (texto)                               │
├─────────────────────────────────────────────────────┤
│  EDIDS (Status Records) — N por IDoc                │
│  Histórico de processamento (03=enviado, 53=OK...)  │
└─────────────────────────────────────────────────────┘
```

**Terminologia essencial:**

| Termo | Significa |
|-------|-----------|
| **Basic Type** | Estrutura do IDoc (ex: ORDERS05) — define os segmentos disponíveis |
| **Message Type** | Mensagem de negócio (ex: ORDERS) — mapeada para 1+ Basic Types |
| **IDoc Type** | Combinação de Basic Type + Extensions |
| **Partner Profile** | Configuração do parceiro comercial (WE20) |
| **Port** | Canal de comunicação (arquivo, RFC, tRFC) |

---

## 💻 Código

### Lendo a estrutura de um IDoc em ABAP

```abap
REPORT z_decoded_idoc_01.

" Tabelas principais do IDoc no banco de dados:
" EDIDC — Control Records (cabeçalho do IDoc)
" EDID4 — Data Records (segmentos de dados)
" EDIDS — Status Records

DATA: ls_edidc TYPE edidc,
      lt_edid4 TYPE TABLE OF edid4,
      lt_edids TYPE TABLE OF edids.

PARAMETERS: pa_docnum TYPE edi_docnum OBLIGATORY.

START-OF-SELECTION.

  " Busca o control record
  SELECT SINGLE *
    FROM edidc
    INTO @ls_edidc
    WHERE docnum = @pa_docnum.

  IF sy-subrc <> 0.
    WRITE: / |IDoc { pa_docnum } não encontrado.|.
    RETURN.
  ENDIF.

  " Exibe cabeçalho
  WRITE: / '=== CONTROL RECORD ===',
         / |IDoc Number : { ls_edidc-docnum }|,
         / |Direction   : { ls_edidc-direct }  (1=Outbound 2=Inbound)|,
         / |Status      : { ls_edidc-status }|,
         / |Messg Type  : { ls_edidc-mestyp }|,
         / |Basic Type  : { ls_edidc-idoctp }|,
         / |Partner     : { ls_edidc-sndprt }/{ ls_edidc-sndprn }|,
         / |Receiver    : { ls_edidc-rcvprt }/{ ls_edidc-rcvprn }|.

  " Busca os data records
  SELECT * FROM edid4
    INTO TABLE @lt_edid4
    WHERE docnum = @pa_docnum
    ORDER BY segnum.

  " Exibe segmentos
  WRITE: / / '=== DATA RECORDS ==='.
  LOOP AT lt_edid4 INTO DATA(ls_seg).
    WRITE: / |Seg { ls_seg-segnum } | { ls_seg-segnam } | Nível { ls_seg-hlevel }|.
  ENDLOOP.

  " Busca o histórico de status
  SELECT * FROM edids
    INTO TABLE @lt_edids
    WHERE docnum = @pa_docnum
    ORDER BY logdat logti.

  WRITE: / / '=== STATUS HISTORY ==='.
  LOOP AT lt_edids INTO DATA(ls_st).
    WRITE: / |{ ls_st-logdat } { ls_st-logti } | Status { ls_st-status } | { ls_st-statxt }|.
  ENDLOOP.
```

---

### Entendendo os status mais comuns

```abap
" Outbound (SAP → Externo):
" 01 — IDoc gerado, aguardando envio
" 02 — Erro na geração
" 03 — Enviado para o parceiro
" 04 — Erro no envio
" 06 — Tradução EDI OK
" 08 — Erro na tradução EDI
" 12 — Enviado com sucesso (confirmação recebida)
" 26 — Erro de comunicação

" Inbound (Externo → SAP):
" 50 — Recebido, aguardando processamento
" 51 — Erro no processamento (Application Error)
" 53 — Processado com sucesso
" 56 — Exceção de IDoc

" Os status 51 e 56 são os que você mais vai debugar
```

---

### Trabalhando com segmentos — acessando os dados

```abap
REPORT z_decoded_idoc_segmentos.

DATA: lt_edid4 TYPE TABLE OF edid4,
      ls_edid4 TYPE edid4.

PARAMETERS: pa_docnum TYPE edi_docnum.

START-OF-SELECTION.

  SELECT * FROM edid4
    INTO TABLE @lt_edid4
    WHERE docnum = @pa_docnum.

  LOOP AT lt_edid4 INTO ls_edid4 WHERE segnam = 'E1MARAM'.
    " Os dados do segmento ficam no campo SDATA (1000 bytes)
    DATA: ls_e1maram TYPE e1maram.

    " Converte o SDATA para a estrutura do segmento
    MOVE ls_edid4-sdata TO ls_e1maram.

    WRITE: / |Material: { ls_e1maram-matnr } | Tipo: { ls_e1maram-mtart }|.
  ENDLOOP.
```

---

### Transações essenciais — decore essas

| Transação | Para que serve |
|-----------|---------------|
| `WE60` | Documentação de Basic Types e segmentos |
| `WE30` | Criar/visualizar Basic Types |
| `WE81` | Message Types |
| `WE82` | Vincular Message Type ao Basic Type |
| `WE20` | Partner Profiles (configuração de parceiros) |
| `WE21` | Ports (canais de comunicação) |
| `WE02` | Monitor de IDocs (buscar e visualizar) |
| `WE05` | Monitor simplificado de IDocs |
| `WE19` | Testar IDocs manualmente |
| `BD87` | Reprocessar IDocs com erro (Inbound) |
| `WE14` | Reprocessar IDocs com erro (Outbound) |

---

## ⚠️ Pegadinhas

**1. SDATA é o campo que contém os dados do segmento**
```abap
" SDATA tem 1000 bytes e contém os dados do segmento
" Para acessar os campos, você precisa fazer MOVE para a estrutura do segmento:
DATA: ls_e1edka1 TYPE e1edka1.
MOVE ls_edid4-sdata TO ls_e1edka1.
" Agora ls_e1edka1-partn tem o número do parceiro, etc.
```

**2. Status 51 vs 56**
```abap
" 51 = Application Error — erro no processamento da lógica de negócio
"      (ex: material não encontrado, cliente bloqueado)
" 56 = IDoc exception — erro mais grave, geralmente de configuração
"      (ex: message type não configurado, function module não encontrado)
" Para reprocessar: BD87 (inbound) ou WE14 (outbound)
```

**3. Nunca modifique EDIDC/EDID4 diretamente**
```abap
" Não faça UPDATE edidc SET status = '53' WHERE docnum = pa_docnum.
" Use os Function Modules oficiais:
" EDI_DOCUMENT_STATUS_SET — para atualizar status
" IDOC_INBOUND_ASYNCHRONOUS — para reprocessar inbound
```

---

## 🏋️ Exercício

1. Na transação `WE02`, filtre IDocs com status 51 dos últimos 7 dias
2. Abra um deles e anote: número do IDoc, Message Type, parceiro emissor, texto do erro no status record
3. No SE38, crie um programa que lista todos os IDocs com status 51 da última semana, mostrando: número, message type, parceiro, data de criação e texto do último status

---

⬅️ [README do módulo](./README.md) | ➡️ [02 — Processamento de IDocs](./02-processamento-idoc.md)
