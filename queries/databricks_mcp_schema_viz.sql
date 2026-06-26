-- Databricks MCP query pack: schema discovery + visualization-ready datasets
-- Usage:
-- 1) Replace <table_name> and optional filter placeholders.
-- 2) Run each query with your Databricks MCP SQL tool.
-- 3) Feed result sets to your charting UI (line/bar/pie/table).

USE CATALOG main;
USE SCHEMA silver;

-- 1) List all tables/views in the active catalog and schema
SELECT
  table_catalog,
  table_schema,
  table_name,
  table_type,
  created,
  last_altered
FROM system.information_schema.tables
WHERE table_catalog = current_catalog()
  AND table_schema = current_schema()
ORDER BY table_type, table_name;

-- 2) Inspect columns for a target table
SELECT
  table_catalog,
  table_schema,
  table_name,
  column_name,
  ordinal_position,
  data_type,
  is_nullable,
  comment
FROM system.information_schema.columns
WHERE table_catalog = current_catalog()
  AND table_schema = current_schema()
  AND table_name = '<table_name>'
ORDER BY ordinal_position;

-- 3) Quick profile for a target table (record count + freshness)
SELECT
  COUNT(*) AS row_count,
  MIN(created_at) AS min_created_at,
  MAX(created_at) AS max_created_at
FROM main.silver.<table_name>;

-- 4) Time-series dataset (line chart)
-- Replace created_at with your timestamp column.
SELECT
  DATE_TRUNC('day', created_at) AS day,
  COUNT(*) AS records
FROM main.silver.<table_name>
GROUP BY 1
ORDER BY 1;

-- 5) Category distribution dataset (bar/pie chart)
-- Replace category with a low-cardinality dimension (status/type/segment).
SELECT
  category,
  COUNT(*) AS records
FROM main.silver.<table_name>
GROUP BY category
ORDER BY records DESC
LIMIT 20;

-- 6) Top-N metric dataset (horizontal bar chart)
-- Replace entity_id and amount with your dimensions/measures.
SELECT
  entity_id,
  SUM(amount) AS total_amount
FROM main.silver.<table_name>
GROUP BY entity_id
ORDER BY total_amount DESC
LIMIT 15;

-- 7) Null check / data quality summary (stacked bar or table)
-- Add/remove columns as needed.
SELECT
  SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) AS id_nulls,
  SUM(CASE WHEN created_at IS NULL THEN 1 ELSE 0 END) AS created_at_nulls,
  SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS category_nulls,
  COUNT(*) AS total_rows
FROM main.silver.<table_name>;
