select
    *
from
    employee_profile;

with duplicates as (
    select 
        *,
        row_number() over(
            partition by id_num, employee_id, name, branch_id, dob, phone_number, age,
                         start_date, gender, group_sal, thp, email, last_update
        ) as dup_row
    from employee_profile
)
select
    *
from
    duplicates
where
    dup_row > 1;

select
    count(*) as total_rows,
    count(distinct id_num) as unique_id,
    count(distinct employee_id) as unique_emp_id
from
    employee_profile ep;

select 
    sum(case when nullif(trim(name), '') is null then 1 else 0 end) as missing_name,
    sum(case when nullif(trim(branch_id), '') is null then 1 else 0 end) as missing_branch,
    sum(case when dob is null then 1 else 0 end) as missing_dob,
    sum(case when nullif(trim(phone_number), '') is null then 1 else 0 end) as missing_phone,
    sum(case when nullif(trim(start_date), '') is null then 1 else 0 end) as missing_sdate,
    sum(case when nullif(trim(gender), '') is null then 1 else 0 end) as missing_gender,
    sum(case when nullif(trim(group_sal), '') is null then 1 else 0 end) as missing_group,
    sum(case when thp is null then 1 else 0 end) as missing_thp,
    sum(case when nullif(trim(email), '') is null then 1 else 0 end) as missing_email
from
    employee_profile ep;

select 
    min(dob) as min_dob,
    max(dob) as max_dob,
    min(start_date) as min_sdate,
    max(start_date) as max_sdate,
    min(thp) as min_thp,
    max(thp) as max_thp
from
    employee_profile;

select
    distinct branch_id
from
    employee_profile;

select
    distinct gender
from
    employee_profile;

select
    distinct group_sal
from
    employee_profile;