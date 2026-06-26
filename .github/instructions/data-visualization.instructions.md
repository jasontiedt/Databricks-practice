---
applyTo: '**'
description: 'Chart selection and rendering conventions for query results.'
---

# Data visualization conventions

Apply these rules whenever you have query results to visualize.

## Chart selection

Pick the chart from the data shape, not the user's request:

| Result shape                          | Chart                                    |
| ------------------------------------- | ---------------------------------------- |
| Single scalar                         | bolded callout — no chart                |
| Two cols: category + numeric          | Bar chart (top 25, sorted desc)          |
| Two cols: date/timestamp + numeric    | Line chart (downsample to ≤ 90 points)   |
| Two cols: numeric + numeric           | Scatter (downsample to ≤ 5000 points)    |
| One numeric, > 25 distinct values     | Histogram (20 bins)                      |
| One numeric, ≤ 25 distinct values     | Bar chart                                |
| Three+ columns                        | Markdown table + suggest a pivot         |

If the user explicitly asked for a chart type, honor it but note when a
different chart would represent the data better.

## Rendering

- Prefer Mermaid `xychart-beta` for bar and line charts so they render inline.
- Use ASCII bar charts (`█` glyphs) when the data is small (≤ 10 rows) or
  when Mermaid would be too wide.
- Always label both axes with the column name and unit.
- Title the chart with a short, factual phrase (no marketing language).

### Mermaid example

````markdown
```mermaid
xychart-beta
    title "Daily orders, last 30 days"
    x-axis [2026-05-27, 2026-05-28, ...]
    y-axis "order_count" 0 --> 500
    line [120, 140, 95, ...]
```
````

## Downsampling rules

- Time series with > 90 points → bucket to the next coarser grain (day → week → month).
- Scatter with > 5000 points → `TABLESAMPLE (5000 ROWS)`.
- Bar with > 25 categories → top 25 + an "other" bucket with the remaining sum.

## Color & style

- Do not specify colors — let Mermaid pick defaults so themes remain consistent.
- Do not add emojis to chart titles or axes.
- Do not use 3D / pie / donut charts.

<!-- CUSTOMIZE: if you have a preferred dashboard tool (Tableau, Power BI,
Databricks SQL dashboards, Lakeview), note conventions for handoff here.
For example:
- "Always include a `-- viz: line` comment header so the dashboard parser
   knows the intended chart type."
- "Limit aggregations to columns ending in `_metric` or `_count`."
-->

## When NOT to chart

- The result is empty.
- The result is a schema description, DDL, or row count alone.
- The user is debugging SQL — show only the table.
- Confidence in the result is low (recent error, unresolved assumptions).
