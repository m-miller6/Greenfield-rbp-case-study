# Greenfield Properties RBP Performance Analysis

## Executive Summary

Greenfield Properties' Resident Benefits Package shows solid overall adoption with ~3.5 benefits enrolled per resident and a 75% activation rate. However, the Alexandria market exhibits 17% higher churn than Arlington and DC (27.7% vs 23.6%), representing the largest retention opportunity in the portfolio. Additionally, residents who activate benefits within 7 days of enrollment show significantly better retention, pointing to a clear operational intervention.

---

## Key Findings

### 1. Alexandria Market Has Elevated Churn

Alexandria properties show a 27.7% churn rate compared to 23.6% for the rest of the portfolio—a 17.4% relative increase. This pattern is consistent across all 12 Alexandria properties, ruling out individual property issues.

| Market | Total Residents | Churn Rate |
|--------|-----------------|------------|
| Alexandria, VA | 2,315 | 27.7% |
| Arlington, VA | 2,522 | 24.5% |
| Washington, DC | 1,663 | 22.7% |

The elevated churn appears market-wide rather than tied to specific property managers, rent levels, or property characteristics. Further investigation into local competitive dynamics (new construction, pricing pressure, commute patterns) is warranted.

**Impact estimate:** Reducing Alexandria churn to portfolio average would retain 95 additional residents annually, representing approximately $20,000 in preserved CARR.

### 2. Early Benefit Activation Correlates with Retention

Residents who activate at least one benefit within 7 days of enrollment have approximately 34% lower churn than those who activate later.

| Activation Timing | Residents | Churn Rate |
|-------------------|-----------|------------|
| Early (0-7 days) | 5,194  | 22.7% |
| Late (8+ days) | 1,183 | 34.2% |

This is the strongest behavioral predictor of retention identified in the data. The first week after enrollment appears to be a critical window for resident engagement.

### 3. Data Quality Issue at Property P017

Property P017 (Landmark Center Residences) has a 38% null activation rate—significantly higher than the portfolio average of 26.3%. This affects roughly 300 resident enrollments.

The pattern suggests either:
- A process gap at the property (staff not completing activation steps)
- A system integration issue (activation data not syncing)
- Historical data migration problems

Recommend excluding P017 from activation benchmarks until resolved, and coordinating with the property team to identify root cause.

---

## Recommendations

### For the Alexandria Churn Issue

**Conduct market research** to understand local competitive factors. Specific questions to investigate:
- Are there new Class A properties pulling residents?
- How do Greenfield rents compare to alternatives within a 5-mile radius?
- Is there a common move-out destination (competitor, homeownership, relocation)?

Consider exit survey analysis or a brief outreach to recent Alexandria move-outs to gather qualitative data.

### For Early Activation

**Implement a first-week activation campaign:**
- Day 1: Welcome email with clear activation CTAs
- Day 3: SMS reminder for any unactivated benefits
- Day 5: Property manager follow-up call for residents with zero activations
- Day 7: Final nudge with deadline framing ("Complete setup this week")

This intervention is low-cost and directly addresses the retention correlation found in the data.

### For the P017 Data Issue

**Schedule a call with the Landmark Center property team** to walk through their enrollment process. Bring specific examples of enrollments missing activation dates. Determine whether this is a training issue, a system issue, or both.

---

## Methodology Notes

**Data scope:** 35 properties, 6,500 residents, 22,672 benefit enrollments spanning July 2022 through January 2025.

**Churn definition:** A resident is considered churned if `move_out_date` is not null. This captures both lease non-renewals and early terminations.

**Cohort approach:** Retention analysis uses lease start month as the cohort dimension. This approach was chosen over individual-level survival modeling because:
1. Monthly cohorts are easier to communicate to a PM audience
2. Sample sizes per cohort are sufficient for reliable percentages
3. Cohort trends are directly actionable for operations planning

**Exclusions:** Property P017 was excluded from activation rate calculations due to the identified data quality issue.

---

## Appendix: Data Quality Issues Identified

- **P017 activation gap:** 38% of enrollments at Landmark Center Residences have null activation dates vs. ~26% portfolio average
- **Future lease dates:** Some `lease_end_date` values extend beyond the analysis period, which is expected for active leases but should be monitored
- **Benefit cancellation timing:** A small number of cancellation dates fall on the same day as activation, which may indicate immediate regret or data entry errors
- **Rent amount outliers:** Rent values appear reasonable ($1,400-$3,200 range) with no obvious data entry errors detected
