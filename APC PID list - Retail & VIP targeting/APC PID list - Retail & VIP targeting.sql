-- Not VIP Users
SELECT DISTINCT 
    user_events.user_id, 
    user_events.user_language
FROM 
    user_data.user_events user_events
LEFT JOIN 
    user_data.user_rfm user_rfm 
    ON user_rfm.user_id = user_events.user_id
WHERE 
    UPPER(user_events.user_language) IN ('ENG', 'DEU', 'FRA', 'ITA', 'IT', 'SPA')
    AND user_rfm.bitpanda_club IS NULL
    AND user_events.platform = 'bitpanda';

-- VIP Users
SELECT DISTINCT 
    user_events.user_id, 
    user_events.user_language
FROM 
    user_data.user_events user_events
LEFT JOIN 
    user_data.user_rfm user_rfm 
    ON user_rfm.user_id = user_events.user_id
WHERE 
    UPPER(user_events.user_language) IN ('ENG', 'DEU', 'FRA', 'ITA', 'IT')
    AND user_rfm.vip_flag = TRUE
    AND user_events.platform = 'bitpanda';
``
