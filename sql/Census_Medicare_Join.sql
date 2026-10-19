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