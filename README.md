# SQL BigQuery Data Quality Audit Pipeline

End-to-end SQL data quality audit pipeline built in **Google BigQuery** to profile, standardize, validate, and flag anomalies across approximately **50,000 synthetic employee records**.

The project simulates an institutional data validation workflow where raw operational data must be converted into trusted, review-ready outputs before it can be used for reporting or decision-making.

The pipeline includes:

- Raw data profiling and duplicate analysis
- Set-based cleaning and standardization
- Production-layer preparation
- 17 rule-based data quality checks
- Cross-field reconciliation
- Row-level exception logging
- Severity-based review prioritization
- Validation summaries and audit reconciliation

> All data in this repository is synthetic. No real employee, company, citizen, or government data is included.

---

## Project Overview

Large operational datasets are rarely ready for analysis immediately after ingestion.

Common problems include duplicate identifiers, inconsistent date formats, missing values, mismatched information across related fields, invalid salary ranges, and records that violate business rules.

At smaller volumes these issues may be reviewed manually. At larger volumes, validation needs to become repeatable, traceable, and query-driven.

This project builds that workflow using SQL and Google BigQuery.

The objective is not only to identify bad records, but also to answer:

- What issue was detected?
- Which field was affected?
- Which business rule failed?
- How severe is the issue?
- What action should be taken?
- Which records require review first?
- How many records passed validation?
- Can the reported results be reconciled back to the production dataset?

---

## Architecture

```text
Synthetic CSV
     │
     ▼
employee_profile_raw
     │
     ├── 01. Data Profiling
     │
     ├── 02. Deduplication Analysis
     │
     ▼
emp_prof_staging
     │
     │  Exact-row deduplication
     │  Cleaning
     │  Standardization
     │  Data type conversion
     │
     ▼
emp_prof_prod
     │
     ├── 05. Validation Checks
     │
     ▼
emp_prof_dqlog
     │
     ├── Rule-level exceptions
     ├── Severity
     ├── Affected fields
     └── Recommended actions
     │
     ▼
Quality Reporting
     ├── Validation summary
     ├── Issue summary
     ├── Severity summary
     └── Review prioritization
```

The BigQuery implementation uses **set-based transformations** rather than repeated row-by-row updates. Cleaning logic is consolidated into bulk transformations, while ambiguous or potentially incorrect values are preserved and flagged for review rather than automatically overwritten.

---

## Dataset

The project uses approximately **50,000 synthetic employee-style records** designed to reproduce data quality problems that may occur in large institutional datasets.

Example fields include:

| Field | Description |
| --- | --- |
| `id_num` | 16-character identification number |
| `employee_id` | Employee identifier containing embedded date information |
| `name` | Employee name |
| `branch_id` | Branch or organizational unit |
| `dob` | Date of birth |
| `phone_number` | Employee phone number |
| `start_date` | Employment start date |
| `gender` | Gender category |
| `group_sal` | Salary group |
| `thp` | Take-home pay |
| `email` | Employee email |
| `last_update` | Source update information |

The dataset intentionally contains duplicate records, inconsistent formats, missing values, cross-field mismatches, and business-rule violations.

The 50K dataset is the actual dataset used for this portfolio implementation. The pipeline architecture is designed using set-based SQL patterns that can be applied to larger workloads, but this repository does not claim production testing on millions of rows.

---

## Tools and SQL Concepts

**Platform**

- Google BigQuery
- GoogleSQL / BigQuery Standard SQL

**SQL techniques**

- Common Table Expressions
- Window functions
- `ROW_NUMBER()`
- `COUNT() OVER()`
- `CASE`
- `COUNTIF()`
- `SAFE.PARSE_DATE()`
- `SAFE_DIVIDE()`
- Regular expressions
- Cross-field reconciliation
- Conditional aggregation
- `UNION ALL`
- `CREATE OR REPLACE TABLE AS SELECT`

The repository also retains the original SQL implementation to show how the project evolved before being redesigned for BigQuery.

---

# Pipeline Workflow

## 01. Data Profiling

Before changing the data, the raw dataset is inspected to understand its structure and existing quality problems.

Profiling includes:

- Total row count
- Unique identifier counts
- Exact duplicate detection
- Missing and blank values
- Category distributions
- Salary ranges
- Date-format patterns
- Branch, gender, and salary-group distributions

No source values are modified during this stage.

**BigQuery script:**  
[`01_data_profiling.sql`](bigquery_sql/01_data_profiling.sql)

---

## 02. Deduplication Analysis

Exact duplicate records are identified using `ROW_NUMBER()` across the complete raw record.

This stage is analysis-only. It calculates:

- Exact duplicate rows
- Expected row count after deduplication
- Duplicate ID numbers
- Duplicate employee IDs
- Missing identifiers requiring separate treatment

Exact duplicates and duplicated business identifiers are intentionally treated as different data quality problems.

**BigQuery script:**  
[`02_staging_and_deduplication.sql`](bigquery_sql/02_staging_and_deduplication.sql)

---

## 03. Cleaning and Standardization

Approved transformations are consolidated into a single set-based staging operation.

Examples include:

