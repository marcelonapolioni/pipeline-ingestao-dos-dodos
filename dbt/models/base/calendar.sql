{{ config(materialized='table') }}

with bounds as (
  select
    min(date(ultima_atividade)) as start_date,
    max(date(ultima_atividade)) as end_date
  from {{ ref('negocios_transforms') }}  -- ou de onde venha ultima_atividade
),

calendar as (
  select
    date           as calendar_date,
    extract(year from date)   as year,
    extract(month from date)  as month,
    format_date('%B', date)   as month_name,
    extract(day from date)    as day,
    extract(week from date)   as week,
    format_date('%A', date)   as weekday,
    case when extract(dayofweek from date) in (1,7) then true else false end as is_weekend
  from bounds,
  unnest(generate_date_array(start_date, end_date, interval 1 day)) as date
)

select * from calendar
