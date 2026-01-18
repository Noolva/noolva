-- Insert Data Models for user_groups, teams, roles, and companies tables
-- This script inserts records into data_models and data_model_fields for the existing tables
-- Each model is in its own transaction to prevent one failure from aborting all

-- ==========================================
-- 1. USER GROUPS Data Model
-- ==========================================
BEGIN;
DO $$
DECLARE
    v_app_id INTEGER;
    v_system_user_id INTEGER;
    v_model_id INTEGER;
    v_text_field_type_id INTEGER;
    v_uuid_field_type_id INTEGER;
    v_timestamp_field_type_id INTEGER;
    v_integer_field_type_id INTEGER;
BEGIN
    -- Get app_id for app_studio
    SELECT app_id INTO v_app_id 
    FROM public.apps 
    WHERE app_name = 'app_studio' 
    LIMIT 1;
    
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
    
    -- Get field type IDs
    SELECT field_type_id INTO v_text_field_type_id FROM public.field_types WHERE type_code = 'text' LIMIT 1;
    SELECT field_type_id INTO v_uuid_field_type_id FROM public.field_types WHERE type_code = 'uuid' LIMIT 1;
    SELECT field_type_id INTO v_timestamp_field_type_id FROM public.field_types WHERE type_code = 'timestamp' LIMIT 1;
    SELECT field_type_id INTO v_integer_field_type_id FROM public.field_types WHERE type_code = 'integer' LIMIT 1;
    
    -- Fallback for text if type_code doesn't exist
    IF v_text_field_type_id IS NULL THEN
        SELECT field_type_id INTO v_text_field_type_id 
        FROM public.field_types 
        WHERE actual_db_type IN ('VARCHAR', 'TEXT') 
        LIMIT 1;
    END IF;
    
    -- Fallback for uuid
    IF v_uuid_field_type_id IS NULL THEN
        SELECT field_type_id INTO v_uuid_field_type_id 
        FROM public.field_types 
        WHERE actual_db_type = 'UUID' 
        LIMIT 1;
    END IF;
    
    -- Fallback for timestamp
    IF v_timestamp_field_type_id IS NULL THEN
        SELECT field_type_id INTO v_timestamp_field_type_id 
        FROM public.field_types 
        WHERE actual_db_type IN ('TIMESTAMP', 'TIMESTAMP WITHOUT TIME ZONE') 
        LIMIT 1;
    END IF;
    
    -- Fallback for integer
    IF v_integer_field_type_id IS NULL THEN
        SELECT field_type_id INTO v_integer_field_type_id 
        FROM public.field_types 
        WHERE actual_db_type IN ('INTEGER', 'INT', 'SERIAL') 
        LIMIT 1;
    END IF;
    
    -- Ensure we have at least one field type
    IF v_text_field_type_id IS NULL AND v_integer_field_type_id IS NULL THEN
        RAISE EXCEPTION 'No field types found. Please ensure field_types table has data.';
    END IF;
    
    -- Insert into data_models
    INSERT INTO public.data_models (
        app_id, model_name, display_name, table_name, use_case,
        is_public, is_system_model, is_active, description, icon, created_by
    ) VALUES (
        v_app_id, 'user_groups', 'User Groups', 'user_groups', 'system',
        FALSE, TRUE, TRUE, 'User groups table - organizes users into groups within a company',
        'team', v_system_user_id
    )
    ON CONFLICT (app_id, model_name) DO NOTHING
    RETURNING model_id INTO v_model_id;
    
    IF v_model_id IS NULL THEN
        SELECT model_id INTO v_model_id 
        FROM public.data_models 
        WHERE model_name = 'user_groups' 
        AND (app_id = v_app_id OR (app_id IS NULL AND v_app_id IS NULL))
        LIMIT 1;
    END IF;
    
    IF v_model_id IS NULL THEN
        RAISE EXCEPTION 'Failed to create or find data model for user_groups';
    END IF;
    
    -- Insert fields
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, is_unique, is_primary_key, order_no)
    VALUES (v_model_id, 'group_id', 'Group ID', COALESCE(v_integer_field_type_id, v_text_field_type_id, 1), TRUE, TRUE, TRUE, 1) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, is_unique, order_no)
    VALUES (v_model_id, 'group_uuid', 'Group UUID', COALESCE(v_uuid_field_type_id, v_text_field_type_id, 1), TRUE, TRUE, 2) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, order_no, field_config_json)
    VALUES (v_model_id, 'group_name', 'Group Name', COALESCE(v_text_field_type_id, 1), TRUE, 3, '{"max_length": 100}'::jsonb) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, order_no, field_config_json)
    VALUES (v_model_id, 'group_description', 'Group Description', COALESCE(v_text_field_type_id, 1), 4, '{"max_length": 1000}'::jsonb) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, order_no)
    VALUES (v_model_id, 'company_id', 'Company ID', COALESCE(v_integer_field_type_id, v_text_field_type_id, 1), TRUE, 5) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, order_no)
    VALUES (v_model_id, 'created_by', 'Created By', COALESCE(v_integer_field_type_id, v_text_field_type_id, 1), 6) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, order_no)
    VALUES (v_model_id, 'idate', 'Created Date', COALESCE(v_timestamp_field_type_id, v_text_field_type_id, 1), TRUE, 7) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, order_no)
    VALUES (v_model_id, 'last_updated', 'Last Updated', COALESCE(v_timestamp_field_type_id, v_text_field_type_id, 1), TRUE, 8) 
    ON CONFLICT DO NOTHING;
    
    RAISE NOTICE 'Successfully inserted data model for user_groups table. Model ID: %', v_model_id;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Error inserting user_groups data model: %', SQLERRM;
    RAISE;
