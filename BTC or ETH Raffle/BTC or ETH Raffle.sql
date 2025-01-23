-- Selecting the eligible users
-- Eligible
SELECT 
    DISTINCT trades.pid,
    COUNT(*) AS trade_num,
    SUM(trades.trade_amount_euro) AS trade_amount,
    SUM(trades.trade_fee_euro) AS fees_amount
FROM 
    trading_data trades
JOIN 
    user_events_data events ON events.pid = trades.pid
WHERE 
    trades.domain = 'bitpanda'
    AND events.user_type = 'normal'
    AND events.verification_level = '4'
    AND trades.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey')
    AND trades.time BETWEEN '2024-11-04 00:00' AND '2024-11-11 23:59'
    AND trades.trade_type IN ('buy', 'sell')
    AND trades.asset_symbol IN ('BTC', 'ETH')
GROUP BY 
    trades.pid
HAVING 
    trade_amount >= 50;

-- Selecting data from all trades during the CP
SELECT
    COUNT(DISTINCT trades_main.user_id) AS total_traders,
    SUM(trades_main.trade_amount_euro) AS trade_volume,
    SUM(
        CASE 
            WHEN trades_main.trade_type = 'buy' THEN trades_main.trade_amount_euro 
            ELSE 0 
        END
    ) AS trade_amount,
    SUM(trades_main.trade_amount_euro) / COUNT(*) AS average_trade,
    SUM(trades_main.trade_fee_euro) AS fees
FROM 
    trading_data trades_main
JOIN 
    user_events_data events ON events.pid = trades_main.pid
LEFT JOIN 
    user_rfm_data rfm ON events.user_id = rfm.user_id
LEFT JOIN (
    SELECT 
        trades_sub.user_id, 
        COUNT(*) AS trades
    FROM 
        trading_data trades_sub
    JOIN 
        user_events_data events_sub ON events_sub.pid = trades_sub.pid
    WHERE 
        trades_sub.domain = 'bitpanda'
        AND events_sub.user_type = 'normal'
        AND events_sub.verification_level = '4'
        AND trades_sub.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey')
        AND trades_sub.time BETWEEN '2024-11-04 00:00' AND '2024-11-11 23:59'
        AND trades_sub.trade_type IN ('buy', 'sell')
        AND trades_sub.asset_symbol IN ('BTC', 'ETH')
    GROUP BY 
        trades_sub.user_id
    HAVING 
        COUNT(*) >= 5
) trades ON trades.user_id = trades_main.user_id
WHERE 
    trades_main.domain = 'bitpanda'
    AND events.user_type = 'normal'
    AND events.verification_level = '4'
    AND trades_main.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey')
    AND trades_main.time BETWEEN '2024-11-04 00:00' AND '2024-11-11 23:59'
    AND trades_main.trade_type IN ('buy', 'sell')
    AND trades_main.asset_symbol IN ('BTC', 'ETH');


-- Selecting the Market Share by Trade Volume of the Coins
SELECT 
    SUM(
        CASE 
            WHEN trades.asset_symbol NOT IN ('BTC', 'ETH') THEN trades.trade_amount_euro
            ELSE 0
        END
    ) AS trade_volume_general,
    SUM(
        CASE 
            WHEN trades.asset_symbol = 'ETH' THEN trades.trade_amount_euro
            ELSE 0
        END
    ) AS trade_volume_eth,
    SUM(
        CASE 
            WHEN trades.asset_symbol = 'BTC' THEN trades.trade_amount_euro
            ELSE 0
        END
    ) AS trade_volume_btc
FROM 
    trading_data trades
JOIN 
    user_events_data events ON events.pid = trades.pid
WHERE 
    trades.domain = 'bitpanda'
    AND events.user_type = 'normal'
    AND events.verification_level = '4'
    AND trades.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey')
    AND trades.time BETWEEN '2024-11-12 00:00' AND '2024-11-18 23:59'
GROUP BY 
    trades.asset_symbol;

-- Getting the distribution by trade amount
WITH users_data AS (
    SELECT 
        DISTINCT trades.pid,
        COUNT(*) AS trade_num,
        SUM(trades.trade_amount_euro) AS trade_amount,
        SUM(trades.trade_fee_euro) AS fees_amount
    FROM 
        processed_data.dwh.v_trades_broker trades
    JOIN 
        processed_data.dwh.user_events events ON events.pid = trades.pid
    WHERE 
        trades.domain = 'bitpanda'
        AND events.user_type = 'normal'
        AND events.verification_level = '4'
        AND trades.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey')
        AND trades.time BETWEEN '2024-11-12 00:00' AND '2024-11-18 23:59'
        AND trades.asset_symbol IN ('BTC', 'ETH')
    GROUP BY 
        trades.pid
),
ranges AS (
    SELECT 
        users_data.pid,
        CASE
            WHEN users_data.trade_amount < 10 THEN '0'
            WHEN users_data.trade_amount < 20 THEN '10'
            WHEN users_data.trade_amount < 30 THEN '20'
            WHEN users_data.trade_amount < 40 THEN '30'
            WHEN users_data.trade_amount < 50 THEN '40'
            WHEN users_data.trade_amount < 60 THEN '50'
            WHEN users_data.trade_amount < 70 THEN '60'
            WHEN users_data.trade_amount < 80 THEN '70'
            WHEN users_data.trade_amount < 90 THEN '80'
            WHEN users_data.trade_amount < 100 THEN '90'
            WHEN users_data.trade_amount < 110 THEN '100'
            WHEN users_data.trade_amount < 120 THEN '110'
            WHEN users_data.trade_amount < 130 THEN '120'
            WHEN users_data.trade_amount < 140 THEN '130'
            WHEN users_data.trade_amount < 150 THEN '140'
            WHEN users_data.trade_amount < 160 THEN '150'
            WHEN users_data.trade_amount < 170 THEN '160'
            WHEN users_data.trade_amount < 180 THEN '170'
            WHEN users_data.trade_amount < 190 THEN '180'
            WHEN users_data.trade_amount < 200 THEN '190'
            ELSE '200+'
        END AS range
    FROM 
        users_data
)
SELECT 
    COUNT(DISTINCT ranges.pid) AS total_users,
    ranges.range
FROM 
    ranges
GROUP BY 
    ranges.range
ORDER BY 
    ranges.range;
