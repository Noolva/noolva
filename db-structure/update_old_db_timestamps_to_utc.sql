-- Update existing databases: Convert all timestamp columns to TIMESTAMPTZ (UTC)
-- Run this on existing databases to enforce UTC everywhere
--
-- IMPORTANT: Replace YOUR_DB_NAME and YOUR_DB_USER with your actual database and role names
-- before running. Or run these manually:
--   ALTER DATABASE noolvandb SET timezone = 'UTC';
--   ALTER ROLE noolva_user SET timezone = 'UTC';

-- ==========================================
-- 1. Set Database and Role Timezone to UTC
-- ==========================================
-- Uncomment and replace placeholders:
-- ALTER DATABASE YOUR_DB_NAME SET timezone = 'UTC';
-- ALTER ROLE YOUR_DB_USER SET timezone = 'UTC';

-- ==========================================
-- 2. Convert All Timestamp Columns to TIMESTAMPTZ
-- ==========================================
-- Existing timestamps are treated as UTC during conversion (USING ... AT TIME ZONE 'UTC')

-- ai_events
ALTER TABLE public.ai_events ALTER COLUMN occurred_at TYPE TIMESTAMPTZ USING occurred_at AT TIME ZONE 'UTC';
ALTER TABLE public.ai_events ALTER COLUMN recorded_at TYPE TIMESTAMPTZ USING recorded_at AT TIME ZONE 'UTC';

-- ai_knowledge_nodes
ALTER TABLE public.ai_knowledge_nodes ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'UTC';
ALTER TABLE public.ai_knowledge_nodes ALTER COLUMN updated_at TYPE TIMESTAMPTZ USING updated_at AT TIME ZONE 'UTC';

-- ai_knowledge_relations
ALTER TABLE public.ai_knowledge_relations ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'UTC';

-- ai_knowledge_vectors
ALTER TABLE public.ai_knowledge_vectors ALTER COLUMN updated_at TYPE TIMESTAMPTZ USING updated_at AT TIME ZONE 'UTC';

-- ai_query_plans
ALTER TABLE public.ai_query_plans ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'UTC';

-- ai_rules
ALTER TABLE public.ai_rules ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'UTC';
ALTER TABLE public.ai_rules ALTER COLUMN updated_at TYPE TIMESTAMPTZ USING updated_at AT TIME ZONE 'UTC';

-- api_endpoints
ALTER TABLE public.api_endpoints ALTER COLUMN last_updated TYPE TIMESTAMPTZ USING last_updated AT TIME ZONE 'UTC';
ALTER TABLE public.api_endpoints ALTER COLUMN idate TYPE TIMESTAMPTZ USING idate AT TIME ZONE 'UTC';

-- app_views
ALTER TABLE public.app_views ALTER COLUMN idate TYPE TIMESTAMPTZ USING idate AT TIME ZONE 'UTC';
ALTER TABLE public.app_views ALTER COLUMN last_updated TYPE TIMESTAMPTZ USING last_updated AT TIME ZONE 'UTC';

-- apps
ALTER TABLE public.apps ALTER COLUMN last_updated TYPE TIMESTAMPTZ USING last_updated AT TIME ZONE 'UTC';
ALTER TABLE public.apps ALTER COLUMN idate TYPE TIMESTAMPTZ USING idate AT TIME ZONE 'UTC';

-- archival_policies
ALTER TABLE public.archival_policies ALTER COLUMN last_updated TYPE TIMESTAMPTZ USING last_updated AT TIME ZONE 'UTC';

-- assets
ALTER TABLE public.assets ALTER COLUMN uploaded_at TYPE TIMESTAMPTZ USING uploaded_at AT TIME ZONE 'UTC';

-- audit_logs (partitioned table - alters parent and partitions)
ALTER TABLE public.audit_logs ALTER COLUMN event_time TYPE TIMESTAMPTZ USING event_time AT TIME ZONE 'UTC';

-- audit_logs_default (partition - may need separate alter if not inherited)
-- Note: For partitioned tables, altering the parent alters partitions. If you get an error, 
-- the partition may inherit from parent. Try running just the audit_logs alter above first.

-- collections
ALTER TABLE public.collections ALTER COLUMN last_updated TYPE TIMESTAMPTZ USING last_updated AT TIME ZONE 'UTC';
ALTER TABLE public.collections ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'UTC';

-- companies
ALTER TABLE public.companies ALTER COLUMN idate TYPE TIMESTAMPTZ USING idate AT TIME ZONE 'UTC';
ALTER TABLE public.companies ALTER COLUMN last_updated TYPE TIMESTAMPTZ USING last_updated AT TIME ZONE 'UTC';

-- data_flattening_rules
ALTER TABLE public.data_flattening_rules ALTER COLUMN last_updated TYPE TIMESTAMPTZ USING last_updated AT TIME ZONE 'UTC';

-- data_model_fields
ALTER TABLE public.data_model_fields ALTER COLUMN idate TYPE TIMESTAMPTZ USING idate AT TIME ZONE 'UTC';

