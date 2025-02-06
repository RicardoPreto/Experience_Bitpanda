-- Select with loads of different informations to analyze the campaign
WITH deposit_after AS (
    SELECT 
        crypto_transactions.user_id,
        MIN(crypto_transactions.transaction_date) AS first_deposit,
        COALESCE(SUM(crypto_transactions.transaction_amount_euro), 0) AS total_deposits_after,
        COALESCE(SUM(CASE WHEN transfers.exchange_name = 'Bitvavo.com' 
                          THEN crypto_transactions.transaction_amount_euro END), 0) AS bitvavo_deposits_after,
        COALESCE(SUM(CASE WHEN transfers.transaction_category LIKE '%exchange%' 
                          AND transfers.exchange_name != 'Bitvavo.com' 
                          THEN crypto_transactions.transaction_amount_euro END), 0) AS other_exchange_deposits_after
    FROM 
        crypto_data.transaction_status crypto_transactions
    LEFT JOIN 
        user_wallet.transactions wallet_transactions 
        ON crypto_transactions.transaction_id = wallet_transactions.wallet_tx_id
    LEFT JOIN 
        blockchain_data.transfers transfers 
        ON transfers.transaction_hash = wallet_transactions.transaction_ref
    WHERE 
        crypto_transactions.transaction_status = 'finished' 
        AND crypto_transactions.transaction_type = 'deposit'
        AND crypto_transactions.transaction_date > '2024-05-09'
    GROUP BY 
        crypto_transactions.user_id
),
deposit AS (
    SELECT 
        crypto_transactions.user_id,
        MIN(DATEADD(DAY, 30, crypto_transactions.transaction_date)) AS first_deposit
    FROM 
        crypto_data.transaction_status crypto_transactions
    WHERE 
        crypto_transactions.transaction_status = 'finished' 
        AND crypto_transactions.transaction_type = 'deposit'
        AND crypto_transactions.transaction_date BETWEEN '2024-04-29' AND '2024-05-09'
    GROUP BY 
        crypto_transactions.user_id
),
withdraw_after AS (
    SELECT 
        crypto_transactions.user_id,
        COALESCE(SUM(crypto_transactions.transaction_amount_euro), 0) AS total_withdrawals_after,
        COALESCE(SUM(CASE WHEN transfers.exchange_name = 'Bitvavo.com' 
                          THEN crypto_transactions.transaction_amount_euro END), 0) AS bitvavo_withdrawals_after,
        COALESCE(SUM(CASE WHEN transfers.transaction_category LIKE '%exchange%' 
                          AND transfers.exchange_name != 'Bitvavo.com' 
                          THEN crypto_transactions.transaction_amount_euro END), 0) AS other_exchange_withdrawals_after
    FROM 
        crypto_data.transaction_status crypto_transactions
    LEFT JOIN 
        user_wallet.transactions wallet_transactions 
        ON crypto_transactions.transaction_id = wallet_transactions.wallet_tx_id
    LEFT JOIN 
        blockchain_data.transfers transfers 
        ON transfers.transaction_hash = wallet_transactions.transaction_ref
    LEFT JOIN 
        deposit ON deposit.user_id = crypto_transactions.user_id
    WHERE 
        crypto_transactions.transaction_status = 'finished' 
        AND crypto_transactions.transaction_type = 'withdrawal'
        AND crypto_transactions.transaction_date >= deposit.first_deposit
    GROUP BY 
        crypto_transactions.user_id
)

SELECT 
    campaign_data.user_id,
    campaign_data.cashback_earned,
    campaign_data.bitvavo_deposits,
    campaign_data.other_exchange_deposits,
    campaign_data.total_deposits - campaign_data.bitvavo_deposits - campaign_data.other_exchange_deposits AS other_deposits,
    withdraw_after.total_withdrawals_after,
    withdraw_after.bitvavo_withdrawals_after,
    withdraw_after.other_exchange_withdrawals_after,
    SUM(trade_fees.total_trade_fees) AS total_trade_fees,
    trade_1m.user_id AS trade_1m,
    trade_3m.user_id AS trade_3m,
    trade_6m.user_id AS trade_6m,
    trade_9m.user_id AS trade_9m,
    deposit_after.total_deposits_after AS deposit_total_after_comm,
    deposit_after.bitvavo_deposits_after AS deposit_bitvavo_after_comm,
    deposit_after.other_exchange_deposits_after AS deposit_other_exchange_after_comm
