---
mode: 'agent'
description: 'Run null / duplicate / range / orphan-FK / freshness checks across a Databricks schema and produce a findings report.'
---

# Data quality audit

Inputs:
- Catalog: `${input:catalog:main}`
- Schema: `${input:schema:silver}`
- Table filter (optional, SQL LIKE): `${input:tableFilter:%}`

Use the Databricks MCP server. Run checks across every matching table and aggregate findings into a single report.

## Checks

### A. Schema-level

1. **Empty tables** — `COUNT(*) = 0`.
2. **Tables without primary keys** — no PK in `information_schema.table_constraints`.
3. **Orphan foreign keys** — FK columns where some values don't exist in the referenced table.

### B. Per-column

For each table matching the filter:

4. **Null rate** > 20% on non-nullable-intent columns (id, fk, dates).
5. **Constant columns** — `COUNT(DISTINCT col) = 1`.
6. **Duplicate primary keys** — `COUNT(*) > COUNT(DISTINCT pk_col)`.
7. **Stale timestamps** — max date column older than 7 days (configurable).
8. **Negative values** in columns named like `*amount*`, `*price*`, `*quantity*`, `*count*`.
9. **Future dates** in any date/timestamp column.

## Steps

1. **List target tables**:
   ```sql
   SELECT table_name
   FROM ${input:catalog:main}.information_schema.tables
   WHERE table_schema = '${input:schema:silver}'
     AND table_type   = 'BASE TABLE'
     AND table_name LIKE '${input:tableFilter:%}'
   ORDER BY table_name;
   ```

2. **Get all columns at once**:
   ```sql
   SELECT table_name, column_name, data_type, is_nullable
   FROM ${input:catalog:main}.information_schema.columns
   WHERE table_schema = '${input:schema:silver}'
     AND table_name LIKE '${input:tableFilter:%}'
   ORDER BY table_name, ordinal_position;
   ```

3. **Get all constraints**:
   ```sql
   SELECT tc.table_name, tc.constraint_name, tc.constraint_type, kcu.column_name
   FROM ${input:catalog:main}.information_schema.table_constraints tc
   JOIN ${input:catalog:main}.information_schema.key_column_usage  kcu
     ON  tc.constraint_name = kcu.constraint_name
     AND tc.table_schema    = kcu.table_schema
     AND tc.table_name      = kcu.table_name
   WHERE tc.table_schema = '${input:schema:silver}';
   ```

4. **Per table, build ONE aggregate query** combining checks 1, 4, 5, 6, 7, 8, 9. Example template:
   ```sql
   SELECT
       COUNT(*)                                          AS row_count,
       COUNT(`<col>`)                                    AS non_null_<col>,
       COUNT(DISTINCT `<col>`)                           AS distinct_<col>,
       SUM(CASE WHEN `<amount_col>` < 0 THEN 1 ELSE 0 END) AS negative_<amount_col>,
       SUM(CASE WHEN `<date_col>` > CURRENT_TIMESTAMP() THEN 1 ELSE 0 END) AS future_<date_col>,
       MAX(`<date_col>`)                                 AS latest_<date_col>
   FROM ${input:catalog:main}.${input:schema:silver}.<table>;
   ```

5. **For each declared FK**, run an orphan check:
   ```sql
   SELECT COUNT(*) AS orphan_count
   FROM ${input:catalog:main}.${input:schema:silver}.<child>  c
   LEFT JOIN ${input:catalog:main}.${input:schema:silver}.<parent> p
     ON c.`<fk_col>` = p.`<pk_col>`
   WHERE c.`<fk_col>` IS NOT NULL AND p.`<pk_col>` IS NULL;
   ```

## Severity

| Finding                              | Severity |
| ------------------------------------ | -------- |
| Duplicate PK                         | critical |
| Orphan FK > 0                        | critical |
| Empty table                          | high     |
| Null rate > 50% on id/fk/date column | high     |
| Constant column                      | medium   |
| Stale timestamp > 7 days             | medium   |
| Negative amount/price/quantity       | medium   |
| Future date                          | medium   |
| Null rate 20-50%                     | low      |

## Output

1. **Executive summary** — # tables scanned, # findings by severity, top 3 issues.
2. **Findings table** — table | column | check | severity | count | sample value.
3. **Recommended actions** — grouped by severity, each with a concrete next step (add constraint, backfill, dedupe, etc.).
4. **Re-run command** — show the prompt invocation so the user can re-audit after fixes.
