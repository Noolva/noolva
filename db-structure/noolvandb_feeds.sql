-- noolvandb_feeds.sql
-- Essential Seed Data
-- This file contains essential seed data required for the system to function
-- Execute this after noolvandb_schema.sql

-- ==========================================
-- 1. UI Component Types
-- ==========================================
-- Standard UI Components (Layouts, Inputs, Displays)
INSERT INTO public.ui_component_types (type_code, type_name, category, props_schema_json) VALUES
-- Layouts
('row', 'Row', 'layout', '{"gutter": {"type": "number", "default": 24}, "justify": {"type": "string", "options": ["start","center","end"]}, "align": {"type": "string"}}'),
('column', 'Column', 'layout', '{"span": {"type": "number", "default": 24}, "offset": {"type": "number"}}'),
('divider', 'Divider', 'layout', '{"orientation": {"type": "string", "default": "horizontal"}}'),

-- Containers
('form', 'Form', 'container', '{"layout": {"type": "string", "options": ["horizontal","vertical","inline"]}, "size": {"type": "string"}}'),
('card', 'Card', 'container', '{"title": {"type": "string"}, "bordered": {"type": "boolean"}}'),

-- Inputs
('text', 'Text Input', 'input', '{"label": "string", "place_holder": "string", "default_value": "string", "validation_type": "string"}'),
('textarea', 'Text Area', 'input', '{"rows": "number", "label": "string"}'),
('number', 'Number Input', 'input', '{"min": "number", "max": "number", "label": "string"}'),
('select', 'Select Dropdown', 'input', '{"mode": "string", "options": "array", "label": "string"}'),
('date', 'Date Picker', 'input', '{"format": "string", "label": "string"}'),
('switch', 'Switch', 'input', '{"label": "string", "checked_children": "string", "un_checked_children": "string"}'),
('checkbox', 'Checkbox', 'input', '{"label": "string"}'),
('radio', 'Radio Group', 'input', '{"options": "array", "label": "string"}'),
('upload', 'File Upload', 'input', '{"multiple": "boolean", "accept": "string", "label": "string"}'),

-- Displays
('label', 'Label', 'display', '{"default_value": "string", "strong": "boolean"}'),
('table', 'Table', 'display', '{"columns": "array", "pagination": "boolean"}'),
('statistic', 'Statistic', 'display', '{"title": "string", "value": "number", "precision": "number"}'),
('tag', 'Tag', 'display', '{"color": "string"}'),
('badge', 'Badge', 'display', '{"count": "number", "color": "string"}'),
('image', 'Image', 'display', '{"src": "string", "alt": "string", "width": "number"}'),
('link', 'Link', 'display', '{"href": "string", "target": "string"}'),
('progress', 'Progress', 'display', '{"percent": "number", "status": "string"}')
ON CONFLICT (type_code) DO NOTHING;