-- data_models
ALTER TABLE public.data_models ALTER COLUMN idate TYPE TIMESTAMPTZ USING idate AT TIME ZONE 'UTC';
ALTER TABLE public.data_models ALTER COLUMN last_updated TYPE TIMESTAMPTZ USING last_updated AT TIME ZONE 'UTC';

-- field_types
ALTER TABLE public.field_types ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'UTC';

-- icons
ALTER TABLE public.icons ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'UTC';
ALTER TABLE public.icons ALTER COLUMN last_updated TYPE TIMESTAMPTZ USING last_updated AT TIME ZONE 'UTC';

-- integration_providers
ALTER TABLE public.integration_providers ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'UTC';
ALTER TABLE public.integration_providers ALTER COLUMN last_updated TYPE TIMESTAMPTZ USING last_updated AT TIME ZONE 'UTC';

-- integrations
ALTER TABLE public.integrations ALTER COLUMN last_updated TYPE TIMESTAMPTZ USING last_updated AT TIME ZONE 'UTC';

-- job_queue
ALTER TABLE public.job_queue ALTER COLUMN started_at TYPE TIMESTAMPTZ USING started_at AT TIME ZONE 'UTC';
ALTER TABLE public.job_queue ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'UTC';
ALTER TABLE public.job_queue ALTER COLUMN completed_at TYPE TIMESTAMPTZ USING completed_at AT TIME ZONE 'UTC';

-- menus
ALTER TABLE public.menus ALTER COLUMN last_updated TYPE TIMESTAMPTZ USING last_updated AT TIME ZONE 'UTC';
ALTER TABLE public.menus ALTER COLUMN idate TYPE TIMESTAMPTZ USING idate AT TIME ZONE 'UTC';

-- module_features
ALTER TABLE public.module_features ALTER COLUMN last_updated TYPE TIMESTAMPTZ USING last_updated AT TIME ZONE 'UTC';
ALTER TABLE public.module_features ALTER COLUMN idate TYPE TIMESTAMPTZ USING idate AT TIME ZONE 'UTC';

-- modules
ALTER TABLE public.modules ALTER COLUMN idate TYPE TIMESTAMPTZ USING idate AT TIME ZONE 'UTC';
ALTER TABLE public.modules ALTER COLUMN last_updated TYPE TIMESTAMPTZ USING last_updated AT TIME ZONE 'UTC';

-- products (user-created data model - skip if table does not exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'products') THEN
    ALTER TABLE public.products ALTER COLUMN idate TYPE TIMESTAMPTZ USING idate AT TIME ZONE 'UTC';
    ALTER TABLE public.products ALTER COLUMN last_updated TYPE TIMESTAMPTZ USING last_updated AT TIME ZONE 'UTC';
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'products' AND column_name = 'test_date_time') THEN
      ALTER TABLE public.products ALTER COLUMN test_date_time TYPE TIMESTAMPTZ USING test_date_time AT TIME ZONE 'UTC';
    END IF;
  END IF;
END $$;

-- role_module_features
ALTER TABLE public.role_module_features ALTER COLUMN granted_at TYPE TIMESTAMPTZ USING granted_at AT TIME ZONE 'UTC';

-- roles
ALTER TABLE public.roles ALTER COLUMN last_updated TYPE TIMESTAMPTZ USING last_updated AT TIME ZONE 'UTC';
ALTER TABLE public.roles ALTER COLUMN idate TYPE TIMESTAMPTZ USING idate AT TIME ZONE 'UTC';

-- settings
ALTER TABLE public.settings ALTER COLUMN last_updated TYPE TIMESTAMPTZ USING last_updated AT TIME ZONE 'UTC';

-- teams
ALTER TABLE public.teams ALTER COLUMN last_updated TYPE TIMESTAMPTZ USING last_updated AT TIME ZONE 'UTC';
ALTER TABLE public.teams ALTER COLUMN idate TYPE TIMESTAMPTZ USING idate AT TIME ZONE 'UTC';

-- tenants
ALTER TABLE public.tenants ALTER COLUMN last_updated TYPE TIMESTAMPTZ USING last_updated AT TIME ZONE 'UTC';
ALTER TABLE public.tenants ALTER COLUMN subscription_expires_at TYPE TIMESTAMPTZ USING subscription_expires_at AT TIME ZONE 'UTC';
ALTER TABLE public.tenants ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'UTC';

-- ui_component_types
ALTER TABLE public.ui_component_types ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'UTC';

-- user_account_profiles
ALTER TABLE public.user_account_profiles ALTER COLUMN last_used TYPE TIMESTAMPTZ USING last_used AT TIME ZONE 'UTC';
ALTER TABLE public.user_account_profiles ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'UTC';

-- user_companies
ALTER TABLE public.user_companies ALTER COLUMN joined_at TYPE TIMESTAMPTZ USING joined_at AT TIME ZONE 'UTC';

-- user_group_members
ALTER TABLE public.user_group_members ALTER COLUMN added_at TYPE TIMESTAMPTZ USING added_at AT TIME ZONE 'UTC';

