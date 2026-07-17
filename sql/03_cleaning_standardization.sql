-- Standardize messy field formats before validation

-- 1. Name quality check
select
    name
from
    employee_prof_staging
where
    name regexp '[^a-zA-Z ]';


-- 2. Branch ID standardization
select
    branch_id,
    case
        when branch_id regexp '[a-zA-Z]' then trim(right(branch_id, 2))
        when branch_id like '' then null
        when branch_id regexp '^[0-9]$' then concat('0', trim(branch_id))
        else trim(branch_id)
    end as new_branch
from
    employee_prof_staging;

update
    employee_prof_staging
set
    branch_id = case
        when branch_id regexp '[a-zA-Z]' then trim(right(branch_id, 2))
        when branch_id like '' then null
        when branch_id regexp '^[0-9]$' then concat('0', trim(branch_id))
        else trim(branch_id)
    end;


-- 3. Date of birth standardization
select
	dob,
	case
		-- when XX > 12 (YYYY-XX-YY)
		when trim(dob) regexp '^[0-1][0-9]-([1][3-9]|[2][0-9]|[3][0-1])-[0-9]{4}' 
	    	then str_to_date(trim(dob), '%m-%d-%Y')
		-- format: DD-MM-YYYY
		when trim(dob) like '__-__-____' 
	    	then str_to_date(trim(dob), '%d-%m-%Y')
		-- format: DD/MM/YYYY
		when trim(dob) like '__/%/%' 
	    	then str_to_date(trim(dob), '%d/%m/%Y')
		-- format: YYYY/MM/DD
		when trim(dob) like '____/%/%' 
            then str_to_date(trim(dob), '%Y/%m/%d')
		else trim(dob)
	end as new_dob
from
	employee_prof_staging;

update
	employee_prof_staging
set
	dob = case
		-- when XX > 12 (YYYY-XX-YY)
		when trim(dob) regexp '^[0-1][0-9]-([1][3-9]|[2][0-9]|[3][0-1])-[0-9]{4}' 
	    	then str_to_date(trim(dob), '%m-%d-%Y')
		-- format: DD-MM-YYYY
		when trim(dob) like '__-__-____' 
	    	then str_to_date(trim(dob), '%d-%m-%Y')
		-- format: DD/MM/YYYY
		when trim(dob) like '__/%/%' 
	    	then str_to_date(trim(dob), '%d/%m/%Y')
		-- format: YYYY/MM/DD
		when trim(dob) like '____/%/%' 
            then str_to_date(trim(dob), '%Y/%m/%d')
		else trim(dob)
	end;


-- 4. Phone number standardization
select
	phone_number,
	length(phone_number) as digits
from
	employee_prof_staging
	-- where length(phone_number) < 10 or length(phone_number) > 12
where
	phone_number like '';

with correct_phone as(
select phone_number, case 
	when phone_number regexp '^[1-9]' then concat('0', trim(phone_number))
	when phone_number regexp '[- ]' then regexp_replace(phone_number, '[- ]', '')
	when phone_number like '' then null
	else trim(phone_number)
end as new_phone
from employee_prof_staging)
select
	*,
	length(new_phone) as digits
from
	correct_phone;
-- having digits < 10 or digits > 12;

update
	employee_prof_staging
set
	phone_number = case
		when phone_number regexp '^[1-9]' then concat('0', trim(phone_number))
		when phone_number regexp '[- ]' then regexp_replace(phone_number, '[- ]', '')
		when phone_number like '' then null
		else trim(phone_number)
	end;

select
	phone_number,
	length(phone_number) as digits
from
	employee_prof_staging;


-- 5. Start date standardization
with correct_sdate as (
select
	start_date,
	case
		-- FORMAT: MM-DD-YYYY
		when trim(start_date) regexp '^[0-1][0-9]-([1][3-9]|[2][0-9]|[3][0-1])-[0-9]{4}' 
            then str_to_date(trim(start_date), '%m-%d-%Y')
		-- FORMAT: DD-MM-YYYY
		when trim(start_date) like '__-__-____' 
            then str_to_date(trim(start_date), '%d-%m-%Y')
		-- FORMAT: DD/MM/YYYY
		when trim(start_date) like '__/%/%' 
            then str_to_date(trim(start_date), '%d/%m/%Y')
		-- FORMAT: YYYY/MM/DD
		when trim(start_date) like '____/%/%' 
            then str_to_date(trim(start_date), '%Y/%m/%d')
		-- FORMAT: 'Apr 5, 2018'
		when trim(start_date) regexp '^[a-zA-Z]{3} [0-9]{2}, [0-9]{4}' 
            then str_to_date(trim(start_date), '%b %d, %Y')
		else trim(start_date)
	end as new_sdate
from
	employee_prof_staging)
select
	*
from
	correct_sdate;

update
	employee_prof_staging
set
	start_date = case
		-- FORMAT: MM-DD-YYYY
		when trim(start_date) regexp '^[0-1][0-9]-([1][3-9]|[2][0-9]|[3][0-1])-[0-9]{4}' 
            then str_to_date(trim(start_date), '%m-%d-%Y')
		-- FORMAT: DD-MM-YYYY
		when trim(start_date) like '__-__-____' 
            then str_to_date(trim(start_date), '%d-%m-%Y')
		-- FORMAT: DD/MM/YYYY
		when trim(start_date) like '__/%/%' 
            then str_to_date(trim(start_date), '%d/%m/%Y')
		-- FORMAT: YYYY/MM/DD
		when trim(start_date) like '____/%/%' 
            then str_to_date(trim(start_date), '%Y/%m/%d')
		-- FORMAT: 'Apr 5, 2018'
		when trim(start_date) regexp '^[a-zA-Z]{3} [0-9]{2}, [0-9]{4}' 
            then str_to_date(trim(start_date), '%b %d, %Y')
		else trim(start_date)
	end;


-- 6. Gender standardization
select
	distinct(gender),
	count(gender) as counts
from
	employee_prof_staging
group by
	1
order by
	2 desc;

select
	gender,
	case
		when trim(gender) in ('female', 'f', 'woman') then 'F'
		when trim(gender) in ('male', 'm', 'man') then 'M'
		when trim(gender) = '' then null
		else trim(gender)
	end as new_gender
from
	employee_prof_staging;

update
	employee_prof_staging
set
	gender = case
		when trim(gender) in ('female', 'f', 'woman') then 'F'
		when trim(gender) in ('male', 'm', 'man') then 'M'
		when trim(gender) = '' then null
		else trim(gender)
	end;


-- 7. Salary group standardization
select
	group_sal,
	case
		when group_sal regexp '^[a-zA-Z]' then right(group_sal, 1)
		when group_sal like '0%' then right(group_sal, 1)
		else trim(group_sal)
	end as new_group
from
	employee_prof_staging;

update
	employee_prof_staging
set
	group_sal = case
		when group_sal regexp '^[a-zA-Z]' then right(group_sal, 1)
		when group_sal like '0%' then right(group_sal, 1)
		else trim(group_sal)
	end;


-- 8. THP range check
select
	thp
from
	employee_prof_staging
where
	thp <8000000
	or thp >12000000;


-- 9. Email standardization
select
	email,
	case
		when email like '' then null
		else trim(email)
	end as new_email
from
	employee_prof_staging;

update
	employee_prof_staging
set
	email = case
		when email like '' then null
		else trim(email)
	end;


-- 10. Convert cleaned columns into final data types
alter table employee_prof_staging 
modify column dob date,
modify column start_date date;


-- 11. Remove duplicate marker column after deduplication
alter table employee_prof_staging 
drop column row_num;