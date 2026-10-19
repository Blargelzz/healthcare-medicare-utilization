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
	
	
	
	
	
	
	
	
	
	
	
	
	
		
		
		
		