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