FROM 
    marketing_campaigns.bya_bitvavo campaign_data
LEFT JOIN 
    withdraw_after ON campaign_data.user_id = withdraw_after.user_id
LEFT JOIN (
    SELECT campaign_data.user_id, SUM(trade_fees.trade_fee_euro) AS total_trade_fees
    FROM 
        trading_data.trade_transactions trade_fees
    JOIN 
        marketing_campaigns.bya_bitvavo campaign_data 
        ON trade_fees.user_id = campaign_data.user_id
    WHERE 
        trade_fees.transaction_date >= '2024-04-30'
    GROUP BY 
        campaign_data.user_id
) trade_fees ON trade_fees.user_id = campaign_data.user_id
LEFT JOIN (
    SELECT DISTINCT campaign_data.user_id
    FROM 
        trading_data.trade_transactions trade_data
    JOIN 
        marketing_campaigns.bya_bitvavo campaign_data 
        ON trade_data.user_id = campaign_data.user_id
    WHERE 
        trade_data.transaction_date BETWEEN '2024-04-30' AND '2024-05-29'
) trade_1m ON trade_1m.user_id = campaign_data.user_id
LEFT JOIN (
    SELECT DISTINCT campaign_data.user_id
    FROM 
        trading_data.trade_transactions trade_data
    JOIN 
        marketing_campaigns.bya_bitvavo campaign_data 
        ON trade_data.user_id = campaign_data.user_id
    WHERE 
        trade_data.transaction_date BETWEEN '2024-05-30' AND '2024-07-27'
) trade_3m ON trade_3m.user_id = campaign_data.user_id
LEFT JOIN (
    SELECT DISTINCT campaign_data.user_id
    FROM 
        trading_data.trade_transactions trade_data
    JOIN 
        marketing_campaigns.bya_bitvavo campaign_data 
        ON trade_data.user_id = campaign_data.user_id
    WHERE 
        trade_data.transaction_date BETWEEN '2024-07-28' AND '2024-10-27'
) trade_6m ON trade_6m.user_id = campaign_data.user_id
LEFT JOIN (
    SELECT DISTINCT campaign_data.user_id
    FROM 
        trading_data.trade_transactions trade_data
    JOIN 
        marketing_campaigns.bya_bitvavo campaign_data 
        ON trade_data.user_id = campaign_data.user_id
    WHERE 
        trade_data.transaction_date BETWEEN '2024-10-28' AND '2025-01-27'
) trade_9m ON trade_9m.user_id = campaign_data.user_id
LEFT JOIN 
    deposit_after ON campaign_data.user_id = deposit_after.user_id
GROUP BY 
    campaign_data.user_id, 
    campaign_data.cashback_earned, 
    campaign_data.bitvavo_deposits, 
    campaign_data.other_exchange_deposits, 
    withdraw_after.total_withdrawals_after, 
    withdraw_after.bitvavo_withdrawals_after, 
    withdraw_after.other_exchange_withdrawals_after, 
    deposit_after.total_deposits_after, 
    deposit_after.bitvavo_deposits_after, 
    deposit_after.other_exchange_deposits_after;


-- If the user withdrew, to which competitors?
WITH first_deposit AS (
    SELECT 
        transactions.user_id,
        MIN(DATEADD(DAY, 30, transactions.transaction_date)) AS first_deposit_date
    FROM 
        crypto_data.transaction_status transactions
    WHERE 
        transactions.transaction_status = 'finished' 
        AND transactions.transaction_type = 'deposit'
        AND transactions.transaction_date BETWEEN '2024-04-29' AND '2024-05-09'
    GROUP BY 
        transactions.user_id
)
SELECT 
    campaign_data.user_id,
    transactions.transaction_date - first_deposit.first_deposit_date AS first_withdrawal,
    transfers.exchange_name,
    ROW_NUMBER() OVER (
        PARTITION BY campaign_data.user_id 
        ORDER BY transactions.transaction_date ASC
    ) AS num
