-- Selecting the users getting the respective payout they should receive
    -- Trades >= 9 then 3%, trades >= 5 then 2%, trades >= 1 then 1%

WITH UniqueTradeDates AS (
    SELECT DISTINCT 
        a.pid AS user_id, 
        CONCAT(
            YEAR(a.time), '-', 
            LPAD(MONTH(a.time), 2, '0'), '-', 
            LPAD(DAY(a.time), 2, '0')
        ) AS trade_date
    FROM 
        table_1 a
    JOIN 
        table_2 ue ON ue.pid = a.pid
    WHERE 
        a.domain = 'bitpanda'
        AND ue.user_type = 'normal'
        AND ue.verification_level = '4'
        AND a.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey', 'France')
        AND a.time BETWEEN '2024-10-07 00:00' AND '2024-11-04 23:59'
        AND a.trade_type IN ('buy', 'sell')
        AND trade_amount_euro >= 10
    GROUP BY 
        a.pid, trade_date
),
LaggedTrades AS (
    SELECT 
        user_id, 
        trade_date, 
        LAG(trade_date) OVER (PARTITION BY user_id ORDER BY trade_date) AS prev_trade_date
    FROM 
        UniqueTradeDates
),
Streaks AS (
    SELECT 
        user_id, 
        trade_date, 
        CASE 
            WHEN DATEDIFF(DAY, prev_trade_date, trade_date) = 1 THEN 0 
            ELSE 1 
        END AS new_streak
    FROM 
        LaggedTrades
),
StreakGroups AS (
    SELECT 
        user_id, 
        trade_date, 
        SUM(new_streak) OVER (
            PARTITION BY user_id 
            ORDER BY trade_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS streak_group
    FROM 
        Streaks
),
ConsecutiveCount AS (
    SELECT 
        user_id, 
        streak_group, 
        COUNT(*) AS consecutive_days
    FROM 
        StreakGroups
    GROUP BY 
        user_id, streak_group
)
SELECT DISTINCT 
    ConsecutiveCount.user_id, 
    MAX(consecutive_days) AS max_consecutive_days,
    CASE 
        WHEN MAX(consecutive_days) >= 9 THEN '3%' 
        WHEN MAX(consecutive_days) >= 5 THEN '2%' 
        ELSE '1%' 
    END AS cashback,
    amounts.min_trade,
    CASE 
        WHEN MAX(consecutive_days) >= 9 THEN amounts.min_trade * 0.03 
        WHEN MAX(consecutive_days) >= 5 THEN amounts.min_trade * 0.02 
        ELSE amounts.min_trade * 0.01 
    END AS payout,
    amounts.trade_num, 
    amounts.trade_amount, 
    amounts.fees_amount
FROM 
    ConsecutiveCount
JOIN 
    table_3 campaign ON campaign.user_id = ConsecutiveCount.user_id AND Group_ = 'TEST'
LEFT JOIN (
    SELECT DISTINCT 
        a.pid, 
        COUNT(*) AS trade_num, 
        SUM(trade_amount_euro) AS trade_amount, 
        SUM(trade_fee_euro) AS fees_amount, 
        MIN(trade_amount_euro) AS min_trade
    FROM 
        table_1 a
    JOIN 
        table_2 ue ON ue.pid = a.pid
    WHERE 
        a.domain = 'bitpanda'
        AND ue.user_type = 'normal'
        AND ue.verification_level = '4'
        AND a.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey', 'France')
        AND a.time BETWEEN '2024-10-07 00:00' AND '2024-11-04 23:59'
        AND a.trade_type IN ('buy', 'sell')
        AND trade_amount_euro >= 10
    GROUP BY 
        a.pid
) amounts ON amounts.pid = ConsecutiveCount.user_id
GROUP BY 
    ConsecutiveCount.user_id, 
    amounts.min_trade, 
    amounts.trade_num, 
    amounts.trade_amount, 
    amounts.fees_amount
ORDER BY 
    max_consecutive_days DESC;


-- Getting the trades overtime 
WITH UniqueTradeDates AS (
    SELECT DISTINCT 
        a.pid AS user_id, 
        CONCAT(
            YEAR(a.time), '-', 
            LPAD(MONTH(a.time), 2, '0'), '-', 
            LPAD(DAY(a.time), 2, '0')
        ) AS trade_date
    FROM 
        table_1 a
    JOIN 
        table_2 ue ON ue.pid = a.pid
    WHERE 
        a.domain = 'bitpanda'
        AND ue.user_type = 'normal'
        AND ue.verification_level = '4'
        AND a.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey', 'France')
        AND a.time BETWEEN '2024-10-07 00:00' AND '2024-11-04 23:59'
        AND a.trade_type IN ('buy', 'sell')
        AND trade_amount_euro >= 10
    GROUP BY 
        a.pid, trade_date
),
LaggedTrades AS (
    SELECT 
        user_id, 
        trade_date, 
        LAG(trade_date) OVER (PARTITION BY user_id ORDER BY trade_date) AS prev_trade_date
    FROM 
        UniqueTradeDates
),
Streaks AS (
    SELECT 
        user_id, 
        trade_date, 
        CASE 
            WHEN DATEDIFF(DAY, prev_trade_date, trade_date) = 1 THEN 0 
            ELSE 1 
        END AS new_streak
    FROM 
        LaggedTrades
),
StreakGroups AS (
    SELECT 
        user_id, 
        trade_date, 
        SUM(new_streak) OVER (
            PARTITION BY user_id 
            ORDER BY trade_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS streak_group
    FROM 
        Streaks
),
ConsecutiveCount AS (
    SELECT 
        user_id, 
        streak_group, 
        COUNT(*) AS consecutive_days
    FROM 
        StreakGroups
    GROUP BY 
        user_id, streak_group
),
eligible AS (
    SELECT DISTINCT 
        ConsecutiveCount.user_id, 
        MAX(consecutive_days) AS max_consecutive_days,
        CASE 
            WHEN MAX(consecutive_days) >= 9 THEN '3%' 
            WHEN MAX(consecutive_days) >= 5 THEN '2%' 
            ELSE '1%' 
        END AS cashback,
        amounts.min_trade,
        CASE 
            WHEN MAX(consecutive_days) >= 9 THEN amounts.min_trade * 0.03 
            WHEN MAX(consecutive_days) >= 5 THEN amounts.min_trade * 0.02 
            ELSE amounts.min_trade * 0.01 
        END AS payout,
        amounts.trade_num, 
        amounts.trade_amount, 
        amounts.fees_amount
    FROM 
        ConsecutiveCount
    JOIN 
        table_3 campaign ON campaign.user_id = ConsecutiveCount.user_id AND Group_ = 'TEST'
    LEFT JOIN (
        SELECT DISTINCT 
            a.pid, 
            COUNT(*) AS trade_num, 
            SUM(trade_amount_euro) AS trade_amount, 
            SUM(trade_fee_euro) AS fees_amount, 
            MIN(trade_amount_euro) AS min_trade
        FROM 
            table_1 a
        JOIN 
            table_2 ue ON ue.pid = a.pid
        WHERE 
            a.domain = 'bitpanda'
            AND ue.user_type = 'normal'
            AND ue.verification_level = '4'
            AND a.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey', 'France')
            AND a.time BETWEEN '2024-10-07 00:00' AND '2024-11-04 23:59'
            AND a.trade_type IN ('buy', 'sell')
            AND trade_amount_euro >= 10
        GROUP BY 
            a.pid
    ) amounts ON amounts.pid = ConsecutiveCount.user_id
    GROUP BY 
        ConsecutiveCount.user_id, 
        amounts.min_trade, 
        amounts.trade_num, 
        amounts.trade_amount, 
        amounts.fees_amount
    ORDER BY 
        max_consecutive_days DESC
)
SELECT 
    DATE_PART('day', a.time) AS day, 
    DATE_PART('month', a.time) AS month, 
    COUNT(DISTINCT eligible.user_id) AS traders
FROM 
    table_1 a
JOIN 
    eligible ON a.pid = eligible.user_id
JOIN 
    table_2 ue ON ue.pid = a.pid
WHERE 
    a.domain = 'bitpanda'
    AND ue.user_type = 'normal'
    AND ue.verification_level = '4'
    AND a.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey', 'France')
    AND a.time BETWEEN '2024-10-07 00:00' AND '2024-11-04 23:59'
    AND a.trade_type IN ('buy', 'sell')
    AND trade_amount_euro >= 10
GROUP BY 
    DATE_PART('day', a.time), 
    DATE_PART('month', a.time)
ORDER BY 
    month ASC, 
    day ASC;
