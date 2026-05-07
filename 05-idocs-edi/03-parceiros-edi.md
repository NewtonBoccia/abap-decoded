# 03 — Parceiros EDI e Perfis

## 📖 Conceito

O **Partner Profile** (WE20) é onde você define como o SAP deve se comunicar com cada parceiro comercial. Sem o perfil correto, o IDoc é gerado mas não vai a lugar nenhum — ou chega mas não é processado.

Estrutura de um Partner Profile:

```
Partner Profile (WE20)
├── Partner Type: LS (Logical System), KU (Customer), LI (Vendor)
├── Partner Number: código do parceiro
│
├── Outbound Parameters (para cada Message Type que você ENVIA)
│   ├── Message Type (ex: ORDERS)
│   ├── IDoc Basic Type (ex: ORDERS05)
│   ├── Receiver Port (ex: arquivo, RFC)
│   ├── Output Mode (Immediate / Collect)
│   └── IDoc per Transfer (1 / All)
│
└── Inbound Parameters (para cada Message Type que você RECEBE)
    ├── Message Type (ex: ORDRSP)
    ├── Process Code (função que processa o IDoc)
    └── Processing Mode (Trigger imediato / Background)
```

---

## 💻 Código

### Verificando configuração de parceiro via ABAP

```abap
REPORT z_decoded_edi_parceiros.

" Tabelas relevantes para configuração EDI:
" EDPP1 — Partner Profile Outbound Parameters
" EDPP2 — Partner Profile Inbound Parameters
" EDPOD — Outbound Parameters (tabela mais completa)

PARAMETERS: pa_partn TYPE edi_partn DEFAULT 'PARCEIRO_001',
            pa_ptype TYPE edi_ptype DEFAULT 'LS'.

START-OF-SELECTION.

  " Verifica perfis de saída
  SELECT mestyp idoctp rcvprt rcvprn outmod
    FROM edpp1
    INTO TABLE @DATA(lt_out)
    WHERE sndprt = @pa_ptype
      AND sndprn = @pa_partn.

  WRITE: / |=== OUTBOUND — { pa_partn } ===|.
  LOOP AT lt_out INTO DATA(ls_out).
    WRITE: / |  { ls_out-mestyp } | { ls_out-idoctp } | Port: { ls_out-rcvprt }/{ ls_out-rcvprn }|.
  ENDLOOP.

  " Verifica perfis de entrada
  SELECT mestyp idoctp proca stapa
    FROM edpp2
    INTO TABLE @DATA(lt_in)
    WHERE rcvprt = @pa_ptype
      AND rcvprn = @pa_partn.

  WRITE: / |=== INBOUND — { pa_partn } ===|.
  LOOP AT lt_in INTO DATA(ls_in).
    WRITE: / |  { ls_in-mestyp } | { ls_in-idoctp } | Process Code: { ls_in-proca }|.
  ENDLOOP.
```

---

### Verificando Ports configurados

```abap
" Port define O CANAL de comunicação:
" Tipo A = tRFC (Transactional RFC) — para sistemas SAP-a-SAP
" Tipo F = Arquivo (File port) — para EDI via arquivo
" Tipo X = XML HTTP — para Web Services

" Tabela de ports: EDIPOA (File), EDIPORT (todos os tipos)

SELECT portnam trfcdi rfcdst
  FROM ediport
  INTO TABLE @DATA(lt_ports)
  WHERE porttype = 'A'.  " tRFC ports

LOOP AT lt_ports INTO DATA(ls_port).
  WRITE: / |Port: { ls_port-portnam } | RFC Dest: { ls_port-rfcdst }|.
ENDLOOP.
```

---

### Verificando Process Codes (inbound)

```abap
" Process Code = qual Function Module vai processar o IDoc inbound
" Tabela: TEDE3 (Process Codes)

SELECT prcod text1 funct
  FROM tede3
  INTO TABLE @DATA(lt_procs)
  WHERE mestyp = 'ORDERS'.

LOOP AT lt_procs INTO DATA(ls_proc).
  WRITE: / |Code: { ls_proc-prcod } | FM: { ls_proc-funct } | { ls_proc-text1 }|.
ENDLOOP.
```

---

### Diagnóstico de configuração — script de verificação

