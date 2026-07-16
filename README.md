# Healthcare Diabetes Data Analytics Pipeline

An end-to-end data analytics and health-informatics project automating a clinical data pipeline to monitor and predict patient diabetes risk levels. This repository showcases how raw clinical records are ingested, preprocessed for consistency, managed within a relational database system, and transformed into an executive healthcare dashboard.

---

## 📊 Executive Insights & Clinical Metrics

The dashboard monitors patient cohorts and clinical efficiencies across various medical centers based on the processed dataset:

### 1. High-Level Patient KPIs
* **Total Patients Tracked:** 65 patients
* **Safe Zone Patients:** 20 patients
* **Stable Patient Percentage:** 30.77%
* **Critical Patient Percentage:** 4.62%

### 2. Hospital Performance & Risk Metrics
* **Top Performing Hospitals (Highest Stable Patient %):** **Global Hospitals** leads with **60.00%** stable patients, followed by **AIMS (50.00%)**, **Care Hospitals (50.00%)**, **Medanta (44.44%)**, and **Fortis Healthcare (33.33%)**.
* **Predictive Risk Index Audit:** Clinical logs flag **KIMS** with the highest average **Predictive Risk Index of 5.27**, followed closely by *Narayana Health* (5.00) and *Manipal Hospital* (4.75), indicating a higher density of high-risk diabetic cases at these locations.

### 3. Patient Future Risk Segmentation (Predictive Cohorts)
* **High Risk (Targeted Care Required):** Comprises the largest group with **24 patients (36.92%)**.
* **Safe Zone (Stable Outlook):** Includes **20 patients (30.77%)**.
* **Moderate Warning:** Encompasses **18 patients (27.69%)**.
* **Critical Priority (Immediate Intervention):** Identifies **3 patients (4.62%)** requiring urgent medical tracking.

### 4. Demographic & Age-Group Risk Trends
* **Volume by Region:** **Rajasthan** represents the largest patient distribution hub with **9 patients**, followed by *Odisha* and *Uttar Pradesh* with *6 patients* each.
* **Age vs. Risk Index Correlations:** Average predictive risk scores peak heavily in older age demographics, with the **61-70 age bracket** showing the highest vulnerability score of **5.70 (out of 10 patients)**, compared to the *10-20 youth cohort* which maintains a low risk baseline of *1.57 (out of 7 patients)*.
* **Age Progression Line:** Micro-tracking reveals risk spikes at specific age intervals, peaking at an average risk score of **7.50 around age 70**.

---

## 🛠️ Tech Stack & Analytical Ecosystem

* **Data Cleaning & Preprocessing:** Python (Pandas) utilized to handle missing values, standardize age brackets, and clean structural data inconsistencies.
* **Relational Database Server:** Microsoft SQL Server (SSMS) used for data warehouse ingestion, schema design, and analytical data validation.
* **Business Intelligence Tool:** Power BI Desktop for dimensional modeling, complex DAX measures calculation, and dashboard delivery.
* **Data Extraction (ETL):** Processing tabular clinical exports stored across Microsoft Excel workbooks and raw CSV files.
