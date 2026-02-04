# Data Dictionary

This document describes the structure and contents of the Greenfield Properties RBP analytics dataset.

## Tables Overview

| Table | Description | Row Count |
|-------|-------------|-----------|
| properties | Property information for Greenfield's portfolio | 35 |
| residents | Resident lease records | 6,500 |
| benefit_enrollments | RBP benefit enrollment records | 22,672 |

---

## properties.csv

Property-level information for Greenfield Properties' portfolio in the DC metro area.

| Field | Data Type | Description | Example |
|-------|-----------|-------------|---------|
| property_id | STRING | Unique property identifier | P001 |
| property_name | STRING | Name of the apartment community | The Meridian at Clarendon |
| city | STRING | City where property is located | Arlington |
| state | STRING | State (VA or DC) | VA |
| unit_count | INTEGER | Total number of units at property | 185 |
| onboarding_date | DATE | Date property joined the RBP program | 2022-06-15 |
| property_manager_name | STRING | Name of assigned property manager | Sarah Chen |

**Notes:**
- Properties span three markets: Arlington VA, Alexandria VA, and Washington DC
- Unit counts range from 58 to 278 units
- 8 property managers oversee the portfolio, each managing 4-5 properties
- Onboarding dates range from June 2022 to September 2023

---

## residents.csv

Individual resident lease records. Each row represents one lease term for a resident.

| Field | Data Type | Description | Example |
|-------|-----------|-------------|---------|
| resident_id | STRING | Unique resident identifier | R00001 |
| property_id | STRING | Foreign key to properties table | P001 |
| lease_start_date | DATE | Start date of lease term | 2022-10-08 |
| lease_end_date | DATE | End date of lease term | 2023-10-03 |
| move_out_date | DATE | Actual move-out date (NULL if still active) | 2023-08-15 |
| rent_amount | INTEGER | Monthly rent in USD | 2450 |

**Notes:**
- Lease terms are either 6 months (~15%) or 12 months (~85%)
- Move-out dates may differ from lease end dates (early termination, month-to-month, etc.)
- NULL move_out_date indicates currently active resident
- Rent amounts vary by market: DC tends higher, outer Arlington lower
- This dataset does not track lease renewals as separate records

**Known Issues:**
- Some lease_end_date values extend beyond the current analysis period

---

## benefit_enrollments.csv

Records of resident enrollments in Resident Benefits Package services.

| Field | Data Type | Description | Example |
|-------|-----------|-------------|---------|
| enrollment_id | STRING | Unique enrollment identifier | E00001 |
| resident_id | STRING | Foreign key to residents table | R00001 |
| benefit_type | STRING | Type of benefit enrolled | renters_insurance |
| enrollment_date | DATE | Date resident enrolled in benefit | 2022-11-03 |
| activation_date | DATE | Date benefit was activated (NULL if not activated) | 2022-11-05 |
| cancellation_date | DATE | Date benefit was cancelled (NULL if active) | |
| monthly_fee | INTEGER | Monthly fee charged for benefit in USD | 12 |

**Benefit Types:**

| Benefit | Monthly Fee | Description |
|---------|-------------|-------------|
| renters_insurance | $15 | Liability and personal property coverage |
| credit_building | $5 | Rent payment reporting to credit bureaus |
| air_filter | $12 | HVAC filter delivery service |
| pest_control | $8 | Preventive pest control treatment |
| rewards_program | $0 | Resident rewards and perks (included free) |

**Notes:**
- Residents typically enroll in 2-5 benefits
- Enrollment usually occurs within 30 days of lease start
- Activation requires resident action (confirming details, setting up account, etc.)
- NULL activation_date means the resident enrolled but never completed activation
- NULL cancellation_date means the enrollment is still active

**Known Issues:**
- Property P017 (Landmark Center Residences) has an unusually high rate of NULL activation dates, suggesting a data quality or process issue at that property
- Some activation dates may be missing due to legacy system migration

---

## Relationships

```
properties (1) ──────< (many) residents
                            │
                            │
residents (1) ──────< (many) benefit_enrollments
```

- Each property has many residents
- Each resident has many benefit enrollments
- Foreign keys: residents.property_id → properties.property_id
- Foreign keys: benefit_enrollments.resident_id → residents.resident_id

---

## Data Freshness

- Data current as of: November 2024
- Properties data: Complete
- Residents data: Includes leases starting through October 2024
- Enrollments data: Includes enrollments through November 2024
