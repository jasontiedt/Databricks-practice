# Copilot instructions — Databricks-practice

<!--
  This file is auto-loaded by Copilot for every chat in this repository.
  Keep it concise — long instructions degrade response quality.
  Use the files in .github/instructions/ for scope-specific rules.
-->

## Project context

This repository is for practicing Databricks SQL and ad-hoc analytics through
the **Databricks MCP server** configured in `.vscode/mcp.json`.

- Default catalog: `main` <!-- CUSTOMIZE if you work in a different catalog -->
- Default schema:  `silver` <!-- CUSTOMIZE -->
- SQL warehouse runs **Databricks SQL** (Spark SQL dialect, ANSI mode).
- All queries should be runnable through the `databricks` MCP server.

## House rules for every chat

1. **Ground in real metadata.** Before writing SQL, query `information_schema`
   to confirm table and column names exist. Never invent identifiers.
2. **Use fully qualified names** (`catalog.schema.table`) in every query.
3. **Cap result sizes** with `LIMIT 1000` unless the user asks for more.
4. **Prefer approximate functions** on large data: `APPROX_COUNT_DISTINCT`,
   `APPROX_PERCENTILE`.
5. **Surface SQL before running it** when the query is non-trivial
   (joins, window functions, CTEs).
6. **Render charts inline** with Mermaid `xychart-beta` when the result has a
   natural visualization.

<!-- CUSTOMIZE: add any team-specific conventions below, e.g.:
- "Never query the `gold` schema from chat — it's production."
- "Always show row counts before sampling."
- "Tag exploratory queries with a `-- exploratory` header comment."
-->

## What NOT to do

- Do not modify `.vscode/mcp.json` without asking.
- Do not commit Databricks tokens, host URLs, or warehouse IDs.
- Do not run `DROP`, `DELETE`, `UPDATE`, or `INSERT` without explicit confirmation.
