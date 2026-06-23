# From Zero to a Locally-Rendered Chart

A focused learning path. **Goal:** by the end you will have used Copilot + the Databricks MCP server to query Unity Catalog, save the SQL as a versioned artifact, and render a chart **locally in VS Code**.

Every step below is on the critical path to that outcome. Side topics (PySpark, mutations, DLT, lineage) are out of scope here — see [Next steps](#next-steps) at the end.

> **Mode:** all prompts assume Copilot Chat in **Agent Mode** with the `databricks` MCP server enabled. Replace example tables (e.g. `main.silver.orders`) with names that exist in your workspace.

---

## The end state

When you finish you will have:

```
your-repo/
├─ sql/gold/<your_query>.sql            # the query, versioned, with a header comment
└─ notebooks/<your_query>_viz.py        # reads the .sql, renders a Plotly chart locally
```

…and a chart open in the VS Code output panel.

---

## Table of Contents

- [Step 1 — Verify setup](#step-1--verify-setup)
- [Step 2 — Find a table worth charting](#step-2--find-a-table-worth-charting)
- [Step 3 — Draft a small SELECT](#step-3--draft-a-small-select)
- [Step 4 — Shape the data so it charts well](#step-4--shape-the-data-so-it-charts-well)
- [Step 5 — Validate the numbers](#step-5--validate-the-numbers)
- [Step 6 — Save the query as an artifact](#step-6--save-the-query-as-an-artifact)
- [Step 7 — Generate the visualization notebook](#step-7--generate-the-visualization-notebook)
- [Step 8 — Render locally and iterate](#step-8--render-locally-and-iterate)
- [Daily-driver cheat sheet (viz workflow)](#daily-driver-cheat-sheet-viz-workflow)
- [Troubleshooting](#troubleshooting)
- [Next steps](#next-steps)

---

## Step 1 — Verify setup

**Why:** you can't chart what you can't query.

### MCP works

> What MCP tools do you have available?

> List the catalogs I can access, then list schemas in `main`, then describe `main.silver.orders`.

✅ Three tool-call cards appear (`list_catalogs`, `list_schemas`, `describe_table`) and Copilot summarizes the table. If not, switch the chat mode to **Agent** and toggle on the `databricks` server in the MCP panel.

### Local Python env exists

In a terminal:

```bash
python -m pip install databricks-sql-connector pandas plotly python-dotenv pyarrow
```

Create `.env` at the repo root (already gitignored):

```
DATABRICKS_SERVER_HOSTNAME=<workspace>.cloud.databricks.com
DATABRICKS_HTTP_PATH=/sql/1.0/warehouses/<warehouse_id>
DATABRICKS_TOKEN=<personal-access-token>
```

You don't need to run anything yet — just confirm the file and packages are in place.

---

## Step 2 — Find a table worth charting

**Why:** a good chart starts with a table that has a clear measure and a clear dimension (revenue × customer, events × day, etc.).

> Which tables in `main.gold` look like fact tables (transactions, events, measures)? Use `list_tables` and `describe_table` to decide.

> Pick the one that has both a numeric measure and a date column. Tell me which you'd recommend for a "top N by revenue over time" chart, and why.

> Show me 5 sample rows from that table so I can see the shape.

✅ You should now know exactly one table you want to chart and what its key columns are.

---

## Step 3 — Draft a small SELECT

**Why:** start tiny, prove the connection, then grow.

> Write a SELECT returning the 10 most recent rows of `<table-from-step-2>`. Run it.

> Count the rows in that table.

> Give me the min and max of its date column.

✅ Three tool calls, three answers in chat. You've now read live data through MCP.

---

## Step 4 — Shape the data so it charts well

**Why:** raw rows rarely make a useful chart. You want a small DataFrame with a label column and one or two numeric columns.

Pick **one** of these depending on what your table supports — they all produce chart-friendly output (≈10–30 rows, 1 label + 1–2 metrics):

**Top-N by revenue:**
> Top 10 customers by revenue in `<your-table>` for the last 30 days. Return `customer_id`, `customer_name`, `order_count`, `total_revenue`. Run it.

**Daily trend:**
> Daily count of events in `<your-table>` for the last 30 days. Return `event_date`, `event_count`. Run it.

**Top-N per group (needs a window function):**
> Top 3 products by revenue per category last quarter from `<your-table>`. Use `QUALIFY ROW_NUMBER()`. Run it.

Then refine in plain English:

> Switch the date column to `order_date` and add `region IN ('NA','EU')`.

> Give me the same shape but for the last 90 days instead of 30.

✅ You have a chart-ready result set in chat (~10–30 rows, named columns, sensible types).

---

## Step 5 — Validate the numbers

**Why:** never put a chart in front of anyone with numbers you haven't sanity-checked. With MCP this is one prompt.

> Run the query and **also** run: row count of the underlying data, distinct count of the label column, and NULL count on the join/key column. Tell me if anything looks suspicious.

> Confirm the sum of the metric in my result equals the total over the same window in the source table.

✅ The numbers reconcile. If they don't, Copilot will usually tell you where the gap is.

---

## Step 6 — Save the query as an artifact

**Why:** the notebook in the next step reads this file. Versioning the SQL keeps it reviewable and reusable.

> Save the final query to `sql/gold/<descriptive_name>.sql` with a header comment that includes:
> - Purpose
> - Inputs (table names) and Output columns
> - Engine (Databricks SQL, DBR 15.x)
> - Cadence (ad-hoc / daily)
>
> Style: fully qualify tables as `catalog.schema.table`, CTE-first, no `SELECT *`, partition filter on the date column.

✅ A `.sql` file exists in `sql/gold/`. Example shape: [sql/gold/top_customers_30d.sql](sql/gold/top_customers_30d.sql).

---

## Step 7 — Generate the visualization notebook

**Why:** this is the artifact that runs locally and produces a chart.

> Generate `notebooks/<same-name>_viz.py` as a `# %%`-cell Python script that:
>
> 1. Loads `.env` via `python-dotenv`.
> 2. Reads the SQL text from `sql/gold/<descriptive_name>.sql`.
> 3. Connects via `databricks-sql-connector` and runs the query into a pandas DataFrame using `fetchall_arrow().to_pandas()`.
> 4. Renders a Plotly chart appropriate to the result shape:
>    - top-N → horizontal bar
>    - time series → line
>    - top-N per group → grouped bar or treemap
> 5. Adds a markdown header cell explaining setup and the `.env` keys required.
> 6. Includes an optional final cell that writes the figure to `out/<name>.html`.
>
> Use only: `pandas`, `plotly.express`, `databricks-sql-connector`, `python-dotenv`, `pyarrow`. No Spark, no Databricks runtime required.

✅ A `.py` notebook exists in `notebooks/`. Example shape: [notebooks/top_customers_30d_viz.py](notebooks/top_customers_30d_viz.py).

---

## Step 8 — Render locally and iterate

**Why:** this is the moment of truth — chart on screen.

1. Open the generated `notebooks/<name>_viz.py` in VS Code.
2. Click **Run Cell** above the first `# %%` block. VS Code launches an interactive Python session.
3. Run each cell top-to-bottom (`Shift+Enter`).
4. The Plotly figure renders in the **Interactive** output panel — hover, zoom, pan.

If a cell errors:

> The notebook cell failed with this error: `<paste>`. Diagnose and fix.

Iterate on the chart **without re-running the query** (the DataFrame `df` is in memory):

> Add data labels to the bars and format them as `$1.2M`.

> Sort descending by revenue and highlight the top 3 bars in a different color.

> Convert this to a treemap so revenue share is obvious.

> Add a horizontal reference line at the median.

🎉 Goal achieved — a versioned query, a versioned notebook, and a chart rendered locally.

---

## Daily-driver cheat sheet (viz workflow)

Memorize these — they cover 90% of the loop.

| Need | Prompt |
|---|---|
| Find a chart-worthy table | "Which tables in `main.<schema>` have a numeric measure and a date column?" |
| Sample the data | "Show me 5 rows from `main.schema.table`." |
| Build a chart-ready query | "Top N `<dim>` by `<metric>` for the last `N` days. Run it." |
| Validate | "Run it and also run row count + NULL check on the key. Anything off?" |
| Save the SQL | "Save the final query to `sql/gold/<name>.sql` with a header comment." |
| Generate the viz notebook | "Generate `notebooks/<name>_viz.py` that reads that SQL and renders a Plotly `<chart-type>`." |
| Tweak the chart in place | "Sort descending, format labels as $X.XM, highlight top 3." |
| Export | "Add a final cell that writes the figure to `out/<name>.html`." |

---

## Troubleshooting

| Symptom | Try this |
|---|---|
| "No tools available" in chat | Switch chat mode to **Agent**; toggle on `databricks` in the MCP panel. |
| `UNAUTHENTICATED` from MCP | Reset MCP inputs (Command Palette → "MCP: Reset Inputs") and re-enter the PAT. |
| `databricks-sql-connector` import fails | `pip install databricks-sql-connector pyarrow` in the same Python env VS Code is using. |
| Notebook hangs on the first query | Warehouse is cold-starting; wait 30–60s or use a Serverless warehouse. |
| `KeyError: 'DATABRICKS_TOKEN'` | `.env` not loaded — confirm `load_dotenv()` runs before `os.environ[...]` and `.env` is at repo root. |
| Plotly chart doesn't render | Install `plotly` in the active interpreter; in VS Code make sure the **Jupyter** extension is installed (needed for the Interactive window). |
| Wrong interpreter | Bottom-right of VS Code → pick the interpreter that has the packages installed. |
| Numbers look wrong on the chart | Re-run Step 5 validation before changing the chart code. |

---

## Next steps

After your first chart is rendering, these are natural follow-ons (each is one focused chat session):

- **Parameterize the SQL** — accept a date range or region, regenerate the chart.
- **Multiple charts in one notebook** — bar + scatter + treemap of the same data.
- **Schedule it** — convert the `.sql` to a Databricks SQL Alert / Dashboard for non-engineers.
- **Streamlit wrapper** — turn the notebook into a small local dashboard.
- **Reusable prompt files** — create `.github/prompts/explore-table.prompt.md` and `/review-query.prompt.md` so this loop becomes one keystroke.

For the full reference (setup details, conventions, safety contract, all MCP tools), see [docs/copilot-for-database-queries.md](docs/copilot-for-database-queries.md).

---

*Keep this file open in a side editor while you practice. Copilot reads it as context — you can say "do Step 5 on the table I just queried" and it will know what you mean.*
