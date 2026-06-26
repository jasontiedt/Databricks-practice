---
mode: 'agent'
description: 'Deep schema description for a single Databricks table — columns, types, constraints, comments, and sample rows.'
---

# Describe table

Inputs:
- Catalog: `${input:catalog:main}`
- Schema: `${input:schema:silver}`
- Table: `${input:table}`

Use the Databricks MCP server to run SQL. Resolve everything from query results — never invent columns.

## Steps

1. **Confirm the table exists** and get its type/comment:
   ```sql
   SELECT table_type, comment
   FROM ${input:catalog:main}.information_schema.tables
   WHERE table_schema = '${input:schema:silver}'
     AND table_name   = '${input:table}';
   ```

2. **Column metadata** (compact, sorted by position):
   ```sql
   SELECT column_name, ordinal_position, data_type, is_nullable, comment
   FROM ${input:catalog:main}.information_schema.columns
   WHERE table_schema = '${input:schema:silver}'
     AND table_name   = '${input:table}'
   ORDER BY ordinal_position;
   ```

3. **Extended description** (partitioning, storage, owner):
   ```sql
   DESCRIBE TABLE EXTENDED ${input:catalog:main}.${input:schema:silver}.${input:table};
   ```

4. **Constraints** (if any):
   ```sql
   SELECT tc.constraint_name, tc.constraint_type, kcu.column_name
   FROM ${input:catalog:main}.information_schema.table_constraints tc
   JOIN ${input:catalog:main}.information_schema.key_column_usage  kcu
     ON  tc.constraint_name = kcu.constraint_name
     AND tc.table_schema    = kcu.table_schema
     AND tc.table_name      = kcu.table_name
   WHERE tc.table_schema = '${input:schema:silver}'
     AND tc.table_name   = '${input:table}';
   ```

5. **Row count and a 5-row sample**:
   ```sql
   SELECT COUNT(*) AS row_count FROM ${input:catalog:main}.${input:schema:silver}.${input:table};
   SELECT * FROM ${input:catalog:main}.${input:schema:silver}.${input:table} LIMIT 5;
   ```

## Output

A markdown report with these sections:

1. **Overview** — fully-qualified name, type (TABLE/VIEW), row count, comment.
2. **Columns** — a table: name | type | nullable | position | comment | inferred role (id / fk / measure / dimension / timestamp).
3. **Constraints & partitioning** — PK/FK/unique, partition columns, storage format if surfaced by `DESCRIBE EXTENDED`.
4. **Sample rows** — rendered as a markdown table.
5. **Suggested follow-ups** — 3 concrete prompts (profile, visualize a specific column, time-series on a date column you found).
