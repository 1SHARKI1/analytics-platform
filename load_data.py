"""
Загружает Online Retail II в Postgres (схема raw, таблица online_retail).
Скачай файл вручную: UCI ML Repository -> "Online Retail II" -> online_retail_II.xlsx
Положи рядом со скриптом. В файле два листа (2009-2010, 2010-2011) — грузим оба.
"""
import pandas as pd
from sqlalchemy import create_engine, text

XLSX = "online_retail_II.xlsx"
DB = "postgresql+psycopg2://analytics:analytics@localhost:5432/analytics"

def main():
    engine = create_engine(DB)
    sheets = pd.read_excel(XLSX, sheet_name=None)          # оба листа
    df = pd.concat(sheets.values(), ignore_index=True)
    df.columns = [c.strip().replace(" ", "_").lower() for c in df.columns]
    # ожидаемые колонки: invoice, stockcode, description, quantity, invoicedate, price, customer_id, country
    with engine.begin() as con:
        con.execute(text("CREATE SCHEMA IF NOT EXISTS raw;"))
    df.to_sql("online_retail", engine, schema="raw",
              if_exists="replace", index=False, chunksize=10000)
    print(f"Загружено строк: {len(df):,}")

if __name__ == "__main__":
    main()
