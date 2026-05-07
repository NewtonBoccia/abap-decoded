# 01 — Fiori & RAP: Conceitos e Primeiro App

## 📖 Conceito

O RAP segue uma arquitetura em camadas:

```
┌──────────────────────────────────────────────────┐
│  Fiori Elements App (UI gerada automaticamente)  │
├──────────────────────────────────────────────────┤
│  OData Service (Service Binding)                 │
├──────────────────────────────────────────────────┤
│  Behavior (BDEF + ABAP Implementation)           │
│  • Create / Update / Delete / Actions            │
│  • Validations / Determinations                  │
├──────────────────────────────────────────────────┤
│  CDS View com anotações @UI (Projection View)    │
├──────────────────────────────────────────────────┤
│  CDS View Base (dados do banco)                  │
└──────────────────────────────────────────────────┘
```

Tudo criado no **ADT (ABAP Development Tools)** — Eclipse plugin da SAP.

---

## 💻 Código

### 1. CDS View Base — os dados

```abap
@AbapCatalog.sqlViewName: 'ZV_PEDIDO_B'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Pedidos Base'
define root view entity Z_C_PEDIDO_BASE
  as select from vbak
{
  key vbeln  as NumeroPedido,
      kunnr  as Cliente,
      erdat  as DataCriacao,
      netwr  as ValorLiquido,
      waerk  as Moeda,
      gbsta  as StatusGeral
}
```

---

### 2. CDS Projection View — anotações UI

```abap
@EndUserText.label: 'Pedidos de Venda'
@AccessControl.authorizationCheck: #NOT_REQUIRED

@UI.headerInfo: {
  typeName:       'Pedido',
  typeNamePlural: 'Pedidos',
  title:          { type: #STANDARD, value: 'NumeroPedido' }
}

define root view entity Z_C_PEDIDO
  provider contract transactional_query
  as projection on Z_C_PEDIDO_BASE
{
  @UI.facet: [{ id: 'General', type: #IDENTIFICATION_REFERENCE,
                label: 'Geral', position: 10 }]

  @UI.lineItem:       [{ position: 10, importance: #HIGH }]
  @UI.identification: [{ position: 10 }]
  @UI.selectionField: [{ position: 10 }]
  key NumeroPedido,

  @UI.lineItem:       [{ position: 20 }]
  @UI.identification: [{ position: 20 }]
  @UI.selectionField: [{ position: 20 }]
  Cliente,

  @UI.lineItem: [{ position: 30 }]
  DataCriacao,

  @UI.lineItem: [{ position: 40, importance: #HIGH }]
  @Semantics.amount.currencyCode: 'Moeda'
  ValorLiquido,

  @Semantics.currencyCode: true
  Moeda
}
```

---

### 3. Behavior Definition (BDEF)

```abap
" Arquivo: Z_C_PEDIDO (tipo BDEF no ADT)
managed implementation in class zbp_c_pedido unique;
strict ( 2 );

define behavior for Z_C_PEDIDO alias Pedido
persistent table vbak
lock master
authorization master ( instance )
{
  " Operações CRUD
  create;
  update;
  delete;

  " Campo de controlo de edição
  field ( readonly ) NumeroPedido;

  " Ação customizada
  action ( features : instance ) cancelar result [1] $self;

  " Validação
  validation validarCliente on save { create; update; }

  " Determinação automática
  determination preencherData on modify { create; }

  mapping for vbak {
    NumeroPedido = vbeln;
    Cliente      = kunnr;
    DataCriacao  = erdat;
    ValorLiquido = netwr;
    Moeda        = waerk;
  }
}
```

---

### 4. Behavior Implementation (ABAP Class)

