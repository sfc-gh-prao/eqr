# Equity Residential × Snowflake - EQR IT Huddle
## Cortex Code: Hands-On Lab — Snowsight UI Edition

**Duration:** 100 minutes (5 min setup + 95 min lab, includes discussion breaks)  
**Format:** Self-paced with guided checkpoints  
**Environment:** Your own Snowflake demo account — Snowsight (no local install required)  

---

## Module 0 — Environment Setup (5 min)

> **Do this before anything else.** Each person has their own Snowflake demo account. You'll load the lab dataset directly into your account — it takes about 3–4 minutes to run.

### Step 0.1 — Log In

1. Open your browser and go to https://go.dataops.live/eqr-it-tech-huddle/instructions
2. Register for a demo account using your email address
3. Bookmark the URL provided at the end of the registration process. This will be the account you will be using for the lab.
4. Disregard the "Lab Instructions" link provided at the end of the registration. This README.md will be your lab guide
5. Sign into your Snowflake demo account with the credentials you were provided

### Step 0.2 — Create a new workspace

1. In the left nav, click **Projects → Workspaces**
2. Click **+ Create workspace** at the top left → **Git workspace**
3. Enter the repository URL: https://github.com/sfc-gh-prao/eqr
4. Enter workspace name: EQR HOL
5. Click **+ API Integration**  
   Name: **EQR_HOL**  
   Allowed Prefixes: **https://github.com/sfc-gh-prao/eqr**  
   Leave the default selections for the remaining options and click **Create**  
7. When you return to the create workspace menu, select **Public repository** and click **Create**

> **Why ACCOUNTADMIN?** The setup script creates a database, a warehouse, and several schemas. This requires account-level privileges. You'll switch to a less-privileged role for the rest of the lab.

### Step 0.3 — Run the Setup Script

1. If you were able to successfully create a Git workspace, you will see a **setup.sql** file appear
4. Click **Run All** (▶▶ button, or `Cmd+Shift+Enter` / `Ctrl+Shift+Enter`)
5. Watch the progress — each section runs sequentially. You'll see output for each INSERT statement
6. The final step outputs a row-count summary table — **wait until you see this before moving on**

> **Expected output** at the end:
> ```
> BUILDINGS              50
> UNITS               5,000
> RESIDENTS           4,750
> LEASES              5,500
> MAINTENANCE_REQUESTS 15,000
> RENT_PAYMENTS       54,000
> OPERATING_EXPENSES   6,000
> USER_PERMISSIONS       200
> ACCESS_LOGS        100,000
> QUERY_LOG           10,000
> ```
> If any table shows 0 rows, let your instructor know before proceeding.

### Step 0.4 — Switch to SYSADMIN

Once setup is complete, switch your active role to **`SYSADMIN`** — this is the role you'll use for the rest of the lab.

1. Click the role name in the top-right corner
2. Select `SYSADMIN`

---

## Welcome

Today you'll experience how Cortex Code — Snowflake's AI assistant built directly into the Snowsight browser UI — transforms how your team interacts with data. You'll go from zero to running analytics, building dashboards, and shipping a live app, all without writing a single line of SQL from scratch.

The dataset you'll work with mirrors your world: apartment communities across the US, leases, residents, maintenance operations, financials, and IT security logs.

---

## Lab Data Model

You'll be working in the **`EQR_LAB`** database, organized across four schemas:

| Schema | What's Inside |
|--------|--------------|
| `PROPERTIES` | Buildings, units, residents, leases, maintenance requests |
| `FINANCE` | Rent payments, operating expenses |
| `SECURITY` | Access logs, user permissions |
| `IT_INFRASTRUCTURE` | Query execution history |

**Key numbers:** 50 buildings · 5,000 units · ~4,750 residents · 15,000 maintenance requests · 54,000 rent payments · 100,000 access events

---

## How to Use Cortex Code in Snowsight

1. You're already logged into your demo account from Module 0
2. You should already be in the EQR HOL workspace you created in Module 0
3. In the workspace, click **+Add New** and select **SQL File**. Name it **modules.sql** -- this will be the file where you Cortex Code generated SQL will appear
4. Open Cortex Code if it's not already open from Module 0. It is a blue star icon on the right side of the screen.
5. The following modules will walk through example prompts for you to run in your environment

