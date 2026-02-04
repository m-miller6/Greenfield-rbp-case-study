-- Core metrics for the Greenfield Properties RBP program.
-- These are the numbers you’d typically pull first to understand portfolio health:
-- active units, revenue (MRR/CARR), activation, and product adoption depth.

-- 1) Total Active Units
-- Active units = residents who have not moved out yet (move_out_date is NULL).
select
    count(*) as total_active_units
from `greenfield-rbp-analysis.greenfield.residents`
where move_out_date is null;


-- 2) Active Units by Property and City
-- Quick view of where occupancy lives and how each property is tracking vs unit count.
select
    p.city,
    p.property_name,
    p.property_id,
    count(r.resident_id) as active_units,
    p.unit_count as total_units,
    round(count(r.resident_id) / p.unit_count * 100, 1) as occupancy_pct
from `greenfield-rbp-analysis.greenfield.properties` p
left join `greenfield-rbp-analysis.greenfield.residents` r
    on p.property_id = r.property_id
    and r.move_out_date is null
group by p.city, p.property_name, p.property_id, p.unit_count
order by p.city, active_units desc;


-- 3) Monthly Recurring Revenue (MRR)
-- MRR here is the sum of monthly fees for benefits that are:
-- activated, not cancelled, and tied to residents who are still active.
select
    sum(e.monthly_fee) as mrr_dollars
from `greenfield-rbp-analysis.greenfield.benefit_enrollments` e
join `greenfield-rbp-analysis.greenfield.residents` r on e.resident_id = r.resident_id
where e.activation_date is not null
  and e.cancellation_date is null
  and r.move_out_date is null;


-- 4) Committed Annual Recurring Revenue (CARR)
-- Just annualized MRR (MRR * 12) to make it easier to talk in annual terms.
with current_mrr as (
    select
        sum(e.monthly_fee) as mrr
    from `greenfield-rbp-analysis.greenfield.benefit_enrollments` e
    join `greenfield-rbp-analysis.greenfield.residents` r on e.resident_id = r.resident_id
    where e.activation_date is not null
      and e.cancellation_date is null
      and r.move_out_date is null
)
select
    mrr as monthly_recurring_revenue,
    mrr * 12 as committed_annual_recurring_revenue
from current_mrr;


-- 5) MRR Breakdown by Benefit Type
-- Useful for seeing which benefits are actually driving the revenue.
select
    e.benefit_type,
    count(*) as active_enrollments,
    sum(e.monthly_fee) as mrr_contribution,
    round(sum(e.monthly_fee) / (
        select sum(monthly_fee)
        from `greenfield-rbp-analysis.greenfield.benefit_enrollments` be
        join `greenfield-rbp-analysis.greenfield.residents` re on be.resident_id = re.resident_id
        where be.activation_date is not null
          and be.cancellation_date is null
          and re.move_out_date is null
    ) * 100, 1) as pct_of_total_mrr
from `greenfield-rbp-analysis.greenfield.benefit_enrollments` e
join `greenfield-rbp-analysis.greenfield.residents` r on e.resident_id = r.resident_id
where e.activation_date is not null
  and e.cancellation_date is null
  and r.move_out_date is null
group by e.benefit_type
order by mrr_contribution desc;


-- 6) Activation Rate by Benefit Type
-- This is enrollment-row level: activated enrollments / total enrollments, by benefit.
select
    benefit_type,
    count(*) as total_enrollments,
    sum(case when activation_date is not null then 1 else 0 end) as activated,
    round(
        sum(case when activation_date is not null then 1 else 0 end) / count(*) * 100,
        1
    ) as activation_rate_pct
from `greenfield-rbp-analysis.greenfield.benefit_enrollments`
group by benefit_type
order by activation_rate_pct desc;


-- 7) Overall Portfolio Activation Rate
-- Excluding P017 due to the activation-date data quality issue flagged in validation.
select
    count(*) as total_enrollments,
    sum(case when activation_date is not null then 1 else 0 end) as activated,
    round(
        sum(case when activation_date is not null then 1 else 0 end) / count(*) * 100,
        1
    ) as activation_rate_pct
from `greenfield-rbp-analysis.greenfield.benefit_enrollments` e
join `greenfield-rbp-analysis.greenfield.residents` r on e.resident_id = r.resident_id
where r.property_id != 'P017';  -- Exclude property with data quality issue


-- 8) Average Benefits per Resident
-- Measures adoption depth across active residents (how many benefits they’ve enrolled in).
with benefits_per_resident as (
    select
        r.resident_id,
        count(e.enrollment_id) as benefit_count
    from `greenfield-rbp-analysis.greenfield.residents` r
    left join `greenfield-rbp-analysis.greenfield.benefit_enrollments` e on r.resident_id = e.resident_id
    where r.move_out_date is null  -- Active residents only
    group by r.resident_id
)
select
    round(avg(benefit_count), 2) as avg_benefits_per_resident,
    min(benefit_count) as min_benefits,
    max(benefit_count) as max_benefits
from benefits_per_resident;


-- 9) Active Benefits per Resident (activated, not cancelled)
-- Same idea as above, but only counts benefits that are actually active.
with active_benefits_per_resident as (
    select
        r.resident_id,
        count(e.enrollment_id) as active_benefit_count
    from `greenfield-rbp-analysis.greenfield.residents` r
    left join `greenfield-rbp-analysis.greenfield.benefit_enrollments` e
        on r.resident_id = e.resident_id
        and e.activation_date is not null
        and e.cancellation_date is null
    where r.move_out_date is null
    group by r.resident_id
)
select
    round(avg(active_benefit_count), 2) as avg_active_benefits_per_resident
from active_benefits_per_resident;


-- 10) Metrics Summary Dashboard Query
-- One-row rollup you can plug straight into a simple exec dashboard.
with active_residents as (
    select count(*) as active_units
    from `greenfield-rbp-analysis.greenfield.residents`
    where move_out_date is null
),
mrr_calc as (
    select sum(e.monthly_fee) as mrr
    from `greenfield-rbp-analysis.greenfield.benefit_enrollments` e
    join `greenfield-rbp-analysis.greenfield.residents` r on e.resident_id = r.resident_id
    where e.activation_date is not null
      and e.cancellation_date is null
      and r.move_out_date is null
),
activation as (
    select
        round(
            sum(case when activation_date is not null then 1 else 0 end) / count(*) * 100,
            1
        ) as activation_rate
    from `greenfield-rbp-analysis.greenfield.benefit_enrollments` e
    join `greenfield-rbp-analysis.greenfield.residents` r on e.resident_id = r.resident_id
    where r.property_id != 'P017'
),
benefits_count as (
    select round(avg(cnt), 2) as avg_benefits
    from (
        select r.resident_id, count(e.enrollment_id) as cnt
        from `greenfield-rbp-analysis.greenfield.residents` r
        left join `greenfield-rbp-analysis.greenfield.benefit_enrollments` e on r.resident_id = e.resident_id
        where r.move_out_date is null
        group by r.resident_id
    )
)
select
    ar.active_units,
    m.mrr as monthly_recurring_revenue,
    m.mrr * 12 as carr,
    a.activation_rate as activation_rate_pct,
    b.avg_benefits as avg_benefits_per_resident
from active_residents ar
cross join mrr_calc m
cross join activation a
cross join benefits_count b;
