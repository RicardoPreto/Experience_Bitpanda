-- Selecting the eligible users for the campaign
SELECT
    tx.user_id AS user_count,
    SUM(tx.euro_amount) AS stake_amount
FROM 
    NEW_SCHEMA.FINANCE.TRANSACTIONS tx
JOIN 
    NEW_SCHEMA.MASTER.ASSETS asset 
    ON asset.asset_id = tx.asset_id
LEFT JOIN 
    NEW_SCHEMA.EVENTS.USER_EVENTS event 
    ON event.user_id = tx.user_id
LEFT JOIN 
    NEW_SCHEMA.PROFILES.USER_RFM profile 
    ON event.user_id = profile.user_id
WHERE 
    event.user_type = 'normal'
    AND event.domain = 'bitpanda'
    AND tx.created_at >= '2024-08-29 00:00'
    AND tx.created_at <= '2024-09-05 23:59'
    AND tx.operation_type = 'stake'
    AND event.verification_level = '4'
    AND profile.m_stage NOT IN ('Employee - not eligible for RFM')
    AND event.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey')
GROUP BY ALL
HAVING stake_amount >= 50;


-- Ranking coins
WITH eligible_users AS (
    SELECT 
        tx.user_id, 
        asset.asset_symbol, 
        ROW_NUMBER() OVER (PARTITION BY tx.user_id ORDER BY tx.created_at ASC) AS stake_order
    FROM 
        NEW_SCHEMA.FINANCE.TRANSACTIONS tx
    JOIN 
        NEW_SCHEMA.MASTER.ASSETS asset 
        ON asset.asset_id = tx.asset_id
    LEFT JOIN 
        NEW_SCHEMA.EVENTS.USER_EVENTS event 
        ON event.user_id = tx.user_id
    LEFT JOIN 
        NEW_SCHEMA.PROFILES.USER_RFM profile 
        ON event.user_id = profile.user_id
    WHERE 
        event.user_type = 'normal'
        AND event.domain = 'bitpanda'
        AND tx.created_at >= '2024-08-29 00:00'
        AND tx.created_at <= '2024-09-05 23:59'
        AND tx.operation_type = 'stake'
        AND event.verification_level = '4'
        AND profile.m_stage NOT IN ('Employee - not eligible for RFM')
        AND event.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey')
    GROUP BY 
        tx.user_id, asset.asset_symbol, tx.created_at
    HAVING 
        SUM(tx.euro_amount) >= 50
    QUALIFY 
        stake_order = 1
)

SELECT 
    asset_symbol,
    COUNT(DISTINCT user_id) / (SUM(COUNT(DISTINCT user_id)) OVER ()) * 100 AS perc_stakers
FROM 
    eligible_users
GROUP BY 
    asset_symbol
ORDER BY 
    perc_stakers DESC;


-- Selecting New Stakers
WITH eligible_users AS (
    SELECT
        tx.user_id,
        SUM(tx.euro_amount) AS stake_amount
    FROM 
        NEW_SCHEMA.FINANCE.TRANSACTIONS tx
    JOIN 
        NEW_SCHEMA.MASTER.ASSETS asset 
        ON asset.asset_id = tx.asset_id
    LEFT JOIN 
        NEW_SCHEMA.EVENTS.USER_EVENTS event 
        ON event.user_id = tx.user_id
    LEFT JOIN 
        NEW_SCHEMA.PROFILES.USER_RFM profile 
        ON event.user_id = profile.user_id
    WHERE 
        event.user_type = 'normal'
        AND event.domain = 'bitpanda'
        AND tx.created_at >= '2024-08-29 00:00'
        AND tx.created_at <= '2024-09-05 23:59'
        AND tx.operation_type = 'stake'
        AND event.verification_level = '4'
        AND profile.m_stage NOT IN ('Employee - not eligible for RFM')
        AND event.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey')
    GROUP BY ALL
    HAVING stake_amount >= 50
)

SELECT 
    COUNT(DISTINCT eligible_users.user_id) AS total_users, 
    SUM(tx.euro_amount) AS stake_amount_eur
FROM 
    NEW_SCHEMA.FINANCE.TRANSACTIONS tx
JOIN 
    NEW_SCHEMA.MASTER.ASSETS asset 
    ON asset.asset_id = tx.asset_id 
LEFT JOIN 
    NEW_SCHEMA.EVENTS.USER_EVENTS event 
    ON event.user_id = tx.user_id
LEFT JOIN 
    NEW_SCHEMA.PROFILES.USER_RFM profile 
    ON event.user_id = profile.user_id
