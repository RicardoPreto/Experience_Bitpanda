WITH first_deposit AS (
    SELECT 
        transactions.user_id,
        MIN(transactions.transaction_date) AS first_deposit_date
    FROM 
        financial_data.payment_transactions transactions
    WHERE 
        transactions.payment_type = 'deposit'
        -- AND transactions.payment_method = 'sofort'
        AND transactions.transaction_status = 'finished'
        AND transactions.platform = 'bitpanda'
    GROUP BY 
        transactions.user_id
),
deposit_30days AS (
    SELECT DISTINCT
        transactions.user_id
    FROM 
        financial_data.payment_transactions transactions
    LEFT JOIN 
        first_deposit ON first_deposit.user_id = transactions.user_id
    WHERE 
        transactions.payment_type = 'deposit'
        -- AND transactions.payment_method = 'sofort'
        AND transactions.transaction_status = 'finished'
        AND transactions.platform = 'bitpanda'
        AND DATEADD(DAY, 30, first_deposit.first_deposit_date) <= transactions.transaction_date
),
assistance AS (
    SELECT DISTINCT
        transactions.user_id,
        TO_CHAR(transactions.transaction_date, 'YYYY-MM') AS transaction_month,
        transactions.user_country,
        SUM(transactions.payment_amount_euro) AS deposit_volume,
        COUNT(*) AS total_orders,
        CASE
            WHEN deposit_30days.user_id IS NOT NULL THEN 'Yes'
            ELSE 'No'
        END AS retention,
        MEDIAN(transactions.payment_amount_euro) AS median_deposit
    FROM 
        financial_data.payment_transactions transactions
    LEFT JOIN 
        deposit_30days ON deposit_30days.user_id = transactions.user_id
    WHERE 
        transactions.payment_type = 'deposit'
        -- AND transactions.payment_method = 'sofort'
        AND transactions.transaction_status = 'finished'
        AND transactions.platform = 'bitpanda'
        AND transactions.user_country IN ('Germany', 'Austria', 'Switzerland')
    GROUP BY 
        transactions.user_id, transaction_month, transactions.user_country, retention
)
SELECT 
    assistance.user_country,
    SUM(assistance.deposit_volume) / COUNT(DISTINCT assistance.user_id) AS avg_deposit_volume_user,
    AVG(assistance.total_orders) AS avg_frequency_monthly,
    (COUNT(DISTINCT CASE WHEN assistance.retention = 'Yes' THEN assistance.user_id ELSE NULL END) 
        / COUNT(DISTINCT assistance.user_id)) * 100 AS retention_rate,
    SUM(assistance.deposit_volume) / SUM(assistance.total_orders) AS avg_deposit_value,
    MEDIAN(assistance.deposit_volume) AS median_deposit_monthly,
    AVG(assistance.deposit_volume) AS avg_deposit_monthly,
    COUNT(DISTINCT assistance.user_id) AS total_users
FROM 
    assistance
GROUP BY 
    assistance.user_country;
