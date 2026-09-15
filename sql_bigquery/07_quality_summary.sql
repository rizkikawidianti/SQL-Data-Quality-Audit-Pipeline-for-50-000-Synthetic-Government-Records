-- =====================================================
-- 01. VALIDATION SUMMARY
-- =====================================================

with raw_counts as (
    select count(*) as total_raw_rows
    from dq_audit_portfolio.employee_profile_raw
),
duplicate_counts as (
    select count(*) as duplicate_rows_removed
    from (select row_number() over (partition by
                    id_num,
                    employee_id,
                    name,
                    branch_id,
                    dob,
                    phone_number,
                    start_date,
                    gender,
                    group_sal,
                    thp,
                    email,
                    last_update
            ) as dup_row
        from dq_audit_portfolio.employee_profile_raw)
    where dup_row > 1
),
production_counts as (
    select count(*) as total_production_records
    from dq_audit_portfolio.emp_prof_prod
),
issue_counts as (
    select
        count(*) as total_issue_flags,
        count(distinct prod_id) as records_with_issues
    from dq_audit_portfolio.emp_prof_dqlog
)
select
    raw.total_raw_rows,
    duplicate.duplicate_rows_removed,
    production.total_production_records,
    coalesce(issues.records_with_issues, 0) as records_with_issues,
    production.total_production_records - coalesce(issues.records_with_issues, 0) as records_passed_validation,
    coalesce(issues.total_issue_flags, 0) as total_issue_flags,
    round(
        safe_divide(
            production.total_production_records - coalesce(issues.records_with_issues, 0),
            production.total_production_records) * 100, 2
    ) as validation_pass_rate
from raw_counts as raw
cross join duplicate_counts as duplicate
cross join production_counts as production
cross join issue_counts as issues;


-- =====================================================
-- 02. ISSUE SUMMARY
-- =====================================================

select
    rule_id, error_type, issue_category, severity,
    count(*) as total_records
from dq_audit_portfolio.emp_prof_dqlog
group by
    rule_id, error_type, issue_category, severity
order by total_records desc;


-- =====================================================
-- 03. SEVERITY SUMMARY
-- =====================================================

select
    severity,
    count(*) as total_issue_flags,
    count(distinct prod_id) as affected_records
from dq_audit_portfolio.emp_prof_dqlog
group by 1
order by
    case severity
        when 'HIGH' then 1
        when 'MEDIUM' then 2
        when 'LOW' then 3
        else 4
    end;


-- =====================================================
-- 04. RECORDS REQUIRING REVIEW
-- =====================================================

select
    prod_id,
    count(*) AS issue_count,
    countif(severity = 'HIGH') as high_severity_issues,
    countif(severity = 'MEDIUM') as medium_severity_issues,
    countif(severity = 'LOW') as low_severity_issues
from dq_audit_portfolio.emp_prof_dqlog
group by 1
order by
    high_severity_issues desc,
    medium_severity_issues desc,
    issue_count desc;

