-- =============================================================================
-- COHORT RETENTION ANALYSIS
-- =============================================================================
-- Purpose: Track resident retention over time by grouping residents into monthly
-- cohorts based on their lease start date.
--
-- Why cohort analysis? Unlike simple churn rates, cohort analysis shows how
-- retention changes over the resident lifecycle. This helps answer questions like:
-- - Do we lose most residents early or late in their lease?
-- - Are newer cohorts retaining better than older ones?
-- - At what point should we intervene to prevent churn?
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Monthly Cohort Retention Table
-- -----------------------------------------------------------------------------
-- Groups residents by lease start month and tracks what percentage are still
-- active at months 1, 3, 6, 9, and 12.

with resident_cohorts as (
    select
        resident_id,
        property_id,
        lease_start_date,
        move_out_date,
        date_trunc(lease_start_date, month) as cohort_month,
        case
            when move_out_date is null then 9999  -- Still active, use large number
            else date_diff(move_out_date, lease_start_date, month)
        end as months_until_churn
    from `project.dataset.residents`
),
cohort_sizes as (
    select
        cohort_month,
        count(*) as cohort_size
    from resident_cohorts
    group by cohort_month
)

select
    format_date('%Y-%m', rc.cohort_month) as cohort,
    cs.cohort_size,

    -- Month 1 retention
    round(
        sum(case when rc.months_until_churn >= 1 then 1 else 0 end) / cs.cohort_size * 100,
        1
    ) as retention_m1,

    -- Month 3 retention
    round(
        sum(case when rc.months_until_churn >= 3 then 1 else 0 end) / cs.cohort_size * 100,
        1
    ) as retention_m3,

    -- Month 6 retention
    round(
        sum(case when rc.months_until_churn >= 6 then 1 else 0 end) / cs.cohort_size * 100,
        1
    ) as retention_m6,

    -- Month 9 retention
    round(
        sum(case when rc.months_until_churn >= 9 then 1 else 0 end) / cs.cohort_size * 100,
        1
    ) as retention_m9,

    -- Month 12 retention
    round(
        sum(case when rc.months_until_churn >= 12 then 1 else 0 end) / cs.cohort_size * 100,
        1
    ) as retention_m12

from resident_cohorts rc
join cohort_sizes cs on rc.cohort_month = cs.cohort_month
where rc.cohort_month < date_trunc(current_date(), month)  -- Exclude current partial month
group by rc.cohort_month, cs.cohort_size
order by rc.cohort_month;


-- -----------------------------------------------------------------------------
-- 2. Cohort Churn Rates (inverse of retention)
-- -----------------------------------------------------------------------------
-- Sometimes stakeholders prefer to see churn rather than retention.

with resident_cohorts as (
    select
        resident_id,
        date_trunc(lease_start_date, month) as cohort_month,
        case
            when move_out_date is null then 9999
            else date_diff(move_out_date, lease_start_date, month)
        end as months_until_churn
    from `project.dataset.residents`
),
cohort_sizes as (
    select
        cohort_month,
        count(*) as cohort_size
    from resident_cohorts
    group by cohort_month
)

select
    format_date('%Y-%m', rc.cohort_month) as cohort,
    cs.cohort_size,
    round(
        sum(case when rc.months_until_churn < 3 then 1 else 0 end) / cs.cohort_size * 100,
        1
    ) as churn_by_m3,
    round(
        sum(case when rc.months_until_churn < 6 then 1 else 0 end) / cs.cohort_size * 100,
        1
    ) as churn_by_m6,
    round(
        sum(case when rc.months_until_churn < 12 then 1 else 0 end) / cs.cohort_size * 100,
        1
    ) as churn_by_m12
from resident_cohorts rc
join cohort_sizes cs on rc.cohort_month = cs.cohort_month
where rc.cohort_month <= date_sub(current_date(), interval 12 month)  -- Only cohorts with 12 months of data
group by rc.cohort_month, cs.cohort_size
order by rc.cohort_month;


-- -----------------------------------------------------------------------------
-- 3. Cohort Retention by City
-- -----------------------------------------------------------------------------
-- Breaks down cohort retention by market to identify geographic patterns.

with resident_cohorts as (
    select
        r.resident_id,
        p.city,
        date_trunc(r.lease_start_date, month) as cohort_month,
        case
            when r.move_out_date is null then 9999
            else date_diff(r.move_out_date, r.lease_start_date, month)
        end as months_until_churn
    from `project.dataset.residents` r
    join `project.dataset.properties` p on r.property_id = p.property_id
)

select
    city,
    count(*) as total_residents,
    round(
        sum(case when months_until_churn >= 6 then 1 else 0 end) / count(*) * 100,
        1
    ) as retention_m6,
    round(
        sum(case when months_until_churn >= 12 then 1 else 0 end) / count(*) * 100,
        1
    ) as retention_m12
from resident_cohorts
where cohort_month <= date_sub(current_date(), interval 12 month)
group by city
order by retention_m12 desc;


-- -----------------------------------------------------------------------------
-- 4. Rolling 12-Month Cohort Comparison
-- -----------------------------------------------------------------------------
-- Compares recent cohorts to older ones to see if retention is improving.

with resident_cohorts as (
    select
        resident_id,
        date_trunc(lease_start_date, month) as cohort_month,
        case
            when move_out_date is null then 9999
            else date_diff(move_out_date, lease_start_date, month)
        end as months_until_churn
    from `project.dataset.residents`
),
cohort_periods as (
    select
        *,
        case
            when cohort_month between '2022-07-01' and '2023-06-30' then 'Year 1 (Jul 22 - Jun 23)'
            when cohort_month between '2023-07-01' and '2024-06-30' then 'Year 2 (Jul 23 - Jun 24)'
            else 'Other'
        end as period
    from resident_cohorts
)

select
    period,
    count(*) as cohort_size,
    round(
        sum(case when months_until_churn >= 3 then 1 else 0 end) / count(*) * 100,
        1
    ) as retention_m3,
    round(
        sum(case when months_until_churn >= 6 then 1 else 0 end) / count(*) * 100,
        1
    ) as retention_m6
from cohort_periods
where period != 'Other'
group by period
order by period;


-- -----------------------------------------------------------------------------
-- 5. Survival Curve Data (for visualization)
-- -----------------------------------------------------------------------------
-- Provides data points for a survival curve chart showing retention over time.

with resident_cohorts as (
    select
        resident_id,
        case
            when move_out_date is null then 999
            else date_diff(move_out_date, lease_start_date, day)
        end as days_until_churn
    from `project.dataset.residents`
    where lease_start_date <= date_sub(current_date(), interval 365 day)  -- At least 1 year of data
),
day_points as (
    select day_num
    from unnest(generate_array(0, 365, 30)) as day_num  -- Every 30 days
)

select
    dp.day_num as days_since_lease_start,
    count(*) as total_residents,
    sum(case when rc.days_until_churn > dp.day_num then 1 else 0 end) as still_active,
    round(
        sum(case when rc.days_until_churn > dp.day_num then 1 else 0 end) / count(*) * 100,
        1
    ) as retention_pct
from resident_cohorts rc
cross join day_points dp
group by dp.day_num
order by dp.day_num;
