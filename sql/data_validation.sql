-- Data validation checks for Greenfield Properties RBP greenfield
-- Run this file first to sanity-check required fields, joins, and date logic.
-- Each query returns counts you can scan for anomalies.

-- 1) Check for NULL values in required fields

-- Properties: all fields should be populated
select
    'properties' as table_name,
    sum(case when property_id is null then 1 else 0 end) as null_property_id,
    sum(case when property_name is null then 1 else 0 end) as null_property_name,
    sum(case when city is null then 1 else 0 end) as null_city,
    sum(case when unit_count is null then 1 else 0 end) as null_unit_count,
    sum(case when onboarding_date is null then 1 else 0 end) as null_onboarding_date,
    sum(case when property_manager_name is null then 1 else 0 end) as null_property_manager
from `greenfield-rbp-analysis.greenfield.properties`;

-- Residents: required fields check
select
    'residents' as table_name,
    sum(case when resident_id is null then 1 else 0 end) as null_resident_id,
    sum(case when property_id is null then 1 else 0 end) as null_property_id,
    sum(case when lease_start_date is null then 1 else 0 end) as null_lease_start_date,
    sum(case when lease_end_date is null then 1 else 0 end) as null_lease_end_date,
    sum(case when rent_amount is null then 1 else 0 end) as null_rent_amount
from `greenfield-rbp-analysis.greenfield.residents`;

-- Enrollments: required fields check
select
    'benefit_enrollments' as table_name,
    sum(case when enrollment_id is null then 1 else 0 end) as null_enrollment_id,
    sum(case when resident_id is null then 1 else 0 end) as null_resident_id,
    sum(case when benefit_type is null then 1 else 0 end) as null_benefit_type,
    sum(case when enrollment_date is null then 1 else 0 end) as null_enrollment_date,
    sum(case when monthly_fee is null then 1 else 0 end) as null_monthly_fee
from `greenfield-rbp-analysis.greenfield.benefit_enrollments`;

-- 2) Check for duplicate primary keys

-- Properties: property_id should be unique
select
    property_id,
    count(*) as row_count
from `greenfield-rbp-analysis.greenfield.properties`
group by property_id
having count(*) > 1;

-- Residents: resident_id should be unique
select
    resident_id,
    count(*) as row_count
from `greenfield-rbp-analysis.greenfield.residents`
group by resident_id
having count(*) > 1;

-- Enrollments: enrollment_id should be unique
select
    enrollment_id,
    count(*) as row_count
from `greenfield-rbp-analysis.greenfield.benefit_enrollments`
group by enrollment_id
having count(*) > 1;

-- 3) Check referential integrity (foreign keys)

-- Residents.property_id should exist in properties
select
    r.property_id,
    count(*) as residents_missing_property
from `greenfield-rbp-analysis.greenfield.residents` r
left join `greenfield-rbp-analysis.greenfield.properties` p
    on r.property_id = p.property_id
where p.property_id is null
group by r.property_id
order by residents_missing_property desc;

-- Enrollments.resident_id should exist in residents
select
    e.resident_id,
    count(*) as enrollments_missing_resident
from `greenfield-rbp-analysis.greenfield.benefit_enrollments` e
left join `greenfield-rbp-analysis.greenfield.residents` r
    on e.resident_id = r.resident_id
where r.resident_id is null
group by e.resident_id
order by enrollments_missing_resident desc;

-- 4) Date logic sanity checks

-- Residents: lease_end_date should be after lease_start_date
select
    count(*) as invalid_lease_date_rows
from `greenfield-rbp-analysis.greenfield.residents`
where lease_end_date < lease_start_date;

-- Residents: move_out_date (if present) should be on/after lease_start_date
select
    count(*) as invalid_move_out_rows
from `greenfield-rbp-analysis.greenfield.residents`
where move_out_date is not null
  and move_out_date < lease_start_date;

-- Enrollments: activation_date should be on/after enrollment_date (when present)
select
    count(*) as invalid_activation_rows
from `greenfield-rbp-analysis.greenfield.benefit_enrollments`
where activation_date is not null
  and activation_date < enrollment_date;

-- Enrollments: cancellation_date should be on/after activation_date (when present)
select
    count(*) as invalid_cancellation_rows
from `greenfield-rbp-analysis.greenfield.benefit_enrollments`
where cancellation_date is not null
  and activation_date is not null
  and cancellation_date < activation_date;

-- 5) Quick outlier checks (helps catch obvious bad loads)

-- Rent should be positive and within a reasonable range
select
    count(*) as suspicious_rent_rows
from `greenfield-rbp-analysis.greenfield.residents`
where rent_amount <= 0
   or rent_amount > 10000;

-- Monthly fee should be non-negative and within a reasonable range
select
    count(*) as suspicious_fee_rows
from `greenfield-rbp-analysis.greenfield.benefit_enrollments`
where monthly_fee < 0
   or monthly_fee > 1000;

-- Activation missing rate by property (useful for spotting operational/data issues)
select
    r.property_id,
    p.property_name,
    count(*) as total_enrollments,
    sum(case when e.activation_date is null then 1 else 0 end) as null_activations,
    round(
        safe_divide(
            sum(case when e.activation_date is null then 1 else 0 end),
            count(*)
        ),
        4
    ) as null_activation_rate
from `greenfield-rbp-analysis.greenfield.benefit_enrollments` e
join `greenfield-rbp-analysis.greenfield.residents` r
    on e.resident_id = r.resident_id
join `greenfield-rbp-analysis.greenfield.properties` p
    on r.property_id = p.property_id
group by r.property_id, p.property_name
order by null_activation_rate desc;