FROM 
    marketing_campaigns.bya_bitvavo campaign_data
LEFT JOIN 
    crypto_data.transaction_status transactions 
    ON transactions.user_id = campaign_data.user_id
LEFT JOIN 
    user_wallet.transactions wallet_transactions 
    ON transactions.transaction_id = wallet_transactions.wallet_tx_id
LEFT JOIN 
    blockchain_data.transfers transfers 
    ON transfers.transaction_hash = wallet_transactions.transaction_ref
LEFT JOIN 
    first_deposit 
    ON first_deposit.user_id = transactions.user_id
WHERE 
    transactions.transaction_status = 'finished' 
    AND transactions.transaction_type = 'withdrawal'
    AND transactions.transaction_date > first_deposit.first_deposit_date
GROUP BY 
    campaign_data.user_id, 
    first_withdrawal, 
    transfers.exchange_name, 
    transactions.transaction_date
QUALIFY 
    num = 1;

-- Amount withdrew per competitor
WITH first_deposit AS (
    SELECT 
        transactions.user_id,
        MIN(DATEADD(DAY, 30, transactions.transaction_date)) AS first_deposit_date
    FROM 
        crypto_data.transaction_status transactions
    WHERE 
        transactions.transaction_status = 'finished' 
        AND transactions.transaction_type = 'deposit'
        AND transactions.transaction_date BETWEEN '2024-04-29' AND '2024-05-09'
    GROUP BY 
        transactions.user_id
)
SELECT 
    transfers.exchange_name,
    SUM(transactions.transaction_amount_euro) AS total_withdrawals
FROM 
    marketing_campaigns.bya_bitvavo campaign_data
LEFT JOIN 
    crypto_data.transaction_status transactions 
    ON transactions.user_id = campaign_data.user_id
LEFT JOIN 
    user_wallet.transactions wallet_transactions 
    ON transactions.transaction_id = wallet_transactions.wallet_tx_id
LEFT JOIN 
    blockchain_data.transfers transfers 
    ON transfers.transaction_hash = wallet_transactions.transaction_ref
LEFT JOIN 
    first_deposit 
    ON first_deposit.user_id = transactions.user_id
WHERE 
    transactions.transaction_status = 'finished' 
    AND transactions.transaction_type = 'withdrawal'
    AND transactions.transaction_date > first_deposit.first_deposit_date
GROUP BY 
    transfers.exchange_name
ORDER BY 
    total_withdrawals DESC;

-- When the user reached profit?
WITH first_deposit AS (
    SELECT 
        transactions.user_id,
        MIN(transactions.transaction_date) AS first_deposit_date
    FROM 
        crypto_data.transaction_status transactions
    WHERE 
        transactions.transaction_status = 'finished' 
        AND transactions.transaction_type = 'deposit'
        AND transactions.transaction_date BETWEEN '2024-04-29' AND '2024-05-09'
    GROUP BY 
        transactions.user_id
),
cumulative_fees AS (
    SELECT 
        campaign_data.user_id,
        trades.transaction_date,
        SUM(trades.trade_fee_euro) 
            OVER (PARTITION BY trades.user_id ORDER BY trades.transaction_date) 
            AS cumulative_trade_fee
    FROM 
        marketing_campaigns.bya_bitvavo campaign_data
    LEFT JOIN 
        trading_data.trade_transactions trades 
        ON trades.user_id = campaign_data.user_id
    LEFT JOIN 
        first_deposit 
        ON first_deposit.user_id = campaign_data.user_id
    WHERE 
        trades.transaction_date >= first_deposit.first_deposit_date
),
first_achieved AS (
    SELECT 
        cumulative_fees.user_id,
        cumulative_fees.transaction_date,
        cumulative_fees.cumulative_trade_fee,
        campaign_data.cashback_earned,
        ROW_NUMBER() OVER (
            PARTITION BY cumulative_fees.user_id ORDER BY cumulative_fees.transaction_date ASC
        ) AS row_num
    FROM 
        cumulative_fees
    LEFT JOIN 
        marketing_campaigns.bya_bitvavo campaign_data 
        ON cumulative_fees.user_id = campaign_data.user_id
    WHERE 
        cumulative_fees.cumulative_trade_fee >= campaign_data.cashback_earned
    QUALIFY 
        row_num = 1
)
SELECT
    first_achieved.user_id,
    CASE
        WHEN first_achieved.cashback_earned < trades.trade_fee_euro THEN 'Yes'
        ELSE 'No'
    END AS reached_profit,
    first_achieved.transaction_date - first_deposit.first_deposit_date + 1 AS reached_profit_days
