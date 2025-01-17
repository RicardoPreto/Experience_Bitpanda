-- Selecting the users that received communication
SELECT DISTINCT 
    participants.pid, 
    trades.country_res, 
    participants.variant
FROM 
    marketing_data.camp_payday_6 participants
JOIN 
    trading_data trades 
    ON participants.pid = trades.pid;

-- Selecting eligible users
SELECT DISTINCT 
    participants.pid, 
    trades.country_res,
    participants.variant,
    SUM(trades.trade_amount_euro) AS trade_amount,
    SUM(trades.trade_fee_euro) AS trade_fee
FROM 
    marketing_data.camp_payday_6 participants
LEFT JOIN 
    trading_data trades ON participants.pid = trades.pid
JOIN 
    user_events_data events ON participants.pid = events.pid
WHERE 
    trades.time BETWEEN '2024-11-27 00:00' AND '2024-11-29 23:59'
    AND trades.domain = 'bitpanda'
    AND events.user_type = 'normal'
    AND events.verification_level = '4'
    AND trades.asset_group IN ('token', 'coin', 'index', 'leveraged_token', 'security_token')
    AND trades.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey')
    AND trades.trade_type = 'buy'
GROUP BY 
    participants.pid, 
    trades.country_res, 
    participants.variant
HAVING 
    SUM(trades.trade_amount_euro) >= 20
ORDER BY 
    trade_amount ASC;

-- Retention analysis - Getting information if users kept trading after the campaign
WITH eligible AS (
    SELECT DISTINCT 
        participants.pid, 
        SUM(trades.trade_amount_euro) AS trade_amount,
        SUM(trades.trade_fee_euro) AS trade_fee
    FROM 
        marketing_data.camp_payday_6 participants
    LEFT JOIN 
        trading_data trades ON participants.pid = trades.pid
    JOIN 
        user_events_data events ON participants.pid = events.pid
    WHERE 
        trades.time BETWEEN '2024-11-27 00:00' AND '2024-11-29 23:59'
        AND trades.domain = 'bitpanda'
        AND events.user_type = 'normal'
        AND events.verification_level = '4'
        AND trades.asset_group IN ('token', 'coin', 'index', 'leveraged_token', 'security_token')
        AND trades.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey')
        AND trades.trade_type = 'buy'
        AND participants.variant IN ('C90', 'C120', 'C150')
    GROUP BY 
        participants.pid
    HAVING 
        SUM(trades.trade_amount_euro) >= 20
),
first_week AS (
    SELECT DISTINCT 
        eligible.pid, 
        MIN(trades.time) AS min_trade
    FROM 
        eligible
    JOIN 
        trading_data trades ON eligible.pid = trades.pid
    WHERE 
        trades.time BETWEEN '2024-11-30 00:00' AND '2024-12-06 23:59'
    GROUP BY 
        eligible.pid
),
after_second_week AS (
    SELECT DISTINCT 
        eligible.pid, 
        MIN(trades.time) AS min_trade
    FROM 
        eligible
    JOIN 
        trading_data trades ON eligible.pid = trades.pid
    WHERE 
        trades.time >= '2024-12-07 00:00'
    GROUP BY 
        eligible.pid
)
SELECT 
    COUNT(DISTINCT 
        CASE
            WHEN first_week.min_trade IS NOT NULL THEN eligible.pid
            ELSE NULL
        END
    ) AS first_week_trades,
    COUNT(DISTINCT 
        CASE
            WHEN after_second_week.min_trade IS NOT NULL THEN eligible.pid
            ELSE NULL
        END
    ) AS second_week_trades,
    COUNT(DISTINCT 
        CASE
            WHEN after_second_week.min_trade IS NULL 
                AND first_week.min_trade IS NULL THEN eligible.pid
            ELSE NULL
        END
    ) AS no_trades
FROM 
    eligible
LEFT JOIN 
    first_week ON first_week.pid = eligible.pid
LEFT JOIN 
    after_second_week ON after_second_week.pid = eligible.pid;
