-- =====================================================
-- 06_EXCEPTION_LOG.SQL
--
-- Purpose:
-- Apply all approved validation rules and materialize
-- row-level data quality failures into an audit-ready
-- exception log.
-- =====================================================


create or replace table
    dq_audit_portfolio.emp_prof_dqlog
as
with validation_base as (
    select
        p.*,
        -- duplicate id count
        case
            when nullif(trim(id_num), '') is null then 0
            else count(*) over(partition by id_num)
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
            else
                date_diff(start_date, dob, year) -
                case
                    when format_date('%m%d', start_date) < format_date('%m%d', dob) then 1
                    else 0
                end
        end as age_at_start,
        -- start day
        extract(
            day from start_date
        ) as start_day,
        -- expected salary group based on thp
        case
            when thp between 8000000 and 9000000 then '1'
            when thp > 9000000 and thp <= 10000000 then '2'
            when thp > 10000000 and thp <= 11000000 then '3'
            when thp > 11000000 and thp <= 12000000 then '4'
            when thp < 8000000 then 'under'
            when thp > 12000000 then 'over'
        end as expected_group_sal
    from
        dq_audit_portfolio.emp_prof_prod as p
)
-- =====================================================
-- VR001 - DUPLICATE ID
-- =====================================================
select
    prod_id,
    'VR001' as rule_id,
    'DUPLICATE_RECORD' as issue_category,
    'Duplicate_ID' as error_type,
    'id_num' as affected_field,
    'HIGH' as severity,
    'Review duplicated ID number against the source system' as recommended_action,
    current_timestamp() as logged_at
from validation_base
where id_count > 1
union all
-- =====================================================
-- VR002 - DUPLICATE EMPLOYEE ID
-- =====================================================
select
    prod_id,
    'VR002',
    'DUPLICATE_RECORD',
    'Duplicate_Employee_ID',
    'employee_id',
    'HIGH', 
    'Review duplicated employee ID against HR or master employee records',
    current_timestamp()
from validation_base
where employee_id_count > 1
union all
-- =====================================================
-- VR003 - INVALID ID LENGTH
-- =====================================================
select
    prod_id,
    'VR003',
    'FORMAT_ERROR',
    'Invalid_ID_Length',
    'id_num',
    'HIGH',
    'Review ID number length. Expected 16 characters',
    current_timestamp()
from validation_base
where
    id_num is not null
    and length(id_num) <> 16
union all
-- =====================================================
-- VR004 - INVALID EMPLOYEE ID LENGTH
-- =====================================================
select
    prod_id,
    'VR004',
    'FORMAT_ERROR',
    'Invalid_Employee_ID_Length',
    'employee_id',
    'HIGH',
    'Review employee ID length. Expected 18 characters',
    current_timestamp()
from validation_base
where
    employee_id is not null
    and length(employee_id) <> 18
union all
-- =====================================================
-- VR005 - DOB MISMATCH IN ID
-- =====================================================
select
    prod_id,
    'VR005',
    'CROSS_FIELD_MISMATCH',
    'DOB_Mismatch_in_ID',
    'id_num, dob',
    'HIGH',
    'Compare DOB with the DOB embedded inside the ID number',
    current_timestamp()
from validation_base
where
    id_num is not null
    and dob is not null
    and substr(id_num, 5, 8) <> format_date('%Y%m%d', dob)
union all
-- =====================================================
-- VR006 - DOB MISMATCH IN EMPLOYEE ID
-- =====================================================
select
    prod_id,
    'VR006',
    'CROSS_FIELD_MISMATCH',
    'DOB_Mismatch_in_Employee_ID',
    'employee_id, dob',
    'HIGH',
    'Compare DOB with the DOB embedded inside the employee ID',
    current_timestamp()
from validation_base
where
    employee_id is not null
    and dob is not null
    and substr(employee_id, 1, 8) <> format_date('%Y%m%d', dob)
union all
-- =====================================================
-- VR007 - START DATE MISMATCH IN EMPLOYEE ID
-- =====================================================
SELECT
    prod_id,
    'VR007',
    'CROSS_FIELD_MISMATCH',
    'Start_Date_Mismatch_in_Employee_ID',
    'employee_id, start_date',
    'MEDIUM',
    'Compare start date with the start date embedded inside the employee ID',
    current_timestamp()
from validation_base
where
    employee_id is not null
    and start_date is not null
    and substr(employee_id, 9, 6) <> format_date('%Y%m', start_date)
union all
-- =====================================================
-- VR008 - START AGE RULE
-- =====================================================
select
    prod_id,
    'VR008',
    'BUSINESS_RULE_EXCEPTION',
    case
        when age_at_start < 18 then 'Start_Age_Under_18'
        when age_at_start > 45 then 'Start_Age_Over_45'
    end as error_type,
    'dob, start_date',
    'HIGH',
    'Review whether employee start age is valid based on policy',
    current_timestamp()
