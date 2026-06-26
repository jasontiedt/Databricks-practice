---
mode: 'agent'
description: 'Pearson correlation + downsampled scatter plot between two numeric Databricks columns.'
---

# Correlate columns

Inputs:
- Catalog: `${input:catalog:main}`
- Schema: `${input:schema:silver}`
- Table: `${input:table}`
- Column X: `${input:colX}`
- Column Y: `${input:colY}`

Use the Databricks MCP server. Verify both columns are numeric before computing correlation.

## Steps

1. **Verify both columns are numeric**:
   ```sql
   SELECT column_name, data_type
   FROM ${input:catalog:main}.information_schema.columns
   WHERE table_schema = '${input:schema:silver}'
     AND table_name   = '${input:table}'
     AND column_name IN ('${input:colX}', '${input:colY}');
   ```
   If either is not numeric (`int`, `bigint`, `float`, `double`, `decimal`), stop and tell the user.

2. **Compute correlation, covariance, and regression slope/intercept**:
   ```sql
   SELECT CORR(`${input:colX}`, `${input:colY}`)             AS pearson_corr,
          COVAR_SAMP(`${input:colX}`, `${input:colY}`)       AS covariance,
          REGR_SLOPE(`${input:colY}`, `${input:colX}`)       AS slope,
          REGR_INTERCEPT(`${input:colY}`, `${input:colX}`)   AS intercept,
          COUNT(*)                                           AS n
   FROM ${input:catalog:main}.${input:schema:silver}.${input:table}
   WHERE `${input:colX}` IS NOT NULL AND `${input:colY}` IS NOT NULL;
   ```

3. **Per-column summary stats** (for axis ranges):
   ```sql
   SELECT MIN(`${input:colX}`) AS min_x, MAX(`${input:colX}`) AS max_x,
          AVG(`${input:colX}`) AS mean_x,
          MIN(`${input:colY}`) AS min_y, MAX(`${input:colY}`) AS max_y,
          AVG(`${input:colY}`) AS mean_y
   FROM ${input:catalog:main}.${input:schema:silver}.${input:table}
   WHERE `${input:colX}` IS NOT NULL AND `${input:colY}` IS NOT NULL;
   ```

4. **Scatter sample** (downsample to 5000 rows for rendering):
   ```sql
   SELECT `${input:colX}` AS x, `${input:colY}` AS y
   FROM ${input:catalog:main}.${input:schema:silver}.${input:table} TABLESAMPLE (5000 ROWS)
   WHERE `${input:colX}` IS NOT NULL AND `${input:colY}` IS NOT NULL;
   ```

## Interpretation

Classify the Pearson coefficient `r`:

| \|r\|     | Strength      |
| --------- | ------------- |
| 0.00-0.19 | very weak / none |
| 0.20-0.39 | weak          |
| 0.40-0.59 | moderate      |
| 0.60-0.79 | strong        |
| 0.80-1.00 | very strong   |

Sign indicates direction. Note that correlation ≠ causation.

## Output

1. **Result** — `r`, n, regression line equation `y = slope * x + intercept`.
2. **Interpretation** — strength + direction in plain English.
3. **Scatter plot** — Mermaid `xychart-beta` of the 5000-row sample with the regression line overlaid.
4. **Caveats** — warn about outliers if `|r|` changes meaningfully after filtering to the 5-95 percentile range (check this only if `n > 1000`).