**Power-user tip:** Type `#EQR_LAB.PROPERTIES.BUILDINGS` in a prompt to auto-inject the table's schema and sample rows as context. Cortex Code will write smarter queries when it knows your table structure.

---

## Module 1 — Getting Oriented (10 min)

> **Your setup is complete and you're on SYSADMIN.** Now open Cortex Code and let's go.

### Step 1.1 — Set Your Context

Type this as your first prompt:

```
Set my context to use the EQR_LAB database and the EQR_HOL_WH warehouse for this session.
```

### Step 1.2 — Explore the Data Model

```
What tables and schemas exist in the EQR_LAB database? Give me a one-sentence description of each table and tell me how many rows are in each one.
```

> **What to notice:** Cortex Code queries the information schema, counts rows across all tables, and describes each one — something that would normally require writing 10+ queries manually.

### Step 1.3 — Meet Your Data

```
Using #EQR_LAB.PROPERTIES.BUILDINGS, show me a summary of our property portfolio. How many buildings do we have, how are they spread across states, and what's the total number of units?
```

```
What is the overall occupancy rate across the entire portfolio? Which state has the highest occupancy and which has the lowest?
```

---

## Module 2 — Instant Stats, No SQL Required (15 min)

**Goal:** Get real answers from your data in seconds, regardless of your SQL background. Each prompt below is designed for a specific persona on your team — try the ones relevant to you, or all of them.

### For Everyone — Portfolio Pulse

```
Show me the top 10 buildings by monthly rent revenue. For each building include: city, state, number of occupied units, total monthly rent, and average rent per unit.
```

```
How many leases are expiring in the next 90 days? Group by building and state. Flag any building where more than 20% of leases expire in that window.
```

```
What percentage of maintenance requests are currently open vs. resolved? Show me the breakdown by priority level (Emergency, High, Medium, Low).
```

### For Platform Engineers & DBAs

```
Using #EQR_LAB.IT_INFRASTRUCTURE.QUERY_LOG, show me the top 10 most expensive queries by bytes scanned. Who ran them, when, and how long did they take?
```

```
Which users have the highest average query execution time? Are there any queries that ran for more than 5 minutes?
```

### For the Security Team

```
Using #EQR_LAB.SECURITY.ACCESS_LOGS, show me all failed access attempts in the last 30 days. Group by building and access point. Which building had the most failures?
```

```
From the USER_PERMISSIONS table, find any users who have access to more than 3 buildings but have not logged in within the last 60 days. These could be stale permissions.
```

### For Analysts & Product Owners

```
What is our late payment rate? Show the percentage of rent payments that were received after the due date, broken down by month for the last 12 months.
```

```
Which building has the highest maintenance cost per unit? Is there a pattern between building age and total maintenance spend?
```


---

## Module 3 — Data Quality Detection + Build a Live Streamlit App (18 min)

**Goal:** Use Cortex Code to scan for data quality issues, then instantly convert those findings into a shareable Streamlit in Snowflake dashboard.

### Step 3.1 — Data Quality Scan

```
Run a comprehensive data quality audit on the EQR_LAB database. For each table, check for:
- Null values in columns that should never be null (IDs, dates, amounts)
- Duplicate records on primary key columns
- Referential integrity: are there orphaned records (e.g. a lease pointing to a unit_id that doesn't exist)?
- Logical date errors (e.g. lease end_date before start_date, resolved_date before submitted_date)
- Out-of-range values (e.g. monthly_rent = $0 or monthly_rent > $15,000)
Summarize the findings in a table showing: table name, issue type, number of affected rows, and severity.
```

> **What to watch for:** Notice that Cortex Code doesn't just run one query — it generates a series of targeted checks and aggregates the results into a single summary. This would normally take a DBA hours to write.

### Step 3.2 — Drill Into Specific Issues

```
I saw there are lease date errors. Show me the specific records where lease end_date is before start_date. Include the unit_id, building name, resident name, and both dates.
```

