-- Migration: row_exposure_modes, row_exposure_mode_id on models, settings.user_uuid, current_user_mode setting
-- Run this on existing databases to add new tables/columns and backfill metadata.

-- ==========================================
-- 1. Create row_exposure_modes table (if not exists)
-- ==========================================
CREATE TABLE IF NOT EXISTS public.row_exposure_modes (
    exposure_mode_id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE,
    description TEXT,
    expose_data BOOLEAN DEFAULT FALSE
);
-- Ensure unique on name for existing tables that may have been created without it
ALTER TABLE public.row_exposure_modes DROP CONSTRAINT IF EXISTS row_exposure_modes_name_key;
ALTER TABLE public.row_exposure_modes ADD CONSTRAINT row_exposure_modes_name_key UNIQUE (name);

-- ==========================================
-- 2. Add user_uuid to settings
-- ==========================================
ALTER TABLE public.settings
ADD COLUMN IF NOT EXISTS user_uuid UUID REFERENCES public.users(user_uuid) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_settings_user_uuid ON public.settings(user_uuid);

-- Drop old unique constraint (name may vary)
ALTER TABLE public.settings DROP CONSTRAINT IF EXISTS settings_setting_key_tenant_id_key;
ALTER TABLE public.settings DROP CONSTRAINT IF EXISTS settings_setting_key_tenant_id_key1;

-- Add partial unique indexes: one global row per (key, tenant); one per user per (key, tenant)
DROP INDEX IF EXISTS public.idx_settings_key_tenant_user_global;
DROP INDEX IF EXISTS public.idx_settings_key_tenant_user_specific;
CREATE UNIQUE INDEX idx_settings_key_tenant_user_global ON public.settings (setting_key, tenant_id) WHERE user_uuid IS NULL;
CREATE UNIQUE INDEX idx_settings_key_tenant_user_specific ON public.settings (setting_key, tenant_id, user_uuid) WHERE user_uuid IS NOT NULL;

-- ==========================================
-- 3. Add row_exposure_mode_id to every table that has a data_model
-- ==========================================
DO $$
DECLARE
    r RECORD;
    tbl regclass;
BEGIN
    FOR r IN
        SELECT model_id, table_name
        FROM public.data_models
        WHERE is_active = TRUE
    LOOP
        BEGIN
            EXECUTE format(
                'ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS row_exposure_mode_id INTEGER REFERENCES public.row_exposure_modes(exposure_mode_id)',
                r.table_name
            );
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not add row_exposure_mode_id to %.%: %', 'public', r.table_name, SQLERRM;
        END;
    END LOOP;
END $$;

-- ==========================================
-- 4. Insert row_exposure_mode_id into data_model_fields for each model
-- ==========================================
DO $$
DECLARE
    r RECORD;
    ft_number_id INT;
    max_order INT;
BEGIN
    SELECT field_type_id INTO ft_number_id FROM public.field_types WHERE type_code = 'number' LIMIT 1;
    IF ft_number_id IS NULL THEN
        RAISE NOTICE 'field_types number not found; skipping data_model_fields insert for row_exposure_mode_id';
        RETURN;
    END IF;

    FOR r IN
        SELECT model_id FROM public.data_models WHERE is_active = TRUE
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM public.data_model_fields
            WHERE model_id = r.model_id AND field_name = 'row_exposure_mode_id'
        ) THEN
            SELECT COALESCE(MAX(order_no), 0) + 1 INTO max_order
            FROM public.data_model_fields WHERE model_id = r.model_id;

            INSERT INTO public.data_model_fields (
                model_id, field_name, display_name, field_type_id,
                field_config_json, is_required, is_unique, is_primary_key,
                default_value, encryption_method, ui_component, order_no
            ) VALUES (
                r.model_id,
                'row_exposure_mode_id',
                'Row Exposure Mode',
                ft_number_id,
                '{}'::jsonb,
                FALSE,
                FALSE,
                FALSE,
                NULL,
                'none',
                NULL,
                max_order
            );
        END IF;
    END LOOP;
END $$;

-- ==========================================
-- 5. Insert "Current User Mode" setting (definition row, user_uuid NULL)
-- ==========================================
DO $$
DECLARE
    ft_single_choice_id INT;
BEGIN
    SELECT field_type_id INTO ft_single_choice_id FROM public.field_types WHERE type_code = 'single_choice' LIMIT 1;
    IF ft_single_choice_id IS NULL THEN
        SELECT field_type_id INTO ft_single_choice_id FROM public.field_types WHERE type_code = 'number' LIMIT 1;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.settings WHERE setting_key = 'current_user_mode' AND tenant_id IS NULL AND user_uuid IS NULL) THEN
        INSERT INTO public.settings (
            group_name, setting_key, setting_name, description,
            field_type_id, default_value, value, scope, tenant_id, user_uuid, is_built_in, field_config_json
        ) VALUES (
            'General',
            'current_user_mode',
            'Current User Mode',
            'When set, auto CRUD list returns only rows whose row_exposure_mode matches this mode and expose_data is Yes. Null = show all.',
            ft_single_choice_id,
            NULL,
            NULL,
            'global',
            NULL,
            NULL,
            TRUE,
            '{"options_source": "row_exposure_modes"}'::jsonb
        );
    END IF;
EXCEPTION
    WHEN unique_violation THEN NULL;
    WHEN OTHERS THEN
        RAISE NOTICE 'Insert current_user_mode setting: %', SQLERRM;
END $$;
