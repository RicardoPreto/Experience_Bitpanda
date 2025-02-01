WITH initial_deposits AS (
    SELECT 
        DISTINCT transactions.user_id,
        COUNT(*) AS deposit_count
    FROM 
        financial_data.payment_transactions transactions
    WHERE 
        transactions.payment_type = 'deposit'
        AND transactions.status = 'finished'
        AND transactions.payment_method = 'paypal'
        AND transactions.transaction_date BETWEEN '2024-02-22' AND '2024-02-27'
    GROUP BY 
        transactions.user_id
) 
SELECT 
    initial_deposits.user_id,
    CASE
        WHEN second_deposit.user_id IS NOT NULL OR initial_deposits.deposit_count >= 2 THEN 'YES'
        ELSE 'NO'
    END AS deposited_30days,
    CASE
        WHEN third_deposit.user_id IS NOT NULL OR initial_deposits.deposit_count >= 2 THEN 'YES'
        ELSE 'NO'
    END AS deposited_90days,
    deposit_frequency_before.deposit_frequency AS frequency_30days_before,
    deposit_frequency_after.deposit_frequency AS frequency_30days_after
FROM 
    initial_deposits
LEFT JOIN (
    SELECT 
        DISTINCT transactions.user_id
    FROM 
        financial_data.payment_transactions transactions
    WHERE 
        transactions.payment_type = 'deposit'
        AND transactions.status = 'finished'
        AND transactions.transaction_date BETWEEN '2024-02-28' AND '2024-03-23'
        AND transactions.payment_method = 'paypal'
) second_deposit ON second_deposit.user_id = initial_deposits.user_id 
LEFT JOIN (
    SELECT 
        DISTINCT transactions.user_id
    FROM 
        financial_data.payment_transactions transactions
    WHERE 
        transactions.payment_type = 'deposit'
        AND transactions.status = 'finished'
        AND transactions.transaction_date BETWEEN '2024-02-28' AND '2024-05-20'
        AND transactions.payment_method = 'paypal'
) third_deposit ON third_deposit.user_id = initial_deposits.user_id 
LEFT JOIN (
    SELECT 
        DISTINCT transactions.user_id,
        COUNT(*) AS deposit_frequency
    FROM 
        financial_data.payment_transactions transactions
    WHERE 
        transactions.payment_type = 'deposit'
        AND transactions.status = 'finished'
        AND transactions.transaction_date BETWEEN '2024-01-24' AND '2024-02-21'
    GROUP BY 
        transactions.user_id
) deposit_frequency_before ON deposit_frequency_before.user_id = initial_deposits.user_id
LEFT JOIN (
    SELECT 
        DISTINCT transactions.user_id,
        COUNT(*) AS deposit_frequency
    FROM 
        financial_data.payment_transactions transactions
    WHERE 
        transactions.payment_type = 'deposit'
        AND transactions.status = 'finished'
        AND transactions.transaction_date BETWEEN '2024-02-22' AND '2024-03-21'
    GROUP BY 
        transactions.user_id
) deposit_frequency_after ON deposit_frequency_after.user_id = initial_deposits.user_id;
