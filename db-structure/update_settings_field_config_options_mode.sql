-- Update settings field_config_json to add options_mode for existing records
-- This adds "options_mode": "custom_collection" to settings that have options array
-- but are missing the options_mode field

-- Update settings with Single Choice field type
UPDATE public.settings s
SET field_config_json = 
    CASE 
        -- If field_config_json has options but no options_mode, add options_mode
        WHEN s.field_config_json ? 'options' 
             AND NOT (s.field_config_json ? 'options_mode')
        THEN s.field_config_json || '{"options_mode": "custom_collection"}'::jsonb
        
        -- If field_config_json exists but has no options key, add both
        WHEN s.field_config_json IS NOT NULL 
             AND NOT (s.field_config_json ? 'options')
             AND NOT (s.field_config_json ? 'options_mode')
        THEN s.field_config_json || '{"options_mode": "custom_collection", "options": []}'::jsonb
        
        -- Otherwise keep as is
        ELSE s.field_config_json
    END
WHERE s.field_type_id IN (
    SELECT field_type_id 
    FROM public.field_types 
    WHERE type_code IN ('single_choice', 'multi_choice')
)
AND (
    -- Has options but no options_mode
    (s.field_config_json ? 'options' AND NOT (s.field_config_json ? 'options_mode'))
    OR
    -- Has no options_mode at all (will set default)
    NOT (s.field_config_json ? 'options_mode')
);

-- Update settings with Multiple Choice field type (same logic)
-- Note: The above query already handles both single_choice and multi_choice

-- Verify the updates
SELECT 
    s.setting_id,
    s.setting_key,
    s.setting_name,
    ft.type_code AS field_type_code,
    s.field_config_json,
    CASE 
        WHEN s.field_config_json ? 'options_mode' THEN 'Has options_mode'
        ELSE 'Missing options_mode'
    END AS options_mode_status
FROM public.settings s
LEFT JOIN public.field_types ft ON ft.field_type_id = s.field_type_id
WHERE ft.type_code IN ('single_choice', 'multi_choice')
ORDER BY s.setting_key;
