-- update_old_db_api_endpoints.sql
-- Migration: Update api_endpoints table schema
-- - Remove: flattening_rule_id, custom_logic_json
-- - Add: reference_model_ids (INTEGER[]), custom_json (JSONB)
-- Run this on existing databases before applying full schema reload

-- 1. Add new columns (if not exist)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'api_endpoints' AND column_name = 'reference_model_ids'
    ) THEN
        ALTER TABLE public.api_endpoints ADD COLUMN reference_model_ids INTEGER[] DEFAULT '{}';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'api_endpoints' AND column_name = 'custom_json'
    ) THEN
        ALTER TABLE public.api_endpoints ADD COLUMN custom_json JSONB DEFAULT '{}'::jsonb;
    END IF;
END $$;

-- 2. Migrate data: set reference_model_ids from related_model_id where applicable
UPDATE public.api_endpoints
SET reference_model_ids = ARRAY[related_model_id]
WHERE related_model_id IS NOT NULL
  AND (reference_model_ids IS NULL OR reference_model_ids = '{}');

-- 3. Migrate custom_logic_json to custom_json (if custom_logic_json had data)
UPDATE public.api_endpoints
SET custom_json = jsonb_build_object('query', custom_logic_json->>'query', 'joins', COALESCE(custom_logic_json->'joins', '[]'::jsonb))
WHERE custom_logic_json IS NOT NULL
  AND type = 'custom_query';

-- 4. Drop old columns (only if they exist)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'api_endpoints' AND column_name = 'flattening_rule_id'
    ) THEN
        ALTER TABLE public.api_endpoints DROP CONSTRAINT IF EXISTS api_endpoints_flattening_rule_id_fkey;
        ALTER TABLE public.api_endpoints DROP COLUMN flattening_rule_id;
    END IF;
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'api_endpoints' AND column_name = 'custom_logic_json'
    ) THEN
        ALTER TABLE public.api_endpoints DROP COLUMN custom_logic_json;
    END IF;
END $$;
