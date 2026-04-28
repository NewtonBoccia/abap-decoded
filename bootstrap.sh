#!/bin/bash
# bootstrap.sh — Cria a estrutura completa do repositório abap-decoded

echo "🔓 Criando estrutura do abap-decoded..."

# Módulo 00 — Setup
mkdir -p 00-setup
cat > 00-setup/README.md << 'EOF'
# 00 — Setup do Ambiente

## Opções gratuitas para praticar ABAP

### 1. SAP BTP Trial (recomendado)
- Acesse: https://www.sap.com/developer/trials-demos/developer-starter-pack.html
- Crie uma conta gratuita
- Ative o SAP BTP ABAP Environment

### 2. SAP Developer Edition (local)
- Requer hardware robusto (mínimo 16GB RAM)
- Download via SAP Software Center

## Configurando o ADT (ABAP Development Tools)

1. Baixe o Eclipse: https://www.eclipse.org/downloads/
2. Instale o plugin ADT via Help → Install New Software
3. URL: `https://tools.hana.ondemand.com/latest`
4. Conecte ao seu sistema SAP

## Transações úteis para ter em mão

| Transação | Para que serve |
|-----------|----------------|
| `SE38` | Editor de programas ABAP |
| `SE24` | Class Builder (OO ABAP) |
| `SE37` | Function Builder |
| `SE11` | ABAP Dictionary |
| `ST05` | SQL Trace (performance) |
| `SM50` | Monitor de processos |

---
➡️ Próximo: [01 — Fundamentos](../01-fundamentos/README.md)
EOF

# Módulo 01 — Fundamentos
mkdir -p 01-fundamentos
cat > 01-fundamentos/README.md << 'EOF'
# 01 — Fundamentos

| Aula | Conteúdo |
|------|----------|
| [01 - Sintaxe Básica](./01-sintaxe-basica.md) | Estrutura de um programa, WRITE, comentários |
| [02 - Tipos de Dados](./02-tipos-de-dados.md) | DATA, tipos elementares, conversões |
| [03 - Estruturas e Tabelas Internas](./03-estruturas-tabelas-internas.md) | TYPES, DATA, APPEND, LOOP |
| [04 - Loops e Condicionais](./04-loops-condicionais.md) | IF, CASE, DO, WHILE, LOOP AT |
EOF

touch 01-fundamentos/01-sintaxe-basica.md
touch 01-fundamentos/02-tipos-de-dados.md
touch 01-fundamentos/03-estruturas-tabelas-internas.md
touch 01-fundamentos/04-loops-condicionais.md

# Módulo 02 — Modularização
mkdir -p 02-modularizacao
cat > 02-modularizacao/README.md << 'EOF'
# 02 — Modularização

| Aula | Conteúdo |
|------|----------|
| [01 - Subroutines](./01-subroutines-form.md) | FORM / PERFORM — o jeito antigo (que você vai encontrar) |
| [02 - Function Modules](./02-function-modules.md) | FUNCTION, parâmetros, exceções |
| [03 - Include Programs](./03-include-programs.md) | Como organizar programas grandes |
EOF

touch 02-modularizacao/01-subroutines-form.md
touch 02-modularizacao/02-function-modules.md
touch 02-modularizacao/03-include-programs.md

# Módulos subsequentes — estrutura básica
for module in "03-oo-abap" "04-banco-de-dados" "05-idocs-edi" "06-bapi-rfc" "07-reports-alv" "08-smartforms-adobe" "09-fiori-rap"; do
  mkdir -p "$module"
  echo "# ${module} — Em breve 🚧" > "$module/README.md"
done

# Exercícios e recursos
mkdir -p exercicios/01-fundamentos
mkdir -p exercicios/02-modularizacao
mkdir -p recursos

cat > recursos/cheatsheet.md << 'EOF'
# ABAP Cheatsheet

## Tipos de dados mais usados
| Tipo | Descrição | Exemplo |
|------|-----------|---------|
| `C` | Caractere | `DATA: lv_name TYPE c LENGTH 30` |
| `N` | Numérico caractere | `DATA: lv_doc TYPE n LENGTH 10` |
| `I` | Inteiro | `DATA: lv_count TYPE i` |
| `P` | Packed (decimal) | `DATA: lv_value TYPE p DECIMALS 2` |
| `D` | Data | `DATA: lv_date TYPE d` |
| `T` | Hora | `DATA: lv_time TYPE t` |
| `STRING` | String dinâmica | `DATA: lv_text TYPE string` |

## Operadores de comparação
```abap
= ou EQ    " igual
<> ou NE   " diferente
< ou LT    " menor que
> ou GT    " maior que
<= ou LE   " menor ou igual
>= ou GE   " maior ou igual
```

## Comandos essenciais
```abap
" Declaração
DATA: lv_var TYPE string.

" Atribuição
lv_var = 'valor'.

" Concatenação
CONCATENATE lv_a lv_b INTO lv_result SEPARATED BY space.
" ou moderno:
lv_result = |{ lv_a } { lv_b }|.

" Saída (debug/relatórios)
WRITE: / lv_var.
MESSAGE 'texto' TYPE 'I'.
```
EOF

cat > recursos/transacoes-uteis.md << 'EOF'
# Transações Úteis

## Desenvolvimento
| Transação | Descrição |
|-----------|-----------|
| SE38 | ABAP Editor |
| SE24 | Class Builder |
| SE37 | Function Module |
| SE11 | Dictionary |
| SE16N | Visualizar tabelas |
| SE80 | Object Navigator |

## Debug & Performance
| Transação | Descrição |
|-----------|-----------|
| ST05 | SQL Trace |
| SAT | Runtime Analysis |
| SM50 | Process Monitor |
| SU53 | Verificar autorizações |

## IDocs & EDI
| Transação | Descrição |
|-----------|-----------|
| WE19 | Testar IDoc |
| WE05 | IDoc List |
| WE02 | IDoc Monitor |
| WE60 | Documentação IDoc |
| BD87 | Reprocessar IDocs |
EOF

cat > CONTRIBUTING.md << 'EOF'
# Contribuindo com o ABAP Decoded

Obrigado por querer contribuir! 🙌

## Como contribuir

1. Faça um fork do repositório
2. Crie uma branch: `git checkout -b minha-contribuicao`
3. Siga o padrão de aulas (veja abaixo)
4. Abra um Pull Request com uma descrição clara

## Padrão de aulas

Cada arquivo `.md` de aula deve seguir esta estrutura:

```markdown
# [Número] — [Título da Aula]

## 📖 Conceito
Explicação objetiva. Sem copiar manual SAP.

## 💻 Código
Exemplo real, comentado.

## ⚠️ Pegadinhas
Erros comuns. O que o manual não te conta.

## 🏋️ Exercício
Desafio prático para fixar o conteúdo.

---
⬅️ [Anterior]() | ➡️ [Próxima]()
```

## O que NÃO queremos
- Copiar/colar da documentação SAP
- Exemplos sem contexto real
- Aulas que ensinam o "o quê" mas não o "por quê"
EOF

echo ""
echo "✅ Estrutura criada com sucesso!"
echo ""
echo "Próximos passos:"
echo "  1. cd abap-decoded"
echo "  2. git init"
echo "  3. git add ."
echo "  4. git commit -m 'chore: initial structure'"
echo "  5. Criar repo no GitHub e fazer push"
echo ""
echo "🔓 ABAP Decoded está pronto para decolar!"
