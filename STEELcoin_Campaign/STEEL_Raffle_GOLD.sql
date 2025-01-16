-- Selecting the eligible users
SELECT 
    DISTINCT trades.pid, 
    SUM(trades.trade_amount_euro) AS trade_amount,
    SUM(trades.trade_fee_euro) AS fees_amount
FROM 
    trading_data trades
JOIN 
    user_events events ON events.pid = trades.pid
WHERE 
    trades.domain = 'bitpanda'
    AND events.user_type = 'normal'
    AND events.verification_level = '4'
    AND trades.country_res NOT IN ('Switzerland', 'Netherlands', 'Belgium', 'United Kingdom', 'Turkey')
    AND trades.time BETWEEN '2024-10-14 00:00' AND '2024-10-28 23:59'
    AND trades.trade_type = 'buy'
    AND trades.asset_symbol = 'STEEL'
    AND trades.trade_form NOT IN ('Swaps')
    AND trades.bitpanda_club = 'Gold'
GROUP BY 
    trades.pid
HAVING 
    trade_amount >= 500;


-- Getting market data for during the campaign period
SELECT 
    COUNT(DISTINCT trades.user_id) AS total_traders,
    COUNT(DISTINCT CASE WHEN trades.trade_type = 'buy' THEN trades.user_id ELSE NULL END) AS total_users_buying,
    COUNT(DISTINCT CASE WHEN trades.trade_type = 'sell' THEN trades.user_id ELSE NULL END) AS total_users_selling,
    SUM(CASE WHEN trades.trade_type = 'buy' THEN trade_amount_euro ELSE 0 END) AS trade_amount,
    SUM(trade_amount_euro) AS trade_volume,
    SUM(trade_amount_euro) / COUNT(*) AS average_trade,
    SUM(trade_fee_euro) AS fees
FROM 
    trading_data trades
JOIN 
    user_events events ON events.pid = trades.pid
LEFT JOIN 
    user_rfm_data rfm ON events.user_id = rfm.user_id
WHERE 
    trades.domain = 'bitpanda'
    AND events.user_type = 'normal'
    AND events.verification_level = '4'
    AND trades.country_res NOT IN ('Switzerland', 'Netherlands', 'Belgium', 'United Kingdom', 'Turkey')
    AND trades.time BETWEEN '2024-10-14 00:00' AND '2024-10-28 23:59'
    AND trades.trade_type IN ('buy', 'sell')
    AND trades.asset_symbol = 'STEEL'
    AND trade_form NOT IN ('Swaps')
    AND trades.bitpanda_club = 'Gold';
