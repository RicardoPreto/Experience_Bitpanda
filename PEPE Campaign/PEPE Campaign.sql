SELECT
    trades.user_id, 
    SUM(trades.trade_amount_euro) AS total_trade_amount,
    SUM(trades.trade_fee_euro) AS total_trade_fee
FROM 
    trading_data.trade_transactions trades
JOIN 
    marketing_campaigns.pepe_campaign campaign
    ON trades.user_id = campaign.user_id
LEFT JOIN 
    user_data.user_events events
    ON events.user_id = trades.user_id
WHERE 
    trades.transaction_date BETWEEN '2024-12-16 00:00' AND '2024-12-23 23:59'
    AND trades.platform = 'bitpanda' 
    AND trades.user_type = 'normal' 
    AND events.verification_level = '4'
    AND trades.user_country NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey')
    AND trades.asset_category NOT IN ('index', 'leveraged_token')
    AND trades.trade_method != 'Swaps'
GROUP BY 
    trades.user_id
HAVING 
    total_trade_amount >= 25;
