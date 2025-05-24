{{ config(materialized = 'view') }}

with staging as (
    select
        id,
        criadoEm                      as data_criacao,
        contato_id,
        produto_nome,
        etapa_nome,
        valor,
        vendedor_email,
        anotacoes,
        etiquetas  
    from {{ ref('stg_negocios') }}
    where vendedor_email is not null
),

annotations as (
    select
        id,
        timestamp(json_value(elem, '$.criadoEm')) as anotacao_ts
    from staging,
         unnest(json_extract_array(concat('[', anotacoes, ']'))) as elem
    where json_value(elem, '$.criadoEm') is not null
),

ultima_atividade as (
    select
        id,
        date(max(anotacao_ts)) as ultima_atividade
    from annotations
    group by id
),

vendedor_normalized as (
    select
        id,
        initcap(
          regexp_replace(
            split(vendedor_email, '@')[offset(0)],
            r'[._]',
            ' '
          )
        ) as vendedor_nome
    from staging
)

select
    s.id,
    s.data_criacao,
    u.ultima_atividade,
    v.vendedor_nome,
    s.contato_id,
    s.produto_nome,
    s.etapa_nome,
    s.valor,
    s.etiquetas      
from staging       as s
left join ultima_atividade    as u using(id)
left join vendedor_normalized as v using(id)
