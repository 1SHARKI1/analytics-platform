with source as (
    select * from {{ source('raw', 'online_retail') }}
),
cleaned as (
    select
        cast(invoice as varchar)                    as invoice,
        cast(stockcode as varchar)                  as stock_code,
        description,
        cast(quantity as integer)                   as quantity,
        cast(invoicedate as timestamp)              as invoice_ts,
        cast(price as numeric(12,2))                as unit_price,
        cast(customer_id as bigint)                 as customer_id,
        country,
        cast(quantity as numeric) * cast(price as numeric) as line_revenue
    from source
    where customer_id is not null
      and quantity > 0
      and price > 0
      and invoice not like 'C%'   -- отмены
)
select * from cleaned
