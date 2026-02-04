-- Churn investigation
-- Goal: dig into what’s driving resident churn and surface levers that could realistically move retention.

-- 1) Churn Rate by City
-- First cut: do we see any clear differences by market?
select
    p.city,
    count(r.resident_id) as total_residents,
    sum(case when r.move_out_date is not null then 1 else 0 end) as churned,
    round(
        sum(case when r.move_out_date is not null then 1 else 0 end) / count(*) * 100,
        1
    ) as churn_rate_pct
from `greenfield-rbp-analysis.greenfield.residents` r
join `greenfield-rbp-analysis.greenfield.properties` p on r.property_id = p.property_id
group by p.city
order by churn_rate_pct desc;

-- FINDING: Alexandria shows a significantly higher churn rate compared to
-- Arlington and Washington DC. This warrants deeper investigation.


-- 2) Churn Rate by Property (Top 10 Highest Churn)
-- Helps separate “market problem” from “a few properties dragging the average.”
select
    p.property_id,
    p.property_name,
    p.city,
    p.property_manager_name,
    count(r.resident_id) as total_residents,
    sum(case when r.move_out_date is not null then 1 else 0 end) as churned,
    round(
        sum(case when r.move_out_date is not null then 1 else 0 end) / count(*) * 100,
        1
    ) as churn_rate_pct
from `greenfield-rbp-analysis.greenfield.residents` r
join `greenfield-rbp-analysis.greenfield.properties` p on r.property_id = p.property_id
group by p.property_id, p.property_name, p.city, p.property_manager_name
having count(r.resident_id) >= 50  -- Exclude small sample sizes
order by churn_rate_pct desc
limit 10;


-- 3) Activation Speed vs. Retention
-- Hypothesis: faster activation leads to better retention.
-- "Early activator" = activated at least one benefit within 7 days of enrollment.
with resident_activation as (
    select
        r.resident_id,
        r.move_out_date,
        min(date_diff(e.activation_date, e.enrollment_date, day)) as fastest_activation_days
    from `greenfield-rbp-analysis.greenfield.residents` r
    join `greenfield-rbp-analysis.greenfield.benefit_enrollments` e on r.resident_id = e.resident_id
    where e.activation_date is not null
    group by r.resident_id, r.move_out_date
),
activation_groups as (
    select
        resident_id,
        move_out_date,
        case
            when fastest_activation_days <= 7 then 'Early Activator (0-7 days)'
            else 'Late Activator (8+ days)'
        end as activation_group
    from resident_activation
)
select
    activation_group,
    count(*) as total_residents,
    sum(case when move_out_date is not null then 1 else 0 end) as churned,
    round(
        sum(case when move_out_date is not null then 1 else 0 end) / count(*) * 100,
        1
    ) as churn_rate_pct
from activation_groups
group by activation_group
order by churn_rate_pct;

-- FINDING: Residents who activate benefits within 7 days of enrollment show
-- noticeably lower churn rates. This suggests that driving faster activation
-- could improve retention.


-- 4) Churn by Number of Benefits Enrolled
-- Hypothesis: deeper adoption correlates with better retention.
with resident_benefit_counts as (
    select
        r.resident_id,
        r.move_out_date,
        count(e.enrollment_id) as benefit_count
    from `greenfield-rbp-analysis.greenfield.residents` r
    left join `greenfield-rbp-analysis.greenfield.benefit_enrollments` e on r.resident_id = e.resident_id
    group by r.resident_id, r.move_out_date
)
select
    case
        when benefit_count <= 2 then '1-2 benefits'
        when benefit_count <= 3 then '3 benefits'
        when benefit_count <= 4 then '4 benefits'
        else '5 benefits'
    end as benefit_tier,
    count(*) as total_residents,
    sum(case when move_out_date is not null then 1 else 0 end) as churned,
    round(
        sum(case when move_out_date is not null then 1 else 0 end) / count(*) * 100,
        1
    ) as churn_rate_pct
from resident_benefit_counts
group by benefit_tier
order by benefit_tier;


-- 5) Churn by Active vs. Enrolled Benefits
-- This separates “signed up” from “actually using the benefits.”
with resident_activation_status as (
    select
        r.resident_id,
        r.move_out_date,
        count(e.enrollment_id) as enrolled_benefits,
        sum(case when e.activation_date is not null then 1 else 0 end) as activated_benefits
    from `greenfield-rbp-analysis.greenfield.residents` r
    left join `greenfield-rbp-analysis.greenfield.benefit_enrollments` e on r.resident_id = e.resident_id
    group by r.resident_id, r.move_out_date
),
activation_ratio as (
    select
        *,
        case
            when enrolled_benefits = 0 then 'No Benefits'
            when activated_benefits = 0 then 'Enrolled Only (0% activated)'
            when activated_benefits < enrolled_benefits then 'Partial Activation'
            else 'Full Activation'
        end as activation_status
    from resident_activation_status
)
select
    activation_status,
    count(*) as total_residents,
    sum(case when move_out_date is not null then 1 else 0 end) as churned,
    round(
        sum(case when move_out_date is not null then 1 else 0 end) / count(*) * 100,
        1
    ) as churn_rate_pct
from activation_ratio
group by activation_status
order by churn_rate_pct;


-- 6) Alexandria Deep Dive
-- Since Alexandria shows higher churn, break it down a few different ways.

-- Churn by property within Alexandria
select
    p.property_id,
    p.property_name,
    p.property_manager_name,
    count(r.resident_id) as total_residents,
    round(
        sum(case when r.move_out_date is not null then 1 else 0 end) / count(*) * 100,
        1
    ) as churn_rate_pct,
    round(avg(r.rent_amount), 0) as avg_rent
from `greenfield-rbp-analysis.greenfield.residents` r
join `greenfield-rbp-analysis.greenfield.properties` p on r.property_id = p.property_id
where p.city = 'Alexandria'
group by p.property_id, p.property_name, p.property_manager_name
order by churn_rate_pct desc;


-- Is it a rent issue? Compare rent levels for churned vs. retained in Alexandria
select
    case when r.move_out_date is not null then 'Churned' else 'Retained' end as status,
    round(avg(r.rent_amount), 0) as avg_rent,
    min(r.rent_amount) as min_rent,
    max(r.rent_amount) as max_rent
from `greenfield-rbp-analysis.greenfield.residents` r
join `greenfield-rbp-analysis.greenfield.properties` p on r.property_id = p.property_id
where p.city = 'Alexandria'
group by status;


-- Is it a property manager issue?
select
    p.property_manager_name,
    count(distinct p.property_id) as properties_managed,
    count(r.resident_id) as total_residents,
    round(
        sum(case when r.move_out_date is not null then 1 else 0 end) / count(*) * 100,
        1
    ) as churn_rate_pct
from `greenfield-rbp-analysis.greenfield.residents` r
join `greenfield-rbp-analysis.greenfield.properties` p on r.property_id = p.property_id
group by p.property_manager_name
order by churn_rate_pct desc;


-- 7) Seasonal Churn Patterns
-- Quick check: do move-outs cluster in certain months?
select
    extract(month from move_out_date) as move_out_month,
    format_date('%B', move_out_date) as month_name,
    count(*) as move_outs
from `greenfield-rbp-analysis.greenfield.residents`
where move_out_date is not null
group by move_out_month, month_name
order by move_out_month;
