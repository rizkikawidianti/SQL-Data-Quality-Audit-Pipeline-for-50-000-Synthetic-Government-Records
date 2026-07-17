-- Purpose: Summarize validation results and data quality output

-- Issue summary by category and severity

select
    issue_category,
    severity,
    count(*) as total_issues
from emp_prof_dqlog
group by
    issue_category,
    severity
order by
    total_issues desc;


-- Issue summary by detailed error type

select
    issue_category,
    error_type,
    severity,
    count(*) as total_records
from emp_prof_dqlog
group by
    issue_category,
    error_type,
    severity
order by
    total_records desc;


-- Records that should be reviewed first

select
    prod_id,
    count(*) as total_issues,
    sum(case when severity = 'HIGH' then 1 else 0 end) as high_severity_issues,
    sum(case when severity = 'MEDIUM' then 1 else 0 end) as medium_severity_issues,
    sum(case when severity = 'LOW' then 1 else 0 end) as low_severity_issues
from emp_prof_dqlog
group by
    prod_id
order by
    high_severity_issues desc,
    total_issues desc;