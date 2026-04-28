# 01 — Sintaxe Básica

## 📖 Conceito

ABAP (**A**dvanced **B**usiness **A**pplication **P**rogramming) é a linguagem proprietária da SAP. Criada nos anos 80, ela ainda roda a maior parte do ERP corporativo do planeta — o que significa que código feito há 30 anos ainda está em produção em alguma empresa agora.

Algumas particularidades que vão te surpreender:

- **Não é case-sensitive** — `data`, `DATA` e `Data` são a mesma coisa
- **Todo statement termina com ponto** (`.`) — esquecer o ponto é o erro #1 de todo iniciante
- **Parece inglês mal escrito** — e foi feito assim de propósito, para ser legível

---

## 💻 Código

### Estrutura mínima de um programa

```abap
REPORT z_meu_primeiro_programa.

* Isto é um comentário de linha inteira (asterisco no início)
DATA: lv_mensagem TYPE string.  " Isto também é comentário (aspas duplas)

lv_mensagem = 'Olá, SAP!'.

WRITE: / lv_mensagem.
```

**Quebrando em partes:**

```abap
REPORT z_meu_primeiro_programa.
```
> Todo programa executável começa com `REPORT`. O prefixo `Z` é obrigatório para objetos customizados (o SAP reserva `A`-`Y` para si mesmo).

```abap
DATA: lv_mensagem TYPE string.
```
> Declaração de variável. O prefixo `lv_` é convenção: **l**ocal **v**ariable. Não é obrigatório, mas você vai ver isso em todo lugar.

```abap
WRITE: / lv_mensagem.
```
> Imprime na tela. A `/` significa "nova linha" — como um `\n`.

---

### Convenção de nomenclatura (Hungarian Notation)

O SAP tem uma convenção forte. Aprenda cedo, sofra menos:

| Prefixo | Significa | Exemplo |
|---------|-----------|---------|
| `lv_` | Local Variable | `lv_name` |
| `gv_` | Global Variable | `gv_counter` |
| `ls_` | Local Structure | `ls_employee` |
| `lt_` | Local Table (interna) | `lt_orders` |
| `gs_` | Global Structure | `gs_config` |
| `gt_` | Global Table | `gt_items` |
| `lc_` | Local Constant | `lc_max_lines` |

---

### String moderno vs. clássico

```abap
DATA: lv_nome  TYPE string VALUE 'Newton',
      lv_cargo TYPE string VALUE 'EDI Specialist',
      lv_texto TYPE string.

" Jeito clássico (ainda muito comum em sistemas legados)
CONCATENATE 'Olá,' lv_nome '-' lv_cargo INTO lv_texto SEPARATED BY space.

" Jeito moderno — string templates (ABAP 7.4+)
lv_texto = |Olá, { lv_nome } - { lv_cargo }|.

WRITE: / lv_texto.
" Output: Olá, Newton - EDI Specialist
```

> **Prefira string templates** (`| |`) em código novo. São mais legíveis e menos propensos a erros de espaçamento.

---

### Constantes

```abap
CONSTANTS: lc_empresa TYPE string VALUE 'ABAP Decoded',
           lc_versao  TYPE i      VALUE 1.
```

---

## ⚠️ Pegadinhas

**1. O ponto no lugar errado quebra tudo**
```abap
" ERRADO — ponto antes da hora fecha o bloco
IF lv_flag = abap_true.
  WRITE: / 'Verdadeiro'.
ENDIF.  " ← ponto aqui, correto

" Mas isso aqui vai compilar E fazer coisa errada:
DATA: lv_a TYPE i.
      lv_b TYPE i.  " ← Linha sem DATA:, vai dar syntax error
```

**2. ABAP é 1-indexed**
```abap
" Strings começam na posição 1, não 0
DATA: lv_str TYPE string VALUE 'ABAP'.
WRITE: / lv_str+0(1).  " Retorna 'A' — offset 0, length 1
WRITE: / lv_str+1(1).  " Retorna 'B'
```

**3. Comparação com espaços em tipos `C`**
```abap
DATA: lv_campo TYPE c LENGTH 10 VALUE 'SAP'.
" lv_campo na verdade contém 'SAP       ' (7 espaços à direita)
" Por isso, prefira TYPE string para evitar surpresas
```

---

## 🏋️ Exercício

Crie um programa `Z_DECODED_01` que:

1. Declare três variáveis: seu nome, sua cidade e seu papel no SAP
2. Monte uma frase usando **string template**: `"Olá! Sou [nome], de [cidade], trabalho com [papel]."`
3. Imprima a frase na tela
4. Adicione uma constante `lc_versao` com valor `'1.0'` e imprima junto

**Resultado esperado:**
```
Olá! Sou Newton, de Curitiba, trabalho com EDI/Integração.
Versão: 1.0
```

---

⬅️ [README do módulo](./README.md) | ➡️ [02 — Tipos de Dados](./02-tipos-de-dados.md)
