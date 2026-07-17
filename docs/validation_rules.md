# Validation Rules for Employee Master Data Quality Audit
This document explains the validation rules used in the Employee Master Data Quality Validation project.

The validation process checks whether cleaned employee records meet expected data structure, business logic, and data quality standards. Failed records are stored in the exception log with issue category, affected field, error type, severity, recommended action, and timestamp.

Validation rules are grouped into five categories:

1. Duplicate record checks
2. Format checks
3. Cross-field consistency checks
4. Business rule checks
5. Salary and completeness checks

## Validation Rule Summary

| Rule ID | Issue Category | Error Type | Affected Field | Validation Logic | Severity | Recommended Action |
| --- | --- | --- | --- | --- | --- | --- |
| VR001 | DUPLICATE_RECORD | Duplicate_ID | id_num | Same `id_num` appears more than once in the production table | HIGH | Review duplicated ID number against the source system |
| VR002 | DUPLICATE_RECORD | Duplicate_Employee_ID | employee_id | Same `employee_id` appears more than once in the production table | HIGH | Review duplicated employee ID against HR or master employee records |
| VR003 | FORMAT_ERROR | Invalid_ID_Length | id_num | `id_num` length is not 16 digits | HIGH | Review ID number length. Expected 16 digits |
| VR004 | FORMAT_ERROR | Invalid_Employee_ID_Length | employee_id | `employee_id` length is not 18 digits | HIGH | Review employee ID length. Expected 18 digits |
| VR005 | CROSS_FIELD_MISMATCH | DOB_Mismatch_in_ID | id_num, dob | Digits 5 to 12 of `id_num` must match `dob` in `YYYYMMDD` format | HIGH | Compare DOB column with the DOB embedded inside the ID number |
| VR006 | CROSS_FIELD_MISMATCH | DOB_Mismatch_in_Employee_ID | employee_id, dob | Digits 1 to 8 of `employee_id` must match `dob` in `YYYYMMDD` format | HIGH | Compare DOB column with the DOB embedded inside the employee ID |
| VR007 | CROSS_FIELD_MISMATCH | Start_Date_Mismatch_in_Employee_ID | employee_id, start_date | Digits 9 to 14 of `employee_id` must match `start_date` in `YYYYMM` format | MEDIUM | Compare start_date column with the start date embedded inside the employee ID |
| VR008 | BUSINESS_RULE_EXCEPTION | Start_Age_Under_18 or Start_Age_Over_45 | dob, start_date | Employee start age is below 18 years old or above 45 years old | HIGH | Review whether the employee start age is valid based on policy |
| VR009 | BUSINESS_RULE_EXCEPTION | Start_Date_Not_First_Day | start_date, employee_id | `start_date` does not fall on the first day of the month | LOW | Confirm whether start_date should always begin on the first day of the month |
| VR010 | SALARY_VALIDATION | Mismatched_Group_Salary_and_THP | thp, group_sal | `group_sal` does not match the expected THP salary range | MEDIUM | Review whether group_sal matches the expected THP salary range |
| VR011 | SALARY_VALIDATION | THP_Under | thp | `thp` is below the expected minimum salary range | MEDIUM | Review whether THP value is below the expected salary range |
| VR012 | SALARY_VALIDATION | THP_Over | thp | `thp` is above the expected maximum salary range | MEDIUM | Review whether THP value is above the expected salary range |
| VR013 | DUPLICATE_RECORD | Duplicate_Email | email | Same `email` appears more than once in the production table | MEDIUM | Review whether the email is shared, duplicated, or assigned to the wrong employee |
| VR014 | MISSING_DATA | Missing_Email | email | `email` is NULL after cleaning | LOW | Request or complete the missing employee email value |
| VR015 | MISSING_DATA | Missing_Branch_ID | branch_id | `branch_id` is NULL after cleaning | MEDIUM | Review source record and assign the correct branch ID |
| VR016 | MISSING_DATA | Missing_Phone_Number | phone_number | `phone_number` is NULL after cleaning | LOW | Request or complete the missing phone number |

## Salary Group Rule

The expected salary group is based on the THP value.

| THP Range | Expected group_sal |
| --- | --- |
| 8,000,000 <= THP <= 9,000,000 | 1 |
| 9,000,000 < THP <= 10,000,000 | 2 |
| 10,000,000 < THP <= 11,000,000 | 3 |
| 11,000,000 < THP <= 12,000,000 | 4 |
| THP < 8,000,000 | under |
| THP > 12,000,000 | over |

## Severity Definition

| Severity | Meaning |
| --- | --- |
| HIGH | The issue may affect identity accuracy, record uniqueness, or business-rule validity. These records should be reviewed first. |
| MEDIUM | The issue may affect reporting accuracy or classification reliability. These records need review before final use. |
| LOW | The issue is usually related to completeness or lower-risk formatting. These records may still be usable, but should be completed or confirmed. |

## Exception Log Output

Each failed validation rule is stored in the exception log with this structure:

| Column | Description |
| --- | --- |
| prod_id | Unique production record ID used for traceability |
| rule_id | Unique validation rule identifier used to trace each failed record back to the documented validation rule |
| issue_category | Broad issue group |
| error_type | Specific validation rule that failed |
| affected_field | Field or fields involved in the issue |
| severity | Priority level for review |
| recommended_action | Suggested follow-up action |
| logged_at | Timestamp when the issue was logged |
