-- Insert Data Model for Users Table
-- This script inserts records into data_models and data_model_fields for the existing users table

BEGIN;

-- Step 1: Get the app_id for "app_studio" (or the app where data models should be registered)
-- If app_studio doesn't exist, you may need to create it first or use NULL
DO $$
DECLARE
    v_app_id INTEGER;
    v_system_user_id INTEGER;
    v_model_id INTEGER;
    v_text_field_type_id INTEGER;
    v_uuid_field_type_id INTEGER;
    v_timestamp_field_type_id INTEGER;
    v_boolean_field_type_id INTEGER;
    v_integer_field_type_id INTEGER;
BEGIN
    -- Get app_id for app_studio (adjust app_name if different)
    SELECT app_id INTO v_app_id 
    FROM public.apps 
    WHERE app_name = 'app_studio' 
    LIMIT 1;
    
    -- If app_studio doesn't exist, you can use NULL or create the app first
    -- For now, we'll use NULL if not found
    IF v_app_id IS NULL THEN
        RAISE NOTICE 'App "app_studio" not found. Using NULL for app_id.';
    END IF;
    
    -- Get system user for created_by
    SELECT user_id INTO v_system_user_id 
    FROM public.users 
    WHERE user_type = 'system' 
    LIMIT 1;
    
    IF v_system_user_id IS NULL THEN
        RAISE EXCEPTION 'System user not found. Please create a system user first.';
    END IF;
    
    -- Get field type IDs (these should exist from seed data)
    SELECT field_type_id INTO v_text_field_type_id FROM public.field_types WHERE type_code = 'text' LIMIT 1;
    SELECT field_type_id INTO v_uuid_field_type_id FROM public.field_types WHERE type_code = 'uuid' LIMIT 1;
    SELECT field_type_id INTO v_timestamp_field_type_id FROM public.field_types WHERE type_code = 'timestamp' LIMIT 1;
    SELECT field_type_id INTO v_boolean_field_type_id FROM public.field_types WHERE type_code = 'boolean' LIMIT 1;
    SELECT field_type_id INTO v_integer_field_type_id FROM public.field_types WHERE type_code = 'integer' LIMIT 1;
    
    -- If field types don't exist, use defaults (you may need to adjust based on your field_types table)
    IF v_text_field_type_id IS NULL THEN
        -- Try to get any text-like field type
        SELECT field_type_id INTO v_text_field_type_id 
        FROM public.field_types 
        WHERE actual_db_type IN ('VARCHAR', 'TEXT') 
        LIMIT 1;
    END IF;
    
    -- Step 2: Insert into data_models
    INSERT INTO public.data_models (
        app_id,
        model_name,
        display_name,
        table_name,
        use_case,
        is_public,
        is_system_model,
        is_active,
        description,
        icon,
        created_by
    ) VALUES (
        v_app_id,
        'users',
        'Users',
        'users',
        'system',
        FALSE,
        TRUE,
        TRUE,
        'User management table - stores user accounts and authentication information',
        'user',
        v_system_user_id
    )
    ON CONFLICT (app_id, model_name) DO NOTHING
    RETURNING model_id INTO v_model_id;
    
    -- If model already exists, get its ID
    IF v_model_id IS NULL THEN
        SELECT model_id INTO v_model_id 
        FROM public.data_models 
        WHERE model_name = 'users' 
        AND (app_id = v_app_id OR (app_id IS NULL AND v_app_id IS NULL))
        LIMIT 1;
    END IF;
    
    IF v_model_id IS NULL THEN
        RAISE EXCEPTION 'Failed to create or find data model for users';
    END IF;
    
    -- Step 3: Insert fields into data_model_fields
    -- Primary Key
    INSERT INTO public.data_model_fields (
        model_id, field_name, display_name, field_type_id, 
        is_required, is_unique, is_primary_key, order_no
    ) VALUES (
        v_model_id, 'user_id', 'User ID', COALESCE(v_integer_field_type_id, 1),
        TRUE, TRUE, TRUE, 1
    ) ON CONFLICT DO NOTHING;
    
    -- UUID
    INSERT INTO public.data_model_fields (
        model_id, field_name, display_name, field_type_id, 
        is_required, is_unique, order_no
    ) VALUES (
        v_model_id, 'user_uuid', 'User UUID', COALESCE(v_uuid_field_type_id, 1),
        TRUE, TRUE, 2
    ) ON CONFLICT DO NOTHING;
    
    -- Username
    INSERT INTO public.data_model_fields (
        model_id, field_name, display_name, field_type_id, 
        is_required, is_unique, order_no, field_config_json
    ) VALUES (
        v_model_id, 'username', 'Username', COALESCE(v_text_field_type_id, 1),
        TRUE, TRUE, 3, '{"max_length": 100}'::jsonb
    ) ON CONFLICT DO NOTHING;
    
    -- Password
    INSERT INTO public.data_model_fields (
        model_id, field_name, display_name, field_type_id, 
        is_required, order_no, field_config_json
    ) VALUES (
        v_model_id, 'password', 'Password', COALESCE(v_text_field_type_id, 1),
        TRUE, 4, '{"max_length": 120, "is_password": true}'::jsonb
    ) ON CONFLICT DO NOTHING;
    
    -- First Name
    INSERT INTO public.data_model_fields (
        model_id, field_name, display_name, field_type_id, 
        order_no, field_config_json
    ) VALUES (
        v_model_id, 'first_name', 'First Name', COALESCE(v_text_field_type_id, 1),
        5, '{"max_length": 100}'::jsonb
    ) ON CONFLICT DO NOTHING;
    
    -- Last Name
    INSERT INTO public.data_model_fields (
        model_id, field_name, display_name, field_type_id, 
        order_no, field_config_json
    ) VALUES (
        v_model_id, 'last_name', 'Last Name', COALESCE(v_text_field_type_id, 1),
        6, '{"max_length": 100}'::jsonb
    ) ON CONFLICT DO NOTHING;
    
    -- Email
    INSERT INTO public.data_model_fields (
        model_id, field_name, display_name, field_type_id, 
        order_no, field_config_json
    ) VALUES (
        v_model_id, 'email', 'Email', COALESCE(v_text_field_type_id, 1),
        7, '{"max_length": 100, "validation": "email"}'::jsonb
    ) ON CONFLICT DO NOTHING;
    
    -- Phone
    INSERT INTO public.data_model_fields (
        model_id, field_name, display_name, field_type_id, 
        order_no, field_config_json
    ) VALUES (
        v_model_id, 'phone', 'Phone', COALESCE(v_text_field_type_id, 1),
        8, '{"max_length": 20}'::jsonb
    ) ON CONFLICT DO NOTHING;
    
    -- Avatar URL
    INSERT INTO public.data_model_fields (
        model_id, field_name, display_name, field_type_id, 
        order_no, field_config_json
    ) VALUES (
        v_model_id, 'avatar_url', 'Avatar URL', COALESCE(v_text_field_type_id, 1),
        9, '{"validation": "url"}'::jsonb
    ) ON CONFLICT DO NOTHING;
    
    -- User Type
    INSERT INTO public.data_model_fields (
        model_id, field_name, display_name, field_type_id, 
        is_required, order_no, field_config_json
    ) VALUES (
        v_model_id, 'user_type', 'User Type', COALESCE(v_text_field_type_id, 1),
        TRUE, 10, '{"max_length": 20, "options": ["saas_admin", "saas_employee", "saas_reseller", "saas_promoter", "tenant_admin", "tenant_user", "system"]}'::jsonb
    ) ON CONFLICT DO NOTHING;
    
    -- Is Super Admin
    INSERT INTO public.data_model_fields (
        model_id, field_name, display_name, field_type_id, 
        order_no, default_value
    ) VALUES (
        v_model_id, 'is_super_admin', 'Is Super Admin', COALESCE(v_boolean_field_type_id, 1),
        11, 'false'
    ) ON CONFLICT DO NOTHING;
    
    -- Active Status
    INSERT INTO public.data_model_fields (
        model_id, field_name, display_name, field_type_id, 
        is_required, order_no, default_value, field_config_json
    ) VALUES (
        v_model_id, 'active_status', 'Active Status', COALESCE(v_integer_field_type_id, 1),
        TRUE, 12, '1', '{"options": [{"label": "Inactive", "value": 0}, {"label": "Active", "value": 1}, {"label": "Suspended", "value": 2}]}'::jsonb
    ) ON CONFLICT DO NOTHING;
    
    -- Last Login
    INSERT INTO public.data_model_fields (
        model_id, field_name, display_name, field_type_id, 
        order_no
    ) VALUES (
        v_model_id, 'last_login', 'Last Login', COALESCE(v_timestamp_field_type_id, 1),
        13
    ) ON CONFLICT DO NOTHING;
    
    -- Created By
    INSERT INTO public.data_model_fields (
        model_id, field_name, display_name, field_type_id, 
        order_no
    ) VALUES (
        v_model_id, 'created_by', 'Created By', COALESCE(v_integer_field_type_id, 1),
        14
    ) ON CONFLICT DO NOTHING;
    
    -- Created Date
    INSERT INTO public.data_model_fields (
        model_id, field_name, display_name, field_type_id, 
        is_required, order_no
    ) VALUES (
        v_model_id, 'idate', 'Created Date', COALESCE(v_timestamp_field_type_id, 1),
        TRUE, 15
    ) ON CONFLICT DO NOTHING;
    
    -- Last Updated
    INSERT INTO public.data_model_fields (
        model_id, field_name, display_name, field_type_id, 
        is_required, order_no
    ) VALUES (
        v_model_id, 'last_updated', 'Last Updated', COALESCE(v_timestamp_field_type_id, 1),
        TRUE, 16
    ) ON CONFLICT DO NOTHING;
    
    RAISE NOTICE 'Successfully inserted data model for users table. Model ID: %', v_model_id;
END $$;

COMMIT;

-- Verification query
-- SELECT dm.model_id, dm.model_name, dm.display_name, dm.table_name, COUNT(dmf.field_id) as field_count
-- FROM public.data_models dm
-- LEFT JOIN public.data_model_fields dmf ON dm.model_id = dmf.model_id
-- WHERE dm.model_name = 'users'
-- GROUP BY dm.model_id, dm.model_name, dm.display_name, dm.table_name;
