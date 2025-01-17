-- Selecting the eligible ones
WITH duplicates AS (
    SELECT 
        pid, 
        MIN(variant) AS variant_new
    FROM 
        marketing_data.public.payday_06_december
    GROUP BY 
        pid
)
SELECT DISTINCT 
    broker.pid, 
    duplicates.variant_new, 
    user_events.country_res,
    SUM(broker.trade_amount_euro) AS trade_amount,
    SUM(broker.trade_fee_euro) AS trade_fee,
    10 AS payout
FROM 
    marketing_data.public.payday_06_december campaign
LEFT JOIN 
    trading_data broker ON campaign.pid = broker.pid
JOIN 
    duplicates ON duplicates.pid = campaign.pid
LEFT JOIN 
    user_events_data user_events ON user_events.pid = broker.pid
WHERE 
    broker.time BETWEEN '2024-12-27 00:00' AND '2024-12-29 23:59'
    AND broker.domain = 'bitpanda'
    AND broker.user_type = 'normal'
    AND user_events.verification_level = '4'
    AND broker.country_res

-- Selecting users that received the communication
WITH duplicates AS (

    select DISTINCT
    campaign.pid, 
    user.country_res,
    min(CASE
      WHEN variant IN ('90', '120', '150') THEN variant
      ELSE variant
    END) as variant_new,
    sum(broker.trade_amount_euro)   AS trade_amount,
    sum(broker.trade_fee_euro)      AS trade_fee
    FROM MARKETING_DATA.PUBLIC.PAYDAY_06_DECEMBER campaign
    LEFT JOIN PROCESSED_DATA.DWH.V_TRADES_BROKER broker
        ON campaign.pid = broker.pid
    LEFT JOIN processed_data.dwh.user_events user 
        ON user.pid = broker.pid
    WHERE broker.time >= '2024-12-27 00:00' 
        AND broker.time <= '2024-12-29 23:59'
        AND broker.domain = 'bitpanda' 
        AND broker.user_type = 'normal' 
        AND user.verification_level = '4'
        AND broker.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey')
        AND broker.asset_group in ('token', 'coin', 'index', 'leveraged_token')
    group by 1,2
)
SELECT 
    DISTINCT
    campaign.pid, 
    CASE 
        WHEN duplicates.variant_new IS NOT NULL THEN duplicates.variant_new
        ELSE campaign.variant
    END AS variant, 
    user.country_res,
    duplicates.trade_amount,
    duplicates.trade_fee
FROM MARKETING_DATA.PUBLIC.PAYDAY_06_DECEMBER campaign
LEFT JOIN duplicates 
    ON duplicates.pid = campaign.pid
LEFT JOIN processed_data.dwh.user_events user 
        ON user.pid = campaign.pid


-- Retention analysis - Getting information if users kept trading after the campaign
WITH duplicates AS (
    SELECT
        pid, 
        MIN(
            CASE
                WHEN variant IN ('C90', 'C120', 'C150') THEN variant
                ELSE variant
            END
        ) AS variant_new
    FROM 
        marketing_data.public.payday_06_december
    GROUP BY 
        pid
),
eligible AS (
    SELECT DISTINCT
        broker.pid, 
        duplicates.variant_new, 
        user_events.country_res,
        SUM(broker.trade_amount_euro) AS trade_amount,
        SUM(broker.trade_fee_euro) AS trade_fee,
        10 AS payout
    FROM 
        marketing_data.public.payday_06_december campaign
    LEFT JOIN 
        trading_data broker ON campaign.pid = broker.pid
    JOIN 
        duplicates ON duplicates.pid = campaign.pid
    LEFT JOIN 
        user_events_data user_events ON user_events.pid = broker.pid
    WHERE 
        broker.time BETWEEN '2024-12-27 00:00' AND '2024-12-29 23:59'
        AND broker.domain = 'bitpanda'
        AND broker.user_type = 'normal'
        AND user_events.verification_level = '4'
        AND broker.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey')
        AND broker.asset_group IN ('token', 'coin', 'index', 'leveraged_token')
        AND campaign.variant IN ('C90', 'C120', 'C150')
    GROUP BY 
        broker.pid, 
        duplicates.variant_new, 
        user_events.country_res
    HAVING 
        SUM(broker.trade_amount_euro) >= 20
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
        trades.time BETWEEN '2024-12-30 00:00' AND '2025-01-05 23:59'
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
        trades.time >= '2025-01-06 00:00'
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
