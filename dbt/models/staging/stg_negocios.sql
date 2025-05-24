{{ config(materialized = 'view') }}

with base as (
  select *
  from {{ source('crm_raw', 'negocios') }}
),

staged as (
  select
    base.* except(criadoEm, fechamento),
    cast(base.criadoEm as timestamp) as criadoEm,
    cast(base.fechamento as timestamp) as fechamento
  from base
)

select * from staged