-- ==========================================
-- 2. Field Types
-- ==========================================
-- Standard Field Types for the Dynamic Data System
INSERT INTO public.field_types (type_name, type_code, category, actual_db_type, default_props_json, default_component_type_id) VALUES
-- Basic Text
('Text', 'text', 'basic', 'VARCHAR', '{"max_length": 255}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'text')),
('Paragraph', 'paragraph', 'basic', 'TEXT', '{}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'textarea')),

-- Numbers
('Number', 'number', 'basic', 'NUMERIC', '{"precision": 10, "scale": 2}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'number')),
('Auto Number', 'auto_number', 'advanced', 'SERIAL', '{}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'label')),
('Currency', 'currency', 'advanced', 'NUMERIC', '{"currency_symbol": "$", "precision": 10, "scale": 2}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'number')),
('Percentage', 'percentage', 'advanced', 'NUMERIC', '{"precision": 5, "scale": 2}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'number')),
('Rating', 'rating', 'advanced', 'INTEGER', '{"max_stars": 5}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'number')),

-- Dates & Time
('Date', 'date', 'basic', 'DATE', '{}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'date')),
('DateTime', 'datetime', 'basic', 'TIMESTAMP', '{}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'date')),
('Time', 'time', 'basic', 'TIME', '{}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'date')),
('Duration', 'duration', 'advanced', 'INTERVAL', '{}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'text')),

-- Boolean & Choice
('Yes/No', 'boolean', 'basic', 'BOOLEAN', '{}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'switch')),
('Single Choice', 'single_choice', 'basic', 'VARCHAR', '{"allow_custom": false}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'select')),
('Multiple Choice', 'multi_choice', 'basic', 'JSONB', '{"allow_custom": false}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'select')),

-- Contact / Web
('Email Address', 'email', 'basic', 'VARCHAR', '{"validation_regex": "^[^@]+@[^@]+\\.[^@]+$"}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'text')),
('Phone Number', 'phone', 'basic', 'VARCHAR', '{}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'text')),
('Website Link', 'url', 'basic', 'VARCHAR', '{}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'text')),
('Password', 'password', 'advanced', 'VARCHAR', '{"encrypted": true}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'text')),

-- Media & Location
('Color', 'color', 'advanced', 'VARCHAR', '{}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'text')),
('Image', 'image', 'media', 'VARCHAR', '{"storage_provider": "s3", "multiple": false}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'upload')),
('File', 'file', 'media', 'VARCHAR', '{"storage_provider": "s3", "multiple": false}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'upload')),
('Video', 'video', 'media', 'VARCHAR', '{"storage_provider": "s3"}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'upload')),
('Audio', 'audio', 'media', 'VARCHAR', '{"storage_provider": "s3"}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'upload')),
('Address', 'address', 'advanced', 'JSONB', '{"fields": ["street", "city", "zip", "country"]}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'form')),
('Map Location', 'location', 'advanced', 'POINT', '{}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'text')),

-- Relational
('Relative Field', 'relation', 'relational', 'INTEGER', '{"target_model": null, "relation_type": "one_to_many"}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'select')),

-- Rich Content
('Rich Text', 'rich_text', 'advanced', 'TEXT', '{}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'textarea')),
('JSON', 'json', 'advanced', 'JSONB', '{}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'textarea'))
ON CONFLICT (type_code) DO NOTHING;

-- ==========================================
-- 3. Settings
-- ==========================================
-- Ensure settings supports per-field config for dynamic UI (dropdown options, ranges, etc.)
ALTER TABLE public.settings
ADD COLUMN IF NOT EXISTS field_config_json JSONB DEFAULT '{}'::jsonb;

-- Global System Settings
DO $$
DECLARE
    ft_text INT;
    ft_color INT;
    ft_number INT;
    ft_bool INT;
    ft_image INT;
    ft_single_choice INT;
BEGIN
    SELECT field_type_id INTO ft_text FROM public.field_types WHERE type_code = 'text';
    SELECT field_type_id INTO ft_color FROM public.field_types WHERE type_code = 'color';
    SELECT field_type_id INTO ft_number FROM public.field_types WHERE type_code = 'number';
    SELECT field_type_id INTO ft_bool FROM public.field_types WHERE type_code = 'boolean';
    SELECT field_type_id INTO ft_image FROM public.field_types WHERE type_code = 'image';
    SELECT field_type_id INTO ft_single_choice FROM public.field_types WHERE type_code = 'single_choice';

    -- 1. General Settings
    INSERT INTO public.settings (group_name, setting_key, setting_name, description, field_type_id, default_value, value, scope, is_built_in, field_config_json)
    VALUES
    ('General', 'app_name', 'Application Name', 'The visible name of the SaaS platform', ft_text, '"Noolva SaaS"', '"Noolva SaaS"', 'global', true, '{}'::jsonb),
    ('Branding', 'brand_color', 'Primary Brand Color', 'Main accent color', ft_color, '"#007bff"', '"#007bff"', 'global', true, '{}'::jsonb),
    
    -- 1.1 Theme Settings
    ('Theme', 'theme', 'Theme', 'Selected theme key', ft_single_choice, '"default"', '"default"', 'global', true,
        '{"options":[{"label":"Default Corporate","value":"default"},{"label":"Slate Corporate","value":"slate"}]}'::jsonb
    ),
    ('Theme', 'theme_color_primary', 'Theme Primary Color', 'Primary theme color', ft_color, '"#1890ff"', '"#1890ff"', 'global', true,
        '{"presets":[{"label":"Blue / Green","primary":"#1890ff","secondary":"#52c41a"},{"label":"Purple / Orange","primary":"#722ed1","secondary":"#fa8c16"},{"label":"Teal / Gold","primary":"#13c2c2","secondary":"#faad14"},{"label":"Pink / Gray","primary":"#eb2f96","secondary":"#8c8c8c"}]}'::jsonb
    ),
    ('Theme', 'theme_color_secondary', 'Theme Secondary Color', 'Secondary theme color', ft_color, '"#52c41a"', '"#52c41a"', 'global', true, '{}'::jsonb),
    ('Theme', 'theme_mode', 'Theme Mode', 'light or dark', ft_single_choice, '"light"', '"light"', 'global', true,
        '{"options":[{"label":"Light","value":"light"},{"label":"Dark","value":"dark"}]}'::jsonb
    ),
    ('Theme', 'font_size_base', 'Base Font Size', 'Global base font size (px)', ft_number, '14', '14', 'global', true,
        '{"min":12,"max":18,"step":1}'::jsonb
    ),
    ('Theme', 'font_size_small', 'Small Font Size', 'Small font size (px)', ft_number, '12', '12', 'global', true,
        '{"min":10,"max":16,"step":1}'::jsonb
    ),
    ('Theme', 'font_size_large', 'Large Font Size', 'Large font size (px)', ft_number, '16', '16', 'global', true,
        '{"min":14,"max":22,"step":1}'::jsonb
    ),
    
    -- 2. Security
    ('Security', 'password_min_length', 'Minimum Password Length', 'Enforced complexity', ft_number, '8', '8', 'global', true, '{"min":6,"max":64,"step":1}'::jsonb),
    ('Security', 'enable_2fa', 'Enable 2FA', 'Allow users to enable Two-Factor Auth', ft_bool, 'false', 'false', 'global', true, '{}'::jsonb)
    ON CONFLICT DO NOTHING;
END $$;

-- ==========================================
-- 3.1 Apps & Menus (Seed)
-- ==========================================
-- Apps (top-level): Dashboards, Organization, App Studio, Settings
DO $$
DECLARE
    system_user_id INT;
    dashboards_app_id INT;
    organization_app_id INT;
    appstudio_app_id INT;
    settings_app_id INT;
    dev_console_app_id INT;
BEGIN
    SELECT user_id INTO system_user_id FROM public.users WHERE user_type = 'system' LIMIT 1;

    -- Apps (global scope by leaving tenant_id/company_id NULL)
    INSERT INTO public.apps (app_name, app_title, app_description, app_image_url, tenant_id, company_id, is_saas_default, is_builtin, is_active, order_no, created_by)
    VALUES ('dashboards', 'Dashboards', 'Dashboards and analytics', '/assets/dashboards_app_icon.png', NULL, NULL, TRUE, TRUE, TRUE, 10, system_user_id)
    ON CONFLICT ON CONSTRAINT unique_app_per_tenant_scope
    DO UPDATE SET app_title = EXCLUDED.app_title, last_updated = CURRENT_TIMESTAMP
    RETURNING app_id INTO dashboards_app_id;

    IF dashboards_app_id IS NULL THEN
        SELECT app_id INTO dashboards_app_id FROM public.apps WHERE app_name='dashboards' AND tenant_id IS NULL AND company_id IS NULL LIMIT 1;
    END IF;

    INSERT INTO public.apps (app_name, app_title, app_description, app_image_url, tenant_id, company_id, is_saas_default, is_builtin, is_active, order_no, created_by)
    VALUES ('organization', 'Organization', 'Company, users, roles and permissions', '/assets/organization_app_icon.svg', NULL, NULL, TRUE, TRUE, TRUE, 20, system_user_id)
    ON CONFLICT ON CONSTRAINT unique_app_per_tenant_scope
    DO UPDATE SET app_title = EXCLUDED.app_title, last_updated = CURRENT_TIMESTAMP
    RETURNING app_id INTO organization_app_id;

    IF organization_app_id IS NULL THEN
        SELECT app_id INTO organization_app_id FROM public.apps WHERE app_name='organization' AND tenant_id IS NULL AND company_id IS NULL LIMIT 1;
    END IF;

    INSERT INTO public.apps (app_name, app_title, app_description, app_image_url, tenant_id, company_id, is_saas_default, is_builtin, is_active, order_no, created_by)
    VALUES ('app_studio', 'App Studio', 'Low-code studio (models, views, menus, APIs)', '/assets/app_studio_app_icon.svg', NULL, NULL, TRUE, TRUE, TRUE, 30, system_user_id)
    ON CONFLICT ON CONSTRAINT unique_app_per_tenant_scope
    DO UPDATE SET app_title = EXCLUDED.app_title, last_updated = CURRENT_TIMESTAMP
    RETURNING app_id INTO appstudio_app_id;

    IF appstudio_app_id IS NULL THEN
        SELECT app_id INTO appstudio_app_id FROM public.apps WHERE app_name='app_studio' AND tenant_id IS NULL AND company_id IS NULL LIMIT 1;
    END IF;

    INSERT INTO public.apps (app_name, app_title, app_description, app_image_url, tenant_id, company_id, is_saas_default, is_builtin, is_active, order_no, created_by)
    VALUES ('settings', 'Settings', 'Platform settings', '/assets/settings_app_icon.svg', NULL, NULL, TRUE, TRUE, TRUE, 40, system_user_id)
    ON CONFLICT ON CONSTRAINT unique_app_per_tenant_scope
    DO UPDATE SET app_title = EXCLUDED.app_title, last_updated = CURRENT_TIMESTAMP
    RETURNING app_id INTO settings_app_id;

    IF settings_app_id IS NULL THEN
        SELECT app_id INTO settings_app_id FROM public.apps WHERE app_name='settings' AND tenant_id IS NULL AND company_id IS NULL LIMIT 1;
    END IF;

    -- Developer Console app
    INSERT INTO public.apps (app_name, app_title, app_description, app_image_url, tenant_id, company_id, is_saas_default, is_builtin, is_active, order_no, created_by)
    VALUES ('developer_console', 'Developer Console', 'Database administration and query tools', '/assets/developer_console_app_icon.svg', NULL, NULL, TRUE, TRUE, TRUE, 50, system_user_id)
    ON CONFLICT ON CONSTRAINT unique_app_per_tenant_scope
    DO UPDATE SET app_title = EXCLUDED.app_title, last_updated = CURRENT_TIMESTAMP
    RETURNING app_id INTO dev_console_app_id;

    IF dev_console_app_id IS NULL THEN
        SELECT app_id INTO dev_console_app_id FROM public.apps WHERE app_name='developer_console' AND tenant_id IS NULL AND company_id IS NULL LIMIT 1;
    END IF;

    -- Menus for Developer Console app (all direct children, parent_id = NULL)
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=dev_console_app_id AND parent_id IS NULL AND menu_title='Database') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Database',NULL,'item','dev_console_database','database',dev_console_app_id,'saas',TRUE,10,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=dev_console_app_id AND parent_id IS NULL AND menu_title='Db Query') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Db Query',NULL,'item','dev_console_db_query','code',dev_console_app_id,'saas',TRUE,20,system_user_id);
    END IF;

    -- Menus for Organization app (all direct children, parent_id = NULL)
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=organization_app_id AND parent_id IS NULL AND menu_title='Companies') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Companies',NULL,'item','org_companies','bank',organization_app_id,'saas',TRUE,10,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=organization_app_id AND parent_id IS NULL AND menu_title='App Menus') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('App Menus',NULL,'item','org_app_menus','appstore',organization_app_id,'saas',TRUE,20,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=organization_app_id AND parent_id IS NULL AND menu_title='Users') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Users',NULL,'item','org_users','user',organization_app_id,'saas',TRUE,30,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=organization_app_id AND parent_id IS NULL AND menu_title='User Groups') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('User Groups',NULL,'item','org_user_groups','users',organization_app_id,'saas',TRUE,40,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=organization_app_id AND parent_id IS NULL AND menu_title='Teams') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Teams',NULL,'item','org_teams','team',organization_app_id,'saas',TRUE,50,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=organization_app_id AND parent_id IS NULL AND menu_title='Roles') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Roles',NULL,'item','org_roles','safety',organization_app_id,'saas',TRUE,60,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=organization_app_id AND parent_id IS NULL AND menu_title='Permissions') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Permissions',NULL,'item','org_permissions','key',organization_app_id,'saas',TRUE,70,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=organization_app_id AND parent_id IS NULL AND menu_title='Settings') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Settings',NULL,'item','settings','setting',organization_app_id,'saas',TRUE,80,system_user_id);
    END IF;

    -- Menus for App Studio app (all direct children, parent_id = NULL)
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=appstudio_app_id AND parent_id IS NULL AND menu_title='App Store') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('App Store',NULL,'item','studio_app_store','shop',appstudio_app_id,'saas',TRUE,10,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=appstudio_app_id AND parent_id IS NULL AND menu_title='My Apps') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('My Apps',NULL,'item','studio_my_apps','appstore',appstudio_app_id,'saas',TRUE,20,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=appstudio_app_id AND parent_id IS NULL AND menu_title='Modules') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Modules',NULL,'item','studio_modules','blocks',appstudio_app_id,'saas',TRUE,30,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=appstudio_app_id AND parent_id IS NULL AND menu_title='Features') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Features',NULL,'item','studio_features','profile',appstudio_app_id,'saas',TRUE,40,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=appstudio_app_id AND parent_id IS NULL AND menu_title='Api Endpoints') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Api Endpoints',NULL,'item','studio_api_endpoints','api',appstudio_app_id,'saas',TRUE,50,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=appstudio_app_id AND parent_id IS NULL AND menu_title='Data Models') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Data Models',NULL,'item','studio_data_models','database',appstudio_app_id,'saas',TRUE,60,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=appstudio_app_id AND parent_id IS NULL AND menu_title='UI Views') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('UI Views',NULL,'item','studio_ui_views','layout',appstudio_app_id,'saas',TRUE,70,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=appstudio_app_id AND parent_id IS NULL AND menu_title='Jobs/Actions') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Jobs/Actions',NULL,'item','studio_jobs_actions','rocket',appstudio_app_id,'saas',TRUE,80,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=appstudio_app_id AND parent_id IS NULL AND menu_title='Integration Manager') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Integration Manager',NULL,'item','studio_integrations','link',appstudio_app_id,'saas',TRUE,90,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=appstudio_app_id AND parent_id IS NULL AND menu_title='Assets') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Assets',NULL,'item','studio_assets','picture',appstudio_app_id,'saas',TRUE,100,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=appstudio_app_id AND parent_id IS NULL AND menu_title='UI Components') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('UI Components',NULL,'item','studio_ui_components','build',appstudio_app_id,'saas',TRUE,110,system_user_id);
    END IF;
END $$;

-- ==========================================
-- 4. Default Tenant and Company
-- ==========================================
-- Create a default tenant and company for initial setup
-- This ensures S3 integration and other company-scoped features work out of the box
DO $$
DECLARE
    system_user_id INT;
    default_tenant_id INT;
    default_company_id INT;
    tenant_exists BOOLEAN;
    company_exists BOOLEAN;
BEGIN
    -- Get system user ID (created during CLI setup, may not exist yet during feeds)
    SELECT user_id INTO system_user_id FROM public.users WHERE user_type = 'system' LIMIT 1;
    
    -- Check if default tenant already exists
    SELECT EXISTS(SELECT 1 FROM public.tenants WHERE tenant_name = 'Default Tenant') INTO tenant_exists;
    
    IF NOT tenant_exists THEN
        -- Create default tenant
        INSERT INTO public.tenants (
            tenant_name,
            contact_email,
            subscription_plan,
            subscription_status,
            is_active,
            created_by
        ) VALUES (
            'Default Tenant',
            NULL,
            'trial',
            'active',
            TRUE,
            system_user_id
        )
        RETURNING tenant_id INTO default_tenant_id;
    ELSE
        -- Get existing tenant ID
        SELECT tenant_id INTO default_tenant_id FROM public.tenants WHERE tenant_name = 'Default Tenant' LIMIT 1;
    END IF;
    
    -- Check if default company already exists
    SELECT EXISTS(SELECT 1 FROM public.companies WHERE company_code = 'your-company') INTO company_exists;
    
    IF NOT company_exists THEN
        -- Create default company
        INSERT INTO public.companies (
            tenant_id,
            company_name,
            company_code,
            is_default,
            is_active,
            created_by
        ) VALUES (
            default_tenant_id,
            'Your Company',
            'your-company',
            TRUE,
            TRUE,
            system_user_id
        )
        RETURNING company_id INTO default_company_id;
    ELSE
        -- Get existing company ID
        SELECT company_id INTO default_company_id FROM public.companies WHERE company_code = 'your-company' LIMIT 1;
    END IF;
    
END $$;

-- ==========================================
-- 5. Integration Providers
-- ==========================================
-- Standard Integration Providers (SES, SMS, S3, CCAvenue) with required field configurations
DO $$
DECLARE
    ft_text INT;
    ft_email INT;
    ft_url INT;
    ft_number INT;
    ft_boolean INT;
BEGIN
    SELECT field_type_id INTO ft_text FROM public.field_types WHERE type_code = 'text';
    SELECT field_type_id INTO ft_email FROM public.field_types WHERE type_code = 'email';
    SELECT field_type_id INTO ft_url FROM public.field_types WHERE type_code = 'url';
    SELECT field_type_id INTO ft_number FROM public.field_types WHERE type_code = 'number';
    SELECT field_type_id INTO ft_boolean FROM public.field_types WHERE type_code = 'boolean';

    -- 1. AWS SES (Simple Email Service)
    INSERT INTO public.integration_providers (
        provider_name, provider_display_name, provider_category, description,
        required_fields_json, optional_fields_json, metadata_json, is_builtin
    ) VALUES (
        'aws_ses',
        'AWS SES',
        'email',
        'Amazon Simple Email Service for sending transactional and marketing emails',
        jsonb_build_array(
            jsonb_build_object(
                'field_name', 'aws_access_key_id',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'AWS Access Key ID',
                'is_secret', false,
                'description', 'Your AWS access key ID'
            ),
            jsonb_build_object(
                'field_name', 'aws_secret_access_key',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'AWS Secret Access Key',
                'is_secret', true,
                'description', 'Your AWS secret access key'
            ),
            jsonb_build_object(
                'field_name', 'aws_region',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'AWS Region',
                'is_secret', false,
                'description', 'AWS region (e.g., us-east-1, ap-south-1)',
                'default_value', 'us-east-1'
            )
        ),
        jsonb_build_array(
            jsonb_build_object(
                'field_name', 'from_email',
                'field_type_id', ft_email,
                'is_required', false,
                'display_name', 'Default From Email',
                'description', 'Default sender email address'
            ),
            jsonb_build_object(
                'field_name', 'from_name',
                'field_type_id', ft_text,
                'is_required', false,
                'display_name', 'Default From Name',
                'description', 'Default sender name'
            )
        ),
        jsonb_build_object('service_url', 'https://aws.amazon.com/ses/', 'api_docs', 'https://docs.aws.amazon.com/ses/'),
        true
    ) ON CONFLICT (provider_name) DO NOTHING;

    -- 2. AWS S3 (Simple Storage Service)
    INSERT INTO public.integration_providers (
        provider_name, provider_display_name, provider_category, description,
        required_fields_json, optional_fields_json, metadata_json, is_builtin
    ) VALUES (
        'aws_s3',
        'AWS S3',
        'storage',
        'Amazon Simple Storage Service for file and asset storage',
        jsonb_build_array(
            jsonb_build_object(
                'field_name', 'aws_access_key_id',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'AWS Access Key ID',
                'is_secret', false,
                'description', 'Your AWS access key ID'
            ),
            jsonb_build_object(
                'field_name', 'aws_secret_access_key',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'AWS Secret Access Key',
                'is_secret', true,
                'description', 'Your AWS secret access key'
            ),
            jsonb_build_object(
                'field_name', 'bucket_name',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'S3 Bucket Name',
                'is_secret', false,
                'description', 'Name of the S3 bucket'
            ),
            jsonb_build_object(
                'field_name', 'aws_region',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'AWS Region',
                'is_secret', false,
                'description', 'AWS region (e.g., us-east-1, ap-south-1)',
                'default_value', 'us-east-1'
            )
        ),
        jsonb_build_array(
            jsonb_build_object(
                'field_name', 'bucket_prefix',
                'field_type_id', ft_text,
                'is_required', false,
                'display_name', 'Bucket Prefix/Folder',
                'description', 'Optional prefix/folder path in bucket (e.g., "production", "staging"). Assets will be stored under {prefix}/assets/',
                'default_value', ''
            ),
            jsonb_build_object(
                'field_name', 'endpoint_url',
                'field_type_id', ft_url,
                'is_required', false,
                'display_name', 'Custom Endpoint URL',
                'description', 'Custom S3 endpoint (for S3-compatible services)'
            ),
            jsonb_build_object(
                'field_name', 'cdn_url',
                'field_type_id', ft_url,
                'is_required', false,
                'display_name', 'CDN URL',
                'description', 'CDN URL for public asset access'
            )
        ),
        jsonb_build_object('service_url', 'https://aws.amazon.com/s3/', 'api_docs', 'https://docs.aws.amazon.com/s3/'),
        true
    ) ON CONFLICT (provider_name) DO NOTHING;

    -- 3. AWS SMS / SNS (Simple Notification Service)
    INSERT INTO public.integration_providers (
        provider_name, provider_display_name, provider_category, description,
        required_fields_json, optional_fields_json, metadata_json, is_builtin
    ) VALUES (
        'aws_sms',
        'AWS SMS (SNS)',
        'sms',
        'Amazon Simple Notification Service for sending SMS messages',
        jsonb_build_array(
            jsonb_build_object(
                'field_name', 'aws_access_key_id',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'AWS Access Key ID',
                'is_secret', false,
                'description', 'Your AWS access key ID'
            ),
            jsonb_build_object(
                'field_name', 'aws_secret_access_key',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'AWS Secret Access Key',
                'is_secret', true,
                'description', 'Your AWS secret access key'
            ),
            jsonb_build_object(
                'field_name', 'aws_region',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'AWS Region',
                'is_secret', false,
                'description', 'AWS region (e.g., us-east-1, ap-south-1)',
                'default_value', 'us-east-1'
            )
        ),
        jsonb_build_array(
            jsonb_build_object(
                'field_name', 'sender_id',
                'field_type_id', ft_text,
                'is_required', false,
                'display_name', 'Sender ID',
                'description', 'Default SMS sender ID'
            )
        ),
        jsonb_build_object('service_url', 'https://aws.amazon.com/sns/', 'api_docs', 'https://docs.aws.amazon.com/sns/'),
        true
    ) ON CONFLICT (provider_name) DO NOTHING;

    -- 4. CCAvenue Payment Gateway
    INSERT INTO public.integration_providers (
        provider_name, provider_display_name, provider_category, description,
        required_fields_json, optional_fields_json, metadata_json, is_builtin
    ) VALUES (
        'ccavenue',
        'CCAvenue',
        'payment',
        'CCAvenue payment gateway for processing online payments',
        jsonb_build_array(
            jsonb_build_object(
                'field_name', 'merchant_id',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'Merchant ID',
                'is_secret', false,
                'description', 'Your CCAvenue merchant ID'
            ),
            jsonb_build_object(
                'field_name', 'access_code',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'Access Code',
                'is_secret', true,
                'description', 'Your CCAvenue access code'
            ),
            jsonb_build_object(
                'field_name', 'working_key',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'Working Key',
                'is_secret', true,
                'description', 'Your CCAvenue working key (encryption key)'
            )
        ),
        jsonb_build_array(
            jsonb_build_object(
                'field_name', 'environment',
                'field_type_id', ft_text,
                'is_required', false,
                'display_name', 'Environment',
                'description', 'Payment environment: test or production',
                'default_value', 'test',
                'options', jsonb_build_array('test', 'production')
            ),
            jsonb_build_object(
                'field_name', 'currency',
                'field_type_id', ft_text,
                'is_required', false,
                'display_name', 'Default Currency',
                'description', 'Default currency code (e.g., INR, USD)',
                'default_value', 'INR'
            )
        ),
        jsonb_build_object('service_url', 'https://www.ccavenue.com/', 'api_docs', 'https://www.ccavenue.com/supportcenter/knowledgebase'),
        true
    ) ON CONFLICT (provider_name) DO NOTHING;

END $$;

-- ==========================================
-- 6. Default Apps and Menus (Built-in)
-- ==========================================
-- These are required so the Admin UI can show Apps first, then menus inside each app.
-- Safe to run multiple times (uses existence checks).
DO $$
DECLARE
    dashboards_app_id INT;
    users_app_id INT;
    overview_menu_id INT;
    user_mgmt_menu_id INT;
BEGIN
    -- ----------------------------
    -- Apps
    -- ----------------------------
    -- Dashboards app
    SELECT app_id INTO dashboards_app_id
    FROM public.apps
    WHERE app_name = 'dashboards' AND tenant_id IS NULL AND company_id IS NULL
    LIMIT 1;

    IF dashboards_app_id IS NULL THEN
        INSERT INTO public.apps (
            app_name,
            app_title,
            app_image_url,
            app_description,
            tenant_id,
            company_id,
            is_builtin,
            is_saas_default,
            is_tenant_default,
            order_no
        ) VALUES (
            'dashboards',
            'Dashboards',
            'https://cdn.avkaran.com/dashboards_app_icon.png',
            'Dashboard and analytics application',
            NULL,
            NULL,
            TRUE,
            TRUE,
            TRUE,
            1
        )
        RETURNING app_id INTO dashboards_app_id;
    END IF;

    -- Users app
    SELECT app_id INTO users_app_id
    FROM public.apps
    WHERE app_name = 'users' AND tenant_id IS NULL AND company_id IS NULL
    LIMIT 1;

    IF users_app_id IS NULL THEN
        INSERT INTO public.apps (
            app_name,
            app_title,
            app_image_url,
            app_description,
            tenant_id,
            company_id,
            is_builtin,
            is_saas_default,
            is_tenant_default,
            order_no
        ) VALUES (
            'users',
            'Users',
            'https://cdn.avkaran.com/users_app_icon.png',
            'User and access management application',
            NULL,
            NULL,
            TRUE,
            TRUE,
            TRUE,
            2
        )
        RETURNING app_id INTO users_app_id;
    END IF;

    -- ----------------------------
    -- Menus for Dashboards app
    -- ----------------------------
    -- Root: Overview
    SELECT menu_id INTO overview_menu_id
    FROM public.menus
    WHERE app_id = dashboards_app_id
      AND menu_title = 'Overview'
      AND parent_id IS NULL
    LIMIT 1;

    IF overview_menu_id IS NULL THEN
        INSERT INTO public.menus (
            menu_title,
            parent_id,
            route_path,
            icon,
            app_id,
            type,
            scope,
            order_no,
            is_builtin,
            is_hidden
        ) VALUES (
            'Overview',
            NULL,
            '/dashboards/overview',
            'AppstoreOutlined',
            dashboards_app_id,
            'item',
            'both',
            1,
            TRUE,
            FALSE
        )
        RETURNING menu_id INTO overview_menu_id;
    END IF;

    -- Child: Dashboard Stats
    IF NOT EXISTS (
        SELECT 1
        FROM public.menus
        WHERE app_id = dashboards_app_id
          AND menu_title = 'Dashboard Stats'
          AND parent_id = overview_menu_id
    ) THEN
        INSERT INTO public.menus (
            menu_title,
            parent_id,
            route_path,
            icon,
            app_id,
            type,
            scope,
            order_no,
            is_builtin,
            is_hidden
        ) VALUES (
            'Dashboard Stats',
            overview_menu_id,
            '/dashboards/stats',
            NULL,
            dashboards_app_id,
            'item',
            'both',
            1,
            TRUE,
            FALSE
        );
    END IF;

    -- Root: Reports
    IF NOT EXISTS (
        SELECT 1
        FROM public.menus
        WHERE app_id = dashboards_app_id
          AND menu_title = 'Reports'
          AND parent_id IS NULL
    ) THEN
        INSERT INTO public.menus (
            menu_title,
            parent_id,
            route_path,
            icon,
            app_id,
            type,
            scope,
            order_no,
            is_builtin,
            is_hidden
        ) VALUES (
            'Reports',
            NULL,
            '/dashboards/reports',
            'FileOutlined',
            dashboards_app_id,
            'item',
            'both',
            2,
            TRUE,
            FALSE
        );
    END IF;

    -- ----------------------------
    -- Menus for Users app
    -- ----------------------------
    -- Root: User Management
    SELECT menu_id INTO user_mgmt_menu_id
    FROM public.menus
    WHERE app_id = users_app_id
      AND menu_title = 'User Management'
      AND parent_id IS NULL
    LIMIT 1;

    IF user_mgmt_menu_id IS NULL THEN
        INSERT INTO public.menus (
            menu_title,
            parent_id,
            route_path,
            icon,
            app_id,
            type,
            scope,
            order_no,
            is_builtin,
            is_hidden
        ) VALUES (
            'User Management',
            NULL,
            '/users',
            'UserOutlined',
            users_app_id,
            'item',
            'both',
            1,
            TRUE,
            FALSE
        )
        RETURNING menu_id INTO user_mgmt_menu_id;
    END IF;

    -- Child: User List
    IF NOT EXISTS (
        SELECT 1
        FROM public.menus
        WHERE app_id = users_app_id
          AND menu_title = 'User List'
          AND parent_id = user_mgmt_menu_id
    ) THEN
        INSERT INTO public.menus (
            menu_title,
            parent_id,
            route_path,
            icon,
            app_id,
            type,
            scope,
            order_no,
            is_builtin,
            is_hidden
        ) VALUES (
            'User List',
            user_mgmt_menu_id,
            '/users/list',
            NULL,
            users_app_id,
            'item',
            'both',
            1,
            TRUE,
            FALSE
        );
    END IF;

    -- Child: Add User
    IF NOT EXISTS (
        SELECT 1
        FROM public.menus
        WHERE app_id = users_app_id
          AND menu_title = 'Add User'
          AND parent_id = user_mgmt_menu_id
    ) THEN
        INSERT INTO public.menus (
            menu_title,
            parent_id,
            route_path,
            icon,
            app_id,
            type,
            scope,
            order_no,
            is_builtin,
            is_hidden
        ) VALUES (
            'Add User',
            user_mgmt_menu_id,
            '/users/add',
            NULL,
            users_app_id,
            'item',
            'both',
            2,
            TRUE,
            FALSE
        );
    END IF;
END $$;