```
Find residents who appear to have two or more simultaneously active leases. This is likely a data entry error or a duplicate record issue. Show me the full details.
```

```
In the RENT_PAYMENTS table, find any payments where the payment_date is more than 120 days after the due_date. Are these legitimate late payments or data errors? Show context around each record.
```

### Step 3.3 — Build the Data Quality Streamlit App


Now watch how fast we can turn this audit into a live app:

```
Build a Streamlit in Snowflake app called EQR_DATA_QUALITY_DASHBOARD.

Show:
- A header that reads "EQR Data Quality Monitor" styled with a navy blue (#003057) background and white text
- Four summary numbers at the top, one per schema in EQR_LAB (PROPERTIES, FINANCE, SECURITY, IT_INFRASTRUCTURE), each showing the total null count across the most important column in that schema: monthly_rent for PROPERTIES, amount_paid for FINANCE, building_id for SECURITY, and execution_seconds for IT_INFRASTRUCTURE
- A table with one row per table in EQR_LAB showing: schema name, table name, row count, and the count of null values in that table's most important column
- A bar chart of null count by table name
- A button labeled "Refresh" that reruns the app

Just build out the python file. Do not deploy it.
```


Once the python file has been generated, do the following:
1. Copy all the code in the python file in your workspace
2. Go to **Projects** -> **Streamlit**
3. Click on **+ Streamlit App**
4. For the App title, enter **EQR_DATA_QUALITY**
5. For the App location, select EQR_LAB for the database and PUBLIC for the schema
6. Select **Run on container** for the runtime
7. Select the EQR_HOL_WH for the query warehouse
8. When the app is first created, you will see a template with some python code. Overwrite it with the code you copied from your workspace.
9. Click **Run** at the top

> **Note:** You may see an error when running the Streamlit application. With the application open, use Cortex Code on the right to troubleshoot. Start the prompt with "There's an error in the app:" and paste the error. You will be given an option to copy and paste the entire code
   
> **What just happened?** You went from discovering data quality problems to having a live, branded dashboard that your entire organization can access — in under 5 minutes. No front-end development, no deployment pipeline, no infrastructure to manage.


---

## Module 4 — Query Troubleshooting & Optimization (8 min)

**Goal:** Diagnose and fix a slow-running query using Cortex Code as your debugging partner.

### Step 4.1 — Analyze a Slow Query

The following query is taking over 2 minutes to run. Paste the entire block below into the Cortex Code chat:

```
The following SQL query is running very slowly — over 2 minutes on our warehouse. Please analyze why it is slow, explain the root cause in plain English, and provide an optimized version with an explanation of every change you made.

-- SLOW QUERY START
SELECT
    b.building_id,
    b.name            AS building_name,
    b.city,
    b.state,
    COUNT(DISTINCT r.resident_id)                                           AS total_residents,
    SUM(rp.amount_paid)                                                     AS total_collected,
    SUM(rp.amount_due)                                                      AS total_due,
    ROUND((SUM(rp.amount_paid) / NULLIF(SUM(rp.amount_due),0)) * 100, 2)  AS collection_rate_pct,
    AVG(DATEDIFF('day', mr.submitted_date, mr.resolved_date))              AS avg_resolution_days
FROM   EQR_LAB.PROPERTIES.BUILDINGS          b
LEFT JOIN EQR_LAB.PROPERTIES.UNITS           u   ON b.building_id   = u.building_id
LEFT JOIN EQR_LAB.PROPERTIES.LEASES          l   ON u.unit_id       = l.unit_id
LEFT JOIN EQR_LAB.PROPERTIES.RESIDENTS       r   ON l.resident_id   = r.resident_id
LEFT JOIN EQR_LAB.FINANCE.RENT_PAYMENTS      rp  ON l.lease_id      = rp.lease_id
LEFT JOIN EQR_LAB.PROPERTIES.MAINTENANCE_REQUESTS mr ON b.building_id = mr.building_id
WHERE  rp.due_date >= DATEADD('year', -2, CURRENT_DATE())
GROUP  BY b.building_id, b.name, b.city, b.state
ORDER  BY total_collected DESC;
-- SLOW QUERY END
```

