@echo off
echo Criando arquivos faltantes...

:: Pasta 01-fundamentos
mkdir 01-fundamentos 2>nul

echo # 01 - Fundamentos > 01-fundamentos\README.md
echo. >> 01-fundamentos\README.md
echo Aulas de fundamentos do ABAP. >> 01-fundamentos\README.md
echo. >> 01-fundamentos\README.md
echo - [01 - Sintaxe Basica](./01-sintaxe-basica.md) >> 01-fundamentos\README.md
echo - [02 - Tipos de Dados](./02-tipos-de-dados.md) >> 01-fundamentos\README.md
echo - [03 - Estruturas e Tabelas Internas](./03-estruturas-tabelas-internas.md) >> 01-fundamentos\README.md
echo - [04 - Loops e Condicionais](./04-loops-condicionais.md) >> 01-fundamentos\README.md

echo # Em construcao > 01-fundamentos\02-tipos-de-dados.md
echo # Em construcao > 01-fundamentos\03-estruturas-tabelas-internas.md
echo # Em construcao > 01-fundamentos\04-loops-condicionais.md

:: Pasta 02-modularizacao
mkdir 02-modularizacao 2>nul

echo # 02 - Modularizacao > 02-modularizacao\README.md
echo. >> 02-modularizacao\README.md
echo Aulas de modularizacao em ABAP. >> 02-modularizacao\README.md
echo. >> 02-modularizacao\README.md
echo - [01 - Subroutines](./01-subroutines-form.md) >> 02-modularizacao\README.md
echo - [02 - Function Modules](./02-function-modules.md) >> 02-modularizacao\README.md
echo - [03 - Include Programs](./03-include-programs.md) >> 02-modularizacao\README.md

echo # Em construcao > 02-modularizacao\01-subroutines-form.md
echo # Em construcao > 02-modularizacao\02-function-modules.md
echo # Em construcao > 02-modularizacao\03-include-programs.md

:: Demais modulos
for %%M in (03-oo-abap 04-banco-de-dados 05-idocs-edi 06-bapi-rfc 07-reports-alv 08-smartforms-adobe 09-fiori-rap) do (
    mkdir %%M 2>nul
    echo # %%M - Em breve > %%M\README.md
)

:: Recursos
mkdir recursos 2>nul
echo # Cheatsheet ABAP > recursos\cheatsheet.md
echo # Transacoes Uteis > recursos\transacoes-uteis.md

:: Exercicios
mkdir exercicios 2>nul
mkdir exercicios\01-fundamentos 2>nul
mkdir exercicios\02-modularizacao 2>nul
echo # Exercicios > exercicios\README.md

echo.
echo Pronto! Agora rode:
echo   git add .
echo   git commit -m "feat: add missing folders and files"
echo   git push
