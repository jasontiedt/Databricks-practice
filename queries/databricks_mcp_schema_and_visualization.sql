-- Databricks MCP query set: schema discovery + visualization-ready data
-- Uses environment defaults from .vscode/mcp.json:
--   catalog = main
--   schema  = silver

-- =========================================================
-- 1) List all tables/views in the active catalog + schema
-- =========================================================
SELECT
  table_catalog,
  table_schema,
  table_name,
  table_type,
  created,
  last_altered
FROM main.information_schema.tables
WHERE table_catalog = 'main'
  AND table_schema = 'silver'
ORDER BY table_type, table_name;

-- =========================================================
-- 2) List columns for one table (replace <table_name>)
-- =========================================================
SELECT
  table_catalog,
  table_schema,
  table_name,
  ordinal_position,
  column_name,
  data_type,
  is_nullable,
  comment
FROM main.information_schema.columns
WHERE table_catalog = 'main'
  AND table_schema = 'silver'
  AND table_name = '<table_name>'
ORDER BY ordinal_position;

-- =========================================================
-- 3) Quick data preview (replace <table_name>)
-- =========================================================
SELECT *
FROM main.silver.<table_name>
LIMIT 100;

-- =========================================================
-- 4) Visualization query template (time series)
-- Replace:
--   <table_name>    with your table
--   <date_column>   with DATE/TIMESTAMP column
--   <metric_column> with numeric column to aggregate
-- =========================================================
SELECT
  date_trunc('day', <date_column>) AS day,
  SUM(<metric_column>) AS metric_value
FROM main.silver.<table_name>
GROUP BY 1
ORDER BY 1;

-- =========================================================
-- 5) Visualization query template (category bar chart)
-- Replace:
--   <table_name>       with your table
--   <category_column>  with dimension/category
-- =========================================================
SELECT
  <category_column> AS category,
  COUNT(*) AS record_count
FROM main.silver.<table_name>
GROUP BY 1
ORDER BY record_count DESC
LIMIT 25;