- Exact-row deduplication
- Branch ID standardization
- Mixed date-format parsing
- Phone-number separator removal
- Leading-zero phone standardization
- Gender standardization
- Salary-group standardization
- Blank email conversion to `NULL`
- Date conversion into BigQuery `DATE`

Values that cannot be safely inferred are **not automatically corrected**. They remain available for validation and exception reporting.

Post-transformation QA checks verify:

- Raw rows − duplicate rows = staging rows
- Expected data types
- Standardized categories
- Phone-number conditions
- THP conditions
- No new exact duplicates were created by standardization

**BigQuery script:**  
[`03_cleaning_standardization.sql`](bigquery_sql/03_cleaning_standardization.sql)

---

## 04. Production Layer

The standardized staging dataset is promoted into the production validation layer.

A run-level `prod_id` is generated using the processing date and a deterministic row sequence so that every validation exception can be traced back to its production record.

Example:

```text
202609150000001
│       │
│       └── record sequence
└────────── processing date
```

This table represents standardized data prepared for validation. It does **not** imply that every record has passed data quality checks.

**BigQuery script:**  
[`04_create_production_table.sql`](bigquery_sql/04_create_production_table.sql)

---

## 05. Validation Checks

A reusable `validation_base` CTE calculates shared validation metrics such as:

- ID occurrence count
- Employee ID occurrence count
- Email occurrence count
- Employee age at start date
- Start-date day
- Expected salary group based on THP

Individual validation rules can then use simpler conditions.

Example:

```sql
SELECT *
FROM validation_base
WHERE age_at_start < 18
   OR age_at_start > 45;
```

This separates:

**how a validation metric is calculated**

from

**what condition causes a record to fail a rule**

which makes the rules easier to inspect and test individually.

**BigQuery script:**  
[`05_validation_checks.sql`](bigquery_sql/05_validation_checks.sql)

---

## 06. Exception Log

All approved validation failures are consolidated into an audit-ready exception table.

Each failed rule creates one exception record.

A single production record can therefore produce multiple exception rows if it fails multiple validation rules.

Example structure:

```text
prod_id
rule_id
issue_category
error_type
affected_field
severity
recommended_action
logged_at
```

`UNION ALL` is used so that every rule failure is retained independently.

The exception-log process also verifies:

- Total issue flags
- Distinct records containing issues
- Issue count by validation rule
- Referential consistency between exception records and production records

**BigQuery script:**  
[`06_exception_log.sql`](bigquery_sql/06_exception_log.sql)

---

## 07. Quality Summary

The final stage converts detailed exception records into stakeholder-friendly reporting outputs.

Reporting includes:

- Total raw records
- Exact duplicates removed
- Production records
- Records with one or more issues
- Records passing all validation rules
- Total issue flags
- Validation pass rate
- Issue count by rule
- Issue count by severity
- Records requiring the most review attention
- Final production-to-validation reconciliation

The reporting layer uses aggregation queries rather than creating unnecessary permanent summary tables.

**BigQuery script:**  
[`07_quality_summary.sql`](bigquery_sql/07_quality_summary.sql)

---

# Validation Rules

The current pipeline contains **17 validation rules**.

| Rule ID | Validation | Severity |
| --- | --- | --- |
| VR001 | Duplicate ID number | High |
| VR002 | Duplicate employee ID | High |
| VR003 | Invalid ID length | High |
| VR004 | Invalid employee ID length | High |
| VR005 | DOB does not match DOB embedded in ID | High |
| VR006 | DOB does not match DOB embedded in employee ID | High |
| VR007 | Start date does not match employee ID | Medium |
| VR008 | Employee start age outside expected range | High |
| VR009 | Start date is not on the expected first day of month | Low |
| VR010 | Salary group does not match expected THP range | Medium |
| VR011 | THP below expected range | Medium |
| VR012 | THP above expected range | Medium |
| VR013 | Duplicate email | Medium |
| VR014 | Missing email | Low |
| VR015 | Missing branch ID | Medium |
| VR016 | Missing phone number | Low |
| VR017 | Invalid phone-number length | Low |

---

# Exception Management

The pipeline distinguishes between **safe standardization** and **issues requiring investigation**.

Safe transformations include formatting changes where the intended value can be determined without changing its business meaning.

Examples:

```text
branch "BR01" → "01"
gender "Female" → "F"
blank email → NULL
phone separators removed
supported date strings → DATE
```

Potentially substantive problems are preserved and flagged rather than automatically corrected.

Examples include:

```text
duplicate employee IDs
DOB mismatches
salary mismatches
invalid identifier structures
unexpected employment start age
```

This reflects a practical data-quality workflow where the analyst identifies and documents an issue, while the source owner or responsible department confirms the correct value.

---

# Main Outputs

## Validation Summary

[`validation_summary.csv`](outputs/validation_summary.csv)

High-level audit metrics showing the overall quality of the production dataset.

Example metrics:

```text
total_raw_rows
duplicate_rows_removed
total_production_records
records_with_issues
records_passed_validation
total_issue_flags
validation_pass_rate
```

---

## Exception Log Sample

[`exception_log_sample.csv`](outputs/exception_log_sample.csv)

