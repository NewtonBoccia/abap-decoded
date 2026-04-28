@echo off
echo Criando estrutura do abap-decoded...

:: Modulo 00 - Setup
mkdir 00-setup
(
echo # 00 ^— Setup do Ambiente
echo.
echo ## Opcoes gratuitas para praticar ABAP
echo.
echo ### 1. SAP BTP Trial ^(recomendado^)
echo - Acesse: https://www.sap.com/developer/trials-demos/developer-starter-pack.html
echo - Crie uma conta gratuita
echo - Ative o SAP BTP ABAP Environment
echo.
echo ### 2. ADT ^(ABAP Development Tools^)
echo 1. Baixe o Eclipse: https://www.eclipse.org/downloads/
echo 2. Instale o plugin ADT via Help ^-^> Install New Software
echo 3. URL: https://tools.hana.ondemand.com/latest
echo.
echo ## Transacoes uteis
echo.
echo ^| Transacao ^| Para que serve ^|
echo ^|--------^|--------^|
echo ^| SE38 ^| Editor ABAP ^|
echo ^| SE24 ^| Class Builder ^|
echo ^| SE37 ^| Function Builder ^|
echo ^| SE11 ^| ABAP Dictionary ^|
echo ^| ST05 ^| SQL Trace ^|
echo ^| WE19 ^| Testar IDoc ^|
) > 00-setup\README.md

:: Modulo 01 - Fundamentos
mkdir 01-fundamentos
(
echo # 01 ^— Fundamentos
echo.
echo ^| Aula ^| Conteudo ^|
echo ^|------^|----------^|
echo ^| [01 - Sintaxe Basica](./01-sintaxe-basica.md) ^| Estrutura de programa, WRITE, comentarios ^|
echo ^| [02 - Tipos de Dados](./02-tipos-de-dados.md) ^| DATA, tipos elementares, conversoes ^|
echo ^| [03 - Estruturas e Tabelas Internas](./03-estruturas-tabelas-internas.md) ^| TYPES, APPEND, LOOP ^|
echo ^| [04 - Loops e Condicionais](./04-loops-condicionais.md) ^| IF, CASE, DO, WHILE, LOOP AT ^|
) > 01-fundamentos\README.md

copy NUL 01-fundamentos\02-tipos-de-dados.md >nul
copy NUL 01-fundamentos\03-estruturas-tabelas-internas.md >nul
copy NUL 01-fundamentos\04-loops-condicionais.md >nul

:: Modulo 02 - Modularizacao
mkdir 02-modularizacao
(
echo # 02 ^— Modularizacao
echo.
echo ^| Aula ^| Conteudo ^|
echo ^|------^|----------^|
echo ^| [01 - Subroutines](./01-subroutines-form.md) ^| FORM/PERFORM - o jeito antigo ^|
echo ^| [02 - Function Modules](./02-function-modules.md) ^| FUNCTION, parametros, excecoes ^|
echo ^| [03 - Include Programs](./03-include-programs.md) ^| Organizando programas grandes ^|
) > 02-modularizacao\README.md

copy NUL 02-modularizacao\01-subroutines-form.md >nul
copy NUL 02-modularizacao\02-function-modules.md >nul
copy NUL 02-modularizacao\03-include-programs.md >nul

:: Modulos avancados
for %%M in (03-oo-abap 04-banco-de-dados 05-idocs-edi 06-bapi-rfc 07-reports-alv 08-smartforms-adobe 09-fiori-rap) do (
    mkdir %%M
    echo # %%M ^— Em breve > %%M\README.md
)

:: Exercicios e recursos
mkdir exercicios\01-fundamentos
mkdir exercicios\02-modularizacao
mkdir recursos

(
echo # ABAP Cheatsheet
echo.
echo ## Tipos de dados mais usados
echo ^| Tipo ^| Descricao ^| Exemplo ^|
echo ^|------^|-----------^|---------^|
echo ^| C ^| Caractere ^| DATA: lv_name TYPE c LENGTH 30 ^|
echo ^| N ^| Numerico ^| DATA: lv_doc TYPE n LENGTH 10 ^|
echo ^| I ^| Inteiro ^| DATA: lv_count TYPE i ^|
echo ^| P ^| Packed decimal ^| DATA: lv_value TYPE p DECIMALS 2 ^|
echo ^| D ^| Data ^| DATA: lv_date TYPE d ^|
echo ^| STRING ^| String dinamica ^| DATA: lv_text TYPE string ^|
) > recursos\cheatsheet.md

(
echo # Transacoes Uteis
echo.
echo ## Desenvolvimento
echo ^| Transacao ^| Descricao ^|
echo ^|--------^|--------^|
echo ^| SE38 ^| ABAP Editor ^|
echo ^| SE24 ^| Class Builder ^|
echo ^| SE37 ^| Function Module ^|
echo ^| SE11 ^| Dictionary ^|
echo ^| SE16N ^| Visualizar tabelas ^|
echo.
echo ## IDocs e EDI
echo ^| Transacao ^| Descricao ^|
echo ^|--------^|--------^|
echo ^| WE19 ^| Testar IDoc ^|
echo ^| WE05 ^| IDoc List ^|
echo ^| WE02 ^| IDoc Monitor ^|
echo ^| BD87 ^| Reprocessar IDocs ^|
) > recursos\transacoes-uteis.md

echo.
echo Estrutura criada com sucesso!
echo.
echo Agora rode:
echo   git pull --rebase
echo   git add .
echo   git commit -m "feat: add full folder structure"
echo   git push
