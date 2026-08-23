# analytics-platform

Аналитическая платформа на реальных данных: сырьё → витрины (dbt) → A/B и каузальная оценка эффектов → BI-дашборд.
Проект показывает полный цикл работы аналитика: моделирование данных, контроль качества, эксперименты.

> **Данные реальные и открытые.** Backbone — [Online Retail II](https://archive.ics.uci.edu/dataset/502/online+retail+ii) (UCI, CC BY 4.0): ~1,07 млн транзакций британского онлайн-ритейлера за 2009–2011.
> Эксперименты (Модуль C) — на публичных рандомизированных датасетах. Это не продакшн-данные конкретной компании, а открытые наборы; методология и код — рабочие.

---

## Стек

| Слой | Инструмент |
|---|---|
| Хранилище | PostgreSQL (Neon, облако) / Docker Postgres локально |
| Трансформации | **dbt** (staging → marts, тесты, документация) |
| Оркестрация | GitHub Actions (cron) *(Модуль B)* |
| Анализ / A/B / каузальность | Python: pandas, numpy, statsmodels, scikit-uplift *(Модули C–D)* |
| BI | Looker Studio / Superset *(Модуль E)* |

---

## Архитектура данных

```
raw.online_retail            сырьё как есть (загрузка из UCI)
        │
        ▼
stg_online_retail  (view)    очистка: отмены, пустые клиенты, валидные суммы, line_revenue
        │
        ▼
fct_orders         (table)   факт заказов, грейн = один invoice
        │
        ├──► dim_customers      (table)   RFM + когорта по клиенту
        │
        └──► cohort_retention   (table)   матрица удержания: когорта × период
```

Слой `staging` — очистка и sanity-check (убраны отмены `Invoice C%`, строки без `customer_id`, невалидные количества/цены).
Слой `marts` — витрины данных (data marts), готовые для BI и анализа.

---

## Витрины

- **`fct_orders`** — заказы: `order_id`, `customer_id`, дата, страна, число позиций, выручка заказа.
- **`dim_customers`** — RFM по клиенту: recency (дней с последнего заказа), frequency (число заказов), monetary (сумма), месяц когорты.
- **`cohort_retention`** — удержание по когортам: `cohort_month`, `period_number`, активные клиенты, `retention_rate`.

Каждая витрина покрыта тестами качества (`not_null`, `unique`).

---

## Результаты последнего прогона

```
dbt run  → PASS=4   (stg_online_retail + 3 витрины)
dbt test → PASS=8   (ERROR=0)

fct_orders:       36 969 заказов
dim_customers:    5 878 клиентов
cohort_retention: 325 строк матрицы удержания
```

<!-- Скриншоты положи в папку docs/ и раскомментируй:
![dbt run & test](docs/dbt_run_test.png)
![Витрина fct_orders](docs/fct_orders.png)
![Матрица удержания](docs/retention.png)
-->

---

## Как запустить

### Вариант 1 — онлайн, без установки (Colab + Neon)
1. Заведи бесплатный Postgres на [neon.tech](https://neon.tech), скопируй connection string.
2. Открой `notebooks/Module_A_online.ipynb` в Google Colab.
3. Вставь connection string в ячейку 2 и прогони ячейки сверху вниз: загрузка данных → `dbt run` → `dbt test` → проверка витрин.

### Вариант 2 — локально (Docker + dbt)
```bash
docker compose up -d                       # поднять Postgres
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python load_data.py                        # загрузить Online Retail II в raw
cd dbt
dbt run  --profiles-dir .
dbt test --profiles-dir .
```

> `profiles.yml` в репозитории содержит только локальные dev-креды (`analytics/analytics`).
> Реальные строки подключения (Neon и пр.) **не коммитить** — только в секретах.

---

## Дорожная карта

- [x] **Модуль A** — dbt + витрины на реальных данных, тесты качества
- [ ] **Модуль B** — оркестрация: GitHub Actions по расписанию (cron) гоняет `dbt run`
- [ ] **Модуль C** — A/B end-to-end на реальном рандомизированном эксперименте (Hillstrom): дизайн, размер выборки, guardrail, значимость, ROMI
- [ ] **Модуль D** — каузальная оценка эффекта (diff-in-diff / CausalImpact / uplift) с проверкой против экспериментальной истины
- [ ] **Модуль E** — BI-дашборд (Looker Studio / Superset) поверх витрин

---

## Структура репозитория

```
analytics-platform/
├── dbt/                    dbt-проект (модели, тесты, профиль)
│   ├── models/
│   │   ├── staging/        stg_online_retail + источники
│   │   └── marts/          fct_orders, dim_customers, cohort_retention
│   ├── dbt_project.yml
│   └── profiles.yml        (только локальные dev-креды)
├── notebooks/              Colab-ноутбук для онлайн-запуска
├── docker-compose.yml      локальный Postgres
├── load_data.py            загрузка Online Retail II
└── requirements.txt
```
