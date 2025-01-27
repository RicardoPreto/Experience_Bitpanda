-- Getting data from all users
WITH user_trades AS (
    SELECT 
        DISTINCT transactions.pid,
        COUNT(*) AS trades
    FROM 
        transaction_data.trades_broker transactions
    WHERE 
        transactions.country_res = 'France'
        AND transactions.domain = 'bitpanda'
        AND transactions.time >= '2023-01-01'
        AND transactions.time < '2024-01-01'
    GROUP BY 
        transactions.pid
)
SELECT
    COUNT(DISTINCT user_trades.pid) AS total_traders,
    COUNT(DISTINCT CASE WHEN user_trades.trades >= 50 THEN user_trades.pid ELSE NULL END) AS "50+_trades",
    COUNT(DISTINCT CASE WHEN user_trades.trades < 50 THEN user_trades.pid ELSE NULL END) AS "-50_trades"
FROM 
    user_trades;


-- Getting data from Gold & Silver Club clients
WITH user_trades AS (
    SELECT 
        DISTINCT transactions.pid,
        COUNT(*) AS trades
    FROM 
        transaction_data.trades_broker transactions
    WHERE 
        transactions.country_res = 'France'
        AND transactions.domain = 'bitpanda'
        AND transactions.time >= '2023-01-01'
        AND transactions.time < '2024-01-01'
        AND transactions.bitpanda_club IN ('Gold', 'Silver')
    GROUP BY 
        transactions.pid
)
SELECT
    COUNT(DISTINCT user_trades.pid) AS total_traders,
    COUNT(DISTINCT CASE WHEN user_trades.trades >= 50 THEN user_trades.pid ELSE NULL END) AS "50+_trades",
    COUNT(DISTINCT CASE WHEN user_trades.trades < 50 THEN user_trades.pid ELSE NULL END) AS "-50_trades"
FROM 
    user_trades;

-- Selecting just from Gold members
WITH user_trades AS (
    SELECT 
        DISTINCT transactions.pid,
        COUNT(*) AS trades
    FROM 
        transaction_data.v_trades_broker transactions
    WHERE 
        transactions.country_res = 'France'
        AND transactions.domain = 'bitpanda'
        AND transactions.time >= '2023-01-01'
        AND transactions.time < '2024-01-01'
        AND transactions.bitpanda_club IN ('Gold')
    GROUP BY 
        transactions.pid
)
SELECT
    COUNT(DISTINCT user_trades.pid) AS total_traders,
    COUNT(DISTINCT CASE WHEN user_trades.trades >= 50 THEN user_trades.pid ELSE NULL END) AS "50+_trades",
    COUNT(DISTINCT CASE WHEN user_trades.trades < 50 THEN user_trades.pid ELSE NULL END) AS "-50_trades"
FROM 
    user_trades;
