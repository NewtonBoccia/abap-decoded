# 04 — Exceções OO (TRY/CATCH)

## 📖 Conceito

ABAP moderno usa exceções baseadas em classes — muito mais expressivas que o antigo `sy-subrc`. O mecanismo é `TRY / CATCH / CLEANUP / ENDTRY`.

Hierarquia de classes de exceção:
```
CX_ROOT
├── CX_STATIC_CHECK   — verificada em compilação (o caller é obrigado a tratar)
├── CX_DYNAMIC_CHECK  — verificada em runtime
└── CX_NO_CHECK       — não precisa declarar no raising
```

Você cria suas próprias exceções herdando de uma dessas três.

---

## 💻 Código

### TRY/CATCH básico

```abap
REPORT z_decoded_oo_04.

DATA: lv_divisor TYPE i VALUE 0,
      lv_result  TYPE i.

TRY.
  lv_result = 10 / lv_divisor.
  WRITE: / |Resultado: { lv_result }|.

CATCH cx_sy_zerodivide INTO DATA(lo_ex).
  WRITE: / |Erro: divisão por zero — { lo_ex->get_text( ) }|.

CATCH cx_root INTO DATA(lo_qualquer).
  " Pega qualquer exceção não tratada acima
  WRITE: / |Erro inesperado: { lo_qualquer->get_text( ) }|.

ENDTRY.
```

---

### Criando sua própria exceção

No SE24, crie `ZCX_PEDIDO_INVALIDO` herdando de `CX_STATIC_CHECK`.

Adicione um atributo `MV_NUMERO TYPE VBELN` e um construtor que aceita o número.

```abap
" Implementação da classe de exceção (SE24):
CLASS zcx_pedido_invalido DEFINITION
  INHERITING FROM cx_static_check
  FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    DATA: mv_numero TYPE vbeln.

    METHODS constructor
      IMPORTING iv_numero TYPE vbeln
                textid    LIKE textid    OPTIONAL
                previous  LIKE previous  OPTIONAL.
ENDCLASS.

CLASS zcx_pedido_invalido IMPLEMENTATION.
  METHOD constructor.
    super->constructor( textid = textid previous = previous ).
    mv_numero = iv_numero.
  ENDMETHOD.
ENDCLASS.
```

---

### Usando a exceção customizada

```abap
CLASS lcl_processador DEFINITION.
  PUBLIC SECTION.
    METHODS processar_pedido
      IMPORTING iv_numero TYPE vbeln
      RAISING   zcx_pedido_invalido.
ENDCLASS.

CLASS lcl_processador IMPLEMENTATION.
  METHOD processar_pedido.
    IF iv_numero IS INITIAL.
      RAISE EXCEPTION TYPE zcx_pedido_invalido
        EXPORTING iv_numero = iv_numero.
    ENDIF.
    " processamento normal...
    WRITE: / |Processando { iv_numero }|.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  DATA: lo_proc TYPE REF TO lcl_processador.
  lo_proc = NEW lcl_processador( ).

  TRY.
    lo_proc->processar_pedido( iv_numero = '' ).

  CATCH zcx_pedido_invalido INTO DATA(lo_err).
    WRITE: / |Pedido inválido: { lo_err->mv_numero }|.
  ENDTRY.
```

---

### CLEANUP — executado sempre, mesmo com exceção

```abap
DATA: lo_arquivo TYPE REF TO cl_gui_frontend_services.

TRY.
  " abre recurso...
  " processa...
  RAISE EXCEPTION TYPE cx_sy_file_open.  " simula erro

CATCH cx_sy_file_open INTO DATA(lo_file_err).
  WRITE: / 'Erro ao abrir arquivo'.

CLEANUP.
  " Sempre executado — ideal para liberar recursos
  " (fechar arquivo, deletar lock, etc.)
  WRITE: / 'Limpeza executada'.

ENDTRY.
```

---

### Exceções encadeadas (PREVIOUS)

```abap
TRY.
  TRY.
    " operação de baixo nível
    RAISE EXCEPTION TYPE cx_sy_zerodivide.
  CATCH cx_sy_zerodivide INTO DATA(lo_low).
    " re-lança como exceção de negócio, mantendo a causa original
    RAISE EXCEPTION TYPE zcx_pedido_invalido
      EXPORTING
        iv_numero = '0000012345'
        previous  = lo_low.    " ← encadeia a exceção original
  ENDTRY.

CATCH zcx_pedido_invalido INTO DATA(lo_biz).
  WRITE: / |Erro negócio: { lo_biz->get_text( ) }|.
  " Navega pela cadeia de causas
  DATA(lo_prev) = lo_biz->previous.
  IF lo_prev IS BOUND.
    WRITE: / |Causa: { lo_prev->get_text( ) }|.
  ENDIF.
ENDTRY.
```

---

## ⚠️ Pegadinhas

**1. CX_STATIC_CHECK — você é obrigado a declarar no RAISING**
```abap
" Se sua exceção herda de CX_STATIC_CHECK, o método que faz RAISE
" precisa declarar RAISING, e quem chama precisa ter TRY/CATCH.
" Isso é uma garantia em compilação — muito melhor que sy-subrc ignorado.
```

**2. CATCH sem INTO — exceção é tratada mas não acessível**
```abap
CATCH cx_root.
  " Aqui você não tem acesso ao objeto da exceção
  " Bom para ignorar, ruim para logar o erro real
  " Prefira: CATCH cx_root INTO DATA(lo_err).
```

**3. Nunca faça CATCH cx_root para esconder todos os erros**
```abap
" Isso é o goto do tratamento de exceções:
TRY.
  " código perigoso
CATCH cx_root.
  " silencia TUDO — bugs ficam invisíveis
ENDTRY.
" Se precisar pegar tudo, ao menos logue: MESSAGE lo_err->get_text( ) TYPE 'W'.
```

---

## 🏋️ Exercício

1. Crie a classe de exceção `ZCX_VALIDACAO` (herdando de `CX_STATIC_CHECK`) com um atributo `mv_campo TYPE string` e `mv_motivo TYPE string`
2. Crie uma classe `LCL_VALIDADOR` com método `validar_email( iv_email )` que lança `ZCX_VALIDACAO` se o e-mail não contiver `@`
3. Crie um programa que chama `validar_email` com 3 e-mails (2 válidos, 1 inválido) dentro de um loop, capturando e imprimindo os erros sem interromper o processamento dos outros

---

⬅️ [03 — Interfaces](./03-interfaces.md) | ➡️ [Módulo 04 — Banco de Dados](../04-banco-de-dados/README.md)
