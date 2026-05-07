# 01 — Classes e Objetos

## 📖 Conceito

Uma **classe** define a estrutura (atributos) e o comportamento (métodos) de um objeto. Um **objeto** é uma instância dessa classe em memória.

Em ABAP OO você pode criar classes de dois jeitos:
- **Local class** — dentro do próprio programa (começa com `LCL_`)
- **Global class** — no repositório, reutilizável entre programas, criada via SE24 (começa com `ZCL_`)

Visibilidades:
- `PUBLIC` — acessível por qualquer código
- `PROTECTED` — acessível pela própria classe e subclasses
- `PRIVATE` — acessível apenas pela própria classe

---

## 💻 Código

### Classe local — estrutura básica

```abap
REPORT z_decoded_oo_01.

"======================================================================
" Definição da classe
"======================================================================
CLASS lcl_pedido DEFINITION.
  PUBLIC SECTION.
    DATA: mv_numero  TYPE vbeln READ-ONLY,
          mv_cliente TYPE kunnr READ-ONLY,
          mv_valor   TYPE netwr READ-ONLY.

    METHODS:
      constructor
        IMPORTING iv_numero  TYPE vbeln
                  iv_cliente TYPE kunnr
                  iv_valor   TYPE netwr,

      exibir,

      calcular_desconto
        IMPORTING iv_pct       TYPE p
        RETURNING VALUE(rv_total) TYPE netwr.

  PRIVATE SECTION.
    DATA: mv_criado_em TYPE d.
ENDCLASS.

"======================================================================
" Implementação da classe
"======================================================================
CLASS lcl_pedido IMPLEMENTATION.

  METHOD constructor.
    mv_numero   = iv_numero.
    mv_cliente  = iv_cliente.
    mv_valor    = iv_valor.
    mv_criado_em = sy-datum.
  ENDMETHOD.

  METHOD exibir.
    WRITE: / |Pedido: { mv_numero } | Cliente: { mv_cliente } | Valor: R$ { mv_valor }|.
  ENDMETHOD.

  METHOD calcular_desconto.
    rv_total = mv_valor - ( mv_valor * iv_pct / 100 ).
  ENDMETHOD.

ENDCLASS.

"======================================================================
" Programa principal
"======================================================================
START-OF-SELECTION.
  DATA: lo_pedido TYPE REF TO lcl_pedido.

  " Cria objeto com NEW (ABAP 7.4+)
  lo_pedido = NEW lcl_pedido(
    iv_numero  = '0000012345'
    iv_cliente = '0001234567'
    iv_valor   = '5000.00'
  ).

  lo_pedido->exibir( ).

  DATA(lv_com_desconto) = lo_pedido->calcular_desconto( iv_pct = 15 ).
  WRITE: / |Com 15% desconto: R$ { lv_com_desconto }|.
```

---

### Métodos estáticos (CLASS-METHODS) — sem instanciar objeto

```abap
CLASS lcl_util DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      formatar_cpf
        IMPORTING iv_cpf        TYPE string
        RETURNING VALUE(rv_fmt) TYPE string,

      validar_cnpj
        IMPORTING iv_cnpj        TYPE string
        RETURNING VALUE(rv_ok)   TYPE abap_bool.
ENDCLASS.

CLASS lcl_util IMPLEMENTATION.

  METHOD formatar_cpf.
    " 12345678901 → 123.456.789-01
    IF strlen( iv_cpf ) <> 11.
      rv_fmt = iv_cpf.
      RETURN.
    ENDIF.
    rv_fmt = iv_cpf(3) && '.' && iv_cpf+3(3) && '.' &&
             iv_cpf+6(3) && '-' && iv_cpf+9(2).
  ENDMETHOD.

  METHOD validar_cnpj.
    rv_ok = xsdbool( strlen( iv_cnpj ) = 14 ).
    " validação real requer dígitos verificadores — simplificado aqui
  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.
  " Chama sem instanciar — direto na classe
  DATA(lv_cpf) = lcl_util=>formatar_cpf( iv_cpf = '12345678901' ).
  WRITE: / |CPF: { lv_cpf }|.

  DATA(lv_ok) = lcl_util=>validar_cnpj( iv_cnpj = '12345678000195' ).
  WRITE: / |CNPJ válido: { lv_ok }|.
```

---

### Encadeamento de chamadas (method chaining)

```abap
CLASS lcl_builder DEFINITION.
  PUBLIC SECTION.
    METHODS:
      set_numero
        IMPORTING iv_num TYPE vbeln
        RETURNING VALUE(ro_self) TYPE REF TO lcl_builder,
      set_cliente
        IMPORTING iv_cli TYPE kunnr
        RETURNING VALUE(ro_self) TYPE REF TO lcl_builder,
      build
        RETURNING VALUE(ro_pedido) TYPE REF TO lcl_pedido.

  PRIVATE SECTION.
    DATA: mv_num TYPE vbeln,
          mv_cli TYPE kunnr.
ENDCLASS.

CLASS lcl_builder IMPLEMENTATION.
  METHOD set_numero.
    mv_num  = iv_num.
    ro_self = me.  " me = referência ao objeto atual (como 'this')
  ENDMETHOD.

  METHOD set_cliente.
    mv_cli  = iv_cli.
    ro_self = me.
  ENDMETHOD.

  METHOD build.
    ro_pedido = NEW lcl_pedido(
      iv_numero  = mv_num
      iv_cliente = mv_cli
      iv_valor   = 0
    ).
  ENDMETHOD.
ENDCLASS.

" Uso com chaining
DATA(lo_pedido2) = NEW lcl_builder(
  )->set_numero( '0000099999'
  )->set_cliente( '0000000001'
  )->build( ).
```

---

## ⚠️ Pegadinhas

**1. Acesso a atributo de referência nula — dump MOVE_CAST_ERROR**
```abap
DATA: lo_pedido TYPE REF TO lcl_pedido.
" lo_pedido é INITIAL (null) aqui
lo_pedido->exibir( ).  " DUMP: Access to a null object reference

" Sempre verifique antes de usar:
IF lo_pedido IS BOUND.
  lo_pedido->exibir( ).
ENDIF.
```

**2. READ-ONLY não impede mudança dentro da classe**
```abap
" READ-ONLY na PUBLIC SECTION só impede acesso externo
" Dentro da própria classe, você pode alterar livremente
METHOD alterar_interno.
  mv_numero = 'NOVO'.  " OK dentro da classe
ENDMETHOD.
```

**3. `me->` vs. acesso direto**
```abap
" Dentro de um método, 'me' é a referência ao objeto atual
" me->mv_numero e mv_numero são a mesma coisa dentro da classe
" Use me-> quando precisar passar o próprio objeto como parâmetro
```

---

## 🏋️ Exercício

Crie uma classe `LCL_PRODUTO` com:
1. Atributos: `mv_codigo`, `mv_descricao`, `mv_preco`, `mv_estoque` (READ-ONLY)
2. `constructor` que inicializa todos os atributos
3. Método `aplicar_reajuste( iv_pct )` que aumenta o preço
4. Método `dar_entrada( iv_qtd )` que incrementa o estoque
5. Método estático `criar_sem_estoque( iv_codigo, iv_descricao, iv_preco )` que retorna um objeto com estoque 0
6. Método `exibir` que imprime todos os atributos formatados

---

⬅️ [README do módulo](./README.md) | ➡️ [02 — Herança e Polimorfismo](./02-heranca-polimorfismo.md)