FROM 
    first_achieved
LEFT JOIN 
    first_deposit ON first_deposit.user_id = first_achieved.user_id
LEFT JOIN (
    SELECT 
        campaign_data.user_id, 
        SUM(trades.trade_fee_euro) AS total_trade_fee
    FROM 
        trading_data.trade_transactions trades
    JOIN 
        marketing_campaigns.bya_bitvavo campaign_data 
        ON trades.user_id = campaign_data.user_id
    WHERE 
        trades.transaction_date >= '2024-04-30'
    GROUP BY 
        campaign_data.user_id
) trades ON trades.user_id = first_achieved.user_id
HAVING 
    reached_profit = 'Yes';


-- Scenario 01 (Cashback 2%) - reach profit
WITH first_deposit AS (
    SELECT 
        transactions.user_id,
        MIN(transactions.transaction_date) AS first_deposit_date
    FROM 
        crypto_data.transaction_status transactions
    WHERE 
        transactions.transaction_status = 'finished' 
        AND transactions.transaction_type = 'deposit'
        AND transactions.transaction_date BETWEEN '2024-04-29' AND '2024-05-09'
    GROUP BY 
        transactions.user_id
),
cumulative_fees AS (
    SELECT 
        campaign_data.user_id,
        trades.transaction_date,
        SUM(trades.trade_fee_euro) 
            OVER (PARTITION BY trades.user_id ORDER BY trades.transaction_date) 
            AS cumulative_trade_fee
    FROM 
        marketing_campaigns.bya_bitvavo campaign_data
    LEFT JOIN 
        trading_data.trade_transactions trades 
        ON trades.user_id = campaign_data.user_id
    LEFT JOIN 
        first_deposit 
        ON first_deposit.user_id = campaign_data.user_id
    WHERE 
        trades.transaction_date >= first_deposit.first_deposit_date
),
first_achieved AS (
    SELECT 
        cumulative_fees.user_id,
        cumulative_fees.transaction_date,
        cumulative_fees.cumulative_trade_fee,
        campaign_data.cashback_earned,
        ROW_NUMBER() OVER (
            PARTITION BY cumulative_fees.user_id ORDER BY cumulative_fees.transaction_date ASC
        ) AS row_num
    FROM 
        cumulative_fees
    LEFT JOIN 
        marketing_campaigns.bya_bitvavo campaign_data 
        ON cumulative_fees.user_id = campaign_data.user_id
    WHERE 
        cumulative_fees.cumulative_trade_fee >= (campaign_data.cashback_earned * 0.6666666667)
    QUALIFY 
        row_num = 1
)
SELECT
    first_achieved.user_id,
    CASE
        WHEN first_achieved.cashback_earned < trades.total_trade_fees THEN 'Yes'
        ELSE 'No'
    END AS reached_profit,
    first_achieved.transaction_date - first_deposit.first_deposit_date + 1 AS reached_profit_days
FROM 
    first_achieved
LEFT JOIN 
    first_deposit ON first_deposit.user_id = first_achieved.user_id
LEFT JOIN (
    SELECT 
        campaign_data.user_id, 
        SUM(trades.trade_fee_euro) AS total_trade_fees
    FROM 
        trading_data.trade_transactions trades
    JOIN 
        marketing_campaigns.bya_bitvavo campaign_data 
        ON trades.user_id = campaign_data.user_id
    WHERE 
        trades.transaction_date >= '2024-04-30'
    GROUP BY 
        campaign_data.user_id
) trades ON trades.user_id = first_achieved.user_id
HAVING 
    reached_profit = 'Yes';
