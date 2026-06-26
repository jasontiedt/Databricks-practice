# Databricks MCP + visualization — self-paced tasks

A graduated set of 15-20 minute exercises. Work through them in order, or
jump to a stage that matches your current focus. Each task lists a **goal**,
**steps**, and **done when** criteria so you know when to move on.

> **Prereqs.** A working `.vscode/mcp.json` connected to a Databricks SQL
> warehouse you have read access to, with at least one catalog containing
> tables you can `SELECT` from. You also need GitHub Copilot Chat in VS Code
> and Python 3.11+ on `PATH`. The companion prompt files live under
> `.github/prompts/` (run them from chat with `/explore-schema`,
> `/profile-table`, etc.).
>
> **No assumptions about the data.** These tasks do **not** assume any
> particular catalog, schema, or table layout — you'll discover what you have
> in Task 1.1 and reuse those names for the rest of the path.
>
> **Override prompt defaults.** The prompt files default to `catalog=main`
> and `schema=silver`. When you invoke them, VS Code will ask for those
> inputs — type your actual catalog and schema names instead of accepting
> the defaults. (You can also update the defaults once in
> `.github/copilot-instructions.md` so you don't keep retyping them.)

---

## Tool reference — what's already wired up

Every task below relies on artifacts that already live in this repo. Skim
this table before Stage 1 so you know what each one does, then bookmark this
section.

### Prompt files (`.github/prompts/`) — invoke from chat with `/<name>`

| Prompt | What it does | Used in |
|---|---|---|
| [/explore-schema](../.github/prompts/explore-schema.prompt.md) | Walks a catalog/schema, lists tables, suggests analyses | Task 1.1, 5.1 |
| [/describe-table](../.github/prompts/describe-table.prompt.md) | Full schema dump for one table (columns, constraints, sample rows) | Task 1.2, 5.1 |
| [/profile-table](../.github/prompts/profile-table.prompt.md) | Per-column null/distinct/min/max profile + issue flags | Task 2.1, 5.1 |
| [/visualize-column](../.github/prompts/visualize-column.prompt.md) | Auto-picks histogram / bar / line for a single column | Task 2.2, 3.2 |
| [/correlate-columns](../.github/prompts/correlate-columns.prompt.md) | Pearson correlation + scatter for two numeric columns | Task 2.2 |
| [/time-series-report](../.github/prompts/time-series-report.prompt.md) | Daily + monthly rollup with trend chart and anomalies | Task 2.5, 5.1 |
| [/data-quality-audit](../.github/prompts/data-quality-audit.prompt.md) | Schema-wide null/dup/orphan/freshness audit | Task 2.6, 5.1 |
| [/nl-to-sql](../.github/prompts/nl-to-sql.prompt.md) | Natural-language question → schema-grounded SQL | Task 1.3, 5.1 |

### Instruction files (`.github/`) — auto-loaded by Copilot

| File | Scope | Why you should read it |
|---|---|---|
| [copilot-instructions.md](../.github/copilot-instructions.md) | always | Project context, default catalog/schema, mutation safety rules |
| [databricks-sql.instructions.md](../.github/instructions/databricks-sql.instructions.md) | `**/*.sql` | Dialect rules, naming, performance defaults you should follow when writing SQL |
| [databricks-mcp.instructions.md](../.github/instructions/databricks-mcp.instructions.md) | always | How Copilot must interact with the MCP server (ground in `information_schema`, never invent names) |
| [data-visualization.instructions.md](../.github/instructions/data-visualization.instructions.md) | always | Chart-type decision table, Mermaid conventions, downsampling rules |
| [notebook.instructions.md](../.github/instructions/notebook.instructions.md) | `notebook/**` | Conventions for the journal you're currently reading |

The tasks below both **use** these artifacts (invoking the prompts, citing
the instruction rules) and **extend** them (you'll customize, fork, and add
to them as you go).

---

## Stage 0 — One-time setup (10 min)

Before Stage 1, write down (in a scratch note or at the top of
`notebook/learning-path.md`) the values you'll reuse throughout these tasks:

- **Catalog** I'm working in: `_______`
- **Schema** I'm working in: `_______`
- **Three tables** in that schema I want to learn about: `_______`, `_______`, `_______`
- A **wide table** (10+ columns) for profiling exercises: `_______`
- A table with a **date/timestamp** column for time-series exercises: `_______`
- A table with at least **two numeric columns** for correlation exercises: `_______`

If you don't know any of these yet, leave them blank — Task 1.1 will help
you fill them in. Whenever a later task says *"pick a table"*, prefer one
from this list so your work compounds.

---

## Stage 1 — Get oriented with the MCP server

### Task 1.1 — First contact (15 min)
**Goal.** Confirm the Databricks MCP server is wired up and discover what catalogs, schemas, and tables you actually have access to.

**Steps.**
1. Open Copilot Chat in agent mode.
2. Ask: *"List every catalog the warehouse can see."* Copilot should call the MCP `execute_sql` tool with `SHOW CATALOGS`.
3. Pick one catalog from the result. Ask: *"List schemas in `<that catalog>` and the table count in each."*
4. Pick **one schema** that looks interesting. Run the [`/explore-schema`](../.github/prompts/explore-schema.prompt.md) prompt against it, typing your real catalog and schema into the inputs.
5. Record your chosen catalog, schema, and the most promising tables from the report into the Stage 0 worksheet so every later task can reuse them.

**Done when.** You can name your catalog and schema, 3 tables inside that schema, their approximate row counts, and at least one column from each. The `/explore-schema` report shows a populated **table inventory** and at least one **suggested follow-up** that names a real table.

**Stretch.** Manually re-run the underlying queries from `queries/schema_and_visualize.sql` sections 1–3 and compare the raw output to what `/explore-schema` produced. Where did the prompt summarize? Where did it omit?

---

### Task 1.2 — Schema deep-dive (10 min)
**Goal.** Use a prompt to get an authoritative table description and learn what "grounded in `information_schema`" looks like in practice.

**Steps.**
1. Pick a table from your Stage 0 worksheet.
2. Run the [`/describe-table`](../.github/prompts/describe-table.prompt.md) prompt against it.
3. Open [`databricks-mcp.instructions.md`](../.github/instructions/databricks-mcp.instructions.md) side-by-side and verify the prompt actually followed the **Discovery before generation** rules — every column and constraint in the output should be traceable to an `information_schema` query Copilot ran.
4. Save the report as `notebook/reports/<table>-schema.md` for reuse in later stages.

**Done when.** You have a one-page schema reference, you can point to the specific `information_schema` queries that produced each section, and you can explain what each column likely represents in plain English.

**Stretch.** **Extend** `/describe-table` — add a new section to the prompt body that pulls table-level stats (last modified, file count, size). Re-run and confirm the new section appears.

---

### Task 1.3 — Your first guided query (20 min)
**Goal.** Author and run a non-trivial SQL through the MCP server against **your** data, then audit the result against the project's instruction files.

**Steps.**
1. Pick a question that makes sense for the tables you discovered in Task 1.1. Generic patterns that work for almost any dataset:
   - *"What are the top 10 `<grouping_column>` values by `<numeric_column>`?"*
   - *"How many rows per `<categorical_column>` exist in `<table>`?"*
   - *"What's the most recent value in `<date_column>` for `<table>`?"*
2. Run the [`/nl-to-sql`](../.github/prompts/nl-to-sql.prompt.md) prompt with your question. When it asks for `catalog` and `schema`, type your real values from the Stage 0 worksheet.
3. Read the generated SQL **before** running it. Spot at least one assumption it made (join key, time filter, column choice).
4. **Audit it against the rules.** Open [`databricks-sql.instructions.md`](../.github/instructions/databricks-sql.instructions.md) and check: three-part names? `LIMIT` present? snake_case identifiers? approximate functions where the table is large? Note any rule the prompt violated.
5. Run the query through the MCP server.
6. Save the final working SQL to `queries/<descriptive_name>.sql` with a header comment explaining the question and the date you ran it. Apply any fixes from step 4 before saving.

**Done when.** The query runs, returns ≤ 1000 rows, follows every rule in `databricks-sql.instructions.md`, and you can defend every line of it to a colleague.

**Stretch.** Re-run the same question with a different aggregation (`AVG` instead of `SUM`, weekly instead of daily) and diff the SQL changes.

---

## Stage 2 — Get fluent with Copilot for query generation

### Task 2.1 — Profile-driven exploration (15 min)
**Goal.** Use Copilot to surface data-quality surprises before you build on a table.

**Steps.**
1. Use the **wide table** (10+ columns) you recorded in the Stage 0 worksheet. If you don't have one yet, run `SHOW TABLES` again and pick the widest one you can find.
2. Run [`/profile-table`](../.github/prompts/profile-table.prompt.md). Type your real catalog, schema, and table into the prompt inputs.
3. Read the issue flags (high nulls, constants, skew). For each flagged column, write a single sentence: *"This matters because…"* or *"This is fine because…"*.
4. Pick the most surprising flag and write a follow-up query to investigate it.

**Done when.** You have a one-page "things I would warn a teammate about" note for that table.

**Stretch.** **Extend the prompt.** Open `.github/prompts/profile-table.prompt.md` and add one new issue-detection rule that catches something specific to your data (e.g. "flag string columns where >5% of values are whitespace-only", or "flag email columns missing `@`"). Re-run and confirm your rule fires.

---

### Task 2.2 — Compare two columns (15 min)
**Goal.** Build intuition for correlation, both numerically and visually, by chaining two prompts.

**Steps.**
1. Use the table you noted for correlation in the Stage 0 worksheet (or run a quick query against `information_schema.columns` filtered to `data_type IN ('int','bigint','double','float','decimal')` to find candidates).
2. Pick two numeric columns you suspect are **related** in your data.
3. First, run [`/visualize-column`](../.github/prompts/visualize-column.prompt.md) once for each column individually. Note the chart type each one picked and what the distribution looks like in isolation.
4. Then run [`/correlate-columns`](../.github/prompts/correlate-columns.prompt.md) on the pair. Predict the Pearson `r` before looking at the result. Were you right?
5. Repeat step 4 with two columns you expect to be **unrelated** to confirm what near-zero correlation looks like in your data.

**Done when.** You can articulate the difference between `r = 0.95`, `r = 0.4`, and `r = 0.02` for *your* dataset, not just in the abstract. You can also explain why each individual column's distribution (from step 3) affects how to interpret the correlation.
---

### Task 2.3 — Author your own prompt (20 min)
**Goal.** Internalize the prompt-file pattern by writing one that fits **your** data.

**Steps.**
1. Pick a task you find yourself repeating against your tables (e.g. "show top N grouped by some column for the last N days", "compare this period vs the same period last year", "find rows where two columns disagree").
2. Copy `.github/prompts/nl-to-sql.prompt.md` as a starting point and rename it.
3. Edit the frontmatter `description` and replace the body with your own steps + output format.
4. Use `${input:foo:default}` syntax for the variable parts — including `catalog` and `schema` so the prompt is reusable across environments.
5. Invoke it from chat and refine until you get a clean result in one shot.

**Done when.** You can run your prompt twice in a row, with different inputs, and get useful output both times.

---

### Task 2.4 — Tighten the guardrails (10 min)
**Goal.** Make the project's instruction files actually reflect your environment.

**Steps.**
1. Open [`.github/copilot-instructions.md`](../.github/copilot-instructions.md). Replace the default `catalog: main` / `schema: silver` with your Stage 0 values so prompts use the right defaults out of the box.
2. Skim the four files under [`.github/instructions/`](../.github/instructions/). Pick the **one** you'll bump into most often (typically `databricks-sql.instructions.md` or `databricks-mcp.instructions.md`) and replace at least two `<!-- CUSTOMIZE -->` markers with rules your team actually follows.
3. Add one new "What NOT to do" bullet in `copilot-instructions.md` based on a real mistake Copilot made for you this week.
4. Re-run an earlier prompt and confirm the new defaults and rules take effect.

**Done when.** Prompts use the right defaults without overrides, your highest-leverage instruction file has team-specific rules in it, and Copilot stops repeating the mistake you just guarded against.

**Stretch.** Repeat step 2 for the remaining three instruction files when you have time — each one tightens a different part of the workflow.

---

### Task 2.5 — Time-series report (15 min)
**Goal.** Produce a polished time-series narrative using the prompt that owns this pattern.

**Steps.**
1. Use the table with a date/timestamp column you noted in the Stage 0 worksheet. If you don't have one, run this against `information_schema.columns`:
   ```sql
   SELECT table_name, column_name, data_type
   FROM <catalog>.information_schema.columns
   WHERE table_schema = '<schema>'
     AND data_type IN ('date','timestamp','timestamp_ntz');
   ```
2. Pick a numeric column to roll up. If you only want event counts, use `1` and the prompt will count rows.
3. Run [`/time-series-report`](../.github/prompts/time-series-report.prompt.md). Provide catalog, schema, table, date column, metric column, and aggregation.
4. Save the rendered report as `notebook/reports/<topic>-timeseries.md`.

**Done when.** The report contains a populated monthly chart, daily chart, anomaly list, and trend commentary — all grounded in your real data, all consistent with the rules in [`data-visualization.instructions.md`](../.github/instructions/data-visualization.instructions.md).

**Stretch.** For each anomaly the prompt flagged, confirm with a follow-up query against the raw data. **Or** extend `/time-series-report` to also compute week-over-week percent change in SQL.

---

### Task 2.6 — Schema-wide quality audit (20 min)
**Goal.** Run the heaviest prompt in the kit — a full data-quality audit across an entire schema.

**Steps.**
1. Pick the schema you've been working in (from the Stage 0 worksheet).
2. Optionally set a table filter to scope the audit (e.g. `dim_%` or `%fact%`) if your schema is large.
3. Run [`/data-quality-audit`](../.github/prompts/data-quality-audit.prompt.md) with your catalog, schema, and filter.
4. Read the executive summary first. For each **critical** finding (duplicate PK, orphan FK > 0), open a follow-up chat to drill in.
5. Pick one finding you can actually fix or escalate. Capture it in `notebook/reports/dq-findings.md` with: table, column, check, count, severity, owner, next action.

**Done when.** You have a saved findings doc that lists at least three real issues from your schema, ranked by severity, with concrete next actions — not just a copy of the prompt's output.

**Stretch.** **Extend** the prompt's severity table in `data-quality-audit.prompt.md`: add a domain-specific rule and severity for it (e.g. "price < cost" → critical, "address missing country" → medium).

---

## Stage 3 — Visualize locally

### Task 3.1 — Bridge: SQL → pandas (15 min)
**Goal.** Get query results into a Python DataFrame on your laptop.

**Steps.**
1. `pip install databricks-sql-connector pandas python-dotenv`
2. Create a `.env` (it's gitignored) with `DATABRICKS_SERVER_HOSTNAME`, `DATABRICKS_HTTP_PATH`, and `DATABRICKS_TOKEN`.
3. Reuse the `run_query` helper pattern from [learning-path.md](learning-path.md) to load one of your queries from `queries/` and print `df.head()` and `df.describe()`.

**Done when.** You can run `python -c "import scripts.X; X.run()"` (or equivalent) and see DataFrame output without re-typing the SQL.

**Stretch.** Wrap the loader in a function that takes a SQL filename and returns a DataFrame, then commit it to `scripts/db.py`.

---

### Task 3.2 — Plotly Express, two charts (15 min)
**Goal.** Build interactive charts that you can hand to non-engineers as HTML — using Copilot's chart picks as a baseline.

**Steps.**
1. Take the DataFrame from Task 3.1. Pick two columns to visualize.
2. **Baseline from the prompt.** For each column, run [`/visualize-column`](../.github/prompts/visualize-column.prompt.md) and note which chart type it picked and why. This is your spec.
3. Implement those two picks in Plotly Express. Aim for one **bar** and one **line or scatter** (substitute if your data doesn't support either).
4. Confirm each pick aligns with the decision table in [`data-visualization.instructions.md`](../.github/instructions/data-visualization.instructions.md). If your Plotly chart disagrees with the prompt's pick, note why.
5. Export each figure with `fig.write_html("out/<name>.html")`.

**Done when.** You have two standalone `.html` files, both chart picks are justified against the instruction file's rules, and any prompt-vs-implementation disagreement is documented.

**Stretch.** Add a third chart (treemap or sunburst) over a categorical column to show share / hierarchy.

---

### Task 3.3 — Matplotlib for static reports (15 min)
**Goal.** Practice the "print-friendly" path when an HTML chart is not an option.

**Steps.**
1. `pip install matplotlib seaborn`
2. Re-render two of the Task 3.2 charts in matplotlib.
3. Save them as 1200×800 PNGs with `plt.savefig(..., dpi=150, bbox_inches="tight")`.
4. Compare side by side with the Plotly HTML versions. Note one thing each format does better.

**Done when.** PNGs render cleanly in a markdown preview of `notebook/learning-path.md` (`![](../out/bar.png)`).

---

### Task 3.4 — Hand-rolled HTML dashboard (20 min)
**Goal.** Build a small dashboard with zero framework — pure HTML + Chart.js.

**Steps.**
1. Run a query through the MCP server and have Copilot export the result as a JSON array.
2. Save it to `out/dashboard/data.json`.
3. Create `out/dashboard/index.html` with:
   - A `<script src="https://cdn.jsdelivr.net/npm/chart.js">` include.
   - One `<canvas>` per chart.
   - A `fetch("./data.json")` block that wires the data into `new Chart(...)`.
4. Open it in a browser via `python -m http.server 8000 --directory out/dashboard`.

**Done when.** The page loads, charts render from the JSON, and you can drop new data into `data.json` and reload to see updates.

**Stretch.** Add a `<select>` filter that switches between two metrics in the JSON.

---

### Task 3.5 — Streamlit mini-app (20 min)
**Goal.** Wrap a query + chart in an interactive web app you can demo.

**Steps.**
1. `pip install streamlit`
2. Create `apps/explore.py`:
   - Use `st.text_input` for a SQL filename from `queries/`.
   - Load it, run it through your `db.py` helper, cache with `@st.cache_data`.
   - Render `st.dataframe(df)` and one `st.plotly_chart(fig)`.
3. Run `streamlit run apps/explore.py`.

**Done when.** You can change the input, the cache invalidates, and the chart updates.

**Stretch.** Add a `st.date_input` that injects a `WHERE date >= :start` filter into the SQL.

---

### Task 3.6 — DuckDB for offline iteration (15 min)
**Goal.** Iterate on transforms locally without re-billing the warehouse.

**Steps.**
1. `pip install duckdb`
2. Save the result of a MCP query to `out/sample.parquet`.
3. Open a Python REPL or notebook and run the same analytical query against the parquet file through DuckDB. Adapt the column names to whatever you saved — e.g.:
   ```python
   import duckdb
   con = duckdb.connect()
   con.execute(
       "SELECT <some_categorical_col>, COUNT(*) "
       "FROM 'out/sample.parquet' "
       "GROUP BY 1 "
       "ORDER BY 2 DESC LIMIT 10"
   ).fetchdf()
   ```
4. Compare the DuckDB result with the warehouse result to confirm semantics match.

**Done when.** You have a local Parquet snapshot + DuckDB query you can iterate on offline.

---

## Stage 4 — Share your work

### Task 4.1 — Embed charts in markdown (15 min)
**Goal.** Produce a single-file report that combines narrative + charts.

**Steps.**
1. Pick a finding from any earlier task.
2. Write a short markdown report in `notebook/reports/<topic>.md` with sections: *Question*, *Method*, *Result*, *Caveats*.
3. Embed two assets: one PNG (from Task 3.3) and one link to an HTML chart (from Task 3.2).
4. Ask Copilot to review for clarity and tighten the prose.

**Done when.** A teammate could read the report top-to-bottom and reproduce it from the linked SQL files.

---

### Task 4.2 — Export to a shareable bundle (15 min)
**Goal.** Package a query + chart + readme so someone without Databricks access can review it.

**Steps.**
1. Create `out/bundles/<topic>/` and put inside:
   - `query.sql` (the SQL you ran)
   - `result.csv` (frozen output)
   - `chart.html` (Plotly export from Task 3.2)
   - `README.md` (1 paragraph: question + answer + as-of timestamp)
2. Open `chart.html` in a browser to confirm it renders standalone.

**Done when.** A non-Databricks user could open the folder, double-click `chart.html`, and understand the finding from `README.md` — no setup required.

**Stretch.** Zip the folder for emailing, or commit it under `out/bundles/` for teammates to pull.

---

### Task 4.3 — Quarto or nbconvert (optional, 20 min)
**Goal.** Render a notebook to HTML/PDF on demand.

**Steps.**
1. Either install [Quarto](https://quarto.org) or `pip install nbconvert`.
2. Take `notebook/learning-path.md` (or convert it to `.qmd` / `.ipynb` first).
3. Render to HTML: `quarto render notebook/learning-path.qmd --to html` (or `jupyter nbconvert --to html`).
4. Inspect the output and tweak metadata until charts and tables render correctly.

**Done when.** A teammate can read the rendered HTML without VS Code or Databricks.

---

## Stage 5 — Capstone

### Task 5.1 — End-to-end mini-analysis (20 min × 2 sittings)
**Goal.** Chain every prompt in the kit on a question you care about, using each artifact for what it does best.

**Steps.**
1. **Sitting 1 — explore + build (20 min).**
   - Pick a real question.
   - Use [`/explore-schema`](../.github/prompts/explore-schema.prompt.md) to refresh your map of the schema.
   - Pick the most relevant table and run [`/describe-table`](../.github/prompts/describe-table.prompt.md) on it.
   - Run [`/profile-table`](../.github/prompts/profile-table.prompt.md) on the same table; note any quality issue that would invalidate the answer.
   - Use [`/nl-to-sql`](../.github/prompts/nl-to-sql.prompt.md) to generate the query. Save it to `queries/`.
2. **Sitting 2 — visualize + share (20 min).**
   - If your result has a date dimension, also run [`/time-series-report`](../.github/prompts/time-series-report.prompt.md) on it.
   - Use [`/visualize-column`](../.github/prompts/visualize-column.prompt.md) to pick the right chart for the headline metric.
   - Load result into pandas; build one interactive (Plotly) and one static (matplotlib) chart, both consistent with [`data-visualization.instructions.md`](../.github/instructions/data-visualization.instructions.md).
   - Write a 3-paragraph report under `notebook/reports/`.
   - Bundle as in Task 4.2.

**Done when.** The bundle README cites which prompts and instruction rules produced each artifact (e.g. *"chart pick justified by data-visualization.instructions.md § chart selection; SQL grounded via /nl-to-sql"*). A colleague can act on the bundle without asking you a clarifying question.

---

## Stage 6 — Extend the toolkit

These tasks have you grow the prompt + instruction set so it keeps fitting
your work as it evolves.

### Task 6.1 — Compose a chained prompt (20 min)
**Goal.** Author a single prompt that internally orchestrates several existing ones, so a teammate can do a full table review in one command.

**Steps.**
1. Create `.github/prompts/analyze-table.prompt.md`.
2. In the body, instruct the agent to run the following sequence for a given table:
   1. `/describe-table` (skip if a recent report exists under `notebook/reports/`).
   2. `/profile-table`.
   3. For each column flagged numeric-high-cardinality, run `/visualize-column`.
   4. If a date column exists, run `/time-series-report` against the largest numeric column.
3. Specify a single combined **Output** section: schema summary → quality issues → visualizations → suggested next steps.
4. Add `${input:catalog}`, `${input:schema}`, and `${input:table}` inputs.
5. Test on a real table from your worksheet. Iterate until one invocation produces a complete review.

**Done when.** Running `/analyze-table` produces a single coherent report — not four loosely-joined ones — and you can re-run it on any table without editing the prompt.

**Stretch.** Add a `${input:depth:quick,deep:quick}` input. `quick` skips the visualizations; `deep` runs everything.

---

### Task 6.2 — Author a new instruction file (15 min)
**Goal.** Codify a convention that none of the existing instruction files yet covers.

**Steps.**
1. Pick a domain that keeps biting you. Examples:
   - Python data-loading conventions → `python-data.instructions.md` (`applyTo: '**/*.py'`).
   - Report-writing voice and structure → `reports.instructions.md` (`applyTo: 'notebook/reports/**'`).
   - Streamlit app conventions → `streamlit.instructions.md` (`applyTo: 'apps/**/*.py'`).
2. Create the file under `.github/instructions/` with proper YAML frontmatter (`applyTo`, `description`).
3. Write 5–10 concrete rules. Each rule should be testable — "prefer X over Y" rather than "write good code".
4. Trigger the new file by opening a matching file in VS Code and starting a chat. Confirm the rules influence Copilot's output.

**Done when.** The instruction file is loaded automatically for the right file glob, and you can show one chat response that obeys a rule you authored.

---

### Task 6.3 — Publish a custom chat mode (20 min, optional)
**Goal.** Lock Copilot into a strict persona for one of your repeating workflows.

**Steps.**
1. Create `.github/chatmodes/analyst.chatmode.md` (or whichever persona fits).
2. Restrict the tool list to read-only Databricks MCP + file reads. No shell, no file writes.
3. In the body, paste the most important rules from your customized `databricks-mcp.instructions.md` and `databricks-sql.instructions.md` so the mode is self-contained even if the instruction files change.
4. Switch to the mode in chat and run Task 5.1 inside it. Note where the restricted toolset forces a different (better?) workflow.

**Done when.** You can hand the mode to a teammate as a safer default for ad-hoc exploration.

---

## How to track progress

Add a checklist to your personal copy of `learning-path.md`:

```markdown
- [ ] 0   One-time setup                  (10 min)
- [ ] 1.1 First contact                   (15 min)
- [ ] 1.2 Schema deep-dive                (10 min)
- [ ] 1.3 First guided query              (20 min)
- [ ] 2.1 Profile-driven exploration      (15 min)
- [ ] 2.2 Compare two columns             (15 min)
- [ ] 2.3 Author your own prompt          (20 min)
- [ ] 2.4 Tighten the guardrails          (10 min)
- [ ] 2.5 Time-series report              (15 min)
- [ ] 2.6 Schema-wide quality audit       (20 min)
- [ ] 3.1 SQL → pandas                    (15 min)
- [ ] 3.2 Plotly Express                  (15 min)
- [ ] 3.3 Matplotlib static               (15 min)
- [ ] 3.4 HTML + Chart.js                 (20 min)
- [ ] 3.5 Streamlit                       (20 min)
- [ ] 3.6 DuckDB offline                  (15 min)
- [ ] 4.1 Markdown report                 (15 min)
- [ ] 4.2 Shareable bundle                (15 min)
- [ ] 4.3 Quarto / nbconvert              (20 min, optional)
- [ ] 5.1 Capstone                        (40 min, 2 sittings)
- [ ] 6.1 Chained /analyze-table prompt   (20 min)
- [ ] 6.2 Authored a new instruction file (15 min)
- [ ] 6.3 Custom chat mode                (20 min, optional)
```

Estimated total focused time: **~6 hours** (or ~5 hours if you skip the
optional tasks), split across whatever number of sittings works for you.
