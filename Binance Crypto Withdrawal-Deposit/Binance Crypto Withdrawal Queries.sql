-- Selecting users that made at least a deposit/withdrawal from/to Binance since 2024 in France and deposited less than twice in the last 2 months
SELECT
    crypto_data.user_id,
    SUM(
        CASE 
            WHEN crypto_data.transaction_type = 'deposit' 
            THEN crypto_data.transaction_amount_euro 
            ELSE 0 
        END
    ) AS total_deposits,
    SUM(
        CASE 
            WHEN crypto_data.transaction_type = 'withdrawal' 
            THEN crypto_data.transaction_amount_euro 
            ELSE 0 
        END
    ) AS total_withdrawals,
    SUM(
        CASE 
            WHEN crypto_data.transaction_type = 'deposit' 
                 AND crypto_data.transaction_date >= '2024-12-01' 
            THEN 1 
            ELSE 0 
        END
    ) AS deposit_count_last_2m
FROM 
    crypto_transactions_data crypto_data
LEFT JOIN 
    user_wallet_transactions wallet_data 
    ON crypto_data.transaction_id = wallet_data.wallet_tx_id
LEFT JOIN 
    blockchain_transfers blockchain_data 
    ON blockchain_data.tx_hash = wallet_data.transaction_ref
WHERE 
    crypto_data.transaction_status = 'finished'
    AND crypto_data.transaction_date >= '2024-01-01'
    AND blockchain_data.exchange_name = 'Binance.com'
    AND crypto_data.user_country = 'France'
GROUP BY 
    crypto_data.user_id
HAVING 
    deposit_count_last_2m < 2;
