---
applyTo: '**'
description: 'Rules for interacting with the Databricks MCP server during chat sessions.'
---

# Databricks MCP usage

These rules apply whenever you have access to the `databricks` MCP server
(configured in `.vscode/mcp.json`).

## Discovery before generation

1. **Never invent table or column names.** Before writing any non-trivial SQL,
   query `information_schema` first.
2. Use these grounding queries (cheap; safe to run anytime):
   ```sql
   -- What tables exist?
   SELECT table_name, table_type
   FROM main.information_schema.tables
   WHERE table_schema = 'silver';

   -- What columns does table X have?
   SELECT column_name, data_type, is_nullable
   FROM main.information_schema.columns
   WHERE table_schema = 'silver' AND table_name = 'X';
   ```
3. If grounding returns nothing matching the user's intent, **stop and ask**.
   Do not guess at schemas.

## Query construction

- Always use three-part names: `main.silver.<table>`.
- Always include `LIMIT` on exploratory `SELECT *` (default 1000, max 5000 unless asked).
- Prefer one wider query over many narrow ones — round-trip latency dominates.
- Use parameterized placeholders (`:name`) in **stored** SQL files, but substitute
  literal values when sending to the MCP server (the executor does not bind `:`).

## Showing your work

- For any query > 5 lines or with joins/CTEs/windows, **show the SQL in a fenced
  block before running it** so the user can intercept mistakes.
- After running, summarize:
  - row count returned,
  - any approximations used,
  - any assumptions about join keys, time windows, or filters.

## Result handling

- Render small result sets (≤ 25 rows) as markdown tables.
- For larger sets, show the first 25 rows + total count and offer a follow-up.
- Choose visualizations per `data-visualization.instructions.md`.

## Mutation safety

Treat these as **destructive** and require explicit user confirmation each time:

- `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `TRUNCATE`
- `DROP TABLE/VIEW/SCHEMA`
- `CREATE OR REPLACE TABLE/VIEW`
- `ALTER TABLE` (any form)
- `GRANT` / `REVOKE`

Read-only operations are always fine: `SELECT`, `SHOW`, `DESCRIBE`, `EXPLAIN`.

<!-- CUSTOMIZE: if your warehouse has additional guardrails, add them below.
For example:
- "Production tables in `main.gold` are read-only from this workspace."
- "Long-running queries (> 60s) must be canceled and rewritten."
- "Never query PII columns: ssn, email, phone."
-->

## Failure modes

If a query fails:

1. Read the error carefully — Databricks errors are usually precise.
2. Common causes: missing catalog/schema, ambiguous column names, type mismatches,
   permission denied, warehouse not started.
3. Re-ground from `information_schema` before retrying.
4. Do not retry the same query more than twice. After the second failure,
   explain the diagnosis and ask the user.
