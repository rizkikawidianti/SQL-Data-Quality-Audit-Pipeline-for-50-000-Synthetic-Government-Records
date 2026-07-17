# SQL-Data-Quality-Audit-Pipeline-for-50-000-Synthetic-Government-Records
SQL-based data quality audit pipeline for profiling, cleaning, validating, and flagging anomalies in 50,000 synthetic employee records.

# Overview

This project demonstrates a SQL-based data quality audit workflow using a 50,000-row synthetic employee dataset modeled after a large-scale government institution data validation case.

The goal of this project is to show how raw data can be profiled, cleaned, standardized, validated, and converted into review-ready outputs using SQL.

This repository does not contain real government, company, employee, or citizen data. All data used in this project is synthetic and created for portfolio purposes.

## Project Background

In a real institutional environment, large datasets are often used for reporting, monitoring, compliance, and decision-making. When the dataset contains millions of rows, manual validation is not practical.

The challenge is not only finding errors, but also creating a repeatable and auditable process that explains:

- What issue was found
- Which field was affected
- How serious the issue is
- What action should be taken next
- How many records passed or required review

This project recreates that type of workflow using SQL and synthetic data.

## Problem

A large employee-style dataset may contain hidden data quality issues, such as:

- Duplicate ID numbers
- Duplicate employee IDs
- Inconsistent date formats
- Missing or blank values
- Incorrect gender formatting
- Salary group mismatches
- Date of birth mismatches
- Start date mismatches
- Records that violate business rules

If these issues are not detected, the dataset may produce inaccurate reports and reduce stakeholder trust in the analysis.

## Objective

The objective of this project is to build a structured SQL workflow that can:

1. Profile the raw dataset
2. Detect duplicate records
3. Clean and standardize inconsistent fields
4. Create a production-ready table
5. Apply validation and anomaly detection rules
6. Generate a row-level exception log
7. Summarize data quality results for review

## [Dataset](data/synthetic_employee_profile_50000.csv)

The project uses a synthetic employee profile dataset with approximately 50,000 records.

Example fields include:

- ID number
- Employee ID
- Date of birth
- Start date
- Gender
- Salary group
- Take-home pay
- Email

The dataset is synthetic and does not represent any real person, company, or government institution.

## Tools Used

- SQL
- MySQL-style syntax
- Window functions
- Common table expressions
- Conditional logic
- Aggregation queries
- Data validation rules

## Workflow

### 1. Data Profiling

The first step is to understand the raw dataset before making changes.

This includes checking:

- Total row count
- Unique ID count
- Duplicate records
- Missing values
- Minimum and maximum values
- Distinct category values
- Date and salary ranges

File: [01_data_profiling.sql](sql/01_data_profiling.sql)


### 2. Staging and Deduplication

A staging table is created to safely process the raw data before moving it into the final production table.

Duplicate records are identified using SQL window functions and removed from the staging layer.

File: [02_staging_and_deduplication.sql](sql/02_staging_and_deduplication.sql)


### 3. Cleaning and Standardization

In this step, inconsistent values are cleaned and standardized.

Examples include:

- Converting date fields into a consistent format
- Standardizing gender values
- Cleaning salary group values
- Replacing blank emails with null values
- Converting cleaned columns into final data types

File: [03_cleaning_standardization.sql](sql/03_cleaning_standardization.sql)


### 4. Production Table Creation

After cleaning, a production-ready table is created from the staging table.

A stable production ID is generated to support validation tracking and exception logging.

File:c [04_create_production_table.sql](sql/04_create_production_table.sql)


### 5. Validation Checks

Validation rules are applied to detect invalid, inconsistent, or suspicious records.

The checks include:

- Duplicate ID validation
- Duplicate employee ID validation
- Date of birth mismatch checks
- Employee ID structure checks
- Start date mismatch checks
- Start age business rule validation
- Start date rule validation
- Salary group and take-home pay consistency checks
- Duplicate email checks

File: [05_validation_checks.sql](sql/05_validation_checks.sql)


### 6. Exception Log

A review-ready exception log is created from the validation failures.

The exception log captures:

- Production record ID
- Validation Rule ID
- Issue category
- Error type
- Affected field
- Severity level
- Recommended action
- Timestamp

This makes the validation output easier to audit, review, and prioritize.

File: [sql/06_exception_log.sql](sql/06_exception_log.sql)


### 7. Quality Summary

The final step summarizes the validation results into stakeholder-friendly outputs.

The quality summary includes:

- Issue count by category
- Issue count by severity
- Issue count by detailed error type
- Records that should be reviewed first
- Passed records vs review-required records
- Validation pass rate

