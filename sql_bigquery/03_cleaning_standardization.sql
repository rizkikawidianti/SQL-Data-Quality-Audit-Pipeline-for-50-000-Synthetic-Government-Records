--======================================================
-- 3. FIELD-BY-FIELD INVESTIGATION
-- Use one SELECT at a time.
--======================================================

with deduplicated as (
    select * 
    from dq_audit_portfolio.employee_profile_raw
    qualify row_number() over(partition by id_num, employee_id, name, branch_id, dob, phone_number, start_date, gender, group_sal, thp, email, last_update)=1
)
--===========================
-- 1. Name quality check
--===========================
-- select
--     name,
--     count(*) as total,
--     case
--         when nullif(trim(name), '') is null then 'MISSING_NAME'
--         when regexp_contains (name, r"[^a-zA-Z '-]") then 'NON_STANDARD_CHARACTER'
--     end as issue_type
-- from deduplicated
-- where 
--     nullif(trim(name), '') is null or
--     regexp_contains (name, r"[^a-zA-Z '-]")
-- group by 1
-- order by 2 desc
--===========================
-- 2. BRANCH_ID CHECK
--===========================
-- select
--     branch_id as ori_branch_id,
--     case
--         when nullif(trim(branch_id), '') is null then NULL
--         when regexp_contains (branch_id, r'[a-zA-Z]') then trim(right(branch_id, 2))
--         when regexp_contains (branch_id, r'^[0-9]$') then concat('0', trim(branch_id))
--         else trim(branch_id)
--     end as standardized_branch_id,
--     count(*) as total
-- from
--     deduplicated
-- group by 1
-- order by total desc;
--===========================
-- 3. DOB CHECK
--===========================
-- select
-- 	dob as ori_dob,
--   coalesce(
--         safe.parse_date('%Y-%m-%d', trim(dob)),
--         safe.parse_date('%Y/%m/%d', trim(dob)),
--         safe.parse_date('%d/%m/%Y', trim(dob)),
--         safe.parse_date('%d-%m-%Y', trim(dob)),
--         safe.parse_date('%m-%d-%Y', trim(dob))
--   ) as standardize_dob,
-- 	case
--         when nullif(trim(dob),'') is null then 'MISSING_DOB'
--         when coalesce(
--             safe.parse_date('%Y-%m-%d', trim(dob)),
--             safe.parse_date('%Y/%m/%d', trim(dob)),
--             safe.parse_date('%d/%m/%Y', trim(dob)),
--             safe.parse_date('%d-%m-%Y', trim(dob)),
--             safe.parse_date('%m-%d-%Y', trim(dob))
--         ) is null then 'UNPARSEABLE_DOB'
--         else 'VALID'
--       end as status,
--     count(*) as total
-- from deduplicated
-- group by 1
-- order by status, total desc;
--===========================
-- 4. PHONE_NUMBER CHECK
--===========================
-- select
-- 	phone_number as ori_phone,
--   case
--     when nullif(regexp_replace(trim(phone_number), r'[-\s]', ''),'') is NULL then NULL
--     when regexp_contains(regexp_replace(trim(phone_number), r'[-\s]', ''),r'^[1-9]')  then concat('0', regexp_replace(trim(phone_number), r'[-\s]', ''))
--     else regexp_replace(trim(phone_number), r'[-\s]', '')
--   end as standardize_phone,
--   count(*) as total
-- from deduplicated
-- group by 1
-- order by total desc;
-- -- ============== check phone value
-- ,phone_cleaning as(
-- select
-- 	phone_number as ori_phone,
--   case
--     when nullif(regexp_replace(trim(phone_number), r'[-\s]', ''),'') is null then null
--     when regexp_contains(regexp_replace(trim(phone_number), r'[-\s]', ''),r'^[1-9]') 
--       then concat('0', regexp_replace(trim(phone_number), r'[-\s]', ''))
--     else regexp_replace(trim(phone_number), r'[-\s]', '')
--   end as standardize_phone
-- from
-- 	deduplicated)
-- select 
--   ori_phone, standardize_phone, length(standardize_phone) as length, case
--     when standardize_phone is null then 'MISSING_PHONE_NUMBER'
--     when length(standardize_phone) < 10 then 'PHONE_NUMBER TOO SHORT'
--     when length(standardize_phone) > 12 then 'PHONE_NUMBER TOO LONG'
--     else 'valid'
--   end as status_phone   
-- from phone_cleaning
-- where standardize_phone is null 
--   or length(standardize_phone) < 10 
--   or length(standardize_phone) > 12;
--===========================
-- 5. START_DATE CHECK
--===========================
-- select start_date as ori_date,
--   coalesce(
--     safe.parse_date('%Y-%m-%d', trim(start_date)),
--     safe.parse_date('%Y/%m/%d', trim(start_date)),
--     safe.parse_date('%d/%m/%Y', trim(start_date)),
--     safe.parse_date('%d-%m-%Y', trim(start_date)),
--     safe.parse_date('%m-%d-%Y', trim(start_date)),
--     safe.parse_date('%b %e, %Y', trim(start_date))
--   ) as standardize_sdate,
--   case
--     when nullif(trim(start_date),'') is null then 'MISSING_START_DATE'
--     when coalesce(
--       safe.parse_date('%Y-%m-%d', trim(start_date)),
--       safe.parse_date('%Y/%m/%d', trim(start_date)),
--       safe.parse_date('%d/%m/%Y', trim(start_date)),
--       safe.parse_date('%d-%m-%Y', trim(start_date)),
--       safe.parse_date('%m-%d-%Y', trim(start_date)),
--       safe.parse_date('%b %e, %Y', trim(start_date))
--       ) is NULL then 'UNPARSEABLE_START_DATE'
--     else 'VALID'
--   end as status_sdate,
--   count(*) as total
-- from deduplicated
-- group by 1
-- order by total desc;
--===========================
-- 6. GENDER CHECK
--===========================
-- select gender as ori_gender, case
--   when nullif(trim(gender),'') is null then null
--   when lower(trim(gender)) in ('female', 'f', 'woman') then 'F'
--   when lower(trim(gender)) in ('male', 'm', 'man') then 'M'
--   else trim(gender)
--   end as standardized_gender,
--   count (*) as total
-- from deduplicated
-- group by 1
-- order by 2 desc
--===========================
-- 7. SAL_GROUP CHECK
--===========================
-- select group_sal as ori_group,
--   case
--     when nullif(trim(group_sal),'') is null then null
--     when regexp_contains(trim(group_sal), r'^[a-zA-Z]') then right(trim(group_sal),1)
--     when regexp_contains(trim(group_sal), r'^0') then right(trim(group_sal),1)
--     else trim(group_sal)
--   end as standardize_group,
--   count(*) as total
-- from deduplicated
-- group by 1
-- order by total desc
--===========================
-- 8. THP CHECK
--===========================
-- select
--   thp as ori_thp,
--   case
--     when thp is null then 'MISSING_THP'
--     when thp < 8000000 then 'THP_UNDER_RANGE'
--     when thp > 12000000 then 'THP_OVER_RANGE'
--     else 'VALID'
--   end as thp_status,
--   count(*) as total   
-- from deduplicated
-- group by 1
-- order by total desc
--===========================
-- 9. EMAIL CHECK
--===========================
-- select email as ori_email,
--   nullif(trim(email),'') as standardize_email,
--   count(*) as total
-- from deduplicated
-- group by 1
-- order by total desc
-- -- ==================checking duplicate email
-- select trim(email) as email, 
--   count(*) as total
-- from deduplicated
-- where nullif(trim(email),'') is not NULL
-- group by 1
-- having total > 1
-- order by total desc

