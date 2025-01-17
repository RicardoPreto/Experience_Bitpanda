-- Selecting users that received the communications
SELECT DISTINCT 
    participants.user_id, 
    events.country_res,
    participants.variant,
    SUM(trades.trade_amount_euro) AS trade_amount,
    SUM(trades.trade_fee_euro) AS trade_fee
FROM 
    marketing_data.payday_october_communication participants
LEFT JOIN 
    trading_data trades ON participants.user_id = trades.pid
LEFT JOIN 
    user_events_data events ON participants.user_id = events.pid
GROUP BY 
    participants.user_id, 
    events.country_res, 
    participants.variant;

-- Selecting the users eligible to receive the bonus
SELECT 
    participants.user_id, 
    trades.country_res,
    participants.variant,
    SUM(trades.trade_amount_euro) AS trade_amount,
    SUM(trades.trade_fee_euro) AS trade_fee
FROM 
    marketing_data.payday_october_communication participants
JOIN 
    trading_data trades ON participants.user_id = trades.pid
JOIN 
    user_events_data events ON participants.user_id = events.pid
WHERE 
    trades.time BETWEEN '2024-10-29 00:00' AND '2024-11-05 23:59'
    AND trades.domain = 'bitpanda'
    AND trades.user_type = 'normal'
    AND trades.verification_level = '4'
    AND trades.asset_group IN ('token', 'coin', 'index', 'leveraged_token', 'security_token')
    AND trades.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey')
    AND trades.trade_type = 'buy'
GROUP BY 
    participants.user_id, 
    trades.country_res, 
    participants.variant
HAVING 
    SUM(trades.trade_amount_euro) >= 20;


-- Selecting the users eligible to receive the bonus by trade date
WITH traded AS (
    SELECT
        participants.user_id, 
        trades.country_res,
        participants.variant,
        MIN(trades.time) AS traded,
        SUM(trades.trade_amount_euro) AS trade_amount,
        SUM(trades.trade_fee_euro) AS trade_fee
    FROM 
        marketing_data.payday_october_communication participants
    JOIN 
        trading_data trades ON participants.user_id = trades.pid
    JOIN 
        user_events_data events ON participants.user_id = events.pid
    WHERE 
        trades.time BETWEEN '2024-10-29 00:00' AND '2024-11-05 23:59'
        AND trades.domain = 'bitpanda'
        AND trades.user_type = 'normal'
        AND trades.verification_level = '4'
        AND trades.asset_group IN ('token', 'coin', 'index', 'leveraged_token', 'security_token')
        AND trades.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey')
        AND trades.trade_type = 'buy'
    GROUP BY 
        participants.user_id, 
        trades.country_res, 
        participants.variant
    HAVING 
        SUM(trades.trade_amount_euro) >= 20
)
SELECT 
    TO_CHAR(traded.traded, 'DD-MM') AS traded_date,
    traded.country_res,
    traded.variant,
    COUNT(DISTINCT traded.user_id) AS users
FROM 
    traded
GROUP BY 
    traded.traded_date, 
    traded.country_res, 
    traded.variant
ORDER BY 
    traded_date ASC;


