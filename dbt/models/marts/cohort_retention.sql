-- Матрица удержания: когорта (месяц первого заказа) x месяц активности.
with orders as (
    select * from {{ ref('fct_orders') }}
),
cust as (
    select customer_id, cohort_month from {{ ref('dim_customers') }}
),
activity as (
    select
        c.cohort_month,
        date_trunc('month', o.order_date) as activity_month,
        o.customer_id
    from orders o
    join cust c on c.customer_id = o.customer_id
),
by_month as (
    select
        cohort_month,
        activity_month,
        (extract(year from activity_month) - extract(year from cohort_month)) * 12
          + (extract(month from activity_month) - extract(month from cohort_month)) as period_number,
        count(distinct customer_id) as active_customers
    from activity
    group by cohort_month, activity_month
),
cohort_size as (
    select cohort_month, count(distinct customer_id) as cohort_size
    from cust group by cohort_month
)
select
    b.cohort_month,
    b.period_number,
    b.active_customers,
    s.cohort_size,
    round(b.active_customers::numeric / s.cohort_size, 4) as retention_rate
from by_month b
join cohort_size s on s.cohort_month = b.cohort_month
order by b.cohort_month, b.period_number
