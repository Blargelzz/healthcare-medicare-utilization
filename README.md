# 2024 Medicare Part D Regional Spend & Utilization Pipeline

An end-to-end data engineering and analytics pipeline built to ingest 28M+ federal Medicare Part D prescriber records, normalize state spending against 2024 U.S. Census population benchmarks, and isolate regional cost drivers.

## Live Interactive Deliverables

* **Interactive Tableau Dashboard:** [Tableau Public Live View](https://public.tableau.com/views/medicarepercapita/Dashboard1?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)
* **In-Depth Engineering Breakdown:** [Read the Full Technical Case Study (CASE_STUDY.md)](CASE_STUDY.md)

## Architecture & Tech Stack

* **Database Engine:** DuckDB (Zero-copy in-memory columnar execution against 28M+ row local Parquet store)
* **SQL Transformations:** DBeaver (CTEs, Relational Inline Mapping via `VALUES`, Type Casting, `NULLIF` zero-division handling)
* **Spreadsheet Modeling:** LibreOffice Calc (Executive financial formatting, zebra-striped currency tables)
* **BI & Visual Analytics:** Tableau Public (Geographic heatmap, Price-vs-Volume quadrant matrix, scrollable state leaderboard)

## Core Analytical Findings

1. **Appalachian Utilization Volume:** Normalizing by population reveals that **Kentucky ($870.89/resident)** and **West Virginia ($847.00/resident)** dominate national spending due to extreme prescription volume intensity reaching **6.4 claims per resident** (nearly double California at 3.29).
2. **Washington D.C. Specialty Outlier:** Ranks in the national top 10 for per-capita spend ($800.52) despite having the low prescription volume  (2.74 claims/resident), driven by a national peak average prescription cost of **$291.73/claim**.
3. **Northeast Compounding Pressure:** **New York ($908.64)** and **Connecticut ($883.02)** lead overall national per-capita spending due to a combination of high claims frequency (~4.7 claims/resident) and elevated average claim costs (~$190/claim).

## Repository Structure
```text
healthcare-medicare-utilization/
├── README.md                           # Executive overview and dashboard links
├── CASE_STUDY.md                      # End-to-end technical engineering writeup
├── sql/
│   ├── Parquet_Creation.sql           # Raw CSV to compressed columnar Parquet conversion
│   ├── Medicare_By_State_CSV_Creation.sql # State-level aggregation and zero-division handling
│   ├── Census_Data_Cleaning.sql       # Census parsing, type-casting, and relational crosswalk
│   └── Census_Medicare_Join.sql       # Final per-capita dimensional join and export
└── reports/
    ├── medicare_per_capita_final.csv  # Clean normalized analytical dataset
    └── medicare_per_capita_final_fancy.ods # Executive financial spreadsheet model
```
