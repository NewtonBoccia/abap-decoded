# 03 — Interfaces

## 📖 Conceito

Uma **interface** define um contrato — métodos que qualquer classe que a implemente é obrigada a fornecer. Diferente de herança (1 pai), uma classe pode implementar **múltiplas interfaces**.

Em ABAP, interfaces são a base de:
- **BAdIs** (Business Add-Ins) — pontos de extensão do SAP que você implementa
- **AMDP** — classes com código CDS/HANA embutido
- **RAP** — Restful ABAP Programming Model

---

## 💻 Código

### Definindo e implementando uma interface

```abap
REPORT z_decoded_oo_03.

"======================================================================
" Interface — define o contrato
"======================================================================
INTERFACE lif_exportavel.
  METHODS:
    exportar_csv
      RETURNING VALUE(rv_csv) TYPE string,
    exportar_json
      RETURNING VALUE(rv_json) TYPE string.
ENDINTERFACE.

INTERFACE lif_validavel.
  METHODS:
    validar
      RETURNING VALUE(rv_ok)    TYPE abap_bool
      RAISING   cx_sy_conversion_error.
ENDINTERFACE.

"======================================================================
" Classe que implementa DUAS interfaces
"======================================================================
CLASS lcl_pedido DEFINITION.
  PUBLIC SECTION.
    INTERFACES: lif_exportavel,
                lif_validavel.

    DATA: mv_numero TYPE string,
          mv_valor  TYPE p DECIMALS 2.

    METHODS constructor
      IMPORTING iv_numero TYPE string
                iv_valor  TYPE p.
ENDCLASS.

CLASS lcl_pedido IMPLEMENTATION.

  METHOD constructor.
    mv_numero = iv_numero.
    mv_valor  = iv_valor.
  ENDMETHOD.

  " Implementação dos métodos da interface — prefixo é o nome da interface
  METHOD lif_exportavel~exportar_csv.
    rv_csv = |{ mv_numero };{ mv_valor }|.
  ENDMETHOD.

  METHOD lif_exportavel~exportar_json.
    rv_json = |\{"numero":"{ mv_numero }","valor":{ mv_valor }\}|.
  ENDMETHOD.

  METHOD lif_validavel~validar.
    rv_ok = xsdbool( mv_numero IS NOT INITIAL AND mv_valor > 0 ).
  ENDMETHOD.

ENDCLASS.
```

---

### Usando a interface como tipo (polimorfismo)

```abap
START-OF-SELECTION.

  DATA: lo_ref_export TYPE REF TO lif_exportavel,
        lo_pedido     TYPE REF TO lcl_pedido.

  lo_pedido = NEW lcl_pedido( iv_numero = 'PED-001' iv_valor = '1500.00' ).

  " Trata o objeto como lif_exportavel — só enxerga métodos da interface
  lo_ref_export = lo_pedido.
  WRITE: / lo_ref_export->lif_exportavel~exportar_csv( ).
  WRITE: / lo_ref_export->lif_exportavel~exportar_json( ).

  " Validação via interface
  DATA: lo_val TYPE REF TO lif_validavel.
  lo_val = lo_pedido.
  TRY.
    IF lo_val->lif_validavel~validar( ).
      WRITE: / 'Pedido válido.'.
    ELSE.
      WRITE: / 'Pedido inválido.'.
    ENDIF.
  CATCH cx_sy_conversion_error INTO DATA(lo_err).
    WRITE: / |Erro de validação: { lo_err->get_text( ) }|.
  ENDTRY.
```

---

### Aliases — simplificando o acesso à interface

```abap
CLASS lcl_nf DEFINITION.
  PUBLIC SECTION.
    INTERFACES lif_exportavel.

    " Alias: exportar_csv → lif_exportavel~exportar_csv
    ALIASES: exportar_csv  FOR lif_exportavel~exportar_csv,
             exportar_json FOR lif_exportavel~exportar_json.
ENDCLASS.

CLASS lcl_nf IMPLEMENTATION.
  METHOD lif_exportavel~exportar_csv.
    rv_csv = 'nota_fiscal_csv'.
  ENDMETHOD.
  METHOD lif_exportavel~exportar_json.
    rv_json = '\{"tipo":"NF"\}'.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  DATA(lo_nf) = NEW lcl_nf( ).
  " Com alias, chama direto sem o prefixo da interface
  WRITE: / lo_nf->exportar_csv( ).
```

---

### Interfaces na prática — BAdI

```abap
" Exemplo de como um BAdI funciona (código conceitual)
" Na transação SE19, você implementa a interface do BAdI

" A SAP define a interface (você não altera):
INTERFACE if_badi_meu_exit.
  METHODS executar
    IMPORTING iv_matnr TYPE matnr
    CHANGING  ct_dados TYPE tt_meus_dados.
ENDINTERFACE.

" Você cria a implementação:
CLASS zcl_impl_meu_exit DEFINITION.
  PUBLIC SECTION.
    INTERFACES if_badi_meu_exit.
ENDCLASS.

CLASS zcl_impl_meu_exit IMPLEMENTATION.
  METHOD if_badi_meu_exit~executar.
    " Sua lógica de extensão aqui
    " O SAP chama automaticamente quando o ponto de exit é alcançado
    LOOP AT ct_dados ASSIGNING FIELD-SYMBOL(<ls>).
      " processar...
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
```

---

## ⚠️ Pegadinhas

**1. Constante em interface — disponível para todos que implementam**
```abap
INTERFACE lif_status.
  CONSTANTS: gc_aberto    TYPE c LENGTH 1 VALUE 'A',
             gc_fechado   TYPE c LENGTH 1 VALUE 'F'.
  METHODS processar.
ENDINTERFACE.

" Classe que implementa pode acessar as constantes:
CLASS lcl_doc DEFINITION.
  PUBLIC SECTION.
    INTERFACES lif_status.
ENDCLASS.

" Uso:
IF ls_status = lif_status=>gc_aberto.  " acessa via interface=>constante
```

**2. Modificar interface existente quebra todas as implementações**
```abap
" Se você adicionar um novo método a uma interface,
" TODAS as classes que a implementam precisam implementar o novo método.
" Em sistemas em produção, prefira criar uma nova interface ao invés de modificar.
```

---

## 🏋️ Exercício

Crie uma interface `LIF_NOTIFICAVEL` com métodos:
- `notificar_email( iv_destinatario TYPE string iv_mensagem TYPE string )`
- `notificar_log( iv_mensagem TYPE string )`

Implemente em duas classes:
1. `LCL_NOTIF_CONSOLE` — imprime na tela com WRITE
2. `LCL_NOTIF_TABELA` — salva em uma tabela interna `lt_log`

Crie um programa que: dependendo de um parâmetro de seleção, usa uma implementação ou outra — sem mudar o código que chama.

---

⬅️ [02 — Herança e Polimorfismo](./02-heranca-polimorfismo.md) | ➡️ [04 — Exceções OO](./04-excecoes-oo.md)
