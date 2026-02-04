-- Cohort retention analysis
-- Goal: understand retention over the resident lifecycle by grouping residents into
-- monthly cohorts based on lease_start_date.
--
-- Why cohorts: churn rates can hide when residents leave. Cohorts make it easier to see:
-- - do we lose people early vs late in the lease?
-- - are newer cohorts behaving differently than older ones?
-- - when should we intervene to prevent churn?

-- 1) Monthly cohort retention table
-- Group residents by lease start month, then calculate % still active at M1/M3/M6/M9/M12.
with resident_cohorts as (
    select
        resident_id,
        property_id,
        lease_start_date,
        move_out_date,
        date_trunc(lease_start_date, month) as cohort_month,
        case
            when move_out_date is null then 9999  -- still active; treat as "hasn't churned yet"
            else date_diff(move_out_date, lease_start_date, month)
        end as months_until_churn
    from `greenfield-rbp-analysis.greenfield.residents`
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
        sum(case when rc.months_until_churn >= 1 then 1 else 0 end) / cs.cohort_size * 100,
        1
    ) as retention_m1,

    round(
        sum(case when rc.months_until_churn >= 3 then 1 else 0 end) / cs.cohort_size * 100,
        1
    ) as retention_m3,

    round(
        sum(case when rc.months_until_churn >= 6 then 1 else 0 end) / cs.cohort_size * 100,
        1
    ) as retention_m6,

    round(
        sum(case when rc.months_until_churn >= 9 then 1 else 0 end) / cs.cohort_size * 100,
        1
    ) as retention_m9,

    round(
        sum(case when rc.months_until_churn >= 12 then 1 else 0 end) / cs.cohort_size * 100,
        1
    ) as retention_m12
from resident_cohorts rc
join cohort_sizes cs on rc.cohort_month = cs.cohort_month
where rc.cohort_month < date_trunc(current_date(), month)  -- exclude the current partial month
group by rc.cohort_month, cs.cohort_size
order by rc.cohort_month;


-- 2) Cohort churn rates (inverse of retention)
-- Same cohort setup, but shown as churn-by checkpoints (some stakeholders prefer this view).
with resident_cohorts as (
    select
        resident_id,
        date_trunc(lease_start_date, month) as cohort_month,
        case
            when move_out_date is null then 9999
            else date_diff(move_out_date, lease_start_date, month)
        end as months_until_churn
    from `greenfield-rbp-analysis.greenfield.residents`
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
where rc.cohort_month <= date_sub(current_date(), interval 12 month)  -- only cohorts with 12+ months of runway
group by rc.cohort_month, cs.cohort_size
order by rc.cohort_month;


-- 3) Cohort retention by city
-- Quick market cut: where are cohorts holding up better/worse (M6 / M12)?
with resident_cohorts as (
    select
        r.resident_id,
        p.city,
        date_trunc(r.lease_start_date, month) as cohort_month,
        case
            when r.move_out_date is null then 9999
            else date_diff(r.move_out_date, r.lease_start_date, month)
        end as months_until_churn
    from `greenfield-rbp-analysis.greenfield.residents` r
    join `greenfield-rbp-analysis.greenfield.properties` p on r.property_id = p.property_id
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


-- 4) Rolling 12-month cohort comparison
-- Compare two “year buckets” of cohorts to see if retention is improving over time.
with resident_cohorts as (
    select
        resident_id,
        date_trunc(lease_start_date, month) as cohort_month,
        case
            when move_out_date is null then 9999
            else date_diff(move_out_date, lease_start_date, month)
        end as months_until_churn
    from `greenfield-rbp-analysis.greenfield.residents`
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


-- 5) Survival curve data (for visualization)
-- Output points you can plot as a survival curve: retention % over days since lease start.
with resident_cohorts as (
    select
        resident_id,
        case
            when move_out_date is null then 999
            else date_diff(move_out_date, lease_start_date, day)
        end as days_until_churn
    from `greenfield-rbp-analysis.greenfield.residents`
    where lease_start_date <= date_sub(current_date(), interval 365 day)  -- need at least ~1 year of runway
),
day_points as (
    select day_num
    from unnest(generate_array(0, 365, 30)) as day_num  -- every 30 days
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
