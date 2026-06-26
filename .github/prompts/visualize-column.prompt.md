---
mode: 'agent'
description: 'Visualize a single Databricks column — auto-pick chart type from data type and render.'
---

# Visualize column

Inputs:
- Catalog: `${input:catalog:main}`
- Schema: `${input:schema:silver}`
- Table: `${input:table}`
- Column: `${input:column}`

Goal: pick the right chart for the column's data type and render it. Use the Databricks MCP server for queries.

## Steps

1. **Resolve the column type and basic stats**:
   ```sql
   SELECT data_type
   FROM ${input:catalog:main}.information_schema.columns
   WHERE table_schema = '${input:schema:silver}'
     AND table_name   = '${input:table}'
     AND column_name  = '${input:column}';
   ```
   ```sql
   SELECT COUNT(*)                                   AS total,
          COUNT(`${input:column}`)                   AS non_null,
          COUNT(DISTINCT `${input:column}`)          AS distinct_n
   FROM ${input:catalog:main}.${input:schema:silver}.${input:table};
   ```

2. **Choose chart type** based on type + cardinality:

   | Data type                             | Cardinality      | Chart           |
   | ------------------------------------- | ---------------- | --------------- |
   | numeric (`int`, `bigint`, `double`, `decimal`) | high      | histogram (20 bins) |
   | numeric                               | distinct ≤ 25    | bar chart       |
   | `string` / `boolean`                  | distinct ≤ 50    | bar chart (top 25) |
   | `string`                              | distinct > 50    | top 25 bar chart + note about high cardinality |
   | `date` / `timestamp`                  | any              | daily-count line chart |

3. **Run the appropriate query**:

   **Histogram (numeric, high cardinality)**:
   ```sql
   WITH bounds AS (
       SELECT MIN(`${input:column}`) AS lo, MAX(`${input:column}`) AS hi
       FROM ${input:catalog:main}.${input:schema:silver}.${input:table}
   ),
   binned AS (
       SELECT FLOOR((`${input:column}` - bounds.lo)
                    / NULLIF((bounds.hi - bounds.lo) / 20.0, 0)) AS bin_index,
              bounds.lo, bounds.hi
       FROM ${input:catalog:main}.${input:schema:silver}.${input:table}, bounds
       WHERE `${input:column}` IS NOT NULL
   )
   SELECT bin_index,
          lo + bin_index * ((hi - lo) / 20.0)        AS bin_start,
          lo + (bin_index + 1) * ((hi - lo) / 20.0)  AS bin_end,
          COUNT(*)                                   AS frequency
   FROM binned
   GROUP BY bin_index, lo, hi
   ORDER BY bin_index;
   ```

   **Bar (categorical / low-cardinality)**:
   ```sql
   SELECT `${input:column}` AS category, COUNT(*) AS frequency
   FROM ${input:catalog:main}.${input:schema:silver}.${input:table}
   WHERE `${input:column}` IS NOT NULL
   GROUP BY `${input:column}`
   ORDER BY frequency DESC
   LIMIT 25;
   ```

   **Time series (date/timestamp)**:
   ```sql
   SELECT DATE_TRUNC('day', `${input:column}`) AS day, COUNT(*) AS row_count
   FROM ${input:catalog:main}.${input:schema:silver}.${input:table}
   WHERE `${input:column}` IS NOT NULL
   GROUP BY DATE_TRUNC('day', `${input:column}`)
   ORDER BY day;
   ```

## Output

1. **Decision** — which chart type you picked and why (1 sentence).
2. **Data table** — first 25 rows of the result as a markdown table.
3. **Chart** — render as a Mermaid `xychart-beta` (bar/line) or as an ASCII bar chart if Mermaid would be too wide. Include axis labels.
4. **Notes** — null %, distinct count, anything unusual (long tail, gaps in time series, outliers).
