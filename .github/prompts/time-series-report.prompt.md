---
mode: 'agent'
description: 'Daily + monthly time-series report of a metric over a date column, with trend chart and callouts.'
---

# Time-series report

Inputs:
- Catalog: `${input:catalog:main}`
- Schema: `${input:schema:silver}`
- Table: `${input:table}`
- Date column: `${input:dateColumn}`
- Metric column: `${input:metricColumn}` (numeric; use `1` for pure event counts)
- Aggregation: `${input:agg|sum,avg,count,min,max:sum}`

Use the Databricks MCP server. Never fabricate values; every number must come from a query.

## Steps

1. **Sanity-check the columns**:
   ```sql
   SELECT MIN(`${input:dateColumn}`) AS earliest,
          MAX(`${input:dateColumn}`) AS latest,
          COUNT(*)                   AS total_rows,
          COUNT(`${input:dateColumn}`)   AS non_null_dates,
          COUNT(`${input:metricColumn}`) AS non_null_metric
   FROM ${input:catalog:main}.${input:schema:silver}.${input:table};
   ```

2. **Daily rollup**:
   ```sql
   SELECT DATE_TRUNC('day', `${input:dateColumn}`)        AS day,
          COUNT(*)                                        AS row_count,
          ${input:agg|sum,avg,count,min,max:sum}(`${input:metricColumn}`) AS metric_value
   FROM ${input:catalog:main}.${input:schema:silver}.${input:table}
   WHERE `${input:dateColumn}` IS NOT NULL
   GROUP BY DATE_TRUNC('day', `${input:dateColumn}`)
   ORDER BY day;
   ```

3. **Monthly rollup**:
   ```sql
   SELECT DATE_TRUNC('month', `${input:dateColumn}`)      AS month,
          COUNT(*)                                        AS row_count,
          ${input:agg|sum,avg,count,min,max:sum}(`${input:metricColumn}`) AS metric_value
   FROM ${input:catalog:main}.${input:schema:silver}.${input:table}
   WHERE `${input:dateColumn}` IS NOT NULL
   GROUP BY DATE_TRUNC('month', `${input:dateColumn}`)
   ORDER BY month;
   ```

4. **Week-over-week change** (on the daily series) — compute in your output, not in SQL: `pct_change = (today - 7_days_ago) / 7_days_ago`.

## Analysis

From the rollup results, derive:

- **Trend** — overall direction (up / down / flat) and approximate slope per month.
- **Seasonality** — day-of-week or month-of-year pattern if obvious.
- **Anomalies** — days where `metric_value` is > 3 stddev from the trailing 30-day mean. List them with values.
- **Gaps** — missing days in the date range.

## Output

1. **Summary** — date range, total rows, total metric, daily average.
2. **Monthly chart** — Mermaid `xychart-beta` line chart of monthly `metric_value`.
3. **Daily chart** — Mermaid `xychart-beta` line chart of daily `metric_value` (downsample to last 90 days if range > 90 days).
4. **Anomalies** — bulleted list with date, value, and z-score.
5. **Trend commentary** — 3-5 sentence summary.
