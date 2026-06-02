# Telecom Subscriber & Churn Analytics

An end-to-end data analysis project built with **Oracle SQL**, analyzing a telecom company's subscriber base, network usage, and payment behavior to **proactively identify customers at risk of churning**.

> The key finding: 9 customers are at high churn risk — and 4 of them still appear **"Active"** in the system. Standard status reports hide this risk; SQL analysis reveals it.

---

## 📊 Project Overview

The project analyzes **80 subscribers** across **4 relational tables** (1,205+ records) and answers real business questions through four analysis stages:

| Stage | Focus | Example Questions |
|-------|-------|-------------------|
| **I. Profile Analysis** | Demographics & geography | Age segmentation, city distribution, registration trends |
| **II. Usage Traffic** | Network behavior | Top users, voice/data overage, passive customers |
| **III. Financial** | Revenue & payments | Tariff revenue, debt analysis, payment discipline |
| **IV. Churn Risk** | Customer retention | Who is about to leave, and why |

---

## 🗂️ Database Schema

Four tables connected through primary and foreign keys for referential integrity:

- **`tariff_plans`** (25 rows) - tariff packages, fees, free allowances
- **`subscribers`** (80 rows) - customer demographics and status
- **`call_data_records`** (650 rows) - calls, internet, and SMS activity
- **`billing_history`** (450 rows) - invoices and payment status

---

## 🔍 Key Insights

- **Hidden churn risk:** 9 high-risk customers identified; 4 still flagged "Active" by the system.
- **The tenure paradox:** Churned (3.3 yrs) and Suspended (3.5 yrs) customers have *longer* tenure than Active ones (2.7 yrs), loyalty is not about how long they stay.
- **Upsell opportunity:** 16 customers exceeded their data limit (4x more than voice), the biggest revenue opportunity.
- **Payment risk:** 41% of invoices are problematic (unpaid or late), creating cash-flow risk.
- **Most loyal segment:** Seniors churn the least (6.1%), while the Middle-Aged group is the highest risk (17.5%).

---

## 🛠️ Techniques Used

- Joins (`INNER`, `LEFT`) across multiple tables
- Aggregation & grouping (`GROUP BY`, `SUM`, `COUNT`, `AVG`)
- Conditional logic (`CASE WHEN`, `DECODE`)
- Window functions (`ROW_NUMBER() OVER (PARTITION BY ...)`)
- Date functions (`MONTHS_BETWEEN`, `ADD_MONTHS`, `SYSDATE`)
- `NVL` / null handling, `HAVING`, subqueries & CTEs (`WITH`)

---

## 📁 Repository Contents

| File | Description |
|------|-------------|
| `telecom_subscribers_prohect.sql` | All SQL scripts (DDL + analysis queries) |
| `Telecom_Analysis_EN.xlsx` | Excel workbook with charts and insights |
| `Telecom_Presentation_EN.pptx` | Presentation deck |
| `*.csv` | Source datasets |

---

## 🚀 How to Run

1. Create the tables using the `CREATE TABLE` scripts in the `.sql` file.
2. Import the four CSV files into the corresponding tables (Insert method).
3. Verify row counts: `tariff_plans=25`, `subscribers=80`, `call_data_records=650`, `billing_history=450`.
4. Run the analysis queries in order (sections I–IV).

---

## 👤 Author

**Babak Suleymanov** — Computer Science student, ADA University
First independent SQL data analysis project · 2026
