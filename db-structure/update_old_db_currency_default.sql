-- Update existing databases: Set currency field type default to Indian Rupee (₹)
-- Run this on existing databases to update the currency default from USD ($) to INR (₹)

UPDATE public.field_types
SET default_props_json = jsonb_set(
    COALESCE(default_props_json, '{}'::jsonb),
    '{currency_symbol}',
    '"₹"'
)
WHERE type_code = 'currency';
