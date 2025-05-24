{{ config(
    materialized     = "table",
    on_schema_change = "sync_all_columns"
) }}

with base as (
  select
    ultima_atividade   as data_negocio,
    vendedor_nome,
    produto_nome,
    etapa_nome,
    valor,
    contato_id,
    etiquetas
  from {{ ref('negocios_transforms') }}
  where vendedor_nome is not null
),

negocios_agrupados as (
  select
    data_negocio,
    vendedor_nome,
    produto_nome,
    etapa_nome,
    contato_id,
    etiquetas,
    max(valor)                                as valor,
    count(*)                                   as quantidade_negocios,
    sum(valor)                                 as valor_total,
    count(distinct contato_id)                 as leads_unicos,
    sum(case when etapa_nome = 'VENDA REALIZADA' then valor else 0 end) as valor_vendido,
    
    case
      when count(*) > 0 then 
        sum(case when etapa_nome = 'VENDA REALIZADA' then valor else 0 end) * 1.0 / count(*)
      else null
    end as taxa_conversao

  from base
  group by
    data_negocio,
    vendedor_nome,
    produto_nome,
    etapa_nome,
    contato_id,
    etiquetas
)


select * from negocios_agrupados
