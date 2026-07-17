-- 1. ID number length check
select
    id_num,
    length(id_num) as len
from
    emp_prof_prod
where
    length(id_num) < 16
    or length(id_num) > 16;


-- 2. DOB embedded in ID number check
select
    id_num,
    dob,
    substring(id_num, 5, 8) as dob_from_id
from
    emp_prof_prod
where
    substring(id_num, 5, 8) != date_format(dob, '%Y%m%d');


-- 3. Employee ID length check
select
    employee_id,
    length(employee_id) as len
from
    emp_prof_prod
where
    length(employee_id) < 18
    or length(employee_id) > 18;


-- 4. DOB embedded in employee ID check
select
    employee_id,
    dob,
    substring(employee_id, 1, 8) as dob_from_emp_id
from
    emp_prof_prod
where
    substring(employee_id, 1, 8) != date_format(dob, '%Y%m%d');


-- 5. Start date embedded in employee ID check
select
    employee_id,
    start_date,
    substring(employee_id, 9, 6) as sdate_from_emp_id
from
    emp_prof_prod
where
    substring(employee_id, 9, 6) != date_format(start_date, '%Y%m');


-- 6. Start age business rule check
with age_start_check as (
    select
        prod_id,
        dob,
        start_date,
        timestampdiff(year, dob, start_date) as age_start
    from emp_prof_prod
)
select *
from age_start_check
where age_start < 18
   or age_start > 45;


-- 7. Start date day rule check
with start_day_check as (
    select
        prod_id,
        start_date,
        day(start_date) as start_day
    from emp_prof_prod
)
select *
from start_day_check
where start_day > 1;


-- 8. THP and salary group validation
select
    thp,
    group_sal,
    case
        when thp >= 8000000 and thp <= 9000000 then '1'
        when thp > 9000000 and thp <= 10000000 then '2'
        when thp > 10000000 and thp <= 11000000 then '3'
        when thp > 11000000 and thp <= 12000000 then '4'
        when thp < 8000000 then 'under'
        when thp > 12000000 then 'over'
    end as supposed_thp
from
    emp_prof_prod
having
    group_sal != supposed_thp;


-- 9. Phone number length check
select
    phone_number,
    length(phone_number) as len
from
    emp_prof_prod
where
    length(phone_number) < 10
    or length(phone_number) > 12;











