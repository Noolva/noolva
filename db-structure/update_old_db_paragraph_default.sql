-- Update existing databases: Set paragraph field type default max_line_counts to 3
-- Run this on existing databases to add max_line_counts default for paragraph field type

UPDATE public.field_types
SET default_props_json = COALESCE(default_props_json, '{}'::jsonb) || '{"max_line_counts": 3}'::jsonb
WHERE type_code = 'paragraph';
