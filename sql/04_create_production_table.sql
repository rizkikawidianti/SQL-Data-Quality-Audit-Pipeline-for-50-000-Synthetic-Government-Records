create table emp_prof_prod as
select 
    row_number() over(
        order by 
            employee_id,
            id_num,
            name,
            dob,
            start_date,
            email,
            last_update
    ) as prod_id,
    eps.*
from
    employee_prof_staging eps;

select
    count(*) as production_total_rows
from
    emp_prof_prod;

select
    *
from
    emp_prof_prod
limit 100;