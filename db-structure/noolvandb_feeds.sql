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
('Paragraph', 'paragraph', 'basic', 'TEXT', '{"max_line_counts": 3}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'textarea')),

-- Numbers
('Number', 'number', 'basic', 'NUMERIC', '{"precision": 10, "scale": 2}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'number')),
('Auto Number', 'auto_number', 'advanced', 'SERIAL', '{}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'label')),
('Currency', 'currency', 'advanced', 'NUMERIC', '{"currency_symbol": "₹", "precision": 10, "scale": 2}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'number')),
('Percentage', 'percentage', 'advanced', 'NUMERIC', '{"precision": 5, "scale": 2}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'number')),
('Rating', 'rating', 'advanced', 'INTEGER', '{"max_stars": 5}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'number')),

-- Dates & Time
('Date', 'date', 'basic', 'DATE', '{}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'date')),
('DateTime', 'datetime', 'basic', 'TIMESTAMPTZ', '{}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'date')),
('Time', 'time', 'basic', 'TIME', '{}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'date')),
('Duration', 'duration', 'advanced', 'INTERVAL', '{}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'text')),

-- Boolean & Choice
('Yes/No', 'boolean', 'basic', 'BOOLEAN', '{}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'switch')),
('Single Choice', 'single_choice', 'basic', 'VARCHAR', '{"options_mode": "custom_collection", "options": []}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'select')),
('Multiple Choice', 'multi_choice', 'basic', 'JSONB', '{"options_mode": "custom_collection", "options": []}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'select')),

-- Auto Code (Automatically generated codes based on pattern)
('Auto Code', 'auto_code', 'advanced', 'VARCHAR', '{"pattern": [{"type": "prefix", "value": "CODE"}, {"type": "separator", "value": "-"}, {"type": "date", "format": "YYYY-MM"}, {"type": "separator", "value": "-"}, {"type": "increment", "padding": 4, "start": 1}]}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'text')),

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
('JSON', 'json', 'advanced', 'JSONB', '{}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'textarea')),

-- Icons
('Icon', 'icon', 'media', 'VARCHAR', '{"format": "prefix:name", "examples": ["fa:heart", "antd:download", "smily:thanks", "custom:myhome"]}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'select'))
ON CONFLICT (type_code) DO NOTHING;

-- Update input_type_image for all field types
UPDATE public.field_types SET input_type_image = 'field_types/field_type_text.svg' WHERE type_code = 'text';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_paragraph.svg' WHERE type_code = 'paragraph';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_number.svg' WHERE type_code = 'number';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_auto_number.svg' WHERE type_code = 'auto_number';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_currency.svg' WHERE type_code = 'currency';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_percentage.svg' WHERE type_code = 'percentage';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_rating.svg' WHERE type_code = 'rating';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_date.svg' WHERE type_code = 'date';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_datetime.svg' WHERE type_code = 'datetime';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_time.svg' WHERE type_code = 'time';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_duration.svg' WHERE type_code = 'duration';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_boolean.svg' WHERE type_code = 'boolean';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_email.svg' WHERE type_code = 'email';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_phone.svg' WHERE type_code = 'phone';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_url.svg' WHERE type_code = 'url';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_password.svg' WHERE type_code = 'password';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_color.svg' WHERE type_code = 'color';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_image.svg' WHERE type_code = 'image';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_file.svg' WHERE type_code = 'file';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_video.svg' WHERE type_code = 'video';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_audio.svg' WHERE type_code = 'audio';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_address.svg' WHERE type_code = 'address';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_location.svg' WHERE type_code = 'location';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_relation.svg' WHERE type_code = 'relation';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_json.svg' WHERE type_code = 'json';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_icon.svg' WHERE type_code = 'icon';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_multi_choice.svg' WHERE type_code = 'multi_choice';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_auto_code.svg' WHERE type_code = 'auto_code';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_rich_text.svg' WHERE type_code = 'rich_text';
UPDATE public.field_types SET input_type_image = 'field_types/field_type_single_choice.svg' WHERE type_code = 'single_choice';

-- Update order_no for field types (for consistent ordering in UI)
UPDATE public.field_types SET order_no = 1 WHERE type_code = 'text';
UPDATE public.field_types SET order_no = 2 WHERE type_code = 'paragraph';
UPDATE public.field_types SET order_no = 3 WHERE type_code = 'number';
UPDATE public.field_types SET order_no = 4 WHERE type_code = 'auto_number';
UPDATE public.field_types SET order_no = 5 WHERE type_code = 'currency';
UPDATE public.field_types SET order_no = 6 WHERE type_code = 'percentage';
UPDATE public.field_types SET order_no = 7 WHERE type_code = 'rating';
UPDATE public.field_types SET order_no = 8 WHERE type_code = 'date';
UPDATE public.field_types SET order_no = 9 WHERE type_code = 'datetime';
UPDATE public.field_types SET order_no = 10 WHERE type_code = 'time';
UPDATE public.field_types SET order_no = 11 WHERE type_code = 'duration';
UPDATE public.field_types SET order_no = 12 WHERE type_code = 'boolean';
UPDATE public.field_types SET order_no = 13 WHERE type_code = 'single_choice';
UPDATE public.field_types SET order_no = 14 WHERE type_code = 'multi_choice';
UPDATE public.field_types SET order_no = 15 WHERE type_code = 'auto_code';
UPDATE public.field_types SET order_no = 16 WHERE type_code = 'email';
UPDATE public.field_types SET order_no = 17 WHERE type_code = 'phone';
UPDATE public.field_types SET order_no = 18 WHERE type_code = 'url';
UPDATE public.field_types SET order_no = 19 WHERE type_code = 'password';
UPDATE public.field_types SET order_no = 20 WHERE type_code = 'color';
UPDATE public.field_types SET order_no = 21 WHERE type_code = 'image';
UPDATE public.field_types SET order_no = 22 WHERE type_code = 'file';
UPDATE public.field_types SET order_no = 23 WHERE type_code = 'video';
UPDATE public.field_types SET order_no = 24 WHERE type_code = 'audio';
UPDATE public.field_types SET order_no = 25 WHERE type_code = 'address';
UPDATE public.field_types SET order_no = 26 WHERE type_code = 'location';
UPDATE public.field_types SET order_no = 27 WHERE type_code = 'relation';
UPDATE public.field_types SET order_no = 28 WHERE type_code = 'rich_text';
UPDATE public.field_types SET order_no = 29 WHERE type_code = 'json';
UPDATE public.field_types SET order_no = 30 WHERE type_code = 'icon';

-- ==========================================
-- 2.1. Assets for Field Type Images
-- ==========================================
-- Insert field type SVG images into assets table (system-level, public assets)
-- Note: These assets should be uploaded to storage (S3/local) before or after this insert
DO $$
DECLARE
    v_system_user_id INTEGER;
BEGIN
    -- Get system user (super admin)
    SELECT user_id INTO v_system_user_id FROM public.users WHERE is_super_admin = TRUE LIMIT 1;
    
    -- Insert assets only if they don't already exist (check by storage_path)
    INSERT INTO public.assets (file_name, original_name, mime_type, storage_path, is_public, company_id, uploaded_by)
    SELECT * FROM (VALUES
        ('field_type_text.svg', 'field_type_text.svg', 'image/svg+xml', 'field_types/field_type_text.svg', TRUE, NULL, v_system_user_id),
        ('field_type_paragraph.svg', 'field_type_paragraph.svg', 'image/svg+xml', 'field_types/field_type_paragraph.svg', TRUE, NULL, v_system_user_id),
        ('field_type_number.svg', 'field_type_number.svg', 'image/svg+xml', 'field_types/field_type_number.svg', TRUE, NULL, v_system_user_id),
        ('field_type_auto_number.svg', 'field_type_auto_number.svg', 'image/svg+xml', 'field_types/field_type_auto_number.svg', TRUE, NULL, v_system_user_id),
        ('field_type_currency.svg', 'field_type_currency.svg', 'image/svg+xml', 'field_types/field_type_currency.svg', TRUE, NULL, v_system_user_id),
        ('field_type_percentage.svg', 'field_type_percentage.svg', 'image/svg+xml', 'field_types/field_type_percentage.svg', TRUE, NULL, v_system_user_id),
        ('field_type_rating.svg', 'field_type_rating.svg', 'image/svg+xml', 'field_types/field_type_rating.svg', TRUE, NULL, v_system_user_id),
        ('field_type_date.svg', 'field_type_date.svg', 'image/svg+xml', 'field_types/field_type_date.svg', TRUE, NULL, v_system_user_id),
        ('field_type_datetime.svg', 'field_type_datetime.svg', 'image/svg+xml', 'field_types/field_type_datetime.svg', TRUE, NULL, v_system_user_id),
        ('field_type_time.svg', 'field_type_time.svg', 'image/svg+xml', 'field_types/field_type_time.svg', TRUE, NULL, v_system_user_id),
        ('field_type_duration.svg', 'field_type_duration.svg', 'image/svg+xml', 'field_types/field_type_duration.svg', TRUE, NULL, v_system_user_id),
        ('field_type_boolean.svg', 'field_type_boolean.svg', 'image/svg+xml', 'field_types/field_type_boolean.svg', TRUE, NULL, v_system_user_id),
        ('field_type_email.svg', 'field_type_email.svg', 'image/svg+xml', 'field_types/field_type_email.svg', TRUE, NULL, v_system_user_id),
        ('field_type_phone.svg', 'field_type_phone.svg', 'image/svg+xml', 'field_types/field_type_phone.svg', TRUE, NULL, v_system_user_id),
        ('field_type_url.svg', 'field_type_url.svg', 'image/svg+xml', 'field_types/field_type_url.svg', TRUE, NULL, v_system_user_id),
        ('field_type_password.svg', 'field_type_password.svg', 'image/svg+xml', 'field_types/field_type_password.svg', TRUE, NULL, v_system_user_id),
        ('field_type_color.svg', 'field_type_color.svg', 'image/svg+xml', 'field_types/field_type_color.svg', TRUE, NULL, v_system_user_id),
        ('field_type_image.svg', 'field_type_image.svg', 'image/svg+xml', 'field_types/field_type_image.svg', TRUE, NULL, v_system_user_id),
        ('field_type_file.svg', 'field_type_file.svg', 'image/svg+xml', 'field_types/field_type_file.svg', TRUE, NULL, v_system_user_id),
        ('field_type_video.svg', 'field_type_video.svg', 'image/svg+xml', 'field_types/field_type_video.svg', TRUE, NULL, v_system_user_id),
        ('field_type_audio.svg', 'field_type_audio.svg', 'image/svg+xml', 'field_types/field_type_audio.svg', TRUE, NULL, v_system_user_id),
        ('field_type_address.svg', 'field_type_address.svg', 'image/svg+xml', 'field_types/field_type_address.svg', TRUE, NULL, v_system_user_id),
        ('field_type_location.svg', 'field_type_location.svg', 'image/svg+xml', 'field_types/field_type_location.svg', TRUE, NULL, v_system_user_id),
        ('field_type_relation.svg', 'field_type_relation.svg', 'image/svg+xml', 'field_types/field_type_relation.svg', TRUE, NULL, v_system_user_id),
        ('field_type_json.svg', 'field_type_json.svg', 'image/svg+xml', 'field_types/field_type_json.svg', TRUE, NULL, v_system_user_id),
        ('field_type_icon.svg', 'field_type_icon.svg', 'image/svg+xml', 'field_types/field_type_icon.svg', TRUE, NULL, v_system_user_id),
        ('field_type_multi_choice.svg', 'field_type_multi_choice.svg', 'image/svg+xml', 'field_types/field_type_multi_choice.svg', TRUE, NULL, v_system_user_id),
        ('field_type_auto_code.svg', 'field_type_auto_code.svg', 'image/svg+xml', 'field_types/field_type_auto_code.svg', TRUE, NULL, v_system_user_id),
        ('field_type_rich_text.svg', 'field_type_rich_text.svg', 'image/svg+xml', 'field_types/field_type_rich_text.svg', TRUE, NULL, v_system_user_id),
        ('field_type_single_choice.svg', 'field_type_single_choice.svg', 'image/svg+xml', 'field_types/field_type_single_choice.svg', TRUE, NULL, v_system_user_id)
    ) AS t(file_name, original_name, mime_type, storage_path, is_public, company_id, uploaded_by)
    WHERE NOT EXISTS (
        SELECT 1 FROM public.assets WHERE assets.storage_path = t.storage_path AND assets.company_id IS NULL
    );
END $$;

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

-- ==========================================
-- 7. Icons (Popular Free Icons)
-- ==========================================
-- Inserts popular free icons from FontAwesome, Ant Design, Smilies, and Custom examples
DO $$
DECLARE
    v_system_user_id INTEGER;
BEGIN
    -- Get system user for created_by
    SELECT user_id INTO v_system_user_id 
    FROM public.users 
    WHERE user_type = 'system' 
    LIMIT 1;
    
    IF v_system_user_id IS NULL THEN
        RAISE NOTICE 'System user not found. Using NULL for created_by.';
    END IF;

    -- FontAwesome Icons (Popular Free Icons)
    INSERT INTO public.icons (icon_code, icon_type, icon_name, category, description, tags, icon_data, is_popular, created_by) VALUES
    -- Navigation & UI
    ('fa:home', 'fa', 'Home', 'navigation', 'Home icon', ARRAY['home', 'house', 'main', 'dashboard'], '{"class": "fas fa-home"}'::jsonb, true, v_system_user_id),
    ('fa:user', 'fa', 'User', 'users', 'User profile icon', ARRAY['user', 'person', 'profile', 'account'], '{"class": "fas fa-user"}'::jsonb, true, v_system_user_id),
    ('fa:users', 'fa', 'Users', 'users', 'Multiple users icon', ARRAY['users', 'people', 'team', 'group'], '{"class": "fas fa-users"}'::jsonb, true, v_system_user_id),
    ('fa:cog', 'fa', 'Settings', 'settings', 'Settings/gear icon', ARRAY['settings', 'gear', 'config', 'preferences'], '{"class": "fas fa-cog"}'::jsonb, true, v_system_user_id),
    ('fa:search', 'fa', 'Search', 'actions', 'Search icon', ARRAY['search', 'find', 'magnify'], '{"class": "fas fa-search"}'::jsonb, true, v_system_user_id),
    ('fa:bell', 'fa', 'Notifications', 'notifications', 'Bell/notification icon', ARRAY['bell', 'notification', 'alert'], '{"class": "fas fa-bell"}'::jsonb, true, v_system_user_id),
    ('fa:heart', 'fa', 'Heart', 'social', 'Heart/like icon', ARRAY['heart', 'like', 'love', 'favorite'], '{"class": "fas fa-heart"}'::jsonb, true, v_system_user_id),
    ('fa:star', 'fa', 'Star', 'ratings', 'Star icon', ARRAY['star', 'favorite', 'rating'], '{"class": "fas fa-star"}'::jsonb, true, v_system_user_id),
    ('fa:envelope', 'fa', 'Email', 'communication', 'Email/envelope icon', ARRAY['email', 'mail', 'message'], '{"class": "fas fa-envelope"}'::jsonb, true, v_system_user_id),
    ('fa:phone', 'fa', 'Phone', 'communication', 'Phone icon', ARRAY['phone', 'call', 'telephone'], '{"class": "fas fa-phone"}'::jsonb, true, v_system_user_id),
    -- Actions
    ('fa:plus', 'fa', 'Add', 'actions', 'Plus/add icon', ARRAY['add', 'plus', 'new', 'create'], '{"class": "fas fa-plus"}'::jsonb, true, v_system_user_id),
    ('fa:edit', 'fa', 'Edit', 'actions', 'Edit/pencil icon', ARRAY['edit', 'modify', 'pencil', 'update'], '{"class": "fas fa-edit"}'::jsonb, true, v_system_user_id),
    ('fa:trash', 'fa', 'Delete', 'actions', 'Delete/trash icon', ARRAY['delete', 'trash', 'remove'], '{"class": "fas fa-trash"}'::jsonb, true, v_system_user_id),
    ('fa:save', 'fa', 'Save', 'actions', 'Save icon', ARRAY['save', 'store', 'disk'], '{"class": "fas fa-save"}'::jsonb, true, v_system_user_id),
    ('fa:download', 'fa', 'Download', 'actions', 'Download icon', ARRAY['download', 'get', 'export'], '{"class": "fas fa-download"}'::jsonb, true, v_system_user_id),
    ('fa:upload', 'fa', 'Upload', 'actions', 'Upload icon', ARRAY['upload', 'send', 'import'], '{"class": "fas fa-upload"}'::jsonb, true, v_system_user_id),
    ('fa:check', 'fa', 'Check', 'actions', 'Checkmark icon', ARRAY['check', 'done', 'success', 'approve'], '{"class": "fas fa-check"}'::jsonb, true, v_system_user_id),
    ('fa:times', 'fa', 'Close', 'actions', 'Close/cancel icon', ARRAY['close', 'cancel', 'times', 'x'], '{"class": "fas fa-times"}'::jsonb, true, v_system_user_id),
    -- Business & Data
    ('fa:database', 'fa', 'Database', 'data', 'Database icon', ARRAY['database', 'data', 'storage'], '{"class": "fas fa-database"}'::jsonb, true, v_system_user_id),
    ('fa:chart-bar', 'fa', 'Chart', 'data', 'Bar chart icon', ARRAY['chart', 'graph', 'analytics', 'statistics'], '{"class": "fas fa-chart-bar"}'::jsonb, true, v_system_user_id),
    ('fa:file', 'fa', 'File', 'documents', 'File icon', ARRAY['file', 'document'], '{"class": "fas fa-file"}'::jsonb, true, v_system_user_id),
    ('fa:folder', 'fa', 'Folder', 'documents', 'Folder icon', ARRAY['folder', 'directory'], '{"class": "fas fa-folder"}'::jsonb, true, v_system_user_id),
    ('fa:building', 'fa', 'Building', 'business', 'Building/company icon', ARRAY['building', 'company', 'office'], '{"class": "fas fa-building"}'::jsonb, true, v_system_user_id),
    ('fa:briefcase', 'fa', 'Briefcase', 'business', 'Briefcase/business icon', ARRAY['briefcase', 'business', 'work'], '{"class": "fas fa-briefcase"}'::jsonb, true, v_system_user_id),
    -- Navigation & Arrows
    ('fa:arrow-left', 'fa', 'Arrow Left', 'navigation', 'Left arrow icon', ARRAY['arrow', 'left', 'back', 'previous'], '{"class": "fas fa-arrow-left"}'::jsonb, true, v_system_user_id),
    ('fa:arrow-right', 'fa', 'Arrow Right', 'navigation', 'Right arrow icon', ARRAY['arrow', 'right', 'next', 'forward'], '{"class": "fas fa-arrow-right"}'::jsonb, true, v_system_user_id),
    ('fa:arrow-up', 'fa', 'Arrow Up', 'navigation', 'Up arrow icon', ARRAY['arrow', 'up', 'top'], '{"class": "fas fa-arrow-up"}'::jsonb, true, v_system_user_id),
    ('fa:arrow-down', 'fa', 'Arrow Down', 'navigation', 'Down arrow icon', ARRAY['arrow', 'down', 'bottom'], '{"class": "fas fa-arrow-down"}'::jsonb, true, v_system_user_id),
    -- Social & Media
    ('fa:facebook', 'fa', 'Facebook', 'social', 'Facebook icon', ARRAY['facebook', 'social', 'fb'], '{"class": "fab fa-facebook"}'::jsonb, true, v_system_user_id),
    ('fa:twitter', 'fa', 'Twitter', 'social', 'Twitter icon', ARRAY['twitter', 'social', 'tweet'], '{"class": "fab fa-twitter"}'::jsonb, true, v_system_user_id),
    ('fa:linkedin', 'fa', 'LinkedIn', 'social', 'LinkedIn icon', ARRAY['linkedin', 'social', 'professional'], '{"class": "fab fa-linkedin"}'::jsonb, true, v_system_user_id),
    ('fa:instagram', 'fa', 'Instagram', 'social', 'Instagram icon', ARRAY['instagram', 'social', 'ig'], '{"class": "fab fa-instagram"}'::jsonb, true, v_system_user_id),
    -- Security & Status
    ('fa:lock', 'fa', 'Lock', 'security', 'Lock/security icon', ARRAY['lock', 'security', 'protected'], '{"class": "fas fa-lock"}'::jsonb, true, v_system_user_id),
    ('fa:unlock', 'fa', 'Unlock', 'security', 'Unlock icon', ARRAY['unlock', 'open', 'access'], '{"class": "fas fa-unlock"}'::jsonb, true, v_system_user_id),
    ('fa:shield', 'fa', 'Shield', 'security', 'Shield/security icon', ARRAY['shield', 'security', 'protection'], '{"class": "fas fa-shield-alt"}'::jsonb, true, v_system_user_id),
    ('fa:key', 'fa', 'Key', 'security', 'Key icon', ARRAY['key', 'access', 'permission'], '{"class": "fas fa-key"}'::jsonb, true, v_system_user_id),
    -- Status & Feedback
    ('fa:check-circle', 'fa', 'Success', 'status', 'Success/check circle icon', ARRAY['success', 'check', 'done', 'complete'], '{"class": "fas fa-check-circle"}'::jsonb, true, v_system_user_id),
    ('fa:exclamation-circle', 'fa', 'Warning', 'status', 'Warning icon', ARRAY['warning', 'alert', 'caution'], '{"class": "fas fa-exclamation-circle"}'::jsonb, true, v_system_user_id),
    ('fa:times-circle', 'fa', 'Error', 'status', 'Error/close circle icon', ARRAY['error', 'close', 'fail'], '{"class": "fas fa-times-circle"}'::jsonb, true, v_system_user_id),
    ('fa:info-circle', 'fa', 'Info', 'status', 'Information icon', ARRAY['info', 'information', 'help'], '{"class": "fas fa-info-circle"}'::jsonb, true, v_system_user_id)
    ON CONFLICT (icon_code) DO NOTHING;

    -- Ant Design Icons (Popular)
    INSERT INTO public.icons (icon_code, icon_type, icon_name, category, description, tags, icon_data, is_popular, created_by) VALUES
    -- Navigation & UI
    ('antd:home', 'antd', 'Home', 'navigation', 'Home icon (Ant Design)', ARRAY['home', 'house', 'main'], '{"component": "HomeOutlined"}'::jsonb, true, v_system_user_id),
    ('antd:user', 'antd', 'User', 'users', 'User icon (Ant Design)', ARRAY['user', 'person', 'profile'], '{"component": "UserOutlined"}'::jsonb, true, v_system_user_id),
    ('antd:users', 'antd', 'Users', 'users', 'Users icon (Ant Design)', ARRAY['users', 'people', 'team'], '{"component": "UsergroupAddOutlined"}'::jsonb, true, v_system_user_id),
    ('antd:setting', 'antd', 'Settings', 'settings', 'Settings icon (Ant Design)', ARRAY['settings', 'config'], '{"component": "SettingOutlined"}'::jsonb, true, v_system_user_id),
    ('antd:search', 'antd', 'Search', 'actions', 'Search icon (Ant Design)', ARRAY['search', 'find'], '{"component": "SearchOutlined"}'::jsonb, true, v_system_user_id),
    ('antd:bell', 'antd', 'Notifications', 'notifications', 'Bell icon (Ant Design)', ARRAY['bell', 'notification'], '{"component": "BellOutlined"}'::jsonb, true, v_system_user_id),
    ('antd:heart', 'antd', 'Heart', 'social', 'Heart icon (Ant Design)', ARRAY['heart', 'like'], '{"component": "HeartOutlined"}'::jsonb, true, v_system_user_id),
    ('antd:star', 'antd', 'Star', 'ratings', 'Star icon (Ant Design)', ARRAY['star', 'favorite'], '{"component": "StarOutlined"}'::jsonb, true, v_system_user_id),
    -- Actions
    ('antd:plus', 'antd', 'Add', 'actions', 'Plus icon (Ant Design)', ARRAY['add', 'plus', 'new'], '{"component": "PlusOutlined"}'::jsonb, true, v_system_user_id),
    ('antd:edit', 'antd', 'Edit', 'actions', 'Edit icon (Ant Design)', ARRAY['edit', 'modify'], '{"component": "EditOutlined"}'::jsonb, true, v_system_user_id),
    ('antd:delete', 'antd', 'Delete', 'actions', 'Delete icon (Ant Design)', ARRAY['delete', 'remove'], '{"component": "DeleteOutlined"}'::jsonb, true, v_system_user_id),
    ('antd:save', 'antd', 'Save', 'actions', 'Save icon (Ant Design)', ARRAY['save', 'store'], '{"component": "SaveOutlined"}'::jsonb, true, v_system_user_id),
    ('antd:download', 'antd', 'Download', 'actions', 'Download icon (Ant Design)', ARRAY['download', 'export'], '{"component": "DownloadOutlined"}'::jsonb, true, v_system_user_id),
    ('antd:upload', 'antd', 'Upload', 'actions', 'Upload icon (Ant Design)', ARRAY['upload', 'import'], '{"component": "UploadOutlined"}'::jsonb, true, v_system_user_id),
    ('antd:check', 'antd', 'Check', 'actions', 'Check icon (Ant Design)', ARRAY['check', 'done'], '{"component": "CheckOutlined"}'::jsonb, true, v_system_user_id),
    ('antd:close', 'antd', 'Close', 'actions', 'Close icon (Ant Design)', ARRAY['close', 'cancel'], '{"component": "CloseOutlined"}'::jsonb, true, v_system_user_id),
    -- Data & Business
    ('antd:database', 'antd', 'Database', 'data', 'Database icon (Ant Design)', ARRAY['database', 'data'], '{"component": "DatabaseOutlined"}'::jsonb, true, v_system_user_id),
    ('antd:file', 'antd', 'File', 'documents', 'File icon (Ant Design)', ARRAY['file', 'document'], '{"component": "FileOutlined"}'::jsonb, true, v_system_user_id),
    ('antd:folder', 'antd', 'Folder', 'documents', 'Folder icon (Ant Design)', ARRAY['folder', 'directory'], '{"component": "FolderOutlined"}'::jsonb, true, v_system_user_id),
    ('antd:appstore', 'antd', 'App Store', 'navigation', 'App store icon (Ant Design)', ARRAY['app', 'store', 'grid'], '{"component": "AppstoreOutlined"}'::jsonb, true, v_system_user_id),
    -- Navigation
    ('antd:arrow-left', 'antd', 'Arrow Left', 'navigation', 'Left arrow (Ant Design)', ARRAY['arrow', 'left', 'back'], '{"component": "ArrowLeftOutlined"}'::jsonb, true, v_system_user_id),
    ('antd:arrow-right', 'antd', 'Arrow Right', 'navigation', 'Right arrow (Ant Design)', ARRAY['arrow', 'right', 'next'], '{"component": "ArrowRightOutlined"}'::jsonb, true, v_system_user_id),
    ('antd:arrow-up', 'antd', 'Arrow Up', 'navigation', 'Up arrow (Ant Design)', ARRAY['arrow', 'up'], '{"component": "ArrowUpOutlined"}'::jsonb, true, v_system_user_id),
    ('antd:arrow-down', 'antd', 'Arrow Down', 'navigation', 'Down arrow (Ant Design)', ARRAY['arrow', 'down'], '{"component": "ArrowDownOutlined"}'::jsonb, true, v_system_user_id),
    -- Status
    ('antd:check-circle', 'antd', 'Success', 'status', 'Success icon (Ant Design)', ARRAY['success', 'check'], '{"component": "CheckCircleOutlined"}'::jsonb, true, v_system_user_id),
    ('antd:exclamation-circle', 'antd', 'Warning', 'status', 'Warning icon (Ant Design)', ARRAY['warning', 'alert'], '{"component": "ExclamationCircleOutlined"}'::jsonb, true, v_system_user_id),
    ('antd:close-circle', 'antd', 'Error', 'status', 'Error icon (Ant Design)', ARRAY['error', 'close'], '{"component": "CloseCircleOutlined"}'::jsonb, true, v_system_user_id),
    ('antd:info-circle', 'antd', 'Info', 'status', 'Info icon (Ant Design)', ARRAY['info', 'information'], '{"component": "InfoCircleOutlined"}'::jsonb, true, v_system_user_id)
    ON CONFLICT (icon_code) DO NOTHING;

    -- Smilies/Emojis (Popular)
    INSERT INTO public.icons (icon_code, icon_type, icon_name, category, description, tags, icon_data, is_popular, created_by) VALUES
    ('smily:thanks', 'smily', 'Thanks', 'emotions', 'Thank you emoji', ARRAY['thanks', 'thank', 'gratitude', 'appreciate'], '{"emoji": "🙏", "unicode": "U+1F64F"}'::jsonb, true, v_system_user_id),
    ('smily:smile', 'smily', 'Smile', 'emotions', 'Happy smile emoji', ARRAY['smile', 'happy', 'joy', '😊'], '{"emoji": "😊", "unicode": "U+1F60A"}'::jsonb, true, v_system_user_id),
    ('smily:thumbs-up', 'smily', 'Thumbs Up', 'emotions', 'Thumbs up emoji', ARRAY['thumbs', 'up', 'like', 'good', '👍'], '{"emoji": "👍", "unicode": "U+1F44D"}'::jsonb, true, v_system_user_id),
    ('smily:heart', 'smily', 'Heart', 'emotions', 'Heart emoji', ARRAY['heart', 'love', '❤️'], '{"emoji": "❤️", "unicode": "U+2764"}'::jsonb, true, v_system_user_id),
    ('smily:star', 'smily', 'Star', 'emotions', 'Star emoji', ARRAY['star', 'favorite', '⭐'], '{"emoji": "⭐", "unicode": "U+2B50"}'::jsonb, true, v_system_user_id),
    ('smily:fire', 'smily', 'Fire', 'emotions', 'Fire emoji', ARRAY['fire', 'hot', '🔥'], '{"emoji": "🔥", "unicode": "U+1F525"}'::jsonb, true, v_system_user_id),
    ('smily:rocket', 'smily', 'Rocket', 'emotions', 'Rocket emoji', ARRAY['rocket', 'launch', '🚀'], '{"emoji": "🚀", "unicode": "U+1F680"}'::jsonb, true, v_system_user_id),
    ('smily:party', 'smily', 'Party', 'emotions', 'Party emoji', ARRAY['party', 'celebration', '🎉'], '{"emoji": "🎉", "unicode": "U+1F389"}'::jsonb, true, v_system_user_id),
    ('smily:check', 'smily', 'Check Mark', 'emotions', 'Check mark emoji', ARRAY['check', 'done', '✅'], '{"emoji": "✅", "unicode": "U+2705"}'::jsonb, true, v_system_user_id),
    ('smily:warning', 'smily', 'Warning', 'emotions', 'Warning emoji', ARRAY['warning', 'alert', '⚠️'], '{"emoji": "⚠️", "unicode": "U+26A0"}'::jsonb, true, v_system_user_id)
    ON CONFLICT (icon_code) DO NOTHING;

    -- Custom Icons (Examples)
    INSERT INTO public.icons (icon_code, icon_type, icon_name, category, description, tags, icon_data, is_popular, created_by) VALUES
    ('custom:myhome', 'custom', 'My Home', 'custom', 'Custom home icon', ARRAY['custom', 'home', 'myhome'], '{"svg": "<svg viewBox=\"0 0 24 24\"><path d=\"M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z\"/></svg>"}'::jsonb, false, v_system_user_id),
    ('custom:logo', 'custom', 'Logo', 'custom', 'Custom logo icon', ARRAY['custom', 'logo'], '{"svg": "<svg viewBox=\"0 0 24 24\"><circle cx=\"12\" cy=\"12\" r=\"10\"/></svg>"}'::jsonb, false, v_system_user_id)
    ON CONFLICT (icon_code) DO NOTHING;

    -- Additional FontAwesome Icons (Part 1)
    INSERT INTO public.icons (icon_code, icon_type, icon_name, category, description, tags, icon_data, is_popular, created_by) VALUES
    ('fa:copy', 'fa', 'Copy', 'actions', 'Copy icon', ARRAY['copy', 'duplicate'], '{"class": "fas fa-copy"}'::jsonb, false, v_system_user_id),
    ('fa:cut', 'fa', 'Cut', 'actions', 'Cut icon', ARRAY['cut', 'scissors'], '{"class": "fas fa-cut"}'::jsonb, false, v_system_user_id),
    ('fa:paste', 'fa', 'Paste', 'actions', 'Paste icon', ARRAY['paste', 'clipboard'], '{"class": "fas fa-paste"}'::jsonb, false, v_system_user_id),
    ('fa:undo', 'fa', 'Undo', 'actions', 'Undo icon', ARRAY['undo', 'revert'], '{"class": "fas fa-undo"}'::jsonb, false, v_system_user_id),
    ('fa:redo', 'fa', 'Redo', 'actions', 'Redo icon', ARRAY['redo', 'repeat'], '{"class": "fas fa-redo"}'::jsonb, false, v_system_user_id),
    ('fa:refresh', 'fa', 'Refresh', 'actions', 'Refresh icon', ARRAY['refresh', 'reload'], '{"class": "fas fa-sync"}'::jsonb, false, v_system_user_id),
    ('fa:filter', 'fa', 'Filter', 'actions', 'Filter icon', ARRAY['filter', 'sort'], '{"class": "fas fa-filter"}'::jsonb, false, v_system_user_id),
    ('fa:eye', 'fa', 'View', 'actions', 'Eye/view icon', ARRAY['eye', 'view'], '{"class": "fas fa-eye"}'::jsonb, false, v_system_user_id),
    ('fa:eye-slash', 'fa', 'Hide', 'actions', 'Eye slash/hide icon', ARRAY['hide', 'invisible'], '{"class": "fas fa-eye-slash"}'::jsonb, false, v_system_user_id),
    ('fa:print', 'fa', 'Print', 'actions', 'Print icon', ARRAY['print', 'printer'], '{"class": "fas fa-print"}'::jsonb, false, v_system_user_id),
    ('fa:share', 'fa', 'Share', 'actions', 'Share icon', ARRAY['share', 'send'], '{"class": "fas fa-share"}'::jsonb, false, v_system_user_id),
    ('fa:link', 'fa', 'Link', 'actions', 'Link icon', ARRAY['link', 'url'], '{"class": "fas fa-link"}'::jsonb, false, v_system_user_id),
    ('fa:calendar', 'fa', 'Calendar', 'time', 'Calendar icon', ARRAY['calendar', 'date'], '{"class": "fas fa-calendar"}'::jsonb, false, v_system_user_id),
    ('fa:clock', 'fa', 'Clock', 'time', 'Clock icon', ARRAY['clock', 'time'], '{"class": "fas fa-clock"}'::jsonb, false, v_system_user_id),
    ('fa:money-bill', 'fa', 'Money', 'business', 'Money bill icon', ARRAY['money', 'cash'], '{"class": "fas fa-money-bill"}'::jsonb, false, v_system_user_id),
    ('fa:credit-card', 'fa', 'Credit Card', 'business', 'Credit card icon', ARRAY['credit', 'card'], '{"class": "fas fa-credit-card"}'::jsonb, false, v_system_user_id),
    ('fa:chart-line', 'fa', 'Chart Line', 'data', 'Line chart icon', ARRAY['chart', 'line'], '{"class": "fas fa-chart-line"}'::jsonb, false, v_system_user_id),
    ('fa:chart-pie', 'fa', 'Chart Pie', 'data', 'Pie chart icon', ARRAY['chart', 'pie'], '{"class": "fas fa-chart-pie"}'::jsonb, false, v_system_user_id),
    ('fa:calculator', 'fa', 'Calculator', 'tools', 'Calculator icon', ARRAY['calculator', 'math'], '{"class": "fas fa-calculator"}'::jsonb, false, v_system_user_id),
    ('fa:comment', 'fa', 'Comment', 'communication', 'Comment icon', ARRAY['comment', 'message'], '{"class": "fas fa-comment"}'::jsonb, false, v_system_user_id),
    ('fa:comments', 'fa', 'Comments', 'communication', 'Comments icon', ARRAY['comments', 'messages'], '{"class": "fas fa-comments"}'::jsonb, false, v_system_user_id),
    ('fa:video', 'fa', 'Video', 'media', 'Video icon', ARRAY['video', 'camera'], '{"class": "fas fa-video"}'::jsonb, false, v_system_user_id),
    ('fa:microphone', 'fa', 'Microphone', 'media', 'Microphone icon', ARRAY['microphone', 'audio'], '{"class": "fas fa-microphone"}'::jsonb, false, v_system_user_id),
    ('fa:image', 'fa', 'Image', 'media', 'Image icon', ARRAY['image', 'picture'], '{"class": "fas fa-image"}'::jsonb, false, v_system_user_id),
    ('fa:camera', 'fa', 'Camera', 'media', 'Camera icon', ARRAY['camera', 'photo'], '{"class": "fas fa-camera"}'::jsonb, false, v_system_user_id),
    ('fa:bars', 'fa', 'Menu', 'navigation', 'Bars/menu icon', ARRAY['menu', 'bars'], '{"class": "fas fa-bars"}'::jsonb, false, v_system_user_id),
    ('fa:list', 'fa', 'List', 'navigation', 'List icon', ARRAY['list', 'items'], '{"class": "fas fa-list"}'::jsonb, false, v_system_user_id),
    ('fa:table', 'fa', 'Table', 'data', 'Table icon', ARRAY['table', 'grid'], '{"class": "fas fa-table"}'::jsonb, false, v_system_user_id),
    ('fa:angle-left', 'fa', 'Angle Left', 'navigation', 'Angle left icon', ARRAY['angle', 'left'], '{"class": "fas fa-angle-left"}'::jsonb, false, v_system_user_id),
    ('fa:angle-right', 'fa', 'Angle Right', 'navigation', 'Angle right icon', ARRAY['angle', 'right'], '{"class": "fas fa-angle-right"}'::jsonb, false, v_system_user_id),
    ('fa:chevron-left', 'fa', 'Chevron Left', 'navigation', 'Chevron left icon', ARRAY['chevron', 'left'], '{"class": "fas fa-chevron-left"}'::jsonb, false, v_system_user_id),
    ('fa:chevron-right', 'fa', 'Chevron Right', 'navigation', 'Chevron right icon', ARRAY['chevron', 'right'], '{"class": "fas fa-chevron-right"}'::jsonb, false, v_system_user_id),
    ('fa:file-pdf', 'fa', 'PDF', 'documents', 'PDF file icon', ARRAY['pdf', 'file'], '{"class": "fas fa-file-pdf"}'::jsonb, false, v_system_user_id),
    ('fa:file-word', 'fa', 'Word', 'documents', 'Word file icon', ARRAY['word', 'doc'], '{"class": "fas fa-file-word"}'::jsonb, false, v_system_user_id),
    ('fa:file-excel', 'fa', 'Excel', 'documents', 'Excel file icon', ARRAY['excel', 'xls'], '{"class": "fas fa-file-excel"}'::jsonb, false, v_system_user_id),
    ('fa:youtube', 'fa', 'YouTube', 'social', 'YouTube icon', ARRAY['youtube', 'video'], '{"class": "fab fa-youtube"}'::jsonb, false, v_system_user_id),
    ('fa:github', 'fa', 'GitHub', 'social', 'GitHub icon', ARRAY['github', 'code'], '{"class": "fab fa-github"}'::jsonb, false, v_system_user_id),
    ('fa:whatsapp', 'fa', 'WhatsApp', 'social', 'WhatsApp icon', ARRAY['whatsapp', 'chat'], '{"class": "fab fa-whatsapp"}'::jsonb, false, v_system_user_id),
    ('fa:slack', 'fa', 'Slack', 'social', 'Slack icon', ARRAY['slack', 'chat'], '{"class": "fab fa-slack"}'::jsonb, false, v_system_user_id),
    ('fa:spinner', 'fa', 'Spinner', 'status', 'Spinner/loading icon', ARRAY['spinner', 'loading'], '{"class": "fas fa-spinner"}'::jsonb, false, v_system_user_id),
    ('fa:question-circle', 'fa', 'Question', 'status', 'Question circle icon', ARRAY['question', 'help'], '{"class": "far fa-circle-question"}'::jsonb, false, v_system_user_id),
    ('fa:wrench', 'fa', 'Wrench', 'tools', 'Wrench icon', ARRAY['wrench', 'tool'], '{"class": "fas fa-wrench"}'::jsonb, false, v_system_user_id),
    ('fa:map', 'fa', 'Map', 'location', 'Map icon', ARRAY['map', 'location'], '{"class": "fas fa-map"}'::jsonb, false, v_system_user_id),
    ('fa:globe', 'fa', 'Globe', 'location', 'Globe icon', ARRAY['globe', 'world'], '{"class": "fas fa-globe"}'::jsonb, false, v_system_user_id),
    ('fa:shopping-cart', 'fa', 'Shopping Cart', 'shopping', 'Shopping cart icon', ARRAY['cart', 'shopping'], '{"class": "fas fa-shopping-cart"}'::jsonb, false, v_system_user_id),
    ('fa:tag', 'fa', 'Tag', 'shopping', 'Tag icon', ARRAY['tag', 'label'], '{"class": "fas fa-tag"}'::jsonb, false, v_system_user_id),
    ('fa:gift', 'fa', 'Gift', 'shopping', 'Gift icon', ARRAY['gift', 'present'], '{"class": "fas fa-gift"}'::jsonb, false, v_system_user_id),
    ('fa:graduation-cap', 'fa', 'Graduation Cap', 'education', 'Graduation cap icon', ARRAY['graduation', 'education'], '{"class": "fas fa-graduation-cap"}'::jsonb, false, v_system_user_id),
    ('fa:utensils', 'fa', 'Utensils', 'food', 'Utensils icon', ARRAY['utensils', 'food'], '{"class": "fas fa-utensils"}'::jsonb, false, v_system_user_id),
    ('fa:coffee', 'fa', 'Coffee', 'food', 'Coffee icon', ARRAY['coffee', 'drink'], '{"class": "fas fa-mug-hot"}'::jsonb, false, v_system_user_id),
    ('fa:laptop', 'fa', 'Laptop', 'technology', 'Laptop icon', ARRAY['laptop', 'computer'], '{"class": "fas fa-laptop"}'::jsonb, false, v_system_user_id),
    ('fa:mobile-alt', 'fa', 'Mobile', 'technology', 'Mobile icon', ARRAY['mobile', 'phone'], '{"class": "fas fa-mobile-screen-button"}'::jsonb, false, v_system_user_id),
    ('fa:wifi', 'fa', 'WiFi', 'technology', 'WiFi icon', ARRAY['wifi', 'wireless'], '{"class": "fas fa-wifi"}'::jsonb, false, v_system_user_id),
    ('fa:code', 'fa', 'Code', 'development', 'Code icon', ARRAY['code', 'programming'], '{"class": "fas fa-code"}'::jsonb, false, v_system_user_id),
    ('fa:terminal', 'fa', 'Terminal', 'development', 'Terminal icon', ARRAY['terminal', 'command'], '{"class": "fas fa-terminal"}'::jsonb, false, v_system_user_id)
    ON CONFLICT (icon_code) DO NOTHING;

    -- Additional FontAwesome Icons (Part 2)
    INSERT INTO public.icons (icon_code, icon_type, icon_name, category, description, tags, icon_data, is_popular, created_by) VALUES
    ('fa:sort', 'fa', 'Sort', 'actions', 'Sort icon', ARRAY['sort', 'order'], '{"class": "fas fa-sort"}'::jsonb, false, v_system_user_id),
    ('fa:expand', 'fa', 'Expand', 'navigation', 'Expand icon', ARRAY['expand', 'fullscreen'], '{"class": "fas fa-expand"}'::jsonb, false, v_system_user_id),
    ('fa:compress', 'fa', 'Compress', 'navigation', 'Compress icon', ARRAY['compress'], '{"class": "fas fa-compress"}'::jsonb, false, v_system_user_id),
    ('fa:caret-down', 'fa', 'Caret Down', 'navigation', 'Caret down icon', ARRAY['caret', 'down'], '{"class": "fas fa-caret-down"}'::jsonb, false, v_system_user_id),
    ('fa:caret-up', 'fa', 'Caret Up', 'navigation', 'Caret up icon', ARRAY['caret', 'up'], '{"class": "fas fa-caret-up"}'::jsonb, false, v_system_user_id),
    ('fa:folder-open', 'fa', 'Folder Open', 'documents', 'Folder open icon', ARRAY['folder', 'open'], '{"class": "fas fa-folder-open"}'::jsonb, false, v_system_user_id),
    ('fa:book', 'fa', 'Book', 'documents', 'Book icon', ARRAY['book', 'read'], '{"class": "fas fa-book"}'::jsonb, false, v_system_user_id),
    ('fa:bookmark', 'fa', 'Bookmark', 'documents', 'Bookmark icon', ARRAY['bookmark', 'save'], '{"class": "fas fa-bookmark"}'::jsonb, false, v_system_user_id),
    ('fa:newspaper', 'fa', 'Newspaper', 'documents', 'Newspaper icon', ARRAY['newspaper', 'news'], '{"class": "far fa-newspaper"}'::jsonb, false, v_system_user_id),
    ('fa:reddit', 'fa', 'Reddit', 'social', 'Reddit icon', ARRAY['reddit', 'social'], '{"class": "fab fa-reddit"}'::jsonb, false, v_system_user_id),
    ('fa:discord', 'fa', 'Discord', 'social', 'Discord icon', ARRAY['discord', 'chat'], '{"class": "fab fa-discord"}'::jsonb, false, v_system_user_id),
    ('fa:telegram', 'fa', 'Telegram', 'social', 'Telegram icon', ARRAY['telegram', 'chat'], '{"class": "fab fa-telegram"}'::jsonb, false, v_system_user_id),
    ('fa:skype', 'fa', 'Skype', 'social', 'Skype icon', ARRAY['skype', 'chat'], '{"class": "fab fa-skype"}'::jsonb, false, v_system_user_id),
    ('fa:pinterest', 'fa', 'Pinterest', 'social', 'Pinterest icon', ARRAY['pinterest', 'social'], '{"class": "fab fa-pinterest"}'::jsonb, false, v_system_user_id),
    ('fa:dribbble', 'fa', 'Dribbble', 'social', 'Dribbble icon', ARRAY['dribbble', 'design'], '{"class": "fab fa-dribbble"}'::jsonb, false, v_system_user_id),
    ('fa:behance', 'fa', 'Behance', 'social', 'Behance icon', ARRAY['behance', 'design'], '{"class": "fab fa-behance"}'::jsonb, false, v_system_user_id),
    ('fa:circle', 'fa', 'Circle', 'status', 'Circle icon', ARRAY['circle', 'dot'], '{"class": "far fa-circle"}'::jsonb, false, v_system_user_id),
    ('fa:ban', 'fa', 'Ban', 'status', 'Ban icon', ARRAY['ban', 'block'], '{"class": "fas fa-ban"}'::jsonb, false, v_system_user_id),
    ('fa:play-circle', 'fa', 'Play', 'media', 'Play circle icon', ARRAY['play', 'video'], '{"class": "far fa-circle-play"}'::jsonb, false, v_system_user_id),
    ('fa:pause-circle', 'fa', 'Pause', 'media', 'Pause circle icon', ARRAY['pause', 'video'], '{"class": "far fa-circle-pause"}'::jsonb, false, v_system_user_id),
    ('fa:stop-circle', 'fa', 'Stop', 'media', 'Stop circle icon', ARRAY['stop', 'video'], '{"class": "far fa-circle-stop"}'::jsonb, false, v_system_user_id),
    ('fa:paint-brush', 'fa', 'Paint Brush', 'tools', 'Paint brush icon', ARRAY['paint', 'brush'], '{"class": "fas fa-paint-brush"}'::jsonb, false, v_system_user_id),
    ('fa:palette', 'fa', 'Palette', 'tools', 'Palette icon', ARRAY['palette', 'color'], '{"class": "fas fa-palette"}'::jsonb, false, v_system_user_id),
    ('fa:sliders-h', 'fa', 'Sliders', 'settings', 'Sliders icon', ARRAY['sliders', 'settings'], '{"class": "fas fa-sliders"}'::jsonb, false, v_system_user_id),
    ('fa:toggle-on', 'fa', 'Toggle On', 'settings', 'Toggle on icon', ARRAY['toggle', 'on'], '{"class": "fas fa-toggle-on"}'::jsonb, false, v_system_user_id),
    ('fa:toggle-off', 'fa', 'Toggle Off', 'settings', 'Toggle off icon', ARRAY['toggle', 'off'], '{"class": "fas fa-toggle-off"}'::jsonb, false, v_system_user_id),
    ('fa:power-off', 'fa', 'Power Off', 'settings', 'Power off icon', ARRAY['power', 'off'], '{"class": "fas fa-power-off"}'::jsonb, false, v_system_user_id),
    ('fa:lightbulb', 'fa', 'Lightbulb', 'tools', 'Lightbulb icon', ARRAY['lightbulb', 'idea'], '{"class": "far fa-lightbulb"}'::jsonb, false, v_system_user_id),
    ('fa:map-marker', 'fa', 'Map Marker', 'location', 'Map marker icon', ARRAY['map', 'marker'], '{"class": "fas fa-location-dot"}'::jsonb, false, v_system_user_id),
    ('fa:plane', 'fa', 'Plane', 'travel', 'Plane icon', ARRAY['plane', 'airplane'], '{"class": "fas fa-plane"}'::jsonb, false, v_system_user_id),
    ('fa:car', 'fa', 'Car', 'travel', 'Car icon', ARRAY['car', 'vehicle'], '{"class": "fas fa-car"}'::jsonb, false, v_system_user_id),
    ('fa:bus', 'fa', 'Bus', 'travel', 'Bus icon', ARRAY['bus', 'vehicle'], '{"class": "fas fa-bus"}'::jsonb, false, v_system_user_id),
    ('fa:train', 'fa', 'Train', 'travel', 'Train icon', ARRAY['train', 'vehicle'], '{"class": "fas fa-train"}'::jsonb, false, v_system_user_id),
    ('fa:shipping-fast', 'fa', 'Shipping Fast', 'shopping', 'Fast shipping icon', ARRAY['shipping', 'fast'], '{"class": "fas fa-shipping-fast"}'::jsonb, false, v_system_user_id),
    ('fa:truck', 'fa', 'Truck', 'shopping', 'Truck icon', ARRAY['truck', 'delivery'], '{"class": "fas fa-truck"}'::jsonb, false, v_system_user_id),
    ('fa:heartbeat', 'fa', 'Heartbeat', 'health', 'Heartbeat icon', ARRAY['heartbeat', 'health'], '{"class": "fas fa-heartbeat"}'::jsonb, false, v_system_user_id),
    ('fa:stethoscope', 'fa', 'Stethoscope', 'health', 'Stethoscope icon', ARRAY['stethoscope', 'medical'], '{"class": "fas fa-stethoscope"}'::jsonb, false, v_system_user_id),
    ('fa:hospital', 'fa', 'Hospital', 'health', 'Hospital icon', ARRAY['hospital', 'medical'], '{"class": "fas fa-hospital"}'::jsonb, false, v_system_user_id),
    ('fa:school', 'fa', 'School', 'education', 'School icon', ARRAY['school', 'education'], '{"class": "fas fa-school"}'::jsonb, false, v_system_user_id),
    ('fa:university', 'fa', 'University', 'education', 'University icon', ARRAY['university', 'education'], '{"class": "fas fa-building-columns"}'::jsonb, false, v_system_user_id),
    ('fa:wine-glass', 'fa', 'Wine Glass', 'food', 'Wine glass icon', ARRAY['wine', 'drink'], '{"class": "fas fa-wine-glass"}'::jsonb, false, v_system_user_id),
    ('fa:pizza-slice', 'fa', 'Pizza', 'food', 'Pizza slice icon', ARRAY['pizza', 'food'], '{"class": "fas fa-pizza-slice"}'::jsonb, false, v_system_user_id),
    ('fa:football-ball', 'fa', 'Football', 'sports', 'Football icon', ARRAY['football', 'sports'], '{"class": "fas fa-football"}'::jsonb, false, v_system_user_id),
    ('fa:basketball-ball', 'fa', 'Basketball', 'sports', 'Basketball icon', ARRAY['basketball', 'sports'], '{"class": "fas fa-basketball"}'::jsonb, false, v_system_user_id),
    ('fa:gamepad', 'fa', 'Gamepad', 'games', 'Gamepad icon', ARRAY['gamepad', 'game'], '{"class": "fas fa-gamepad"}'::jsonb, false, v_system_user_id),
    ('fa:sun', 'fa', 'Sun', 'weather', 'Sun icon', ARRAY['sun', 'weather'], '{"class": "far fa-sun"}'::jsonb, false, v_system_user_id),
    ('fa:moon', 'fa', 'Moon', 'weather', 'Moon icon', ARRAY['moon', 'night'], '{"class": "far fa-moon"}'::jsonb, false, v_system_user_id),
    ('fa:cloud', 'fa', 'Cloud', 'weather', 'Cloud icon', ARRAY['cloud', 'weather'], '{"class": "fas fa-cloud"}'::jsonb, false, v_system_user_id),
    ('fa:cloud-rain', 'fa', 'Rain', 'weather', 'Cloud rain icon', ARRAY['rain', 'weather'], '{"class": "fas fa-cloud-rain"}'::jsonb, false, v_system_user_id),
    ('fa:snowflake', 'fa', 'Snowflake', 'weather', 'Snowflake icon', ARRAY['snowflake', 'snow'], '{"class": "far fa-snowflake"}'::jsonb, false, v_system_user_id),
    ('fa:umbrella', 'fa', 'Umbrella', 'weather', 'Umbrella icon', ARRAY['umbrella', 'rain'], '{"class": "fas fa-umbrella"}'::jsonb, false, v_system_user_id),
    ('fa:bolt', 'fa', 'Bolt', 'weather', 'Bolt/lightning icon', ARRAY['bolt', 'lightning'], '{"class": "fas fa-bolt"}'::jsonb, false, v_system_user_id),
    ('fa:gem', 'fa', 'Gem', 'objects', 'Gem icon', ARRAY['gem', 'diamond'], '{"class": "far fa-gem"}'::jsonb, false, v_system_user_id),
    ('fa:crown', 'fa', 'Crown', 'objects', 'Crown icon', ARRAY['crown', 'royal'], '{"class": "fas fa-crown"}'::jsonb, false, v_system_user_id),
    ('fa:trophy', 'fa', 'Trophy', 'objects', 'Trophy icon', ARRAY['trophy', 'award'], '{"class": "fas fa-trophy"}'::jsonb, false, v_system_user_id),
    ('fa:medal', 'fa', 'Medal', 'objects', 'Medal icon', ARRAY['medal', 'award'], '{"class": "fas fa-medal"}'::jsonb, false, v_system_user_id),
    ('fa:award', 'fa', 'Award', 'objects', 'Award icon', ARRAY['award', 'prize'], '{"class": "fas fa-award"}'::jsonb, false, v_system_user_id),
    ('fa:flag', 'fa', 'Flag', 'objects', 'Flag icon', ARRAY['flag', 'country'], '{"class": "fas fa-flag"}'::jsonb, false, v_system_user_id),
    ('fa:hand-paper', 'fa', 'Hand Paper', 'actions', 'Hand paper/stop icon', ARRAY['hand', 'stop'], '{"class": "far fa-hand"}'::jsonb, false, v_system_user_id),
    ('fa:thumbs-down', 'fa', 'Thumbs Down', 'actions', 'Thumbs down icon', ARRAY['thumbs', 'down'], '{"class": "far fa-thumbs-down"}'::jsonb, false, v_system_user_id),
    ('fa:handshake', 'fa', 'Handshake', 'business', 'Handshake icon', ARRAY['handshake', 'deal'], '{"class": "far fa-handshake"}'::jsonb, false, v_system_user_id),
    ('fa:user-tie', 'fa', 'User Tie', 'business', 'User tie icon', ARRAY['user', 'tie'], '{"class": "fas fa-user-tie"}'::jsonb, false, v_system_user_id),
    ('fa:user-graduate', 'fa', 'User Graduate', 'education', 'User graduate icon', ARRAY['user', 'graduate'], '{"class": "fas fa-user-graduate"}'::jsonb, false, v_system_user_id),
    ('fa:user-shield', 'fa', 'User Shield', 'security', 'User shield icon', ARRAY['user', 'shield'], '{"class": "fas fa-user-shield"}'::jsonb, false, v_system_user_id),
    ('fa:user-plus', 'fa', 'User Plus', 'users', 'User plus icon', ARRAY['user', 'plus'], '{"class": "fas fa-user-plus"}'::jsonb, false, v_system_user_id),
    ('fa:user-minus', 'fa', 'User Minus', 'users', 'User minus icon', ARRAY['user', 'minus'], '{"class": "fas fa-user-minus"}'::jsonb, false, v_system_user_id),
    ('fa:id-card', 'fa', 'ID Card', 'users', 'ID card icon', ARRAY['id', 'card'], '{"class": "far fa-id-card"}'::jsonb, false, v_system_user_id),
    ('fa:desktop', 'fa', 'Desktop', 'technology', 'Desktop icon', ARRAY['desktop', 'computer'], '{"class": "fas fa-desktop"}'::jsonb, false, v_system_user_id),
    ('fa:tablet', 'fa', 'Tablet', 'technology', 'Tablet icon', ARRAY['tablet', 'device'], '{"class": "fas fa-tablet"}'::jsonb, false, v_system_user_id),
    ('fa:server', 'fa', 'Server', 'technology', 'Server icon', ARRAY['server', 'computer'], '{"class": "fas fa-server"}'::jsonb, false, v_system_user_id),
    ('fa:keyboard', 'fa', 'Keyboard', 'technology', 'Keyboard icon', ARRAY['keyboard', 'input'], '{"class": "far fa-keyboard"}'::jsonb, false, v_system_user_id),
    ('fa:mouse', 'fa', 'Mouse', 'technology', 'Mouse icon', ARRAY['mouse', 'input'], '{"class": "fas fa-computer-mouse"}'::jsonb, false, v_system_user_id),
    ('fa:headset', 'fa', 'Headset', 'technology', 'Headset icon', ARRAY['headset', 'audio'], '{"class": "fas fa-headset"}'::jsonb, false, v_system_user_id),
    ('fa:tv', 'fa', 'TV', 'technology', 'TV icon', ARRAY['tv', 'television'], '{"class": "fas fa-tv"}'::jsonb, false, v_system_user_id),
    ('fa:fingerprint', 'fa', 'Fingerprint', 'security', 'Fingerprint icon', ARRAY['fingerprint', 'biometric'], '{"class": "fas fa-fingerprint"}'::jsonb, false, v_system_user_id),
    ('fa:lock-open', 'fa', 'Lock Open', 'security', 'Lock open icon', ARRAY['lock', 'open'], '{"class": "fas fa-lock-open"}'::jsonb, false, v_system_user_id),
    ('fa:sync', 'fa', 'Sync', 'actions', 'Sync icon', ARRAY['sync', 'synchronize'], '{"class": "fas fa-arrows-rotate"}'::jsonb, false, v_system_user_id),
    ('fa:random', 'fa', 'Random', 'actions', 'Random icon', ARRAY['random', 'shuffle'], '{"class": "fas fa-shuffle"}'::jsonb, false, v_system_user_id),
    ('fa:external-link-alt', 'fa', 'External Link', 'navigation', 'External link icon', ARRAY['external', 'link'], '{"class": "fas fa-arrow-up-right-from-square"}'::jsonb, false, v_system_user_id),
    ('fa:sign-in-alt', 'fa', 'Sign In', 'authentication', 'Sign in icon', ARRAY['sign', 'in'], '{"class": "fas fa-right-to-bracket"}'::jsonb, false, v_system_user_id),
    ('fa:sign-out-alt', 'fa', 'Sign Out', 'authentication', 'Sign out icon', ARRAY['sign', 'out'], '{"class": "fas fa-right-from-bracket"}'::jsonb, false, v_system_user_id),
    ('fa:language', 'fa', 'Language', 'communication', 'Language icon', ARRAY['language', 'translate'], '{"class": "fas fa-language"}'::jsonb, false, v_system_user_id),
    ('fa:bold', 'fa', 'Bold', 'text', 'Bold icon', ARRAY['bold', 'text'], '{"class": "fas fa-bold"}'::jsonb, false, v_system_user_id),
    ('fa:italic', 'fa', 'Italic', 'text', 'Italic icon', ARRAY['italic', 'text'], '{"class": "fas fa-italic"}'::jsonb, false, v_system_user_id),
    ('fa:underline', 'fa', 'Underline', 'text', 'Underline icon', ARRAY['underline', 'text'], '{"class": "fas fa-underline"}'::jsonb, false, v_system_user_id),
    ('fa:bug', 'fa', 'Bug', 'development', 'Bug icon', ARRAY['bug', 'error'], '{"class": "fas fa-bug"}'::jsonb, false, v_system_user_id),
    ('fa:code-branch', 'fa', 'Code Branch', 'development', 'Code branch icon', ARRAY['branch', 'git'], '{"class": "fas fa-code-branch"}'::jsonb, false, v_system_user_id),
    ('fa:html5', 'fa', 'HTML5', 'development', 'HTML5 icon', ARRAY['html5', 'web'], '{"class": "fab fa-html5"}'::jsonb, false, v_system_user_id),
    ('fa:css3', 'fa', 'CSS3', 'development', 'CSS3 icon', ARRAY['css3', 'web'], '{"class": "fab fa-css3-alt"}'::jsonb, false, v_system_user_id),
    ('fa:js', 'fa', 'JavaScript', 'development', 'JavaScript icon', ARRAY['javascript', 'js'], '{"class": "fab fa-js"}'::jsonb, false, v_system_user_id),
    ('fa:python', 'fa', 'Python', 'development', 'Python icon', ARRAY['python', 'programming'], '{"class": "fab fa-python"}'::jsonb, false, v_system_user_id),
    ('fa:node-js', 'fa', 'Node.js', 'development', 'Node.js icon', ARRAY['nodejs', 'javascript'], '{"class": "fab fa-node-js"}'::jsonb, false, v_system_user_id),
    ('fa:react', 'fa', 'React', 'development', 'React icon', ARRAY['react', 'javascript'], '{"class": "fab fa-react"}'::jsonb, false, v_system_user_id),
    ('fa:vue', 'fa', 'Vue', 'development', 'Vue icon', ARRAY['vue', 'javascript'], '{"class": "fab fa-vuejs"}'::jsonb, false, v_system_user_id),
    ('fa:angular', 'fa', 'Angular', 'development', 'Angular icon', ARRAY['angular', 'javascript'], '{"class": "fab fa-angular"}'::jsonb, false, v_system_user_id),
    ('fa:bootstrap', 'fa', 'Bootstrap', 'development', 'Bootstrap icon', ARRAY['bootstrap', 'css'], '{"class": "fab fa-bootstrap"}'::jsonb, false, v_system_user_id),
    ('fa:npm', 'fa', 'NPM', 'development', 'NPM icon', ARRAY['npm', 'package'], '{"class": "fab fa-npm"}'::jsonb, false, v_system_user_id),
    ('fa:docker', 'fa', 'Docker', 'development', 'Docker icon', ARRAY['docker', 'container'], '{"class": "fab fa-docker"}'::jsonb, false, v_system_user_id),
    ('fa:aws', 'fa', 'AWS', 'development', 'AWS icon', ARRAY['aws', 'cloud'], '{"class": "fab fa-aws"}'::jsonb, false, v_system_user_id),
    ('fa:linux', 'fa', 'Linux', 'development', 'Linux icon', ARRAY['linux', 'os'], '{"class": "fab fa-linux"}'::jsonb, false, v_system_user_id),
    ('fa:windows', 'fa', 'Windows', 'development', 'Windows icon', ARRAY['windows', 'os'], '{"class": "fab fa-windows"}'::jsonb, false, v_system_user_id),
    ('fa:apple', 'fa', 'Apple', 'development', 'Apple icon', ARRAY['apple', 'os'], '{"class": "fab fa-apple"}'::jsonb, false, v_system_user_id),
    ('fa:android', 'fa', 'Android', 'development', 'Android icon', ARRAY['android', 'mobile'], '{"class": "fab fa-android"}'::jsonb, false, v_system_user_id),
    ('fa:chrome', 'fa', 'Chrome', 'development', 'Chrome icon', ARRAY['chrome', 'browser'], '{"class": "fab fa-chrome"}'::jsonb, false, v_system_user_id),
    ('fa:firefox', 'fa', 'Firefox', 'development', 'Firefox icon', ARRAY['firefox', 'browser'], '{"class": "fab fa-firefox"}'::jsonb, false, v_system_user_id),
    ('fa:safari', 'fa', 'Safari', 'development', 'Safari icon', ARRAY['safari', 'browser'], '{"class": "fab fa-safari"}'::jsonb, false, v_system_user_id),
        ON CONFLICT (icon_code) DO NOTHING;

    -- Additional Ant Design Icons
    INSERT INTO public.icons (icon_code, icon_type, icon_name, category, description, tags, icon_data, is_popular, created_by) VALUES
    INSERT INTO public.icons (icon_code, icon_type, icon_name, category, description, tags, icon_data, is_popular, created_by) VALUES
    ('antd:copy', 'antd', 'Copy', 'actions', 'Copy icon (Ant Design)', ARRAY['copy', 'duplicate'], '{"component": "CopyOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:cut', 'antd', 'Cut', 'actions', 'Cut icon (Ant Design)', ARRAY['cut'], '{"component": "ScissorOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:paste', 'antd', 'Paste', 'actions', 'Paste icon (Ant Design)', ARRAY['paste'], '{"component": "SnippetsOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:undo', 'antd', 'Undo', 'actions', 'Undo icon (Ant Design)', ARRAY['undo'], '{"component": "UndoOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:redo', 'antd', 'Redo', 'actions', 'Redo icon (Ant Design)', ARRAY['redo'], '{"component": "RedoOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:reload', 'antd', 'Reload', 'actions', 'Reload icon (Ant Design)', ARRAY['reload', 'refresh'], '{"component": "ReloadOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:filter', 'antd', 'Filter', 'actions', 'Filter icon (Ant Design)', ARRAY['filter'], '{"component": "FilterOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:eye', 'antd', 'View', 'actions', 'Eye/view icon (Ant Design)', ARRAY['eye', 'view'], '{"component": "EyeOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:eye-invisible', 'antd', 'Hide', 'actions', 'Eye invisible icon (Ant Design)', ARRAY['hide'], '{"component": "EyeInvisibleOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:printer', 'antd', 'Print', 'actions', 'Print icon (Ant Design)', ARRAY['print'], '{"component": "PrinterOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:share-alt', 'antd', 'Share', 'actions', 'Share icon (Ant Design)', ARRAY['share'], '{"component": "ShareAltOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:link', 'antd', 'Link', 'actions', 'Link icon (Ant Design)', ARRAY['link'], '{"component": "LinkOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:calendar', 'antd', 'Calendar', 'time', 'Calendar icon (Ant Design)', ARRAY['calendar'], '{"component": "CalendarOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:clock-circle', 'antd', 'Clock', 'time', 'Clock icon (Ant Design)', ARRAY['clock', 'time'], '{"component": "ClockCircleOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:dollar', 'antd', 'Dollar', 'business', 'Dollar icon (Ant Design)', ARRAY['dollar', 'money'], '{"component": "DollarOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:credit-card', 'antd', 'Credit Card', 'business', 'Credit card icon (Ant Design)', ARRAY['credit', 'card'], '{"component": "CreditCardOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:line-chart', 'antd', 'Line Chart', 'data', 'Line chart icon (Ant Design)', ARRAY['chart', 'line'], '{"component": "LineChartOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:pie-chart', 'antd', 'Pie Chart', 'data', 'Pie chart icon (Ant Design)', ARRAY['chart', 'pie'], '{"component": "PieChartOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:bar-chart', 'antd', 'Bar Chart', 'data', 'Bar chart icon (Ant Design)', ARRAY['chart', 'bar'], '{"component": "BarChartOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:calculator', 'antd', 'Calculator', 'tools', 'Calculator icon (Ant Design)', ARRAY['calculator'], '{"component": "CalculatorOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:message', 'antd', 'Message', 'communication', 'Message icon (Ant Design)', ARRAY['message'], '{"component": "MessageOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:comment', 'antd', 'Comment', 'communication', 'Comment icon (Ant Design)', ARRAY['comment'], '{"component": "CommentOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:video-camera', 'antd', 'Video', 'media', 'Video camera icon (Ant Design)', ARRAY['video'], '{"component": "VideoCameraOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:audio', 'antd', 'Audio', 'media', 'Audio icon (Ant Design)', ARRAY['audio'], '{"component": "AudioOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:picture', 'antd', 'Picture', 'media', 'Picture icon (Ant Design)', ARRAY['picture', 'image'], '{"component": "PictureOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:camera', 'antd', 'Camera', 'media', 'Camera icon (Ant Design)', ARRAY['camera'], '{"component": "CameraOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:menu', 'antd', 'Menu', 'navigation', 'Menu icon (Ant Design)', ARRAY['menu'], '{"component": "MenuOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:unordered-list', 'antd', 'List', 'navigation', 'List icon (Ant Design)', ARRAY['list'], '{"component": "UnorderedListOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:table', 'antd', 'Table', 'data', 'Table icon (Ant Design)', ARRAY['table'], '{"component": "TableOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:left', 'antd', 'Left', 'navigation', 'Left icon (Ant Design)', ARRAY['left'], '{"component": "LeftOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:right', 'antd', 'Right', 'navigation', 'Right icon (Ant Design)', ARRAY['right'], '{"component": "RightOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:up', 'antd', 'Up', 'navigation', 'Up icon (Ant Design)', ARRAY['up'], '{"component": "UpOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:down', 'antd', 'Down', 'navigation', 'Down icon (Ant Design)', ARRAY['down'], '{"component": "DownOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:double-left', 'antd', 'Double Left', 'navigation', 'Double left icon (Ant Design)', ARRAY['left', 'double'], '{"component": "DoubleLeftOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:double-right', 'antd', 'Double Right', 'navigation', 'Double right icon (Ant Design)', ARRAY['right', 'double'], '{"component": "DoubleRightOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:file-text', 'antd', 'File Text', 'documents', 'File text icon (Ant Design)', ARRAY['file', 'text'], '{"component": "FileTextOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:folder-open', 'antd', 'Folder Open', 'documents', 'Folder open icon (Ant Design)', ARRAY['folder', 'open'], '{"component": "FolderOpenOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:book', 'antd', 'Book', 'documents', 'Book icon (Ant Design)', ARRAY['book'], '{"component": "BookOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:youtube', 'antd', 'YouTube', 'social', 'YouTube icon (Ant Design)', ARRAY['youtube'], '{"component": "YoutubeOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:github', 'antd', 'GitHub', 'social', 'GitHub icon (Ant Design)', ARRAY['github'], '{"component": "GithubOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:loading', 'antd', 'Loading', 'status', 'Loading icon (Ant Design)', ARRAY['loading', 'spinner'], '{"component": "LoadingOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:question-circle', 'antd', 'Question', 'status', 'Question circle icon (Ant Design)', ARRAY['question'], '{"component": "QuestionCircleOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:tool', 'antd', 'Tool', 'tools', 'Tool icon (Ant Design)', ARRAY['tool'], '{"component": "ToolOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:global', 'antd', 'Global', 'location', 'Global icon (Ant Design)', ARRAY['global', 'world'], '{"component": "GlobalOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:shopping-cart', 'antd', 'Shopping Cart', 'shopping', 'Shopping cart icon (Ant Design)', ARRAY['cart'], '{"component": "ShoppingCartOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:tag', 'antd', 'Tag', 'shopping', 'Tag icon (Ant Design)', ARRAY['tag'], '{"component": "TagOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:gift', 'antd', 'Gift', 'shopping', 'Gift icon (Ant Design)', ARRAY['gift'], '{"component": "GiftOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:graduation-cap', 'antd', 'Graduation', 'education', 'Graduation cap icon (Ant Design)', ARRAY['graduation'], '{"component": "ReadOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:laptop', 'antd', 'Laptop', 'technology', 'Laptop icon (Ant Design)', ARRAY['laptop'], '{"component": "LaptopOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:mobile', 'antd', 'Mobile', 'technology', 'Mobile icon (Ant Design)', ARRAY['mobile'], '{"component": "MobileOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:tablet', 'antd', 'Tablet', 'technology', 'Tablet icon (Ant Design)', ARRAY['tablet'], '{"component": "TabletOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:code', 'antd', 'Code', 'development', 'Code icon (Ant Design)', ARRAY['code'], '{"component": "CodeOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:bug', 'antd', 'Bug', 'development', 'Bug icon (Ant Design)', ARRAY['bug'], '{"component": "BugOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:api', 'antd', 'API', 'development', 'API icon (Ant Design)', ARRAY['api'], '{"component": "ApiOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:thunderbolt', 'antd', 'Thunderbolt', 'tools', 'Thunderbolt icon (Ant Design)', ARRAY['thunderbolt'], '{"component": "ThunderboltOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:rocket', 'antd', 'Rocket', 'tools', 'Rocket icon (Ant Design)', ARRAY['rocket'], '{"component": "RocketOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:fire', 'antd', 'Fire', 'tools', 'Fire icon (Ant Design)', ARRAY['fire'], '{"component": "FireOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:bulb', 'antd', 'Bulb', 'tools', 'Bulb icon (Ant Design)', ARRAY['bulb', 'idea'], '{"component": "BulbOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:compass', 'antd', 'Compass', 'location', 'Compass icon (Ant Design)', ARRAY['compass'], '{"component": "CompassOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:environment', 'antd', 'Environment', 'location', 'Environment/location icon (Ant Design)', ARRAY['environment', 'location'], '{"component": "EnvironmentOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:car', 'antd', 'Car', 'travel', 'Car icon (Ant Design)', ARRAY['car'], '{"component": "CarOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:medicine-box', 'antd', 'Medicine', 'health', 'Medicine box icon (Ant Design)', ARRAY['medicine'], '{"component": "MedicineBoxOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:heart', 'antd', 'Heart', 'health', 'Heart icon (Ant Design)', ARRAY['heart'], '{"component": "HeartOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:coffee', 'antd', 'Coffee', 'food', 'Coffee icon (Ant Design)', ARRAY['coffee'], '{"component": "CoffeeOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:shop', 'antd', 'Shop', 'shopping', 'Shop icon (Ant Design)', ARRAY['shop'], '{"component": "ShopOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:bank', 'antd', 'Bank', 'business', 'Bank icon (Ant Design)', ARRAY['bank'], '{"component": "BankOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:wallet', 'antd', 'Wallet', 'business', 'Wallet icon (Ant Design)', ARRAY['wallet'], '{"component": "WalletOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:file-pdf', 'antd', 'PDF', 'documents', 'PDF icon (Ant Design)', ARRAY['pdf'], '{"component": "FilePdfOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:file-excel', 'antd', 'Excel', 'documents', 'Excel icon (Ant Design)', ARRAY['excel'], '{"component": "FileExcelOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:file-word', 'antd', 'Word', 'documents', 'Word icon (Ant Design)', ARRAY['word'], '{"component": "FileWordOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:file-image', 'antd', 'Image File', 'documents', 'Image file icon (Ant Design)', ARRAY['image', 'file'], '{"component": "FileImageOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:file-zip', 'antd', 'Zip', 'documents', 'Zip file icon (Ant Design)', ARRAY['zip'], '{"component": "FileZipOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:cloud', 'antd', 'Cloud', 'technology', 'Cloud icon (Ant Design)', ARRAY['cloud'], '{"component": "CloudOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:cloud-upload', 'antd', 'Cloud Upload', 'technology', 'Cloud upload icon (Ant Design)', ARRAY['cloud', 'upload'], '{"component": "CloudUploadOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:cloud-download', 'antd', 'Cloud Download', 'technology', 'Cloud download icon (Ant Design)', ARRAY['cloud', 'download'], '{"component": "CloudDownloadOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:sync', 'antd', 'Sync', 'actions', 'Sync icon (Ant Design)', ARRAY['sync'], '{"component": "SyncOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:swap', 'antd', 'Swap', 'actions', 'Swap icon (Ant Design)', ARRAY['swap'], '{"component": "SwapOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:retweet', 'antd', 'Retweet', 'actions', 'Retweet icon (Ant Design)', ARRAY['retweet'], '{"component": "RetweetOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:enter', 'antd', 'Enter', 'navigation', 'Enter icon (Ant Design)', ARRAY['enter'], '{"component": "EnterOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:logout', 'antd', 'Logout', 'authentication', 'Logout icon (Ant Design)', ARRAY['logout'], '{"component": "LogoutOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:login', 'antd', 'Login', 'authentication', 'Login icon (Ant Design)', ARRAY['login'], '{"component": "LoginOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:translation', 'antd', 'Translation', 'communication', 'Translation icon (Ant Design)', ARRAY['translation'], '{"component": "TranslationOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:font-size', 'antd', 'Font Size', 'text', 'Font size icon (Ant Design)', ARRAY['font'], '{"component": "FontSizeOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:bold', 'antd', 'Bold', 'text', 'Bold icon (Ant Design)', ARRAY['bold'], '{"component": "BoldOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:italic', 'antd', 'Italic', 'text', 'Italic icon (Ant Design)', ARRAY['italic'], '{"component": "ItalicOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:underline', 'antd', 'Underline', 'text', 'Underline icon (Ant Design)', ARRAY['underline'], '{"component": "UnderlineOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:strikethrough', 'antd', 'Strikethrough', 'text', 'Strikethrough icon (Ant Design)', ARRAY['strikethrough'], '{"component": "StrikethroughOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:highlight', 'antd', 'Highlight', 'text', 'Highlight icon (Ant Design)', ARRAY['highlight'], '{"component": "HighlightOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:align-left', 'antd', 'Align Left', 'text', 'Align left icon (Ant Design)', ARRAY['align', 'left'], '{"component": "AlignLeftOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:align-center', 'antd', 'Align Center', 'text', 'Align center icon (Ant Design)', ARRAY['align', 'center'], '{"component": "AlignCenterOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:align-right', 'antd', 'Align Right', 'text', 'Align right icon (Ant Design)', ARRAY['align', 'right'], '{"component": "AlignRightOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:ordered-list', 'antd', 'Ordered List', 'text', 'Ordered list icon (Ant Design)', ARRAY['list', 'ordered'], '{"component": "OrderedListOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:unordered-list', 'antd', 'Unordered List', 'text', 'Unordered list icon (Ant Design)', ARRAY['list', 'unordered'], '{"component": "UnorderedListOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:code', 'antd', 'Code', 'development', 'Code icon (Ant Design)', ARRAY['code'], '{"component": "CodeOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:console-sql', 'antd', 'SQL', 'development', 'SQL console icon (Ant Design)', ARRAY['sql'], '{"component": "ConsoleSqlOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:branches', 'antd', 'Branches', 'development', 'Branches icon (Ant Design)', ARRAY['branches', 'git'], '{"component": "BranchesOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:gitlab', 'antd', 'GitLab', 'development', 'GitLab icon (Ant Design)', ARRAY['gitlab'], '{"component": "GitlabOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:html5', 'antd', 'HTML5', 'development', 'HTML5 icon (Ant Design)', ARRAY['html5'], '{"component": "Html5Outlined"}'::jsonb, false, v_system_user_id),
    ('antd:css3', 'antd', 'CSS3', 'development', 'CSS3 icon (Ant Design)', ARRAY['css3'], '{"component": "Css3Outlined"}'::jsonb, false, v_system_user_id),
    ('antd:js', 'antd', 'JavaScript', 'development', 'JavaScript icon (Ant Design)', ARRAY['javascript'], '{"component": "JavascriptOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:python', 'antd', 'Python', 'development', 'Python icon (Ant Design)', ARRAY['python'], '{"component": "PythonOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:java', 'antd', 'Java', 'development', 'Java icon (Ant Design)', ARRAY['java'], '{"component": "JavaOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:node', 'antd', 'Node', 'development', 'Node icon (Ant Design)', ARRAY['node'], '{"component": "NodeIndexOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:react', 'antd', 'React', 'development', 'React icon (Ant Design)', ARRAY['react'], '{"component": "ReactOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:vue', 'antd', 'Vue', 'development', 'Vue icon (Ant Design)', ARRAY['vue'], '{"component": "VueOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:angular', 'antd', 'Angular', 'development', 'Angular icon (Ant Design)', ARRAY['angular'], '{"component": "AngularOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:docker', 'antd', 'Docker', 'development', 'Docker icon (Ant Design)', ARRAY['docker'], '{"component": "DockerOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:linux', 'antd', 'Linux', 'development', 'Linux icon (Ant Design)', ARRAY['linux'], '{"component": "LinuxOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:windows', 'antd', 'Windows', 'development', 'Windows icon (Ant Design)', ARRAY['windows'], '{"component": "WindowsOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:apple', 'antd', 'Apple', 'development', 'Apple icon (Ant Design)', ARRAY['apple'], '{"component": "AppleOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:android', 'antd', 'Android', 'development', 'Android icon (Ant Design)', ARRAY['android'], '{"component": "AndroidOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:chrome', 'antd', 'Chrome', 'development', 'Chrome icon (Ant Design)', ARRAY['chrome'], '{"component": "ChromeOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:firefox', 'antd', 'Firefox', 'development', 'Firefox icon (Ant Design)', ARRAY['firefox'], '{"component": "FirefoxOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:safari', 'antd', 'Safari', 'development', 'Safari icon (Ant Design)', ARRAY['safari'], '{"component": "SafariOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:edge', 'antd', 'Edge', 'development', 'Edge icon (Ant Design)', ARRAY['edge'], '{"component": "EdgeOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:opera', 'antd', 'Opera', 'development', 'Opera icon (Ant Design)', ARRAY['opera'], '{"component": "OperaOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:ie', 'antd', 'Internet Explorer', 'development', 'IE icon (Ant Design)', ARRAY['ie'], '{"component": "IeOutlined"}'::jsonb, false, v_system_user_id),
    ('antd:brave', 'antd', 'Brave', 'development', 'Brave icon (Ant Design)', ARRAY['brave'], '{"component": "BraveOutlined"}'::jsonb, false, v_system_user_id),
        ON CONFLICT (icon_code) DO NOTHING;

    -- Additional Smilies/Emojis
    INSERT INTO public.icons (icon_code, icon_type, icon_name, category, description, tags, icon_data, is_popular, created_by) VALUES
    INSERT INTO public.icons (icon_code, icon_type, icon_name, category, description, tags, icon_data, is_popular, created_by) VALUES
    ('smily:laughing', 'smily', 'Laughing', 'emotions', 'Laughing emoji', ARRAY['laughing', 'lol', '😂'], '{"emoji": "😂", "unicode": "U+1F602"}'::jsonb, false, v_system_user_id),
    ('smily:joy', 'smily', 'Joy', 'emotions', 'Joy emoji', ARRAY['joy', 'tears', '😂'], '{"emoji": "😂", "unicode": "U+1F602"}'::jsonb, false, v_system_user_id),
    ('smily:grinning', 'smily', 'Grinning', 'emotions', 'Grinning emoji', ARRAY['grinning', '😀'], '{"emoji": "😀", "unicode": "U+1F600"}'::jsonb, false, v_system_user_id),
    ('smily:wink', 'smily', 'Wink', 'emotions', 'Wink emoji', ARRAY['wink', '😉'], '{"emoji": "😉", "unicode": "U+1F609"}'::jsonb, false, v_system_user_id),
    ('smily:kiss', 'smily', 'Kiss', 'emotions', 'Kiss emoji', ARRAY['kiss', '😘'], '{"emoji": "😘", "unicode": "U+1F618"}'::jsonb, false, v_system_user_id),
    ('smily:love', 'smily', 'Love Eyes', 'emotions', 'Love eyes emoji', ARRAY['love', 'eyes', '😍'], '{"emoji": "😍", "unicode": "U+1F60D"}'::jsonb, false, v_system_user_id),
    ('smily:cool', 'smily', 'Cool', 'emotions', 'Cool emoji', ARRAY['cool', '😎'], '{"emoji": "😎", "unicode": "U+1F60E"}'::jsonb, false, v_system_user_id),
    ('smily:thinking', 'smily', 'Thinking', 'emotions', 'Thinking emoji', ARRAY['thinking', '🤔'], '{"emoji": "🤔", "unicode": "U+1F914"}'::jsonb, false, v_system_user_id),
    ('smily:shushing', 'smily', 'Shushing', 'emotions', 'Shushing emoji', ARRAY['shushing', '🤫'], '{"emoji": "🤫", "unicode": "U+1F92B"}'::jsonb, false, v_system_user_id),
    ('smily:zipper-mouth', 'smily', 'Zipper Mouth', 'emotions', 'Zipper mouth emoji', ARRAY['zipper', '🤐'], '{"emoji": "🤐", "unicode": "U+1F910"}'::jsonb, false, v_system_user_id),
    ('smily:raised-eyebrow', 'smily', 'Raised Eyebrow', 'emotions', 'Raised eyebrow emoji', ARRAY['raised', 'eyebrow', '🤨'], '{"emoji": "🤨", "unicode": "U+1F928"}'::jsonb, false, v_system_user_id),
    ('smily:neutral', 'smily', 'Neutral', 'emotions', 'Neutral face emoji', ARRAY['neutral', '😐'], '{"emoji": "😐", "unicode": "U+1F610"}'::jsonb, false, v_system_user_id),
    ('smily:expressionless', 'smily', 'Expressionless', 'emotions', 'Expressionless emoji', ARRAY['expressionless', '😑'], '{"emoji": "😑", "unicode": "U+1F611"}'::jsonb, false, v_system_user_id),
    ('smily:rolling-eyes', 'smily', 'Rolling Eyes', 'emotions', 'Rolling eyes emoji', ARRAY['rolling', 'eyes', '🙄'], '{"emoji": "🙄", "unicode": "U+1F644"}'::jsonb, false, v_system_user_id),
    ('smily:sad', 'smily', 'Sad', 'emotions', 'Sad emoji', ARRAY['sad', '😢'], '{"emoji": "😢", "unicode": "U+1F622"}'::jsonb, false, v_system_user_id),
    ('smily:crying', 'smily', 'Crying', 'emotions', 'Crying emoji', ARRAY['crying', '😭'], '{"emoji": "😭", "unicode": "U+1F62D"}'::jsonb, false, v_system_user_id),
    ('smily:angry', 'smily', 'Angry', 'emotions', 'Angry emoji', ARRAY['angry', '😠'], '{"emoji": "😠", "unicode": "U+1F620"}'::jsonb, false, v_system_user_id),
    ('smily:rage', 'smily', 'Rage', 'emotions', 'Rage emoji', ARRAY['rage', '😡'], '{"emoji": "😡", "unicode": "U+1F621"}'::jsonb, false, v_system_user_id),
    ('smily:confused', 'smily', 'Confused', 'emotions', 'Confused emoji', ARRAY['confused', '😕'], '{"emoji": "😕", "unicode": "U+1F615"}'::jsonb, false, v_system_user_id),
    ('smily:worried', 'smily', 'Worried', 'emotions', 'Worried emoji', ARRAY['worried', '😟'], '{"emoji": "😟", "unicode": "U+1F61F"}'::jsonb, false, v_system_user_id),
    ('smily:slightly-frowning', 'smily', 'Slightly Frowning', 'emotions', 'Slightly frowning emoji', ARRAY['frowning', '🙁'], '{"emoji": "🙁", "unicode": "U+1F641"}'::jsonb, false, v_system_user_id),
    ('smily:open-mouth', 'smily', 'Open Mouth', 'emotions', 'Open mouth emoji', ARRAY['open', 'mouth', '😮'], '{"emoji": "😮", "unicode": "U+1F62E"}'::jsonb, false, v_system_user_id),
    ('smily:hushed', 'smily', 'Hushed', 'emotions', 'Hushed emoji', ARRAY['hushed', '😯'], '{"emoji": "😯", "unicode": "U+1F62F"}'::jsonb, false, v_system_user_id),
    ('smily:astonished', 'smily', 'Astonished', 'emotions', 'Astonished emoji', ARRAY['astonished', '😲'], '{"emoji": "😲", "unicode": "U+1F632"}'::jsonb, false, v_system_user_id),
    ('smily:flushed', 'smily', 'Flushed', 'emotions', 'Flushed emoji', ARRAY['flushed', '😳'], '{"emoji": "😳", "unicode": "U+1F633"}'::jsonb, false, v_system_user_id),
    ('smily:pleading', 'smily', 'Pleading', 'emotions', 'Pleading emoji', ARRAY['pleading', '🥺'], '{"emoji": "🥺", "unicode": "U+1F97A"}'::jsonb, false, v_system_user_id),
    ('smily:relieved', 'smily', 'Relieved', 'emotions', 'Relieved emoji', ARRAY['relieved', '😌'], '{"emoji": "😌", "unicode": "U+1F60C"}'::jsonb, false, v_system_user_id),
    ('smily:pensive', 'smily', 'Pensive', 'emotions', 'Pensive emoji', ARRAY['pensive', '😔'], '{"emoji": "😔", "unicode": "U+1F614"}'::jsonb, false, v_system_user_id),
    ('smily:sleepy', 'smily', 'Sleepy', 'emotions', 'Sleepy emoji', ARRAY['sleepy', '😪'], '{"emoji": "😪", "unicode": "U+1F62A"}'::jsonb, false, v_system_user_id),
    ('smily:drooling', 'smily', 'Drooling', 'emotions', 'Drooling emoji', ARRAY['drooling', '🤤'], '{"emoji": "🤤", "unicode": "U+1F924"}'::jsonb, false, v_system_user_id),
    ('smily:sleeping', 'smily', 'Sleeping', 'emotions', 'Sleeping emoji', ARRAY['sleeping', '😴'], '{"emoji": "😴", "unicode": "U+1F634"}'::jsonb, false, v_system_user_id),
    ('smily:mask', 'smily', 'Mask', 'emotions', 'Mask emoji', ARRAY['mask', '😷'], '{"emoji": "😷", "unicode": "U+1F637"}'::jsonb, false, v_system_user_id),
    ('smily:face-with-thermometer', 'smily', 'Sick', 'emotions', 'Sick emoji', ARRAY['sick', 'thermometer', '🤒'], '{"emoji": "🤒", "unicode": "U+1F912"}'::jsonb, false, v_system_user_id),
    ('smily:face-with-head-bandage', 'smily', 'Injured', 'emotions', 'Injured emoji', ARRAY['injured', 'bandage', '🤕'], '{"emoji": "🤕", "unicode": "U+1F915"}'::jsonb, false, v_system_user_id),
    ('smily:nauseated', 'smily', 'Nauseated', 'emotions', 'Nauseated emoji', ARRAY['nauseated', '🤢'], '{"emoji": "🤢", "unicode": "U+1F922"}'::jsonb, false, v_system_user_id),
    ('smily:vomiting', 'smily', 'Vomiting', 'emotions', 'Vomiting emoji', ARRAY['vomiting', '🤮'], '{"emoji": "🤮", "unicode": "U+1F92E"}'::jsonb, false, v_system_user_id),
    ('smily:sneezing', 'smily', 'Sneezing', 'emotions', 'Sneezing emoji', ARRAY['sneezing', '🤧'], '{"emoji": "🤧", "unicode": "U+1F927"}'::jsonb, false, v_system_user_id),
    ('smily:hot', 'smily', 'Hot', 'emotions', 'Hot face emoji', ARRAY['hot', '🥵'], '{"emoji": "🥵", "unicode": "U+1F975"}'::jsonb, false, v_system_user_id),
    ('smily:cold', 'smily', 'Cold', 'emotions', 'Cold face emoji', ARRAY['cold', '🥶'], '{"emoji": "🥶", "unicode": "U+1F976"}'::jsonb, false, v_system_user_id),
    ('smily:woozy', 'smily', 'Woozy', 'emotions', 'Woozy emoji', ARRAY['woozy', '🥴'], '{"emoji": "🥴", "unicode": "U+1F974"}'::jsonb, false, v_system_user_id),
    ('smily:dizzy', 'smily', 'Dizzy', 'emotions', 'Dizzy emoji', ARRAY['dizzy', '😵'], '{"emoji": "😵", "unicode": "U+1F635"}'::jsonb, false, v_system_user_id),
    ('smily:exploding-head', 'smily', 'Exploding Head', 'emotions', 'Exploding head emoji', ARRAY['exploding', 'head', '🤯'], '{"emoji": "🤯", "unicode": "U+1F92F"}'::jsonb, false, v_system_user_id),
    ('smily:cowboy', 'smily', 'Cowboy', 'emotions', 'Cowboy emoji', ARRAY['cowboy', '🤠'], '{"emoji": "🤠", "unicode": "U+1F920"}'::jsonb, false, v_system_user_id),
    ('smily:partying', 'smily', 'Partying', 'emotions', 'Partying emoji', ARRAY['partying', '🥳'], '{"emoji": "🥳", "unicode": "U+1F973"}'::jsonb, false, v_system_user_id),
    ('smily:disguised', 'smily', 'Disguised', 'emotions', 'Disguised emoji', ARRAY['disguised', '🥸'], '{"emoji": "🥸", "unicode": "U+1F978"}'::jsonb, false, v_system_user_id),
    ('smily:sunglasses', 'smily', 'Sunglasses', 'emotions', 'Sunglasses emoji', ARRAY['sunglasses', '😎'], '{"emoji": "😎", "unicode": "U+1F60E"}'::jsonb, false, v_system_user_id),
    ('smily:nerd', 'smily', 'Nerd', 'emotions', 'Nerd emoji', ARRAY['nerd', '🤓'], '{"emoji": "🤓", "unicode": "U+1F913"}'::jsonb, false, v_system_user_id),
    ('smily:monocle', 'smily', 'Monocle', 'emotions', 'Monocle emoji', ARRAY['monocle', '🧐'], '{"emoji": "🧐", "unicode": "U+1F9D0"}'::jsonb, false, v_system_user_id),
    ('smily:confused-face', 'smily', 'Confused Face', 'emotions', 'Confused face emoji', ARRAY['confused', '😕'], '{"emoji": "😕", "unicode": "U+1F615"}'::jsonb, false, v_system_user_id),
    ('smily:worried-face', 'smily', 'Worried Face', 'emotions', 'Worried face emoji', ARRAY['worried', '😟'], '{"emoji": "😟", "unicode": "U+1F61F"}'::jsonb, false, v_system_user_id),
    ('smily:slightly-frowning-face', 'smily', 'Slightly Frowning Face', 'emotions', 'Slightly frowning face emoji', ARRAY['frowning', '🙁'], '{"emoji": "🙁", "unicode": "U+1F641"}'::jsonb, false, v_system_user_id),
    ('smily:open-mouth-face', 'smily', 'Open Mouth Face', 'emotions', 'Open mouth face emoji', ARRAY['open', 'mouth', '😮'], '{"emoji": "😮", "unicode": "U+1F62E"}'::jsonb, false, v_system_user_id),
    ('smily:hushed-face', 'smily', 'Hushed Face', 'emotions', 'Hushed face emoji', ARRAY['hushed', '😯'], '{"emoji": "😯", "unicode": "U+1F62F"}'::jsonb, false, v_system_user_id),
    ('smily:astonished-face', 'smily', 'Astonished Face', 'emotions', 'Astonished face emoji', ARRAY['astonished', '😲'], '{"emoji": "😲", "unicode": "U+1F632"}'::jsonb, false, v_system_user_id),
    ('smily:flushed-face', 'smily', 'Flushed Face', 'emotions', 'Flushed face emoji', ARRAY['flushed', '😳'], '{"emoji": "😳", "unicode": "U+1F633"}'::jsonb, false, v_system_user_id),
    ('smily:pleading-face', 'smily', 'Pleading Face', 'emotions', 'Pleading face emoji', ARRAY['pleading', '🥺'], '{"emoji": "🥺", "unicode": "U+1F97A"}'::jsonb, false, v_system_user_id),
    ('smily:frowning-face', 'smily', 'Frowning Face', 'emotions', 'Frowning face emoji', ARRAY['frowning', '☹️'], '{"emoji": "☹️", "unicode": "U+2639"}'::jsonb, false, v_system_user_id),
    ('smily:anguished', 'smily', 'Anguished', 'emotions', 'Anguished emoji', ARRAY['anguished', '😧'], '{"emoji": "😧", "unicode": "U+1F627"}'::jsonb, false, v_system_user_id),
    ('smily:fearful', 'smily', 'Fearful', 'emotions', 'Fearful emoji', ARRAY['fearful', '😨'], '{"emoji": "😨", "unicode": "U+1F628"}'::jsonb, false, v_system_user_id),
    ('smily:cold-sweat', 'smily', 'Cold Sweat', 'emotions', 'Cold sweat emoji', ARRAY['cold', 'sweat', '😰'], '{"emoji": "😰", "unicode": "U+1F630"}'::jsonb, false, v_system_user_id),
    ('smily:disappointed-relieved', 'smily', 'Disappointed Relieved', 'emotions', 'Disappointed relieved emoji', ARRAY['disappointed', 'relieved', '😥'], '{"emoji": "😥", "unicode": "U+1F625"}'::jsonb, false, v_system_user_id),
    ('smily:cry', 'smily', 'Cry', 'emotions', 'Cry emoji', ARRAY['cry', '😢'], '{"emoji": "😢", "unicode": "U+1F622"}'::jsonb, false, v_system_user_id),
    ('smily:sob', 'smily', 'Sob', 'emotions', 'Sob emoji', ARRAY['sob', '😭'], '{"emoji": "😭", "unicode": "U+1F62D"}'::jsonb, false, v_system_user_id),
    ('smily:scream', 'smily', 'Scream', 'emotions', 'Scream emoji', ARRAY['scream', '😱'], '{"emoji": "😱", "unicode": "U+1F631"}'::jsonb, false, v_system_user_id),
    ('smily:flushed', 'smily', 'Flushed', 'emotions', 'Flushed emoji', ARRAY['flushed', '😳'], '{"emoji": "😳", "unicode": "U+1F633"}'::jsonb, false, v_system_user_id),
    ('smily:persevere', 'smily', 'Persevere', 'emotions', 'Persevere emoji', ARRAY['persevere', '😣'], '{"emoji": "😣", "unicode": "U+1F623"}'::jsonb, false, v_system_user_id),
    ('smily:disappointed', 'smily', 'Disappointed', 'emotions', 'Disappointed emoji', ARRAY['disappointed', '😞'], '{"emoji": "😞", "unicode": "U+1F61E"}'::jsonb, false, v_system_user_id),
    ('smily:sweat', 'smily', 'Sweat', 'emotions', 'Sweat emoji', ARRAY['sweat', '😓'], '{"emoji": "😓", "unicode": "U+1F613"}'::jsonb, false, v_system_user_id),
    ('smily:weary', 'smily', 'Weary', 'emotions', 'Weary emoji', ARRAY['weary', '😩'], '{"emoji": "😩", "unicode": "U+1F629"}'::jsonb, false, v_system_user_id),
    ('smily:tired', 'smily', 'Tired', 'emotions', 'Tired emoji', ARRAY['tired', '😫'], '{"emoji": "😫", "unicode": "U+1F62B"}'::jsonb, false, v_system_user_id),
    ('smily:yawning', 'smily', 'Yawning', 'emotions', 'Yawning emoji', ARRAY['yawning', '🥱'], '{"emoji": "🥱", "unicode": "U+1F971"}'::jsonb, false, v_system_user_id),
    ('smily:steam-nose', 'smily', 'Steam Nose', 'emotions', 'Steam nose emoji', ARRAY['steam', 'nose', '😤'], '{"emoji": "😤", "unicode": "U+1F624"}'::jsonb, false, v_system_user_id),
    ('smily:pouting', 'smily', 'Pouting', 'emotions', 'Pouting emoji', ARRAY['pouting', '😡'], '{"emoji": "😡", "unicode": "U+1F621"}'::jsonb, false, v_system_user_id),
    ('smily:angry-face', 'smily', 'Angry Face', 'emotions', 'Angry face emoji', ARRAY['angry', '😠'], '{"emoji": "😠", "unicode": "U+1F620"}'::jsonb, false, v_system_user_id),
    ('smily:cursing', 'smily', 'Cursing', 'emotions', 'Cursing emoji', ARRAY['cursing', '🤬'], '{"emoji": "🤬", "unicode": "U+1F92C"}'::jsonb, false, v_system_user_id),
    ('smily:symbols-over-mouth', 'smily', 'Symbols Over Mouth', 'emotions', 'Symbols over mouth emoji', ARRAY['symbols', 'mouth', '🤭'], '{"emoji": "🤭", "unicode": "U+1F92D"}'::jsonb, false, v_system_user_id),
    ('smily:hand-over-mouth', 'smily', 'Hand Over Mouth', 'emotions', 'Hand over mouth emoji', ARRAY['hand', 'mouth', '🤭'], '{"emoji": "🤭", "unicode": "U+1F92D"}'::jsonb, false, v_system_user_id),
    ('smily:shushing-face', 'smily', 'Shushing Face', 'emotions', 'Shushing face emoji', ARRAY['shushing', '🤫'], '{"emoji": "🤫", "unicode": "U+1F92B"}'::jsonb, false, v_system_user_id),
    ('smily:lying', 'smily', 'Lying', 'emotions', 'Lying emoji', ARRAY['lying', '🤥'], '{"emoji": "🤥", "unicode": "U+1F925"}'::jsonb, false, v_system_user_id),
    ('smily:no-mouth', 'smily', 'No Mouth', 'emotions', 'No mouth emoji', ARRAY['no', 'mouth', '😶'], '{"emoji": "😶", "unicode": "U+1F636"}'::jsonb, false, v_system_user_id),
    ('smily:smirk', 'smily', 'Smirk', 'emotions', 'Smirk emoji', ARRAY['smirk', '😏'], '{"emoji": "😏", "unicode": "U+1F60F"}'::jsonb, false, v_system_user_id),
    ('smily:unamused', 'smily', 'Unamused', 'emotions', 'Unamused emoji', ARRAY['unamused', '😒'], '{"emoji": "😒", "unicode": "U+1F612"}'::jsonb, false, v_system_user_id),
    ('smily:roll-eyes', 'smily', 'Roll Eyes', 'emotions', 'Roll eyes emoji', ARRAY['roll', 'eyes', '🙄'], '{"emoji": "🙄", "unicode": "U+1F644"}'::jsonb, false, v_system_user_id),
    ('smily:grimacing', 'smily', 'Grimacing', 'emotions', 'Grimacing emoji', ARRAY['grimacing', '😬'], '{"emoji": "😬", "unicode": "U+1F62C"}'::jsonb, false, v_system_user_id),
    ('smily:lying-face', 'smily', 'Lying Face', 'emotions', 'Lying face emoji', ARRAY['lying', '🤥'], '{"emoji": "🤥", "unicode": "U+1F925"}'::jsonb, false, v_system_user_id),
    ('smily:relieved-face', 'smily', 'Relieved Face', 'emotions', 'Relieved face emoji', ARRAY['relieved', '😌'], '{"emoji": "😌", "unicode": "U+1F60C"}'::jsonb, false, v_system_user_id),
    ('smily:pensive-face', 'smily', 'Pensive Face', 'emotions', 'Pensive face emoji', ARRAY['pensive', '😔'], '{"emoji": "😔", "unicode": "U+1F614"}'::jsonb, false, v_system_user_id),
    ('smily:sleepy-face', 'smily', 'Sleepy Face', 'emotions', 'Sleepy face emoji', ARRAY['sleepy', '😪'], '{"emoji": "😪", "unicode": "U+1F62A"}'::jsonb, false, v_system_user_id),
    ('smily:drooling-face', 'smily', 'Drooling Face', 'emotions', 'Drooling face emoji', ARRAY['drooling', '🤤'], '{"emoji": "🤤", "unicode": "U+1F924"}'::jsonb, false, v_system_user_id),
    ('smily:sleeping-face', 'smily', 'Sleeping Face', 'emotions', 'Sleeping face emoji', ARRAY['sleeping', '😴'], '{"emoji": "😴", "unicode": "U+1F634"}'::jsonb, false, v_system_user_id),
    ('smily:face-with-medical-mask', 'smily', 'Medical Mask', 'emotions', 'Medical mask emoji', ARRAY['mask', 'medical', '😷'], '{"emoji": "😷", "unicode": "U+1F637"}'::jsonb, false, v_system_user_id),
    ('smily:face-with-thermometer', 'smily', 'Thermometer', 'emotions', 'Face with thermometer emoji', ARRAY['thermometer', '🤒'], '{"emoji": "🤒", "unicode": "U+1F912"}'::jsonb, false, v_system_user_id),
    ('smily:face-with-head-bandage', 'smily', 'Head Bandage', 'emotions', 'Face with head bandage emoji', ARRAY['bandage', 'head', '🤕'], '{"emoji": "🤕", "unicode": "U+1F915"}'::jsonb, false, v_system_user_id),
    ('smily:nauseated-face', 'smily', 'Nauseated Face', 'emotions', 'Nauseated face emoji', ARRAY['nauseated', '🤢'], '{"emoji": "🤢", "unicode": "U+1F922"}'::jsonb, false, v_system_user_id),
    ('smily:face-vomiting', 'smily', 'Vomiting Face', 'emotions', 'Face vomiting emoji', ARRAY['vomiting', '🤮'], '{"emoji": "🤮", "unicode": "U+1F92E"}'::jsonb, false, v_system_user_id),
    ('smily:sneezing-face', 'smily', 'Sneezing Face', 'emotions', 'Sneezing face emoji', ARRAY['sneezing', '🤧'], '{"emoji": "🤧", "unicode": "U+1F927"}'::jsonb, false, v_system_user_id),
    ('smily:hot-face', 'smily', 'Hot Face', 'emotions', 'Hot face emoji', ARRAY['hot', '🥵'], '{"emoji": "🥵", "unicode": "U+1F975"}'::jsonb, false, v_system_user_id),
    ('smily:cold-face', 'smily', 'Cold Face', 'emotions', 'Cold face emoji', ARRAY['cold', '🥶'], '{"emoji": "🥶", "unicode": "U+1F976"}'::jsonb, false, v_system_user_id),
    ('smily:woozy-face', 'smily', 'Woozy Face', 'emotions', 'Woozy face emoji', ARRAY['woozy', '🥴'], '{"emoji": "🥴", "unicode": "U+1F974"}'::jsonb, false, v_system_user_id),
    ('smily:dizzy-face', 'smily', 'Dizzy Face', 'emotions', 'Dizzy face emoji', ARRAY['dizzy', '😵'], '{"emoji": "😵", "unicode": "U+1F635"}'::jsonb, false, v_system_user_id),
    ('smily:exploding-head-face', 'smily', 'Exploding Head Face', 'emotions', 'Exploding head face emoji', ARRAY['exploding', 'head', '🤯'], '{"emoji": "🤯", "unicode": "U+1F92F"}'::jsonb, false, v_system_user_id),
    ('smily:cowboy-hat-face', 'smily', 'Cowboy Hat', 'emotions', 'Cowboy hat face emoji', ARRAY['cowboy', 'hat', '🤠'], '{"emoji": "🤠", "unicode": "U+1F920"}'::jsonb, false, v_system_user_id),
    ('smily:partying-face', 'smily', 'Partying Face', 'emotions', 'Partying face emoji', ARRAY['partying', '🥳'], '{"emoji": "🥳", "unicode": "U+1F973"}'::jsonb, false, v_system_user_id),
    ('smily:disguised-face', 'smily', 'Disguised Face', 'emotions', 'Disguised face emoji', ARRAY['disguised', '🥸'], '{"emoji": "🥸", "unicode": "U+1F978"}'::jsonb, false, v_system_user_id),
    ('smily:sunglasses-face', 'smily', 'Sunglasses Face', 'emotions', 'Sunglasses face emoji', ARRAY['sunglasses', '😎'], '{"emoji": "😎", "unicode": "U+1F60E"}'::jsonb, false, v_system_user_id),
    ('smily:nerd-face', 'smily', 'Nerd Face', 'emotions', 'Nerd face emoji', ARRAY['nerd', '🤓'], '{"emoji": "🤓", "unicode": "U+1F913"}'::jsonb, false, v_system_user_id),
    ('smily:face-with-monocle', 'smily', 'Monocle', 'emotions', 'Face with monocle emoji', ARRAY['monocle', '🧐'], '{"emoji": "🧐", "unicode": "U+1F9D0"}'::jsonb, false, v_system_user_id),
    ('smily:confused-face-emoji', 'smily', 'Confused Face Emoji', 'emotions', 'Confused face emoji', ARRAY['confused', '😕'], '{"emoji": "😕", "unicode": "U+1F615"}'::jsonb, false, v_system_user_id),
    ('smily:worried-face-emoji', 'smily', 'Worried Face Emoji', 'emotions', 'Worried face emoji', ARRAY['worried', '😟'], '{"emoji": "😟", "unicode": "U+1F61F"}'::jsonb, false, v_system_user_id),
    ('smily:slightly-frowning-face-emoji', 'smily', 'Slightly Frowning Face Emoji', 'emotions', 'Slightly frowning face emoji', ARRAY['frowning', '🙁'], '{"emoji": "🙁", "unicode": "U+1F641"}'::jsonb, false, v_system_user_id),
    ('smily:open-mouth-face-emoji', 'smily', 'Open Mouth Face Emoji', 'emotions', 'Open mouth face emoji', ARRAY['open', 'mouth', '😮'], '{"emoji": "😮", "unicode": "U+1F62E"}'::jsonb, false, v_system_user_id),
    ('smily:hushed-face-emoji', 'smily', 'Hushed Face Emoji', 'emotions', 'Hushed face emoji', ARRAY['hushed', '😯'], '{"emoji": "😯", "unicode": "U+1F62F"}'::jsonb, false, v_system_user_id),
    ('smily:astonished-face-emoji', 'smily', 'Astonished Face Emoji', 'emotions', 'Astonished face emoji', ARRAY['astonished', '😲'], '{"emoji": "😲", "unicode": "U+1F632"}'::jsonb, false, v_system_user_id),
    ('smily:flushed-face-emoji', 'smily', 'Flushed Face Emoji', 'emotions', 'Flushed face emoji', ARRAY['flushed', '😳'], '{"emoji": "😳", "unicode": "U+1F633"}'::jsonb, false, v_system_user_id),
    ('smily:pleading-face-emoji', 'smily', 'Pleading Face Emoji', 'emotions', 'Pleading face emoji', ARRAY['pleading', '🥺'], '{"emoji": "🥺", "unicode": "U+1F97A"}'::jsonb, false, v_system_user_id),
    ('smily:frowning-face-emoji', 'smily', 'Frowning Face Emoji', 'emotions', 'Frowning face emoji', ARRAY['frowning', '☹️'], '{"emoji": "☹️", "unicode": "U+2639"}'::jsonb, false, v_system_user_id),
    ('smily:anguished-face', 'smily', 'Anguished Face', 'emotions', 'Anguished face emoji', ARRAY['anguished', '😧'], '{"emoji": "😧", "unicode": "U+1F627"}'::jsonb, false, v_system_user_id),
    ('smily:fearful-face', 'smily', 'Fearful Face', 'emotions', 'Fearful face emoji', ARRAY['fearful', '😨'], '{"emoji": "😨", "unicode": "U+1F628"}'::jsonb, false, v_system_user_id),
    ('smily:cold-sweat-face', 'smily', 'Cold Sweat Face', 'emotions', 'Cold sweat face emoji', ARRAY['cold', 'sweat', '😰'], '{"emoji": "😰", "unicode": "U+1F630"}'::jsonb, false, v_system_user_id),
    ('smily:disappointed-relieved-face', 'smily', 'Disappointed Relieved Face', 'emotions', 'Disappointed relieved face emoji', ARRAY['disappointed', 'relieved', '😥'], '{"emoji": "😥", "unicode": "U+1F625"}'::jsonb, false, v_system_user_id),
    ('smily:cry-face', 'smily', 'Cry Face', 'emotions', 'Cry face emoji', ARRAY['cry', '😢'], '{"emoji": "😢", "unicode": "U+1F622"}'::jsonb, false, v_system_user_id),
    ('smily:sob-face', 'smily', 'Sob Face', 'emotions', 'Sob face emoji', ARRAY['sob', '😭'], '{"emoji": "😭", "unicode": "U+1F62D"}'::jsonb, false, v_system_user_id),
    ('smily:scream-face', 'smily', 'Scream Face', 'emotions', 'Scream face emoji', ARRAY['scream', '😱'], '{"emoji": "😱", "unicode": "U+1F631"}'::jsonb, false, v_system_user_id),
    ('smily:flushed-face-emoji', 'smily', 'Flushed Face Emoji', 'emotions', 'Flushed face emoji', ARRAY['flushed', '😳'], '{"emoji": "😳", "unicode": "U+1F633"}'::jsonb, false, v_system_user_id),
    ('smily:persevere-face', 'smily', 'Persevere Face', 'emotions', 'Persevere face emoji', ARRAY['persevere', '😣'], '{"emoji": "😣", "unicode": "U+1F623"}'::jsonb, false, v_system_user_id),
    ('smily:disappointed-face', 'smily', 'Disappointed Face', 'emotions', 'Disappointed face emoji', ARRAY['disappointed', '😞'], '{"emoji": "😞", "unicode": "U+1F61E"}'::jsonb, false, v_system_user_id),
    ('smily:sweat-face', 'smily', 'Sweat Face', 'emotions', 'Sweat face emoji', ARRAY['sweat', '😓'], '{"emoji": "😓", "unicode": "U+1F613"}'::jsonb, false, v_system_user_id),
    ('smily:weary-face', 'smily', 'Weary Face', 'emotions', 'Weary face emoji', ARRAY['weary', '😩'], '{"emoji": "😩", "unicode": "U+1F629"}'::jsonb, false, v_system_user_id),
    ('smily:tired-face', 'smily', 'Tired Face', 'emotions', 'Tired face emoji', ARRAY['tired', '😫'], '{"emoji": "😫", "unicode": "U+1F62B"}'::jsonb, false, v_system_user_id),
    ('smily:yawning-face', 'smily', 'Yawning Face', 'emotions', 'Yawning face emoji', ARRAY['yawning', '🥱'], '{"emoji": "🥱", "unicode": "U+1F971"}'::jsonb, false, v_system_user_id),
    ('smily:steam-nose-face', 'smily', 'Steam Nose Face', 'emotions', 'Steam nose face emoji', ARRAY['steam', 'nose', '😤'], '{"emoji": "😤", "unicode": "U+1F624"}'::jsonb, false, v_system_user_id),
    ('smily:pouting-face', 'smily', 'Pouting Face', 'emotions', 'Pouting face emoji', ARRAY['pouting', '😡'], '{"emoji": "😡", "unicode": "U+1F621"}'::jsonb, false, v_system_user_id),
    ('smily:angry-face-emoji', 'smily', 'Angry Face Emoji', 'emotions', 'Angry face emoji', ARRAY['angry', '😠'], '{"emoji": "😠", "unicode": "U+1F620"}'::jsonb, false, v_system_user_id),
    ('smily:cursing-face', 'smily', 'Cursing Face', 'emotions', 'Cursing face emoji', ARRAY['cursing', '🤬'], '{"emoji": "🤬", "unicode": "U+1F92C"}'::jsonb, false, v_system_user_id),
    ('smily:symbols-over-mouth-face', 'smily', 'Symbols Over Mouth Face', 'emotions', 'Symbols over mouth face emoji', ARRAY['symbols', 'mouth', '🤭'], '{"emoji": "🤭", "unicode": "U+1F92D"}'::jsonb, false, v_system_user_id),
    ('smily:hand-over-mouth-face', 'smily', 'Hand Over Mouth Face', 'emotions', 'Hand over mouth face emoji', ARRAY['hand', 'mouth', '🤭'], '{"emoji": "🤭", "unicode": "U+1F92D"}'::jsonb, false, v_system_user_id),
    ('smily:shushing-face-emoji', 'smily', 'Shushing Face Emoji', 'emotions', 'Shushing face emoji', ARRAY['shushing', '🤫'], '{"emoji": "🤫", "unicode": "U+1F92B"}'::jsonb, false, v_system_user_id),
    ('smily:lying-face-emoji', 'smily', 'Lying Face Emoji', 'emotions', 'Lying face emoji', ARRAY['lying', '🤥'], '{"emoji": "🤥", "unicode": "U+1F925"}'::jsonb, false, v_system_user_id),
    ('smily:no-mouth-face', 'smily', 'No Mouth Face', 'emotions', 'No mouth face emoji', ARRAY['no', 'mouth', '😶'], '{"emoji": "😶", "unicode": "U+1F636"}'::jsonb, false, v_system_user_id),
    ('smily:smirk-face', 'smily', 'Smirk Face', 'emotions', 'Smirk face emoji', ARRAY['smirk', '😏'], '{"emoji": "😏", "unicode": "U+1F60F"}'::jsonb, false, v_system_user_id),
    ('smily:unamused-face', 'smily', 'Unamused Face', 'emotions', 'Unamused face emoji', ARRAY['unamused', '😒'], '{"emoji": "😒", "unicode": "U+1F612"}'::jsonb, false, v_system_user_id),
    ('smily:roll-eyes-face', 'smily', 'Roll Eyes Face', 'emotions', 'Roll eyes face emoji', ARRAY['roll', 'eyes', '🙄'], '{"emoji": "🙄", "unicode": "U+1F644"}'::jsonb, false, v_system_user_id),
    ('smily:grimacing-face', 'smily', 'Grimacing Face', 'emotions', 'Grimacing face emoji', ARRAY['grimacing', '😬'], '{"emoji": "😬", "unicode": "U+1F62C"}'::jsonb, false, v_system_user_id),
    ('smily:lying-face-emoji2', 'smily', 'Lying Face Emoji 2', 'emotions', 'Lying face emoji', ARRAY['lying', '🤥'], '{"emoji": "🤥", "unicode": "U+1F925"}'::jsonb, false, v_system_user_id),
    ('smily:relieved-face-emoji', 'smily', 'Relieved Face Emoji', 'emotions', 'Relieved face emoji', ARRAY['relieved', '😌'], '{"emoji": "😌", "unicode": "U+1F60C"}'::jsonb, false, v_system_user_id),
    ('smily:pensive-face-emoji', 'smily', 'Pensive Face Emoji', 'emotions', 'Pensive face emoji', ARRAY['pensive', '😔'], '{"emoji": "😔", "unicode": "U+1F614"}'::jsonb, false, v_system_user_id),
    ('smily:sleepy-face-emoji', 'smily', 'Sleepy Face Emoji', 'emotions', 'Sleepy face emoji', ARRAY['sleepy', '😪'], '{"emoji": "😪", "unicode": "U+1F62A"}'::jsonb, false, v_system_user_id),
    ('smily:drooling-face-emoji', 'smily', 'Drooling Face Emoji', 'emotions', 'Drooling face emoji', ARRAY['drooling', '🤤'], '{"emoji": "🤤", "unicode": "U+1F924"}'::jsonb, false, v_system_user_id),
    ('smily:sleeping-face-emoji', 'smily', 'Sleeping Face Emoji', 'emotions', 'Sleeping face emoji', ARRAY['sleeping', '😴'], '{"emoji": "😴", "unicode": "U+1F634"}'::jsonb, false, v_system_user_id),
    ('smily:face-with-medical-mask-emoji', 'smily', 'Medical Mask Emoji', 'emotions', 'Medical mask emoji', ARRAY['mask', 'medical', '😷'], '{"emoji": "😷", "unicode": "U+1F637"}'::jsonb, false, v_system_user_id),
    ('smily:face-with-thermometer-emoji', 'smily', 'Thermometer Emoji', 'emotions', 'Face with thermometer emoji', ARRAY['thermometer', '🤒'], '{"emoji": "🤒", "unicode": "U+1F912"}'::jsonb, false, v_system_user_id),
    ('smily:face-with-head-bandage-emoji', 'smily', 'Head Bandage Emoji', 'emotions', 'Face with head bandage emoji', ARRAY['bandage', 'head', '🤕'], '{"emoji": "🤕", "unicode": "U+1F915"}'::jsonb, false, v_system_user_id),
    ('smily:nauseated-face-emoji', 'smily', 'Nauseated Face Emoji', 'emotions', 'Nauseated face emoji', ARRAY['nauseated', '🤢'], '{"emoji": "🤢", "unicode": "U+1F922"}'::jsonb, false, v_system_user_id),
    ('smily:face-vomiting-emoji', 'smily', 'Vomiting Face Emoji', 'emotions', 'Face vomiting emoji', ARRAY['vomiting', '🤮'], '{"emoji": "🤮", "unicode": "U+1F92E"}'::jsonb, false, v_system_user_id),
    ('smily:sneezing-face-emoji', 'smily', 'Sneezing Face Emoji', 'emotions', 'Sneezing face emoji', ARRAY['sneezing', '🤧'], '{"emoji": "🤧", "unicode": "U+1F927"}'::jsonb, false, v_system_user_id),
    ('smily:hot-face-emoji', 'smily', 'Hot Face Emoji', 'emotions', 'Hot face emoji', ARRAY['hot', '🥵'], '{"emoji": "🥵", "unicode": "U+1F975"}'::jsonb, false, v_system_user_id),
    ('smily:cold-face-emoji', 'smily', 'Cold Face Emoji', 'emotions', 'Cold face emoji', ARRAY['cold', '🥶'], '{"emoji": "🥶", "unicode": "U+1F976"}'::jsonb, false, v_system_user_id),
    ('smily:woozy-face-emoji', 'smily', 'Woozy Face Emoji', 'emotions', 'Woozy face emoji', ARRAY['woozy', '🥴'], '{"emoji": "🥴", "unicode": "U+1F974"}'::jsonb, false, v_system_user_id),
    ('smily:dizzy-face-emoji', 'smily', 'Dizzy Face Emoji', 'emotions', 'Dizzy face emoji', ARRAY['dizzy', '😵'], '{"emoji": "😵", "unicode": "U+1F635"}'::jsonb, false, v_system_user_id),
    ('smily:exploding-head-face-emoji', 'smily', 'Exploding Head Face Emoji', 'emotions', 'Exploding head face emoji', ARRAY['exploding', 'head', '🤯'], '{"emoji": "🤯", "unicode": "U+1F92F"}'::jsonb, false, v_system_user_id),
    ('smily:cowboy-hat-face-emoji', 'smily', 'Cowboy Hat Emoji', 'emotions', 'Cowboy hat face emoji', ARRAY['cowboy', 'hat', '🤠'], '{"emoji": "🤠", "unicode": "U+1F920"}'::jsonb, false, v_system_user_id),
    ('smily:partying-face-emoji', 'smily', 'Partying Face Emoji', 'emotions', 'Partying face emoji', ARRAY['partying', '🥳'], '{"emoji": "🥳", "unicode": "U+1F973"}'::jsonb, false, v_system_user_id),
    ('smily:disguised-face-emoji', 'smily', 'Disguised Face Emoji', 'emotions', 'Disguised face emoji', ARRAY['disguised', '🥸'], '{"emoji": "🥸", "unicode": "U+1F978"}'::jsonb, false, v_system_user_id),
    ('smily:sunglasses-face-emoji', 'smily', 'Sunglasses Face Emoji', 'emotions', 'Sunglasses face emoji', ARRAY['sunglasses', '😎'], '{"emoji": "😎", "unicode": "U+1F60E"}'::jsonb, false, v_system_user_id),
    ('smily:nerd-face-emoji', 'smily', 'Nerd Face Emoji', 'emotions', 'Nerd face emoji', ARRAY['nerd', '🤓'], '{"emoji": "🤓", "unicode": "U+1F913"}'::jsonb, false, v_system_user_id),
    ('smily:face-with-monocle-emoji', 'smily', 'Monocle Emoji', 'emotions', 'Face with monocle emoji', ARRAY['monocle', '🧐'], '{"emoji": "🧐", "unicode": "U+1F9D0"}'::jsonb, false, v_system_user_id),
        ON CONFLICT (icon_code) DO NOTHING;

END $$;