> **The root cause (what to look for):** Cortex Code should identify that `MAINTENANCE_REQUESTS` is joined on `building_id` without being pre-aggregated. This means every row in RENT_PAYMENTS gets cross-joined against every maintenance record for that building, creating millions of intermediate rows before the GROUP BY can collapse them.

### Step 4.2 — Query Health Check

```
Look at #EQR_LAB.IT_INFRASTRUCTURE.QUERY_LOG. Which queries show signs of full table scans (high bytes_scanned relative to rows_produced)? For the top 5 worst offenders, suggest what optimization strategy would help — clustering keys, search optimization, or query rewrite.
```

```
Are there any users in the QUERY_LOG who are consistently running inefficient queries? If so, what training or guardrails would you recommend?
```

---

## Module 5 — Build Your Own App (7 min)

**Goal:** Ship something useful before the lab ends. Choose the prompt that matches your role.

Pick the app that resonates with your work. Use the prompt exactly as written, then try the enhancement prompts once it's running.

RUN the prompt for one of the options below first. Once the python file has been generated, do the following:
1. Copy all the code in the python file in your workspace
2. Go to **Projects** -> **Streamlit**
3. Click on **+ Streamlit App**
4. For the App title, enter any app name. For example, **EQR_PORTFOLIO_DASHBOARD**
5. For the App location, select EQR_LAB for the database and PUBLIC for the schema
6. Select **Run on container** for the runtime
7. Select the EQR_HOL_WH for the query warehouse
8. When the app is first created, you will see a template with some python code. Overwrite it with the code you copied from your workspace.
---

### Option A — For Platform Engineers & DBAs
**Warehouse Health Monitor**

```
Build a Streamlit in Snowflake app called EQR_WAREHOUSE_MONITOR using data from EQR_LAB.IT_INFRASTRUCTURE.QUERY_LOG.

Show:
- Four summary numbers at the top: total queries in the table, number of distinct users, number of failed queries, and the single highest execution time in seconds
- A bar chart showing how many queries each user has run — show the top 10 users by query count
- A table of the 10 queries with the highest bytes_scanned — show user_name, warehouse_name, bytes_scanned, execution_status, and the first 60 characters of query_text

Just build out the python file. Do not deploy it.
```

---

### Option B — For the Security Team
**Security Audit Dashboard**

```
Build a Streamlit in Snowflake app called EQR_SECURITY_AUDIT using data from EQR_LAB.SECURITY.

Show:
- Four summary numbers at the top: total rows in ACCESS_LOGS, count of rows where result is 'Failed', count of rows where result is 'Denied', and count of users in USER_PERMISSIONS where is_active is false
- A bar chart of failed and denied access event count by access_point — one bar per access point type
- A table of the 20 most recent rows in ACCESS_LOGS where result is 'Failed' or 'Denied' — show building_id, username, access_point, result, and event_timestamp
- A table of all users from USER_PERMISSIONS where is_active is false — show username, department, role_name, and last_login

Just build out the python file. Do not deploy it.
```

---

### Option C — For Analysts & Product Owners
**Executive Portfolio Dashboard**

```
Build a Streamlit in Snowflake app called EQR_PORTFOLIO_DASHBOARD using data from EQR_LAB.

Show:
- Four summary numbers at the top: total number of buildings, total number of units, number of units where status is 'Occupied', and number of open maintenance requests
- A bar chart of unit count by state — show how many units exist in each state
- A table of the top 10 buildings by total unit count — include building name, city, state, property type, and total units
- A table of the 10 buildings with the most open maintenance requests — include building name, city, state, and open request count

Just build out the python file. Do not deploy it.
```

---

### Option D — For DBAs & Everyone
**Data Health Monitor**

