-- Selecting eligible users for the campaign
WITH eligible AS (
    SELECT 
        s.user_id, 
        SUM(euro_amount) AS stake_amount
    FROM 
        table_1 s
    JOIN 
        table_2 da ON da.asset_pid = s.asset_id
    LEFT JOIN 
        table_3 ue ON ue.pid = s.user_id
    LEFT JOIN 
        table_4 rfm ON ue.user_id = rfm.user_id
    WHERE 
        ue.user_type = 'normal'
        AND ue.domain = 'bitpanda'
        AND created_at >= '2024-08-29 00:00'
        AND created_at <= '2024-09-05 23:59'
        AND operation_type = 'stake'
        AND ue.verification_level = '4'
        AND m_stage NOT IN ('Employee - not eligible for RFM')
        AND ue.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey')
    GROUP BY 
        s.user_id
    HAVING 
        stake_amount >= 50
)
SELECT 
    ue.country_res,
    COUNT(DISTINCT eligible.user_id) AS total_stakers,
    COUNT(DISTINCT eligible.user_id) / SUM(COUNT(DISTINCT eligible.user_id)) OVER() * 100 AS perc_stakers,
    SUM(s.euro_amount) AS stake_amount
FROM 
    eligible
JOIN 
    table_1 s ON s.user_id = eligible.user_id
JOIN 
    table_2 da ON da.asset_pid = s.asset_id
LEFT JOIN 
    table_3 ue ON ue.pid = s.user_id
LEFT JOIN 
    table_4 rfm ON ue.user_id = rfm.user_id
WHERE 
    ue.user_type = 'normal'
    AND ue.domain = 'bitpanda'
    AND created_at >= '2024-08-29 00:00'
    AND created_at <= '2024-09-05 23:59'
    AND operation_type IN ('stake')
    AND ue.verification_level = '4'
    AND m_stage NOT IN ('Employee - not eligible for RFM')
    AND ue.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey')
GROUP BY 
    ue.country_res
ORDER BY 
    total_stakers DESC;

-- Selecting data to analyze reactivated users
WITH eligible AS (
    SELECT DISTINCT 
        a.pid AS user_id, 
        COUNT(*) AS trade_num, 
        SUM(trade_amount_euro) AS trade_amount, 
        SUM(trade_fee_euro) AS fees_amount,
        CASE 
            WHEN COUNT(*) >= 9 THEN 20 
            WHEN COUNT(*) >= 7 THEN 15 
            ELSE 10 
        END AS payout
    FROM 
        table_1 a
    JOIN 
        table_2 ue ON ue.pid = a.pid
    JOIN 
        table_3 frequency ON a.pid = frequency.user_id
    WHERE 
        a.domain = 'bitpanda'
        AND ue.user_type = 'normal'
        AND ue.verification_level = '4'
        AND a.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey', 'France')
        AND a.time >= '2024-10-07 00:00'
        AND a.time <= '2024-11-04 23:59'
        AND a.trade_type IN ('buy', 'sell')
        AND trade_amount_euro >= 10
    GROUP BY 
        a.pid
    HAVING 
        trade_num >= 5
), 
analysis AS (
    WITH trade_after AS (
        SELECT DISTINCT 
            a.pid AS user_id, 
            MIN(a.time) AS time
        FROM 
            table_1 a
        JOIN 
            table_2 ue ON ue.pid = a.pid
        LEFT JOIN 
            table_4 rfm ON ue.user_id = rfm.user_id
        WHERE 
            a.domain = 'bitpanda'
            AND ue.user_type = 'normal'
            AND ue.verification_level = '4'
            AND a.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey', 'France')
            AND a.time BETWEEN '2024-10-07 00:00' AND '2024-11-04 23:59'
            AND a.trade_type = 'buy'
        GROUP BY 
            a.pid
    ), 
    last_trade_before AS (
        SELECT DISTINCT 
            a.pid AS user_id, 
            MAX(a.time) AS time
        FROM 
            table_1 a
        JOIN 
            table_2 ue ON ue.pid = a.pid
        LEFT JOIN 
            table_4 rfm ON ue.user_id = rfm.user_id
        WHERE 
            a.domain = 'bitpanda'
            AND ue.user_type = 'normal'
            AND ue.verification_level = '4'
            AND a.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey', 'France')
            AND a.time <= '2024-10-06 23:59'
            AND a.trade_type = 'buy'
        GROUP BY 
            a.pid
    )
    SELECT 
        eligible.user_id, 
        ltb.time AS last_trade_before_time, 
        ta.time AS first_time_after
    FROM 
        eligible
    LEFT JOIN 
        trade_after ta ON eligible.user_id = ta.user_id
    LEFT JOIN 
        last_trade_before ltb ON ta.user_id = ltb.user_id
)
SELECT 
    COUNT(DISTINCT CASE WHEN last_trade_before_time >= '2024-09-07 00:00' AND last_trade_before_time < '2024-10-07 00:00' THEN user_id END) AS last_30_days,
    COUNT(DISTINCT CASE WHEN last_trade_before_time >= '2024-07-07 00:00' AND last_trade_before_time < '2024-09-07 00:00' THEN user_id END) AS last_3_months,
    COUNT(DISTINCT CASE WHEN last_trade_before_time >= '2024-04-07 00:00' AND last_trade_before_time < '2024-07-07 00:00' THEN user_id END) AS last_6_months,
    COUNT(DISTINCT CASE WHEN last_trade_before_time < '2024-04-07 00:00' THEN user_id END) AS before_6months,
    COUNT(DISTINCT CASE WHEN last_trade_before_time IS NULL THEN user_id END) AS never_traded_before
FROM 
    analysis;

-- Selecting data to analyze it overtime
WITH eligible AS (
    SELECT DISTINCT 
        a.pid, 
        COUNT(*) AS trade_num, 
        SUM(trade_amount_euro) AS trade_amount, 
        SUM(trade_fee_euro) AS fees_amount,
        CASE 
            WHEN COUNT(*) >= 9 THEN 20 
            WHEN COUNT(*) >= 7 THEN 15 
            ELSE 10 
        END AS payout
    FROM 
        table_1 a
    JOIN 
        table_2 ue ON ue.pid = a.pid
    JOIN 
        table_3 frequency ON a.pid = frequency.user_id
    WHERE 
        a.domain = 'bitpanda'
        AND ue.user_type = 'normal'
        AND ue.verification_level = '4'
        AND a.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey', 'France')
        AND a.time >= '2024-10-07 00:00'
        AND a.time <= '2024-11-04 23:59'
        AND a.trade_type IN ('buy', 'sell')
        AND trade_amount_euro >= 10
    GROUP BY 
        a.pid
    HAVING 
        trade_num >= 5
)
SELECT 
    DATE_PART('day', a.time) AS day, 
    DATE_PART('month', a.time) AS month, 
    COUNT(DISTINCT eligible.pid) AS traders
FROM 
    table_1 a
JOIN 
    eligible ON a.pid = eligible.pid
JOIN 
    table_2 ue ON ue.pid = a.pid
WHERE 
    a.domain = 'bitpanda'
    AND ue.user_type = 'normal'
    AND ue.verification_level = '4'
    AND a.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey', 'France')
    AND a.time >= '2024-10-07 00:00'
    AND a.time <= '2024-11-04 23:59'
    AND a.trade_type IN ('buy', 'sell')
    AND trade_amount_euro >= 10
GROUP BY 
    DATE_PART('day', a.time), 
    DATE_PART('month', a.time)
ORDER BY 
    month ASC, 
    day ASC;

