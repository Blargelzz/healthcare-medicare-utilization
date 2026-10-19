COPY (
    SELECT *
    FROM read_csv_auto('/home/ethan/Documents/Medicare Part D Prescribers - by Provider and Drug/Medicare Part D Prescribers - by Provider and Drug/2024/MUP_DPR_RY26_P04_V10_DY24_NPIBN.csv')
) TO '/home/ethan/Documents/medicare_by_provider_2024.parquet' (FORMAT PARQUET);