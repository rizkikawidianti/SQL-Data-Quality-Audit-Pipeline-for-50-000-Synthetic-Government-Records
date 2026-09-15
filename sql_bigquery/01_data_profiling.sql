select
    *
from
    dq_audit_portfolio.employee_profile_raw;

with duplicates as (
    select 
        *,
        row_number() over(
            partition by id_num, employee_id, name, branch_id, dob, phone_number,
                         start_date, gender, group_sal, thp, email, last_update
        ) as dup_row
    from dq_audit_portfolio.employee_profile_raw
)
select *
from duplicates
where dup_row > 1;

select
    count(*) as total_rows,
    count(distinct id_num) as unique_id,
    count(distinct employee_id) as unique_emp_id
from
    dq_audit_portfolio.employee_profile_raw;

select 
    countif(nullif(trim(name), '') is null) as missing_name,
    countif(nullif(trim(branch_id), '') is null) as missing_branch,
    countif(nullif(trim(dob), '') is null) as missing_dob,
    countif(nullif(trim(phone_number), '') is null) as missing_phone,
    countif(nullif(trim(start_date), '') is null) as missing_sdate,
    countif(nullif(trim(gender), '') is null) as missing_gender,
    countif(nullif(trim(group_sal), '') is null) as missing_group,
    countif(thp is null) as missing_thp,
    countif(nullif(trim(email), '') is null) as missing_email
from
    dq_audit_portfolio.employee_profile_raw;

-- min max profiling will be done after cleaning, because all fields are STRING

select
    dob,
    count(*) as dob_records
from dq_audit_portfolio.employee_profile_raw
group by 1
order by 2 desc;

select
    case
        when dob is null or trim(dob) = '' then 'MISSING'
        when regexp_contains(trim(dob), r'^\d{2}-\d{2}-\d{4}$') then 'XX-XX-YYYY'
        when regexp_contains(trim(dob), r'^\d{2}/\d{2}/\d{4}$') then 'XX/XX/YYYY'
        when regexp_contains(trim(dob), r'^\d{4}/\d{2}/\d{2}$') then 'YYYY/MM/DD'
        when regexp_contains(trim(dob), r'^\d{4}-\d{2}-\d{2}$') then 'YYYY-MM-DD'
        else 'OTHER'
    end as dob_format,
    count(*) as records
from dq_audit_portfolio.employee_profile_raw
group by dob_format
order by records desc;

select
    case
        when start_date is null or trim(start_date) = '' then 'MISSING'
        when regexp_contains(trim(start_date), r'^\d{2}-\d{2}-\d{4}$') then 'XX-XX-YYYY'
        when regexp_contains(trim(start_date), r'^\d{2}/\d{2}/\d{4}$') then 'XX/XX/YYYY'
        when regexp_contains(trim(start_date), r'^\d{4}/\d{2}/\d{2}$') then 'YYYY/MM/DD'
        when regexp_contains(trim(start_date), r'^\d{4}-\d{2}-\d{2}$') then 'YYYY-MM-DD'
        when regexp_contains(trim(start_date), r'^[A-Za-z]{3} \d{1,2}, \d{4}$')
            then 'MON DD, YYYY'
        else 'OTHER'
    end as start_date_format,
    count(*) as records
from dq_audit_portfolio.employee_profile_raw
group by start_date_format
order by records desc;

select
    distinct branch_id,
    count(*) as branch_records
from dq_audit_portfolio.employee_profile_raw
group by 1
order by 2 desc;

select
    distinct gender,
    count(*) as gender_records
from dq_audit_portfolio.employee_profile_raw
group by 1
order by 2 desc;

select
    distinct group_sal,
    count(*) as sal_records
from dq_audit_portfolio.employee_profile_raw
group by 1
order by 2 desc;