-- Purpose: Summarize validation results and data quality output

create view validation_summary as
with raw_counts as (
    select
        count(*) as total_raw_rows
    from
        employee_profile
),
duplicate_counts as (
    select
        count(*) as duplicate_rows_removed
    from (
        select
            row_number() over (
                partition by 
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
        from
            employee_profile
    ) d
    where
        dup_row > 1
),
clean_counts as (
    select
        count(*) as total_clean_records
    from
        emp_prof_prod
),
issue_counts as (
    select
        count(*) as total_issue_flags,
        count(distinct prod_id) as records_with_issues
    from
        emp_prof_dqlog
),
summary_base as (
    select
        r.total_raw_rows,
        d.duplicate_rows_removed,
        c.total_clean_records,
        coalesce(i.total_issue_flags, 0) as total_issue_flags,
        coalesce(i.records_with_issues, 0) as records_with_issues,
        c.total_clean_records - coalesce(i.records_with_issues, 0) as records_passed_validation,
        round(
            (c.total_clean_records - coalesce(i.records_with_issues, 0)) * 100.0 
            / c.total_clean_records,
            2
        ) as validation_pass_rate
    from
        raw_counts r
        cross join duplicate_counts d
        cross join clean_counts c
        cross join issue_counts i
)
select
    'total_raw_rows' as metric,
    cast(total_raw_rows as char) as value
from
    summary_base
union all
select
    'duplicate_rows_removed',
    cast(duplicate_rows_removed as char)
from
    summary_base
union all
select
    'total_clean_records',
    cast(total_clean_records as char)
from
    summary_base
union all
select
    'records_with_issues',
    cast(records_with_issues as char)
from
    summary_base
union all
select
    'records_passed_validation',
    cast(records_passed_validation as char)
from
    summary_base
union all
select
    'total_issue_flags',
    cast(total_issue_flags as char)
from
    summary_base
union all
select
    'validation_pass_rate',
    concat(validation_pass_rate, '%')
from
    summary_base;




-- Issue summary by detailed error type
create view issue_summary as
select
	rule_id,
    error_type,
    issue_category,    
    severity,
    count(*) as total_records
from emp_prof_dqlog
group by
    rule_id,
    error_type,
    issue_category,    
    severity
order by
    total_records desc;




-- exception_log_sample
with ranked_by_rule as (
    select
        *,
        row_number() over(
            partition by rule_id
            order by prod_id
        ) as rule_row_num
    from
        emp_prof_dqlog
),
balanced_pool as (
    select
        *
    from
        ranked_by_rule
    where
        rule_row_num <= 10
),
final_sample as (
    select
        prod_id,
        rule_id,
        issue_category,
        error_type,
        affected_field,
        severity,
        recommended_action,
        logged_at,
        row_number() over(
            order by rule_row_num, rule_id, prod_id
        ) as sample_row_num
    from
        balanced_pool
)
select
    prod_id,
    rule_id,
    issue_category,
    error_type,
    affected_field,
    severity,
    recommended_action,
    logged_at
from
    final_sample
where
    sample_row_num <= 100
order by
    sample_row_num;
