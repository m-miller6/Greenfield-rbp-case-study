# Dashboard Specification: Greenfield Properties RBP Performance

**Tool:** Google Looker Studio (free tier)
**Data Source:** CSV files uploaded to Looker Studio
**Refresh:** Manual (for this portfolio project)

---

## Page 1: Executive Overview

### Layout

```
+------------------+------------------+------------------+
|   Active Units   |       CARR       |  Activation Rate |
|    (Scorecard)   |   (Scorecard)    |   (Scorecard)    |
+------------------+------------------+------------------+
|                                                        |
|          Monthly Enrollments (Line Chart)              |
|                                                        |
+--------------------------------------------------------+
|                                                        |
|      Activation Rate by Benefit Type (Bar Chart)       |
|                                                        |
+------------------------+-------------------------------+
|     Filter: Date       |       Filter: City            |
+------------------------+-------------------------------+
```

### Component Details

#### Scorecard: Active Units
- **Metric:** Count of residents where `move_out_date` is NULL
- **Format:** Whole number with thousands separator
- **Comparison:** None (single value)
- **Label:** "Active Units"

#### Scorecard: CARR
- **Metric:** Sum of `monthly_fee` for active enrollments × 12
- **Active enrollment:** `activation_date` is not NULL AND `cancellation_date` is NULL AND resident's `move_out_date` is NULL
- **Format:** Currency (USD), no decimals
- **Label:** "Committed Annual Recurring Revenue"

#### Scorecard: Activation Rate
- **Metric:** (Enrollments with `activation_date` not NULL) / (Total enrollments) × 100
- **Format:** Percentage, 1 decimal place
- **Label:** "Overall Activation Rate"
- **Note:** Exclude property P017 from this calculation

#### Line Chart: Monthly Enrollments
- **Dimension:** `enrollment_date` (aggregated to month)
- **Metric:** Count of enrollment_id
- **X-axis:** Month-Year (e.g., "Jul 2022")
- **Y-axis:** Number of enrollments
- **Format:** Single line, data points visible
- **Interactions:** Responds to date and city filters

#### Bar Chart: Activation Rate by Benefit Type
- **Dimension:** `benefit_type`
- **Metric:** (Enrollments with activation_date) / (Total enrollments) × 100
- **Orientation:** Horizontal bars
- **Sort:** Descending by activation rate
- **Data labels:** Show percentage on bars
- **Expected order:** credit_building (highest) → pest_control (lowest)

#### Filters
- **Date Range:** Date picker for `lease_start_date` or `enrollment_date`
- **City:** Dropdown with options: All, Arlington, Alexandria, Washington

---

## Page 2: Retention Deep Dive

### Layout

```
+--------------------------------------------------------+
|                                                        |
|         Cohort Retention Heatmap (Table/Heatmap)       |
|                                                        |
+--------------------------------------------------------+
|                           |                            |
|   Churn Rate by City      |   Properties by Churn Rate |
|     (Bar Chart)           |        (Table)             |
|                           |                            |
+---------------------------+----------------------------+
|   Filter: Date    |   Filter: City   |  Filter: Prop  |
+-------------------+------------------+-----------------+
```

### Component Details

#### Heatmap: Cohort Retention
- **Rows:** Cohort month (lease_start_date aggregated to month)
- **Columns:** Months since lease start (1, 3, 6, 9, 12)
- **Values:** Retention percentage (residents still active / cohort size × 100)
- **Conditional formatting:**
  - Green (>80%): Strong retention
  - Yellow (60-80%): Moderate
  - Red (<60%): Needs attention
- **Note:** In Looker Studio, implement as a pivot table with background color rules

#### Bar Chart: Churn Rate by City
- **Dimension:** `city` (from properties table via join)
- **Metric:** (Residents with move_out_date) / (Total residents) × 100
- **Orientation:** Vertical bars
- **Sort:** Descending by churn rate
- **Data labels:** Show percentage
- **Highlight:** This chart should make the Alexandria issue immediately visible

#### Table: Properties Ranked by Churn Rate
- **Columns:**
  - Property Name
  - City
  - Total Residents
  - Churn Rate (%)
  - Property Manager
- **Sort:** Descending by churn rate (default)
- **Rows:** All properties (35 rows)
- **Pagination:** Show 10 per page
- **Conditional formatting:** Highlight churn rate >40% in red

#### Filters
- **Date Range:** Same as Page 1
- **City:** Dropdown with options: All, Arlington, Alexandria, Washington
- **Property:** Dropdown with all property names (optional cross-filter)

---

## Data Connections

### Connecting CSVs to Looker Studio

1. Open Looker Studio (datastudio.google.com)
2. Create > Data Source > File Upload
3. Upload each CSV file:
   - properties.csv
   - residents.csv
   - benefit_enrollments.csv
4. For each file, verify field types:
   - Date fields recognized as DATE
   - ID fields as TEXT
   - Numeric fields as NUMBER
5. Create blended data sources as needed for joins

### Required Joins

**Residents + Properties:**
- Join key: `property_id`
- Type: Left join (residents left, properties right)

**Enrollments + Residents:**
- Join key: `resident_id`
- Type: Left join (enrollments left, residents right)

### Calculated Fields to Create

```
// Active Resident Flag
CASE WHEN move_out_date IS NULL THEN 1 ELSE 0 END

// Activated Enrollment Flag
CASE WHEN activation_date IS NOT NULL THEN 1 ELSE 0 END

// Active Enrollment Flag
CASE
  WHEN activation_date IS NOT NULL
   AND cancellation_date IS NULL
  THEN 1
  ELSE 0
END

// MRR (for active enrollments)
CASE
  WHEN activation_date IS NOT NULL
   AND cancellation_date IS NULL
  THEN monthly_fee
  ELSE 0
END

// Churned Resident Flag
CASE WHEN move_out_date IS NOT NULL THEN 1 ELSE 0 END
```

---

## Design Guidelines

### Color Palette

| Use | Color | Hex |
|-----|-------|-----|
| Primary (metrics, highlights) | Teal | #0F9D9D |
| Secondary (comparisons) | Slate | #475569 |
| Accent (alerts, issues) | Coral | #F97066 |
| Background | White | #FFFFFF |
| Text | Dark gray | #1F2937 |

### Typography
- Use Looker Studio's default "Roboto" font
- Scorecards: 32pt for values, 12pt for labels
- Chart titles: 14pt bold
- Axis labels: 10pt

### General Notes
- Keep it simple—no unnecessary decorations
- Every chart should answer one clear question
- Include tooltips on interactive elements
- Add a "Data as of: [date]" footer on each page

---

## Build Notes for Looker Studio Free Tier

1. **Blended data has limits:** Free tier allows up to 5 data sources in a blend. The three tables in this project are within limits.

2. **No scheduled refresh:** CSV uploads require manual re-upload to refresh. Note this in the dashboard footer.

3. **Calculated field syntax:** Looker Studio uses its own formula syntax (similar to SQL but with some differences). Test calculated fields before building charts.

4. **Export options:** Free tier allows PDF export. PNG export of individual charts is also available.

5. **Sharing:** Use "View" link sharing rather than "Edit" to protect the dashboard structure.
