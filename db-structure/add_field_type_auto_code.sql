-- Add "Auto Code" field type to field_types table
-- This field type automatically generates codes based on a pattern when saving records

INSERT INTO public.field_types (
    type_name,
    type_code,
    category,
    actual_db_type,
    default_props_json,
    default_component_type_id,
    is_active
)
SELECT 
    'Auto Code',
    'auto_code',
    'advanced',
    'VARCHAR',
    '{
        "pattern": [
            {"type": "prefix", "value": "CODE"},
            {"type": "separator", "value": "-"},
            {"type": "date", "format": "YYYY-MM"},
            {"type": "separator", "value": "-"},
            {"type": "increment", "padding": 4, "start": 1}
        ]
    }'::jsonb,
    (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'text'),
    TRUE
WHERE NOT EXISTS (
    SELECT 1 FROM public.field_types 
    WHERE type_code = 'auto_code' OR type_name = 'Auto Code'
);

-- Verify the insertion
SELECT 
    field_type_id,
    type_name,
    type_code,
    category,
    actual_db_type,
    default_props_json
FROM public.field_types
WHERE type_code = 'auto_code'
ORDER BY type_name;

-- Pattern structure documentation:
-- The pattern is an array of objects, each with a "type" field:
--
-- 1. "prefix" - Static string prefix
--    {"type": "prefix", "value": "AT"}
--
-- 2. "date" - Current date with dayjs format
--    {"type": "date", "format": "YYYY-MM"} or {"type": "date", "format": "MMD"}
--    Supported formats: Any dayjs format (YYYY, MM, DD, YYYY-MM, MMD, etc.)
--
-- 3. "increment" - Auto-incrementing number
--    {"type": "increment", "padding": 4, "start": 1}
--    - padding: Number of digits (pads with zeros, e.g., 4 = "0001", "0002")
--    - start: Starting number (default: 1)
--
-- 4. "separator" - Static separator string
--    {"type": "separator", "value": "-"} or {"type": "separator", "value": "/"}
--
-- Example patterns:
--   ["AT-{YYYY-MM}-{0001}"] -> AT-2024-01-0001, AT-2024-01-0002
--   ["{YYYYMMDD}-{AT}-{0001}"] -> 20240115-AT-0001, 20240115-AT-0002
--   ["ATS{MMD}{0001}"] -> ATS01150001, ATS01150002