File: [07_quality_summary.sql](sql/07_quality_summary.sql)


### 8. Remediation and Revalidation

The SQL pipeline identifies records that require review, but data correction often requires confirmation from other departments or source data owners.

In real data quality work, validation does not stop after issues are detected. Some failed records require confirmation from the responsible department before the database can be updated. The responsible department would verify the flagged records and provide corrected values or confirmation. After updates are applied, the validation scripts would be rerun to measure the final validation pass rate.

This reflects the practical data quality cycle: detect, review, correct, revalidate, and report.


## Main Outputs

This project produces three analytical outputs and one operational handoff template.

### 1. [validation_summary.csv](outputs/validation_summary.csv)

A high-level summary of the validation result.

This output is designed for quick review and shows the overall condition of the dataset after the initial validation run.

**Note:** This output represents the initial audit result before remediation. In a real monthly workflow, records requiring review would be sent to the responsible department through a correction request template. After confirmed updates were applied, the validation checks would be rerun to produce the final reporting dataset.

Example metrics:

- Total clean records
- Total issue flags
- Records requiring review
- Passed records
- Review-required records
- Validation pass rate

### 2. [exception_log_sample.csv](outputs/exception_log_sample.csv)

A row-level audit log of validation failures.

This output shows which record failed, what issue was detected, which field was affected, how severe the issue was, and what action should be taken.

Example columns:

```
prod_id
rule_id
issue_category
error_type
affected_field
severity
recommended_action
logged_at
```

### 3. [issue_count_by_error_type.csv](outputs/issue_count_by_error_type.csv)

A summary of recurring data quality issues.

This output helps identify the most common issue types so reviewers can prioritize the biggest data quality risks first.

Example columns:

```
rule_id
error_type
issue_category
severity
total_records
```

### [data_correction_request_template.xlsx](templates/data_correction_request_template.xlsx)

A sample operational handoff template used to request corrected values from the responsible data owner or department.

The file contains records pulled from the production table and exception log where required fields are missing or need confirmation. Blank correction columns are included so the responsible team can provide the correct values before the database is updated and revalidated.

## Repository Structure

```
sql-data-quality-audit-pipeline/
│
├── README.md
│
├── data/
│   └── synthetic_employee_profile_50000.csv
│
├── sql/
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
|
└── docs/
    ├── validation_rules.md
    └── accuracy_proof.md
```

## Key Validation Rules

| Rule Area | Description | Severity |
| --- | --- | --- |
| Duplicate ID | Detects duplicated ID numbers | High |
| Duplicate Employee ID | Detects duplicated employee identifiers | High |
| DOB Mismatch | Compares date of birth fields against embedded ID values | High |
| Start Date Mismatch | Checks whether employee ID start date matches the start date field | Medium |
| Start Age Rule | Flags records where start age is outside the expected policy range | High |
| Start Date Rule | Flags records where start date does not follow the expected day rule | Low |
| Salary Validation | Compares salary group against take-home pay range | Medium |
| Duplicate Email | Detects repeated email values | Medium |

## Proof of Accuracy

The validation process is supported by several accuracy checks:

1. Row count reconciliation between raw, staging, and production tables
2. Duplicate detection using SQL window functions
3. Rule-based validation for each major field
4. Cross-field comparison between ID values, date of birth, and start date
5. Severity classification for prioritization
6. Row-level exception logging for auditability
7. Aggregated issue summaries for stakeholder review

## What This Project Demonstrates

This project demonstrates my ability to:

- Write structured SQL for data quality checking
- Profile raw datasets before cleaning
- Design validation rules based on business logic
- Detect duplicate, invalid, inconsistent, and suspicious records
- Create audit-ready exception logs
- Summarize validation results for stakeholders
- Protect confidential data by using synthetic records in a public portfolio

## Confidentiality Note

This project is inspired by a real data validation workflow applied in an institutional environment. However, all data, table names, field names, and outputs in this repository have been anonymized, generalized, or recreated using synthetic data.

No confidential company, government, employee, or citizen data is included in this repository.

## Recommended Use

This project can be reviewed as a portfolio example for roles such as:

- Data Analyst
- SQL Analyst
- Data Quality Analyst
- Data Governance Analyst
- Business Intelligence Analyst
- Reporting Analyst

## Project Summary

Built a SQL-based data quality audit pipeline that profiles, cleans, validates, and summarizes a 50,000-row synthetic dataset. The workflow produces audit-ready outputs including a validation summary, exception log, and issue breakdown by error type.
