-- Update field_types default_props_json for Single Choice and Multiple Choice
-- This updates the default props to support options_mode: foreign_key, collections, or custom_collection
--
-- options_mode can be:
--   - "collections": Use a collection from the collections table (requires collection_id)
--   - "foreign_key": Use data from a table.column (requires table_column and optionally display_columns)
--   - "custom_collection": Use inline options array (requires options array)
--
-- Example configurations:
--   Collections: {"options_mode": "collections", "collection_id": 1}
--   Foreign Key: {"options_mode": "foreign_key", "table_column": "users.user_id", "display_columns": "first_name + ' ' + last_name"}
--   Custom: {"options_mode": "custom_collection", "options": [{"label": "Option 1", "value": "opt1"}]}

-- Update Single Choice field type
UPDATE public.field_types
SET default_props_json = '{
  "options_mode": "custom_collection",
  "options": []
}'::jsonb
WHERE type_name = 'Single Choice' OR type_code = 'single_choice';

-- Update Multiple Choice field type
UPDATE public.field_types
SET default_props_json = '{
  "options_mode": "custom_collection",
  "options": []
}'::jsonb
WHERE type_name = 'Multiple Choice' OR type_code = 'multi_choice';

-- Verify the updates
SELECT 
    field_type_id,
    type_name,
    type_code,
    default_props_json
FROM public.field_types
WHERE type_name IN ('Single Choice', 'Multiple Choice')
   OR type_code IN ('single_choice', 'multi_choice')
ORDER BY type_name;
