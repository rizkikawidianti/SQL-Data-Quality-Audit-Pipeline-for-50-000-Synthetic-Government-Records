# Accuracy Proof of Employee Master Data Quality Audit

## Purpose

This document explains how the SQL data quality validation process was verified for accuracy.

The goal is to prove that the validation results are reliable, traceable, and review-ready. The project uses a synthetic employee master dataset and applies structured SQL checks to detect duplicate records, format errors, cross-field mismatches, business rule exceptions, salary validation issues, and missing data.

This document does not repeat the validation rules in detail. Those rules are documented separately in `validation_rules.md`.

## What Accuracy Means in This Project

In this project, accuracy means:

1. Records are not accidentally lost during processing.
2. Duplicate records are detected and removed correctly.
3. Cleaned fields follow the expected format.
4. Validation rules correctly identify records that fail business or data quality logic.
5. Failed records are stored in the exception log with enough detail for review.
6. Summary outputs match the records stored in the exception log.
7. Each issue can be traced back to a documented validation rule.

## Accuracy Verification Steps

## 1. Row Count Reconciliation

Row count reconciliation was used to confirm that records were not accidentally lost during the pipeline.

The row count was checked at each major stage:

- Raw dataset
- Staging table
- Deduplicated staging table
- Production table
- Exception log
- Quality summary

### Expected Result

The production record count should equal:

```
raw records - duplicate records removed
```

### Example Check

```
select count(*) as raw_record_count
from employee_profile_raw;

select count(*) as staging_record_count
from emp_prof_staging;

select count(*) as production_record_count
from emp_prof_prod;
```

### Why This Proves Accuracy

This confirms that the pipeline did not accidentally delete, duplicate, or skip records outside the intended deduplication process.

## 2. Duplicate Detection Verification

Duplicate detection was verified using SQL window functions and grouping logic.

The process checks whether duplicate identifiers appear more than once in the production table.

Duplicate checks include:

- Duplicate ID number
- Duplicate employee ID
- Duplicate email

### Example Check

```
select id_num, count(*) as total_records
from emp_prof_prod
group by id_num
having count(*) > 1;
```

### Expected Result

Any duplicate record should appear in the exception log with the correct rule ID, issue category, error type, affected field, severity, and recommended action.

### Why This Proves Accuracy

This proves that duplicate issues are not only detected, but also captured in a review-ready format.

## 3. Cleaning and Standardization Verification

After the cleaning process, standardized fields were checked to confirm that the transformation worked as expected.

The checks include:

- Date fields converted into valid date format
- Gender values standardized
- Blank emails converted to null
- Salary group values standardized
- Production table created from cleaned records

### Example Check

```
select distinct gender
from emp_prof_prod;

select count(*) as missing_email_count
from emp_prof_prod
where email is null;
```

### Expected Result

Cleaned fields should only contain expected values or documented null values.

### Why This Proves Accuracy

This confirms that inconsistent raw values were standardized before validation rules were applied.

## 4. Rule-Level Validation Testing

Each validation rule was tested individually before being inserted into the exception log.

This helps confirm that every rule detects the correct failure condition.

Examples of rule-level checks include:

- ID number length must be 16 digits
- Employee ID length must be 18 digits
- Date of birth embedded in ID must match the `dob` column
- Date of birth embedded in employee ID must match the `dob` column
- Start date embedded in employee ID must match the `start_date` column
- Start age must follow the expected policy range
- Salary group must match the THP range

### Example Check

```
select prod_id, id_num
from emp_prof_prod
where length(id_num) <> 16;
```

### Expected Result

The records returned by the individual validation query should match the records inserted into the exception log for the same rule.

### Why This Proves Accuracy

This proves that the exception log is generated from tested validation logic, not from manual judgment or random filtering.

## 5. Cross-Field Consistency Verification

Cross-field checks were used to confirm whether related fields tell the same story.

Examples:

- `id_num` contains an embedded date of birth
- `employee_id` contains an embedded date of birth
- `employee_id` contains an embedded start date
- These embedded values are compared against the cleaned `dob` and `start_date` columns

### Example Check

```
select
    prod_id,
    id_num,
    dob,
    substring(id_num, 5, 8) as dob_from_id,
    date_format(dob, '%Y%m%d') as dob_from_column
from emp_prof_prod
where substring(id_num, 5, 8) <> date_format(dob, '%Y%m%d');
```

### Expected Result

Any mismatch should be recorded as a cross-field mismatch in the exception log.

### Why This Proves Accuracy

This proves that the validation process does not only check single fields, but also verifies whether related fields are logically consistent.

## 6. Salary Rule Verification

Salary validation was checked by comparing `thp` against the expected salary group range.

The expected salary group is based on the documented THP boundary rules.

### Example Logic

```
8,000,000 <= THP <= 9,000,000      → group 1
9,000,000 < THP <= 10,000,000      → group 2
10,000,000 < THP <= 11,000,000     → group 3
11,000,000 < THP <= 12,000,000     → group 4
THP < 8,000,000                    → under
THP > 12,000,000                   → over
```

### Example Check

