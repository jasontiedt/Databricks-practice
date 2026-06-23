-- =============================================================================
-- Databricks MCP — Schema discovery & data visualization queries
-- Target catalog/schema (from .vscode/mcp.json): main.silver
--
-- Run individual statements through the Databricks MCP server
-- (e.g. via the `execute_sql` / `run_query` tool). Each section is independent.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. Catalog & schema overview
-- -----------------------------------------------------------------------------

-- List all catalogs the warehouse can see
SHOW CATALOGS;

-- List schemas in the active catalog
SHOW SCHEMAS IN main;

-- List tables & views in the active schema
SHOW TABLES IN main.silver;
SHOW VIEWS  IN main.silver;


-- -----------------------------------------------------------------------------
-- 2. Schema details for a single table
--    Replace :table_name with the table you want to inspect.
-- -----------------------------------------------------------------------------

-- Column list with data types, nullability, and comments
DESCRIBE TABLE EXTENDED main.silver.:table_name;

-- Compact column metadata via information_schema
SELECT
    column_name,
    ordinal_position,
    data_type,
    is_nullable,
    comment
FROM main.information_schema.columns
WHERE table_catalog = 'main'
  AND table_schema  = 'silver'
  AND table_name    = ':table_name'
ORDER BY ordinal_position;

-- Primary key / unique / foreign key constraints (if defined)
SELECT
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM main.information_schema.table_constraints tc
JOIN main.information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
 AND tc.table_schema    = kcu.table_schema
 AND tc.table_name      = kcu.table_name
WHERE tc.table_schema = 'silver'
  AND tc.table_name   = ':table_name';


-- -----------------------------------------------------------------------------
-- 3. Schema inventory across the whole `silver` schema
-- -----------------------------------------------------------------------------

-- Tables with column counts and (best-effort) row counts via stats
SELECT
    t.table_name,
    t.table_type,
    COUNT(c.column_name) AS column_count,
    t.comment
FROM main.information_schema.tables t
LEFT JOIN main.information_schema.columns c
  ON  c.table_catalog = t.table_catalog
  AND c.table_schema  = t.table_schema
  AND c.table_name    = t.table_name
WHERE t.table_schema = 'silver'
GROUP BY t.table_name, t.table_type, t.comment
ORDER BY t.table_name;

-- Wide view: every column in every table in the schema
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM main.information_schema.columns
WHERE table_schema = 'silver'
ORDER BY table_name, ordinal_position;


-- -----------------------------------------------------------------------------
-- 4. Quick data peek (replace :table_name)
-- -----------------------------------------------------------------------------

-- Sample rows
SELECT * FROM main.silver.:table_name LIMIT 100;

-- Row count
SELECT COUNT(*) AS row_count FROM main.silver.:table_name;


-- -----------------------------------------------------------------------------
-- 5. Column profiling for visualization
--    Replace :table_name and :column_name. Use these to feed charts/dashboards.
-- -----------------------------------------------------------------------------

-- Null / distinct profile for one column
SELECT
    COUNT(*)                                              AS total_rows,
    COUNT(`:column_name`)                                 AS non_null_rows,
    COUNT(*) - COUNT(`:column_name`)                      AS null_rows,
    COUNT(DISTINCT `:column_name`)                        AS distinct_values
FROM main.silver.:table_name;

-- Top categorical values (bar chart)
SELECT
    `:column_name` AS category,
    COUNT(*)       AS frequency
FROM main.silver.:table_name
WHERE `:column_name` IS NOT NULL
GROUP BY `:column_name`
ORDER BY frequency DESC
LIMIT 25;

-- Numeric distribution summary (box-plot inputs)
SELECT
    MIN(`:column_name`)                                  AS min_value,
    APPROX_PERCENTILE(`:column_name`, 0.25)              AS p25,
    APPROX_PERCENTILE(`:column_name`, 0.50)              AS median,
    APPROX_PERCENTILE(`:column_name`, 0.75)              AS p75,
    MAX(`:column_name`)                                  AS max_value,
    AVG(`:column_name`)                                  AS mean,
    STDDEV(`:column_name`)                               AS stddev
FROM main.silver.:table_name;

-- Numeric histogram (20 bins) for line/area/bar charts
WITH bounds AS (
    SELECT MIN(`:column_name`) AS lo, MAX(`:column_name`) AS hi
    FROM main.silver.:table_name
),
binned AS (
    SELECT
        FLOOR(
            (`:column_name` - bounds.lo) /
            NULLIF((bounds.hi - bounds.lo) / 20.0, 0)
        ) AS bin_index,
        bounds.lo, bounds.hi
    FROM main.silver.:table_name, bounds
    WHERE `:column_name` IS NOT NULL
)
SELECT
    bin_index,
    lo + bin_index * ((hi - lo) / 20.0)        AS bin_start,
    lo + (bin_index + 1) * ((hi - lo) / 20.0)  AS bin_end,
    COUNT(*)                                   AS frequency
FROM binned
GROUP BY bin_index, lo, hi
ORDER BY bin_index;


-- -----------------------------------------------------------------------------
-- 6. Time-series rollup (replace :table_name, :date_column, :metric_column)
-- -----------------------------------------------------------------------------

-- Daily aggregation — feed to a line chart
SELECT
    DATE_TRUNC('day', `:date_column`) AS day,
    COUNT(*)                          AS row_count,
    SUM(`:metric_column`)             AS metric_sum,
    AVG(`:metric_column`)             AS metric_avg
FROM main.silver.:table_name
WHERE `:date_column` IS NOT NULL
GROUP BY DATE_TRUNC('day', `:date_column`)
ORDER BY day;

-- Monthly rollup
SELECT
    DATE_TRUNC('month', `:date_column`) AS month,
    COUNT(*)                            AS row_count,
    SUM(`:metric_column`)               AS metric_sum
FROM main.silver.:table_name
WHERE `:date_column` IS NOT NULL
GROUP BY DATE_TRUNC('month', `:date_column`)
ORDER BY month;


-- -----------------------------------------------------------------------------
-- 7. Correlation between two numeric columns (replace :col_x and :col_y)
-- -----------------------------------------------------------------------------

SELECT
    CORR(`:col_x`, `:col_y`)        AS pearson_corr,
    COVAR_SAMP(`:col_x`, `:col_y`)  AS covariance,
    COUNT(*)                        AS n
FROM main.silver.:table_name
WHERE `:col_x` IS NOT NULL AND `:col_y` IS NOT NULL;

-- Scatter-plot sample (downsample for rendering)
SELECT `:col_x`, `:col_y`
FROM main.silver.:table_name TABLESAMPLE (5000 ROWS)
WHERE `:col_x` IS NOT NULL AND `:col_y` IS NOT NULL;
