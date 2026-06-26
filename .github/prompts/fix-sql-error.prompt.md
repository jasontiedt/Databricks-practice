---
agent: true
description: 'Debug a failing Databricks SQL query, identify root cause, produce a corrected query, and validate with a safe sample run.'
---

# Fix SQL error

Inputs:
- Catalog: `${input:catalog:main}`
- Schema: `${input:schema:silver}`
- Failing SQL: `${input:failingSql}`
- Error message: `${input:errorMessage}`

Use the Databricks MCP server. Focus on root cause and minimal, correct fixes.

## Steps

1. **Classify the failure** from `${input:errorMessage}`:
   - syntax
   - missing table/view
   - missing column
   - type mismatch
   - ambiguous column
   - permissions/access
   - performance/timeout

2. **Ground in schema metadata** before changing SQL:
   ```sql
   SELECT table_name
   FROM ${input:catalog:main}.information_schema.tables
   WHERE table_schema = '${input:schema:silver}'
   ORDER BY table_name;
   ```
   ```sql
   SELECT table_name, column_name, data_type
   FROM ${input:catalog:main}.information_schema.columns
   WHERE table_schema = '${input:schema:silver}'
   ORDER BY table_name, ordinal_position;
   ```

3. **Explain root cause** in 1-3 bullets tied to the exact failing SQL fragment.

4. **Produce corrected SQL**:
   - Keep original intent.
   - Use fully-qualified names (`catalog.schema.table`).
   - Add explicit casts only when needed.
   - Add `LIMIT 100` for validation when result size is unknown.

5. **Run a safe validation query**:
   - If query is read-only, run corrected query with safe limit if applicable.
   - If potentially write-impacting, convert to a read-only validation (`SELECT`, `EXPLAIN`, or sampled equivalent) and state why.

6. **If still failing**, iterate once with a second correction and re-test.

## Output

1. **Root cause**
2. **Corrected SQL** (fenced `sql` block)
3. **Validation result** (success/failure + first rows if successful)
4. **What changed** (brief diff-style bullets)
5. **Next check** (one suggested follow-up test)

## Guardrails

- Do not invent columns/tables.
- Do not claim success without an executed validation step.
- If permissions block execution, provide corrected SQL and exact permission needed.
