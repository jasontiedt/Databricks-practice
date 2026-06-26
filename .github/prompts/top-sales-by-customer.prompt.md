---
mode: 'agent'
description: 'Fetch the top customers by sales from a Databricks table, grounded in live schema metadata.'
---

# Top sales by customer

Inputs:
- Catalog: `${input:catalog:main}`
- Schema: `${input:schema:silver}`
- Table: `${input:table}`
- Customer column: `${input:customerColumn}`
- Sales column: `${input:salesColumn}`
- Customer label column (optional): `${input:customerLabelColumn:}`
- Top N: `${input:topN:10}`

Use the Databricks MCP server to run SQL. Never invent tables or columns — confirm everything from `information_schema` before you aggregate.

## Steps

1. **Confirm the table exists**:
   ```sql
   SELECT table_type, comment
   FROM ${input:catalog:main}.information_schema.tables
   WHERE table_schema = '${input:schema:silver}'
     AND table_name   = '${input:table}';
   ```

2. **Confirm the requested columns exist** and capture their data types:
   ```sql
   SELECT column_name, data_type, is_nullable
   FROM ${input:catalog:main}.information_schema.columns
   WHERE table_schema = '${input:schema:silver}'
     AND table_name   = '${input:table}'
     AND column_name IN (
       '${input:customerColumn}',
       '${input:salesColumn}'
     )
   ORDER BY ordinal_position;
   ```
   If `customerLabelColumn` is not blank, also confirm it exists with:
   ```sql
   SELECT column_name, data_type, is_nullable
   FROM ${input:catalog:main}.information_schema.columns
   WHERE table_schema = '${input:schema:silver}'
     AND table_name   = '${input:table}'
     AND column_name  = '${input:customerLabelColumn:}';
   ```
   If any required column is missing, stop and ask the user to correct the inputs.

3. **Sanity-check the source data** before aggregating:
   ```sql
   SELECT COUNT(*)                          AS row_count,
          COUNT(`${input:customerColumn}`)  AS non_null_customers,
          COUNT(`${input:salesColumn}`)     AS non_null_sales,
          MIN(`${input:salesColumn}`)       AS min_sales,
          MAX(`${input:salesColumn}`)       AS max_sales
   FROM ${input:catalog:main}.${input:schema:silver}.${input:table};
   ```

4. **Show the final SQL before running it.** If `customerLabelColumn` is blank, use `customerColumn` as both the identifier and display label.
   - **With a separate label column:**
   ```sql
   WITH customer_sales AS (
       SELECT
           `${input:customerColumn}` AS customer_id,
           CAST(`${input:customerLabelColumn:}` AS STRING) AS customer_label,
           COUNT(*) AS row_count,
           SUM(`${input:salesColumn}`) AS total_sales
       FROM ${input:catalog:main}.${input:schema:silver}.${input:table}
       WHERE `${input:customerColumn}` IS NOT NULL
         AND `${input:salesColumn}` IS NOT NULL
       GROUP BY
           `${input:customerColumn}`,
           CAST(`${input:customerLabelColumn:}` AS STRING)
   )
   SELECT
       customer_id,
       customer_label,
       row_count,
       total_sales
   FROM customer_sales
   ORDER BY total_sales DESC, row_count DESC, customer_label
   LIMIT ${input:topN:10};
   ```
   - **Without a separate label column:**
   ```sql
   WITH customer_sales AS (
       SELECT
           `${input:customerColumn}` AS customer_id,
           CAST(`${input:customerColumn}` AS STRING) AS customer_label,
           COUNT(*) AS row_count,
           SUM(`${input:salesColumn}`) AS total_sales
       FROM ${input:catalog:main}.${input:schema:silver}.${input:table}
       WHERE `${input:customerColumn}` IS NOT NULL
         AND `${input:salesColumn}` IS NOT NULL
       GROUP BY `${input:customerColumn}`
   )
   SELECT
       customer_id,
       customer_label,
       row_count,
       total_sales
   FROM customer_sales
   ORDER BY total_sales DESC, row_count DESC, customer_label
   LIMIT ${input:topN:10};
   ```

5. **Run the query** through the Databricks MCP server after the SQL is shown in chat.

## Output

1. **Interpretation** — restate which table and columns were used.
2. **SQL** — the exact query you ran, in a fenced `sql` block.
3. **Result table** — first 25 rows as markdown.
4. **Chart** — render a Mermaid `xychart-beta` bar chart of `customer_label` vs `total_sales`.
5. **Checks** — report the source row count, NULL counts, and any assumption you made about the label column.