--======================================================
-- 03_CLEANING_STANDARDIZATION.SQL
--
-- Purpose:
-- Deduplicate, clean, standardize, and convert raw
-- employee data into the staging layer using one
-- set-based BigQuery transformation.
--======================================================

create or replace table dq_audit_portfolio.emp_prof_staging as
  with deduplicated as (
    select * 
    from dq_audit_portfolio.employee_profile_raw
    qualify row_number() 
        over(partition by id_num, employee_id, name, branch_id, dob, phone_number, start_date, gender, group_sal, thp, email, last_update)=1
  )
  select 
    id_num,employee_id,name, 
    --======================================================
    -- BRANCH_ID STANDARDIZATION
    --======================================================
    case
      when nullif(trim(branch_id), '') is null then NULL
      when regexp_contains (branch_id, r'[a-zA-Z]') then trim(right(branch_id, 2))
      when regexp_contains (branch_id, r'^[0-9]$') then concat('0', trim(branch_id))
      else trim(branch_id)
    end as branch_id,
    --======================================================
    -- DOB STANDARDIZATION
    --======================================================
    coalesce(
            safe.parse_date('%Y-%m-%d', trim(dob)),
            safe.parse_date('%Y/%m/%d', trim(dob)),
            safe.parse_date('%d/%m/%Y', trim(dob)),
            safe.parse_date('%d-%m-%Y', trim(dob)),
            safe.parse_date('%m-%d-%Y', trim(dob))
      ) as dob,
      --======================================================
    -- PHONE_NUMBER STANDARDIZATION
    --======================================================
    case
      when nullif(regexp_replace(trim(phone_number), r'[-\s]', ''),'') is NULL then NULL
      when regexp_contains(regexp_replace(trim(phone_number), r'[-\s]', ''),r'^[1-9]') 
        then concat('0', regexp_replace(trim(phone_number), r'[-\s]', ''))
      else regexp_replace(trim(phone_number), r'[-\s]', '')
    end as phone_number,
    --======================================================
    -- START_DATE STANDARDIZATION
    --======================================================
    coalesce(
      safe.parse_date('%Y-%m-%d', trim(start_date)),
      safe.parse_date('%Y/%m/%d', trim(start_date)),
      safe.parse_date('%d/%m/%Y', trim(start_date)),
      safe.parse_date('%d-%m-%Y', trim(start_date)),
      safe.parse_date('%m-%d-%Y', trim(start_date)),
      safe.parse_date('%b %e, %Y', trim(start_date))
    ) as start_date,
    --======================================================
    -- GENDER STANDARDIZATION
    --======================================================
    case
      when nullif(trim(gender),'') is NULL then NULL
      when lower(trim(gender)) in ('female', 'f', 'woman') then 'F'
      when lower(trim(gender)) in ('male', 'm', 'man') then 'M'
    else trim(gender)
    end as gender,
    --======================================================
    -- GROUP_SAL STANDARDIZATION
    --======================================================
    case
      when nullif(trim(group_sal),'') is NULL then NULL
      when regexp_contains(trim(group_sal), r'^[a-zA-Z]')
        then right(trim(group_sal),1)
      when regexp_contains(trim(group_sal), r'^0')
        then right(trim(group_sal),1)
      else trim(group_sal)
    end as group_sal,
    thp,
    --======================================================
    -- EMAIL STANDARDIZATION
    --======================================================
    nullif(trim(email),'') as email,   
    last_update
  from deduplicated;