A review-ready sample of row-level validation failures.

Instead of exporting only the first records from the exception table, the sample is balanced across validation rules so that multiple issue types are represented.

Example fields:

```text
prod_id
rule_id
issue_category
error_type
affected_field
severity
recommended_action
logged_at
```

---

## Issue Count by Error Type

[`issue_count_by_error_type.csv`](outputs/issue_count_by_error_type.csv)

Aggregated issue counts that show which data quality problems occur most frequently.

This output can be used to identify recurring data-quality patterns and prioritize remediation.

---

## Data Correction Request Template

[`data_correction_request_template.xlsx`](templates/data_correction_request_template.xlsx)

Example operational handoff file for records requiring confirmation from a source owner or responsible department.

The template demonstrates the workflow beyond SQL:

```text
Detect
   ↓
Flag
   ↓
Review
   ↓
Request correction
   ↓
Apply confirmed update
   ↓
Revalidate
```

---

# Accuracy and Reconciliation

The pipeline includes QA checks throughout the workflow rather than validating only the final output.

Examples include:

**Row-count reconciliation**

```text
Raw records
- Exact duplicate rows
= Expected staging records
= Actual staging records
```

**Production reconciliation**

```text
Records passed validation
+ Records requiring review
= Total production records
```

**Exception reconciliation**

Individual validation-rule counts from `05_validation_checks.sql` are compared against the corresponding rule counts materialized in `06_exception_log.sql`.

**Referential QA**

Every `prod_id` in the exception log is verified against the production table.

Expected orphan exception count:

```text
0
```

These checks help ensure that the data quality pipeline itself can be audited.

See:

[`accuracy_proof.md`](docs/accuracy_proof.md)

---

# Final Audit Results

After running the complete BigQuery pipeline, the final metrics can be summarized here:

| Metric | Result |
| --- | ---: |
| Raw records | `TBD` |
| Exact duplicates removed | `TBD` |
| Production records | `TBD` |
| Records requiring review | `TBD` |
| Records passing validation | `TBD` |
| Total issue flags | `TBD` |
| Validation pass rate | `TBD` |

These values should be populated from the final `07_quality_summary.sql` output so that the README remains consistent with the repository results.

---

# Repository Structure

```text
SQL-Data-Quality-Audit-Pipeline/
│
├── README.md
│
├── data/
│   └── synthetic_employee_profile_50000.csv
│
├── sql/
│   └── Original SQL implementation
│
├── bigquery_sql/
│   ├── 01_data_profiling.sql
│   ├── 02_staging_and_deduplication.sql
│   ├── 03_cleaning_standardization.sql
│   ├── 04_create_production_table.sql
│   ├── 05_validation_checks.sql
│   ├── 06_exception_log.sql
│   └── 07_quality_summary.sql
│
├── outputs/
│   ├── validation_summary.csv
│   ├── exception_log_sample.csv
│   └── issue_count_by_error_type.csv
│
├── templates/
│   └── data_correction_request_template.xlsx
│
└── docs/
    ├── validation_rules.md
    └── accuracy_proof.md
```

---

# Original SQL vs BigQuery Version

The repository retains the original SQL implementation while adding a redesigned BigQuery version.

The BigQuery version changes the architecture from sequential row-level transformations toward more scalable set-based processing.

Key changes include:

| Original Implementation | BigQuery Implementation |
| --- | --- |
| Sequential cleaning operations | Consolidated set-based transformation |
| Staging updates | `CREATE OR REPLACE TABLE AS SELECT` |
| Repeated validation calculations | Reusable validation CTE |
| Basic validation output | Standardized exception log |
| Rule summaries | Rule, severity, and record-level prioritization |
| SQL workflow | BigQuery-oriented audit pipeline |

This allows the repository to show both the original solution and how the design was improved after learning BigQuery.

---

# What This Project Demonstrates

This project demonstrates the ability to:

- Profile unfamiliar raw datasets before transformation
- Separate safe standardization from ambiguous corrections
- Build set-based SQL transformations in BigQuery
- Design reusable data-quality validation logic
- Reconcile information across related fields
- Detect duplicates, missing values, format errors, and business-rule exceptions
- Build standardized row-level exception logs
- Assign severity and recommended remediation actions
- Prioritize records requiring manual review
- Reconcile validation results back to production data
- Produce stakeholder-friendly data-quality metrics
- Document an auditable data-validation workflow

---

# Confidentiality

This project is inspired by the type of data-validation work that may occur in large institutional environments.

However:

- All records are synthetic
- All identifiers are fictitious
- Field names and business rules are generalized for portfolio purposes
- No real government, company, employee, customer, or citizen data is included

---

# Project Summary

Built an end-to-end **BigQuery data quality audit pipeline** using approximately **50,000 synthetic employee records**.

The pipeline profiles raw data, removes exact duplicates, standardizes approved fields, applies **17 validation rules**, reconciles related data points, creates an audit-ready row-level exception log, prioritizes issues by severity, and produces quality metrics for stakeholder review.

The project focuses on creating data that is not only cleaner, but also **traceable, reviewable, and trustworthy before reporting**.