```
Build a Streamlit in Snowflake app called EQR_DATA_HEALTH_MONITOR using data from EQR_LAB.

Show:
- Four summary numbers at the top: total number of tables in EQR_LAB, total row count across all tables (sum them up), number of schemas, and the number of tables with more than 10,000 rows
- A table listing every table in EQR_LAB.PROPERTIES, EQR_LAB.FINANCE, EQR_LAB.SECURITY, and EQR_LAB.IT_INFRASTRUCTURE — show schema name, table name, and row count for each
- A bar chart of row count by table name
- A table showing the 15 most recent rows from EQR_LAB.IT_INFRASTRUCTURE.QUERY_LOG — show user_name, warehouse_name, execution_seconds, and execution_status

Just build out the python file. Do not deploy it.
```

---

### Enhancement Prompts (try these after your app is deployed)

Once your app is running, iterate with these:

```
Add a date range picker to the sidebar so users can filter all charts and tables to a custom time window.
```

```
Make the building name column in any table clickable — clicking a building should filter the entire dashboard to show only that building's data.
```

```
Add a "Download as CSV" button below each data table in the app.
```

```
Add a short explanatory caption below each chart explaining what the user should look for.
```

---

---

## Module 6 — AI Analytics Layer: Semantic Views & Snowflake Agents (20 min)

**Goal:** Package everything you've built into a reusable intelligence layer — a semantic view that encodes business logic as a Snowflake object, and a Cortex Agent any member of your team can query in plain English through Snowflake Intelligence.

This is the shift from "I ran some queries" to "I built something my entire team can use."

---

### Step 6.1 — Create the Semantic View (6 min)

A semantic view is a business model stored in Snowflake. It defines how tables join, what the metrics mean, and which questions it can reliably answer. Cortex Analyst reads it to generate verified SQL from natural language — so every analyst, product owner, and executive works from the same definitions.

```
Using the context from these tables:
#EQR_LAB.PROPERTIES.BUILDINGS
#EQR_LAB.PROPERTIES.UNITS
#EQR_LAB.PROPERTIES.LEASES
#EQR_LAB.FINANCE.RENT_PAYMENTS
#EQR_LAB.FINANCE.OPERATING_EXPENSES
#EQR_LAB.PROPERTIES.MAINTENANCE_REQUESTS

Create a semantic view called EQR_ANALYTICS_VIEW in EQR_LAB.PUBLIC.

Define these relationships:
- buildings joins units on building_id
- units joins leases on unit_id
- leases joins rent_payments on lease_id
- buildings joins operating_expenses on building_id
- units joins maintenance_requests on unit_id

Include dimensions for: city, state, property_type (from buildings); bedrooms, unit status (from units); lease_status (from leases); maintenance category, priority, and status (from maintenance_requests).

Include metrics for: total rent collected (SUM of rent_payments.amount_paid), total operating expenses (SUM of operating_expenses.amount), net operating income (total rent minus total expenses), occupancy rate (occupied units / total units), and open maintenance count.

Include verified queries for:
1. Net operating income ranked by building, flagging any with negative NOI
2. Month-over-month rent collection rate for the past 12 months
3. Average rent by unit type (studio, 1BR, 2BR, 3BR)
4. Average days to resolve a maintenance request by category and priority
5. Tenant lease renewal rate by building
6. Buildings with occupancy below 85% and late payment rate above 15%

Write the complete CREATE SEMANTIC VIEW statement and run it.
```

> **Checkpoint:** Confirm the view was created: `SHOW SEMANTIC VIEWS IN SCHEMA EQR_LAB.PUBLIC;`

---

### Step 6.2 — Create the Analytics Agent (4 min)

Now create a Cortex Agent backed by that semantic view. This agent is what surfaces in Snowflake Intelligence for your business users.

```
Create a Cortex Agent called EQR_ANALYTICS_AGENT in EQR_LAB.PUBLIC using warehouse EQR_HOL_WH.

Configure it with a Cortex Analyst tool that uses the semantic view EQR_LAB.PUBLIC.EQR_ANALYTICS_VIEW.

Give it these system instructions:
"You are an analytics assistant for Equity Residential, a national apartment company. Answer questions about portfolio performance, financial health, occupancy, rent collection, maintenance operations, and building risk. Be concise and data-driven. When asked for projections, explain your methodology. Cite specific buildings, states, or metrics when relevant."

Write and run the CREATE AGENT statement. Then grant USAGE on the agent to role SYSADMIN.
```

