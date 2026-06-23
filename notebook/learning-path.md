# %% [markdown]
# # Top Customers (30d) — Visualization
#
# Runs [`sql/gold/top_customers_30d.sql`](../sql/gold/top_customers_30d.sql) against the
# Databricks SQL warehouse and renders charts with Plotly.
#
# **How it works**
#
# - Reads the same `.sql` file the rest of the repo uses (single source of truth).
# - Connects via `databricks-sql-connector` to the warehouse configured in `.env`.
# - Returns a pandas DataFrame; charts are interactive Plotly figures.
#
# **Setup (one-time)**
#
# ```bash
# pip install databricks-sql-connector pandas plotly python-dotenv
# ```
#
# Create a `.env` (already in `.gitignore`):
# ```
# DATABRICKS_SERVER_HOSTNAME=<workspace>.cloud.databricks.com
# DATABRICKS_HTTP_PATH=/sql/1.0/warehouses/<warehouse_id>
# DATABRICKS_TOKEN=<pat>
# ```

# %%
from __future__ import annotations

import os
from pathlib import Path

import pandas as pd
import plotly.express as px
from databricks import sql
from dotenv import load_dotenv

load_dotenv()

REPO_ROOT = Path(__file__).resolve().parents[1]
QUERY_FILE = REPO_ROOT / "sql" / "gold" / "top_customers_30d.sql"


def run_query(sql_text: str) -> pd.DataFrame:
    """Execute SQL on the Databricks SQL warehouse and return a DataFrame."""
    with sql.connect(
        server_hostname=os.environ["DATABRICKS_SERVER_HOSTNAME"],
        http_path=os.environ["DATABRICKS_HTTP_PATH"],
        access_token=os.environ["DATABRICKS_TOKEN"],
    ) as conn, conn.cursor() as cur:
        cur.execute(sql_text)
        return cur.fetchall_arrow().to_pandas()


# %%
query_text = QUERY_FILE.read_text(encoding="utf-8")
df = run_query(query_text)
df

# %% [markdown]
# ## Chart 1 — Revenue per customer (horizontal bar)
#
# Horizontal bar is easier to read than vertical when customer names are long.

# %%
fig_bar = px.bar(
    df.sort_values("total_revenue"),
    x="total_revenue",
    y="customer_name",
    orientation="h",
    text="total_revenue",
    title="Top 10 customers by revenue — last 30 days",
    labels={"total_revenue": "Revenue ($)", "customer_name": "Customer"},
)
fig_bar.update_traces(texttemplate="$%{text:,.0f}", textposition="outside")
fig_bar.update_layout(yaxis={"categoryorder": "total ascending"}, height=500)
fig_bar.show()

# %% [markdown]
# ## Chart 2 — Order count vs. revenue (scatter)
#
# Highlights customers who are big-by-volume vs. big-by-ticket-size.

# %%
fig_scatter = px.scatter(
    df,
    x="order_count",
    y="total_revenue",
    size="total_revenue",
    hover_name="customer_name",
    title="Order volume vs. revenue",
    labels={"order_count": "Orders (last 30d)", "total_revenue": "Revenue ($)"},
)
fig_scatter.update_layout(height=500)
fig_scatter.show()

# %% [markdown]
# ## Chart 3 — Revenue share (treemap)
#
# Treemap is a good fit when you want to show concentration of revenue across the top N.

# %%
fig_tree = px.treemap(
    df,
    path=["customer_name"],
    values="total_revenue",
    title="Revenue share — top 10 customers (last 30d)",
)
fig_tree.update_traces(textinfo="label+percent root+value")
fig_tree.show()

# %% [markdown]
# ## Export
#
# Optional: write the charts out as standalone HTML for sharing without a Python environment.

# %%
out_dir = REPO_ROOT / "out" / "top_customers_30d"
out_dir.mkdir(parents=True, exist_ok=True)
fig_bar.write_html(out_dir / "revenue_bar.html")
fig_scatter.write_html(out_dir / "orders_vs_revenue.html")
fig_tree.write_html(out_dir / "revenue_treemap.html")
print(f"Wrote 3 HTML charts to {out_dir}")