-- user_groups
ALTER TABLE public.user_groups ALTER COLUMN idate TYPE TIMESTAMPTZ USING idate AT TIME ZONE 'UTC';
ALTER TABLE public.user_groups ALTER COLUMN last_updated TYPE TIMESTAMPTZ USING last_updated AT TIME ZONE 'UTC';

-- user_module_features
ALTER TABLE public.user_module_features ALTER COLUMN granted_at TYPE TIMESTAMPTZ USING granted_at AT TIME ZONE 'UTC';
ALTER TABLE public.user_module_features ALTER COLUMN expiration TYPE TIMESTAMPTZ USING expiration AT TIME ZONE 'UTC';

-- user_roles
ALTER TABLE public.user_roles ALTER COLUMN assigned_at TYPE TIMESTAMPTZ USING assigned_at AT TIME ZONE 'UTC';

-- user_sessions
ALTER TABLE public.user_sessions ALTER COLUMN expires_at TYPE TIMESTAMPTZ USING expires_at AT TIME ZONE 'UTC';
ALTER TABLE public.user_sessions ALTER COLUMN last_activity TYPE TIMESTAMPTZ USING last_activity AT TIME ZONE 'UTC';
ALTER TABLE public.user_sessions ALTER COLUMN login_at TYPE TIMESTAMPTZ USING login_at AT TIME ZONE 'UTC';

-- user_teams
ALTER TABLE public.user_teams ALTER COLUMN joined_at TYPE TIMESTAMPTZ USING joined_at AT TIME ZONE 'UTC';

-- users
ALTER TABLE public.users ALTER COLUMN last_login TYPE TIMESTAMPTZ USING last_login AT TIME ZONE 'UTC';
ALTER TABLE public.users ALTER COLUMN last_updated TYPE TIMESTAMPTZ USING last_updated AT TIME ZONE 'UTC';
ALTER TABLE public.users ALTER COLUMN idate TYPE TIMESTAMPTZ USING idate AT TIME ZONE 'UTC';
ALTER TABLE public.users ALTER COLUMN deleted_at TYPE TIMESTAMPTZ USING deleted_at AT TIME ZONE 'UTC';

-- workflow_runs
ALTER TABLE public.workflow_runs ALTER COLUMN completed_at TYPE TIMESTAMPTZ USING completed_at AT TIME ZONE 'UTC';
ALTER TABLE public.workflow_runs ALTER COLUMN started_at TYPE TIMESTAMPTZ USING started_at AT TIME ZONE 'UTC';

-- workflows
ALTER TABLE public.workflows ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'UTC';
ALTER TABLE public.workflows ALTER COLUMN updated_at TYPE TIMESTAMPTZ USING updated_at AT TIME ZONE 'UTC';

-- ==========================================
-- 3. Update Field Types (for new datetime columns)
-- ==========================================
-- Ensures new tables created via Data Models API use TIMESTAMPTZ for datetime fields
UPDATE public.field_types 
SET actual_db_type = 'TIMESTAMPTZ' 
WHERE type_code = 'datetime';

-- ==========================================
-- 4. Dynamically Created Tables (Data Models)
-- ==========================================
-- For tables created via the Data Models API, run similar ALTERs.
-- Example for a custom table "your_table" with created_at, updated_at:
--
-- ALTER TABLE public.your_table ALTER COLUMN idate TYPE TIMESTAMPTZ USING idate AT TIME ZONE 'UTC';
-- ALTER TABLE public.your_table ALTER COLUMN last_updated TYPE TIMESTAMPTZ USING last_updated AT TIME ZONE 'UTC';
--
-- To migrate ALL user-created data model tables automatically:
/*
DO $$
DECLARE
  r RECORD;
  col RECORD;
BEGIN
  FOR r IN 
    SELECT t.table_name 
    FROM information_schema.tables t
    WHERE t.table_schema = 'public' 
      AND t.table_type = 'BASE TABLE'
      AND t.table_name NOT IN (
        SELECT table_name FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name IN ('users','tenants','companies','user_companies','user_sessions','user_account_profiles','user_groups','user_group_members','teams','user_teams','apps','modules','module_features','menus','roles','user_roles','role_module_features','user_module_features','menu_permissions','data_models','ui_component_types','field_types','collections','icons','data_model_fields','field_permissions','model_row_access_policies','app_views','archival_policies','audit_logs','audit_logs_default','data_flattening_rules','api_endpoints','actions','workflows','workflow_runs','job_queue','integration_providers','integrations','assets','settings','ai_knowledge_nodes','ai_knowledge_relations','ai_events','ai_knowledge_vectors','ai_query_plans','ai_entity_aliases','ai_rules')
      )
  LOOP
    FOR col IN 
      SELECT column_name FROM information_schema.columns 
      WHERE table_schema = 'public' AND table_name = r.table_name 
      AND data_type = 'timestamp without time zone'
    LOOP
      EXECUTE format('ALTER TABLE public.%I ALTER COLUMN %I TYPE TIMESTAMPTZ USING %I AT TIME ZONE ''UTC''', r.table_name, col.column_name, col.column_name);
    END LOOP;
  END LOOP;
END $$;
*/