--======================================================
-- STAGING TABLE CHECK
--======================================================

--========================================
-- 1. ROW COUNT RECONCILIATION
--========================================
with raw_count as(
  select count(*) as total_row_raw
  from dq_audit_portfolio.employee_profile_raw
)
,dup_raw_count as (
  select count(*) as total_row_dup
  from(
    select row_number() over(
      partition by id_num, employee_id, name, branch_id, dob, phone_number, start_date, gender, group_sal, thp, email, last_update) AS dup_row
    from dq_audit_portfolio.employee_profile_raw)
  where dup_row > 1
)
,staging_count as (
  select count(*) as total_row_staging
  from dq_audit_portfolio.emp_prof_staging
)
select
    total_row_raw,
    total_row_dup,
    (total_row_raw-total_row_dup) as expected_staging_rows,
    total_row_staging,
    total_row_staging-(total_row_raw-total_row_dup) as row_differences
from raw_count
cross join dup_raw_count
cross join staging_count;
--========================================
-- 2. DATA TYPE CHECK
--========================================
select
    column_name,
    data_type
from dq_audit_portfolio.INFORMATION_SCHEMA.COLUMNS
where table_name = 'emp_prof_staging'
order by ordinal_position;
--========================================
-- 3. STANDARDIZATION CHECK
--========================================
select
    'gender' as field,
    gender as value,
    count(*) as total
from dq_audit_portfolio.emp_prof_staging
group by gender
union all
select
    'group_sal',
    group_sal,
    count(*)
from dq_audit_portfolio.emp_prof_staging
group by group_sal
order by field, total desc;
--========================================
-- 4. PHONE NUMBER CHECK
--========================================
select 
  phone_number, length(phone_number) as length, 
  case
    when phone_number is null then 'MISSING PHONE NUMBER'
    when length(phone_number) < 10 then 'PHONE NUMBER TOO SHORT'
    when length(phone_number) >12 then 'PHONE NUMBER TOO LONG'
  end as issue
from  dq_audit_portfolio.emp_prof_staging
where phone_number is null or length(phone_number) < 10 or length(phone_number)>12;
--========================================
-- 5. THP CHECK
--========================================
select thp,
  case
    when thp is null then 'MISSING THP'
    when thp < 8000000 then 'THP UNDER RANGE'
    when thp > 12000000 then 'THP OVER RANGE'
  end as issues,
  count(*) as total
from dq_audit_portfolio.emp_prof_staging
where thp is null or thp < 8000000 or thp > 12000000
group by 1
order by total desc;
--========================================
-- 6. POST-STANDARDIZATION DUPLICATE CHECK
--========================================
with post_clean_duplicates as(
    select
        row_number() over(partition by
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
    from dq_audit_portfolio.emp_prof_staging
)
select
    count(*) AS post_standardization_duplicate_rows
from post_clean_duplicates
where dup_row > 1;