END $$;
COMMIT;

-- ==========================================
-- 2. TEAMS Data Model
-- ==========================================
BEGIN;
DO $$
DECLARE
    v_app_id INTEGER;
    v_system_user_id INTEGER;
    v_model_id INTEGER;
    v_text_field_type_id INTEGER;
    v_uuid_field_type_id INTEGER;
    v_timestamp_field_type_id INTEGER;
    v_integer_field_type_id INTEGER;
BEGIN
    SELECT app_id INTO v_app_id FROM public.apps WHERE app_name = 'app_studio' LIMIT 1;
    IF v_app_id IS NULL THEN RAISE NOTICE 'App "app_studio" not found. Using NULL for app_id.'; END IF;
    
    SELECT user_id INTO v_system_user_id FROM public.users WHERE user_type = 'system' LIMIT 1;
    IF v_system_user_id IS NULL THEN RAISE EXCEPTION 'System user not found.'; END IF;
    
    SELECT field_type_id INTO v_text_field_type_id FROM public.field_types WHERE type_code = 'text' LIMIT 1;
    SELECT field_type_id INTO v_uuid_field_type_id FROM public.field_types WHERE type_code = 'uuid' LIMIT 1;
    SELECT field_type_id INTO v_timestamp_field_type_id FROM public.field_types WHERE type_code = 'timestamp' LIMIT 1;
    SELECT field_type_id INTO v_integer_field_type_id FROM public.field_types WHERE type_code = 'integer' LIMIT 1;
    
    IF v_text_field_type_id IS NULL THEN
        SELECT field_type_id INTO v_text_field_type_id FROM public.field_types WHERE actual_db_type IN ('VARCHAR', 'TEXT') LIMIT 1;
    END IF;
    IF v_uuid_field_type_id IS NULL THEN
        SELECT field_type_id INTO v_uuid_field_type_id FROM public.field_types WHERE actual_db_type = 'UUID' LIMIT 1;
    END IF;
    IF v_timestamp_field_type_id IS NULL THEN
        SELECT field_type_id INTO v_timestamp_field_type_id FROM public.field_types WHERE actual_db_type IN ('TIMESTAMP', 'TIMESTAMP WITHOUT TIME ZONE') LIMIT 1;
    END IF;
    IF v_integer_field_type_id IS NULL THEN
        SELECT field_type_id INTO v_integer_field_type_id FROM public.field_types WHERE actual_db_type IN ('INTEGER', 'INT', 'SERIAL') LIMIT 1;
    END IF;
    
    INSERT INTO public.data_models (
        app_id, model_name, display_name, table_name, use_case,
        is_public, is_system_model, is_active, description, icon, created_by
    ) VALUES (
        v_app_id, 'teams', 'Teams', 'teams', 'system',
        FALSE, TRUE, TRUE, 'Teams table - organizes users into teams with hierarchy and management',
        'team', v_system_user_id
    )
    ON CONFLICT (app_id, model_name) DO NOTHING
    RETURNING model_id INTO v_model_id;
    
    IF v_model_id IS NULL THEN
        SELECT model_id INTO v_model_id FROM public.data_models 
        WHERE model_name = 'teams' AND (app_id = v_app_id OR (app_id IS NULL AND v_app_id IS NULL)) LIMIT 1;
    END IF;
    
    IF v_model_id IS NULL THEN RAISE EXCEPTION 'Failed to create or find data model for teams'; END IF;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, is_unique, is_primary_key, order_no)
    VALUES (v_model_id, 'team_id', 'Team ID', COALESCE(v_integer_field_type_id, v_text_field_type_id, 1), TRUE, TRUE, TRUE, 1) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, is_unique, order_no)
    VALUES (v_model_id, 'team_uuid', 'Team UUID', COALESCE(v_uuid_field_type_id, v_text_field_type_id, 1), TRUE, TRUE, 2) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, order_no, field_config_json)
    VALUES (v_model_id, 'team_name', 'Team Name', COALESCE(v_text_field_type_id, 1), TRUE, 3, '{"max_length": 100}'::jsonb) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, order_no, field_config_json)
    VALUES (v_model_id, 'team_description', 'Team Description', COALESCE(v_text_field_type_id, 1), 4, '{"max_length": 1000}'::jsonb) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, order_no)
    VALUES (v_model_id, 'company_id', 'Company ID', COALESCE(v_integer_field_type_id, v_text_field_type_id, 1), TRUE, 5) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, order_no)
    VALUES (v_model_id, 'parent_team_id', 'Parent Team ID', COALESCE(v_integer_field_type_id, v_text_field_type_id, 1), 6) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, order_no)
    VALUES (v_model_id, 'manager_id', 'Manager ID', COALESCE(v_integer_field_type_id, v_text_field_type_id, 1), 7) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, order_no)
    VALUES (v_model_id, 'created_by', 'Created By', COALESCE(v_integer_field_type_id, v_text_field_type_id, 1), 8) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, order_no)
    VALUES (v_model_id, 'idate', 'Created Date', COALESCE(v_timestamp_field_type_id, v_text_field_type_id, 1), TRUE, 9) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, order_no)
    VALUES (v_model_id, 'last_updated', 'Last Updated', COALESCE(v_timestamp_field_type_id, v_text_field_type_id, 1), TRUE, 10) 
    ON CONFLICT DO NOTHING;
    
    RAISE NOTICE 'Successfully inserted data model for teams table. Model ID: %', v_model_id;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Error inserting teams data model: %', SQLERRM;
    RAISE;
