-- Selecting the users
WITH transaction_summary AS (
    SELECT DISTINCT
        user_id, 
        SUM(CASE WHEN transaction_type = 'deposit' THEN 1 ELSE 0 END) AS deposited,
        SUM(CASE WHEN transaction_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal
    FROM 
        NEW_SCHEMA.FINANCE.TRANSACTIONS
    WHERE 
        transaction_type IN ('deposit', 'withdrawal')
        AND status = 'finished'
        AND domain = 'bitpanda'
        AND user_type = 'normal'
        AND asset_type = 'cryptocoin'
        AND transaction_group = 'Normal'
    GROUP BY ALL
)

SELECT DISTINCT
    user_id,
    CASE WHEN deposited >= 1 THEN 'Yes' ELSE 'No' END AS deposited,
    CASE WHEN withdrawal >= 1 THEN 'Yes' ELSE 'No' END AS withdrawal
FROM 
    transaction_summary;
