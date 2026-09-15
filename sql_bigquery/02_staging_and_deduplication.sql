-- =====================================================
-- 02_STAGING_AND_DEDUPLICATION.SQL
-- Purpose:
-- Analyze duplicate records in the raw dataset and
-- define the deduplication logic that will be applied
-- during the staging transformation.
-- =====================================================

-- =====================================================
-- 01. IDENTIFY EXACT DUPLICATE RECORDS
-- =====================================================
with dup_check as (
    select *, row_number() over(partition by id_num, employee_id, name, branch_id, dob, phone_number, start_date, gender, group_sal, thp, email, last_update) AS dup_row
    from dq_audit_portfolio.employee_profile_raw
)
select *
from dup_check
where dup_row > 1;

-- =====================================================
-- 02. COUNT EXACT DUPLICATE ROWS
-- =====================================================
with dup_check as (
    select row_number() over(partition by id_num, employee_id, name, branch_id, dob, phone_number, start_date, gender, group_sal, thp, email, last_update) AS dup_row
    from dq_audit_portfolio.employee_profile_raw
)
select count(*) as exact_duplicate_rows
from dup_check
where dup_row > 1;

-- =====================================================
-- 03. EXPECTED ROW COUNT AFTER DEDUPLICATION
-- =====================================================
with dup_check as (
    select row_number() over(partition by id_num, employee_id, name, branch_id, dob, phone_number, start_date, gender, group_sal, thp, email, last_update) AS dup_row
    from dq_audit_portfolio.employee_profile_raw
)
select
    count(*) as total_raw_rows,
    countif(dup_row > 1) AS exact_duplicate_rows,
    countif(dup_row = 1) AS expected_staging_rows
from dup_check;

-- =====================================================
-- 04. DUPLICATE ID NUMBER ANALYSIS
-- AFTER EXACT-ROW DEDUPLICATION
-- =====================================================
with deduplicated as (
    select * from dq_audit_portfolio.employee_profile_raw
    qualify row_number() over(partition by id_num, employee_id, name, branch_id, dob, phone_number, start_date, gender, group_sal, thp, email, last_update)=1
)
select
    id_num,
    count(*) as total
from deduplicated
where
    nullif(trim(id_num), '') is not null
group by 1
having total > 1
order by total desc;

-- =====================================================
-- 05. DUPLICATE EMPLOYEE ID ANALYSIS
-- AFTER EXACT-ROW DEDUPLICATION
-- =====================================================
with deduplicated as (
    select * from dq_audit_portfolio.employee_profile_raw
    qualify row_number() over(partition by id_num, employee_id, name, branch_id, dob, phone_number, start_date, gender, group_sal, thp, email, last_update)=1
)
select
    employee_id,
    count(*) as total
from deduplicated
where nullif(trim(employee_id), '') is not null
group by 1
having total > 1
order by total desc;

-- =====================================================
-- 06. DUPLICATE IDENTIFIER SUMMARY
-- AFTER EXACT-ROW DEDUPLICATION
-- =====================================================
with deduplicated as (
    select * from dq_audit_portfolio.employee_profile_raw
    qualify row_number() over(partition by id_num, employee_id, name, branch_id, dob, phone_number, start_date, gender, group_sal, thp, email, last_update)=1
),
dup_id as(
    select
        id_num, count(*) as total
    from deduplicated
    where nullif(trim(id_num), '') is not null
    group by 1
    having total > 1
),
dup_emp_id as(
    select
        employee_id, count(*) as total
    from deduplicated
    where nullif(trim(employee_id), '') is not null
    group by 1
    having total > 1)
select (select count(*) from dup_id) as duplicate_id_values,
    (select count(*) from dup_emp_id) as duplicate_emp_id_values;