> **Checkpoint:** Confirm the agent exists: `SHOW AGENTS IN SCHEMA EQR_LAB.PUBLIC;`

---

### Step 6.3 — Ask the Business Questions (8 min)

Open **Snowflake Intelligence** — click the **Intelligence** icon in the left navigation bar. Find **EQR_ANALYTICS_AGENT** and start a new conversation.

> These are the same analytical questions you've been exploring all session — now they route through a semantic layer with verified business logic.

**Financial Analytics**

```
What is the net operating income for each building? Rank highest to lowest and flag any building with a negative NOI.
```

```
Show me the month-over-month rent collection rate for the past 12 months. Which month had the biggest single-month drop?
```

```
Which unit type — studio, 1BR, 2BR, or 3BR — generates the most rent per unit? Is there a unit mix we should be optimizing for?
```

**Operational Analytics**

```
What is the average number of days to resolve a maintenance request by category and priority? Which category-priority combination is most backlogged?
```

```
What percentage of leases were renewed versus not renewed per building? Which buildings have the best tenant retention?
```

**Cross-Domain Risk Analysis**

```
Find buildings with all three risk factors: occupancy below 85%, late payment rate above 15%, and more than 10 open high-priority maintenance requests. Score each building 1–10 based on severity and explain the scoring logic.
```

```
Show me leases expiring in the next 60 days where the resident has had 2 or more late payments. Sort by building. These are renewal conversations that need to happen now.
```

**Forward-Looking Projections**

```
Based on current occupancy and average monthly rents by state, project total monthly rental revenue 3 months from now assuming current occupancy holds. Compare to actual revenue from 3 months ago.
```

---

## Wrap-Up

### What You Built in 100 Minutes

| Module | What Happened |
|--------|---------------|
| 1 | Explored a 10-table, 4-schema database without writing SQL |
| 2 | Ran portfolio, security, and IT analytics via natural language |
| 3 | Audited data quality across all tables and deployed a live branded dashboard |
| 4 | Diagnosed a multi-million-row intermediate result issue and rewrote the query |
| 5 | Shipped a production-ready Streamlit app in under 7 minutes |
| 6 | Created a semantic view, deployed a Cortex Agent, and queried live data through Snowflake Intelligence |

### What This Means for Your Team

| Persona | Old World | With Cortex Code |
|---------|-----------|-----------------|
| **Platform Engineers** | Write monitoring scripts manually, wait for tickets | Ask for what you need, get live dashboards in minutes |
| **Security Team** | Pull logs manually, build audit reports in Excel | Live anomaly detection dashboard, always current |
| **DBAs** | Debug slow queries alone, document issues in Confluence | AI-assisted diagnosis, optimized query in seconds |
| **Analysts** | Wait for data team to write queries, work with stale exports | Self-service analytics on live data, no bottleneck |
| **Product Owners** | Request KPI reports, get them 2 weeks later | Build your own dashboard, iterate in real time |

### Key Prompting Tips to Take Home

1. **Be specific about what you want.** "Show me occupancy by state" gets a table. "Show me occupancy by state as a bar chart sorted descending, highlight states below 88%" gets something actionable.
2. **Reference tables directly.** Use `#SCHEMA.TABLE` syntax — it gives Cortex Code the column names and sample data it needs to write precise queries.
3. **Iterate.** Your first prompt doesn't have to be perfect. Say "make the chart interactive" or "add a filter by building" and it keeps going.
4. **Ask why, not just what.** "Why is this query slow?" and "What's causing this null pattern?" are just as valid as data questions.
5. **Trust but verify.** Cortex Code is very good, but always review the SQL it generates for large-impact operations.

### Next Steps

- [ ] Request Cortex Code access for your team in your Snowflake account
- [ ] Identify 3 manual reporting processes that could be self-served with this approach
- [ ] Share the Data Quality Dashboard with your data governance stakeholders

---

*Lab prepared by Snowflake Solutions Engineering | EQR Account Team*
*Questions? Contact your SE: Ryan Coy*
