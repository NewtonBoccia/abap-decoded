# 03 — Include Programs

## 📖 Conceito

Include programs são arquivos de código ABAP que não executam sozinhos — eles são inseridos dentro de outros programas em tempo de compilação, como um `#include` em C.

Usos principais:
- **Dividir programas grandes** em partes lógicas (top include, seleção, processamento, forms)
- **Compartilhar estruturas e tipos** entre programas
- **Padrão obrigatório** em programas gerados pelo SAP (Module Pools, Report com SAP-standard)

**Convenção de nomes SAP:**

| Sufixo | Conteúdo |
|--------|----------|
| `TOP` | Declarações globais, TYPES, DATA |
| `SEL` | Tela de seleção (SELECTION-SCREEN) |
| `F01`, `F02`... | FORMs de processamento |
| `O01`, `O02`... | PBO (Process Before Output) |
| `I01`, `I02`... | PAI (Process After Input) |

---

## 💻 Código

### Estrutura típica de um report com includes

**Programa principal: `Z_DECODED_MODULAR`**

```abap
REPORT z_decoded_modular.

" Declarações globais
INCLUDE z_decoded_modular_top.

" Tela de seleção
INCLUDE z_decoded_modular_sel.

" Start-of-Selection chama as FORMs
START-OF-SELECTION.
  PERFORM selecionar_dados.
  PERFORM processar_dados.
  PERFORM exibir_resultado.

" FORMs de processamento
INCLUDE z_decoded_modular_f01.
```

---

**Include TOP: `Z_DECODED_MODULAR_TOP`**

```abap
*&---------------------------------------------------------------------*
*& Include Z_DECODED_MODULAR_TOP
*& Declarações globais do programa
*&---------------------------------------------------------------------*

TYPES: BEGIN OF ty_pedido,
         vbeln TYPE vbeln,
         kunnr TYPE kunnr,
         netwr TYPE netwr,
         waerk TYPE waerk,
       END OF ty_pedido.

DATA: lt_pedidos TYPE TABLE OF ty_pedido,
      ls_pedido  TYPE ty_pedido,
      gv_total   TYPE p DECIMALS 2.

CONSTANTS: gc_status_aberto    TYPE c LENGTH 1 VALUE 'A',
           gc_status_fechado   TYPE c LENGTH 1 VALUE 'F',
           gc_status_cancelado TYPE c LENGTH 1 VALUE 'C'.
```

---

**Include SEL: `Z_DECODED_MODULAR_SEL`**

```abap
*&---------------------------------------------------------------------*
*& Include Z_DECODED_MODULAR_SEL
*& Tela de seleção
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS: so_kunnr FOR ls_pedido-kunnr OBLIGATORY,
                  so_data  FOR sy-datum DEFAULT sy-datum.
  PARAMETERS:     pa_max   TYPE i DEFAULT 100.
SELECTION-SCREEN END OF BLOCK b1.
```

---

**Include F01: `Z_DECODED_MODULAR_F01`**

```abap
*&---------------------------------------------------------------------*
*& Include Z_DECODED_MODULAR_F01
*& FORMs de processamento
*&---------------------------------------------------------------------*

*---------------------------------------------------------------------*
FORM selecionar_dados.
*---------------------------------------------------------------------*
  SELECT vbeln kunnr netwr waerk
    FROM vbak
    INTO TABLE lt_pedidos
    WHERE kunnr IN so_kunnr
      AND audat IN so_data
      AND vbtyp = 'C'
    UP TO pa_max ROWS.

  IF sy-subrc <> 0.
    MESSAGE 'Nenhum pedido encontrado.' TYPE 'I'.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
FORM processar_dados.
*---------------------------------------------------------------------*
  IF lt_pedidos IS INITIAL.
    RETURN.
  ENDIF.

  SORT lt_pedidos BY kunnr vbeln.

  LOOP AT lt_pedidos ASSIGNING FIELD-SYMBOL(<ls>).
    gv_total = gv_total + <ls>-netwr.
  ENDLOOP.
ENDFORM.

*---------------------------------------------------------------------*
FORM exibir_resultado.
*---------------------------------------------------------------------*
  LOOP AT lt_pedidos INTO ls_pedido.
    WRITE: / ls_pedido-vbeln, ls_pedido-kunnr, ls_pedido-netwr, ls_pedido-waerk.
  ENDLOOP.
  WRITE: / |─────────────────────────────|.
  WRITE: / |Total: { gv_total }|.
ENDFORM.
```

---

### Include de tipos compartilhados (TYPE-POOL vs. Include)

```abap
" Padrão moderno: criar um include global de tipos
" criado como INCLUDE no SE38 — tipo ZINC (Include)

" Conteúdo do include Z_TIPOS_COMUNS:
TYPES: BEGIN OF ty_endereco,
         rua    TYPE string,
         numero TYPE n LENGTH 6,
         cep    TYPE n LENGTH 8,
         cidade TYPE string,
         estado TYPE c LENGTH 2,
       END OF ty_endereco.

TYPES: BEGIN OF ty_pessoa,
         cpf      TYPE n LENGTH 11,
         nome     TYPE string,
         email    TYPE string,
         endereco TYPE ty_endereco,
       END OF ty_pessoa.

" Em qualquer programa que precise usar esses tipos:
INCLUDE z_tipos_comuns.
DATA: ls_cliente TYPE ty_pessoa.
```

---

### Include em Function Groups

```abap
" Function Groups também usam includes automaticamente:
" SAPL<nome_grupo> — programa principal (gerado automaticamente)
" L<nome_grupo>TOP — declarações globais do grupo
" L<nome_grupo>U01 — FMs do grupo (um include por FM, geralmente)
" L<nome_grupo>F01 — FORMs auxiliares

" Você raramente edita esses includes manualmente — o SE37 gerencia
```

---

## ⚠️ Pegadinhas

**1. Include não pode ser ativado sozinho**
```abap
" ERRO: tentar executar um include diretamente
" Includes são compilados junto com o programa principal.
" Para testar: ative o programa principal, não o include.
```

**2. Circular include — programa A inclui B que inclui A**
```abap
" O sistema não deixa isso acontecer, mas vai dar erro de sintaxe confuso.
" Se você ver "include not found" ou loops estranhos, verifique dependências.
```

**3. Variáveis globais em includes são globais de verdade**
```abap
" Se o TOP include declara gv_total, qualquer FORM em qualquer include
" do programa pode ler e modificar gv_total.
" Em programas grandes, isso causa bugs difíceis de rastrear.
" Prefira passar parâmetros explícitos via USING/CHANGING.
```

---

## 🏋️ Exercício

Refatore o programa `Z_DECODED_MODULAR_01` (criado nas aulas anteriores) para usar includes:

1. Crie `Z_DECODED_MODULAR_01_TOP` com todos os TYPES e DATA globais
2. Crie `Z_DECODED_MODULAR_01_SEL` com a tela de seleção
3. Crie `Z_DECODED_MODULAR_01_F01` com todas as FORMs
4. No programa principal, use apenas os INCLUDEs e o START-OF-SELECTION

**Objetivo:** o programa principal deve ter menos de 15 linhas de código real.

---

⬅️ [02 — Function Modules](./02-function-modules.md) | ➡️ [Módulo 03 — OO ABAP](../03-oo-abap/README.md)
