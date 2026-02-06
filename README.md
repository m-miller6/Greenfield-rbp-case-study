# Greenfield Properties RBP Analytics

A portfolio project demonstrating Business Intelligence skills in a PropTech context. 

## The Scenario

Greenfield Properties is a fictional property management company operating 35 apartment communities in the Washington DC metro area (Arlington, Alexandria, and DC). They've implemented a Resident Benefits Package (RBP), offering services like renters insurance, credit building, air filter delivery, pest control, and a rewards program.

Leadership wants to understand: How is the RBP performing? Where are we losing residents? What can we do about it?

## What's in This Repo

```
├── data/
│   ├── properties.csv          # 35 properties
│   ├── residents.csv           # 6,500 resident records
│   ├── benefit_enrollments.csv # 22,672 enrollment records
│   └── data_dictionary.md      # Field definitions and notes
├── sql/
│   ├── data_validation.sql     # Data quality checks
│   ├── core_metrics.sql        # KPIs: Active Units, CARR, activation rates
│   ├── cohort_analysis.sql     # Monthly retention cohorts
│   └── churn_investigation.sql # Churn drivers analysis
├── analysis/
│   └── findings.md             # Written analysis with recommendations
└── results/
    ├── bigquery_active_units.png          # Query result: 4,863 active residents
    ├── bigquery_carr.png                  # Query result: $974,676 annual revenue
    ├── bigquery_activation_rate.png       # Query result: 74.1% activation rate
    ├── bigquery_churn_by_city.png         # Query result: Churn rates by market
    ├── bigquery_activation_by_benefit.png # Query result: Activation by benefit type
    ├── bigquery_early_late_churn.png      # Query result: Early vs late activator churn
    ├── dashboard_executive_overview.png   # Dashboard page 1 screenshot
    ├── dashboard_retention_deep_dive.png  # Dashboard page 2 screenshot
    └── dashboard_link.md                  # Live Looker Studio dashboard URL
```

## Key Findings

- **Alexandria churn issue:** The Alexandria market shows 27.7% churn vs. 23.8% in Arlington and DC, a 16% relative increase that's consistent across all 12 Alexandria properties.
- **Early activation matters:** Residents who activate at least one benefit within 7 days of enrollment have ~34% lower churn rates than late activators.
- **Data quality flag:** One property (P017) has 38% of enrollments missing activation dates, suggesting a process or integration issue.

## Decisions & Tradeoffs

**Cohort analysis over individual modeling:** I used monthly cohorts for retention analysis rather than individual-level survival curves. Cohorts are easier to explain to a property management audience and more directly actionable for operations planning. The tradeoff is less precision for any single resident.

**Simulated data with embedded patterns:** The data is synthetic but designed to contain realistic, discoverable insights. Real analysis would involve messier data and more ambiguous findings, but for a portfolio piece, I wanted to show the full analytical workflow from validation through recommendation.

**BigQuery SQL syntax:** I wrote queries in BigQuery Standard SQL because it's commonly used in growth-stage companies and has good documentation. The queries should be portable to other SQL dialects with minor adjustments.

## What I'd Do Next

1. **Exit survey analysis:** The Alexandria churn insight raises questions that data alone can't answer. I'd want to look at qualitative data—exit surveys, NPS comments, or even a few phone calls to recent move-outs—to understand whether this is a competitive issue, a service issue, or something else.

2. **Activation funnel:** The early activation correlation is strong, but I'd want to map out exactly where residents drop off in the activation flow. Is it at email open? First click? Account creation? Knowing this would help target the intervention.

---

## Author

**Michael Miller**
[LinkedIn](https://www.linkedin.com/in/michael-e-miller1/)

