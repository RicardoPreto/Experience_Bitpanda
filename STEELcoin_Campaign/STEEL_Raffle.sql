-- Selecting the eligible users
SELECT 
    DISTINCT trades.pid, 
    SUM(trades.trade_amount_euro) AS trade_amount,
    SUM(trades.trade_fee_euro) AS fees_amount
FROM 
    table_trades trades
JOIN 
    table_user_events events ON events.pid = trades.pid
LEFT JOIN 
    table_user_rfm rfm ON events.user_id = rfm.user_id
WHERE 
    trades.domain = 'bitpanda'
    AND events.user_type = 'normal'
    AND events.verification_level = '4'
    AND trades.country_res NOT IN ('Switzerland', 'Netherlands', 'Belgium', 'United Kingdom', 'Turkey')
    AND trades.time BETWEEN '2024-10-11 00:00' AND '2024-10-18 23:59'
    AND trades.trade_type = 'buy'
    AND trades.asset_symbol = 'STEEL'
    AND trades.trade_form NOT IN ('Swaps')
GROUP BY 
    trades.pid
HAVING 
    trade_amount >= 30;



-- Selecting just new users
SELECT 
    COUNT(DISTINCT trades.pid) AS total_users, 
    SUM(trades.trade_amount_euro) AS trade_amount
FROM 
    trading_data trades
LEFT JOIN 
    user_events events ON events.pid = trades.pid
WHERE 
    trades.domain = 'bitpanda'
    AND events.user_type = 'normal'
    AND events.verification_level = '4'
    AND trades.country_res NOT IN ('Switzerland', 'Netherlands', 'Belgium', 'United Kingdom', 'Turkey')
    AND trades.time <= '2024-10-10 23:59'
    AND trades.trade_type = 'buy'
    AND trades.asset_symbol = 'STEEL'
    AND trades.pid NOT IN (
        SELECT DISTINCT 
            trades_sub.pid 
        FROM 
            trading_data trades_sub
        WHERE 
            trades_sub.time <= '2024-10-01 23:59' 
            AND trades_sub.asset_symbol = 'STEEL'
    );

