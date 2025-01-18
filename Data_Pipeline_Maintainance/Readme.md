# Ownership of Pipelines

| **Pipeline**                                | **Primary Owner** | **Secondary Owner** |
|---------------------------------------------|--------------------|----------------------|
| Unit-level profit (experiment-focused)      | Engineer A         | Engineer B           |
| Aggregate profit (investor reporting)       | Engineer B         | Engineer C           |
| Aggregate growth (investor reporting)       | Engineer C         | Engineer D           |
| Daily growth (experiment-focused)           | Engineer D         | Engineer A           |
| Aggregate engagement (investor reporting)   | Engineer A         | Engineer D           |

---

# On-Call Schedule

## Weekly Rotation
Each engineer is on call for one week, ensuring even distribution across a 4-week cycle.

- **Week 1**: Engineer A  
- **Week 2**: Engineer B  
- **Week 3**: Engineer C  
- **Week 4**: Engineer D  

## Holiday Policy
1. Use a shared calendar where engineers can block unavailable dates.
2. Secondary owner steps in when the primary is unavailable.
3. Allow engineers to swap on-call weeks if needed.

## Daily Onboarding Hand-Off
- Schedule a **20-30 minute meeting** at the end of the on-call period for the outgoing engineer to onboard the incoming engineer.
- Topics to discuss:
  - Active issues being resolved.
  - Known outages or delays.
  - Status of all pipelines.
  - Pending action items.

---

# Runbooks for Pipelines

## Runbook: Unit-Level Profit (Experiment-Focused)

### Purpose
This pipeline calculates profit at the unit level for running experiments and evaluating their success.

### Pipeline Components
- **Data Sources**: Transactional databases, experiment tracking logs.
- **Transformation Logic**: Aggregation by units and experiments, profit calculation.
- **Storage**: Intermediate data stored in a data warehouse.
- **Reporting Layer**: Accessible via dashboards for analysis.

### Failure Scenarios
1. Missing or delayed transactional data.
2. Incorrect experiment tagging or data mismatch.
3. Pipeline timeout or compute resource limitations.

### Troubleshooting Steps
1. Verify input data availability and integrity.
2. Check experiment tags in the source data.
3. Review pipeline logs for execution errors.

### Metrics Validation
- Validate profit values match expected ranges.
- Cross-check experiment results with historical data.

---

## Runbook: Aggregate Profit (Investor Reporting)

### Purpose
This pipeline calculates company-wide profit metrics for quarterly investor reporting.

### Pipeline Components
- **Data Sources**: Financial systems, ERP platforms.
- **Transformation Logic**: Profit aggregation across regions and categories.
- **Storage**: Finalized metrics stored in a secure reporting database.
- **Reporting Layer**: Investor-facing dashboards and presentations.

### Failure Scenarios
1. Schema changes in financial data sources.
2. Delays in data aggregation or pipeline execution.
3. Discrepancies in regional data aggregation.

### Troubleshooting Steps
1. Confirm source schema matches the pipeline’s ETL logic.
2. Review logs for delays or resource constraints.
3. Verify aggregated values against backup metrics.

### Metrics Validation
- Ensure consistency with quarterly projections.
- Compare output with historical data trends.

---

## Runbook: Aggregate Growth (Investor Reporting)

### Purpose
This pipeline measures aggregate growth metrics for reporting to investors.

### Pipeline Components
- **Data Sources**: User activity data, revenue data.
- **Transformation Logic**: Aggregation of growth metrics over time.
- **Storage**: Historical and real-time growth data in the data warehouse.
- **Reporting Layer**: Charts and graphs in investor reports.

### Failure Scenarios
1. Inconsistent growth metrics due to incomplete data.
2. Missing historical data for trend analysis.
3. Failures in periodic updates to the data warehouse.

### Troubleshooting Steps
1. Validate historical data completeness.
2. Check real-time update schedules and logs.
3. Ensure proper transformations are applied during aggregation.

### Metrics Validation
- Verify aggregate growth aligns with benchmarks.
- Check consistency with other business metrics.

---

## Runbook: Daily Growth (Experiment-Focused)

### Purpose
This pipeline calculates daily growth metrics to support ongoing experiments.

### Pipeline Components
- **Data Sources**: User activity logs, experiment tracking logs.
- **Transformation Logic**: Calculate daily growth rates by user segments.
- **Storage**: Temporary storage in the data lake for daily metrics.
- **Reporting Layer**: Experiment monitoring dashboards.

### Failure Scenarios
1. Delayed or missing activity logs.
2. Outliers or anomalies in daily metrics.
3. Unexpected spikes or dips causing false alarms.

### Troubleshooting Steps
1. Check upstream log systems for delays.
2. Review anomaly detection thresholds.
3. Rerun failed tasks in the pipeline.

### Metrics Validation
- Cross-check daily growth against historical patterns.
- Validate segment-level growth calculations.

---

## Runbook: Aggregate Engagement (Investor Reporting)

### Purpose
This pipeline computes company-wide engagement metrics for investors.

### Pipeline Components
- **Data Sources**: User activity logs, CRM systems.
- **Transformation Logic**: Aggregate metrics like daily active users (DAU) and monthly active users (MAU).
- **Storage**: Long-term storage in the reporting database.
- **Reporting Layer**: Engagement metrics dashboard for investor presentations.

### Failure Scenarios
1. Missing activity logs for key user cohorts.
2. Delays in CRM system data updates.
3. Inconsistencies in active user definitions.

### Troubleshooting Steps
1. Verify data availability and freshness.
2. Review logs for errors or delays.
3. Validate aggregation logic for DAU and MAU.

### Metrics Validation
- Check DAU/MAU ratios for expected patterns.
- Compare engagement trends with previous reporting periods.
