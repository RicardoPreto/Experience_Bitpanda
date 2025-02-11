WITH first_trade AS (
    SELECT
        trades.asset_symbol,
        trades.user_id, 
        trades.transaction_date,
        trades.trade_amount_euro,
        trades.trade_fee_euro,
        ROW_NUMBER() OVER (
            PARTITION BY trades.user_id 
            ORDER BY trades.transaction_date ASC
        ) AS trade_rank
    FROM 
        trading_data.trade_transactions trades
    WHERE 
        trades.user_country = 'Austria'
        -- trades.user_country = 'Switzerland'
        AND trades.transaction_date >= '2022-01-01'
        AND trades.trade_type = 'buy'
        AND trades.platform = 'bitpanda'
    QUALIFY 
        trade_rank = 1
)
SELECT 
    DATE_TRUNC('week', first_trade.transaction_date) AS trade_week,
    first_trade.asset_symbol,
    SUM(first_trade.trade_amount_euro) AS total_trade_amount,
    SUM(first_trade.trade_fee_euro) AS total_trade_fees,
    SUM(first_trade.trade_fee_euro) / NULLIF(SUM(first_trade.trade_amount_euro), 0) AS revenue
FROM 
    first_trade
GROUP BY 
    trade_week, 
    first_trade.asset_symbol
ORDER BY 
    trade_week ASC, 
    total_trade_amount DESC;
