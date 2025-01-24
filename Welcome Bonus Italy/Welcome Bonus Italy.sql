-- Selecting Elegible users and their customer/trading infos 
WITH user_payouts AS (
    SELECT 
        user_id,
        SUM(payout) AS total_payout
    FROM 
        rewards_data.bonus_eligibility
    GROUP BY 
        user_id
)
SELECT 
    payouts.user_id,
    events.registered_at,
    payouts.total_payout AS payout,
    transactions.channel,
    MAX(transactions.date) AS last_trade,
    DATEDIFF('day', events.registered_at, MAX(transactions.date)) AS days_active,
    SUM(transactions.trade_fee_euro) AS fees
FROM 
    user_payouts AS payouts
JOIN 
    transaction_data.transactions AS transactions ON payouts.user_id = transactions.pid
JOIN 
    event_data.user_events AS events ON events.pid = transactions.pid
GROUP BY 
    payouts.user_id, 
    events.registered_at, 
    payouts.total_payout, 
    transactions.channel
ORDER BY 
    events.registered_at;

-- Selecting data for a retention analysis
WITH user_payouts AS (
    SELECT 
        user_id,
        SUM(payout) AS total_payout
    FROM 
        rewards_data.bonus_eligibility
    GROUP BY 
        user_id
),
trade_assistance AS (
    SELECT 
        payouts.user_id,
        SUM(
            CASE
                WHEN trades.date > DATEADD('DAY', 13, events.registered_at) THEN 1
                ELSE 0
            END
        ) AS trades_after_promo,
        SUM(trades.trade_fee_euro) AS total_fees
    FROM 
        user_payouts AS payouts
    JOIN 
        transaction_data.transactions AS trades ON payouts.user_id = trades.pid
    JOIN 
        event_data.user_events AS events ON events.pid = trades.pid
    GROUP BY 
        payouts.user_id
    ORDER BY 
        trades_after_promo
)
SELECT 
    assistance.user_id,
    CASE
        WHEN payouts.total_payout = 50 AND assistance.trades_after_promo >= 5 THEN assistance.trades_after_promo - 5
        ELSE assistance.trades_after_promo
    END AS trades_after_promo,
    assistance.total_fees AS fees
FROM 
    trade_assistance AS assistance
LEFT JOIN 
    user_payouts AS payouts ON payouts.user_id = assistance.user_id;
