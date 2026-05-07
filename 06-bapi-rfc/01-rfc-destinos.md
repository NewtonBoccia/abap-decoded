# 01 — RFC: Destinos e Tipos

## 📖 Conceito

RFC (Remote Function Call) permite chamar Function Modules em outro sistema como se fossem locais. Tipos:

| Tipo | Nome | Comportamento |
|------|------|---------------|
| `sRFC` | Synchronous RFC | Aguarda resposta — uso geral |
| `aRFC` | Asynchronous RFC | Não aguarda — dispara e esquece |
| `tRFC` | Transactional RFC | Garantia de entrega (exactly-once) |
| `bgRFC` | Background RFC | tRFC moderno, gerenciado |

**SM59** é onde você cria e testa RFC Destinations.

---

## 💻 Código

### Chamando FM em sistema remoto

```abap
REPORT z_decoded_rfc_01.

" Chama um FM no sistema PRD a partir do QAS
" O destino 'RFC_PARA_PRD' deve estar configurado em SM59

DATA: lv_resultado TYPE string.

CALL FUNCTION 'Z_MEU_FM_REMOTO'
  DESTINATION 'RFC_PARA_PRD'     " ← nome do RFC Destination (SM59)
  EXPORTING
    iv_param = 'TESTE'
  IMPORTING
    ev_result = lv_resultado
  EXCEPTIONS
    system_failure        = 1 MESSAGE lv_resultado
    communication_failure = 2 MESSAGE lv_resultado
    OTHERS                = 3.

CASE sy-subrc.
  WHEN 0.
    WRITE: / |Resultado: { lv_resultado }|.
  WHEN 1.
    WRITE: / |Falha no sistema remoto: { lv_resultado }|.
  WHEN 2.
    WRITE: / |Falha de comunicação: { lv_resultado }|.
  WHEN OTHERS.
    WRITE: / 'Erro desconhecido'.
ENDCASE.
```

---

### tRFC — garantia de entrega

```abap
" tRFC: o SAP garante que o FM será executado exatamente uma vez,
" mesmo se a conexão cair no meio

DATA: lv_tid TYPE trfctid.  " Transaction ID — identifica o pacote

" Gera um ID de transação único
CALL FUNCTION 'ID_OF_TRANSID'
  IMPORTING
    tid = lv_tid.

" Chama com TRANSACTION ID
CALL FUNCTION 'Z_PROCESSAR_PEDIDO'
  IN BACKGROUND TASK             " ← tRFC
  DESTINATION 'RFC_SISTEMA_B'
  EXPORTING
    iv_pedido = '0000012345'.

COMMIT WORK.  " ← OBRIGATÓRIO — sem COMMIT, o tRFC não é enviado
```

---

### Verificando RFC Destinations programaticamente

```abap
" Lista todos os RFC Destinations configurados em SM59
SELECT rfcdest rfctype rfchost rfcsysid
  FROM rfcdes
  INTO TABLE @DATA(lt_rfcs)
  WHERE rfctype IN ('3', 'L')  " 3=ABAP conn, L=Local
  ORDER BY rfcdest.

LOOP AT lt_rfcs INTO DATA(ls_rfc).
  WRITE: / ls_rfc-rfcdest, ls_rfc-rfchost, ls_rfc-rfcsysid.
ENDLOOP.
```

---

## ⚠️ Pegadinhas

**1. tRFC sem COMMIT WORK não é enviado**
```abap
" CALL FUNCTION ... IN BACKGROUND TASK apenas registra a chamada
" COMMIT WORK é quem dispara o envio para o sistema remoto
```

**2. system_failure vs communication_failure**
```abap
" communication_failure: problema de rede/conexão (SM59 errado)
" system_failure: o sistema remoto teve um ABAP dump ou erro
" Ambos precisam ser tratados separadamente
```

---

⬅️ [README](./README.md) | ➡️ [02 — BAPIs](./02-bapi-basico.md)
