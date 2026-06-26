---
mode: 'agent'
description: 'Convert a natural-language question into Databricks SQL grounded in the current schema, run it, and return a table + chart.'
---

# Natural language to SQL

Input:
- Question: `${input:question}`
- Catalog: `${input:catalog:main}`
- Schema: `${input:schema:silver}`

You are answering an analytical question by translating it into Databricks SQL, running it through the Databricks MCP server, and presenting the result. Never invent column or table names — always ground in `information_schema`.

## Steps

1. **Discover available tables** (do this first, every time):
   ```sql
   SELECT table_name
   FROM ${input:catalog:main}.information_schema.tables
   WHERE table_schema = '${input:schema:silver}'
   ORDER BY table_name;
   ```

2. **Pick candidate tables** (1-3) that look relevant to the question by name.

3. **Pull their columns** in a single query:
   ```sql
   SELECT table_name, column_name, data_type
   FROM ${input:catalog:main}.information_schema.columns
   WHERE table_schema = '${input:schema:silver}'
     AND table_name IN (<candidate_tables>)
   ORDER BY table_name, ordinal_position;
   ```

4. **Draft the SQL**:
   - Use fully-qualified names: `${input:catalog:main}.${input:schema:silver}.<table>`.
   - Cap result size with `LIMIT 1000` unless the question explicitly needs more.
   - For aggregations, always include both the grouping column(s) and the aggregate(s) in the SELECT.
   - Prefer `APPROX_COUNT_DISTINCT` over `COUNT(DISTINCT ...)` on large tables.
   - Quote identifiers with backticks if they contain spaces or reserved words.

5. **Show the SQL to the user** in a fenced ```sql block BEFORE running it. If the SQL is non-trivial (joins, window functions, CTEs), briefly explain the approach in 1-2 sentences.

6. **Run the query** via the Databricks MCP server.

7. **Pick a visualization** based on the result shape:

   | Result shape                         | Chart                    |
   | ------------------------------------ | ------------------------ |
   | single number                        | callout / no chart       |
   | two columns: category + numeric      | bar chart (top 25)       |
   | two columns: date + numeric          | line chart               |
   | three+ columns                       | table + suggest follow-up |

## Output

1. **Interpretation** — restate the question in 1 sentence to confirm intent.
2. **SQL** — the query you ran, in a fenced block.
3. **Result table** — first 25 rows as a markdown table; note total row count if larger.
4. **Chart** — Mermaid `xychart-beta` if appropriate; otherwise skip with a 1-line explanation.
5. **Caveats** — anything you assumed (table choice, join keys, time windows) so the user can correct you.

## Refusals

If after step 3 you cannot find tables/columns that plausibly answer the question, do NOT guess. Tell the user which tables you searched and ask them to point to the right ones.
