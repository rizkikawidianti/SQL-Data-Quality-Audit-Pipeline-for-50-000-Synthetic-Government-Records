# Remediation Workflow

This document explains how validation findings would be handled after the SQL audit process.

## Purpose

The SQL pipeline identifies records that fail validation rules. In a real business environment, these records are not automatically corrected without confirmation. Many issues require coordination with data owners, branch teams, HR teams, operations teams, or other departments responsible for the original data. In a real workflow, not every issue can be fixed directly from SQL. Some missing or inconsistent values require confirmation from the responsible department.

For that reason, the exception log can be converted into a missing data request file. This file contains the affected production record, the failed validation rule, the affected field, the current value, and blank columns for the responsible team to fill in the corrected data.

After the corrected file is returned, the database can be updated and the validation checks can be run again.

## Process

1. Run SQL validation checks.
2. Generate the exception log.
3. Group failed records by issue type, affected field, severity, and responsible owner.
4. Send records requiring review to the relevant department.
5. Receive corrected or confirmed values.
6. Update the database based on the confirmed data.
7. Re-run validation checks.
8. Compare the initial validation result with the final post-remediation result.
9. Use the final validated dataset for reporting.

## Why This Matters

The exception log is not only a technical output. It is also a coordination tool.

It helps reviewers understand:

- Which records need attention
- Which field caused the issue
- Why the record failed validation
- How serious the issue is
- What action should be taken next

## Initial vs Final Validation Result

The initial validation run may show many records requiring review. This does not mean the final reporting data remains inaccurate.

In a real monthly process, flagged records are reviewed and corrected before the reporting deadline. After corrections are applied, the validation checks are rerun to confirm that the final dataset meets the expected quality threshold.

## Practical Example

| Stage | Description |
|---|---|
| Initial validation | SQL flags records with missing, duplicate, invalid, or inconsistent values |
| Department review | Flagged records are sent to the responsible data owner |
| Data correction | Corrected values are received and applied to the database |
| Revalidation | SQL checks are rerun after correction |
| Final reporting dataset | Only validated data is used for monthly reporting |

## Real-World Context

This portfolio project uses synthetic data, but the workflow reflects a real data quality process used in a high-accountability institutional environment. In that environment, repeated validation, follow-up, correction, and revalidation helped maintain final validated data accuracy at around 99% or higher before reporting. 
