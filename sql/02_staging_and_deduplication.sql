create table employee_prof_staging (
  id_num text,
  employee_id text,
  name text,
  branch_id text,
  dob text,
  phone_number text,
  age int default null,
  start_date text,
  gender text,
  group_sal text character set utf8mb4 collate utf8mb4_0900_ai_ci,
  thp int default null,
  email text,
  last_update text,
  row_num int default null
) engine = innodb default charset = utf8mb4 collate = utf8mb4_0900_ai_ci;

insert into employee_prof_staging
select
    *,
    row_number() over(
        partition by id_num, employee_id, name, branch_id, dob, phone_number, age,
                     start_date, gender, group_sal, thp, email, last_update
    ) as dup_row
from
    employee_profile;

select
    *
from
    employee_prof_staging;

delete
from
    employee_prof_staging
where
    row_num > 1;
-- 150 duplicate rows deleted 

select
    id_num,
    count(id_num) as total
from
    employee_prof_staging
group by
    id_num
having
    total > 1
order by
    total desc;

select
    employee_id,
    count(employee_id) as total
from
    employee_prof_staging
group by
    employee_id
having
    total > 1
order by
    total desc;