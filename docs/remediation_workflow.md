# Remediation Workflow

## Purpose

This document explains how validation findings are handled after the SQL audit process.

The SQL pipeline identifies records that fail validation rules. However, in a real business or institutional environment, failed records are not always corrected automatically. Many issues require confirmation from the responsible data owner, such as HR, branch teams, operations teams, or other departments that manage the original source data.

For that reason, the exception log can be converted into a remediation request file. This file contains the affected production record, failed validation rule, affected field, current value, and blank columns for the responsible team to provide the corrected or confirmed value.

After the corrected file is returned, the database can be updated and the validation checks can be run again.

## Remediation Process

1. Run SQL validation checks.
2. Generate the exception log.
3. Group failed records by issue type, affected field, severity, and responsible owner.
4. Export relevant records into the remediation template.
5. Send the remediation file to the responsible department.
6. Receive corrected or confirmed values.
7. Update the database based on confirmed corrections.
8. Re-run validation checks.
9. Compare the initial validation result with the post-remediation result.
10. Use the final validated dataset for reporting.

## Remediation Template

The remediation template is an Excel file used to coordinate corrections with the responsible department.

Example columns:

| Column | Purpose |
|---|---|
| prod_id | Unique production record ID |
| rule_id | Validation rule that failed |
| issue_category | Broad issue group |
| error_type | Specific validation failure |
| affected_field | Field that requires review |
| current_value | Existing value in the database |
| corrected_value | Value provided by the responsible team |
| responsible_owner | Department or team responsible for confirmation |
| review_status | Pending, Confirmed, Corrected, or Rejected |
| notes | Additional explanation from reviewer |

## Why This Matters

The exception log is not only a technical output. It is also a coordination tool.

In a real monthly workflow, the initial exception result was followed by department confirmation, database updates, and revalidation. This remediation cycle helped maintain the final reporting dataset at around 99%+ validated accuracy before reporting.

This workflow helps reviewers understand:

- Which records need attention
- Which field caused the issue
- Why the record failed validation
- How serious the issue is
- Who should review or confirm the data
- What action should be taken next

## Initial vs Final Validation Result

The initial validation run may show many records requiring review. This does not mean the final reporting dataset remains inaccurate.

In a real monthly process, flagged records are reviewed and corrected before the reporting deadline. After corrections are applied, the validation checks are run again to confirm that the final dataset meets the expected quality threshold.

| Stage | Description |
|---|---|
| Initial validation | SQL flags records with missing, duplicate, invalid, or inconsistent values |
| Department review | Flagged records are sent to the responsible data owner |
| Data correction | Corrected or confirmed values are received |
| Database update | Confirmed corrections are applied to the database |
| Revalidation | SQL checks are run again after correction |
| Final reporting dataset | Only validated data is used for monthly reporting |

## Real-World Context

This portfolio project uses synthetic data. However, the workflow reflects a real data quality process used in a high-accountability institutional environment.

In that environment, repeated validation, follow-up, correction, and revalidation helped maintain validation performance above 99.87% before reporting.

For confidentiality reasons, this repository does not include real company, government, employee, or citizen data.
