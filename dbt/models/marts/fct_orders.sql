-- Грейн: один заказ (invoice). Агрегация строк заказа.
with lines as (
    select * from {{ ref('stg_online_retail') }}
)
select
    invoice                          as order_id,
    customer_id,
    min(invoice_ts)                  as order_ts,
    cast(min(invoice_ts) as date)    as order_date,
    max(country)                     as country,
    count(*)                         as n_lines,
    sum(quantity)                    as n_items,
    sum(line_revenue)                as order_revenue
from lines
group by invoice, customer_id