END $$;
COMMIT;

-- ==========================================
-- 3. ROLES Data Model
-- ==========================================
BEGIN;
DO $$
DECLARE
    v_app_id INTEGER;
    v_system_user_id INTEGER;
    v_model_id INTEGER;
    v_text_field_type_id INTEGER;
    v_uuid_field_type_id INTEGER;
    v_timestamp_field_type_id INTEGER;
    v_integer_field_type_id INTEGER;
    v_boolean_field_type_id INTEGER;
BEGIN
    SELECT app_id INTO v_app_id FROM public.apps WHERE app_name = 'app_studio' LIMIT 1;
    IF v_app_id IS NULL THEN RAISE NOTICE 'App "app_studio" not found. Using NULL for app_id.'; END IF;
    
    SELECT user_id INTO v_system_user_id FROM public.users WHERE user_type = 'system' LIMIT 1;
    IF v_system_user_id IS NULL THEN RAISE EXCEPTION 'System user not found.'; END IF;
    
    SELECT field_type_id INTO v_text_field_type_id FROM public.field_types WHERE type_code = 'text' LIMIT 1;
    SELECT field_type_id INTO v_uuid_field_type_id FROM public.field_types WHERE type_code = 'uuid' LIMIT 1;
    SELECT field_type_id INTO v_timestamp_field_type_id FROM public.field_types WHERE type_code = 'timestamp' LIMIT 1;
    SELECT field_type_id INTO v_integer_field_type_id FROM public.field_types WHERE type_code = 'integer' LIMIT 1;
    SELECT field_type_id INTO v_boolean_field_type_id FROM public.field_types WHERE type_code = 'boolean' LIMIT 1;
    
    IF v_text_field_type_id IS NULL THEN
        SELECT field_type_id INTO v_text_field_type_id FROM public.field_types WHERE actual_db_type IN ('VARCHAR', 'TEXT') LIMIT 1;
    END IF;
    IF v_uuid_field_type_id IS NULL THEN
        SELECT field_type_id INTO v_uuid_field_type_id FROM public.field_types WHERE actual_db_type = 'UUID' LIMIT 1;
    END IF;
    IF v_timestamp_field_type_id IS NULL THEN
        SELECT field_type_id INTO v_timestamp_field_type_id FROM public.field_types WHERE actual_db_type IN ('TIMESTAMP', 'TIMESTAMP WITHOUT TIME ZONE') LIMIT 1;
    END IF;
    IF v_integer_field_type_id IS NULL THEN
        SELECT field_type_id INTO v_integer_field_type_id FROM public.field_types WHERE actual_db_type IN ('INTEGER', 'INT', 'SERIAL') LIMIT 1;
    END IF;
    IF v_boolean_field_type_id IS NULL THEN
        SELECT field_type_id INTO v_boolean_field_type_id FROM public.field_types WHERE actual_db_type IN ('BOOLEAN', 'BOOL') LIMIT 1;
    END IF;
    
    INSERT INTO public.data_models (
        app_id, model_name, display_name, table_name, use_case,
        is_public, is_system_model, is_active, description, icon, created_by
    ) VALUES (
        v_app_id, 'roles', 'Roles', 'roles', 'system',
        FALSE, TRUE, TRUE, 'Roles table - defines role-based access control roles',
        'safety', v_system_user_id
    )
    ON CONFLICT (app_id, model_name) DO NOTHING
    RETURNING model_id INTO v_model_id;
    
    IF v_model_id IS NULL THEN
        SELECT model_id INTO v_model_id FROM public.data_models 
        WHERE model_name = 'roles' AND (app_id = v_app_id OR (app_id IS NULL AND v_app_id IS NULL)) LIMIT 1;
    END IF;
    
    IF v_model_id IS NULL THEN RAISE EXCEPTION 'Failed to create or find data model for roles'; END IF;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, is_unique, is_primary_key, order_no)
    VALUES (v_model_id, 'role_id', 'Role ID', COALESCE(v_integer_field_type_id, v_text_field_type_id, 1), TRUE, TRUE, TRUE, 1) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, is_unique, order_no)
    VALUES (v_model_id, 'role_uuid', 'Role UUID', COALESCE(v_uuid_field_type_id, v_text_field_type_id, 1), TRUE, TRUE, 2) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, order_no, field_config_json)
    VALUES (v_model_id, 'role_name', 'Role Name', COALESCE(v_text_field_type_id, 1), TRUE, 3, '{"max_length": 100}'::jsonb) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, order_no, field_config_json)
    VALUES (v_model_id, 'role_key', 'Role Key', COALESCE(v_text_field_type_id, 1), TRUE, 4, '{"max_length": 100}'::jsonb) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, order_no, field_config_json)
    VALUES (v_model_id, 'role_description', 'Role Description', COALESCE(v_text_field_type_id, 1), 5, '{"max_length": 1000}'::jsonb) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, order_no)
    VALUES (v_model_id, 'company_id', 'Company ID', COALESCE(v_integer_field_type_id, v_text_field_type_id, 1), 6) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, order_no, default_value)
    VALUES (v_model_id, 'is_system_role', 'Is System Role', COALESCE(v_boolean_field_type_id, v_integer_field_type_id, 1), 7, 'false') 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, order_no)
    VALUES (v_model_id, 'created_by', 'Created By', COALESCE(v_integer_field_type_id, v_text_field_type_id, 1), 8) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, order_no)
    VALUES (v_model_id, 'idate', 'Created Date', COALESCE(v_timestamp_field_type_id, v_text_field_type_id, 1), TRUE, 9) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, order_no)
    VALUES (v_model_id, 'last_updated', 'Last Updated', COALESCE(v_timestamp_field_type_id, v_text_field_type_id, 1), TRUE, 10) 
    ON CONFLICT DO NOTHING;
    
    RAISE NOTICE 'Successfully inserted data model for roles table. Model ID: %', v_model_id;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Error inserting roles data model: %', SQLERRM;
    RAISE;
