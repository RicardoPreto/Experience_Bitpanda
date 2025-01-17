-- Selecting the eligible users
WITH duplicates AS (
    SELECT
        pid, 
        MIN(variant) AS variant_new
    FROM 
        marketing_campaigns.camp_payday_4
    GROUP BY 
        pid
)
SELECT 
    duplicates.pid, 
    duplicates.variant_new, 
    user_events.country_res
FROM 
    duplicates
LEFT JOIN 
    user_events_data user_events 
    ON user_events.pid = duplicates.pid;

-- 