```abap
CLASS zbp_c_pedido DEFINITION PUBLIC ABSTRACT FINAL
  FOR BEHAVIOR OF z_c_pedido.
ENDCLASS.

CLASS zbp_c_pedido IMPLEMENTATION.
ENDCLASS.

" Local class dentro do arquivo de implementação:
CLASS lhc_pedido DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      validar_cliente FOR VALIDATE ON SAVE
        IMPORTING keys FOR pedido~validarCliente,

      preencher_data FOR DETERMINE ON MODIFY
        IMPORTING keys FOR pedido~preencherData,

      cancelar FOR MODIFY
        IMPORTING keys FOR ACTION pedido~cancelar RESULT result.
ENDCLASS.

CLASS lhc_pedido IMPLEMENTATION.

  METHOD validar_cliente.
    " Lê os dados dos pedidos sendo criados/alterados
    READ ENTITIES OF z_c_pedido IN LOCAL MODE
      ENTITY pedido
      FIELDS ( cliente )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_pedidos).

    LOOP AT lt_pedidos INTO DATA(ls).
      " Verifica se o cliente existe
      SELECT SINGLE kunnr FROM kna1 WHERE kunnr = @ls-cliente
        INTO @DATA(lv_kunnr).

      IF sy-subrc <> 0.
        APPEND VALUE #(
          %tky        = ls-%tky
          %state_area = 'VALIDATE_CLIENTE'
        ) TO failed-pedido.

        APPEND VALUE #(
          %tky     = ls-%tky
          %msg     = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Cliente { ls-cliente } não encontrado| )
          %element-cliente = if_abap_behv=>mk-on
        ) TO reported-pedido.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD preencher_data.
    MODIFY ENTITIES OF z_c_pedido IN LOCAL MODE
      ENTITY pedido
      UPDATE FIELDS ( datacriacao )
      WITH VALUE #( FOR key IN keys (
        %tky        = key-%tky
        datacriacao = cl_abap_context_info=>get_system_date( )
      ) ).
  ENDMETHOD.

  METHOD cancelar.
    " Lógica de cancelamento customizada
    READ ENTITIES OF z_c_pedido IN LOCAL MODE
      ENTITY pedido ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_pedidos).

    " ... processa cancelamento

    result = VALUE #( FOR ls IN lt_pedidos (
      %tky = ls-%tky
      %param = ls
    ) ).
  ENDMETHOD.

ENDCLASS.
```

---

### 5. Service Definition e Binding

```abap
" Service Definition (arquivo SRVD no ADT):
@EndUserText.label: 'Serviço de Pedidos'
define service Z_SRV_PEDIDOS {
  expose Z_C_PEDIDO as Pedido;
}

" Service Binding (arquivo SRVB no ADT):
" Criar um OData V4 UI binding apontando para Z_SRV_PEDIDOS
" Publicar e testar no Fiori Launchpad
```

---

## ⚠️ Pegadinhas

**1. RAP requer ABAP 7.54+ / SAP S/4HANA 1909+**
```abap
" RAP não funciona em sistemas SAP ECC. Verifique a versão antes de começar.
" Em ECC: use o modelo clássico (BAPIs + Dynpro ou Web Dynpro)
```

**2. CDS View precisa ter exatamente uma chave primária marcada**
```abap
" define root view entity sem `key` no campo → erro de ativação
" A entidade RAP precisa de pelo menos um campo marcado com `key`
```

**3. Behavior Implementation — classe ABSTRACT FINAL**
```abap
" A classe principal do BDEF (zbp_c_pedido) é ABSTRACT FINAL
" A implementação real fica nas local classes dentro do arquivo .abap
" Não adicione métodos diretamente na classe principal
```

---

## 🏋️ Exercício

Crie um app RAP completo `Z_DECODED_PRODUTOS`:

1. **CDS Base**: selecione `MARA` com campos: `MATNR`, `MTART`, `MEINS`, `MATKL`
2. **CDS Projection**: adicione anotações `@UI.lineItem` e `@UI.selectionField` para os campos
3. **BDEF**: defina create, update, delete e uma ação `bloquear`
4. **Implementação**: valide que o tipo de material (`MTART`) é válido buscando em `T134`
5. **Service**: publique e acesse via Fiori Launchpad (ou Business Application Studio)

**Recursos:** Use o [SAP Learning Journey: ABAP RESTful Application Programming Model](https://learning.sap.com) para os passos de publicação no BAS.

---

⬅️ [README](./README.md) | 🏁 Parabéns — você chegou ao fim do ABAP Decoded!