END $$;
COMMIT;

-- ==========================================
-- 4. COMPANIES Data Model
-- ==========================================
BEGIN;
DO $$
DECLARE
    v_app_id INTEGER;
    v_system_user_id INTEGER;
    v_model_id INTEGER;
    v_text_field_type_id INTEGER;
    v_uuid_field_type_id INTEGER;
    v_timestamp_field_type_id INTEGER;
    v_integer_field_type_id INTEGER;
    v_boolean_field_type_id INTEGER;
    v_jsonb_field_type_id INTEGER;
BEGIN
    SELECT app_id INTO v_app_id FROM public.apps WHERE app_name = 'app_studio' LIMIT 1;
    IF v_app_id IS NULL THEN RAISE NOTICE 'App "app_studio" not found. Using NULL for app_id.'; END IF;
    
    SELECT user_id INTO v_system_user_id FROM public.users WHERE user_type = 'system' LIMIT 1;
    IF v_system_user_id IS NULL THEN RAISE EXCEPTION 'System user not found.'; END IF;
    
    SELECT field_type_id INTO v_text_field_type_id FROM public.field_types WHERE type_code = 'text' LIMIT 1;
    SELECT field_type_id INTO v_uuid_field_type_id FROM public.field_types WHERE type_code = 'uuid' LIMIT 1;
    SELECT field_type_id INTO v_timestamp_field_type_id FROM public.field_types WHERE type_code = 'timestamp' LIMIT 1;
    SELECT field_type_id INTO v_integer_field_type_id FROM public.field_types WHERE type_code = 'integer' LIMIT 1;
    SELECT field_type_id INTO v_boolean_field_type_id FROM public.field_types WHERE type_code = 'boolean' LIMIT 1;
    SELECT field_type_id INTO v_jsonb_field_type_id FROM public.field_types WHERE type_code = 'jsonb' LIMIT 1;
    
    IF v_text_field_type_id IS NULL THEN
        SELECT field_type_id INTO v_text_field_type_id FROM public.field_types WHERE actual_db_type IN ('VARCHAR', 'TEXT') LIMIT 1;
    END IF;
    IF v_uuid_field_type_id IS NULL THEN
        SELECT field_type_id INTO v_uuid_field_type_id FROM public.field_types WHERE actual_db_type = 'UUID' LIMIT 1;
    END IF;
    IF v_timestamp_field_type_id IS NULL THEN
        SELECT field_type_id INTO v_timestamp_field_type_id FROM public.field_types WHERE actual_db_type IN ('TIMESTAMP', 'TIMESTAMP WITHOUT TIME ZONE') LIMIT 1;
    END IF;
    IF v_integer_field_type_id IS NULL THEN
        SELECT field_type_id INTO v_integer_field_type_id FROM public.field_types WHERE actual_db_type IN ('INTEGER', 'INT', 'SERIAL') LIMIT 1;
    END IF;
    IF v_boolean_field_type_id IS NULL THEN
        SELECT field_type_id INTO v_boolean_field_type_id FROM public.field_types WHERE actual_db_type IN ('BOOLEAN', 'BOOL') LIMIT 1;
    END IF;
    IF v_jsonb_field_type_id IS NULL THEN
        SELECT field_type_id INTO v_jsonb_field_type_id FROM public.field_types WHERE actual_db_type = 'JSONB' LIMIT 1;
    END IF;
    
    INSERT INTO public.data_models (
        app_id, model_name, display_name, table_name, use_case,
        is_public, is_system_model, is_active, description, icon, created_by
    ) VALUES (
        v_app_id, 'companies', 'Companies', 'companies', 'system',
        FALSE, TRUE, TRUE, 'Companies table - manages company/organization entities within tenants',
        'bank', v_system_user_id
    )
    ON CONFLICT (app_id, model_name) DO NOTHING
    RETURNING model_id INTO v_model_id;
    
    IF v_model_id IS NULL THEN
        SELECT model_id INTO v_model_id FROM public.data_models 
        WHERE model_name = 'companies' AND (app_id = v_app_id OR (app_id IS NULL AND v_app_id IS NULL)) LIMIT 1;
    END IF;
    
    IF v_model_id IS NULL THEN RAISE EXCEPTION 'Failed to create or find data model for companies'; END IF;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, is_unique, is_primary_key, order_no)
    VALUES (v_model_id, 'company_id', 'Company ID', COALESCE(v_integer_field_type_id, v_text_field_type_id, 1), TRUE, TRUE, TRUE, 1) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, is_unique, order_no)
    VALUES (v_model_id, 'company_uuid', 'Company UUID', COALESCE(v_uuid_field_type_id, v_text_field_type_id, 1), TRUE, TRUE, 2) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, order_no)
    VALUES (v_model_id, 'tenant_id', 'Tenant ID', COALESCE(v_integer_field_type_id, v_text_field_type_id, 1), TRUE, 3) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, order_no, field_config_json)
    VALUES (v_model_id, 'company_name', 'Company Name', COALESCE(v_text_field_type_id, 1), TRUE, 4, '{"max_length": 200}'::jsonb) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, is_unique, order_no, field_config_json)
    VALUES (v_model_id, 'company_code', 'Company Code', COALESCE(v_text_field_type_id, 1), TRUE, TRUE, 5, '{"max_length": 50}'::jsonb) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, order_no, field_config_json)
    VALUES (v_model_id, 'domain', 'Domain', COALESCE(v_text_field_type_id, 1), 6, '{"max_length": 100, "validation": "domain"}'::jsonb) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, order_no, field_config_json)
    VALUES (v_model_id, 'logo_url', 'Logo URL', COALESCE(v_text_field_type_id, 1), 7, '{"validation": "url"}'::jsonb) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, order_no)
    VALUES (v_model_id, 'branding_config', 'Branding Config', COALESCE(v_jsonb_field_type_id, v_text_field_type_id, 1), 8) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, order_no)
    VALUES (v_model_id, 'parent_company_id', 'Parent Company ID', COALESCE(v_integer_field_type_id, v_text_field_type_id, 1), 9) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, order_no, default_value)
    VALUES (v_model_id, 'is_default', 'Is Default', COALESCE(v_boolean_field_type_id, v_integer_field_type_id, 1), 10, 'false') 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, order_no, default_value)
    VALUES (v_model_id, 'is_active', 'Is Active', COALESCE(v_boolean_field_type_id, v_integer_field_type_id, 1), 11, 'true') 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, order_no)
    VALUES (v_model_id, 'created_by', 'Created By', COALESCE(v_integer_field_type_id, v_text_field_type_id, 1), 12) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, order_no)
    VALUES (v_model_id, 'idate', 'Created Date', COALESCE(v_timestamp_field_type_id, v_text_field_type_id, 1), TRUE, 13) 
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.data_model_fields (model_id, field_name, display_name, field_type_id, is_required, order_no)
    VALUES (v_model_id, 'last_updated', 'Last Updated', COALESCE(v_timestamp_field_type_id, v_text_field_type_id, 1), TRUE, 14) 
    ON CONFLICT DO NOTHING;
    
    RAISE NOTICE 'Successfully inserted data model for companies table. Model ID: %', v_model_id;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Error inserting companies data model: %', SQLERRM;
    RAISE;
END $$;
COMMIT;

-- Verification queries
-- SELECT dm.model_id, dm.model_name, dm.display_name, dm.table_name, COUNT(dmf.field_id) as field_count
-- FROM public.data_models dm
-- LEFT JOIN public.data_model_fields dmf ON dm.model_id = dmf.model_id
-- WHERE dm.model_name IN ('user_groups', 'teams', 'roles', 'companies')
-- GROUP BY dm.model_id, dm.model_name, dm.display_name, dm.table_name
-- ORDER BY dm.model_name;
