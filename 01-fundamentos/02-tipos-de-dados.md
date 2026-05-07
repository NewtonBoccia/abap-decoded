# 02 — Tipos de Dados

## 📖 Conceito

ABAP tem dois mundos de tipos: os **elementares** (guardam um valor) e os **complexos** (agrupam valores). Entender qual usar — e quando — é o que separa código que funciona de código que funciona *direito*.

Os tipos elementares mais usados:

| Tipo | Descrição | Tamanho padrão |
|------|-----------|----------------|
| `i` | Integer (inteiro) | 4 bytes |
| `f` | Float (ponto flutuante) | 8 bytes |
| `p` | Packed decimal (valores monetários) | variável |
| `c` | Character (texto fixo) | 1 char |
| `string` | String dinâmica | ilimitado |
| `n` | Numeric text (dígitos como texto) | 1 char |
| `d` | Date (YYYYMMDD) | 8 chars |
| `t` | Time (HHMMSS) | 6 chars |
| `x` | Hexadecimal | 1 byte |

---

## 💻 Código

### Tipos elementares na prática

```abap
REPORT z_decoded_tipos.

DATA: lv_inteiro  TYPE i       VALUE 42,
      lv_texto    TYPE string  VALUE 'SAP',
      lv_char     TYPE c LENGTH 10 VALUE 'Newton',
      lv_data     TYPE d,           " data atual via SY-DATUM
      lv_decimal  TYPE p LENGTH 8 DECIMALS 2 VALUE '1234.56'.

lv_data = sy-datum.  " SY-DATUM = data do sistema no formato YYYYMMDD

WRITE: / 'Inteiro:'  , lv_inteiro,
       / 'Texto:'    , lv_texto,
       / 'Char[10]:' , lv_char,     " vai ter espaços à direita
       / 'Data:'     , lv_data,
       / 'Decimal:'  , lv_decimal.
```

---

### Date e Time — os tipos que mais enganam

```abap
DATA: lv_hoje     TYPE d,
      lv_amanha   TYPE d,
      lv_hora     TYPE t,
      lv_diff     TYPE i.

lv_hoje  = sy-datum.
lv_amanha = lv_hoje + 1.    " aritmética de data funciona direto — adiciona dias

lv_hora = sy-uzeit.         " SY-UZEIT = hora atual HHMMSS

" Extraindo partes da data
DATA: lv_ano  TYPE string,
      lv_mes  TYPE string,
      lv_dia  TYPE string.

lv_ano = lv_hoje(4).        " primeiros 4 caracteres = YYYY
lv_mes = lv_hoje+4(2).      " offset 4, 2 chars = MM
lv_dia = lv_hoje+6(2).      " offset 6, 2 chars = DD

WRITE: / |Hoje: { lv_dia }/{ lv_mes }/{ lv_ano }|,
       / |Amanhã: { lv_amanha }|,
       / |Hora: { lv_hora }|.
```

---

### Packed decimal para dinheiro

```abap
" Use TYPE p para valores monetários — não TYPE f (perde precisão)
DATA: lv_preco    TYPE p LENGTH 8 DECIMALS 2,
      lv_qtd      TYPE i,
      lv_total    TYPE p LENGTH 10 DECIMALS 2.

lv_preco = '99.90'.
lv_qtd   = 3.
lv_total = lv_preco * lv_qtd.

WRITE: / |Preço unit.: R$ { lv_preco }|,
       / |Quantidade: { lv_qtd }|,
       / |Total: R$ { lv_total }|.
" Output: Total: R$ 299.70
```

---

### Conversão de tipos

```abap
DATA: lv_num_texto TYPE string VALUE '2024',
      lv_num_int   TYPE i,
      lv_int_texto TYPE string.

" String → Integer
lv_num_int = lv_num_texto.  " conversão implícita (funciona se for numérico)

" Integer → String
lv_int_texto = lv_num_int.

" Forma explícita e segura
MOVE lv_num_texto TO lv_num_int.

WRITE: / |Int: { lv_num_int }|.
```

---

## ⚠️ Pegadinhas

**1. `c` vs `string` — não são a mesma coisa**
```abap
DATA: lv_c TYPE c LENGTH 5 VALUE 'AB'.
" lv_c na verdade é 'AB   ' (3 espaços à direita)
" Comparações podem dar resultado inesperado

DATA: lv_s TYPE string VALUE 'AB'.
" lv_s é 'AB' — sem padding

IF lv_c = lv_s.
  " Isso é TRUE — ABAP ignora trailing spaces na comparação de c e string
ENDIF.
```

**2. Aritmética com TYPE `d` soma *dias*, não strings**
```abap
DATA: lv_dt TYPE d VALUE '20240101'.
lv_dt = lv_dt + 30.   " Resultado: '20240131' — correto
lv_dt = lv_dt + '30'. " ERRADO — não misture com string
```

**3. Float perde precisão — nunca use para dinheiro**
```abap
DATA: lv_f TYPE f VALUE '0.1'.
DATA: lv_p TYPE p DECIMALS 1 VALUE '0.1'.

" lv_f internamente pode ser 0.09999999... — clássico problema de ponto flutuante
" lv_p é exato
```

---

## 🏋️ Exercício

Crie um programa `Z_DECODED_02` que:

1. Declare uma data de nascimento (`TYPE d`) e calcule quantos dias já se passaram desde ela até hoje (`sy-datum`)
2. Declare um preço e uma quantidade e calcule o total com `TYPE p DECIMALS 2`
3. Extraia o ano, mês e dia da data de nascimento e imprima no formato `DD/MM/YYYY`

**Dica:** subtração de datas em ABAP retorna o número de dias — `lv_dias = sy-datum - lv_nascimento`.

---

⬅️ [01 — Sintaxe Básica](./01-sintaxe-basica.md) | ➡️ [03 — Estruturas e Tabelas Internas](./03-estruturas-tabelas-internas.md)
