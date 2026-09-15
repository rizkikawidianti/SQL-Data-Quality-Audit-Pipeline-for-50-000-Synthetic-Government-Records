-- =====================================================
-- 04_CREATE_PRODUCTION_TABLE.SQL
--
-- Purpose:
-- Create the production-layer employee table from the
-- standardized staging data and generate a deterministic
-- record identifier for downstream validation and
-- exception logging.
-- =====================================================


-- =====================================================
-- 01. CREATE PRODUCTION TABLE
-- =====================================================

create or replace table
    dq_audit_portfolio.emp_prof_prod
as
  select
    concat(format_date('%Y%m%d', current_date('Asia/Jakarta')),
        lpad(cast(row_number() over (order by
                    employee_id,
                    id_num,
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
                ) as string
            ), 7, '0')
      ) as prod_id,
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
  from dq_audit_portfolio.emp_prof_staging;


-- =====================================================
-- 02. ROW COUNT RECONCILIATION
-- =====================================================

select
    staging.staging_rows,
    production.production_rows,
    production.production_rows - staging.staging_rows as row_difference
from (select count(*) as staging_rows
    from dq_audit_portfolio.emp_prof_staging
) as staging
cross join(select count(*) as production_rows
    from dq_audit_portfolio.emp_prof_prod) as production;

-- =====================================================
-- 03. PROD_ID UNIQUENESS CHECK
-- =====================================================

select
    count(*) AS total_records,
    count(distinct prod_id) as unique_prod_ids,
    count(*) - count(distinct prod_id) as duplicate_prod_ids
from dq_audit_portfolio.emp_prof_prod;