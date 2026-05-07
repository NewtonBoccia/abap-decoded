# 02 — BAPIs: Usar e Criar

## 📖 Conceito

BAPI (Business Application Programming Interface) é um Function Module com contrato estável, documentado e versões garantidas pela SAP. A regra de ouro: **sempre use BAPI quando existir uma para o que você precisa fazer** — modificar tabelas diretamente é frágil e não suportado.

**Onde encontrar:** BAPI Explorer (transação `BAPI`) ou SAP Help Portal.

**Retorno padrão:** a maioria das BAPIs retorna uma tabela `RETURN` com mensagens. Sempre processe essa tabela.

---

## 💻 Código

### Usando BAPI_SALESORDER_CREATEFROMDAT2 — criar pedido de venda

```abap
REPORT z_decoded_bapi_so.

DATA: ls_header    TYPE bapisdhd1,
      ls_headerx   TYPE bapisdhd1x,
      lt_items     TYPE TABLE OF bapisditm,
      lt_itemsx    TYPE TABLE OF bapisditmx,
      lt_partners  TYPE TABLE OF bapiparnr,
      lt_return    TYPE TABLE OF bapiret2,
      ls_item      TYPE bapisditm,
      ls_itemx     TYPE bapisditmx,
      ls_partner   TYPE bapiparnr,
      lv_salesdoc  TYPE bapivbeln-vbeln.

START-OF-SELECTION.

  " Cabeçalho do pedido
  ls_header-doc_type   = 'ZOR'.    " tipo de pedido
  ls_header-sales_org  = '1000'.
  ls_header-distr_chan  = '10'.
  ls_header-division   = '00'.
  ls_header-purch_no_c = 'PO-CLIENTE-001'.

  " Campos que foram preenchidos (X = informado)
  ls_headerx-doc_type   = 'X'.
  ls_headerx-sales_org  = 'X'.
  ls_headerx-distr_chan  = 'X'.
  ls_headerx-division   = 'X'.
  ls_headerx-purch_no_c = 'X'.

  " Parceiros do pedido
  ls_partner-parvw = 'AG'.          " Sold-to
  ls_partner-partn = '0001234567'.
  APPEND ls_partner TO lt_partners.

  ls_partner-parvw = 'WE'.          " Ship-to
  ls_partner-partn = '0001234568'.
  APPEND ls_partner TO lt_partners.

  " Item 1
  ls_item-itm_number  = '000010'.
  ls_item-material    = '000000000000000001'.
  ls_item-target_qty  = '10'.
  ls_item-target_qu   = 'UN'.
  APPEND ls_item TO lt_items.

  ls_itemx-itm_number  = '000010'.
  ls_itemx-material    = 'X'.
  ls_itemx-target_qty  = 'X'.
  ls_itemx-target_qu   = 'X'.
  APPEND ls_itemx TO lt_itemsx.

  " Chama a BAPI
  CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
    EXPORTING
      order_header_in  = ls_header
      order_header_inx = ls_headerx
    IMPORTING
      salesdocument    = lv_salesdoc
    TABLES
      order_items_in   = lt_items
      order_items_inx  = lt_itemsx
      order_partners   = lt_partners
      return           = lt_return.

  " Processa o retorno
  PERFORM processar_retorno_bapi
    USING lt_return lv_salesdoc.

*---------------------------------------------------------------------*
FORM processar_retorno_bapi
  USING pt_return  TYPE TABLE
        pv_docnum  TYPE bapivbeln-vbeln.
*---------------------------------------------------------------------*
  DATA: lv_tem_erro TYPE abap_bool VALUE abap_false.

  LOOP AT pt_return INTO DATA(ls_ret).
    CASE ls_ret-type.
      WHEN 'E' OR 'A'.
        lv_tem_erro = abap_true.
        WRITE: / |❌ Erro: { ls_ret-message }|.
      WHEN 'W'.
        WRITE: / |⚠️  Aviso: { ls_ret-message }|.
      WHEN 'S'.
        WRITE: / |✅ { ls_ret-message }|.
    ENDCASE.
  ENDLOOP.

  IF lv_tem_erro = abap_false AND pv_docnum IS NOT INITIAL.
    COMMIT WORK AND WAIT.
    WRITE: / |Pedido criado: { pv_docnum }|.
  ELSE.
    ROLLBACK WORK.
    WRITE: / 'Pedido NÃO criado — erros encontrados.'.
  ENDIF.
ENDFORM.
```

---

### BAPI_MATERIAL_SAVEDATA — criar/atualizar material