from validation_base
where
    age_at_start < 18 or age_at_start > 45
union all
-- =====================================================
-- VR009 - START DATE NOT FIRST DAY
-- =====================================================
select
    prod_id,
    'VR009',
    'BUSINESS_RULE_EXCEPTION',
    'Start_Date_Not_First_Day',
    'start_date, employee_id',
    'LOW',
    'Confirm whether start date should begin on the first day of the month',
    current_timestamp()
from validation_base
where start_day <> 1
union all
-- =====================================================
-- VR010 - SALARY GROUP / THP MISMATCH
-- =====================================================
select
    prod_id,
    'VR010',
    'SALARY_VALIDATION',
    'Mismatched_Group_Salary_and_THP',
    'group_sal, thp',
    'MEDIUM',
    'Review whether salary group matches the expected THP range',
    current_timestamp()
from validation_base
where
    expected_group_sal NOT IN ('UNDER', 'OVER')
    AND group_sal <> expected_group_sal
union all
-- =====================================================
-- VR011 - THP UNDER RANGE
-- =====================================================
select
    prod_id,
    'VR011',
    'SALARY_VALIDATION',
    'THP_Under',
    'thp',
    'MEDIUM',
    'Review whether THP is below the expected salary range',
    current_timestamp()
from validation_base
where expected_group_sal = 'UNDER'
union all
-- =====================================================
-- VR012 - THP OVER RANGE
-- =====================================================
select
    prod_id,
    'VR012',
    'SALARY_VALIDATION',
    'THP_Over',
    'thp',
    'MEDIUM',
    'Review whether THP is above the expected salary range',
    current_timestamp()
from validation_base
where expected_group_sal = 'OVER'
union all
-- =====================================================
-- VR013 - DUPLICATE EMAIL
-- =====================================================
select
    prod_id,
    'VR013',
    'DUPLICATE_RECORD',
    'Duplicate_Email',
    'email',
    'MEDIUM',
    'Review whether the email is shared, duplicated, or assigned incorrectly',
    current_timestamp()
from validation_base
where email_count > 1
union all
-- =====================================================
-- VR014 - MISSING EMAIL
-- =====================================================
select
    prod_id,
    'VR014',
    'MISSING_DATA',
    'Missing_Email',
    'email',
    'LOW',
    'Request or complete the missing employee email value',
    current_timestamp()
from validation_base
where email is null
union all
-- =====================================================
-- VR015 - MISSING BRANCH ID
-- =====================================================
select
    prod_id,
    'VR015',
    'MISSING_DATA',
    'Missing_Branch_ID',
    'branch_id',
    'MEDIUM',
    'Review the source record and assign the correct branch ID',
    current_timestamp()
from validation_base
where branch_id IS NULL
union all
-- =====================================================
-- VR016 - MISSING PHONE NUMBER
-- =====================================================
select
    prod_id,
    'VR016',
    'MISSING_DATA',
    'Missing_Phone_Number',
    'phone_number',
    'LOW',
    'Request or complete the missing employee phone number',
    current_timestamp()
from validation_base
where phone_number is null
union all
-- =====================================================
-- VR017 - INVALID PHONE LENGTH
-- =====================================================
select
    prod_id,
    'VR017',
    'FORMAT_ERROR',
    case
        when length(phone_number) < 10 then 'Phone_Number_Too_Short'
        when length(phone_number) > 12 then 'Phone_Number_Too_Long'
    end as error_type,
    'phone_number',
    'LOW',
    'Review phone number length. Expected between 10 and 12 digits',
    current_timestamp()
from validation_base
where
    phone_number is not null
    and(length(phone_number) < 10 or length(phone_number) > 12);


-- =====================================================
-- QA 01. EXCEPTION LOG SUMMARY
-- =====================================================
select
    count(*) as total_issue_flags,
    count(distinct prod_id) as records_with_issues
from dq_audit_portfolio.emp_prof_dqlog;

-- =====================================================
-- QA 02. ISSUE COUNT BY RULE
-- =====================================================
select
    rule_id, error_type, issue_category, severity,
    count(*) as total_records
from dq_audit_portfolio.emp_prof_dqlog
group by
    rule_id, error_type, issue_category, severity
order by
    rule_id, total_records desc;

-- =====================================================
-- QA 03. CHECK IF prod_id EXISTS IN PRODUCTION
-- =====================================================

select
    count(*) as orphan_exception_rows
from
    dq_audit_portfolio.emp_prof_dqlog as dq
    left join
    dq_audit_portfolio.emp_prof_prod as prod on dq.prod_id = prod.prod_id
where prod.prod_id is null;


select * from dq_audit_portfolio.emp_prof_dqlog
