---
mode: 'agent'
description: 'Full per-column data profile for a Databricks table — null %, distinct counts, min/max, top values, flagged issues.'
---

# Profile table

Inputs:
- Catalog: `${input:catalog:main}`
- Schema: `${input:schema:silver}`
- Table: `${input:table}`

Goal: produce a column-by-column profile and surface data quality issues. Use the Databricks MCP server for every SQL call.

## Steps

1. **Get the column list** so you know what to profile:
   ```sql
   SELECT column_name, data_type
   FROM ${input:catalog:main}.information_schema.columns
   WHERE table_schema = '${input:schema:silver}'
     AND table_name   = '${input:table}'
   ORDER BY ordinal_position;
   ```

2. **Single aggregate query** — build one SQL that returns counts/distinct/nulls per column to avoid N round-trips. Template:
   ```sql
   SELECT
       COUNT(*) AS total_rows,
       COUNT(`<col1>`)            AS non_null_col1,
       COUNT(DISTINCT `<col1>`)   AS distinct_col1,
       COUNT(`<col2>`)            AS non_null_col2,
       COUNT(DISTINCT `<col2>`)   AS distinct_col2
       -- repeat per column
   FROM ${input:catalog:main}.${input:schema:silver}.${input:table};
   ```

3. **For numeric columns**, add min/max/avg/stddev and 5-number summary in one query each:
   ```sql
   SELECT
       MIN(`<col>`)                         AS min,
       APPROX_PERCENTILE(`<col>`, 0.25)     AS p25,
       APPROX_PERCENTILE(`<col>`, 0.50)     AS median,
       APPROX_PERCENTILE(`<col>`, 0.75)     AS p75,
       MAX(`<col>`)                         AS max,
       AVG(`<col>`)                         AS mean,
       STDDEV(`<col>`)                      AS stddev
   FROM ${input:catalog:main}.${input:schema:silver}.${input:table};
   ```

4. **For low-cardinality / string columns** (distinct ≤ 50), pull top values:
   ```sql
   SELECT `<col>` AS value, COUNT(*) AS frequency
   FROM ${input:catalog:main}.${input:schema:silver}.${input:table}
   WHERE `<col>` IS NOT NULL
   GROUP BY `<col>`
   ORDER BY frequency DESC
   LIMIT 10;
   ```

5. **For date/timestamp columns**, get the range:
   ```sql
   SELECT MIN(`<col>`) AS earliest, MAX(`<col>`) AS latest
   FROM ${input:catalog:main}.${input:schema:silver}.${input:table};
   ```

## Issue detection rules

Flag columns where:

- `null %` > 20% → **High null rate**
- `distinct = 1` → **Constant column** (candidate for removal)
- `distinct = total_rows` → **Unique** (candidate key)
- numeric `stddev = 0` → **Zero variance**
- date range spans > 50 years → **Suspicious date range**
- top value frequency > 80% of non-null rows → **Heavily skewed**

## Output

1. **Summary** — table name, row count, column count, # of issues found.
2. **Column profile table** — column | type | null % | distinct | min/p50/max (numeric) or top value (categorical) | flags.
3. **Issues** — bulleted list of flagged columns with severity and suggested action.
4. **Suggested charts** — for each numeric column, propose histogram; for each categorical with distinct ≤ 25, propose bar chart; for each date column, propose time-series.
