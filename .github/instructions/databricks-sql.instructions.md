---
applyTo: '**/*.sql'
description: 'Databricks SQL authoring conventions (dialect, naming, performance).'
---

# Databricks SQL authoring

These rules apply to every `.sql` file in this repo.

## Dialect

- Target engine: **Databricks SQL** on a serverless / pro SQL warehouse.
- ANSI mode is **on**.
- Identifiers are case-insensitive but should be written in `snake_case`.
- Quote identifiers with **backticks**: `` `column name` `` — never double quotes.
- String literals use **single quotes**: `'value'`.

## Catalog / schema

- Default catalog: `main` <!-- CUSTOMIZE -->
- Default schema: `silver` <!-- CUSTOMIZE -->
- Always write three-part names: `catalog.schema.table`. Never rely on `USE`.

## Naming conventions

<!-- CUSTOMIZE the entries below to match your team's standards -->

- Tables: `snake_case`, plural nouns (`orders`, `customers`).
- Columns: `snake_case`. Booleans prefixed `is_` / `has_`.
- Primary keys: `<entity>_id`.
- Foreign keys: `<referenced_entity>_id`.
- Timestamps: `_at` suffix (`created_at`, `updated_at`).
- Dates: `_date` suffix (`order_date`).

## Query style

- One statement per file unless the file is explicitly a script.
- Lead-in keywords (`SELECT`, `FROM`, `WHERE`, `GROUP BY`, `ORDER BY`) on their own line.
- Indent column lists 4 spaces.
- Trailing commas are **not** allowed.
- Always alias derived columns (`AS column_name`).
- Use CTEs (`WITH ... AS`) instead of nested subqueries when readability suffers.

## Performance defaults

- Always include a `LIMIT` on exploratory queries (`LIMIT 1000` is the default).
- Prefer `APPROX_COUNT_DISTINCT` over `COUNT(DISTINCT ...)` on > 10M rows.
- Prefer `APPROX_PERCENTILE` over `PERCENTILE` for distributions.
- For sampling, use `TABLESAMPLE (N ROWS)` rather than `ORDER BY RAND() LIMIT N`.
- Filter on partition columns when present <!-- CUSTOMIZE: list partition columns -->.

## Safety

- Never write `DROP`, `DELETE`, `UPDATE`, `INSERT`, `MERGE`, `TRUNCATE`, or
  `CREATE OR REPLACE` without explicit user confirmation.
- Read-only `SELECT`, `SHOW`, `DESCRIBE`, and `EXPLAIN` are always safe.

## Comments

- File header: 1-3 lines describing intent.
- `-- ` line comments only; do not use `/* */` block comments.
- Mark placeholders with `:placeholder_name` so they're easy to find-and-replace.
