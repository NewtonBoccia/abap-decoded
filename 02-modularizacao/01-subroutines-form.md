# 01 — Subroutines (FORM/PERFORM)

## 📖 Conceito

FORM/PERFORM é a forma mais antiga de reutilizar código em ABAP — existe desde os anos 80 e ainda aparece muito em sistemas legados. Em código novo você vai usar **Function Modules** ou **métodos de classe**, mas é impossível trabalhar com SAP sem entender FORM.

**FORM** = define a sub-rotina  
**PERFORM** = chama a sub-rotina  

A grande diferença para métodos modernos: FORM vive no mesmo programa (ou em um INCLUDE), sem encapsulamento.

---

## 💻 Código

### FORM básico — sem parâmetros

```abap
REPORT z_decoded_modular_01.

START-OF-SELECTION.
  PERFORM exibir_cabecalho.
  PERFORM processar_dados.
  PERFORM exibir_rodape.

*---------------------------------------------------------------------*
FORM exibir_cabecalho.
*---------------------------------------------------------------------*
  WRITE: / '================================================',
         / '   RELATÓRIO DE PEDIDOS — ABAP Decoded         ',
         / '================================================'.
ENDFORM.

*---------------------------------------------------------------------*
FORM processar_dados.
*---------------------------------------------------------------------*
  WRITE: / 'Processando...'.
ENDFORM.

*---------------------------------------------------------------------*
FORM exibir_rodape.
*---------------------------------------------------------------------*
  WRITE: / '================================================',
         / |   Gerado em: { sy-datum } { sy-uzeit }        |,
         / '================================================'.
ENDFORM.
```

---

### FORM com parâmetros USING (entrada) e CHANGING (entrada/saída)

```abap
REPORT z_decoded_modular_params.

DATA: lv_resultado TYPE p DECIMALS 2.

START-OF-SELECTION.
  PERFORM calcular_total
    USING    '250.00'   " preco
             3          " quantidade
             '10'       " desconto percentual
    CHANGING lv_resultado.

  WRITE: / |Total com desconto: R$ { lv_resultado }|.

*---------------------------------------------------------------------*
FORM calcular_total
  USING    pv_preco    TYPE p
           pv_qtd      TYPE i
           pv_desc_pct TYPE p
  CHANGING pv_total    TYPE p.
*---------------------------------------------------------------------*
  DATA: lv_bruto    TYPE p DECIMALS 2,
        lv_desconto TYPE p DECIMALS 2.

  lv_bruto    = pv_preco * pv_qtd.
  lv_desconto = lv_bruto * pv_desc_pct / 100.
  pv_total    = lv_bruto - lv_desconto.
ENDFORM.
```

---

### FORM com tabelas internas (TABLES)

```abap
TYPES: BEGIN OF ty_item,
         codigo TYPE matnr,
         qtd    TYPE i,
         preco  TYPE p DECIMALS 2,
       END OF ty_item.

DATA: lt_itens TYPE TABLE OF ty_item.

PERFORM popular_itens CHANGING lt_itens.
PERFORM imprimir_itens USING lt_itens.

*---------------------------------------------------------------------*
FORM popular_itens
  CHANGING pt_itens TYPE TABLE.
*---------------------------------------------------------------------*
  APPEND VALUE #( codigo = 'MAT-001' qtd = 10 preco = '25.00' )
    TO pt_itens.
  APPEND VALUE #( codigo = 'MAT-002' qtd = 5  preco = '80.50' )
    TO pt_itens.
  APPEND VALUE #( codigo = 'MAT-003' qtd = 20 preco = '12.00' )
    TO pt_itens.
ENDFORM.

*---------------------------------------------------------------------*
FORM imprimir_itens
  USING pt_itens TYPE TABLE.
*---------------------------------------------------------------------*
  DATA: ls_item  TYPE ty_item,
        lv_total TYPE p DECIMALS 2.

  LOOP AT pt_itens INTO ls_item.
    lv_total = lv_total + ( ls_item-qtd * ls_item-preco ).
    WRITE: / |{ ls_item-codigo } | Qtd: { ls_item-qtd } | R$ { ls_item-preco }|.
  ENDLOOP.
  WRITE: / |Total: R$ { lv_total }|.
ENDFORM.
```

---

### PERFORM ON COMMIT — execução adiada

```abap
" Registra o FORM para executar quando acontecer um COMMIT WORK
PERFORM gravar_log ON COMMIT.

" ... algum processamento ...

COMMIT WORK.  " aqui o gravar_log é chamado automaticamente

*---------------------------------------------------------------------*
FORM gravar_log.
*---------------------------------------------------------------------*
  " Gravação de log após commit bem-sucedido
  INSERT zminha_tabela_log FROM ls_log.
ENDFORM.
```

---

## ⚠️ Pegadinhas

**1. Escopo de variáveis — FORM enxerga variáveis globais**
```abap
DATA: gv_global TYPE string VALUE 'global'.

PERFORM testar_escopo.

FORM testar_escopo.
  " gv_global é acessível aqui — sem passar como parâmetro
  " Isso pode causar bugs difíceis de rastrear em programas grandes
  WRITE: / gv_global.  " funciona, mas é má prática
ENDFORM.
```

**2. Passar tabela interna tipada — o tipo importa**
```abap
" ERRADO — TYPE TABLE é genérico demais
FORM processar
  USING pt_dados TYPE TABLE.

" CORRETO — tipo específico previne erros em tempo de compilação
FORM processar
  USING pt_dados TYPE tt_meu_tipo.
```

**3. FORM não retorna valor — use CHANGING ou variável global**
```abap
" FORM não tem RETURN VALUE como Function Module
" Para retornar um valor, use CHANGING:
FORM buscar_descricao
  USING    pv_codigo TYPE matnr
  CHANGING pv_descr  TYPE string.
  SELECT SINGLE maktx INTO pv_descr
    FROM makt WHERE matnr = pv_codigo AND spras = sy-langu.
ENDFORM.
```

---

## 🏋️ Exercício

Crie o programa `Z_DECODED_FORM`:

1. Crie uma FORM `validar_cpf` que receba um CPF (string) via USING e retorne um flag de válido/inválido via CHANGING (pode ser validação simplificada: verifica se tem 11 dígitos numéricos)
2. Crie uma FORM `formatar_moeda` que receba um valor TYPE p e retorne uma string formatada como `R$ 1.234,56`
3. Crie uma FORM `imprimir_tabela` que receba uma tabela interna de pedidos e imprima o cabeçalho + linhas + total
4. Chame as três FORMs a partir do START-OF-SELECTION

---

⬅️ [README do módulo](./README.md) | ➡️ [02 — Function Modules](./02-function-modules.md)
