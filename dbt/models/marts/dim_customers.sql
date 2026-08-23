-- RFM + когорта по каждому клиенту.
with orders as (
    select * from {{ ref('fct_orders') }}
),
bounds as (
    select max(order_date) as snapshot_date from orders
),
agg as (
    select
        o.customer_id,
        min(o.order_date)                       as first_order_date,
        max(o.order_date)                       as last_order_date,
        date_trunc('month', min(o.order_date))  as cohort_month,
        count(distinct o.order_id)              as frequency,
        sum(o.order_revenue)                    as monetary
    from orders o
    group by o.customer_id
)
select
    a.*,
    (select snapshot_date from bounds) - a.last_order_date as recency_days
from agg a