JOIN 
    eligible_users 
    ON eligible_users.user_id = tx.user_id
WHERE 
    event.user_type = 'normal'
    AND event.domain = 'bitpanda'
    AND tx.created_at >= '2024-08-29 00:00'
    AND tx.created_at <= '2024-09-05 23:59'
    AND tx.operation_type = 'stake'
    AND event.verification_level = '4'
    AND profile.m_stage NOT IN ('Employee - not eligible for RFM')
    AND event.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey') 
    AND tx.user_id NOT IN (
        SELECT DISTINCT tx_sub.user_id 
        FROM NEW_SCHEMA.FINANCE.TRANSACTIONS tx_sub 
        LEFT JOIN NEW_SCHEMA.MASTER.ASSETS asset_sub 
        ON asset_sub.asset_id = tx_sub.asset_id 
        WHERE tx_sub.created_at < '2024-08-29 00:00' 
        AND tx_sub.operation_type = 'stake'
    );


-- Selecting market data during the campaign period
SELECT 
    COUNT(DISTINCT CASE WHEN tx.operation_type = 'stake' THEN tx.user_id ELSE NULL END) AS total_users_staking,
    SUM(CASE WHEN tx.operation_type = 'stake' THEN tx.euro_amount ELSE 0 END) / 
    COUNT(DISTINCT CASE WHEN tx.operation_type = 'stake' THEN tx.user_id ELSE NULL END) AS average_stake,
    SUM(CASE WHEN tx.operation_type = 'stake' THEN tx.euro_amount ELSE 0 END) AS stake_amount,
    SUM(tx.euro_amount) AS stake_volume
FROM 
    NEW_SCHEMA.FINANCE.TRANSACTIONS tx
JOIN 
    NEW_SCHEMA.MASTER.ASSETS asset 
    ON asset.asset_id = tx.asset_id
LEFT JOIN 
    NEW_SCHEMA.EVENTS.USER_EVENTS event 
    ON event.user_id = tx.user_id
LEFT JOIN 
    NEW_SCHEMA.PROFILES.USER_RFM profile 
    ON event.user_id = profile.user_id
WHERE 
    event.user_type = 'normal'
    AND event.domain = 'bitpanda'
    AND tx.created_at >= '2024-08-29 00:00'
    AND tx.created_at <= '2024-09-05 23:59'
    AND tx.operation_type IN ('stake', 'unstake')
    AND event.verification_level = '4'
    AND profile.m_stage NOT IN ('Employee - not eligible for RFM')
    AND event.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey')
ORDER BY 
    stake_amount ASC;


-- Selecting unstakers after campaign period to analyze retention
WITH eligible_users AS (
    SELECT
        tx.user_id,
        SUM(tx.euro_amount) AS stake_amount
    FROM 
        NEW_SCHEMA.FINANCE.TRANSACTIONS tx
    JOIN 
        NEW_SCHEMA.MASTER.ASSETS asset 
        ON asset.asset_id = tx.asset_id
    LEFT JOIN 
        NEW_SCHEMA.EVENTS.USER_EVENTS event 
        ON event.user_id = tx.user_id
    LEFT JOIN 
        NEW_SCHEMA.PROFILES.USER_RFM profile 
        ON event.user_id = profile.user_id
    WHERE 
        event.user_type = 'normal'
        AND event.domain = 'bitpanda'
        AND tx.created_at >= '2024-08-29 00:00'
        AND tx.created_at <= '2024-09-05 23:59'
        AND tx.operation_type = 'stake'
        AND event.verification_level = '4'
        AND profile.m_stage NOT IN ('Employee - not eligible for RFM')
        AND event.country_res NOT IN ('Netherlands', 'Belgium', 'United Kingdom', 'Turkey')
    GROUP BY ALL
    HAVING stake_amount >= 50
)

SELECT 
    COUNT(DISTINCT CASE WHEN tx.euro_amount >= eligible_users.stake_amount THEN eligible_users.user_id ELSE NULL END) AS stakers
FROM 
    eligible_users
JOIN 
    NEW_SCHEMA.FINANCE.TRANSACTIONS tx
    ON tx.user_id = eligible_users.user_id
LEFT JOIN 
    NEW_SCHEMA.EVENTS.USER_EVENTS event 
    ON event.user_id = tx.user_id
LEFT JOIN 
    NEW_SCHEMA.PROFILES.USER_RFM profile 
    ON event.user_id = profile.user_id
WHERE 
    event.user_type = 'normal'
    AND event.domain = 'bitpanda'
    AND tx.created_at >= '2024-09-06 00:00'
    AND tx
