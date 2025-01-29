-- Selecting users to understand Spotlight traders behavior

WITH first_trade AS (
    SELECT
        trade.user_id, 
        trade.asset_symbol, 
        trade.time,
        ROW_NUMBER() OVER (PARTITION BY trade.user_id ORDER BY trade.time ASC) AS row_num
    FROM 
        NEW_SCHEMA.TRADING.TRADES_BROKER trade
    JOIN 
        NEW_SCHEMA.EVENTS.USER_EVENTS event 
        ON event.user_id = trade.user_id
    WHERE 
        trade.domain = 'bitpanda' 
        AND event.user_type = 'normal'
        AND event.verification_level = '4'
        AND trade.spotlight_asset = TRUE
    QUALIFY 
        row_num = 1
),

launchpad_subscriptions AS (
    SELECT
        sub.user_id,
        MIN(sub.created_at) AS subscription_time
    FROM 
        NEW_SCHEMA.ENGAGEMENT.LAUNCHPAD_SUBSCRIPTIONS sub
    JOIN 
        NEW_SCHEMA.ENGAGEMENT.LAUNCHPAD_ASSETS asset 
        ON sub.launchpad_asset_id = asset.asset_id
    WHERE 
        asset.symbol IN ('CGPT')
    GROUP BY 
        sub.user_id
)

SELECT 
    COUNT(DISTINCT launchpad_subscriptions.user_id) AS total_subscribers,
    COUNT(DISTINCT CASE WHEN launchpad_subscriptions.subscription_time >= first_trade.time THEN first_trade.user_id END) AS traded_spotlight_before,
    COUNT(DISTINCT CASE WHEN launchpad_subscriptions.subscription_time < first_trade.time THEN first_trade.user_id END) AS traded_spotlight_after,
    COUNT(DISTINCT CASE WHEN first_trade.user_id IS NULL THEN launchpad_subscriptions.user_id END) AS never_traded_spotlight,
    COUNT(DISTINCT CASE WHEN first_trade.user_id IS NULL THEN launchpad_subscriptions.user_id END) * 1.0 / 
    COUNT(DISTINCT launchpad_subscriptions.user_id) AS never_traded_spotlight_ratio
FROM 
    launchpad_subscriptions
LEFT JOIN 
    first_trade 
    ON first_trade.user_id = launchpad_subscriptions.user_id;
