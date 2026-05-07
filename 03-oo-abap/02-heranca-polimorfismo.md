# 02 — Herança e Polimorfismo

## 📖 Conceito

**Herança** permite que uma classe filha herde atributos e métodos da classe pai, adicionando ou sobrescrevendo comportamento.  
**Polimorfismo** permite tratar objetos de classes diferentes de forma uniforme, desde que compartilhem uma classe pai ou interface.

Em ABAP: `INHERITING FROM` para herdar, `REDEFINITION` para sobrescrever.

---

## 💻 Código

### Herança básica

```abap
REPORT z_decoded_oo_02.

"======================================================================
" Classe base (pai)
"======================================================================
CLASS lcl_documento DEFINITION.
  PUBLIC SECTION.
    DATA: mv_numero TYPE string READ-ONLY,
          mv_data   TYPE d      READ-ONLY.

    METHODS:
      constructor
        IMPORTING iv_numero TYPE string,
      exibir,
      calcular_imposto
        RETURNING VALUE(rv_imposto) TYPE p.

  PROTECTED SECTION.
    DATA: mv_valor TYPE p DECIMALS 2.
ENDCLASS.

CLASS lcl_documento IMPLEMENTATION.
  METHOD constructor.
    mv_numero = iv_numero.
    mv_data   = sy-datum.
  ENDMETHOD.

  METHOD exibir.
    WRITE: / |Doc: { mv_numero } | Data: { mv_data } | Valor: { mv_valor }|.
  ENDMETHOD.

  METHOD calcular_imposto.
    rv_imposto = mv_valor * '0.12'.  " 12% genérico
  ENDMETHOD.
ENDCLASS.

"======================================================================
" Classe filha — Nota Fiscal
"======================================================================
CLASS lcl_nota_fiscal DEFINITION INHERITING FROM lcl_documento.
  PUBLIC SECTION.
    DATA: mv_cnpj_emitente TYPE string READ-ONLY.

    METHODS:
      constructor
        IMPORTING iv_numero TYPE string
                  iv_cnpj   TYPE string
                  iv_valor  TYPE p,

      " Sobrescreve o método do pai
      calcular_imposto REDEFINITION.
ENDCLASS.

CLASS lcl_nota_fiscal IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_numero ).   " chama construtor do pai
    mv_cnpj_emitente = iv_cnpj.
    mv_valor         = iv_valor.
  ENDMETHOD.

  METHOD calcular_imposto.
    " NF tem alíquota diferente — 18% (ICMS simplificado)
    rv_imposto = mv_valor * '0.18'.
  ENDMETHOD.
ENDCLASS.

"======================================================================
" Classe filha — Pedido de Compra
"======================================================================
CLASS lcl_pedido_compra DEFINITION INHERITING FROM lcl_documento.
  PUBLIC SECTION.
    DATA: mv_fornecedor TYPE string READ-ONLY.

    METHODS:
      constructor
        IMPORTING iv_numero     TYPE string
                  iv_fornecedor TYPE string
                  iv_valor      TYPE p,
      calcular_imposto REDEFINITION.
ENDCLASS.

CLASS lcl_pedido_compra IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_numero ).
    mv_fornecedor = iv_fornecedor.
    mv_valor      = iv_valor.
  ENDMETHOD.

  METHOD calcular_imposto.
    rv_imposto = 0.  " compra interna sem imposto direto
  ENDMETHOD.
ENDCLASS.
```

---

### Polimorfismo — tratando objetos diferentes de forma uniforme

```abap
START-OF-SELECTION.

  " Tabela de referências para a classe PAI
  DATA: lt_docs TYPE TABLE OF REF TO lcl_documento,
        lo_doc  TYPE REF TO lcl_documento.

  " Adiciona instâncias de classes FILHAS
  APPEND NEW lcl_nota_fiscal(
    iv_numero = 'NF-001'
    iv_cnpj   = '12345678000195'
    iv_valor  = '10000.00'
  ) TO lt_docs.

  APPEND NEW lcl_pedido_compra(
    iv_numero     = 'PC-001'
    iv_fornecedor = 'Fornecedor X'
    iv_valor      = '5000.00'
  ) TO lt_docs.

  " Loop polimórfico — chama o método certo de cada objeto
  LOOP AT lt_docs INTO lo_doc.
    lo_doc->exibir( ).
    DATA(lv_imposto) = lo_doc->calcular_imposto( ).
    WRITE: / |  Imposto: R$ { lv_imposto }|.
  ENDLOOP.
```

---

### CAST — verificando e convertendo tipos em runtime

```abap
  " Descobrir o tipo real do objeto em tempo de execução
  LOOP AT lt_docs INTO lo_doc.

    " Tenta fazer cast para NF — se não for NF, lança exceção
    TRY.
      DATA(lo_nf) = CAST lcl_nota_fiscal( lo_doc ).
      WRITE: / |NF com CNPJ: { lo_nf->mv_cnpj_emitente }|.
    CATCH cx_sy_move_cast_error.
      " não é nota fiscal — tudo bem, segue em frente
    ENDTRY.

    " Forma mais limpa — verifica antes de fazer cast
    IF lo_doc IS INSTANCE OF lcl_nota_fiscal.
      DATA(lo_nf2) = CAST lcl_nota_fiscal( lo_doc ).
      WRITE: / |CNPJ: { lo_nf2->mv_cnpj_emitente }|.
    ENDIF.

  ENDLOOP.
```

---

## ⚠️ Pegadinhas

**1. Esquecer `super->constructor` no construtor filho**
```abap
" Se o pai tem lógica de inicialização no constructor,
" o filho PRECISA chamar super->constructor — senão atributos herdados ficam vazios
METHOD constructor.
  super->constructor( iv_numero ).  " ← sempre que o pai tem constructor
  " ... inicialização específica do filho
ENDMETHOD.
```

**2. Acesso a atributo PROTECTED do pai**
```abap
" PROTECTED = acessível na classe filho. PRIVATE = NÃO acessível.
" mv_valor está em PROTECTED SECTION do pai — filho pode acessar
" Se fosse PRIVATE SECTION, o filho não enxerga e precisa de getter/setter
```

**3. REDEFINITION de método FINAL — erro de compilação**
```abap
" Método marcado como FINAL não pode ser sobrescrito
CLASS lcl_base DEFINITION.
  PUBLIC SECTION.
    METHODS calcular FINAL  " ← filho não pode redefine isso
      RETURNING VALUE(rv_x) TYPE i.
ENDCLASS.
```

---

## 🏋️ Exercício

Crie uma hierarquia de classes para representar meios de pagamento:

1. **`LCL_PAGAMENTO`** (base): atributos `mv_valor`, `mv_data`; método `processar( )` que imprime "Processando pagamento"
2. **`LCL_BOLETO`** (herda de LCL_PAGAMENTO): adiciona `mv_codigo_barras`, redefine `processar` para imprimir o código de barras
3. **`LCL_PIX`** (herda de LCL_PAGAMENTO): adiciona `mv_chave_pix`, redefine `processar` para imprimir a chave
4. Crie uma tabela com 3 pagamentos mistos e processe todos com um LOOP polimórfico

---

⬅️ [01 — Classes e Objetos](./01-classes-objetos.md) | ➡️ [03 — Interfaces](./03-interfaces.md)
