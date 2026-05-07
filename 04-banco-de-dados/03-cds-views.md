# 03 — CDS Views

## 📖 Conceito

**Core Data Services (CDS)** é a camada de modelagem de dados do SAP moderno. Em vez de escrever SELECTs no código ABAP, você define views com lógica de negócio no banco — e essas views viram a fonte para Fiori apps, APIs OData, e relatórios.

CDS vive em arquivos `.ddls` no ABAP Development Tools (ADT) — o Eclipse plugin da SAP. Não dá para criar CDS pela SE38.

Por que CDS importa:
- Base obrigatória para **RAP** (Restful ABAP Programming Model)
- Performance: lógica executada no banco HANA (pushdown)
- Reuso: uma view CDS serve ABAP, OData, e Analytics ao mesmo tempo

---

## 💻 Código

### CDS View básica — equivalente a um SELECT

```abap
@AbapCatalog.sqlViewName: 'ZVCLI_BRASIL'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Clientes Brasil'
define view Z_CLIENTES_BRASIL
  as select from kna1
{
  key kna1.kunnr as ClienteID,
      kna1.name1 as Nome,
      kna1.land1 as Pais,
      kna1.ktokd as GrupoConta,
      kna1.erdat as DataCriacao
}
where
  kna1.land1 = 'BR'
```

---

### CDS com JOIN — lógica de cruzamento no banco

```abap
@AbapCatalog.sqlViewName: 'ZVPED_CLIENTE'
@EndUserText.label: 'Pedidos com Cliente'
define view Z_PEDIDOS_CLIENTE
  as select from vbak as pedido
  inner join kna1 as cliente
    on pedido.kunnr = cliente.kunnr
{
  key pedido.vbeln as NumeroPedido,
      pedido.erdat as DataCriacao,
      pedido.kunnr as ClienteID,
      cliente.name1 as NomeCliente,
      pedido.netwr as ValorLiquido,
      pedido.waerk as Moeda
}
where
  pedido.vbtyp = 'C'
```

---

### CDS com associações (Associations) — joins sob demanda

```abap
@AbapCatalog.sqlViewName: 'ZVMATERIAL'
@EndUserText.label: 'Materiais com Descrição'
define view Z_MATERIAL_DESC
  as select from mara
  association [1..1] to makt as _Descricao
    on  $projection.Matnr = _Descricao.matnr
    and _Descricao.spras  = $session.system_language
{
  key mara.matnr  as Matnr,
      mara.mtart  as TipoMaterial,
      mara.meins  as UnidadeMedida,
      " Acessa a associação (JOIN só executa se o campo for selecionado)
      _Descricao.maktx as Descricao,
      " Expõe a associação para que o consumidor possa navegar
      _Descricao
}
```

---

### Consumindo CDS View em ABAP

```abap
REPORT z_decoded_cds_consumo.

" Você acessa a CDS pelo nome da VIEW SQL (sqlViewName), não o nome do objeto DDL
SELECT clienteid nome valortotal
  FROM zvped_resumo    " nome definido em @AbapCatalog.sqlViewName
  INTO TABLE @DATA(lt_resultado)
  WHERE valortotal > 5000
  ORDER BY valortotal DESCENDING.

LOOP AT lt_resultado INTO DATA(ls).
  WRITE: / ls-clienteid, ls-nome, ls-valortotal.
ENDLOOP.
```

---

### Annotations importantes

```abap
" Controle de acesso — NUNCA coloque #NOT_REQUIRED em produção
@AccessControl.authorizationCheck: #CHECK          " verifica DCL (Data Control Language)
@AccessControl.authorizationCheck: #NOT_REQUIRED   " apenas para dev/teste

" Para Analytics (relatórios Fiori)
@Analytics.dataCategory: #CUBE
@Analytics.dataCategory: #DIMENSION

" Para OData (APIs)
@OData.publish: true

" Documentação
@EndUserText.label: 'Descrição da view para o usuário final'
@EndUserText.quickInfo: 'Informação adicional no tooltip'
```

---

## ⚠️ Pegadinhas

**1. Não confundir nome DDL com nome SQL View**
```abap
" O objeto no ADT se chama Z_PEDIDOS_CLIENTE (nome DDL)
" Mas no SELECT ABAP você usa o @AbapCatalog.sqlViewName: 'ZVPED_CLIENTE'
SELECT * FROM zvped_cliente ...  " ← nome SQL
" SELECT * FROM Z_PEDIDOS_CLIENTE  " ← não funciona no Open SQL clássico
```

**2. Associations não fazem JOIN automaticamente**
```abap
" A association _Descricao só executa o JOIN se você selecionar um campo dela
" ou expor ela. Se não usar _Descricao, o JOIN não acontece — boa performance.
```

**3. CDS não substitui toda lógica — só modelagem de dados**
```abap
" CDS é ótimo para: seleção, join, agregação, associações, projeção
" CDS NÃO FAZ: loops, condicionais complexas, chamadas de FM, DML (insert/update)
" Para lógica de processo: combine CDS (leitura) + ABAP (processamento)
```

---

## 🏋️ Exercício

1. No ADT (ABAP Development Tools), crie a CDS View `Z_CLIENTES_ATIVOS`:
   - Selecione clientes da `KNA1` com país BR e conta criada nos últimos 2 anos
   - Inclua uma association para `VBAK` (pedidos) via `kunnr`
   - Anote com `@EndUserText.label`

2. No SE38, crie um programa que consome a view via SELECT e imprime os resultados

**Alternativa sem sistema SAP:** documente a estrutura da CDS View em um arquivo `.ddls` no repositório com a sintaxe correta — o GitHub renderiza com syntax highlighting.

---

⬅️ [02 — JOINs](./02-joins-subqueries.md) | ➡️ [Módulo 05 — IDocs & EDI](../05-idocs-edi/README.md)
