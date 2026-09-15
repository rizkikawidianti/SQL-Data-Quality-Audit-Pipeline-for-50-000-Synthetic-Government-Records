-- =====================================================
-- 05_VALIDATION_CHECKS.SQL
--
-- Purpose:
-- Apply rule-based data quality checks against the
-- standardized production dataset.
--
-- This file is read-only.
-- Failed records are materialized into the exception
-- log in 06_exception_log.sql.
--
-- Use one validation SELECT at a time.
-- =====================================================

with validation_base as (
    select
        p.*,
        -- duplicate id count
        case
            when nullif(trim(id_num), '') is null then 0
            else count(*) over (partition by id_num)
        end as id_count,
        -- duplicate employee id count
        case
            when nullif(trim(employee_id), '') is null then 0
            else count(*) over (partition by employee_id)
        end as employee_id_count,
        -- duplicate email count
        case
            when nullif(trim(email), '') is null then 0
            else count(*) over (partition by email)
        end as email_count,
        -- completed age when employee started
        case
            when dob is null or start_date is null then null
            else date_diff(start_date, dob, year) -
                case
                    when format_date('%m%d', start_date) < format_date('%m%d', dob) then 1
                  else 0
                end
        end as age_at_start,
        -- start day
        extract(day from start_date) as start_day,
        -- expected salary group based on thp
        case
            when thp between 8000000 and 9000000 then '1'
            when thp > 9000000 and thp <= 10000000 then '2'
            when thp > 10000000 and thp <= 11000000 then '3'
            when thp > 11000000 and thp <= 12000000 then '4'
            when thp < 8000000 then 'UNDER'
            when thp > 12000000 then 'OVER'
        end as expected_group_sal
    from
        dq_audit_portfolio.emp_prof_prod as p
)
--===================================================
-- 01. Duplicate ID number
--===================================================
-- select
--     prod_id, id_num, id_count
-- from validation_base
-- where id_count > 1
-- order by id_num, prod_id;
--===================================================
-- 02. Duplicate Employee ID
--===================================================
-- select 
--     prod_id, employee_id, employee_id_count
-- from validation_base
-- where employee_id_count > 1
-- order by employee_id, prod_id;
--===================================================
-- 03. Invalid ID number length
--===================================================
-- select
--     prod_id, id_num,
--     length(id_num) as id_length
-- from validation_base
-- where
--     id_num is not null
--     and length(id_num) <> 16;
--===================================================
-- 04. Invalid Employee ID length
--===================================================
-- select
--     prod_id, employee_id,
--     length(employee_id) as employee_id_length
-- from validation_base
-- where
--     employee_id is not null
--     and length(employee_id) <> 18;
--===================================================
-- 05. DOB mismatch inside ID number
--===================================================
-- select
--     prod_id, id_num, dob,
--     substr(id_num, 5, 8) as dob_from_id
-- from validation_base
-- where
--     id_num is not null
--     and dob is not null
--     and substr(id_num, 5, 8) <> format_date('%Y%m%d',dob);
--===================================================
-- 06. DOB mismatch inside Employee ID
--===================================================
-- select
--     prod_id, employee_id, dob,
--     substr(employee_id, 1, 8) as dob_from_employee_id
-- from validation_base
-- where
--     employee_id is not null
--     and dob is not null
--     and substr(employee_id, 1, 8) <> format_date('%Y%m%d', dob);
--===================================================
-- 07. Start-date mismatch inside Employee ID
--===================================================
-- select
--     prod_id, employee_id, start_date,
--     substr(employee_id, 9, 6) as start_date_from_employee_id
-- from validation_base
-- where
--     employee_id is not null
--     and start_date is not null
--     and substr(employee_id, 9, 6) <> format_date('%Y%m', start_date);
--===================================================
-- 08. Start-age rule
--===================================================
-- select
--     prod_id, dob, start_date, age_at_start,
--     case
--         when age_at_start < 18 then 'START_AGE_UNDER_18'
--         when age_at_start > 45 then 'START_AGE_OVER_45'
--     end as issue_type
-- from validation_base
-- where
--     age_at_start < 18
--     or age_at_start > 45
-- order by age_at_start;
--===================================================
-- 09. Start-date day rule
--===================================================
-- select
--     prod_id, employee_id, start_date, start_day
-- from validation_base
-- where start_day <> 1;
--===================================================
-- 10. Salary group vs THP mismatch
--===================================================
-- select
--     prod_id, group_sal, thp, expected_group_sal
-- from validation_base
-- where
--     expected_group_sal not in ('UNDER', 'OVER') and
--     group_sal <> expected_group_sal;
--===================================================
-- 11. THP below valid range
--===================================================
-- select
--     prod_id, group_sal, thp, expected_group_sal
-- from validation_base
-- where expected_group_sal = 'UNDER';
--===================================================
-- 12. THP above valid range
--===================================================
-- select
--     prod_id, group_sal, thp, expected_group_sal
-- from validation_base
-- where expected_group_sal = 'OVER';
--===================================================
-- 13. Duplicate email
--===================================================
-- select
--     prod_id, email, email_count
-- from validation_base
-- where email_count > 1
-- order by email, prod_id;
--===================================================
-- 14. Missing email
--===================================================
-- select
--     prod_id, email
-- from validation_base
-- where email is null;
--===================================================
-- 15. Missing branch
--===================================================
-- select
--     prod_id, branch_id
-- from validation_base
-- where branch_id is null;
--===================================================
-- 16. Missing phone number
--===================================================
-- select
--     prod_id, phone_number
-- from validation_base
-- where phone_number is null;
--===================================================
-- 17. Invalid phone length
--===================================================
-- select
--     prod_id, phone_number,
--     length(phone_number) as phone_length,
--     case
--         when length(phone_number) < 10 then 'PHONE_NUMBER_TOO_SHORT'
--         when length(phone_number) > 12 then 'PHONE_NUMBER_TOO_LONG'
--     end as issue_type
-- from validation_base
-- where
--     phone_number is not null
--     and(length(phone_number) < 10 or length(phone_number) > 12);















