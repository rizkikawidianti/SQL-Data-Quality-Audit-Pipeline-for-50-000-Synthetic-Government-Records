create table emp_prof_dqlog as
with validation_checks as (
select
	*,
	count(id_num) over(partition by id_num) as id_count,
	count(employee_id) over(partition by employee_id) as emp_id_count,
	year(dob) as birth_year,
	timestampdiff(year, dob, start_date) as age_start,
	day(start_date) as start_day,
	case
			when thp >= 8000000
			and thp <= 9000000 then '1'
			when thp> 9000000
			and thp <= 10000000 then '2'
			when thp> 10000000
			and thp <= 11000000 then '3'
			when thp> 11000000
			and thp <= 12000000 then '4'
			when thp < 8000000 then 'under'
			when thp > 12000000 then 'over'
		end as supposed_thp,
	count(email) over(partition by email) as email_count
	from
		emp_prof_prod
)
-- 1. for duplicate ID
select 
    prod_id,
    'VR001' as rule_id,
    'DUPLICATE_RECORD' as issue_category,
    'Duplicate_ID' as error_type,
    'id_num' as affected_field,
    'HIGH' as severity,
    'Review duplicated ID number against the source system' as recommended_action,
    current_timestamp as logged_at
from validation_checks
where id_count > 1
union all
-- 2. for duplicate Employee ID
select 
	prod_id,
	'VR002',
    'DUPLICATE_RECORD',
    'Duplicate_Employee_ID',
    'employee_id',
    'HIGH',
    'Review duplicated employee ID against HR or master employee records',
    current_timestamp
from
	validation_checks
where
	emp_id_count > 1
union all
-- 3. Invalid ID number length
select 
    prod_id,
    'VR003',
    'FORMAT_ERROR',
    'Invalid_ID_Length',
    'id_num',
    'HIGH',
    'Review ID number length. Expected 16 digits',
    current_timestamp
from
    validation_checks
where
    id_num is not null
    and length(id_num) <> 16
union all
-- 4. Invalid employee ID length
select 
    prod_id,
    'VR004',
    'FORMAT_ERROR',
    'Invalid_Employee_ID_Length',
    'employee_id',
    'HIGH',
    'Review employee ID length. Expected 18 digits',
    current_timestamp
from
    validation_checks
where
    employee_id is not null
    and length(employee_id) <> 18
union all
-- 5. for DOB mismatches in ID
select
	prod_id,
	'VR005',
    'CROSS_FIELD_MISMATCH',
    'DOB_Mismatch_in_ID',
    'id_num, dob',
    'HIGH',
    'Compare DOB column with the DOB embedded inside the ID number',
    current_timestamp
from
	validation_checks
where
	substring(id_num, 5, 8) != date_format(dob, '%Y%m%d')
	and id_num is not null
	and dob is not null
union all
-- 6. for DOB mismatches in Employee ID
select 
	prod_id,
	'VR006',
    'CROSS_FIELD_MISMATCH',
    'DOB_Mismatch_in_Employee_ID',
    'employee_id, dob',
    'HIGH',
    'Compare DOB column with the DOB embedded inside the employee ID',
    current_timestamp
from
	validation_checks
where
	substring(employee_id, 1, 8)!= date_format(dob, '%Y%m%d')
	and employee_id is not null
	and dob is not null
union all
-- 7. for Start Date mismatches in Employee ID
select
	prod_id,
	'VR007',
    'CROSS_FIELD_MISMATCH',
    'Start_Date_Mismatch_in_Employee_ID',
    'employee_id, start_date',
    'MEDIUM',
    'Compare start_date column with the start date embedded inside the employee ID',
    current_timestamp
from
	validation_checks
where
	substring(employee_id, 9, 6)!= date_format(start_date, '%Y%m')
union all
-- 8. for Start Date before 18 years old or after 45 years old
select 
	prod_id,
	'VR008',
    'BUSINESS_RULE_EXCEPTION',
	case 
		when age_start < 18 then 'Start_Age_Under_18'
		when age_start > 45 then 'Start_Age_Over_45'
	end,
	'start_date, dob',
    'HIGH',
    'Review whether the employee start age is valid based on policy',
    current_timestamp
from
	validation_checks
where
	age_start < 18
	or age_start > 45
union all
-- 9. for Start Day is not on the first day of the month
select
	prod_id,
	'VR009',
    'BUSINESS_RULE_EXCEPTION',
    'Start_Date_Not_First_Day',
    'start_date, employee_id',
    'LOW',
    'Confirm whether start_date should always begin on the first day of the month',
    current_timestamp
from
	validation_checks
where
	start_day >1
union all
-- 10. mismatch group salary and THP value
select 
	prod_id,
	'VR010',
    'SALARY_VALIDATION',
    'Mismatched_Group_Salary_and_THP',
	'thp, group_sal',
    'MEDIUM',
    'Review whether group_sal matches the expected THP salary range',
    current_timestamp
from
	validation_checks
where
	group_sal != supposed_thp
	and supposed_thp not in ('over','under')
union all
-- 11. THP under value
select 
	prod_id,
	'VR011',
    'SALARY_VALIDATION',
    'THP_Under',
	'thp, group_sal',
    'MEDIUM',
    'Review whether THP value is below the expected salary range',
    current_timestamp
from
	validation_checks
where
	supposed_thp = 'under'
union all
-- 12. THP above value
select 
	prod_id,
	'VR012',
    'SALARY_VALIDATION',
    'THP_Over',
	'thp, group_sal',
    'MEDIUM',
    'Review whether THP value is above the expected salary range',
    current_timestamp
from
	validation_checks
where
	supposed_thp ='over'
union all
-- 13. Duplicate email
select 
	prod_id,
	'VR013',
    'DUPLICATE_RECORD',
    'Duplicate_Email',
    'email',
    'MEDIUM',
    'Review whether the email is shared, duplicated, or assigned to the wrong employee',
    current_timestamp
from
	validation_checks
where
	email_count > 1
union all
-- 14. Missing email
select 
	prod_id,
	'VR014',
    'MISSING_DATA',
    'Missing_Email',
    'email',
    'LOW',
    'Request or complete the missing employee email value',
    current_timestamp
from
	validation_checks
where
	email is null
union all
-- 15. Missing Branch ID
select 
	prod_id,
	'VR015',
    'MISSING_DATA',
    'Missing_Branch_ID',
    'branch_id',
    'MEDIUM',
    'Review source record and assign the correct branch ID',
    current_timestamp
from
	validation_checks
where
	branch_id is null
union all
-- 16. Missing Phone Number
select 
	prod_id,
	'VR016',
    'MISSING_DATA',
    'Missing_Phone_Number',
    'phone_number',
    'LOW',
    'Request or complete the missing phone number',
    current_timestamp
from
	validation_checks
where
	phone_number is null;