```
select
    prod_id,
    thp,
    group_sal,
    case
        when thp < 8000000 then 'under'
        when thp >= 8000000 and thp <= 9000000 then '1'
        when thp > 9000000 and thp <= 10000000 then '2'
        when thp > 10000000 and thp <= 11000000 then '3'
        when thp > 11000000 and thp <= 12000000 then '4'
        when thp > 12000000 then 'over'
    end as expected_group_sal
from emp_prof_prod
where group_sal <> case
        when thp < 8000000 then 'under'
        when thp >= 8000000 and thp <= 9000000 then '1'
        when thp > 9000000 and thp <= 10000000 then '2'
        when thp > 10000000 and thp <= 11000000 then '3'
        when thp > 11000000 and thp <= 12000000 then '4'
        when thp > 12000000 then 'over'
    end;
```

### Expected Result

Any mismatch between `group_sal` and the expected THP range should be logged as a salary validation issue.

### Why This Proves Accuracy

This confirms that salary classification errors are detected using documented threshold logic, not subjective interpretation.

## 7. Exception Log Traceability

Every failed validation rule is stored in the exception log.

The exception log includes:

- `prod_id`
- `rule_id`
- `issue_category`
- `error_type`
- `affected_field`
- `severity`
- `recommended_action`
- `logged_at`

### Expected Result

Each row in the exception log should be traceable to:

1. A production record
2. A documented validation rule
3. A specific affected field
4. A recommended follow-up action

### Example Check

```
select *
from emp_prof_dqlog
where rule_id is null
   or prod_id is null
   or issue_category is null
   or error_type is null;
```

### Why This Proves Accuracy

This confirms that the exception log is audit-ready and that every issue has enough context for review.

## 8. Summary Output Reconciliation

The final quality summary was checked against the exception log.

The purpose is to confirm that summary numbers match the detailed row-level issue log.

### Example Check

```
select
    issue_category,
    error_type,
    severity,
    count(*) as total_issues
from emp_prof_dqlog
group by issue_category, error_type, severity
order by total_issues desc;
```

### Expected Result

The issue counts in `issue_count_by_error_type.csv` should match the grouped counts from the exception log.

### Why This Proves Accuracy

This proves that the final summary output is not manually created. It is directly supported by the row-level exception log.

## 9. Passed vs Review-Required Records

Records were classified into two groups:

- Passed validation
- Requires review

A record requires review if it appears in the exception log at least once.

### Example Check

```
select
    count(distinct p.prod_id) as total_production_records,
    count(distinct d.prod_id) as records_requiring_review,
    count(distinct p.prod_id) - count(distinct d.prod_id) as passed_records
from emp_prof_prod p
left join emp_prof_dqlog d
    on p.prod_id = d.prod_id;
```

### Expected Result

The number of passed records plus records requiring review should equal the total production record count.

```
passed records + review-required records = total production records
```

### Why This Proves Accuracy

This confirms that the final validation status covers the full production dataset.

## 10. Severity Prioritization Check

Severity levels were used to prioritize which records should be reviewed first.

Severity definitions:

- HIGH: affects identity accuracy, record uniqueness, or business-rule validity
- MEDIUM: affects reporting accuracy or classification reliability
- LOW: affects completeness or lower-risk formatting

### Example Check

```
select
    severity,
    count(*) as total_issues
from emp_prof_dqlog
group by severity
order by
    case severity
        when 'HIGH' then 1
        when 'MEDIUM' then 2
        when 'LOW' then 3
    end;
```

### Expected Result

High-severity records should be prioritized first in review outputs.

### Why This Proves Accuracy

This confirms that the validation process does not treat all issues equally. It supports practical review prioritization.



## Output Files Used as Evidence

The accuracy of the process is supported by three main output files:

## 1. validation_summary.csv

This file provides a high-level summary of the validation result.

It should include:

- Total production records
- Total issue flags
- Records requiring review
- Passed records
- Validation pass rate

## 2. exception_log_sample.csv

This file provides row-level validation failures.

It shows:

- Which record failed
- Which validation rule failed
- Which field was affected
- Severity level
- Recommended action

## 3. issue_count_by_error_type.csv

This file summarizes recurring issue patterns.

It shows:

- Issue category
- Error type
- Severity
- Total issue count

## Limitations

This project uses synthetic data for portfolio purposes. The validation rules are designed to demonstrate a realistic data quality audit process, but the dataset does not represent real employees, real citizens, a real company, or a real government institution.

The validation process proves the structure and logic of the data quality workflow. In a real production environment, final rule approval should involve business stakeholders, data owners, and compliance reviewers.

## Conclusion

The SQL validation workflow is considered accurate because:

1. Record counts are reconciled across pipeline stages.
2. Duplicate detection is verified using SQL logic.
3. Cleaned fields are checked before validation.
4. Each validation rule is tested individually.
5. Cross-field mismatches are detected using documented logic.
6. Salary validation follows clear THP boundary rules.
7. Every failed record is stored in a traceable exception log.
8. Final summary outputs are reconciled against the exception log.
9. Passed and review-required records are calculated from the production table.
10. Severity levels support review prioritization.

Together, these checks show that the project is not only a SQL cleaning exercise, but a structured, auditable data quality validation workflow.
