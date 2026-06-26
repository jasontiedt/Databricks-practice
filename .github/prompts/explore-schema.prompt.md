---
mode: 'agent'
description: 'Walk a Databricks catalog/schema: list tables, summarize columns, suggest analyses.'
---

# Explore Databricks schema

Inputs:
- Catalog: `${input:catalog:main}`
- Schema: `${input:schema:silver}`

Use the Databricks MCP server tools to run SQL against the configured SQL warehouse. Do NOT fabricate table or column names — every fact must come from a query result.

## Steps

1. **List schemas** in the catalog so the user can confirm scope:
   ```sql
   SHOW SCHEMAS IN ${input:catalog:main};
   ```

2. **List tables and views** in the target schema:
   ```sql
   SHOW TABLES IN ${input:catalog:main}.${input:schema:silver};
   SHOW VIEWS  IN ${input:catalog:main}.${input:schema:silver};
   ```

3. **Pull a column inventory** across the whole schema in one query:
   ```sql
   SELECT table_name, column_name, data_type, is_nullable, ordinal_position
   FROM ${input:catalog:main}.information_schema.columns
   WHERE table_schema = '${input:schema:silver}'
   ORDER BY table_name, ordinal_position;
   ```

4. **For each table**, also fetch row count and 1 sample row (cap at the first ~10 tables; ask before going further if more):
   ```sql
   SELECT COUNT(*) FROM ${input:catalog:main}.${input:schema:silver}.<table>;
   SELECT * FROM ${input:catalog:main}.${input:schema:silver}.<table> LIMIT 1;
   ```

## Output

Produce a markdown report with:

- **Schema summary** — # of tables, # of views, total columns, total rows (sum).
- **Table inventory table** — one row per table: name, type, column count, row count, 3-5 word purpose guess based on name + columns.
- **Suggested next steps** — 3-5 concrete follow-up prompts (e.g. "profile `orders`", "visualize `revenue` over `order_date`", "audit nulls in `customers`"). Each suggestion should reference a real table/column you observed.

Keep all SQL in fenced ```sql blocks so the user can re-run them.
