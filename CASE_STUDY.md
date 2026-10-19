#Medicare Part D Spending Case Study

##Finding the Data and Making It Efficient

    I started by obtaining the 2024 Medicare Part D Prescribers - by Provider and Drug CSV file from Data.CMS.gov located [here](https://data.cms.gov/provider-summary-by-type-of-service/medicare-part-d-prescribers/medicare-part-d-prescribers-by-provider-and-drug). This is a 4.1gb CSV with 28,023,892 rows and would far exceed the roughly million row limit of software such as Excel or Calc. It would also create a huge memory footprint in Python using pandas, requiring 2 to 3 times the file size in system RAM, straining everyday computers. The data contained within this CSV consists of 22 columns such as provider NPI's, drug names, claim totals, and total drug cost. With the sheer number of rows contained within this CSV to aggregate and gather insights from it, the best option to approach this is using SQL. The goal was to find the totals for each state when it came to drug costs, total claims, and total providers. Since we are only looking for information from a small subset of the columns contained in the CSV, it became clear that formatting the csv to a Parquet format would be efficient. This way, when aggregating, it would not force the CPU to work through every row and would focus on the columns that are being targeted, allowing faster query completion. To do this, we ran an SQL query to COPY the CSV and create a new Apache Parquet file using the following query.

```sql
COPY (
    SELECT *
    FROM read_csv_auto('/home/ethan/Documents/Medicare Part D Prescribers - by Provider and Drug/Medicare Part D Prescribers - by Provider and Drug/2024/MUP_DPR_RY26_P04_V10_DY24_NPIBN.csv')
) TO '/home/ethan/Documents/medicare_by_provider_2024.parquet' (FORMAT PARQUET);
```

##Getting the Data We Want

    Now, with our efficient Parquet file, the goal was to obtain a new CSV containing the data that we want to gain insight into with Medicare spending. To begin, the column for prescriber state is selected, then the total count of distinct prescriber NPIs is selected to get an idea of total doctors per state. Then the sum of total claims is selected per state, as well as the sum of total drug costs rounded to two decimal places, as we are dealing with currency. Also, to obtain an average drug cost per claim value, the sum of total drug cost is divided by the sum of total claims. The use of NULLIF ensures that there is no chance for any zero-division exception handling creating an error in the query. The parquet file is taken in the FROM statement, and a WHERE statement is used to make sure that we are only dealing with the 51 states, as abbreviations for the military and Puerto Rico are present, as well as unknowns such as XX and ZZ. Finally, the query Groups by state, as that is our only column that was not aggregated, and we order it by state ascending to put them in alphabetical order. This query is wrapped in a COPY command in order to create a CSV of the data in order to continue down the pipeline for data visualization and insights. Below is the full SQL query used to create this CSV.

```sql
COPY (
 SELECT
  Prscrbr_State_Abrvtn AS state,
  COUNT(DISTINCT Prscrbr_NPI) AS total_doctors,
  SUM(Tot_Clms) AS total_claims,
  ROUND(SUM(Tot_Drug_Cst), 2) AS total_drug_cost,
  ROUND(SUM(Tot_Drug_Cst) / NULLIF(SUM(Tot_Clms), 0), 2) AS average_drug_cost
 FROM read_parquet('/home/ethan/Documents/medicare_part_d_2024.parquet')
 WHERE Prscrbr_State_Abrvtn NOT IN ('AA', 'AE', 'AP', 'FM', 'GU', 'MP', 'PR', 'VI', 'XX', 'ZZ')
 GROUP BY state
 ORDER BY state ASC
) TO '/home/ethan/Documents/medicare_state_totals.csv'(HEADER, DELIMITER ',');
```

##Bringing in Census Data to Create Real Insights

    When we look at this data and try to get insight, we see who the big spenders are, and immediately California and Texas pop out at you as the big spenders. Though we ask ourselves, are they really? Is this truly the insight we are trying to gain when we ask who is creating the most spending? We are missing a key piece to the puzzle here that makes understanding who is actually spending more out of reach, and that piece is population. California is big and has a large population; therefore, there is a great deal spent, but with a huge population, of course, the price will add up. We really don't see which state has its population spending heavily on Medicare without the crucial population data. This CSV is not enough, and we need the population data, so we obtained it from the United States Census Bureau, where a small xlsx for Annual Estimates of the Resident Population for the United States from 2020 to 2025 is located [here](https://www.census.gov/data/datasets/time-series/demo/popest/2020s-state-total.html). In this xlsx, we have the 2024 population numbers for all the states in the medicare CSV we created, but there is a big issue here. We have to first make it into a CSV so that we can use it in SQL, and while this is a nice-looking xlsx file, it is a mess when you convert it to CSV. The title of the sheet itself is placed in the first two rows, and there is a column header for Geographic Area that takes two rows, yet the years take up row 4, with row 3 above them giving the name population estimates. There are also rows for total United States and regions like Northeast and Midwest.

    When looking at this in SQL, we see many NULL cells present, and it is clear that we are going to have to clean this. Another issue we have to address is that our CSV created from the large Medicare CSV uses abbreviated state names, while this Census CSV uses non-abbreviated state names, making an INNER JOIN impossible. In the process of making the xlsx a CSV, there are also periods before every state name. To begin here, we start by making a new table called dim_clean_pop, which we will later INNER JOIN with our Medicare CSV. For the issues we have to clean, the use of common table expressions is useful so that we can join them together. Starting with raw_census, it begins by trimming the periods in column 0 where the state names are, as well as replacing the commas in the population totals to remove them. Using TRY_CAST to avoid any errors, we change the data type to BIGINT, as it was previously a string, allowing us to aggregate this data. We use header false and skip 9 to get rid of the title as well as the regions we do not need, as we are only dealing with individual states. After this, we make a new common table expression for a crosswalk where we create the abbreviations for each state and match them with the full names of the states. Then we select the columns made from our common table expressions and combine them to create a table containing the 2024 population along with the abbreviated and full state names. The SQL query used to accomplish this is presented below.

```sql
CREATE OR REPLACE TABLE dim_clean_pop AS
WITH raw_census AS (
 SELECT
  TRIM(REPLACE(column0, '.', '')) AS clean_state,
  TRY_CAST(REPLACE(column6, ',', '') AS BIGINT) AS clean_pop_2024
 FROM read_csv(
  '/home/ethan/Documents/state_pop.csv',
  header = false,
  skip = 9
 )
 WHERE column0 IS NOT NULL
  AND column0 NOT IN ('Northeast', 'Midwest', 'South', 'West')
  AND TRY_CAST(REPLACE(column6, ',', '') AS BIGINT) IS NOT NULL
),
crosswalk AS (
 SELECT * FROM (VALUES
  ('Alabama', 'AL'), ('Alaska', 'AK'), ('Arizona', 'AZ'), ('Arkansas', 'AR'),
  ('California', 'CA'), ('Colorado', 'CO'), ('Connecticut', 'CT'), ('Delaware', 'DE'),
  ('District of Columbia', 'DC'), ('Florida', 'FL'), ('Georgia', 'GA'), ('Hawaii', 'HI'),
  ('Idaho', 'ID'), ('Illinois', 'IL'), ('Indiana', 'IN'), ('Iowa', 'IA'),
  ('Kansas', 'KS'), ('Kentucky', 'KY'), ('Louisiana', 'LA'), ('Maine', 'ME'),
  ('Maryland', 'MD'), ('Massachusetts', 'MA'), ('Michigan', 'MI'), ('Minnesota', 'MN'),
  ('Mississippi', 'MS'), ('Missouri', 'MO'), ('Montana', 'MT'), ('Nebraska', 'NE'),
  ('Nevada', 'NV'), ('New Hampshire', 'NH'), ('New Jersey', 'NJ'), ('New Mexico', 'NM'),
  ('New York', 'NY'), ('North Carolina', 'NC'), ('North Dakota', 'ND'), ('Ohio', 'OH'),
  ('Oklahoma', 'OK'), ('Oregon', 'OR'), ('Pennsylvania', 'PA'), ('Rhode Island', 'RI'),
  ('South Carolina', 'SC'), ('South Dakota', 'SD'), ('Tennessee', 'TN'), ('Texas', 'TX'),
  ('Utah', 'UT'), ('Vermont', 'VT'), ('Virginia', 'VA'), ('Washington', 'WA'),
  ('West Virginia', 'WV'), ('Wisconsin', 'WI'), ('Wyoming', 'WY')
 ) AS t(full_name, state_abbr)
)
SELECT
 c.state_abbr,
 r.clean_state AS state_name,
 r.clean_pop_2024 AS population_2024
FROM raw_census r
INNER JOIN crosswalk c
 ON LOWER(r.clean_state) = LOWER(c.full_name)
ORDER BY r.clean_pop_2024 DESC;
```

##Joining our Data

    Now that we have a table in DuckDB for our state populations and a CSV with our total spending per state, we can create our new CSV joining the two together. Selecting from our dim_clean_pop table and our medicare_state_totals CSV, we bring in the states, population, total doctor and claims, as well as drug cost. We bring over the average drug cost, then begin aggregating for spending and claims per capita. We do this by dividing the total drug cost and the total claims by the population, making sure to utilize NULLIF to prevent any division by zero errors. Now that we have the same state names, we can inner join the table and the CSV on the state columns and wrap it in a COPY command to create the CSV. The SQL query created for this is presented below.

```sql
COPY (
 SELECT
  m.state AS state_abbr,
  p.state_name,
  p.population_2024,
  m.total_doctors,
  m.total_claims,
  m.total_drug_cost,
  m.average_drug_cost,
  ROUND(m.total_drug_cost / NULLIF(p.population_2024, 0), 2) AS spend_per_capita,
  ROUND(CAST(m.total_claims AS DOUBLE) / NULLIF(p.population_2024, 0), 2) AS claims_per_capita
 FROM read_csv_auto('/home/ethan/Documents/medicare_state_totals.csv') m
 INNER JOIN dim_clean_pop p
  ON m.state = p.state_abbr
 ORDER BY spend_per_capita DESC
) TO '/home/ethan/Documents/medicare_per_capita_final.csv' (HEADER, DELIMITER ',');
```

##Gaining Clear Insights

    Now that we have our completed CSV, we can bring this into Calc or Excel to create a readable spreadsheet or bring it into Tableau to create a data visualization dashboard. When looking at this data, we begin to see that California, while having the highest spending total, sits below average when it comes to amount spent per resident. We begin to see higher spending per resident in the eastern United States, with the highest spending per resident present in New York, Connecticut, Kentucky, and Pennsylvania.