```abap
REPORT z_decoded_edi_diag.

" Script útil para diagnosticar problemas de configuração
" Verifica se um parceiro está pronto para receber/enviar um message type

PARAMETERS: pa_partn  TYPE edi_partn,
            pa_mestyp TYPE edi_mestyp,
            pa_dir    TYPE c LENGTH 1 DEFAULT '1'.  " 1=OUT, 2=IN

START-OF-SELECTION.

  IF pa_dir = '1'.  " Outbound
    SELECT SINGLE *
      FROM edpp1
      INTO @DATA(ls_out)
      WHERE sndprn = @pa_partn
        AND mestyp = @pa_mestyp.

    IF sy-subrc = 0.
      WRITE: / |✅ Outbound configurado: { pa_mestyp } → { pa_partn }|,
             / |   Basic Type: { ls_out-idoctp }|,
             / |   Output Mode: { ls_out-outmod }|.
    ELSE.
      WRITE: / |❌ FALTA configuração Outbound: { pa_mestyp } → { pa_partn }|.
      WRITE: / '   Ação: WE20 → criar Outbound Parameter'.
    ENDIF.

  ELSE.  " Inbound
    SELECT SINGLE *
      FROM edpp2
      INTO @DATA(ls_in)
      WHERE rcvprn = @pa_partn
        AND mestyp = @pa_mestyp.

    IF sy-subrc = 0.
      WRITE: / |✅ Inbound configurado: { pa_mestyp } ← { pa_partn }|,
             / |   Process Code: { ls_in-proca }|.
    ELSE.
      WRITE: / |❌ FALTA configuração Inbound: { pa_mestyp } ← { pa_partn }|.
      WRITE: / '   Ação: WE20 → criar Inbound Parameter'.
    ENDIF.
  ENDIF.
```

---

### Configuração típica de onboarding de parceiro

Sequência de passos para conectar um novo parceiro EDI:

```
1. WE21 — Criar Port (tipo depende do canal: arquivo, RFC, XI)
2. BD54 — Criar Logical System (se parceiro for LS)
3. WE20 — Criar Partner Profile
   ├── Outbound: Message Types que você vai enviar ao parceiro
   └── Inbound:  Message Types que o parceiro vai te enviar
4. WE30 — Verificar se o Basic Type atende ou criar extensão (ZZ-type)
5. WE19 — Testar com IDoc simulado
6. Validar com parceiro — conferir mapeamento de segmentos/campos
```

---

## ⚠️ Pegadinhas

**1. Output Mode "Transfer IDoc Immediately" vs "Collect IDocs"**
```abap
" Immediate (2) — envia assim que o IDoc é criado (bom para real-time)
" Collect (4)   — acumula e envia em batch (melhor para volume alto)
" Em produção: Collect geralmente é mais estável e evita flood de conexões
```

**2. Port File — caminho de arquivo precisa existir no servidor SAP**
```abap
" Se o port aponta para /usr/sap/export/edi/
" essa pasta precisa existir E o usuário do SAP precisa ter permissão de escrita
" Erros de "port not available" geralmente são de permissão de diretório
```

**3. Mesmo parceiro pode ter perfis diferentes por Message Type**
```abap
" PARCEIRO_001 pode ter:
" Outbound ORDERS com Output Mode = Immediate
" Outbound INVOIC com Output Mode = Collect
" Inbound ORDRSP com Process Code = ORDE
" Cada message type tem sua própria linha no Partner Profile
```

---

## 🏋️ Exercício

No WE20 do seu sistema SAP:

1. Localize um parceiro existente (tipo LS ou KU) e documente:
   - Quantos outbound parameters ele tem e quais message types
   - Quantos inbound parameters e seus process codes
2. Crie um programa `Z_DECODED_PARCEIROS` que:
   - Leia todos os parceiros configurados em WE20
   - Para cada parceiro, mostre: tipo, número, quantidade de outbound e inbound configurados
   - Destaque parceiros sem nenhum parâmetro configurado (possível configuração incompleta)
3. Execute o programa e identifique se há algum parceiro "órfão"

---

⬅️ [02 — Processamento](./02-processamento-idoc.md) | ➡️ [04 — Monitoramento](./04-monitoramento.md)