```abap
DATA: ls_headdata     TYPE bapimathead,
      ls_mara_data    TYPE bapi_mara,
      ls_marax_data   TYPE bapi_marax,
      ls_maktx        TYPE bapi_makt,
      lt_materialdesc TYPE TABLE OF bapi_makt,
      lt_return       TYPE TABLE OF bapiret2.

ls_headdata-material    = 'Z-MATERIAL-001'.
ls_headdata-ind_sector  = 'M'.       " setor industrial
ls_headdata-matl_type   = 'FERT'.    " tipo material
ls_headdata-basic_view  = 'X'.       " cria visão básica

ls_mara_data-base_uom   = 'UN'.
ls_mara_data-matl_group = '001'.
ls_marax_data-base_uom  = 'X'.
ls_marax_data-matl_group = 'X'.

ls_maktx-langu      = 'PT'.
ls_maktx-matl_desc  = 'Material de Teste ABAP Decoded'.
APPEND ls_maktx TO lt_materialdesc.

CALL FUNCTION 'BAPI_MATERIAL_SAVEDATA'
  EXPORTING
    headdata     = ls_headdata
    clientdata   = ls_mara_data
    clientdatax  = ls_marax_data
  TABLES
    materialdescription = lt_materialdesc
    return              = lt_return.

" Verifica erros e commita
LOOP AT lt_return INTO DATA(ls_r) WHERE type = 'E' OR type = 'A'.
  WRITE: / |Erro: { ls_r-message }|.
ENDLOOP.

IF sy-subrc <> 0.  " sy-subrc do LOOP = nenhum erro encontrado
  COMMIT WORK AND WAIT.
  WRITE: / 'Material criado/atualizado.'.
ELSE.
  ROLLBACK WORK.
ENDIF.
```

---

### BAPIs mais usadas — referência rápida

```abap
" Clientes
BAPI_CUSTOMER_GETDETAIL    " ler dados de cliente
BAPI_CUSTOMER_CREATEFROMDATA1  " criar cliente

" Materiais
BAPI_MATERIAL_GET_DETAIL   " ler material
BAPI_MATERIAL_SAVEDATA     " criar/atualizar material

" Pedidos de Venda
BAPI_SALESORDER_CREATEFROMDAT2  " criar pedido
BAPI_SALESORDER_GETDETAILX      " ler pedido
BAPI_SALESORDER_CHANGE          " alterar pedido

" Pedidos de Compra
BAPI_PO_CREATE1            " criar PO
BAPI_PO_CHANGE             " alterar PO
BAPI_PO_GETDETAIL          " ler PO

" Estoque
BAPI_GOODSMVT_CREATE       " movimento de mercadoria (301, 311, 601...)

" Financeiro
BAPI_ACC_DOCUMENT_POST     " postar documento contábil
```

---

## ⚠️ Pegadinhas

**1. COMMIT WORK AND WAIT vs COMMIT WORK**
```abap
" COMMIT WORK         — dispara o commit e segue imediatamente
" COMMIT WORK AND WAIT — espera o commit completar antes de continuar
" Para BAPIs: sempre use AND WAIT para garantir que o documento foi gravado
```

**2. A tabela RETURN não é suficiente — verifique type 'E' e 'A'**
```abap
" Type 'S' = Success, 'W' = Warning, 'E' = Error, 'A' = Abort
" A BAPI pode retornar 'S' com 'W' misturado e o documento foi criado
" A BAPI pode retornar 'W' sem 'E' e o documento foi criado com avisos
" NUNCA cheque apenas sy-subrc — processe a tabela RETURN
```

**3. Campos X (update flags)**
```abap
" Estruturas com sufixo X (bapisdhd1x, bapisditmx...) controlam o que será atualizado
" Se o campo do X não estiver marcado, o campo correspondente é IGNORADO
" Isso é especialmente crítico em updates — se esquecer o X, o campo não muda
```

---

## 🏋️ Exercício

1. Use o BAPI Explorer (`BAPI`) para localizar a BAPI de criação de Delivery
2. Crie um programa que usa `BAPI_SALESORDER_GETDETAILX` para ler um pedido existente e exibe:
   - Dados do cabeçalho (cliente, data, valor total)
   - Lista de itens (material, quantidade, unidade, valor)
   - Mensagens de retorno
3. **Desafio:** adicione um botão no ALV que chama `BAPI_SALESORDER_CHANGE` para bloquear o pedido selecionado (com confirmação via popup)

---

⬅️ [01 — RFC Destinos](./01-rfc-destinos.md) | ➡️ [Módulo 07 — Reports & ALV](../07-reports-alv/README.md)
