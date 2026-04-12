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
('Auto UUID', 'auto_uuid', 'advanced', 'UUID', '{}', (SELECT component_type_id FROM public.ui_component_types WHERE type_code = 'label')),
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
UPDATE public.field_types SET input_type_image = 'field_types/field_type_auto_number.svg' WHERE type_code = 'auto_uuid';
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
UPDATE public.field_types SET order_no = 5 WHERE type_code = 'auto_uuid';
UPDATE public.field_types SET order_no = 6 WHERE type_code = 'currency';
UPDATE public.field_types SET order_no = 7 WHERE type_code = 'percentage';
UPDATE public.field_types SET order_no = 8 WHERE type_code = 'rating';
UPDATE public.field_types SET order_no = 9 WHERE type_code = 'date';
UPDATE public.field_types SET order_no = 10 WHERE type_code = 'datetime';
UPDATE public.field_types SET order_no = 11 WHERE type_code = 'time';
UPDATE public.field_types SET order_no = 12 WHERE type_code = 'duration';
UPDATE public.field_types SET order_no = 13 WHERE type_code = 'boolean';
UPDATE public.field_types SET order_no = 14 WHERE type_code = 'single_choice';
UPDATE public.field_types SET order_no = 15 WHERE type_code = 'multi_choice';
UPDATE public.field_types SET order_no = 16 WHERE type_code = 'auto_code';
UPDATE public.field_types SET order_no = 17 WHERE type_code = 'email';
UPDATE public.field_types SET order_no = 18 WHERE type_code = 'phone';
UPDATE public.field_types SET order_no = 19 WHERE type_code = 'url';
UPDATE public.field_types SET order_no = 20 WHERE type_code = 'password';
UPDATE public.field_types SET order_no = 21 WHERE type_code = 'color';
UPDATE public.field_types SET order_no = 22 WHERE type_code = 'image';
UPDATE public.field_types SET order_no = 23 WHERE type_code = 'file';
UPDATE public.field_types SET order_no = 24 WHERE type_code = 'video';
UPDATE public.field_types SET order_no = 25 WHERE type_code = 'audio';
UPDATE public.field_types SET order_no = 26 WHERE type_code = 'address';
UPDATE public.field_types SET order_no = 27 WHERE type_code = 'location';
UPDATE public.field_types SET order_no = 28 WHERE type_code = 'relation';
UPDATE public.field_types SET order_no = 29 WHERE type_code = 'rich_text';
UPDATE public.field_types SET order_no = 30 WHERE type_code = 'json';
UPDATE public.field_types SET order_no = 31 WHERE type_code = 'icon';

-- ==========================================
-- 2.0. Priorities and Job Areas (Life OS / Tasks)
-- ==========================================
INSERT INTO public.priorities (code, label, description, sort_order, is_active) VALUES
('P1', 'Critical', 'Critical priority', 1, TRUE),
('P2', 'High', 'High priority', 2, TRUE),
('P3', 'Normal', 'Normal priority', 3, TRUE),
('P4', 'Low', 'Low priority', 4, TRUE)
ON CONFLICT (code) DO NOTHING;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.job_areas WHERE name = 'Work' LIMIT 1) THEN
        INSERT INTO public.job_areas (name, description, area_type, is_active) VALUES ('Work', 'Professional and work-related', 'work', TRUE);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.job_areas WHERE name = 'Personal' LIMIT 1) THEN
        INSERT INTO public.job_areas (name, description, area_type, is_active) VALUES ('Personal', 'Personal life and family', 'personal', TRUE);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.job_areas WHERE name = 'Learning' LIMIT 1) THEN
        INSERT INTO public.job_areas (name, description, area_type, is_active) VALUES ('Learning', 'Learning and skill development', 'learning', TRUE);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.job_areas WHERE name = 'Family' LIMIT 1) THEN
        INSERT INTO public.job_areas (name, description, area_type, is_active) VALUES ('Family', 'Family and home', 'life', TRUE);
    END IF;
END $$;

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
-- 2.2 Global icons (bundled pack; platform paths under public/global_icons/{web,android,ios,macos,windows,linux}/)
-- ==========================================
-- Generated by scripts/generate_global_icon_assets.py (do not hand-edit)
DO $$
DECLARE
    v_system_user_id INTEGER;
BEGIN
    SELECT user_id INTO v_system_user_id FROM public.users WHERE is_super_admin = TRUE LIMIT 1;
    INSERT INTO public.assets (file_name, original_name, mime_type, storage_path, is_public, company_id, uploaded_by)
    SELECT * FROM (VALUES
        ('home.svg', 'home.svg', 'image/svg+xml', 'global_icons/web/home.svg', TRUE, NULL, v_system_user_id),
        ('home.xml', 'home.xml', 'application/xml', 'global_icons/android/home.xml', TRUE, NULL, v_system_user_id),
        ('home.svg', 'home.svg', 'image/svg+xml', 'global_icons/ios/home.svg', TRUE, NULL, v_system_user_id),
        ('home.svg', 'home.svg', 'image/svg+xml', 'global_icons/macos/home.svg', TRUE, NULL, v_system_user_id),
        ('home.png', 'home.png', 'image/png', 'global_icons/windows/home.png', TRUE, NULL, v_system_user_id),
        ('home.svg', 'home.svg', 'image/svg+xml', 'global_icons/linux/home.svg', TRUE, NULL, v_system_user_id),
        ('user.svg', 'user.svg', 'image/svg+xml', 'global_icons/web/user.svg', TRUE, NULL, v_system_user_id),
        ('user.xml', 'user.xml', 'application/xml', 'global_icons/android/user.xml', TRUE, NULL, v_system_user_id),
        ('user.svg', 'user.svg', 'image/svg+xml', 'global_icons/ios/user.svg', TRUE, NULL, v_system_user_id),
        ('user.svg', 'user.svg', 'image/svg+xml', 'global_icons/macos/user.svg', TRUE, NULL, v_system_user_id),
        ('user.png', 'user.png', 'image/png', 'global_icons/windows/user.png', TRUE, NULL, v_system_user_id),
        ('user.svg', 'user.svg', 'image/svg+xml', 'global_icons/linux/user.svg', TRUE, NULL, v_system_user_id),
        ('users.svg', 'users.svg', 'image/svg+xml', 'global_icons/web/users.svg', TRUE, NULL, v_system_user_id),
        ('users.xml', 'users.xml', 'application/xml', 'global_icons/android/users.xml', TRUE, NULL, v_system_user_id),
        ('users.svg', 'users.svg', 'image/svg+xml', 'global_icons/ios/users.svg', TRUE, NULL, v_system_user_id),
        ('users.svg', 'users.svg', 'image/svg+xml', 'global_icons/macos/users.svg', TRUE, NULL, v_system_user_id),
        ('users.png', 'users.png', 'image/png', 'global_icons/windows/users.png', TRUE, NULL, v_system_user_id),
        ('users.svg', 'users.svg', 'image/svg+xml', 'global_icons/linux/users.svg', TRUE, NULL, v_system_user_id),
        ('settings.svg', 'settings.svg', 'image/svg+xml', 'global_icons/web/settings.svg', TRUE, NULL, v_system_user_id),
        ('settings.xml', 'settings.xml', 'application/xml', 'global_icons/android/settings.xml', TRUE, NULL, v_system_user_id),
        ('settings.svg', 'settings.svg', 'image/svg+xml', 'global_icons/ios/settings.svg', TRUE, NULL, v_system_user_id),
        ('settings.svg', 'settings.svg', 'image/svg+xml', 'global_icons/macos/settings.svg', TRUE, NULL, v_system_user_id),
        ('settings.png', 'settings.png', 'image/png', 'global_icons/windows/settings.png', TRUE, NULL, v_system_user_id),
        ('settings.svg', 'settings.svg', 'image/svg+xml', 'global_icons/linux/settings.svg', TRUE, NULL, v_system_user_id),
        ('search.svg', 'search.svg', 'image/svg+xml', 'global_icons/web/search.svg', TRUE, NULL, v_system_user_id),
        ('search.xml', 'search.xml', 'application/xml', 'global_icons/android/search.xml', TRUE, NULL, v_system_user_id),
        ('search.svg', 'search.svg', 'image/svg+xml', 'global_icons/ios/search.svg', TRUE, NULL, v_system_user_id),
        ('search.svg', 'search.svg', 'image/svg+xml', 'global_icons/macos/search.svg', TRUE, NULL, v_system_user_id),
        ('search.png', 'search.png', 'image/png', 'global_icons/windows/search.png', TRUE, NULL, v_system_user_id),
        ('search.svg', 'search.svg', 'image/svg+xml', 'global_icons/linux/search.svg', TRUE, NULL, v_system_user_id),
        ('menu.svg', 'menu.svg', 'image/svg+xml', 'global_icons/web/menu.svg', TRUE, NULL, v_system_user_id),
        ('menu.xml', 'menu.xml', 'application/xml', 'global_icons/android/menu.xml', TRUE, NULL, v_system_user_id),
        ('menu.svg', 'menu.svg', 'image/svg+xml', 'global_icons/ios/menu.svg', TRUE, NULL, v_system_user_id),
        ('menu.svg', 'menu.svg', 'image/svg+xml', 'global_icons/macos/menu.svg', TRUE, NULL, v_system_user_id),
        ('menu.png', 'menu.png', 'image/png', 'global_icons/windows/menu.png', TRUE, NULL, v_system_user_id),
        ('menu.svg', 'menu.svg', 'image/svg+xml', 'global_icons/linux/menu.svg', TRUE, NULL, v_system_user_id),
        ('close.svg', 'close.svg', 'image/svg+xml', 'global_icons/web/close.svg', TRUE, NULL, v_system_user_id),
        ('close.xml', 'close.xml', 'application/xml', 'global_icons/android/close.xml', TRUE, NULL, v_system_user_id),
        ('close.svg', 'close.svg', 'image/svg+xml', 'global_icons/ios/close.svg', TRUE, NULL, v_system_user_id),
        ('close.svg', 'close.svg', 'image/svg+xml', 'global_icons/macos/close.svg', TRUE, NULL, v_system_user_id),
        ('close.png', 'close.png', 'image/png', 'global_icons/windows/close.png', TRUE, NULL, v_system_user_id),
        ('close.svg', 'close.svg', 'image/svg+xml', 'global_icons/linux/close.svg', TRUE, NULL, v_system_user_id),
        ('add.svg', 'add.svg', 'image/svg+xml', 'global_icons/web/add.svg', TRUE, NULL, v_system_user_id),
        ('add.xml', 'add.xml', 'application/xml', 'global_icons/android/add.xml', TRUE, NULL, v_system_user_id),
        ('add.svg', 'add.svg', 'image/svg+xml', 'global_icons/ios/add.svg', TRUE, NULL, v_system_user_id),
        ('add.svg', 'add.svg', 'image/svg+xml', 'global_icons/macos/add.svg', TRUE, NULL, v_system_user_id),
        ('add.png', 'add.png', 'image/png', 'global_icons/windows/add.png', TRUE, NULL, v_system_user_id),
        ('add.svg', 'add.svg', 'image/svg+xml', 'global_icons/linux/add.svg', TRUE, NULL, v_system_user_id),
        ('edit.svg', 'edit.svg', 'image/svg+xml', 'global_icons/web/edit.svg', TRUE, NULL, v_system_user_id),
        ('edit.xml', 'edit.xml', 'application/xml', 'global_icons/android/edit.xml', TRUE, NULL, v_system_user_id),
        ('edit.svg', 'edit.svg', 'image/svg+xml', 'global_icons/ios/edit.svg', TRUE, NULL, v_system_user_id),
        ('edit.svg', 'edit.svg', 'image/svg+xml', 'global_icons/macos/edit.svg', TRUE, NULL, v_system_user_id),
        ('edit.png', 'edit.png', 'image/png', 'global_icons/windows/edit.png', TRUE, NULL, v_system_user_id),
        ('edit.svg', 'edit.svg', 'image/svg+xml', 'global_icons/linux/edit.svg', TRUE, NULL, v_system_user_id),
        ('delete.svg', 'delete.svg', 'image/svg+xml', 'global_icons/web/delete.svg', TRUE, NULL, v_system_user_id),
        ('delete.xml', 'delete.xml', 'application/xml', 'global_icons/android/delete.xml', TRUE, NULL, v_system_user_id),
        ('delete.svg', 'delete.svg', 'image/svg+xml', 'global_icons/ios/delete.svg', TRUE, NULL, v_system_user_id),
        ('delete.svg', 'delete.svg', 'image/svg+xml', 'global_icons/macos/delete.svg', TRUE, NULL, v_system_user_id),
        ('delete.png', 'delete.png', 'image/png', 'global_icons/windows/delete.png', TRUE, NULL, v_system_user_id),
        ('delete.svg', 'delete.svg', 'image/svg+xml', 'global_icons/linux/delete.svg', TRUE, NULL, v_system_user_id),
        ('save.svg', 'save.svg', 'image/svg+xml', 'global_icons/web/save.svg', TRUE, NULL, v_system_user_id),
        ('save.xml', 'save.xml', 'application/xml', 'global_icons/android/save.xml', TRUE, NULL, v_system_user_id),
        ('save.svg', 'save.svg', 'image/svg+xml', 'global_icons/ios/save.svg', TRUE, NULL, v_system_user_id),
        ('save.svg', 'save.svg', 'image/svg+xml', 'global_icons/macos/save.svg', TRUE, NULL, v_system_user_id),
        ('save.png', 'save.png', 'image/png', 'global_icons/windows/save.png', TRUE, NULL, v_system_user_id),
        ('save.svg', 'save.svg', 'image/svg+xml', 'global_icons/linux/save.svg', TRUE, NULL, v_system_user_id),
        ('cancel.svg', 'cancel.svg', 'image/svg+xml', 'global_icons/web/cancel.svg', TRUE, NULL, v_system_user_id),
        ('cancel.xml', 'cancel.xml', 'application/xml', 'global_icons/android/cancel.xml', TRUE, NULL, v_system_user_id),
        ('cancel.svg', 'cancel.svg', 'image/svg+xml', 'global_icons/ios/cancel.svg', TRUE, NULL, v_system_user_id),
        ('cancel.svg', 'cancel.svg', 'image/svg+xml', 'global_icons/macos/cancel.svg', TRUE, NULL, v_system_user_id),
        ('cancel.png', 'cancel.png', 'image/png', 'global_icons/windows/cancel.png', TRUE, NULL, v_system_user_id),
        ('cancel.svg', 'cancel.svg', 'image/svg+xml', 'global_icons/linux/cancel.svg', TRUE, NULL, v_system_user_id),
        ('check.svg', 'check.svg', 'image/svg+xml', 'global_icons/web/check.svg', TRUE, NULL, v_system_user_id),
        ('check.xml', 'check.xml', 'application/xml', 'global_icons/android/check.xml', TRUE, NULL, v_system_user_id),
        ('check.svg', 'check.svg', 'image/svg+xml', 'global_icons/ios/check.svg', TRUE, NULL, v_system_user_id),
        ('check.svg', 'check.svg', 'image/svg+xml', 'global_icons/macos/check.svg', TRUE, NULL, v_system_user_id),
        ('check.png', 'check.png', 'image/png', 'global_icons/windows/check.png', TRUE, NULL, v_system_user_id),
        ('check.svg', 'check.svg', 'image/svg+xml', 'global_icons/linux/check.svg', TRUE, NULL, v_system_user_id),
        ('back.svg', 'back.svg', 'image/svg+xml', 'global_icons/web/back.svg', TRUE, NULL, v_system_user_id),
        ('back.xml', 'back.xml', 'application/xml', 'global_icons/android/back.xml', TRUE, NULL, v_system_user_id),
        ('back.svg', 'back.svg', 'image/svg+xml', 'global_icons/ios/back.svg', TRUE, NULL, v_system_user_id),
        ('back.svg', 'back.svg', 'image/svg+xml', 'global_icons/macos/back.svg', TRUE, NULL, v_system_user_id),
        ('back.png', 'back.png', 'image/png', 'global_icons/windows/back.png', TRUE, NULL, v_system_user_id),
        ('back.svg', 'back.svg', 'image/svg+xml', 'global_icons/linux/back.svg', TRUE, NULL, v_system_user_id),
        ('forward.svg', 'forward.svg', 'image/svg+xml', 'global_icons/web/forward.svg', TRUE, NULL, v_system_user_id),
        ('forward.xml', 'forward.xml', 'application/xml', 'global_icons/android/forward.xml', TRUE, NULL, v_system_user_id),
        ('forward.svg', 'forward.svg', 'image/svg+xml', 'global_icons/ios/forward.svg', TRUE, NULL, v_system_user_id),
        ('forward.svg', 'forward.svg', 'image/svg+xml', 'global_icons/macos/forward.svg', TRUE, NULL, v_system_user_id),
        ('forward.png', 'forward.png', 'image/png', 'global_icons/windows/forward.png', TRUE, NULL, v_system_user_id),
        ('forward.svg', 'forward.svg', 'image/svg+xml', 'global_icons/linux/forward.svg', TRUE, NULL, v_system_user_id),
        ('refresh.svg', 'refresh.svg', 'image/svg+xml', 'global_icons/web/refresh.svg', TRUE, NULL, v_system_user_id),
        ('refresh.xml', 'refresh.xml', 'application/xml', 'global_icons/android/refresh.xml', TRUE, NULL, v_system_user_id),
        ('refresh.svg', 'refresh.svg', 'image/svg+xml', 'global_icons/ios/refresh.svg', TRUE, NULL, v_system_user_id),
        ('refresh.svg', 'refresh.svg', 'image/svg+xml', 'global_icons/macos/refresh.svg', TRUE, NULL, v_system_user_id),
        ('refresh.png', 'refresh.png', 'image/png', 'global_icons/windows/refresh.png', TRUE, NULL, v_system_user_id),
        ('refresh.svg', 'refresh.svg', 'image/svg+xml', 'global_icons/linux/refresh.svg', TRUE, NULL, v_system_user_id),
        ('download.svg', 'download.svg', 'image/svg+xml', 'global_icons/web/download.svg', TRUE, NULL, v_system_user_id),
        ('download.xml', 'download.xml', 'application/xml', 'global_icons/android/download.xml', TRUE, NULL, v_system_user_id),
        ('download.svg', 'download.svg', 'image/svg+xml', 'global_icons/ios/download.svg', TRUE, NULL, v_system_user_id),
        ('download.svg', 'download.svg', 'image/svg+xml', 'global_icons/macos/download.svg', TRUE, NULL, v_system_user_id),
        ('download.png', 'download.png', 'image/png', 'global_icons/windows/download.png', TRUE, NULL, v_system_user_id),
        ('download.svg', 'download.svg', 'image/svg+xml', 'global_icons/linux/download.svg', TRUE, NULL, v_system_user_id),
        ('upload.svg', 'upload.svg', 'image/svg+xml', 'global_icons/web/upload.svg', TRUE, NULL, v_system_user_id),
        ('upload.xml', 'upload.xml', 'application/xml', 'global_icons/android/upload.xml', TRUE, NULL, v_system_user_id),
        ('upload.svg', 'upload.svg', 'image/svg+xml', 'global_icons/ios/upload.svg', TRUE, NULL, v_system_user_id),
        ('upload.svg', 'upload.svg', 'image/svg+xml', 'global_icons/macos/upload.svg', TRUE, NULL, v_system_user_id),
        ('upload.png', 'upload.png', 'image/png', 'global_icons/windows/upload.png', TRUE, NULL, v_system_user_id),
        ('upload.svg', 'upload.svg', 'image/svg+xml', 'global_icons/linux/upload.svg', TRUE, NULL, v_system_user_id),
        ('share.svg', 'share.svg', 'image/svg+xml', 'global_icons/web/share.svg', TRUE, NULL, v_system_user_id),
        ('share.xml', 'share.xml', 'application/xml', 'global_icons/android/share.xml', TRUE, NULL, v_system_user_id),
        ('share.svg', 'share.svg', 'image/svg+xml', 'global_icons/ios/share.svg', TRUE, NULL, v_system_user_id),
        ('share.svg', 'share.svg', 'image/svg+xml', 'global_icons/macos/share.svg', TRUE, NULL, v_system_user_id),
        ('share.png', 'share.png', 'image/png', 'global_icons/windows/share.png', TRUE, NULL, v_system_user_id),
        ('share.svg', 'share.svg', 'image/svg+xml', 'global_icons/linux/share.svg', TRUE, NULL, v_system_user_id),
        ('link.svg', 'link.svg', 'image/svg+xml', 'global_icons/web/link.svg', TRUE, NULL, v_system_user_id),
        ('link.xml', 'link.xml', 'application/xml', 'global_icons/android/link.xml', TRUE, NULL, v_system_user_id),
        ('link.svg', 'link.svg', 'image/svg+xml', 'global_icons/ios/link.svg', TRUE, NULL, v_system_user_id),
        ('link.svg', 'link.svg', 'image/svg+xml', 'global_icons/macos/link.svg', TRUE, NULL, v_system_user_id),
        ('link.png', 'link.png', 'image/png', 'global_icons/windows/link.png', TRUE, NULL, v_system_user_id),
        ('link.svg', 'link.svg', 'image/svg+xml', 'global_icons/linux/link.svg', TRUE, NULL, v_system_user_id),
        ('copy.svg', 'copy.svg', 'image/svg+xml', 'global_icons/web/copy.svg', TRUE, NULL, v_system_user_id),
        ('copy.xml', 'copy.xml', 'application/xml', 'global_icons/android/copy.xml', TRUE, NULL, v_system_user_id),
        ('copy.svg', 'copy.svg', 'image/svg+xml', 'global_icons/ios/copy.svg', TRUE, NULL, v_system_user_id),
        ('copy.svg', 'copy.svg', 'image/svg+xml', 'global_icons/macos/copy.svg', TRUE, NULL, v_system_user_id),
        ('copy.png', 'copy.png', 'image/png', 'global_icons/windows/copy.png', TRUE, NULL, v_system_user_id),
        ('copy.svg', 'copy.svg', 'image/svg+xml', 'global_icons/linux/copy.svg', TRUE, NULL, v_system_user_id),
        ('filter.svg', 'filter.svg', 'image/svg+xml', 'global_icons/web/filter.svg', TRUE, NULL, v_system_user_id),
        ('filter.xml', 'filter.xml', 'application/xml', 'global_icons/android/filter.xml', TRUE, NULL, v_system_user_id),
        ('filter.svg', 'filter.svg', 'image/svg+xml', 'global_icons/ios/filter.svg', TRUE, NULL, v_system_user_id),
        ('filter.svg', 'filter.svg', 'image/svg+xml', 'global_icons/macos/filter.svg', TRUE, NULL, v_system_user_id),
        ('filter.png', 'filter.png', 'image/png', 'global_icons/windows/filter.png', TRUE, NULL, v_system_user_id),
        ('filter.svg', 'filter.svg', 'image/svg+xml', 'global_icons/linux/filter.svg', TRUE, NULL, v_system_user_id),
        ('sort.svg', 'sort.svg', 'image/svg+xml', 'global_icons/web/sort.svg', TRUE, NULL, v_system_user_id),
        ('sort.xml', 'sort.xml', 'application/xml', 'global_icons/android/sort.xml', TRUE, NULL, v_system_user_id),
        ('sort.svg', 'sort.svg', 'image/svg+xml', 'global_icons/ios/sort.svg', TRUE, NULL, v_system_user_id),
        ('sort.svg', 'sort.svg', 'image/svg+xml', 'global_icons/macos/sort.svg', TRUE, NULL, v_system_user_id),
        ('sort.png', 'sort.png', 'image/png', 'global_icons/windows/sort.png', TRUE, NULL, v_system_user_id),
        ('sort.svg', 'sort.svg', 'image/svg+xml', 'global_icons/linux/sort.svg', TRUE, NULL, v_system_user_id),
        ('calendar.svg', 'calendar.svg', 'image/svg+xml', 'global_icons/web/calendar.svg', TRUE, NULL, v_system_user_id),
        ('calendar.xml', 'calendar.xml', 'application/xml', 'global_icons/android/calendar.xml', TRUE, NULL, v_system_user_id),
        ('calendar.svg', 'calendar.svg', 'image/svg+xml', 'global_icons/ios/calendar.svg', TRUE, NULL, v_system_user_id),
        ('calendar.svg', 'calendar.svg', 'image/svg+xml', 'global_icons/macos/calendar.svg', TRUE, NULL, v_system_user_id),
        ('calendar.png', 'calendar.png', 'image/png', 'global_icons/windows/calendar.png', TRUE, NULL, v_system_user_id),
        ('calendar.svg', 'calendar.svg', 'image/svg+xml', 'global_icons/linux/calendar.svg', TRUE, NULL, v_system_user_id),
        ('clock.svg', 'clock.svg', 'image/svg+xml', 'global_icons/web/clock.svg', TRUE, NULL, v_system_user_id),
        ('clock.xml', 'clock.xml', 'application/xml', 'global_icons/android/clock.xml', TRUE, NULL, v_system_user_id),
        ('clock.svg', 'clock.svg', 'image/svg+xml', 'global_icons/ios/clock.svg', TRUE, NULL, v_system_user_id),
        ('clock.svg', 'clock.svg', 'image/svg+xml', 'global_icons/macos/clock.svg', TRUE, NULL, v_system_user_id),
        ('clock.png', 'clock.png', 'image/png', 'global_icons/windows/clock.png', TRUE, NULL, v_system_user_id),
        ('clock.svg', 'clock.svg', 'image/svg+xml', 'global_icons/linux/clock.svg', TRUE, NULL, v_system_user_id),
        ('mail.svg', 'mail.svg', 'image/svg+xml', 'global_icons/web/mail.svg', TRUE, NULL, v_system_user_id),
        ('mail.xml', 'mail.xml', 'application/xml', 'global_icons/android/mail.xml', TRUE, NULL, v_system_user_id),
        ('mail.svg', 'mail.svg', 'image/svg+xml', 'global_icons/ios/mail.svg', TRUE, NULL, v_system_user_id),
        ('mail.svg', 'mail.svg', 'image/svg+xml', 'global_icons/macos/mail.svg', TRUE, NULL, v_system_user_id),
        ('mail.png', 'mail.png', 'image/png', 'global_icons/windows/mail.png', TRUE, NULL, v_system_user_id),
        ('mail.svg', 'mail.svg', 'image/svg+xml', 'global_icons/linux/mail.svg', TRUE, NULL, v_system_user_id),
        ('phone.svg', 'phone.svg', 'image/svg+xml', 'global_icons/web/phone.svg', TRUE, NULL, v_system_user_id),
        ('phone.xml', 'phone.xml', 'application/xml', 'global_icons/android/phone.xml', TRUE, NULL, v_system_user_id),
        ('phone.svg', 'phone.svg', 'image/svg+xml', 'global_icons/ios/phone.svg', TRUE, NULL, v_system_user_id),
        ('phone.svg', 'phone.svg', 'image/svg+xml', 'global_icons/macos/phone.svg', TRUE, NULL, v_system_user_id),
        ('phone.png', 'phone.png', 'image/png', 'global_icons/windows/phone.png', TRUE, NULL, v_system_user_id),
        ('phone.svg', 'phone.svg', 'image/svg+xml', 'global_icons/linux/phone.svg', TRUE, NULL, v_system_user_id),
        ('map.svg', 'map.svg', 'image/svg+xml', 'global_icons/web/map.svg', TRUE, NULL, v_system_user_id),
        ('map.xml', 'map.xml', 'application/xml', 'global_icons/android/map.xml', TRUE, NULL, v_system_user_id),
        ('map.svg', 'map.svg', 'image/svg+xml', 'global_icons/ios/map.svg', TRUE, NULL, v_system_user_id),
        ('map.svg', 'map.svg', 'image/svg+xml', 'global_icons/macos/map.svg', TRUE, NULL, v_system_user_id),
        ('map.png', 'map.png', 'image/png', 'global_icons/windows/map.png', TRUE, NULL, v_system_user_id),
        ('map.svg', 'map.svg', 'image/svg+xml', 'global_icons/linux/map.svg', TRUE, NULL, v_system_user_id),
        ('location.svg', 'location.svg', 'image/svg+xml', 'global_icons/web/location.svg', TRUE, NULL, v_system_user_id),
        ('location.xml', 'location.xml', 'application/xml', 'global_icons/android/location.xml', TRUE, NULL, v_system_user_id),
        ('location.svg', 'location.svg', 'image/svg+xml', 'global_icons/ios/location.svg', TRUE, NULL, v_system_user_id),
        ('location.svg', 'location.svg', 'image/svg+xml', 'global_icons/macos/location.svg', TRUE, NULL, v_system_user_id),
        ('location.png', 'location.png', 'image/png', 'global_icons/windows/location.png', TRUE, NULL, v_system_user_id),
        ('location.svg', 'location.svg', 'image/svg+xml', 'global_icons/linux/location.svg', TRUE, NULL, v_system_user_id),
        ('camera.svg', 'camera.svg', 'image/svg+xml', 'global_icons/web/camera.svg', TRUE, NULL, v_system_user_id),
        ('camera.xml', 'camera.xml', 'application/xml', 'global_icons/android/camera.xml', TRUE, NULL, v_system_user_id),
        ('camera.svg', 'camera.svg', 'image/svg+xml', 'global_icons/ios/camera.svg', TRUE, NULL, v_system_user_id),
        ('camera.svg', 'camera.svg', 'image/svg+xml', 'global_icons/macos/camera.svg', TRUE, NULL, v_system_user_id),
        ('camera.png', 'camera.png', 'image/png', 'global_icons/windows/camera.png', TRUE, NULL, v_system_user_id),
        ('camera.svg', 'camera.svg', 'image/svg+xml', 'global_icons/linux/camera.svg', TRUE, NULL, v_system_user_id),
        ('image.svg', 'image.svg', 'image/svg+xml', 'global_icons/web/image.svg', TRUE, NULL, v_system_user_id),
        ('image.xml', 'image.xml', 'application/xml', 'global_icons/android/image.xml', TRUE, NULL, v_system_user_id),
        ('image.svg', 'image.svg', 'image/svg+xml', 'global_icons/ios/image.svg', TRUE, NULL, v_system_user_id),
        ('image.svg', 'image.svg', 'image/svg+xml', 'global_icons/macos/image.svg', TRUE, NULL, v_system_user_id),
        ('image.png', 'image.png', 'image/png', 'global_icons/windows/image.png', TRUE, NULL, v_system_user_id),
        ('image.svg', 'image.svg', 'image/svg+xml', 'global_icons/linux/image.svg', TRUE, NULL, v_system_user_id),
        ('file.svg', 'file.svg', 'image/svg+xml', 'global_icons/web/file.svg', TRUE, NULL, v_system_user_id),
        ('file.xml', 'file.xml', 'application/xml', 'global_icons/android/file.xml', TRUE, NULL, v_system_user_id),
        ('file.svg', 'file.svg', 'image/svg+xml', 'global_icons/ios/file.svg', TRUE, NULL, v_system_user_id),
        ('file.svg', 'file.svg', 'image/svg+xml', 'global_icons/macos/file.svg', TRUE, NULL, v_system_user_id),
        ('file.png', 'file.png', 'image/png', 'global_icons/windows/file.png', TRUE, NULL, v_system_user_id),
        ('file.svg', 'file.svg', 'image/svg+xml', 'global_icons/linux/file.svg', TRUE, NULL, v_system_user_id),
        ('folder.svg', 'folder.svg', 'image/svg+xml', 'global_icons/web/folder.svg', TRUE, NULL, v_system_user_id),
        ('folder.xml', 'folder.xml', 'application/xml', 'global_icons/android/folder.xml', TRUE, NULL, v_system_user_id),
        ('folder.svg', 'folder.svg', 'image/svg+xml', 'global_icons/ios/folder.svg', TRUE, NULL, v_system_user_id),
        ('folder.svg', 'folder.svg', 'image/svg+xml', 'global_icons/macos/folder.svg', TRUE, NULL, v_system_user_id),
        ('folder.png', 'folder.png', 'image/png', 'global_icons/windows/folder.png', TRUE, NULL, v_system_user_id),
        ('folder.svg', 'folder.svg', 'image/svg+xml', 'global_icons/linux/folder.svg', TRUE, NULL, v_system_user_id),
        ('document.svg', 'document.svg', 'image/svg+xml', 'global_icons/web/document.svg', TRUE, NULL, v_system_user_id),
        ('document.xml', 'document.xml', 'application/xml', 'global_icons/android/document.xml', TRUE, NULL, v_system_user_id),
        ('document.svg', 'document.svg', 'image/svg+xml', 'global_icons/ios/document.svg', TRUE, NULL, v_system_user_id),
        ('document.svg', 'document.svg', 'image/svg+xml', 'global_icons/macos/document.svg', TRUE, NULL, v_system_user_id),
        ('document.png', 'document.png', 'image/png', 'global_icons/windows/document.png', TRUE, NULL, v_system_user_id),
        ('document.svg', 'document.svg', 'image/svg+xml', 'global_icons/linux/document.svg', TRUE, NULL, v_system_user_id),
        ('print.svg', 'print.svg', 'image/svg+xml', 'global_icons/web/print.svg', TRUE, NULL, v_system_user_id),
        ('print.xml', 'print.xml', 'application/xml', 'global_icons/android/print.xml', TRUE, NULL, v_system_user_id),
        ('print.svg', 'print.svg', 'image/svg+xml', 'global_icons/ios/print.svg', TRUE, NULL, v_system_user_id),
        ('print.svg', 'print.svg', 'image/svg+xml', 'global_icons/macos/print.svg', TRUE, NULL, v_system_user_id),
        ('print.png', 'print.png', 'image/png', 'global_icons/windows/print.png', TRUE, NULL, v_system_user_id),
        ('print.svg', 'print.svg', 'image/svg+xml', 'global_icons/linux/print.svg', TRUE, NULL, v_system_user_id),
        ('lock.svg', 'lock.svg', 'image/svg+xml', 'global_icons/web/lock.svg', TRUE, NULL, v_system_user_id),
        ('lock.xml', 'lock.xml', 'application/xml', 'global_icons/android/lock.xml', TRUE, NULL, v_system_user_id),
        ('lock.svg', 'lock.svg', 'image/svg+xml', 'global_icons/ios/lock.svg', TRUE, NULL, v_system_user_id),
        ('lock.svg', 'lock.svg', 'image/svg+xml', 'global_icons/macos/lock.svg', TRUE, NULL, v_system_user_id),
        ('lock.png', 'lock.png', 'image/png', 'global_icons/windows/lock.png', TRUE, NULL, v_system_user_id),
        ('lock.svg', 'lock.svg', 'image/svg+xml', 'global_icons/linux/lock.svg', TRUE, NULL, v_system_user_id),
        ('unlock.svg', 'unlock.svg', 'image/svg+xml', 'global_icons/web/unlock.svg', TRUE, NULL, v_system_user_id),
        ('unlock.xml', 'unlock.xml', 'application/xml', 'global_icons/android/unlock.xml', TRUE, NULL, v_system_user_id),
        ('unlock.svg', 'unlock.svg', 'image/svg+xml', 'global_icons/ios/unlock.svg', TRUE, NULL, v_system_user_id),
        ('unlock.svg', 'unlock.svg', 'image/svg+xml', 'global_icons/macos/unlock.svg', TRUE, NULL, v_system_user_id),
        ('unlock.png', 'unlock.png', 'image/png', 'global_icons/windows/unlock.png', TRUE, NULL, v_system_user_id),
        ('unlock.svg', 'unlock.svg', 'image/svg+xml', 'global_icons/linux/unlock.svg', TRUE, NULL, v_system_user_id),
        ('key.svg', 'key.svg', 'image/svg+xml', 'global_icons/web/key.svg', TRUE, NULL, v_system_user_id),
        ('key.xml', 'key.xml', 'application/xml', 'global_icons/android/key.xml', TRUE, NULL, v_system_user_id),
        ('key.svg', 'key.svg', 'image/svg+xml', 'global_icons/ios/key.svg', TRUE, NULL, v_system_user_id),
        ('key.svg', 'key.svg', 'image/svg+xml', 'global_icons/macos/key.svg', TRUE, NULL, v_system_user_id),
        ('key.png', 'key.png', 'image/png', 'global_icons/windows/key.png', TRUE, NULL, v_system_user_id),
        ('key.svg', 'key.svg', 'image/svg+xml', 'global_icons/linux/key.svg', TRUE, NULL, v_system_user_id),
        ('star.svg', 'star.svg', 'image/svg+xml', 'global_icons/web/star.svg', TRUE, NULL, v_system_user_id),
        ('star.xml', 'star.xml', 'application/xml', 'global_icons/android/star.xml', TRUE, NULL, v_system_user_id),
        ('star.svg', 'star.svg', 'image/svg+xml', 'global_icons/ios/star.svg', TRUE, NULL, v_system_user_id),
        ('star.svg', 'star.svg', 'image/svg+xml', 'global_icons/macos/star.svg', TRUE, NULL, v_system_user_id),
        ('star.png', 'star.png', 'image/png', 'global_icons/windows/star.png', TRUE, NULL, v_system_user_id),
        ('star.svg', 'star.svg', 'image/svg+xml', 'global_icons/linux/star.svg', TRUE, NULL, v_system_user_id),
        ('heart.svg', 'heart.svg', 'image/svg+xml', 'global_icons/web/heart.svg', TRUE, NULL, v_system_user_id),
        ('heart.xml', 'heart.xml', 'application/xml', 'global_icons/android/heart.xml', TRUE, NULL, v_system_user_id),
        ('heart.svg', 'heart.svg', 'image/svg+xml', 'global_icons/ios/heart.svg', TRUE, NULL, v_system_user_id),
        ('heart.svg', 'heart.svg', 'image/svg+xml', 'global_icons/macos/heart.svg', TRUE, NULL, v_system_user_id),
        ('heart.png', 'heart.png', 'image/png', 'global_icons/windows/heart.png', TRUE, NULL, v_system_user_id),
        ('heart.svg', 'heart.svg', 'image/svg+xml', 'global_icons/linux/heart.svg', TRUE, NULL, v_system_user_id),
        ('bell.svg', 'bell.svg', 'image/svg+xml', 'global_icons/web/bell.svg', TRUE, NULL, v_system_user_id),
        ('bell.xml', 'bell.xml', 'application/xml', 'global_icons/android/bell.xml', TRUE, NULL, v_system_user_id),
        ('bell.svg', 'bell.svg', 'image/svg+xml', 'global_icons/ios/bell.svg', TRUE, NULL, v_system_user_id),
        ('bell.svg', 'bell.svg', 'image/svg+xml', 'global_icons/macos/bell.svg', TRUE, NULL, v_system_user_id),
        ('bell.png', 'bell.png', 'image/png', 'global_icons/windows/bell.png', TRUE, NULL, v_system_user_id),
        ('bell.svg', 'bell.svg', 'image/svg+xml', 'global_icons/linux/bell.svg', TRUE, NULL, v_system_user_id),
        ('flag.svg', 'flag.svg', 'image/svg+xml', 'global_icons/web/flag.svg', TRUE, NULL, v_system_user_id),
        ('flag.xml', 'flag.xml', 'application/xml', 'global_icons/android/flag.xml', TRUE, NULL, v_system_user_id),
        ('flag.svg', 'flag.svg', 'image/svg+xml', 'global_icons/ios/flag.svg', TRUE, NULL, v_system_user_id),
        ('flag.svg', 'flag.svg', 'image/svg+xml', 'global_icons/macos/flag.svg', TRUE, NULL, v_system_user_id),
        ('flag.png', 'flag.png', 'image/png', 'global_icons/windows/flag.png', TRUE, NULL, v_system_user_id),
        ('flag.svg', 'flag.svg', 'image/svg+xml', 'global_icons/linux/flag.svg', TRUE, NULL, v_system_user_id),
        ('bookmark.svg', 'bookmark.svg', 'image/svg+xml', 'global_icons/web/bookmark.svg', TRUE, NULL, v_system_user_id),
        ('bookmark.xml', 'bookmark.xml', 'application/xml', 'global_icons/android/bookmark.xml', TRUE, NULL, v_system_user_id),
        ('bookmark.svg', 'bookmark.svg', 'image/svg+xml', 'global_icons/ios/bookmark.svg', TRUE, NULL, v_system_user_id),
        ('bookmark.svg', 'bookmark.svg', 'image/svg+xml', 'global_icons/macos/bookmark.svg', TRUE, NULL, v_system_user_id),
        ('bookmark.png', 'bookmark.png', 'image/png', 'global_icons/windows/bookmark.png', TRUE, NULL, v_system_user_id),
        ('bookmark.svg', 'bookmark.svg', 'image/svg+xml', 'global_icons/linux/bookmark.svg', TRUE, NULL, v_system_user_id),
        ('tag.svg', 'tag.svg', 'image/svg+xml', 'global_icons/web/tag.svg', TRUE, NULL, v_system_user_id),
        ('tag.xml', 'tag.xml', 'application/xml', 'global_icons/android/tag.xml', TRUE, NULL, v_system_user_id),
        ('tag.svg', 'tag.svg', 'image/svg+xml', 'global_icons/ios/tag.svg', TRUE, NULL, v_system_user_id),
        ('tag.svg', 'tag.svg', 'image/svg+xml', 'global_icons/macos/tag.svg', TRUE, NULL, v_system_user_id),
        ('tag.png', 'tag.png', 'image/png', 'global_icons/windows/tag.png', TRUE, NULL, v_system_user_id),
        ('tag.svg', 'tag.svg', 'image/svg+xml', 'global_icons/linux/tag.svg', TRUE, NULL, v_system_user_id),
        ('cart.svg', 'cart.svg', 'image/svg+xml', 'global_icons/web/cart.svg', TRUE, NULL, v_system_user_id),
        ('cart.xml', 'cart.xml', 'application/xml', 'global_icons/android/cart.xml', TRUE, NULL, v_system_user_id),
        ('cart.svg', 'cart.svg', 'image/svg+xml', 'global_icons/ios/cart.svg', TRUE, NULL, v_system_user_id),
        ('cart.svg', 'cart.svg', 'image/svg+xml', 'global_icons/macos/cart.svg', TRUE, NULL, v_system_user_id),
        ('cart.png', 'cart.png', 'image/png', 'global_icons/windows/cart.png', TRUE, NULL, v_system_user_id),
        ('cart.svg', 'cart.svg', 'image/svg+xml', 'global_icons/linux/cart.svg', TRUE, NULL, v_system_user_id),
        ('shop.svg', 'shop.svg', 'image/svg+xml', 'global_icons/web/shop.svg', TRUE, NULL, v_system_user_id),
        ('shop.xml', 'shop.xml', 'application/xml', 'global_icons/android/shop.xml', TRUE, NULL, v_system_user_id),
        ('shop.svg', 'shop.svg', 'image/svg+xml', 'global_icons/ios/shop.svg', TRUE, NULL, v_system_user_id),
        ('shop.svg', 'shop.svg', 'image/svg+xml', 'global_icons/macos/shop.svg', TRUE, NULL, v_system_user_id),
        ('shop.png', 'shop.png', 'image/png', 'global_icons/windows/shop.png', TRUE, NULL, v_system_user_id),
        ('shop.svg', 'shop.svg', 'image/svg+xml', 'global_icons/linux/shop.svg', TRUE, NULL, v_system_user_id),
        ('credit_card.svg', 'credit_card.svg', 'image/svg+xml', 'global_icons/web/credit_card.svg', TRUE, NULL, v_system_user_id),
        ('credit_card.xml', 'credit_card.xml', 'application/xml', 'global_icons/android/credit_card.xml', TRUE, NULL, v_system_user_id),
        ('credit_card.svg', 'credit_card.svg', 'image/svg+xml', 'global_icons/ios/credit_card.svg', TRUE, NULL, v_system_user_id),
        ('credit_card.svg', 'credit_card.svg', 'image/svg+xml', 'global_icons/macos/credit_card.svg', TRUE, NULL, v_system_user_id),
        ('credit_card.png', 'credit_card.png', 'image/png', 'global_icons/windows/credit_card.png', TRUE, NULL, v_system_user_id),
        ('credit_card.svg', 'credit_card.svg', 'image/svg+xml', 'global_icons/linux/credit_card.svg', TRUE, NULL, v_system_user_id),
        ('dollar.svg', 'dollar.svg', 'image/svg+xml', 'global_icons/web/dollar.svg', TRUE, NULL, v_system_user_id),
        ('dollar.xml', 'dollar.xml', 'application/xml', 'global_icons/android/dollar.xml', TRUE, NULL, v_system_user_id),
        ('dollar.svg', 'dollar.svg', 'image/svg+xml', 'global_icons/ios/dollar.svg', TRUE, NULL, v_system_user_id),
        ('dollar.svg', 'dollar.svg', 'image/svg+xml', 'global_icons/macos/dollar.svg', TRUE, NULL, v_system_user_id),
        ('dollar.png', 'dollar.png', 'image/png', 'global_icons/windows/dollar.png', TRUE, NULL, v_system_user_id),
        ('dollar.svg', 'dollar.svg', 'image/svg+xml', 'global_icons/linux/dollar.svg', TRUE, NULL, v_system_user_id),
        ('chart.svg', 'chart.svg', 'image/svg+xml', 'global_icons/web/chart.svg', TRUE, NULL, v_system_user_id),
        ('chart.xml', 'chart.xml', 'application/xml', 'global_icons/android/chart.xml', TRUE, NULL, v_system_user_id),
        ('chart.svg', 'chart.svg', 'image/svg+xml', 'global_icons/ios/chart.svg', TRUE, NULL, v_system_user_id),
        ('chart.svg', 'chart.svg', 'image/svg+xml', 'global_icons/macos/chart.svg', TRUE, NULL, v_system_user_id),
        ('chart.png', 'chart.png', 'image/png', 'global_icons/windows/chart.png', TRUE, NULL, v_system_user_id),
        ('chart.svg', 'chart.svg', 'image/svg+xml', 'global_icons/linux/chart.svg', TRUE, NULL, v_system_user_id),
        ('graph.svg', 'graph.svg', 'image/svg+xml', 'global_icons/web/graph.svg', TRUE, NULL, v_system_user_id),
        ('graph.xml', 'graph.xml', 'application/xml', 'global_icons/android/graph.xml', TRUE, NULL, v_system_user_id),
        ('graph.svg', 'graph.svg', 'image/svg+xml', 'global_icons/ios/graph.svg', TRUE, NULL, v_system_user_id),
        ('graph.svg', 'graph.svg', 'image/svg+xml', 'global_icons/macos/graph.svg', TRUE, NULL, v_system_user_id),
        ('graph.png', 'graph.png', 'image/png', 'global_icons/windows/graph.png', TRUE, NULL, v_system_user_id),
        ('graph.svg', 'graph.svg', 'image/svg+xml', 'global_icons/linux/graph.svg', TRUE, NULL, v_system_user_id),
        ('table.svg', 'table.svg', 'image/svg+xml', 'global_icons/web/table.svg', TRUE, NULL, v_system_user_id),
        ('table.xml', 'table.xml', 'application/xml', 'global_icons/android/table.xml', TRUE, NULL, v_system_user_id),
        ('table.svg', 'table.svg', 'image/svg+xml', 'global_icons/ios/table.svg', TRUE, NULL, v_system_user_id),
        ('table.svg', 'table.svg', 'image/svg+xml', 'global_icons/macos/table.svg', TRUE, NULL, v_system_user_id),
        ('table.png', 'table.png', 'image/png', 'global_icons/windows/table.png', TRUE, NULL, v_system_user_id),
        ('table.svg', 'table.svg', 'image/svg+xml', 'global_icons/linux/table.svg', TRUE, NULL, v_system_user_id),
        ('list.svg', 'list.svg', 'image/svg+xml', 'global_icons/web/list.svg', TRUE, NULL, v_system_user_id),
        ('list.xml', 'list.xml', 'application/xml', 'global_icons/android/list.xml', TRUE, NULL, v_system_user_id),
        ('list.svg', 'list.svg', 'image/svg+xml', 'global_icons/ios/list.svg', TRUE, NULL, v_system_user_id),
        ('list.svg', 'list.svg', 'image/svg+xml', 'global_icons/macos/list.svg', TRUE, NULL, v_system_user_id),
        ('list.png', 'list.png', 'image/png', 'global_icons/windows/list.png', TRUE, NULL, v_system_user_id),
        ('list.svg', 'list.svg', 'image/svg+xml', 'global_icons/linux/list.svg', TRUE, NULL, v_system_user_id),
        ('grid.svg', 'grid.svg', 'image/svg+xml', 'global_icons/web/grid.svg', TRUE, NULL, v_system_user_id),
        ('grid.xml', 'grid.xml', 'application/xml', 'global_icons/android/grid.xml', TRUE, NULL, v_system_user_id),
        ('grid.svg', 'grid.svg', 'image/svg+xml', 'global_icons/ios/grid.svg', TRUE, NULL, v_system_user_id),
        ('grid.svg', 'grid.svg', 'image/svg+xml', 'global_icons/macos/grid.svg', TRUE, NULL, v_system_user_id),
        ('grid.png', 'grid.png', 'image/png', 'global_icons/windows/grid.png', TRUE, NULL, v_system_user_id),
        ('grid.svg', 'grid.svg', 'image/svg+xml', 'global_icons/linux/grid.svg', TRUE, NULL, v_system_user_id),
        ('layout.svg', 'layout.svg', 'image/svg+xml', 'global_icons/web/layout.svg', TRUE, NULL, v_system_user_id),
        ('layout.xml', 'layout.xml', 'application/xml', 'global_icons/android/layout.xml', TRUE, NULL, v_system_user_id),
        ('layout.svg', 'layout.svg', 'image/svg+xml', 'global_icons/ios/layout.svg', TRUE, NULL, v_system_user_id),
        ('layout.svg', 'layout.svg', 'image/svg+xml', 'global_icons/macos/layout.svg', TRUE, NULL, v_system_user_id),
        ('layout.png', 'layout.png', 'image/png', 'global_icons/windows/layout.png', TRUE, NULL, v_system_user_id),
        ('layout.svg', 'layout.svg', 'image/svg+xml', 'global_icons/linux/layout.svg', TRUE, NULL, v_system_user_id),
        ('mobile.svg', 'mobile.svg', 'image/svg+xml', 'global_icons/web/mobile.svg', TRUE, NULL, v_system_user_id),
        ('mobile.xml', 'mobile.xml', 'application/xml', 'global_icons/android/mobile.xml', TRUE, NULL, v_system_user_id),
        ('mobile.svg', 'mobile.svg', 'image/svg+xml', 'global_icons/ios/mobile.svg', TRUE, NULL, v_system_user_id),
        ('mobile.svg', 'mobile.svg', 'image/svg+xml', 'global_icons/macos/mobile.svg', TRUE, NULL, v_system_user_id),
        ('mobile.png', 'mobile.png', 'image/png', 'global_icons/windows/mobile.png', TRUE, NULL, v_system_user_id),
        ('mobile.svg', 'mobile.svg', 'image/svg+xml', 'global_icons/linux/mobile.svg', TRUE, NULL, v_system_user_id),
        ('tablet.svg', 'tablet.svg', 'image/svg+xml', 'global_icons/web/tablet.svg', TRUE, NULL, v_system_user_id),
        ('tablet.xml', 'tablet.xml', 'application/xml', 'global_icons/android/tablet.xml', TRUE, NULL, v_system_user_id),
        ('tablet.svg', 'tablet.svg', 'image/svg+xml', 'global_icons/ios/tablet.svg', TRUE, NULL, v_system_user_id),
        ('tablet.svg', 'tablet.svg', 'image/svg+xml', 'global_icons/macos/tablet.svg', TRUE, NULL, v_system_user_id),
        ('tablet.png', 'tablet.png', 'image/png', 'global_icons/windows/tablet.png', TRUE, NULL, v_system_user_id),
        ('tablet.svg', 'tablet.svg', 'image/svg+xml', 'global_icons/linux/tablet.svg', TRUE, NULL, v_system_user_id),
        ('desktop.svg', 'desktop.svg', 'image/svg+xml', 'global_icons/web/desktop.svg', TRUE, NULL, v_system_user_id),
        ('desktop.xml', 'desktop.xml', 'application/xml', 'global_icons/android/desktop.xml', TRUE, NULL, v_system_user_id),
        ('desktop.svg', 'desktop.svg', 'image/svg+xml', 'global_icons/ios/desktop.svg', TRUE, NULL, v_system_user_id),
        ('desktop.svg', 'desktop.svg', 'image/svg+xml', 'global_icons/macos/desktop.svg', TRUE, NULL, v_system_user_id),
        ('desktop.png', 'desktop.png', 'image/png', 'global_icons/windows/desktop.png', TRUE, NULL, v_system_user_id),
        ('desktop.svg', 'desktop.svg', 'image/svg+xml', 'global_icons/linux/desktop.svg', TRUE, NULL, v_system_user_id),
        ('wifi.svg', 'wifi.svg', 'image/svg+xml', 'global_icons/web/wifi.svg', TRUE, NULL, v_system_user_id),
        ('wifi.xml', 'wifi.xml', 'application/xml', 'global_icons/android/wifi.xml', TRUE, NULL, v_system_user_id),
        ('wifi.svg', 'wifi.svg', 'image/svg+xml', 'global_icons/ios/wifi.svg', TRUE, NULL, v_system_user_id),
        ('wifi.svg', 'wifi.svg', 'image/svg+xml', 'global_icons/macos/wifi.svg', TRUE, NULL, v_system_user_id),
        ('wifi.png', 'wifi.png', 'image/png', 'global_icons/windows/wifi.png', TRUE, NULL, v_system_user_id),
        ('wifi.svg', 'wifi.svg', 'image/svg+xml', 'global_icons/linux/wifi.svg', TRUE, NULL, v_system_user_id),
        ('bluetooth.svg', 'bluetooth.svg', 'image/svg+xml', 'global_icons/web/bluetooth.svg', TRUE, NULL, v_system_user_id),
        ('bluetooth.xml', 'bluetooth.xml', 'application/xml', 'global_icons/android/bluetooth.xml', TRUE, NULL, v_system_user_id),
        ('bluetooth.svg', 'bluetooth.svg', 'image/svg+xml', 'global_icons/ios/bluetooth.svg', TRUE, NULL, v_system_user_id),
        ('bluetooth.svg', 'bluetooth.svg', 'image/svg+xml', 'global_icons/macos/bluetooth.svg', TRUE, NULL, v_system_user_id),
        ('bluetooth.png', 'bluetooth.png', 'image/png', 'global_icons/windows/bluetooth.png', TRUE, NULL, v_system_user_id),
        ('bluetooth.svg', 'bluetooth.svg', 'image/svg+xml', 'global_icons/linux/bluetooth.svg', TRUE, NULL, v_system_user_id),
        ('battery.svg', 'battery.svg', 'image/svg+xml', 'global_icons/web/battery.svg', TRUE, NULL, v_system_user_id),
        ('battery.xml', 'battery.xml', 'application/xml', 'global_icons/android/battery.xml', TRUE, NULL, v_system_user_id),
        ('battery.svg', 'battery.svg', 'image/svg+xml', 'global_icons/ios/battery.svg', TRUE, NULL, v_system_user_id),
        ('battery.svg', 'battery.svg', 'image/svg+xml', 'global_icons/macos/battery.svg', TRUE, NULL, v_system_user_id),
        ('battery.png', 'battery.png', 'image/png', 'global_icons/windows/battery.png', TRUE, NULL, v_system_user_id),
        ('battery.svg', 'battery.svg', 'image/svg+xml', 'global_icons/linux/battery.svg', TRUE, NULL, v_system_user_id),
        ('volume.svg', 'volume.svg', 'image/svg+xml', 'global_icons/web/volume.svg', TRUE, NULL, v_system_user_id),
        ('volume.xml', 'volume.xml', 'application/xml', 'global_icons/android/volume.xml', TRUE, NULL, v_system_user_id),
        ('volume.svg', 'volume.svg', 'image/svg+xml', 'global_icons/ios/volume.svg', TRUE, NULL, v_system_user_id),
        ('volume.svg', 'volume.svg', 'image/svg+xml', 'global_icons/macos/volume.svg', TRUE, NULL, v_system_user_id),
        ('volume.png', 'volume.png', 'image/png', 'global_icons/windows/volume.png', TRUE, NULL, v_system_user_id),
        ('volume.svg', 'volume.svg', 'image/svg+xml', 'global_icons/linux/volume.svg', TRUE, NULL, v_system_user_id),
        ('play.svg', 'play.svg', 'image/svg+xml', 'global_icons/web/play.svg', TRUE, NULL, v_system_user_id),
        ('play.xml', 'play.xml', 'application/xml', 'global_icons/android/play.xml', TRUE, NULL, v_system_user_id),
        ('play.svg', 'play.svg', 'image/svg+xml', 'global_icons/ios/play.svg', TRUE, NULL, v_system_user_id),
        ('play.svg', 'play.svg', 'image/svg+xml', 'global_icons/macos/play.svg', TRUE, NULL, v_system_user_id),
        ('play.png', 'play.png', 'image/png', 'global_icons/windows/play.png', TRUE, NULL, v_system_user_id),
        ('play.svg', 'play.svg', 'image/svg+xml', 'global_icons/linux/play.svg', TRUE, NULL, v_system_user_id),
        ('pause.svg', 'pause.svg', 'image/svg+xml', 'global_icons/web/pause.svg', TRUE, NULL, v_system_user_id),
        ('pause.xml', 'pause.xml', 'application/xml', 'global_icons/android/pause.xml', TRUE, NULL, v_system_user_id),
        ('pause.svg', 'pause.svg', 'image/svg+xml', 'global_icons/ios/pause.svg', TRUE, NULL, v_system_user_id),
        ('pause.svg', 'pause.svg', 'image/svg+xml', 'global_icons/macos/pause.svg', TRUE, NULL, v_system_user_id),
        ('pause.png', 'pause.png', 'image/png', 'global_icons/windows/pause.png', TRUE, NULL, v_system_user_id),
        ('pause.svg', 'pause.svg', 'image/svg+xml', 'global_icons/linux/pause.svg', TRUE, NULL, v_system_user_id),
        ('stop.svg', 'stop.svg', 'image/svg+xml', 'global_icons/web/stop.svg', TRUE, NULL, v_system_user_id),
        ('stop.xml', 'stop.xml', 'application/xml', 'global_icons/android/stop.xml', TRUE, NULL, v_system_user_id),
        ('stop.svg', 'stop.svg', 'image/svg+xml', 'global_icons/ios/stop.svg', TRUE, NULL, v_system_user_id),
        ('stop.svg', 'stop.svg', 'image/svg+xml', 'global_icons/macos/stop.svg', TRUE, NULL, v_system_user_id),
        ('stop.png', 'stop.png', 'image/png', 'global_icons/windows/stop.png', TRUE, NULL, v_system_user_id),
        ('stop.svg', 'stop.svg', 'image/svg+xml', 'global_icons/linux/stop.svg', TRUE, NULL, v_system_user_id),
        ('next_track.svg', 'next_track.svg', 'image/svg+xml', 'global_icons/web/next_track.svg', TRUE, NULL, v_system_user_id),
        ('next_track.xml', 'next_track.xml', 'application/xml', 'global_icons/android/next_track.xml', TRUE, NULL, v_system_user_id),
        ('next_track.svg', 'next_track.svg', 'image/svg+xml', 'global_icons/ios/next_track.svg', TRUE, NULL, v_system_user_id),
        ('next_track.svg', 'next_track.svg', 'image/svg+xml', 'global_icons/macos/next_track.svg', TRUE, NULL, v_system_user_id),
        ('next_track.png', 'next_track.png', 'image/png', 'global_icons/windows/next_track.png', TRUE, NULL, v_system_user_id),
        ('next_track.svg', 'next_track.svg', 'image/svg+xml', 'global_icons/linux/next_track.svg', TRUE, NULL, v_system_user_id),
        ('previous_track.svg', 'previous_track.svg', 'image/svg+xml', 'global_icons/web/previous_track.svg', TRUE, NULL, v_system_user_id),
        ('previous_track.xml', 'previous_track.xml', 'application/xml', 'global_icons/android/previous_track.xml', TRUE, NULL, v_system_user_id),
        ('previous_track.svg', 'previous_track.svg', 'image/svg+xml', 'global_icons/ios/previous_track.svg', TRUE, NULL, v_system_user_id),
        ('previous_track.svg', 'previous_track.svg', 'image/svg+xml', 'global_icons/macos/previous_track.svg', TRUE, NULL, v_system_user_id),
        ('previous_track.png', 'previous_track.png', 'image/png', 'global_icons/windows/previous_track.png', TRUE, NULL, v_system_user_id),
        ('previous_track.svg', 'previous_track.svg', 'image/svg+xml', 'global_icons/linux/previous_track.svg', TRUE, NULL, v_system_user_id),
        ('info.svg', 'info.svg', 'image/svg+xml', 'global_icons/web/info.svg', TRUE, NULL, v_system_user_id),
        ('info.xml', 'info.xml', 'application/xml', 'global_icons/android/info.xml', TRUE, NULL, v_system_user_id),
        ('info.svg', 'info.svg', 'image/svg+xml', 'global_icons/ios/info.svg', TRUE, NULL, v_system_user_id),
        ('info.svg', 'info.svg', 'image/svg+xml', 'global_icons/macos/info.svg', TRUE, NULL, v_system_user_id),
        ('info.png', 'info.png', 'image/png', 'global_icons/windows/info.png', TRUE, NULL, v_system_user_id),
        ('info.svg', 'info.svg', 'image/svg+xml', 'global_icons/linux/info.svg', TRUE, NULL, v_system_user_id),
        ('help.svg', 'help.svg', 'image/svg+xml', 'global_icons/web/help.svg', TRUE, NULL, v_system_user_id),
        ('help.xml', 'help.xml', 'application/xml', 'global_icons/android/help.xml', TRUE, NULL, v_system_user_id),
        ('help.svg', 'help.svg', 'image/svg+xml', 'global_icons/ios/help.svg', TRUE, NULL, v_system_user_id),
        ('help.svg', 'help.svg', 'image/svg+xml', 'global_icons/macos/help.svg', TRUE, NULL, v_system_user_id),
        ('help.png', 'help.png', 'image/png', 'global_icons/windows/help.png', TRUE, NULL, v_system_user_id),
        ('help.svg', 'help.svg', 'image/svg+xml', 'global_icons/linux/help.svg', TRUE, NULL, v_system_user_id),
        ('warning.svg', 'warning.svg', 'image/svg+xml', 'global_icons/web/warning.svg', TRUE, NULL, v_system_user_id),
        ('warning.xml', 'warning.xml', 'application/xml', 'global_icons/android/warning.xml', TRUE, NULL, v_system_user_id),
        ('warning.svg', 'warning.svg', 'image/svg+xml', 'global_icons/ios/warning.svg', TRUE, NULL, v_system_user_id),
        ('warning.svg', 'warning.svg', 'image/svg+xml', 'global_icons/macos/warning.svg', TRUE, NULL, v_system_user_id),
        ('warning.png', 'warning.png', 'image/png', 'global_icons/windows/warning.png', TRUE, NULL, v_system_user_id),
        ('warning.svg', 'warning.svg', 'image/svg+xml', 'global_icons/linux/warning.svg', TRUE, NULL, v_system_user_id),
        ('error.svg', 'error.svg', 'image/svg+xml', 'global_icons/web/error.svg', TRUE, NULL, v_system_user_id),
        ('error.xml', 'error.xml', 'application/xml', 'global_icons/android/error.xml', TRUE, NULL, v_system_user_id),
        ('error.svg', 'error.svg', 'image/svg+xml', 'global_icons/ios/error.svg', TRUE, NULL, v_system_user_id),
        ('error.svg', 'error.svg', 'image/svg+xml', 'global_icons/macos/error.svg', TRUE, NULL, v_system_user_id),
        ('error.png', 'error.png', 'image/png', 'global_icons/windows/error.png', TRUE, NULL, v_system_user_id),
        ('error.svg', 'error.svg', 'image/svg+xml', 'global_icons/linux/error.svg', TRUE, NULL, v_system_user_id),
        ('success.svg', 'success.svg', 'image/svg+xml', 'global_icons/web/success.svg', TRUE, NULL, v_system_user_id),
        ('success.xml', 'success.xml', 'application/xml', 'global_icons/android/success.xml', TRUE, NULL, v_system_user_id),
        ('success.svg', 'success.svg', 'image/svg+xml', 'global_icons/ios/success.svg', TRUE, NULL, v_system_user_id),
        ('success.svg', 'success.svg', 'image/svg+xml', 'global_icons/macos/success.svg', TRUE, NULL, v_system_user_id),
        ('success.png', 'success.png', 'image/png', 'global_icons/windows/success.png', TRUE, NULL, v_system_user_id),
        ('success.svg', 'success.svg', 'image/svg+xml', 'global_icons/linux/success.svg', TRUE, NULL, v_system_user_id),
        ('question.svg', 'question.svg', 'image/svg+xml', 'global_icons/web/question.svg', TRUE, NULL, v_system_user_id),
        ('question.xml', 'question.xml', 'application/xml', 'global_icons/android/question.xml', TRUE, NULL, v_system_user_id),
        ('question.svg', 'question.svg', 'image/svg+xml', 'global_icons/ios/question.svg', TRUE, NULL, v_system_user_id),
        ('question.svg', 'question.svg', 'image/svg+xml', 'global_icons/macos/question.svg', TRUE, NULL, v_system_user_id),
        ('question.png', 'question.png', 'image/png', 'global_icons/windows/question.png', TRUE, NULL, v_system_user_id),
        ('question.svg', 'question.svg', 'image/svg+xml', 'global_icons/linux/question.svg', TRUE, NULL, v_system_user_id),
        ('eye.svg', 'eye.svg', 'image/svg+xml', 'global_icons/web/eye.svg', TRUE, NULL, v_system_user_id),
        ('eye.xml', 'eye.xml', 'application/xml', 'global_icons/android/eye.xml', TRUE, NULL, v_system_user_id),
        ('eye.svg', 'eye.svg', 'image/svg+xml', 'global_icons/ios/eye.svg', TRUE, NULL, v_system_user_id),
        ('eye.svg', 'eye.svg', 'image/svg+xml', 'global_icons/macos/eye.svg', TRUE, NULL, v_system_user_id),
        ('eye.png', 'eye.png', 'image/png', 'global_icons/windows/eye.png', TRUE, NULL, v_system_user_id),
        ('eye.svg', 'eye.svg', 'image/svg+xml', 'global_icons/linux/eye.svg', TRUE, NULL, v_system_user_id),
        ('eye_off.svg', 'eye_off.svg', 'image/svg+xml', 'global_icons/web/eye_off.svg', TRUE, NULL, v_system_user_id),
        ('eye_off.xml', 'eye_off.xml', 'application/xml', 'global_icons/android/eye_off.xml', TRUE, NULL, v_system_user_id),
        ('eye_off.svg', 'eye_off.svg', 'image/svg+xml', 'global_icons/ios/eye_off.svg', TRUE, NULL, v_system_user_id),
        ('eye_off.svg', 'eye_off.svg', 'image/svg+xml', 'global_icons/macos/eye_off.svg', TRUE, NULL, v_system_user_id),
        ('eye_off.png', 'eye_off.png', 'image/png', 'global_icons/windows/eye_off.png', TRUE, NULL, v_system_user_id),
        ('eye_off.svg', 'eye_off.svg', 'image/svg+xml', 'global_icons/linux/eye_off.svg', TRUE, NULL, v_system_user_id),
        ('plus.svg', 'plus.svg', 'image/svg+xml', 'global_icons/web/plus.svg', TRUE, NULL, v_system_user_id),
        ('plus.xml', 'plus.xml', 'application/xml', 'global_icons/android/plus.xml', TRUE, NULL, v_system_user_id),
        ('plus.svg', 'plus.svg', 'image/svg+xml', 'global_icons/ios/plus.svg', TRUE, NULL, v_system_user_id),
        ('plus.svg', 'plus.svg', 'image/svg+xml', 'global_icons/macos/plus.svg', TRUE, NULL, v_system_user_id),
        ('plus.png', 'plus.png', 'image/png', 'global_icons/windows/plus.png', TRUE, NULL, v_system_user_id),
        ('plus.svg', 'plus.svg', 'image/svg+xml', 'global_icons/linux/plus.svg', TRUE, NULL, v_system_user_id),
        ('minus.svg', 'minus.svg', 'image/svg+xml', 'global_icons/web/minus.svg', TRUE, NULL, v_system_user_id),
        ('minus.xml', 'minus.xml', 'application/xml', 'global_icons/android/minus.xml', TRUE, NULL, v_system_user_id),
        ('minus.svg', 'minus.svg', 'image/svg+xml', 'global_icons/ios/minus.svg', TRUE, NULL, v_system_user_id),
        ('minus.svg', 'minus.svg', 'image/svg+xml', 'global_icons/macos/minus.svg', TRUE, NULL, v_system_user_id),
        ('minus.png', 'minus.png', 'image/png', 'global_icons/windows/minus.png', TRUE, NULL, v_system_user_id),
        ('minus.svg', 'minus.svg', 'image/svg+xml', 'global_icons/linux/minus.svg', TRUE, NULL, v_system_user_id),
        ('expand.svg', 'expand.svg', 'image/svg+xml', 'global_icons/web/expand.svg', TRUE, NULL, v_system_user_id),
        ('expand.xml', 'expand.xml', 'application/xml', 'global_icons/android/expand.xml', TRUE, NULL, v_system_user_id),
        ('expand.svg', 'expand.svg', 'image/svg+xml', 'global_icons/ios/expand.svg', TRUE, NULL, v_system_user_id),
        ('expand.svg', 'expand.svg', 'image/svg+xml', 'global_icons/macos/expand.svg', TRUE, NULL, v_system_user_id),
        ('expand.png', 'expand.png', 'image/png', 'global_icons/windows/expand.png', TRUE, NULL, v_system_user_id),
        ('expand.svg', 'expand.svg', 'image/svg+xml', 'global_icons/linux/expand.svg', TRUE, NULL, v_system_user_id),
        ('collapse.svg', 'collapse.svg', 'image/svg+xml', 'global_icons/web/collapse.svg', TRUE, NULL, v_system_user_id),
        ('collapse.xml', 'collapse.xml', 'application/xml', 'global_icons/android/collapse.xml', TRUE, NULL, v_system_user_id),
        ('collapse.svg', 'collapse.svg', 'image/svg+xml', 'global_icons/ios/collapse.svg', TRUE, NULL, v_system_user_id),
        ('collapse.svg', 'collapse.svg', 'image/svg+xml', 'global_icons/macos/collapse.svg', TRUE, NULL, v_system_user_id),
        ('collapse.png', 'collapse.png', 'image/png', 'global_icons/windows/collapse.png', TRUE, NULL, v_system_user_id),
        ('collapse.svg', 'collapse.svg', 'image/svg+xml', 'global_icons/linux/collapse.svg', TRUE, NULL, v_system_user_id),
        ('more.svg', 'more.svg', 'image/svg+xml', 'global_icons/web/more.svg', TRUE, NULL, v_system_user_id),
        ('more.xml', 'more.xml', 'application/xml', 'global_icons/android/more.xml', TRUE, NULL, v_system_user_id),
        ('more.svg', 'more.svg', 'image/svg+xml', 'global_icons/ios/more.svg', TRUE, NULL, v_system_user_id),
        ('more.svg', 'more.svg', 'image/svg+xml', 'global_icons/macos/more.svg', TRUE, NULL, v_system_user_id),
        ('more.png', 'more.png', 'image/png', 'global_icons/windows/more.png', TRUE, NULL, v_system_user_id),
        ('more.svg', 'more.svg', 'image/svg+xml', 'global_icons/linux/more.svg', TRUE, NULL, v_system_user_id),
        ('dots_vertical.svg', 'dots_vertical.svg', 'image/svg+xml', 'global_icons/web/dots_vertical.svg', TRUE, NULL, v_system_user_id),
        ('dots_vertical.xml', 'dots_vertical.xml', 'application/xml', 'global_icons/android/dots_vertical.xml', TRUE, NULL, v_system_user_id),
        ('dots_vertical.svg', 'dots_vertical.svg', 'image/svg+xml', 'global_icons/ios/dots_vertical.svg', TRUE, NULL, v_system_user_id),
        ('dots_vertical.svg', 'dots_vertical.svg', 'image/svg+xml', 'global_icons/macos/dots_vertical.svg', TRUE, NULL, v_system_user_id),
        ('dots_vertical.png', 'dots_vertical.png', 'image/png', 'global_icons/windows/dots_vertical.png', TRUE, NULL, v_system_user_id),
        ('dots_vertical.svg', 'dots_vertical.svg', 'image/svg+xml', 'global_icons/linux/dots_vertical.svg', TRUE, NULL, v_system_user_id),
        ('arrow_up.svg', 'arrow_up.svg', 'image/svg+xml', 'global_icons/web/arrow_up.svg', TRUE, NULL, v_system_user_id),
        ('arrow_up.xml', 'arrow_up.xml', 'application/xml', 'global_icons/android/arrow_up.xml', TRUE, NULL, v_system_user_id),
        ('arrow_up.svg', 'arrow_up.svg', 'image/svg+xml', 'global_icons/ios/arrow_up.svg', TRUE, NULL, v_system_user_id),
        ('arrow_up.svg', 'arrow_up.svg', 'image/svg+xml', 'global_icons/macos/arrow_up.svg', TRUE, NULL, v_system_user_id),
        ('arrow_up.png', 'arrow_up.png', 'image/png', 'global_icons/windows/arrow_up.png', TRUE, NULL, v_system_user_id),
        ('arrow_up.svg', 'arrow_up.svg', 'image/svg+xml', 'global_icons/linux/arrow_up.svg', TRUE, NULL, v_system_user_id),
        ('arrow_down.svg', 'arrow_down.svg', 'image/svg+xml', 'global_icons/web/arrow_down.svg', TRUE, NULL, v_system_user_id),
        ('arrow_down.xml', 'arrow_down.xml', 'application/xml', 'global_icons/android/arrow_down.xml', TRUE, NULL, v_system_user_id),
        ('arrow_down.svg', 'arrow_down.svg', 'image/svg+xml', 'global_icons/ios/arrow_down.svg', TRUE, NULL, v_system_user_id),
        ('arrow_down.svg', 'arrow_down.svg', 'image/svg+xml', 'global_icons/macos/arrow_down.svg', TRUE, NULL, v_system_user_id),
        ('arrow_down.png', 'arrow_down.png', 'image/png', 'global_icons/windows/arrow_down.png', TRUE, NULL, v_system_user_id),
        ('arrow_down.svg', 'arrow_down.svg', 'image/svg+xml', 'global_icons/linux/arrow_down.svg', TRUE, NULL, v_system_user_id),
        ('arrow_left.svg', 'arrow_left.svg', 'image/svg+xml', 'global_icons/web/arrow_left.svg', TRUE, NULL, v_system_user_id),
        ('arrow_left.xml', 'arrow_left.xml', 'application/xml', 'global_icons/android/arrow_left.xml', TRUE, NULL, v_system_user_id),
        ('arrow_left.svg', 'arrow_left.svg', 'image/svg+xml', 'global_icons/ios/arrow_left.svg', TRUE, NULL, v_system_user_id),
        ('arrow_left.svg', 'arrow_left.svg', 'image/svg+xml', 'global_icons/macos/arrow_left.svg', TRUE, NULL, v_system_user_id),
        ('arrow_left.png', 'arrow_left.png', 'image/png', 'global_icons/windows/arrow_left.png', TRUE, NULL, v_system_user_id),
        ('arrow_left.svg', 'arrow_left.svg', 'image/svg+xml', 'global_icons/linux/arrow_left.svg', TRUE, NULL, v_system_user_id),
        ('arrow_right.svg', 'arrow_right.svg', 'image/svg+xml', 'global_icons/web/arrow_right.svg', TRUE, NULL, v_system_user_id),
        ('arrow_right.xml', 'arrow_right.xml', 'application/xml', 'global_icons/android/arrow_right.xml', TRUE, NULL, v_system_user_id),
        ('arrow_right.svg', 'arrow_right.svg', 'image/svg+xml', 'global_icons/ios/arrow_right.svg', TRUE, NULL, v_system_user_id),
        ('arrow_right.svg', 'arrow_right.svg', 'image/svg+xml', 'global_icons/macos/arrow_right.svg', TRUE, NULL, v_system_user_id),
        ('arrow_right.png', 'arrow_right.png', 'image/png', 'global_icons/windows/arrow_right.png', TRUE, NULL, v_system_user_id),
        ('arrow_right.svg', 'arrow_right.svg', 'image/svg+xml', 'global_icons/linux/arrow_right.svg', TRUE, NULL, v_system_user_id),
        ('chevron_up.svg', 'chevron_up.svg', 'image/svg+xml', 'global_icons/web/chevron_up.svg', TRUE, NULL, v_system_user_id),
        ('chevron_up.xml', 'chevron_up.xml', 'application/xml', 'global_icons/android/chevron_up.xml', TRUE, NULL, v_system_user_id),
        ('chevron_up.svg', 'chevron_up.svg', 'image/svg+xml', 'global_icons/ios/chevron_up.svg', TRUE, NULL, v_system_user_id),
        ('chevron_up.svg', 'chevron_up.svg', 'image/svg+xml', 'global_icons/macos/chevron_up.svg', TRUE, NULL, v_system_user_id),
        ('chevron_up.png', 'chevron_up.png', 'image/png', 'global_icons/windows/chevron_up.png', TRUE, NULL, v_system_user_id),
        ('chevron_up.svg', 'chevron_up.svg', 'image/svg+xml', 'global_icons/linux/chevron_up.svg', TRUE, NULL, v_system_user_id),
        ('chevron_down.svg', 'chevron_down.svg', 'image/svg+xml', 'global_icons/web/chevron_down.svg', TRUE, NULL, v_system_user_id),
        ('chevron_down.xml', 'chevron_down.xml', 'application/xml', 'global_icons/android/chevron_down.xml', TRUE, NULL, v_system_user_id),
        ('chevron_down.svg', 'chevron_down.svg', 'image/svg+xml', 'global_icons/ios/chevron_down.svg', TRUE, NULL, v_system_user_id),
        ('chevron_down.svg', 'chevron_down.svg', 'image/svg+xml', 'global_icons/macos/chevron_down.svg', TRUE, NULL, v_system_user_id),
        ('chevron_down.png', 'chevron_down.png', 'image/png', 'global_icons/windows/chevron_down.png', TRUE, NULL, v_system_user_id),
        ('chevron_down.svg', 'chevron_down.svg', 'image/svg+xml', 'global_icons/linux/chevron_down.svg', TRUE, NULL, v_system_user_id),
        ('external_link.svg', 'external_link.svg', 'image/svg+xml', 'global_icons/web/external_link.svg', TRUE, NULL, v_system_user_id),
        ('external_link.xml', 'external_link.xml', 'application/xml', 'global_icons/android/external_link.xml', TRUE, NULL, v_system_user_id),
        ('external_link.svg', 'external_link.svg', 'image/svg+xml', 'global_icons/ios/external_link.svg', TRUE, NULL, v_system_user_id),
        ('external_link.svg', 'external_link.svg', 'image/svg+xml', 'global_icons/macos/external_link.svg', TRUE, NULL, v_system_user_id),
        ('external_link.png', 'external_link.png', 'image/png', 'global_icons/windows/external_link.png', TRUE, NULL, v_system_user_id),
        ('external_link.svg', 'external_link.svg', 'image/svg+xml', 'global_icons/linux/external_link.svg', TRUE, NULL, v_system_user_id),
        ('attachment.svg', 'attachment.svg', 'image/svg+xml', 'global_icons/web/attachment.svg', TRUE, NULL, v_system_user_id),
        ('attachment.xml', 'attachment.xml', 'application/xml', 'global_icons/android/attachment.xml', TRUE, NULL, v_system_user_id),
        ('attachment.svg', 'attachment.svg', 'image/svg+xml', 'global_icons/ios/attachment.svg', TRUE, NULL, v_system_user_id),
        ('attachment.svg', 'attachment.svg', 'image/svg+xml', 'global_icons/macos/attachment.svg', TRUE, NULL, v_system_user_id),
        ('attachment.png', 'attachment.png', 'image/png', 'global_icons/windows/attachment.png', TRUE, NULL, v_system_user_id),
        ('attachment.svg', 'attachment.svg', 'image/svg+xml', 'global_icons/linux/attachment.svg', TRUE, NULL, v_system_user_id),
        ('archive.svg', 'archive.svg', 'image/svg+xml', 'global_icons/web/archive.svg', TRUE, NULL, v_system_user_id),
        ('archive.xml', 'archive.xml', 'application/xml', 'global_icons/android/archive.xml', TRUE, NULL, v_system_user_id),
        ('archive.svg', 'archive.svg', 'image/svg+xml', 'global_icons/ios/archive.svg', TRUE, NULL, v_system_user_id),
        ('archive.svg', 'archive.svg', 'image/svg+xml', 'global_icons/macos/archive.svg', TRUE, NULL, v_system_user_id),
        ('archive.png', 'archive.png', 'image/png', 'global_icons/windows/archive.png', TRUE, NULL, v_system_user_id),
        ('archive.svg', 'archive.svg', 'image/svg+xml', 'global_icons/linux/archive.svg', TRUE, NULL, v_system_user_id),
        ('trash.svg', 'trash.svg', 'image/svg+xml', 'global_icons/web/trash.svg', TRUE, NULL, v_system_user_id),
        ('trash.xml', 'trash.xml', 'application/xml', 'global_icons/android/trash.xml', TRUE, NULL, v_system_user_id),
        ('trash.svg', 'trash.svg', 'image/svg+xml', 'global_icons/ios/trash.svg', TRUE, NULL, v_system_user_id),
        ('trash.svg', 'trash.svg', 'image/svg+xml', 'global_icons/macos/trash.svg', TRUE, NULL, v_system_user_id),
        ('trash.png', 'trash.png', 'image/png', 'global_icons/windows/trash.png', TRUE, NULL, v_system_user_id),
        ('trash.svg', 'trash.svg', 'image/svg+xml', 'global_icons/linux/trash.svg', TRUE, NULL, v_system_user_id),
        ('undo.svg', 'undo.svg', 'image/svg+xml', 'global_icons/web/undo.svg', TRUE, NULL, v_system_user_id),
        ('undo.xml', 'undo.xml', 'application/xml', 'global_icons/android/undo.xml', TRUE, NULL, v_system_user_id),
        ('undo.svg', 'undo.svg', 'image/svg+xml', 'global_icons/ios/undo.svg', TRUE, NULL, v_system_user_id),
        ('undo.svg', 'undo.svg', 'image/svg+xml', 'global_icons/macos/undo.svg', TRUE, NULL, v_system_user_id),
        ('undo.png', 'undo.png', 'image/png', 'global_icons/windows/undo.png', TRUE, NULL, v_system_user_id),
        ('undo.svg', 'undo.svg', 'image/svg+xml', 'global_icons/linux/undo.svg', TRUE, NULL, v_system_user_id),
        ('redo.svg', 'redo.svg', 'image/svg+xml', 'global_icons/web/redo.svg', TRUE, NULL, v_system_user_id),
        ('redo.xml', 'redo.xml', 'application/xml', 'global_icons/android/redo.xml', TRUE, NULL, v_system_user_id),
        ('redo.svg', 'redo.svg', 'image/svg+xml', 'global_icons/ios/redo.svg', TRUE, NULL, v_system_user_id),
        ('redo.svg', 'redo.svg', 'image/svg+xml', 'global_icons/macos/redo.svg', TRUE, NULL, v_system_user_id),
        ('redo.png', 'redo.png', 'image/png', 'global_icons/windows/redo.png', TRUE, NULL, v_system_user_id),
        ('redo.svg', 'redo.svg', 'image/svg+xml', 'global_icons/linux/redo.svg', TRUE, NULL, v_system_user_id),
        ('bold.svg', 'bold.svg', 'image/svg+xml', 'global_icons/web/bold.svg', TRUE, NULL, v_system_user_id),
        ('bold.xml', 'bold.xml', 'application/xml', 'global_icons/android/bold.xml', TRUE, NULL, v_system_user_id),
        ('bold.svg', 'bold.svg', 'image/svg+xml', 'global_icons/ios/bold.svg', TRUE, NULL, v_system_user_id),
        ('bold.svg', 'bold.svg', 'image/svg+xml', 'global_icons/macos/bold.svg', TRUE, NULL, v_system_user_id),
        ('bold.png', 'bold.png', 'image/png', 'global_icons/windows/bold.png', TRUE, NULL, v_system_user_id),
        ('bold.svg', 'bold.svg', 'image/svg+xml', 'global_icons/linux/bold.svg', TRUE, NULL, v_system_user_id),
        ('italic.svg', 'italic.svg', 'image/svg+xml', 'global_icons/web/italic.svg', TRUE, NULL, v_system_user_id),
        ('italic.xml', 'italic.xml', 'application/xml', 'global_icons/android/italic.xml', TRUE, NULL, v_system_user_id),
        ('italic.svg', 'italic.svg', 'image/svg+xml', 'global_icons/ios/italic.svg', TRUE, NULL, v_system_user_id),
        ('italic.svg', 'italic.svg', 'image/svg+xml', 'global_icons/macos/italic.svg', TRUE, NULL, v_system_user_id),
        ('italic.png', 'italic.png', 'image/png', 'global_icons/windows/italic.png', TRUE, NULL, v_system_user_id),
        ('italic.svg', 'italic.svg', 'image/svg+xml', 'global_icons/linux/italic.svg', TRUE, NULL, v_system_user_id),
        ('code.svg', 'code.svg', 'image/svg+xml', 'global_icons/web/code.svg', TRUE, NULL, v_system_user_id),
        ('code.xml', 'code.xml', 'application/xml', 'global_icons/android/code.xml', TRUE, NULL, v_system_user_id),
        ('code.svg', 'code.svg', 'image/svg+xml', 'global_icons/ios/code.svg', TRUE, NULL, v_system_user_id),
        ('code.svg', 'code.svg', 'image/svg+xml', 'global_icons/macos/code.svg', TRUE, NULL, v_system_user_id),
        ('code.png', 'code.png', 'image/png', 'global_icons/windows/code.png', TRUE, NULL, v_system_user_id),
        ('code.svg', 'code.svg', 'image/svg+xml', 'global_icons/linux/code.svg', TRUE, NULL, v_system_user_id),
        ('globe.svg', 'globe.svg', 'image/svg+xml', 'global_icons/web/globe.svg', TRUE, NULL, v_system_user_id),
        ('globe.xml', 'globe.xml', 'application/xml', 'global_icons/android/globe.xml', TRUE, NULL, v_system_user_id),
        ('globe.svg', 'globe.svg', 'image/svg+xml', 'global_icons/ios/globe.svg', TRUE, NULL, v_system_user_id),
        ('globe.svg', 'globe.svg', 'image/svg+xml', 'global_icons/macos/globe.svg', TRUE, NULL, v_system_user_id),
        ('globe.png', 'globe.png', 'image/png', 'global_icons/windows/globe.png', TRUE, NULL, v_system_user_id),
        ('globe.svg', 'globe.svg', 'image/svg+xml', 'global_icons/linux/globe.svg', TRUE, NULL, v_system_user_id),
        ('cloud.svg', 'cloud.svg', 'image/svg+xml', 'global_icons/web/cloud.svg', TRUE, NULL, v_system_user_id),
        ('cloud.xml', 'cloud.xml', 'application/xml', 'global_icons/android/cloud.xml', TRUE, NULL, v_system_user_id),
        ('cloud.svg', 'cloud.svg', 'image/svg+xml', 'global_icons/ios/cloud.svg', TRUE, NULL, v_system_user_id),
        ('cloud.svg', 'cloud.svg', 'image/svg+xml', 'global_icons/macos/cloud.svg', TRUE, NULL, v_system_user_id),
        ('cloud.png', 'cloud.png', 'image/png', 'global_icons/windows/cloud.png', TRUE, NULL, v_system_user_id),
        ('cloud.svg', 'cloud.svg', 'image/svg+xml', 'global_icons/linux/cloud.svg', TRUE, NULL, v_system_user_id),
        ('database.svg', 'database.svg', 'image/svg+xml', 'global_icons/web/database.svg', TRUE, NULL, v_system_user_id),
        ('database.xml', 'database.xml', 'application/xml', 'global_icons/android/database.xml', TRUE, NULL, v_system_user_id),
        ('database.svg', 'database.svg', 'image/svg+xml', 'global_icons/ios/database.svg', TRUE, NULL, v_system_user_id),
        ('database.svg', 'database.svg', 'image/svg+xml', 'global_icons/macos/database.svg', TRUE, NULL, v_system_user_id),
        ('database.png', 'database.png', 'image/png', 'global_icons/windows/database.png', TRUE, NULL, v_system_user_id),
        ('database.svg', 'database.svg', 'image/svg+xml', 'global_icons/linux/database.svg', TRUE, NULL, v_system_user_id),
        ('server.svg', 'server.svg', 'image/svg+xml', 'global_icons/web/server.svg', TRUE, NULL, v_system_user_id),
        ('server.xml', 'server.xml', 'application/xml', 'global_icons/android/server.xml', TRUE, NULL, v_system_user_id),
        ('server.svg', 'server.svg', 'image/svg+xml', 'global_icons/ios/server.svg', TRUE, NULL, v_system_user_id),
        ('server.svg', 'server.svg', 'image/svg+xml', 'global_icons/macos/server.svg', TRUE, NULL, v_system_user_id),
        ('server.png', 'server.png', 'image/png', 'global_icons/windows/server.png', TRUE, NULL, v_system_user_id),
        ('server.svg', 'server.svg', 'image/svg+xml', 'global_icons/linux/server.svg', TRUE, NULL, v_system_user_id),
        ('shield.svg', 'shield.svg', 'image/svg+xml', 'global_icons/web/shield.svg', TRUE, NULL, v_system_user_id),
        ('shield.xml', 'shield.xml', 'application/xml', 'global_icons/android/shield.xml', TRUE, NULL, v_system_user_id),
        ('shield.svg', 'shield.svg', 'image/svg+xml', 'global_icons/ios/shield.svg', TRUE, NULL, v_system_user_id),
        ('shield.svg', 'shield.svg', 'image/svg+xml', 'global_icons/macos/shield.svg', TRUE, NULL, v_system_user_id),
        ('shield.png', 'shield.png', 'image/png', 'global_icons/windows/shield.png', TRUE, NULL, v_system_user_id),
        ('shield.svg', 'shield.svg', 'image/svg+xml', 'global_icons/linux/shield.svg', TRUE, NULL, v_system_user_id),
        ('wrench.svg', 'wrench.svg', 'image/svg+xml', 'global_icons/web/wrench.svg', TRUE, NULL, v_system_user_id),
        ('wrench.xml', 'wrench.xml', 'application/xml', 'global_icons/android/wrench.xml', TRUE, NULL, v_system_user_id),
        ('wrench.svg', 'wrench.svg', 'image/svg+xml', 'global_icons/ios/wrench.svg', TRUE, NULL, v_system_user_id),
        ('wrench.svg', 'wrench.svg', 'image/svg+xml', 'global_icons/macos/wrench.svg', TRUE, NULL, v_system_user_id),
        ('wrench.png', 'wrench.png', 'image/png', 'global_icons/windows/wrench.png', TRUE, NULL, v_system_user_id),
        ('wrench.svg', 'wrench.svg', 'image/svg+xml', 'global_icons/linux/wrench.svg', TRUE, NULL, v_system_user_id),
        ('tool.svg', 'tool.svg', 'image/svg+xml', 'global_icons/web/tool.svg', TRUE, NULL, v_system_user_id),
        ('tool.xml', 'tool.xml', 'application/xml', 'global_icons/android/tool.xml', TRUE, NULL, v_system_user_id),
        ('tool.svg', 'tool.svg', 'image/svg+xml', 'global_icons/ios/tool.svg', TRUE, NULL, v_system_user_id),
        ('tool.svg', 'tool.svg', 'image/svg+xml', 'global_icons/macos/tool.svg', TRUE, NULL, v_system_user_id),
        ('tool.png', 'tool.png', 'image/png', 'global_icons/windows/tool.png', TRUE, NULL, v_system_user_id),
        ('tool.svg', 'tool.svg', 'image/svg+xml', 'global_icons/linux/tool.svg', TRUE, NULL, v_system_user_id),
        ('sparkles.svg', 'sparkles.svg', 'image/svg+xml', 'global_icons/web/sparkles.svg', TRUE, NULL, v_system_user_id),
        ('sparkles.xml', 'sparkles.xml', 'application/xml', 'global_icons/android/sparkles.xml', TRUE, NULL, v_system_user_id),
        ('sparkles.svg', 'sparkles.svg', 'image/svg+xml', 'global_icons/ios/sparkles.svg', TRUE, NULL, v_system_user_id),
        ('sparkles.svg', 'sparkles.svg', 'image/svg+xml', 'global_icons/macos/sparkles.svg', TRUE, NULL, v_system_user_id),
        ('sparkles.png', 'sparkles.png', 'image/png', 'global_icons/windows/sparkles.png', TRUE, NULL, v_system_user_id),
        ('sparkles.svg', 'sparkles.svg', 'image/svg+xml', 'global_icons/linux/sparkles.svg', TRUE, NULL, v_system_user_id),
        ('robot.svg', 'robot.svg', 'image/svg+xml', 'global_icons/web/robot.svg', TRUE, NULL, v_system_user_id),
        ('robot.xml', 'robot.xml', 'application/xml', 'global_icons/android/robot.xml', TRUE, NULL, v_system_user_id),
        ('robot.svg', 'robot.svg', 'image/svg+xml', 'global_icons/ios/robot.svg', TRUE, NULL, v_system_user_id),
        ('robot.svg', 'robot.svg', 'image/svg+xml', 'global_icons/macos/robot.svg', TRUE, NULL, v_system_user_id),
        ('robot.png', 'robot.png', 'image/png', 'global_icons/windows/robot.png', TRUE, NULL, v_system_user_id),
        ('robot.svg', 'robot.svg', 'image/svg+xml', 'global_icons/linux/robot.svg', TRUE, NULL, v_system_user_id),
        ('chat.svg', 'chat.svg', 'image/svg+xml', 'global_icons/web/chat.svg', TRUE, NULL, v_system_user_id),
        ('chat.xml', 'chat.xml', 'application/xml', 'global_icons/android/chat.xml', TRUE, NULL, v_system_user_id),
        ('chat.svg', 'chat.svg', 'image/svg+xml', 'global_icons/ios/chat.svg', TRUE, NULL, v_system_user_id),
        ('chat.svg', 'chat.svg', 'image/svg+xml', 'global_icons/macos/chat.svg', TRUE, NULL, v_system_user_id),
        ('chat.png', 'chat.png', 'image/png', 'global_icons/windows/chat.png', TRUE, NULL, v_system_user_id),
        ('chat.svg', 'chat.svg', 'image/svg+xml', 'global_icons/linux/chat.svg', TRUE, NULL, v_system_user_id),
        ('message.svg', 'message.svg', 'image/svg+xml', 'global_icons/web/message.svg', TRUE, NULL, v_system_user_id),
        ('message.xml', 'message.xml', 'application/xml', 'global_icons/android/message.xml', TRUE, NULL, v_system_user_id),
        ('message.svg', 'message.svg', 'image/svg+xml', 'global_icons/ios/message.svg', TRUE, NULL, v_system_user_id),
        ('message.svg', 'message.svg', 'image/svg+xml', 'global_icons/macos/message.svg', TRUE, NULL, v_system_user_id),
        ('message.png', 'message.png', 'image/png', 'global_icons/windows/message.png', TRUE, NULL, v_system_user_id),
        ('message.svg', 'message.svg', 'image/svg+xml', 'global_icons/linux/message.svg', TRUE, NULL, v_system_user_id),
        ('team.svg', 'team.svg', 'image/svg+xml', 'global_icons/web/team.svg', TRUE, NULL, v_system_user_id),
        ('team.xml', 'team.xml', 'application/xml', 'global_icons/android/team.xml', TRUE, NULL, v_system_user_id),
        ('team.svg', 'team.svg', 'image/svg+xml', 'global_icons/ios/team.svg', TRUE, NULL, v_system_user_id),
        ('team.svg', 'team.svg', 'image/svg+xml', 'global_icons/macos/team.svg', TRUE, NULL, v_system_user_id),
        ('team.png', 'team.png', 'image/png', 'global_icons/windows/team.png', TRUE, NULL, v_system_user_id),
        ('team.svg', 'team.svg', 'image/svg+xml', 'global_icons/linux/team.svg', TRUE, NULL, v_system_user_id),
        ('building.svg', 'building.svg', 'image/svg+xml', 'global_icons/web/building.svg', TRUE, NULL, v_system_user_id),
        ('building.xml', 'building.xml', 'application/xml', 'global_icons/android/building.xml', TRUE, NULL, v_system_user_id),
        ('building.svg', 'building.svg', 'image/svg+xml', 'global_icons/ios/building.svg', TRUE, NULL, v_system_user_id),
        ('building.svg', 'building.svg', 'image/svg+xml', 'global_icons/macos/building.svg', TRUE, NULL, v_system_user_id),
        ('building.png', 'building.png', 'image/png', 'global_icons/windows/building.png', TRUE, NULL, v_system_user_id),
        ('building.svg', 'building.svg', 'image/svg+xml', 'global_icons/linux/building.svg', TRUE, NULL, v_system_user_id),
        ('truck.svg', 'truck.svg', 'image/svg+xml', 'global_icons/web/truck.svg', TRUE, NULL, v_system_user_id),
        ('truck.xml', 'truck.xml', 'application/xml', 'global_icons/android/truck.xml', TRUE, NULL, v_system_user_id),
        ('truck.svg', 'truck.svg', 'image/svg+xml', 'global_icons/ios/truck.svg', TRUE, NULL, v_system_user_id),
        ('truck.svg', 'truck.svg', 'image/svg+xml', 'global_icons/macos/truck.svg', TRUE, NULL, v_system_user_id),
        ('truck.png', 'truck.png', 'image/png', 'global_icons/windows/truck.png', TRUE, NULL, v_system_user_id),
        ('truck.svg', 'truck.svg', 'image/svg+xml', 'global_icons/linux/truck.svg', TRUE, NULL, v_system_user_id),
        ('plane.svg', 'plane.svg', 'image/svg+xml', 'global_icons/web/plane.svg', TRUE, NULL, v_system_user_id),
        ('plane.xml', 'plane.xml', 'application/xml', 'global_icons/android/plane.xml', TRUE, NULL, v_system_user_id),
        ('plane.svg', 'plane.svg', 'image/svg+xml', 'global_icons/ios/plane.svg', TRUE, NULL, v_system_user_id),
        ('plane.svg', 'plane.svg', 'image/svg+xml', 'global_icons/macos/plane.svg', TRUE, NULL, v_system_user_id),
        ('plane.png', 'plane.png', 'image/png', 'global_icons/windows/plane.png', TRUE, NULL, v_system_user_id),
        ('plane.svg', 'plane.svg', 'image/svg+xml', 'global_icons/linux/plane.svg', TRUE, NULL, v_system_user_id),
        ('car.svg', 'car.svg', 'image/svg+xml', 'global_icons/web/car.svg', TRUE, NULL, v_system_user_id),
        ('car.xml', 'car.xml', 'application/xml', 'global_icons/android/car.xml', TRUE, NULL, v_system_user_id),
        ('car.svg', 'car.svg', 'image/svg+xml', 'global_icons/ios/car.svg', TRUE, NULL, v_system_user_id),
        ('car.svg', 'car.svg', 'image/svg+xml', 'global_icons/macos/car.svg', TRUE, NULL, v_system_user_id),
        ('car.png', 'car.png', 'image/png', 'global_icons/windows/car.png', TRUE, NULL, v_system_user_id),
        ('car.svg', 'car.svg', 'image/svg+xml', 'global_icons/linux/car.svg', TRUE, NULL, v_system_user_id),
        ('coffee.svg', 'coffee.svg', 'image/svg+xml', 'global_icons/web/coffee.svg', TRUE, NULL, v_system_user_id),
        ('coffee.xml', 'coffee.xml', 'application/xml', 'global_icons/android/coffee.xml', TRUE, NULL, v_system_user_id),
        ('coffee.svg', 'coffee.svg', 'image/svg+xml', 'global_icons/ios/coffee.svg', TRUE, NULL, v_system_user_id),
        ('coffee.svg', 'coffee.svg', 'image/svg+xml', 'global_icons/macos/coffee.svg', TRUE, NULL, v_system_user_id),
        ('coffee.png', 'coffee.png', 'image/png', 'global_icons/windows/coffee.png', TRUE, NULL, v_system_user_id),
        ('coffee.svg', 'coffee.svg', 'image/svg+xml', 'global_icons/linux/coffee.svg', TRUE, NULL, v_system_user_id),
        ('sun.svg', 'sun.svg', 'image/svg+xml', 'global_icons/web/sun.svg', TRUE, NULL, v_system_user_id),
        ('sun.xml', 'sun.xml', 'application/xml', 'global_icons/android/sun.xml', TRUE, NULL, v_system_user_id),
        ('sun.svg', 'sun.svg', 'image/svg+xml', 'global_icons/ios/sun.svg', TRUE, NULL, v_system_user_id),
        ('sun.svg', 'sun.svg', 'image/svg+xml', 'global_icons/macos/sun.svg', TRUE, NULL, v_system_user_id),
        ('sun.png', 'sun.png', 'image/png', 'global_icons/windows/sun.png', TRUE, NULL, v_system_user_id),
        ('sun.svg', 'sun.svg', 'image/svg+xml', 'global_icons/linux/sun.svg', TRUE, NULL, v_system_user_id),
        ('moon.svg', 'moon.svg', 'image/svg+xml', 'global_icons/web/moon.svg', TRUE, NULL, v_system_user_id),
        ('moon.xml', 'moon.xml', 'application/xml', 'global_icons/android/moon.xml', TRUE, NULL, v_system_user_id),
        ('moon.svg', 'moon.svg', 'image/svg+xml', 'global_icons/ios/moon.svg', TRUE, NULL, v_system_user_id),
        ('moon.svg', 'moon.svg', 'image/svg+xml', 'global_icons/macos/moon.svg', TRUE, NULL, v_system_user_id),
        ('moon.png', 'moon.png', 'image/png', 'global_icons/windows/moon.png', TRUE, NULL, v_system_user_id),
        ('moon.svg', 'moon.svg', 'image/svg+xml', 'global_icons/linux/moon.svg', TRUE, NULL, v_system_user_id),
        ('language.svg', 'language.svg', 'image/svg+xml', 'global_icons/web/language.svg', TRUE, NULL, v_system_user_id),
        ('language.xml', 'language.xml', 'application/xml', 'global_icons/android/language.xml', TRUE, NULL, v_system_user_id),
        ('language.svg', 'language.svg', 'image/svg+xml', 'global_icons/ios/language.svg', TRUE, NULL, v_system_user_id),
        ('language.svg', 'language.svg', 'image/svg+xml', 'global_icons/macos/language.svg', TRUE, NULL, v_system_user_id),
        ('language.png', 'language.png', 'image/png', 'global_icons/windows/language.png', TRUE, NULL, v_system_user_id),
        ('language.svg', 'language.svg', 'image/svg+xml', 'global_icons/linux/language.svg', TRUE, NULL, v_system_user_id),
        ('log_in.svg', 'log_in.svg', 'image/svg+xml', 'global_icons/web/log_in.svg', TRUE, NULL, v_system_user_id),
        ('log_in.xml', 'log_in.xml', 'application/xml', 'global_icons/android/log_in.xml', TRUE, NULL, v_system_user_id),
        ('log_in.svg', 'log_in.svg', 'image/svg+xml', 'global_icons/ios/log_in.svg', TRUE, NULL, v_system_user_id),
        ('log_in.svg', 'log_in.svg', 'image/svg+xml', 'global_icons/macos/log_in.svg', TRUE, NULL, v_system_user_id),
        ('log_in.png', 'log_in.png', 'image/png', 'global_icons/windows/log_in.png', TRUE, NULL, v_system_user_id),
        ('log_in.svg', 'log_in.svg', 'image/svg+xml', 'global_icons/linux/log_in.svg', TRUE, NULL, v_system_user_id),
        ('log_out.svg', 'log_out.svg', 'image/svg+xml', 'global_icons/web/log_out.svg', TRUE, NULL, v_system_user_id),
        ('log_out.xml', 'log_out.xml', 'application/xml', 'global_icons/android/log_out.xml', TRUE, NULL, v_system_user_id),
        ('log_out.svg', 'log_out.svg', 'image/svg+xml', 'global_icons/ios/log_out.svg', TRUE, NULL, v_system_user_id),
        ('log_out.svg', 'log_out.svg', 'image/svg+xml', 'global_icons/macos/log_out.svg', TRUE, NULL, v_system_user_id),
        ('log_out.png', 'log_out.png', 'image/png', 'global_icons/windows/log_out.png', TRUE, NULL, v_system_user_id),
        ('log_out.svg', 'log_out.svg', 'image/svg+xml', 'global_icons/linux/log_out.svg', TRUE, NULL, v_system_user_id),
        ('profile.svg', 'profile.svg', 'image/svg+xml', 'global_icons/web/profile.svg', TRUE, NULL, v_system_user_id),
        ('profile.xml', 'profile.xml', 'application/xml', 'global_icons/android/profile.xml', TRUE, NULL, v_system_user_id),
        ('profile.svg', 'profile.svg', 'image/svg+xml', 'global_icons/ios/profile.svg', TRUE, NULL, v_system_user_id),
        ('profile.svg', 'profile.svg', 'image/svg+xml', 'global_icons/macos/profile.svg', TRUE, NULL, v_system_user_id),
        ('profile.png', 'profile.png', 'image/png', 'global_icons/windows/profile.png', TRUE, NULL, v_system_user_id),
        ('profile.svg', 'profile.svg', 'image/svg+xml', 'global_icons/linux/profile.svg', TRUE, NULL, v_system_user_id),
        ('notification.svg', 'notification.svg', 'image/svg+xml', 'global_icons/web/notification.svg', TRUE, NULL, v_system_user_id),
        ('notification.xml', 'notification.xml', 'application/xml', 'global_icons/android/notification.xml', TRUE, NULL, v_system_user_id),
        ('notification.svg', 'notification.svg', 'image/svg+xml', 'global_icons/ios/notification.svg', TRUE, NULL, v_system_user_id),
        ('notification.svg', 'notification.svg', 'image/svg+xml', 'global_icons/macos/notification.svg', TRUE, NULL, v_system_user_id),
        ('notification.png', 'notification.png', 'image/png', 'global_icons/windows/notification.png', TRUE, NULL, v_system_user_id),
        ('notification.svg', 'notification.svg', 'image/svg+xml', 'global_icons/linux/notification.svg', TRUE, NULL, v_system_user_id),
        ('dashboard.svg', 'dashboard.svg', 'image/svg+xml', 'global_icons/web/dashboard.svg', TRUE, NULL, v_system_user_id),
        ('dashboard.xml', 'dashboard.xml', 'application/xml', 'global_icons/android/dashboard.xml', TRUE, NULL, v_system_user_id),
        ('dashboard.svg', 'dashboard.svg', 'image/svg+xml', 'global_icons/ios/dashboard.svg', TRUE, NULL, v_system_user_id),
        ('dashboard.svg', 'dashboard.svg', 'image/svg+xml', 'global_icons/macos/dashboard.svg', TRUE, NULL, v_system_user_id),
        ('dashboard.png', 'dashboard.png', 'image/png', 'global_icons/windows/dashboard.png', TRUE, NULL, v_system_user_id),
        ('dashboard.svg', 'dashboard.svg', 'image/svg+xml', 'global_icons/linux/dashboard.svg', TRUE, NULL, v_system_user_id),
        ('activity.svg', 'activity.svg', 'image/svg+xml', 'global_icons/web/activity.svg', TRUE, NULL, v_system_user_id),
        ('activity.xml', 'activity.xml', 'application/xml', 'global_icons/android/activity.xml', TRUE, NULL, v_system_user_id),
        ('activity.svg', 'activity.svg', 'image/svg+xml', 'global_icons/ios/activity.svg', TRUE, NULL, v_system_user_id),
        ('activity.svg', 'activity.svg', 'image/svg+xml', 'global_icons/macos/activity.svg', TRUE, NULL, v_system_user_id),
        ('activity.png', 'activity.png', 'image/png', 'global_icons/windows/activity.png', TRUE, NULL, v_system_user_id),
        ('activity.svg', 'activity.svg', 'image/svg+xml', 'global_icons/linux/activity.svg', TRUE, NULL, v_system_user_id),
        ('layers.svg', 'layers.svg', 'image/svg+xml', 'global_icons/web/layers.svg', TRUE, NULL, v_system_user_id),
        ('layers.xml', 'layers.xml', 'application/xml', 'global_icons/android/layers.xml', TRUE, NULL, v_system_user_id),
        ('layers.svg', 'layers.svg', 'image/svg+xml', 'global_icons/ios/layers.svg', TRUE, NULL, v_system_user_id),
        ('layers.svg', 'layers.svg', 'image/svg+xml', 'global_icons/macos/layers.svg', TRUE, NULL, v_system_user_id),
        ('layers.png', 'layers.png', 'image/png', 'global_icons/windows/layers.png', TRUE, NULL, v_system_user_id),
        ('layers.svg', 'layers.svg', 'image/svg+xml', 'global_icons/linux/layers.svg', TRUE, NULL, v_system_user_id),
        ('compass.svg', 'compass.svg', 'image/svg+xml', 'global_icons/web/compass.svg', TRUE, NULL, v_system_user_id),
        ('compass.xml', 'compass.xml', 'application/xml', 'global_icons/android/compass.xml', TRUE, NULL, v_system_user_id),
        ('compass.svg', 'compass.svg', 'image/svg+xml', 'global_icons/ios/compass.svg', TRUE, NULL, v_system_user_id),
        ('compass.svg', 'compass.svg', 'image/svg+xml', 'global_icons/macos/compass.svg', TRUE, NULL, v_system_user_id),
        ('compass.png', 'compass.png', 'image/png', 'global_icons/windows/compass.png', TRUE, NULL, v_system_user_id),
        ('compass.svg', 'compass.svg', 'image/svg+xml', 'global_icons/linux/compass.svg', TRUE, NULL, v_system_user_id),
        ('target.svg', 'target.svg', 'image/svg+xml', 'global_icons/web/target.svg', TRUE, NULL, v_system_user_id),
        ('target.xml', 'target.xml', 'application/xml', 'global_icons/android/target.xml', TRUE, NULL, v_system_user_id),
        ('target.svg', 'target.svg', 'image/svg+xml', 'global_icons/ios/target.svg', TRUE, NULL, v_system_user_id),
        ('target.svg', 'target.svg', 'image/svg+xml', 'global_icons/macos/target.svg', TRUE, NULL, v_system_user_id),
        ('target.png', 'target.png', 'image/png', 'global_icons/windows/target.png', TRUE, NULL, v_system_user_id),
        ('target.svg', 'target.svg', 'image/svg+xml', 'global_icons/linux/target.svg', TRUE, NULL, v_system_user_id),
        ('award.svg', 'award.svg', 'image/svg+xml', 'global_icons/web/award.svg', TRUE, NULL, v_system_user_id),
        ('award.xml', 'award.xml', 'application/xml', 'global_icons/android/award.xml', TRUE, NULL, v_system_user_id),
        ('award.svg', 'award.svg', 'image/svg+xml', 'global_icons/ios/award.svg', TRUE, NULL, v_system_user_id),
        ('award.svg', 'award.svg', 'image/svg+xml', 'global_icons/macos/award.svg', TRUE, NULL, v_system_user_id),
        ('award.png', 'award.png', 'image/png', 'global_icons/windows/award.png', TRUE, NULL, v_system_user_id),
        ('award.svg', 'award.svg', 'image/svg+xml', 'global_icons/linux/award.svg', TRUE, NULL, v_system_user_id),
        ('gift.svg', 'gift.svg', 'image/svg+xml', 'global_icons/web/gift.svg', TRUE, NULL, v_system_user_id),
        ('gift.xml', 'gift.xml', 'application/xml', 'global_icons/android/gift.xml', TRUE, NULL, v_system_user_id),
        ('gift.svg', 'gift.svg', 'image/svg+xml', 'global_icons/ios/gift.svg', TRUE, NULL, v_system_user_id),
        ('gift.svg', 'gift.svg', 'image/svg+xml', 'global_icons/macos/gift.svg', TRUE, NULL, v_system_user_id),
        ('gift.png', 'gift.png', 'image/png', 'global_icons/windows/gift.png', TRUE, NULL, v_system_user_id),
        ('gift.svg', 'gift.svg', 'image/svg+xml', 'global_icons/linux/gift.svg', TRUE, NULL, v_system_user_id),
        ('megaphone.svg', 'megaphone.svg', 'image/svg+xml', 'global_icons/web/megaphone.svg', TRUE, NULL, v_system_user_id),
        ('megaphone.xml', 'megaphone.xml', 'application/xml', 'global_icons/android/megaphone.xml', TRUE, NULL, v_system_user_id),
        ('megaphone.svg', 'megaphone.svg', 'image/svg+xml', 'global_icons/ios/megaphone.svg', TRUE, NULL, v_system_user_id),
        ('megaphone.svg', 'megaphone.svg', 'image/svg+xml', 'global_icons/macos/megaphone.svg', TRUE, NULL, v_system_user_id),
        ('megaphone.png', 'megaphone.png', 'image/png', 'global_icons/windows/megaphone.png', TRUE, NULL, v_system_user_id),
        ('megaphone.svg', 'megaphone.svg', 'image/svg+xml', 'global_icons/linux/megaphone.svg', TRUE, NULL, v_system_user_id),
        ('puzzle.svg', 'puzzle.svg', 'image/svg+xml', 'global_icons/web/puzzle.svg', TRUE, NULL, v_system_user_id),
        ('puzzle.xml', 'puzzle.xml', 'application/xml', 'global_icons/android/puzzle.xml', TRUE, NULL, v_system_user_id),
        ('puzzle.svg', 'puzzle.svg', 'image/svg+xml', 'global_icons/ios/puzzle.svg', TRUE, NULL, v_system_user_id),
        ('puzzle.svg', 'puzzle.svg', 'image/svg+xml', 'global_icons/macos/puzzle.svg', TRUE, NULL, v_system_user_id),
        ('puzzle.png', 'puzzle.png', 'image/png', 'global_icons/windows/puzzle.png', TRUE, NULL, v_system_user_id),
        ('puzzle.svg', 'puzzle.svg', 'image/svg+xml', 'global_icons/linux/puzzle.svg', TRUE, NULL, v_system_user_id),
        ('brush.svg', 'brush.svg', 'image/svg+xml', 'global_icons/web/brush.svg', TRUE, NULL, v_system_user_id),
        ('brush.xml', 'brush.xml', 'application/xml', 'global_icons/android/brush.xml', TRUE, NULL, v_system_user_id),
        ('brush.svg', 'brush.svg', 'image/svg+xml', 'global_icons/ios/brush.svg', TRUE, NULL, v_system_user_id),
        ('brush.svg', 'brush.svg', 'image/svg+xml', 'global_icons/macos/brush.svg', TRUE, NULL, v_system_user_id),
        ('brush.png', 'brush.png', 'image/png', 'global_icons/windows/brush.png', TRUE, NULL, v_system_user_id),
        ('brush.svg', 'brush.svg', 'image/svg+xml', 'global_icons/linux/brush.svg', TRUE, NULL, v_system_user_id),
        ('crop.svg', 'crop.svg', 'image/svg+xml', 'global_icons/web/crop.svg', TRUE, NULL, v_system_user_id),
        ('crop.xml', 'crop.xml', 'application/xml', 'global_icons/android/crop.xml', TRUE, NULL, v_system_user_id),
        ('crop.svg', 'crop.svg', 'image/svg+xml', 'global_icons/ios/crop.svg', TRUE, NULL, v_system_user_id),
        ('crop.svg', 'crop.svg', 'image/svg+xml', 'global_icons/macos/crop.svg', TRUE, NULL, v_system_user_id),
        ('crop.png', 'crop.png', 'image/png', 'global_icons/windows/crop.png', TRUE, NULL, v_system_user_id),
        ('crop.svg', 'crop.svg', 'image/svg+xml', 'global_icons/linux/crop.svg', TRUE, NULL, v_system_user_id),
        ('adjust.svg', 'adjust.svg', 'image/svg+xml', 'global_icons/web/adjust.svg', TRUE, NULL, v_system_user_id),
        ('adjust.xml', 'adjust.xml', 'application/xml', 'global_icons/android/adjust.xml', TRUE, NULL, v_system_user_id),
        ('adjust.svg', 'adjust.svg', 'image/svg+xml', 'global_icons/ios/adjust.svg', TRUE, NULL, v_system_user_id),
        ('adjust.svg', 'adjust.svg', 'image/svg+xml', 'global_icons/macos/adjust.svg', TRUE, NULL, v_system_user_id),
        ('adjust.png', 'adjust.png', 'image/png', 'global_icons/windows/adjust.png', TRUE, NULL, v_system_user_id),
        ('adjust.svg', 'adjust.svg', 'image/svg+xml', 'global_icons/linux/adjust.svg', TRUE, NULL, v_system_user_id),
        ('zoom_in.svg', 'zoom_in.svg', 'image/svg+xml', 'global_icons/web/zoom_in.svg', TRUE, NULL, v_system_user_id),
        ('zoom_in.xml', 'zoom_in.xml', 'application/xml', 'global_icons/android/zoom_in.xml', TRUE, NULL, v_system_user_id),
        ('zoom_in.svg', 'zoom_in.svg', 'image/svg+xml', 'global_icons/ios/zoom_in.svg', TRUE, NULL, v_system_user_id),
        ('zoom_in.svg', 'zoom_in.svg', 'image/svg+xml', 'global_icons/macos/zoom_in.svg', TRUE, NULL, v_system_user_id),
        ('zoom_in.png', 'zoom_in.png', 'image/png', 'global_icons/windows/zoom_in.png', TRUE, NULL, v_system_user_id),
        ('zoom_in.svg', 'zoom_in.svg', 'image/svg+xml', 'global_icons/linux/zoom_in.svg', TRUE, NULL, v_system_user_id),
        ('zoom_out.svg', 'zoom_out.svg', 'image/svg+xml', 'global_icons/web/zoom_out.svg', TRUE, NULL, v_system_user_id),
        ('zoom_out.xml', 'zoom_out.xml', 'application/xml', 'global_icons/android/zoom_out.xml', TRUE, NULL, v_system_user_id),
        ('zoom_out.svg', 'zoom_out.svg', 'image/svg+xml', 'global_icons/ios/zoom_out.svg', TRUE, NULL, v_system_user_id),
        ('zoom_out.svg', 'zoom_out.svg', 'image/svg+xml', 'global_icons/macos/zoom_out.svg', TRUE, NULL, v_system_user_id),
        ('zoom_out.png', 'zoom_out.png', 'image/png', 'global_icons/windows/zoom_out.png', TRUE, NULL, v_system_user_id),
        ('zoom_out.svg', 'zoom_out.svg', 'image/svg+xml', 'global_icons/linux/zoom_out.svg', TRUE, NULL, v_system_user_id),
        ('inbox.svg', 'inbox.svg', 'image/svg+xml', 'global_icons/web/inbox.svg', TRUE, NULL, v_system_user_id),
        ('inbox.xml', 'inbox.xml', 'application/xml', 'global_icons/android/inbox.xml', TRUE, NULL, v_system_user_id),
        ('inbox.svg', 'inbox.svg', 'image/svg+xml', 'global_icons/ios/inbox.svg', TRUE, NULL, v_system_user_id),
        ('inbox.svg', 'inbox.svg', 'image/svg+xml', 'global_icons/macos/inbox.svg', TRUE, NULL, v_system_user_id),
        ('inbox.png', 'inbox.png', 'image/png', 'global_icons/windows/inbox.png', TRUE, NULL, v_system_user_id),
        ('inbox.svg', 'inbox.svg', 'image/svg+xml', 'global_icons/linux/inbox.svg', TRUE, NULL, v_system_user_id),
        ('send.svg', 'send.svg', 'image/svg+xml', 'global_icons/web/send.svg', TRUE, NULL, v_system_user_id),
        ('send.xml', 'send.xml', 'application/xml', 'global_icons/android/send.xml', TRUE, NULL, v_system_user_id),
        ('send.svg', 'send.svg', 'image/svg+xml', 'global_icons/ios/send.svg', TRUE, NULL, v_system_user_id),
        ('send.svg', 'send.svg', 'image/svg+xml', 'global_icons/macos/send.svg', TRUE, NULL, v_system_user_id),
        ('send.png', 'send.png', 'image/png', 'global_icons/windows/send.png', TRUE, NULL, v_system_user_id),
        ('send.svg', 'send.svg', 'image/svg+xml', 'global_icons/linux/send.svg', TRUE, NULL, v_system_user_id),
        ('reply.svg', 'reply.svg', 'image/svg+xml', 'global_icons/web/reply.svg', TRUE, NULL, v_system_user_id),
        ('reply.xml', 'reply.xml', 'application/xml', 'global_icons/android/reply.xml', TRUE, NULL, v_system_user_id),
        ('reply.svg', 'reply.svg', 'image/svg+xml', 'global_icons/ios/reply.svg', TRUE, NULL, v_system_user_id),
        ('reply.svg', 'reply.svg', 'image/svg+xml', 'global_icons/macos/reply.svg', TRUE, NULL, v_system_user_id),
        ('reply.png', 'reply.png', 'image/png', 'global_icons/windows/reply.png', TRUE, NULL, v_system_user_id),
        ('reply.svg', 'reply.svg', 'image/svg+xml', 'global_icons/linux/reply.svg', TRUE, NULL, v_system_user_id),
        ('forward_mail.svg', 'forward_mail.svg', 'image/svg+xml', 'global_icons/web/forward_mail.svg', TRUE, NULL, v_system_user_id),
        ('forward_mail.xml', 'forward_mail.xml', 'application/xml', 'global_icons/android/forward_mail.xml', TRUE, NULL, v_system_user_id),
        ('forward_mail.svg', 'forward_mail.svg', 'image/svg+xml', 'global_icons/ios/forward_mail.svg', TRUE, NULL, v_system_user_id),
        ('forward_mail.svg', 'forward_mail.svg', 'image/svg+xml', 'global_icons/macos/forward_mail.svg', TRUE, NULL, v_system_user_id),
        ('forward_mail.png', 'forward_mail.png', 'image/png', 'global_icons/windows/forward_mail.png', TRUE, NULL, v_system_user_id),
        ('forward_mail.svg', 'forward_mail.svg', 'image/svg+xml', 'global_icons/linux/forward_mail.svg', TRUE, NULL, v_system_user_id),
        ('folder_open.svg', 'folder_open.svg', 'image/svg+xml', 'global_icons/web/folder_open.svg', TRUE, NULL, v_system_user_id),
        ('folder_open.xml', 'folder_open.xml', 'application/xml', 'global_icons/android/folder_open.xml', TRUE, NULL, v_system_user_id),
        ('folder_open.svg', 'folder_open.svg', 'image/svg+xml', 'global_icons/ios/folder_open.svg', TRUE, NULL, v_system_user_id),
        ('folder_open.svg', 'folder_open.svg', 'image/svg+xml', 'global_icons/macos/folder_open.svg', TRUE, NULL, v_system_user_id),
        ('folder_open.png', 'folder_open.png', 'image/png', 'global_icons/windows/folder_open.png', TRUE, NULL, v_system_user_id),
        ('folder_open.svg', 'folder_open.svg', 'image/svg+xml', 'global_icons/linux/folder_open.svg', TRUE, NULL, v_system_user_id),
        ('note.svg', 'note.svg', 'image/svg+xml', 'global_icons/web/note.svg', TRUE, NULL, v_system_user_id),
        ('note.xml', 'note.xml', 'application/xml', 'global_icons/android/note.xml', TRUE, NULL, v_system_user_id),
        ('note.svg', 'note.svg', 'image/svg+xml', 'global_icons/ios/note.svg', TRUE, NULL, v_system_user_id),
        ('note.svg', 'note.svg', 'image/svg+xml', 'global_icons/macos/note.svg', TRUE, NULL, v_system_user_id),
        ('note.png', 'note.png', 'image/png', 'global_icons/windows/note.png', TRUE, NULL, v_system_user_id),
        ('note.svg', 'note.svg', 'image/svg+xml', 'global_icons/linux/note.svg', TRUE, NULL, v_system_user_id),
        ('pin.svg', 'pin.svg', 'image/svg+xml', 'global_icons/web/pin.svg', TRUE, NULL, v_system_user_id),
        ('pin.xml', 'pin.xml', 'application/xml', 'global_icons/android/pin.xml', TRUE, NULL, v_system_user_id),
        ('pin.svg', 'pin.svg', 'image/svg+xml', 'global_icons/ios/pin.svg', TRUE, NULL, v_system_user_id),
        ('pin.svg', 'pin.svg', 'image/svg+xml', 'global_icons/macos/pin.svg', TRUE, NULL, v_system_user_id),
        ('pin.png', 'pin.png', 'image/png', 'global_icons/windows/pin.png', TRUE, NULL, v_system_user_id),
        ('pin.svg', 'pin.svg', 'image/svg+xml', 'global_icons/linux/pin.svg', TRUE, NULL, v_system_user_id),
        ('unpin.svg', 'unpin.svg', 'image/svg+xml', 'global_icons/web/unpin.svg', TRUE, NULL, v_system_user_id),
        ('unpin.xml', 'unpin.xml', 'application/xml', 'global_icons/android/unpin.xml', TRUE, NULL, v_system_user_id),
        ('unpin.svg', 'unpin.svg', 'image/svg+xml', 'global_icons/ios/unpin.svg', TRUE, NULL, v_system_user_id),
        ('unpin.svg', 'unpin.svg', 'image/svg+xml', 'global_icons/macos/unpin.svg', TRUE, NULL, v_system_user_id),
        ('unpin.png', 'unpin.png', 'image/png', 'global_icons/windows/unpin.png', TRUE, NULL, v_system_user_id),
        ('unpin.svg', 'unpin.svg', 'image/svg+xml', 'global_icons/linux/unpin.svg', TRUE, NULL, v_system_user_id),
        ('history.svg', 'history.svg', 'image/svg+xml', 'global_icons/web/history.svg', TRUE, NULL, v_system_user_id),
        ('history.xml', 'history.xml', 'application/xml', 'global_icons/android/history.xml', TRUE, NULL, v_system_user_id),
        ('history.svg', 'history.svg', 'image/svg+xml', 'global_icons/ios/history.svg', TRUE, NULL, v_system_user_id),
        ('history.svg', 'history.svg', 'image/svg+xml', 'global_icons/macos/history.svg', TRUE, NULL, v_system_user_id),
        ('history.png', 'history.png', 'image/png', 'global_icons/windows/history.png', TRUE, NULL, v_system_user_id),
        ('history.svg', 'history.svg', 'image/svg+xml', 'global_icons/linux/history.svg', TRUE, NULL, v_system_user_id),
        ('sync.svg', 'sync.svg', 'image/svg+xml', 'global_icons/web/sync.svg', TRUE, NULL, v_system_user_id),
        ('sync.xml', 'sync.xml', 'application/xml', 'global_icons/android/sync.xml', TRUE, NULL, v_system_user_id),
        ('sync.svg', 'sync.svg', 'image/svg+xml', 'global_icons/ios/sync.svg', TRUE, NULL, v_system_user_id),
        ('sync.svg', 'sync.svg', 'image/svg+xml', 'global_icons/macos/sync.svg', TRUE, NULL, v_system_user_id),
        ('sync.png', 'sync.png', 'image/png', 'global_icons/windows/sync.png', TRUE, NULL, v_system_user_id),
        ('sync.svg', 'sync.svg', 'image/svg+xml', 'global_icons/linux/sync.svg', TRUE, NULL, v_system_user_id),
        ('import_icon.svg', 'import_icon.svg', 'image/svg+xml', 'global_icons/web/import_icon.svg', TRUE, NULL, v_system_user_id),
        ('import_icon.xml', 'import_icon.xml', 'application/xml', 'global_icons/android/import_icon.xml', TRUE, NULL, v_system_user_id),
        ('import_icon.svg', 'import_icon.svg', 'image/svg+xml', 'global_icons/ios/import_icon.svg', TRUE, NULL, v_system_user_id),
        ('import_icon.svg', 'import_icon.svg', 'image/svg+xml', 'global_icons/macos/import_icon.svg', TRUE, NULL, v_system_user_id),
        ('import_icon.png', 'import_icon.png', 'image/png', 'global_icons/windows/import_icon.png', TRUE, NULL, v_system_user_id),
        ('import_icon.svg', 'import_icon.svg', 'image/svg+xml', 'global_icons/linux/import_icon.svg', TRUE, NULL, v_system_user_id),
        ('export_icon.svg', 'export_icon.svg', 'image/svg+xml', 'global_icons/web/export_icon.svg', TRUE, NULL, v_system_user_id),
        ('export_icon.xml', 'export_icon.xml', 'application/xml', 'global_icons/android/export_icon.xml', TRUE, NULL, v_system_user_id),
        ('export_icon.svg', 'export_icon.svg', 'image/svg+xml', 'global_icons/ios/export_icon.svg', TRUE, NULL, v_system_user_id),
        ('export_icon.svg', 'export_icon.svg', 'image/svg+xml', 'global_icons/macos/export_icon.svg', TRUE, NULL, v_system_user_id),
        ('export_icon.png', 'export_icon.png', 'image/png', 'global_icons/windows/export_icon.png', TRUE, NULL, v_system_user_id),
        ('export_icon.svg', 'export_icon.svg', 'image/svg+xml', 'global_icons/linux/export_icon.svg', TRUE, NULL, v_system_user_id),
        ('template.svg', 'template.svg', 'image/svg+xml', 'global_icons/web/template.svg', TRUE, NULL, v_system_user_id),
        ('template.xml', 'template.xml', 'application/xml', 'global_icons/android/template.xml', TRUE, NULL, v_system_user_id),
        ('template.svg', 'template.svg', 'image/svg+xml', 'global_icons/ios/template.svg', TRUE, NULL, v_system_user_id),
        ('template.svg', 'template.svg', 'image/svg+xml', 'global_icons/macos/template.svg', TRUE, NULL, v_system_user_id),
        ('template.png', 'template.png', 'image/png', 'global_icons/windows/template.png', TRUE, NULL, v_system_user_id),
        ('template.svg', 'template.svg', 'image/svg+xml', 'global_icons/linux/template.svg', TRUE, NULL, v_system_user_id),
        ('workflow.svg', 'workflow.svg', 'image/svg+xml', 'global_icons/web/workflow.svg', TRUE, NULL, v_system_user_id),
        ('workflow.xml', 'workflow.xml', 'application/xml', 'global_icons/android/workflow.xml', TRUE, NULL, v_system_user_id),
        ('workflow.svg', 'workflow.svg', 'image/svg+xml', 'global_icons/ios/workflow.svg', TRUE, NULL, v_system_user_id),
        ('workflow.svg', 'workflow.svg', 'image/svg+xml', 'global_icons/macos/workflow.svg', TRUE, NULL, v_system_user_id),
        ('workflow.png', 'workflow.png', 'image/png', 'global_icons/windows/workflow.png', TRUE, NULL, v_system_user_id),
        ('workflow.svg', 'workflow.svg', 'image/svg+xml', 'global_icons/linux/workflow.svg', TRUE, NULL, v_system_user_id),
        ('api.svg', 'api.svg', 'image/svg+xml', 'global_icons/web/api.svg', TRUE, NULL, v_system_user_id),
        ('api.xml', 'api.xml', 'application/xml', 'global_icons/android/api.xml', TRUE, NULL, v_system_user_id),
        ('api.svg', 'api.svg', 'image/svg+xml', 'global_icons/ios/api.svg', TRUE, NULL, v_system_user_id),
        ('api.svg', 'api.svg', 'image/svg+xml', 'global_icons/macos/api.svg', TRUE, NULL, v_system_user_id),
        ('api.png', 'api.png', 'image/png', 'global_icons/windows/api.png', TRUE, NULL, v_system_user_id),
        ('api.svg', 'api.svg', 'image/svg+xml', 'global_icons/linux/api.svg', TRUE, NULL, v_system_user_id),
        ('webhook.svg', 'webhook.svg', 'image/svg+xml', 'global_icons/web/webhook.svg', TRUE, NULL, v_system_user_id),
        ('webhook.xml', 'webhook.xml', 'application/xml', 'global_icons/android/webhook.xml', TRUE, NULL, v_system_user_id),
        ('webhook.svg', 'webhook.svg', 'image/svg+xml', 'global_icons/ios/webhook.svg', TRUE, NULL, v_system_user_id),
        ('webhook.svg', 'webhook.svg', 'image/svg+xml', 'global_icons/macos/webhook.svg', TRUE, NULL, v_system_user_id),
        ('webhook.png', 'webhook.png', 'image/png', 'global_icons/windows/webhook.png', TRUE, NULL, v_system_user_id),
        ('webhook.svg', 'webhook.svg', 'image/svg+xml', 'global_icons/linux/webhook.svg', TRUE, NULL, v_system_user_id),
        ('terminal.svg', 'terminal.svg', 'image/svg+xml', 'global_icons/web/terminal.svg', TRUE, NULL, v_system_user_id),
        ('terminal.xml', 'terminal.xml', 'application/xml', 'global_icons/android/terminal.xml', TRUE, NULL, v_system_user_id),
        ('terminal.svg', 'terminal.svg', 'image/svg+xml', 'global_icons/ios/terminal.svg', TRUE, NULL, v_system_user_id),
        ('terminal.svg', 'terminal.svg', 'image/svg+xml', 'global_icons/macos/terminal.svg', TRUE, NULL, v_system_user_id),
        ('terminal.png', 'terminal.png', 'image/png', 'global_icons/windows/terminal.png', TRUE, NULL, v_system_user_id),
        ('terminal.svg', 'terminal.svg', 'image/svg+xml', 'global_icons/linux/terminal.svg', TRUE, NULL, v_system_user_id)
    ) AS t(file_name, original_name, mime_type, storage_path, is_public, company_id, uploaded_by)
    WHERE NOT EXISTS (
        SELECT 1 FROM public.assets a WHERE a.storage_path = t.storage_path AND a.company_id IS NULL
    );
END $$;


-- Generated by scripts/generate_global_icon_assets.py (do not hand-edit)
INSERT INTO public.global_icons (
    icon_key, icon_path_web, icon_path_android, icon_path_ios, icon_path_macos,
    icon_path_windows, icon_path_linux, description, keywords
) VALUES
    ('home', 'public/global_icons/web/home.svg', 'public/global_icons/android/home.xml', 'public/global_icons/ios/home.svg', 'public/global_icons/macos/home.svg', 'public/global_icons/windows/home.png', 'public/global_icons/linux/home.svg', 'Home — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: home.', ARRAY['global','home','icon','noolva','ui']::text[]),
    ('user', 'public/global_icons/web/user.svg', 'public/global_icons/android/user.xml', 'public/global_icons/ios/user.svg', 'public/global_icons/macos/user.svg', 'public/global_icons/windows/user.png', 'public/global_icons/linux/user.svg', 'User — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: user.', ARRAY['global','icon','noolva','ui','user']::text[]),
    ('users', 'public/global_icons/web/users.svg', 'public/global_icons/android/users.xml', 'public/global_icons/ios/users.svg', 'public/global_icons/macos/users.svg', 'public/global_icons/windows/users.png', 'public/global_icons/linux/users.svg', 'Users — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: users.', ARRAY['global','icon','noolva','ui','users']::text[]),
    ('settings', 'public/global_icons/web/settings.svg', 'public/global_icons/android/settings.xml', 'public/global_icons/ios/settings.svg', 'public/global_icons/macos/settings.svg', 'public/global_icons/windows/settings.png', 'public/global_icons/linux/settings.svg', 'Settings — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: settings.', ARRAY['global','icon','noolva','settings','ui']::text[]),
    ('search', 'public/global_icons/web/search.svg', 'public/global_icons/android/search.xml', 'public/global_icons/ios/search.svg', 'public/global_icons/macos/search.svg', 'public/global_icons/windows/search.png', 'public/global_icons/linux/search.svg', 'Search — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: search.', ARRAY['global','icon','noolva','search','ui']::text[]),
    ('menu', 'public/global_icons/web/menu.svg', 'public/global_icons/android/menu.xml', 'public/global_icons/ios/menu.svg', 'public/global_icons/macos/menu.svg', 'public/global_icons/windows/menu.png', 'public/global_icons/linux/menu.svg', 'Menu — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: menu.', ARRAY['global','icon','menu','noolva','ui']::text[]),
    ('close', 'public/global_icons/web/close.svg', 'public/global_icons/android/close.xml', 'public/global_icons/ios/close.svg', 'public/global_icons/macos/close.svg', 'public/global_icons/windows/close.png', 'public/global_icons/linux/close.svg', 'Close — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: close.', ARRAY['close','global','icon','noolva','ui']::text[]),
    ('add', 'public/global_icons/web/add.svg', 'public/global_icons/android/add.xml', 'public/global_icons/ios/add.svg', 'public/global_icons/macos/add.svg', 'public/global_icons/windows/add.png', 'public/global_icons/linux/add.svg', 'Add — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: plus.', ARRAY['add','global','icon','noolva','plus','ui']::text[]),
    ('edit', 'public/global_icons/web/edit.svg', 'public/global_icons/android/edit.xml', 'public/global_icons/ios/edit.svg', 'public/global_icons/macos/edit.svg', 'public/global_icons/windows/edit.png', 'public/global_icons/linux/edit.svg', 'Edit — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: edit.', ARRAY['edit','global','icon','noolva','ui']::text[]),
    ('delete', 'public/global_icons/web/delete.svg', 'public/global_icons/android/delete.xml', 'public/global_icons/ios/delete.svg', 'public/global_icons/macos/delete.svg', 'public/global_icons/windows/delete.png', 'public/global_icons/linux/delete.svg', 'Delete — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: delete.', ARRAY['delete','global','icon','noolva','ui']::text[]),
    ('save', 'public/global_icons/web/save.svg', 'public/global_icons/android/save.xml', 'public/global_icons/ios/save.svg', 'public/global_icons/macos/save.svg', 'public/global_icons/windows/save.png', 'public/global_icons/linux/save.svg', 'Save — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: check.', ARRAY['check','global','icon','noolva','save','ui']::text[]),
    ('cancel', 'public/global_icons/web/cancel.svg', 'public/global_icons/android/cancel.xml', 'public/global_icons/ios/cancel.svg', 'public/global_icons/macos/cancel.svg', 'public/global_icons/windows/cancel.png', 'public/global_icons/linux/cancel.svg', 'Cancel — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: close.', ARRAY['cancel','close','global','icon','noolva','ui']::text[]),
    ('check', 'public/global_icons/web/check.svg', 'public/global_icons/android/check.xml', 'public/global_icons/ios/check.svg', 'public/global_icons/macos/check.svg', 'public/global_icons/windows/check.png', 'public/global_icons/linux/check.svg', 'Check — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: check.', ARRAY['check','global','icon','noolva','ui']::text[]),
    ('back', 'public/global_icons/web/back.svg', 'public/global_icons/android/back.xml', 'public/global_icons/ios/back.svg', 'public/global_icons/macos/back.svg', 'public/global_icons/windows/back.png', 'public/global_icons/linux/back.svg', 'Back — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: arrow_left.', ARRAY['arrow_left','back','global','icon','noolva','ui']::text[]),
    ('forward', 'public/global_icons/web/forward.svg', 'public/global_icons/android/forward.xml', 'public/global_icons/ios/forward.svg', 'public/global_icons/macos/forward.svg', 'public/global_icons/windows/forward.png', 'public/global_icons/linux/forward.svg', 'Forward — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: arrow_right.', ARRAY['arrow_right','forward','global','icon','noolva','ui']::text[]),
    ('refresh', 'public/global_icons/web/refresh.svg', 'public/global_icons/android/refresh.xml', 'public/global_icons/ios/refresh.svg', 'public/global_icons/macos/refresh.svg', 'public/global_icons/windows/refresh.png', 'public/global_icons/linux/refresh.svg', 'Refresh — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: refresh.', ARRAY['global','icon','noolva','refresh','ui']::text[]),
    ('download', 'public/global_icons/web/download.svg', 'public/global_icons/android/download.xml', 'public/global_icons/ios/download.svg', 'public/global_icons/macos/download.svg', 'public/global_icons/windows/download.png', 'public/global_icons/linux/download.svg', 'Download — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: download.', ARRAY['download','global','icon','noolva','ui']::text[]),
    ('upload', 'public/global_icons/web/upload.svg', 'public/global_icons/android/upload.xml', 'public/global_icons/ios/upload.svg', 'public/global_icons/macos/upload.svg', 'public/global_icons/windows/upload.png', 'public/global_icons/linux/upload.svg', 'Upload — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: upload.', ARRAY['global','icon','noolva','ui','upload']::text[]),
    ('share', 'public/global_icons/web/share.svg', 'public/global_icons/android/share.xml', 'public/global_icons/ios/share.svg', 'public/global_icons/macos/share.svg', 'public/global_icons/windows/share.png', 'public/global_icons/linux/share.svg', 'Share — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: share.', ARRAY['global','icon','noolva','share','ui']::text[]),
    ('link', 'public/global_icons/web/link.svg', 'public/global_icons/android/link.xml', 'public/global_icons/ios/link.svg', 'public/global_icons/macos/link.svg', 'public/global_icons/windows/link.png', 'public/global_icons/linux/link.svg', 'Link — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: link.', ARRAY['global','icon','link','noolva','ui']::text[]),
    ('copy', 'public/global_icons/web/copy.svg', 'public/global_icons/android/copy.xml', 'public/global_icons/ios/copy.svg', 'public/global_icons/macos/copy.svg', 'public/global_icons/windows/copy.png', 'public/global_icons/linux/copy.svg', 'Copy — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: file.', ARRAY['copy','file','global','icon','noolva','ui']::text[]),
    ('filter', 'public/global_icons/web/filter.svg', 'public/global_icons/android/filter.xml', 'public/global_icons/ios/filter.svg', 'public/global_icons/macos/filter.svg', 'public/global_icons/windows/filter.png', 'public/global_icons/linux/filter.svg', 'Filter — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: search.', ARRAY['filter','global','icon','noolva','search','ui']::text[]),
    ('sort', 'public/global_icons/web/sort.svg', 'public/global_icons/android/sort.xml', 'public/global_icons/ios/sort.svg', 'public/global_icons/macos/sort.svg', 'public/global_icons/windows/sort.png', 'public/global_icons/linux/sort.svg', 'Sort — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: list.', ARRAY['global','icon','list','noolva','sort','ui']::text[]),
    ('calendar', 'public/global_icons/web/calendar.svg', 'public/global_icons/android/calendar.xml', 'public/global_icons/ios/calendar.svg', 'public/global_icons/macos/calendar.svg', 'public/global_icons/windows/calendar.png', 'public/global_icons/linux/calendar.svg', 'Calendar — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: calendar.', ARRAY['calendar','global','icon','noolva','ui']::text[]),
    ('clock', 'public/global_icons/web/clock.svg', 'public/global_icons/android/clock.xml', 'public/global_icons/ios/clock.svg', 'public/global_icons/macos/clock.svg', 'public/global_icons/windows/clock.png', 'public/global_icons/linux/clock.svg', 'Clock — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: clock.', ARRAY['clock','global','icon','noolva','ui']::text[]),
    ('mail', 'public/global_icons/web/mail.svg', 'public/global_icons/android/mail.xml', 'public/global_icons/ios/mail.svg', 'public/global_icons/macos/mail.svg', 'public/global_icons/windows/mail.png', 'public/global_icons/linux/mail.svg', 'Mail — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: mail.', ARRAY['global','icon','mail','noolva','ui']::text[]),
    ('phone', 'public/global_icons/web/phone.svg', 'public/global_icons/android/phone.xml', 'public/global_icons/ios/phone.svg', 'public/global_icons/macos/phone.svg', 'public/global_icons/windows/phone.png', 'public/global_icons/linux/phone.svg', 'Phone — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: phone.', ARRAY['global','icon','noolva','phone','ui']::text[]),
    ('map', 'public/global_icons/web/map.svg', 'public/global_icons/android/map.xml', 'public/global_icons/ios/map.svg', 'public/global_icons/macos/map.svg', 'public/global_icons/windows/map.png', 'public/global_icons/linux/map.svg', 'Map — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: map.', ARRAY['global','icon','map','noolva','ui']::text[]),
    ('location', 'public/global_icons/web/location.svg', 'public/global_icons/android/location.xml', 'public/global_icons/ios/location.svg', 'public/global_icons/macos/location.svg', 'public/global_icons/windows/location.png', 'public/global_icons/linux/location.svg', 'Location — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: map.', ARRAY['global','icon','location','map','noolva','ui']::text[]),
    ('camera', 'public/global_icons/web/camera.svg', 'public/global_icons/android/camera.xml', 'public/global_icons/ios/camera.svg', 'public/global_icons/macos/camera.svg', 'public/global_icons/windows/camera.png', 'public/global_icons/linux/camera.svg', 'Camera — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: camera.', ARRAY['camera','global','icon','noolva','ui']::text[]),
    ('image', 'public/global_icons/web/image.svg', 'public/global_icons/android/image.xml', 'public/global_icons/ios/image.svg', 'public/global_icons/macos/image.svg', 'public/global_icons/windows/image.png', 'public/global_icons/linux/image.svg', 'Image — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: image.', ARRAY['global','icon','image','noolva','ui']::text[]),
    ('file', 'public/global_icons/web/file.svg', 'public/global_icons/android/file.xml', 'public/global_icons/ios/file.svg', 'public/global_icons/macos/file.svg', 'public/global_icons/windows/file.png', 'public/global_icons/linux/file.svg', 'File — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: file.', ARRAY['file','global','icon','noolva','ui']::text[]),
    ('folder', 'public/global_icons/web/folder.svg', 'public/global_icons/android/folder.xml', 'public/global_icons/ios/folder.svg', 'public/global_icons/macos/folder.svg', 'public/global_icons/windows/folder.png', 'public/global_icons/linux/folder.svg', 'Folder — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: folder.', ARRAY['folder','global','icon','noolva','ui']::text[]),
    ('document', 'public/global_icons/web/document.svg', 'public/global_icons/android/document.xml', 'public/global_icons/ios/document.svg', 'public/global_icons/macos/document.svg', 'public/global_icons/windows/document.png', 'public/global_icons/linux/document.svg', 'Document — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: file.', ARRAY['document','file','global','icon','noolva','ui']::text[]),
    ('print', 'public/global_icons/web/print.svg', 'public/global_icons/android/print.xml', 'public/global_icons/ios/print.svg', 'public/global_icons/macos/print.svg', 'public/global_icons/windows/print.png', 'public/global_icons/linux/print.svg', 'Print — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: file.', ARRAY['file','global','icon','noolva','print','ui']::text[]),
    ('lock', 'public/global_icons/web/lock.svg', 'public/global_icons/android/lock.xml', 'public/global_icons/ios/lock.svg', 'public/global_icons/macos/lock.svg', 'public/global_icons/windows/lock.png', 'public/global_icons/linux/lock.svg', 'Lock — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: lock.', ARRAY['global','icon','lock','noolva','ui']::text[]),
    ('unlock', 'public/global_icons/web/unlock.svg', 'public/global_icons/android/unlock.xml', 'public/global_icons/ios/unlock.svg', 'public/global_icons/macos/unlock.svg', 'public/global_icons/windows/unlock.png', 'public/global_icons/linux/unlock.svg', 'Unlock — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: unlock.', ARRAY['global','icon','noolva','ui','unlock']::text[]),
    ('key', 'public/global_icons/web/key.svg', 'public/global_icons/android/key.xml', 'public/global_icons/ios/key.svg', 'public/global_icons/macos/key.svg', 'public/global_icons/windows/key.png', 'public/global_icons/linux/key.svg', 'Key — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: lock.', ARRAY['global','icon','key','lock','noolva','ui']::text[]),
    ('star', 'public/global_icons/web/star.svg', 'public/global_icons/android/star.xml', 'public/global_icons/ios/star.svg', 'public/global_icons/macos/star.svg', 'public/global_icons/windows/star.png', 'public/global_icons/linux/star.svg', 'Star — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: star.', ARRAY['global','icon','noolva','star','ui']::text[]),
    ('heart', 'public/global_icons/web/heart.svg', 'public/global_icons/android/heart.xml', 'public/global_icons/ios/heart.svg', 'public/global_icons/macos/heart.svg', 'public/global_icons/windows/heart.png', 'public/global_icons/linux/heart.svg', 'Heart — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: heart.', ARRAY['global','heart','icon','noolva','ui']::text[]),
    ('bell', 'public/global_icons/web/bell.svg', 'public/global_icons/android/bell.xml', 'public/global_icons/ios/bell.svg', 'public/global_icons/macos/bell.svg', 'public/global_icons/windows/bell.png', 'public/global_icons/linux/bell.svg', 'Bell — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: bell.', ARRAY['bell','global','icon','noolva','ui']::text[]),
    ('flag', 'public/global_icons/web/flag.svg', 'public/global_icons/android/flag.xml', 'public/global_icons/ios/flag.svg', 'public/global_icons/macos/flag.svg', 'public/global_icons/windows/flag.png', 'public/global_icons/linux/flag.svg', 'Flag — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: warning.', ARRAY['flag','global','icon','noolva','ui','warning']::text[]),
    ('bookmark', 'public/global_icons/web/bookmark.svg', 'public/global_icons/android/bookmark.xml', 'public/global_icons/ios/bookmark.svg', 'public/global_icons/macos/bookmark.svg', 'public/global_icons/windows/bookmark.png', 'public/global_icons/linux/bookmark.svg', 'Bookmark — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: star.', ARRAY['bookmark','global','icon','noolva','star','ui']::text[]),
    ('tag', 'public/global_icons/web/tag.svg', 'public/global_icons/android/tag.xml', 'public/global_icons/ios/tag.svg', 'public/global_icons/macos/tag.svg', 'public/global_icons/windows/tag.png', 'public/global_icons/linux/tag.svg', 'Tag — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: circle.', ARRAY['circle','global','icon','noolva','tag','ui']::text[]),
    ('cart', 'public/global_icons/web/cart.svg', 'public/global_icons/android/cart.xml', 'public/global_icons/ios/cart.svg', 'public/global_icons/macos/cart.svg', 'public/global_icons/windows/cart.png', 'public/global_icons/linux/cart.svg', 'Cart — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: cart.', ARRAY['cart','global','icon','noolva','ui']::text[]),
    ('shop', 'public/global_icons/web/shop.svg', 'public/global_icons/android/shop.xml', 'public/global_icons/ios/shop.svg', 'public/global_icons/macos/shop.svg', 'public/global_icons/windows/shop.png', 'public/global_icons/linux/shop.svg', 'Shop — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: cart.', ARRAY['cart','global','icon','noolva','shop','ui']::text[]),
    ('credit_card', 'public/global_icons/web/credit_card.svg', 'public/global_icons/android/credit_card.xml', 'public/global_icons/ios/credit_card.svg', 'public/global_icons/macos/credit_card.svg', 'public/global_icons/windows/credit_card.png', 'public/global_icons/linux/credit_card.svg', 'Credit Card — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: credit_card.', ARRAY['card','credit','credit card','credit_card','global','icon','noolva','ui']::text[]),
    ('dollar', 'public/global_icons/web/dollar.svg', 'public/global_icons/android/dollar.xml', 'public/global_icons/ios/dollar.svg', 'public/global_icons/macos/dollar.svg', 'public/global_icons/windows/dollar.png', 'public/global_icons/linux/dollar.svg', 'Dollar — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: credit_card.', ARRAY['credit_card','dollar','global','icon','noolva','ui']::text[]),
    ('chart', 'public/global_icons/web/chart.svg', 'public/global_icons/android/chart.xml', 'public/global_icons/ios/chart.svg', 'public/global_icons/macos/chart.svg', 'public/global_icons/windows/chart.png', 'public/global_icons/linux/chart.svg', 'Chart — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: bolt.', ARRAY['bolt','chart','global','icon','noolva','ui']::text[]),
    ('graph', 'public/global_icons/web/graph.svg', 'public/global_icons/android/graph.xml', 'public/global_icons/ios/graph.svg', 'public/global_icons/macos/graph.svg', 'public/global_icons/windows/graph.png', 'public/global_icons/linux/graph.svg', 'Graph — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: chart.', ARRAY['chart','global','graph','icon','noolva','ui']::text[]),
    ('table', 'public/global_icons/web/table.svg', 'public/global_icons/android/table.xml', 'public/global_icons/ios/table.svg', 'public/global_icons/macos/table.svg', 'public/global_icons/windows/table.png', 'public/global_icons/linux/table.svg', 'Table — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: grid.', ARRAY['global','grid','icon','noolva','table','ui']::text[]),
    ('list', 'public/global_icons/web/list.svg', 'public/global_icons/android/list.xml', 'public/global_icons/ios/list.svg', 'public/global_icons/macos/list.svg', 'public/global_icons/windows/list.png', 'public/global_icons/linux/list.svg', 'List — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: list.', ARRAY['global','icon','list','noolva','ui']::text[]),
    ('grid', 'public/global_icons/web/grid.svg', 'public/global_icons/android/grid.xml', 'public/global_icons/ios/grid.svg', 'public/global_icons/macos/grid.svg', 'public/global_icons/windows/grid.png', 'public/global_icons/linux/grid.svg', 'Grid — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: grid.', ARRAY['global','grid','icon','noolva','ui']::text[]),
    ('layout', 'public/global_icons/web/layout.svg', 'public/global_icons/android/layout.xml', 'public/global_icons/ios/layout.svg', 'public/global_icons/macos/layout.svg', 'public/global_icons/windows/layout.png', 'public/global_icons/linux/layout.svg', 'Layout — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: grid.', ARRAY['global','grid','icon','layout','noolva','ui']::text[]),
    ('mobile', 'public/global_icons/web/mobile.svg', 'public/global_icons/android/mobile.xml', 'public/global_icons/ios/mobile.svg', 'public/global_icons/macos/mobile.svg', 'public/global_icons/windows/mobile.png', 'public/global_icons/linux/mobile.svg', 'Mobile — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: phone.', ARRAY['global','icon','mobile','noolva','phone','ui']::text[]),
    ('tablet', 'public/global_icons/web/tablet.svg', 'public/global_icons/android/tablet.xml', 'public/global_icons/ios/tablet.svg', 'public/global_icons/macos/tablet.svg', 'public/global_icons/windows/tablet.png', 'public/global_icons/linux/tablet.svg', 'Tablet — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: phone.', ARRAY['global','icon','noolva','phone','tablet','ui']::text[]),
    ('desktop', 'public/global_icons/web/desktop.svg', 'public/global_icons/android/desktop.xml', 'public/global_icons/ios/desktop.svg', 'public/global_icons/macos/desktop.svg', 'public/global_icons/windows/desktop.png', 'public/global_icons/linux/desktop.svg', 'Desktop — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: grid.', ARRAY['desktop','global','grid','icon','noolva','ui']::text[]),
    ('wifi', 'public/global_icons/web/wifi.svg', 'public/global_icons/android/wifi.xml', 'public/global_icons/ios/wifi.svg', 'public/global_icons/macos/wifi.svg', 'public/global_icons/windows/wifi.png', 'public/global_icons/linux/wifi.svg', 'Wifi — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: wifi.', ARRAY['global','icon','noolva','ui','wifi']::text[]),
    ('bluetooth', 'public/global_icons/web/bluetooth.svg', 'public/global_icons/android/bluetooth.xml', 'public/global_icons/ios/bluetooth.svg', 'public/global_icons/macos/bluetooth.svg', 'public/global_icons/windows/bluetooth.png', 'public/global_icons/linux/bluetooth.svg', 'Bluetooth — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: wifi.', ARRAY['bluetooth','global','icon','noolva','ui','wifi']::text[]),
    ('battery', 'public/global_icons/web/battery.svg', 'public/global_icons/android/battery.xml', 'public/global_icons/ios/battery.svg', 'public/global_icons/macos/battery.svg', 'public/global_icons/windows/battery.png', 'public/global_icons/linux/battery.svg', 'Battery — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: bolt.', ARRAY['battery','bolt','global','icon','noolva','ui']::text[]),
    ('volume', 'public/global_icons/web/volume.svg', 'public/global_icons/android/volume.xml', 'public/global_icons/ios/volume.svg', 'public/global_icons/macos/volume.svg', 'public/global_icons/windows/volume.png', 'public/global_icons/linux/volume.svg', 'Volume — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: bell.', ARRAY['bell','global','icon','noolva','ui','volume']::text[]),
    ('play', 'public/global_icons/web/play.svg', 'public/global_icons/android/play.xml', 'public/global_icons/ios/play.svg', 'public/global_icons/macos/play.svg', 'public/global_icons/windows/play.png', 'public/global_icons/linux/play.svg', 'Play — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: play.', ARRAY['global','icon','noolva','play','ui']::text[]),
    ('pause', 'public/global_icons/web/pause.svg', 'public/global_icons/android/pause.xml', 'public/global_icons/ios/pause.svg', 'public/global_icons/macos/pause.svg', 'public/global_icons/windows/pause.png', 'public/global_icons/linux/pause.svg', 'Pause — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: pause.', ARRAY['global','icon','noolva','pause','ui']::text[]),
    ('stop', 'public/global_icons/web/stop.svg', 'public/global_icons/android/stop.xml', 'public/global_icons/ios/stop.svg', 'public/global_icons/macos/stop.svg', 'public/global_icons/windows/stop.png', 'public/global_icons/linux/stop.svg', 'Stop — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: stop.', ARRAY['global','icon','noolva','stop','ui']::text[]),
    ('next_track', 'public/global_icons/web/next_track.svg', 'public/global_icons/android/next_track.xml', 'public/global_icons/ios/next_track.svg', 'public/global_icons/macos/next_track.svg', 'public/global_icons/windows/next_track.png', 'public/global_icons/linux/next_track.svg', 'Next Track — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: arrow_right.', ARRAY['arrow_right','global','icon','next','next track','next_track','noolva','track','ui']::text[]),
    ('previous_track', 'public/global_icons/web/previous_track.svg', 'public/global_icons/android/previous_track.xml', 'public/global_icons/ios/previous_track.svg', 'public/global_icons/macos/previous_track.svg', 'public/global_icons/windows/previous_track.png', 'public/global_icons/linux/previous_track.svg', 'Previous Track — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: arrow_left.', ARRAY['arrow_left','global','icon','noolva','previous','previous track','previous_track','track','ui']::text[]),
    ('info', 'public/global_icons/web/info.svg', 'public/global_icons/android/info.xml', 'public/global_icons/ios/info.svg', 'public/global_icons/macos/info.svg', 'public/global_icons/windows/info.png', 'public/global_icons/linux/info.svg', 'Info — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: info.', ARRAY['global','icon','info','noolva','ui']::text[]),
    ('help', 'public/global_icons/web/help.svg', 'public/global_icons/android/help.xml', 'public/global_icons/ios/help.svg', 'public/global_icons/macos/help.svg', 'public/global_icons/windows/help.png', 'public/global_icons/linux/help.svg', 'Help — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: info.', ARRAY['global','help','icon','info','noolva','ui']::text[]),
    ('warning', 'public/global_icons/web/warning.svg', 'public/global_icons/android/warning.xml', 'public/global_icons/ios/warning.svg', 'public/global_icons/macos/warning.svg', 'public/global_icons/windows/warning.png', 'public/global_icons/linux/warning.svg', 'Warning — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: warning.', ARRAY['global','icon','noolva','ui','warning']::text[]),
    ('error', 'public/global_icons/web/error.svg', 'public/global_icons/android/error.xml', 'public/global_icons/ios/error.svg', 'public/global_icons/macos/error.svg', 'public/global_icons/windows/error.png', 'public/global_icons/linux/error.svg', 'Error — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: warning.', ARRAY['error','global','icon','noolva','ui','warning']::text[]),
    ('success', 'public/global_icons/web/success.svg', 'public/global_icons/android/success.xml', 'public/global_icons/ios/success.svg', 'public/global_icons/macos/success.svg', 'public/global_icons/windows/success.png', 'public/global_icons/linux/success.svg', 'Success — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: check.', ARRAY['check','global','icon','noolva','success','ui']::text[]),
    ('question', 'public/global_icons/web/question.svg', 'public/global_icons/android/question.xml', 'public/global_icons/ios/question.svg', 'public/global_icons/macos/question.svg', 'public/global_icons/windows/question.png', 'public/global_icons/linux/question.svg', 'Question — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: info.', ARRAY['global','icon','info','noolva','question','ui']::text[]),
    ('eye', 'public/global_icons/web/eye.svg', 'public/global_icons/android/eye.xml', 'public/global_icons/ios/eye.svg', 'public/global_icons/macos/eye.svg', 'public/global_icons/windows/eye.png', 'public/global_icons/linux/eye.svg', 'Eye — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: circle.', ARRAY['circle','eye','global','icon','noolva','ui']::text[]),
    ('eye_off', 'public/global_icons/web/eye_off.svg', 'public/global_icons/android/eye_off.xml', 'public/global_icons/ios/eye_off.svg', 'public/global_icons/macos/eye_off.svg', 'public/global_icons/windows/eye_off.png', 'public/global_icons/linux/eye_off.svg', 'Eye Off — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: close.', ARRAY['close','eye','eye off','eye_off','global','icon','noolva','off','ui']::text[]),
    ('plus', 'public/global_icons/web/plus.svg', 'public/global_icons/android/plus.xml', 'public/global_icons/ios/plus.svg', 'public/global_icons/macos/plus.svg', 'public/global_icons/windows/plus.png', 'public/global_icons/linux/plus.svg', 'Plus — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: plus.', ARRAY['global','icon','noolva','plus','ui']::text[]),
    ('minus', 'public/global_icons/web/minus.svg', 'public/global_icons/android/minus.xml', 'public/global_icons/ios/minus.svg', 'public/global_icons/macos/minus.svg', 'public/global_icons/windows/minus.png', 'public/global_icons/linux/minus.svg', 'Minus — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: minus.', ARRAY['global','icon','minus','noolva','ui']::text[]),
    ('expand', 'public/global_icons/web/expand.svg', 'public/global_icons/android/expand.xml', 'public/global_icons/ios/expand.svg', 'public/global_icons/macos/expand.svg', 'public/global_icons/windows/expand.png', 'public/global_icons/linux/expand.svg', 'Expand — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: arrow_down.', ARRAY['arrow_down','expand','global','icon','noolva','ui']::text[]),
    ('collapse', 'public/global_icons/web/collapse.svg', 'public/global_icons/android/collapse.xml', 'public/global_icons/ios/collapse.svg', 'public/global_icons/macos/collapse.svg', 'public/global_icons/windows/collapse.png', 'public/global_icons/linux/collapse.svg', 'Collapse — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: arrow_up.', ARRAY['arrow_up','collapse','global','icon','noolva','ui']::text[]),
    ('more', 'public/global_icons/web/more.svg', 'public/global_icons/android/more.xml', 'public/global_icons/ios/more.svg', 'public/global_icons/macos/more.svg', 'public/global_icons/windows/more.png', 'public/global_icons/linux/more.svg', 'More — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: menu.', ARRAY['global','icon','menu','more','noolva','ui']::text[]),
    ('dots_vertical', 'public/global_icons/web/dots_vertical.svg', 'public/global_icons/android/dots_vertical.xml', 'public/global_icons/ios/dots_vertical.svg', 'public/global_icons/macos/dots_vertical.svg', 'public/global_icons/windows/dots_vertical.png', 'public/global_icons/linux/dots_vertical.svg', 'Dots Vertical — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: menu.', ARRAY['dots','dots vertical','dots_vertical','global','icon','menu','noolva','ui','vertical']::text[]),
    ('arrow_up', 'public/global_icons/web/arrow_up.svg', 'public/global_icons/android/arrow_up.xml', 'public/global_icons/ios/arrow_up.svg', 'public/global_icons/macos/arrow_up.svg', 'public/global_icons/windows/arrow_up.png', 'public/global_icons/linux/arrow_up.svg', 'Arrow Up — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: arrow_up.', ARRAY['arrow','arrow up','arrow_up','global','icon','noolva','ui','up']::text[]),
    ('arrow_down', 'public/global_icons/web/arrow_down.svg', 'public/global_icons/android/arrow_down.xml', 'public/global_icons/ios/arrow_down.svg', 'public/global_icons/macos/arrow_down.svg', 'public/global_icons/windows/arrow_down.png', 'public/global_icons/linux/arrow_down.svg', 'Arrow Down — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: arrow_down.', ARRAY['arrow','arrow down','arrow_down','down','global','icon','noolva','ui']::text[]),
    ('arrow_left', 'public/global_icons/web/arrow_left.svg', 'public/global_icons/android/arrow_left.xml', 'public/global_icons/ios/arrow_left.svg', 'public/global_icons/macos/arrow_left.svg', 'public/global_icons/windows/arrow_left.png', 'public/global_icons/linux/arrow_left.svg', 'Arrow Left — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: arrow_left.', ARRAY['arrow','arrow left','arrow_left','global','icon','left','noolva','ui']::text[]),
    ('arrow_right', 'public/global_icons/web/arrow_right.svg', 'public/global_icons/android/arrow_right.xml', 'public/global_icons/ios/arrow_right.svg', 'public/global_icons/macos/arrow_right.svg', 'public/global_icons/windows/arrow_right.png', 'public/global_icons/linux/arrow_right.svg', 'Arrow Right — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: arrow_right.', ARRAY['arrow','arrow right','arrow_right','global','icon','noolva','right','ui']::text[]),
    ('chevron_up', 'public/global_icons/web/chevron_up.svg', 'public/global_icons/android/chevron_up.xml', 'public/global_icons/ios/chevron_up.svg', 'public/global_icons/macos/chevron_up.svg', 'public/global_icons/windows/chevron_up.png', 'public/global_icons/linux/chevron_up.svg', 'Chevron Up — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: chevron_up.', ARRAY['chevron','chevron up','chevron_up','global','icon','noolva','ui','up']::text[]),
    ('chevron_down', 'public/global_icons/web/chevron_down.svg', 'public/global_icons/android/chevron_down.xml', 'public/global_icons/ios/chevron_down.svg', 'public/global_icons/macos/chevron_down.svg', 'public/global_icons/windows/chevron_down.png', 'public/global_icons/linux/chevron_down.svg', 'Chevron Down — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: chevron_down.', ARRAY['chevron','chevron down','chevron_down','down','global','icon','noolva','ui']::text[]),
    ('external_link', 'public/global_icons/web/external_link.svg', 'public/global_icons/android/external_link.xml', 'public/global_icons/ios/external_link.svg', 'public/global_icons/macos/external_link.svg', 'public/global_icons/windows/external_link.png', 'public/global_icons/linux/external_link.svg', 'External Link — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: link.', ARRAY['external','external link','external_link','global','icon','link','noolva','ui']::text[]),
    ('attachment', 'public/global_icons/web/attachment.svg', 'public/global_icons/android/attachment.xml', 'public/global_icons/ios/attachment.svg', 'public/global_icons/macos/attachment.svg', 'public/global_icons/windows/attachment.png', 'public/global_icons/linux/attachment.svg', 'Attachment — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: link.', ARRAY['attachment','global','icon','link','noolva','ui']::text[]),
    ('archive', 'public/global_icons/web/archive.svg', 'public/global_icons/android/archive.xml', 'public/global_icons/ios/archive.svg', 'public/global_icons/macos/archive.svg', 'public/global_icons/windows/archive.png', 'public/global_icons/linux/archive.svg', 'Archive — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: folder.', ARRAY['archive','folder','global','icon','noolva','ui']::text[]),
    ('trash', 'public/global_icons/web/trash.svg', 'public/global_icons/android/trash.xml', 'public/global_icons/ios/trash.svg', 'public/global_icons/macos/trash.svg', 'public/global_icons/windows/trash.png', 'public/global_icons/linux/trash.svg', 'Trash — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: delete.', ARRAY['delete','global','icon','noolva','trash','ui']::text[]),
    ('undo', 'public/global_icons/web/undo.svg', 'public/global_icons/android/undo.xml', 'public/global_icons/ios/undo.svg', 'public/global_icons/macos/undo.svg', 'public/global_icons/windows/undo.png', 'public/global_icons/linux/undo.svg', 'Undo — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: arrow_left.', ARRAY['arrow_left','global','icon','noolva','ui','undo']::text[]),
    ('redo', 'public/global_icons/web/redo.svg', 'public/global_icons/android/redo.xml', 'public/global_icons/ios/redo.svg', 'public/global_icons/macos/redo.svg', 'public/global_icons/windows/redo.png', 'public/global_icons/linux/redo.svg', 'Redo — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: arrow_right.', ARRAY['arrow_right','global','icon','noolva','redo','ui']::text[]),
    ('bold', 'public/global_icons/web/bold.svg', 'public/global_icons/android/bold.xml', 'public/global_icons/ios/bold.svg', 'public/global_icons/macos/bold.svg', 'public/global_icons/windows/bold.png', 'public/global_icons/linux/bold.svg', 'Bold — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: edit.', ARRAY['bold','edit','global','icon','noolva','ui']::text[]),
    ('italic', 'public/global_icons/web/italic.svg', 'public/global_icons/android/italic.xml', 'public/global_icons/ios/italic.svg', 'public/global_icons/macos/italic.svg', 'public/global_icons/windows/italic.png', 'public/global_icons/linux/italic.svg', 'Italic — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: edit.', ARRAY['edit','global','icon','italic','noolva','ui']::text[]),
    ('code', 'public/global_icons/web/code.svg', 'public/global_icons/android/code.xml', 'public/global_icons/ios/code.svg', 'public/global_icons/macos/code.svg', 'public/global_icons/windows/code.png', 'public/global_icons/linux/code.svg', 'Code — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: terminal.', ARRAY['code','global','icon','noolva','terminal','ui']::text[]),
    ('globe', 'public/global_icons/web/globe.svg', 'public/global_icons/android/globe.xml', 'public/global_icons/ios/globe.svg', 'public/global_icons/macos/globe.svg', 'public/global_icons/windows/globe.png', 'public/global_icons/linux/globe.svg', 'Globe — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: cloud.', ARRAY['cloud','global','globe','icon','noolva','ui']::text[]),
    ('cloud', 'public/global_icons/web/cloud.svg', 'public/global_icons/android/cloud.xml', 'public/global_icons/ios/cloud.svg', 'public/global_icons/macos/cloud.svg', 'public/global_icons/windows/cloud.png', 'public/global_icons/linux/cloud.svg', 'Cloud — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: cloud.', ARRAY['cloud','global','icon','noolva','ui']::text[]),
    ('database', 'public/global_icons/web/database.svg', 'public/global_icons/android/database.xml', 'public/global_icons/ios/database.svg', 'public/global_icons/macos/database.svg', 'public/global_icons/windows/database.png', 'public/global_icons/linux/database.svg', 'Database — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: database.', ARRAY['database','global','icon','noolva','ui']::text[]),
    ('server', 'public/global_icons/web/server.svg', 'public/global_icons/android/server.xml', 'public/global_icons/ios/server.svg', 'public/global_icons/macos/server.svg', 'public/global_icons/windows/server.png', 'public/global_icons/linux/server.svg', 'Server — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: database.', ARRAY['database','global','icon','noolva','server','ui']::text[]),
    ('shield', 'public/global_icons/web/shield.svg', 'public/global_icons/android/shield.xml', 'public/global_icons/ios/shield.svg', 'public/global_icons/macos/shield.svg', 'public/global_icons/windows/shield.png', 'public/global_icons/linux/shield.svg', 'Shield — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: lock.', ARRAY['global','icon','lock','noolva','shield','ui']::text[]),
    ('wrench', 'public/global_icons/web/wrench.svg', 'public/global_icons/android/wrench.xml', 'public/global_icons/ios/wrench.svg', 'public/global_icons/macos/wrench.svg', 'public/global_icons/windows/wrench.png', 'public/global_icons/linux/wrench.svg', 'Wrench — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: circle.', ARRAY['circle','global','icon','noolva','ui','wrench']::text[]),
    ('tool', 'public/global_icons/web/tool.svg', 'public/global_icons/android/tool.xml', 'public/global_icons/ios/tool.svg', 'public/global_icons/macos/tool.svg', 'public/global_icons/windows/tool.png', 'public/global_icons/linux/tool.svg', 'Tool — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: circle.', ARRAY['circle','global','icon','noolva','tool','ui']::text[]),
    ('sparkles', 'public/global_icons/web/sparkles.svg', 'public/global_icons/android/sparkles.xml', 'public/global_icons/ios/sparkles.svg', 'public/global_icons/macos/sparkles.svg', 'public/global_icons/windows/sparkles.png', 'public/global_icons/linux/sparkles.svg', 'Sparkles — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: star.', ARRAY['global','icon','noolva','sparkles','star','ui']::text[]),
    ('robot', 'public/global_icons/web/robot.svg', 'public/global_icons/android/robot.xml', 'public/global_icons/ios/robot.svg', 'public/global_icons/macos/robot.svg', 'public/global_icons/windows/robot.png', 'public/global_icons/linux/robot.svg', 'Robot — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: terminal.', ARRAY['global','icon','noolva','robot','terminal','ui']::text[]),
    ('chat', 'public/global_icons/web/chat.svg', 'public/global_icons/android/chat.xml', 'public/global_icons/ios/chat.svg', 'public/global_icons/macos/chat.svg', 'public/global_icons/windows/chat.png', 'public/global_icons/linux/chat.svg', 'Chat — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: chat.', ARRAY['chat','global','icon','noolva','ui']::text[]),
    ('message', 'public/global_icons/web/message.svg', 'public/global_icons/android/message.xml', 'public/global_icons/ios/message.svg', 'public/global_icons/macos/message.svg', 'public/global_icons/windows/message.png', 'public/global_icons/linux/message.svg', 'Message — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: chat.', ARRAY['chat','global','icon','message','noolva','ui']::text[]),
    ('team', 'public/global_icons/web/team.svg', 'public/global_icons/android/team.xml', 'public/global_icons/ios/team.svg', 'public/global_icons/macos/team.svg', 'public/global_icons/windows/team.png', 'public/global_icons/linux/team.svg', 'Team — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: users.', ARRAY['global','icon','noolva','team','ui','users']::text[]),
    ('building', 'public/global_icons/web/building.svg', 'public/global_icons/android/building.xml', 'public/global_icons/ios/building.svg', 'public/global_icons/macos/building.svg', 'public/global_icons/windows/building.png', 'public/global_icons/linux/building.svg', 'Building — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: home.', ARRAY['building','global','home','icon','noolva','ui']::text[]),
    ('truck', 'public/global_icons/web/truck.svg', 'public/global_icons/android/truck.xml', 'public/global_icons/ios/truck.svg', 'public/global_icons/macos/truck.svg', 'public/global_icons/windows/truck.png', 'public/global_icons/linux/truck.svg', 'Truck — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: map.', ARRAY['global','icon','map','noolva','truck','ui']::text[]),
    ('plane', 'public/global_icons/web/plane.svg', 'public/global_icons/android/plane.xml', 'public/global_icons/ios/plane.svg', 'public/global_icons/macos/plane.svg', 'public/global_icons/windows/plane.png', 'public/global_icons/linux/plane.svg', 'Plane — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: map.', ARRAY['global','icon','map','noolva','plane','ui']::text[]),
    ('car', 'public/global_icons/web/car.svg', 'public/global_icons/android/car.xml', 'public/global_icons/ios/car.svg', 'public/global_icons/macos/car.svg', 'public/global_icons/windows/car.png', 'public/global_icons/linux/car.svg', 'Car — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: map.', ARRAY['car','global','icon','map','noolva','ui']::text[]),
    ('coffee', 'public/global_icons/web/coffee.svg', 'public/global_icons/android/coffee.xml', 'public/global_icons/ios/coffee.svg', 'public/global_icons/macos/coffee.svg', 'public/global_icons/windows/coffee.png', 'public/global_icons/linux/coffee.svg', 'Coffee — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: circle.', ARRAY['circle','coffee','global','icon','noolva','ui']::text[]),
    ('sun', 'public/global_icons/web/sun.svg', 'public/global_icons/android/sun.xml', 'public/global_icons/ios/sun.svg', 'public/global_icons/macos/sun.svg', 'public/global_icons/windows/sun.png', 'public/global_icons/linux/sun.svg', 'Sun — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: circle.', ARRAY['circle','global','icon','noolva','sun','ui']::text[]),
    ('moon', 'public/global_icons/web/moon.svg', 'public/global_icons/android/moon.xml', 'public/global_icons/ios/moon.svg', 'public/global_icons/macos/moon.svg', 'public/global_icons/windows/moon.png', 'public/global_icons/linux/moon.svg', 'Moon — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: circle.', ARRAY['circle','global','icon','moon','noolva','ui']::text[]),
    ('language', 'public/global_icons/web/language.svg', 'public/global_icons/android/language.xml', 'public/global_icons/ios/language.svg', 'public/global_icons/macos/language.svg', 'public/global_icons/windows/language.png', 'public/global_icons/linux/language.svg', 'Language — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: cloud.', ARRAY['cloud','global','icon','language','noolva','ui']::text[]),
    ('log_in', 'public/global_icons/web/log_in.svg', 'public/global_icons/android/log_in.xml', 'public/global_icons/ios/log_in.svg', 'public/global_icons/macos/log_in.svg', 'public/global_icons/windows/log_in.png', 'public/global_icons/linux/log_in.svg', 'Log In — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: arrow_right.', ARRAY['arrow_right','global','icon','in','log','log in','log_in','noolva','ui']::text[]),
    ('log_out', 'public/global_icons/web/log_out.svg', 'public/global_icons/android/log_out.xml', 'public/global_icons/ios/log_out.svg', 'public/global_icons/macos/log_out.svg', 'public/global_icons/windows/log_out.png', 'public/global_icons/linux/log_out.svg', 'Log Out — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: arrow_left.', ARRAY['arrow_left','global','icon','log','log out','log_out','noolva','out','ui']::text[]),
    ('profile', 'public/global_icons/web/profile.svg', 'public/global_icons/android/profile.xml', 'public/global_icons/ios/profile.svg', 'public/global_icons/macos/profile.svg', 'public/global_icons/windows/profile.png', 'public/global_icons/linux/profile.svg', 'Profile — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: user.', ARRAY['global','icon','noolva','profile','ui','user']::text[]),
    ('notification', 'public/global_icons/web/notification.svg', 'public/global_icons/android/notification.xml', 'public/global_icons/ios/notification.svg', 'public/global_icons/macos/notification.svg', 'public/global_icons/windows/notification.png', 'public/global_icons/linux/notification.svg', 'Notification — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: bell.', ARRAY['bell','global','icon','noolva','notification','ui']::text[]),
    ('dashboard', 'public/global_icons/web/dashboard.svg', 'public/global_icons/android/dashboard.xml', 'public/global_icons/ios/dashboard.svg', 'public/global_icons/macos/dashboard.svg', 'public/global_icons/windows/dashboard.png', 'public/global_icons/linux/dashboard.svg', 'Dashboard — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: grid.', ARRAY['dashboard','global','grid','icon','noolva','ui']::text[]),
    ('activity', 'public/global_icons/web/activity.svg', 'public/global_icons/android/activity.xml', 'public/global_icons/ios/activity.svg', 'public/global_icons/macos/activity.svg', 'public/global_icons/windows/activity.png', 'public/global_icons/linux/activity.svg', 'Activity — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: bolt.', ARRAY['activity','bolt','global','icon','noolva','ui']::text[]),
    ('layers', 'public/global_icons/web/layers.svg', 'public/global_icons/android/layers.xml', 'public/global_icons/ios/layers.svg', 'public/global_icons/macos/layers.svg', 'public/global_icons/windows/layers.png', 'public/global_icons/linux/layers.svg', 'Layers — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: grid.', ARRAY['global','grid','icon','layers','noolva','ui']::text[]),
    ('compass', 'public/global_icons/web/compass.svg', 'public/global_icons/android/compass.xml', 'public/global_icons/ios/compass.svg', 'public/global_icons/macos/compass.svg', 'public/global_icons/windows/compass.png', 'public/global_icons/linux/compass.svg', 'Compass — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: circle.', ARRAY['circle','compass','global','icon','noolva','ui']::text[]),
    ('target', 'public/global_icons/web/target.svg', 'public/global_icons/android/target.xml', 'public/global_icons/ios/target.svg', 'public/global_icons/macos/target.svg', 'public/global_icons/windows/target.png', 'public/global_icons/linux/target.svg', 'Target — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: circle.', ARRAY['circle','global','icon','noolva','target','ui']::text[]),
    ('award', 'public/global_icons/web/award.svg', 'public/global_icons/android/award.xml', 'public/global_icons/ios/award.svg', 'public/global_icons/macos/award.svg', 'public/global_icons/windows/award.png', 'public/global_icons/linux/award.svg', 'Award — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: star.', ARRAY['award','global','icon','noolva','star','ui']::text[]),
    ('gift', 'public/global_icons/web/gift.svg', 'public/global_icons/android/gift.xml', 'public/global_icons/ios/gift.svg', 'public/global_icons/macos/gift.svg', 'public/global_icons/windows/gift.png', 'public/global_icons/linux/gift.svg', 'Gift — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: heart.', ARRAY['gift','global','heart','icon','noolva','ui']::text[]),
    ('megaphone', 'public/global_icons/web/megaphone.svg', 'public/global_icons/android/megaphone.xml', 'public/global_icons/ios/megaphone.svg', 'public/global_icons/macos/megaphone.svg', 'public/global_icons/windows/megaphone.png', 'public/global_icons/linux/megaphone.svg', 'Megaphone — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: bell.', ARRAY['bell','global','icon','megaphone','noolva','ui']::text[]),
    ('puzzle', 'public/global_icons/web/puzzle.svg', 'public/global_icons/android/puzzle.xml', 'public/global_icons/ios/puzzle.svg', 'public/global_icons/macos/puzzle.svg', 'public/global_icons/windows/puzzle.png', 'public/global_icons/linux/puzzle.svg', 'Puzzle — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: grid.', ARRAY['global','grid','icon','noolva','puzzle','ui']::text[]),
    ('brush', 'public/global_icons/web/brush.svg', 'public/global_icons/android/brush.xml', 'public/global_icons/ios/brush.svg', 'public/global_icons/macos/brush.svg', 'public/global_icons/windows/brush.png', 'public/global_icons/linux/brush.svg', 'Brush — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: edit.', ARRAY['brush','edit','global','icon','noolva','ui']::text[]),
    ('crop', 'public/global_icons/web/crop.svg', 'public/global_icons/android/crop.xml', 'public/global_icons/ios/crop.svg', 'public/global_icons/macos/crop.svg', 'public/global_icons/windows/crop.png', 'public/global_icons/linux/crop.svg', 'Crop — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: image.', ARRAY['crop','global','icon','image','noolva','ui']::text[]),
    ('adjust', 'public/global_icons/web/adjust.svg', 'public/global_icons/android/adjust.xml', 'public/global_icons/ios/adjust.svg', 'public/global_icons/macos/adjust.svg', 'public/global_icons/windows/adjust.png', 'public/global_icons/linux/adjust.svg', 'Adjust — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: settings.', ARRAY['adjust','global','icon','noolva','settings','ui']::text[]),
    ('zoom_in', 'public/global_icons/web/zoom_in.svg', 'public/global_icons/android/zoom_in.xml', 'public/global_icons/ios/zoom_in.svg', 'public/global_icons/macos/zoom_in.svg', 'public/global_icons/windows/zoom_in.png', 'public/global_icons/linux/zoom_in.svg', 'Zoom In — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: search.', ARRAY['global','icon','in','noolva','search','ui','zoom','zoom in','zoom_in']::text[]),
    ('zoom_out', 'public/global_icons/web/zoom_out.svg', 'public/global_icons/android/zoom_out.xml', 'public/global_icons/ios/zoom_out.svg', 'public/global_icons/macos/zoom_out.svg', 'public/global_icons/windows/zoom_out.png', 'public/global_icons/linux/zoom_out.svg', 'Zoom Out — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: search.', ARRAY['global','icon','noolva','out','search','ui','zoom','zoom out','zoom_out']::text[]),
    ('inbox', 'public/global_icons/web/inbox.svg', 'public/global_icons/android/inbox.xml', 'public/global_icons/ios/inbox.svg', 'public/global_icons/macos/inbox.svg', 'public/global_icons/windows/inbox.png', 'public/global_icons/linux/inbox.svg', 'Inbox — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: mail.', ARRAY['global','icon','inbox','mail','noolva','ui']::text[]),
    ('send', 'public/global_icons/web/send.svg', 'public/global_icons/android/send.xml', 'public/global_icons/ios/send.svg', 'public/global_icons/macos/send.svg', 'public/global_icons/windows/send.png', 'public/global_icons/linux/send.svg', 'Send — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: arrow_right.', ARRAY['arrow_right','global','icon','noolva','send','ui']::text[]),
    ('reply', 'public/global_icons/web/reply.svg', 'public/global_icons/android/reply.xml', 'public/global_icons/ios/reply.svg', 'public/global_icons/macos/reply.svg', 'public/global_icons/windows/reply.png', 'public/global_icons/linux/reply.svg', 'Reply — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: arrow_left.', ARRAY['arrow_left','global','icon','noolva','reply','ui']::text[]),
    ('forward_mail', 'public/global_icons/web/forward_mail.svg', 'public/global_icons/android/forward_mail.xml', 'public/global_icons/ios/forward_mail.svg', 'public/global_icons/macos/forward_mail.svg', 'public/global_icons/windows/forward_mail.png', 'public/global_icons/linux/forward_mail.svg', 'Forward Mail — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: mail.', ARRAY['forward','forward mail','forward_mail','global','icon','mail','noolva','ui']::text[]),
    ('folder_open', 'public/global_icons/web/folder_open.svg', 'public/global_icons/android/folder_open.xml', 'public/global_icons/ios/folder_open.svg', 'public/global_icons/macos/folder_open.svg', 'public/global_icons/windows/folder_open.png', 'public/global_icons/linux/folder_open.svg', 'Folder Open — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: folder.', ARRAY['folder','folder open','folder_open','global','icon','noolva','open','ui']::text[]),
    ('note', 'public/global_icons/web/note.svg', 'public/global_icons/android/note.xml', 'public/global_icons/ios/note.svg', 'public/global_icons/macos/note.svg', 'public/global_icons/windows/note.png', 'public/global_icons/linux/note.svg', 'Note — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: file.', ARRAY['file','global','icon','noolva','note','ui']::text[]),
    ('pin', 'public/global_icons/web/pin.svg', 'public/global_icons/android/pin.xml', 'public/global_icons/ios/pin.svg', 'public/global_icons/macos/pin.svg', 'public/global_icons/windows/pin.png', 'public/global_icons/linux/pin.svg', 'Pin — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: star.', ARRAY['global','icon','noolva','pin','star','ui']::text[]),
    ('unpin', 'public/global_icons/web/unpin.svg', 'public/global_icons/android/unpin.xml', 'public/global_icons/ios/unpin.svg', 'public/global_icons/macos/unpin.svg', 'public/global_icons/windows/unpin.png', 'public/global_icons/linux/unpin.svg', 'Unpin — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: close.', ARRAY['close','global','icon','noolva','ui','unpin']::text[]),
    ('history', 'public/global_icons/web/history.svg', 'public/global_icons/android/history.xml', 'public/global_icons/ios/history.svg', 'public/global_icons/macos/history.svg', 'public/global_icons/windows/history.png', 'public/global_icons/linux/history.svg', 'History — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: refresh.', ARRAY['global','history','icon','noolva','refresh','ui']::text[]),
    ('sync', 'public/global_icons/web/sync.svg', 'public/global_icons/android/sync.xml', 'public/global_icons/ios/sync.svg', 'public/global_icons/macos/sync.svg', 'public/global_icons/windows/sync.png', 'public/global_icons/linux/sync.svg', 'Sync — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: refresh.', ARRAY['global','icon','noolva','refresh','sync','ui']::text[]),
    ('import_icon', 'public/global_icons/web/import_icon.svg', 'public/global_icons/android/import_icon.xml', 'public/global_icons/ios/import_icon.svg', 'public/global_icons/macos/import_icon.svg', 'public/global_icons/windows/import_icon.png', 'public/global_icons/linux/import_icon.svg', 'Import Icon — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: download.', ARRAY['download','global','icon','import','import icon','import_icon','noolva','ui']::text[]),
    ('export_icon', 'public/global_icons/web/export_icon.svg', 'public/global_icons/android/export_icon.xml', 'public/global_icons/ios/export_icon.svg', 'public/global_icons/macos/export_icon.svg', 'public/global_icons/windows/export_icon.png', 'public/global_icons/linux/export_icon.svg', 'Export Icon — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: upload.', ARRAY['export','export icon','export_icon','global','icon','noolva','ui','upload']::text[]),
    ('template', 'public/global_icons/web/template.svg', 'public/global_icons/android/template.xml', 'public/global_icons/ios/template.svg', 'public/global_icons/macos/template.svg', 'public/global_icons/windows/template.png', 'public/global_icons/linux/template.svg', 'Template — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: file.', ARRAY['file','global','icon','noolva','template','ui']::text[]),
    ('workflow', 'public/global_icons/web/workflow.svg', 'public/global_icons/android/workflow.xml', 'public/global_icons/ios/workflow.svg', 'public/global_icons/macos/workflow.svg', 'public/global_icons/windows/workflow.png', 'public/global_icons/linux/workflow.svg', 'Workflow — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: list.', ARRAY['global','icon','list','noolva','ui','workflow']::text[]),
    ('api', 'public/global_icons/web/api.svg', 'public/global_icons/android/api.xml', 'public/global_icons/ios/api.svg', 'public/global_icons/macos/api.svg', 'public/global_icons/windows/api.png', 'public/global_icons/linux/api.svg', 'Api — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: terminal.', ARRAY['api','global','icon','noolva','terminal','ui']::text[]),
    ('webhook', 'public/global_icons/web/webhook.svg', 'public/global_icons/android/webhook.xml', 'public/global_icons/ios/webhook.svg', 'public/global_icons/macos/webhook.svg', 'public/global_icons/windows/webhook.png', 'public/global_icons/linux/webhook.svg', 'Webhook — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: link.', ARRAY['global','icon','link','noolva','ui','webhook']::text[]),
    ('terminal', 'public/global_icons/web/terminal.svg', 'public/global_icons/android/terminal.xml', 'public/global_icons/ios/terminal.svg', 'public/global_icons/macos/terminal.svg', 'public/global_icons/windows/terminal.png', 'public/global_icons/linux/terminal.svg', 'Terminal — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, Windows PNG tile, Linux SVG). Semantic preset: terminal.', ARRAY['global','icon','noolva','terminal','ui']::text[])
ON CONFLICT (icon_key) DO UPDATE SET
    icon_path_web = EXCLUDED.icon_path_web,
    icon_path_android = EXCLUDED.icon_path_android,
    icon_path_ios = EXCLUDED.icon_path_ios,
    icon_path_macos = EXCLUDED.icon_path_macos,
    icon_path_windows = EXCLUDED.icon_path_windows,
    icon_path_linux = EXCLUDED.icon_path_linux,
    description = EXCLUDED.description,
    keywords = EXCLUDED.keywords;


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
    ft_duration INT;
BEGIN
    SELECT field_type_id INTO ft_text FROM public.field_types WHERE type_code = 'text';
    SELECT field_type_id INTO ft_color FROM public.field_types WHERE type_code = 'color';
    SELECT field_type_id INTO ft_number FROM public.field_types WHERE type_code = 'number';
    SELECT field_type_id INTO ft_bool FROM public.field_types WHERE type_code = 'boolean';
    SELECT field_type_id INTO ft_image FROM public.field_types WHERE type_code = 'image';
    SELECT field_type_id INTO ft_single_choice FROM public.field_types WHERE type_code = 'single_choice';
    SELECT field_type_id INTO ft_duration FROM public.field_types WHERE type_code = 'duration';

    -- 1. General Settings
    INSERT INTO public.settings (group_name, setting_key, setting_name, description, field_type_id, default_value, value, scope, is_built_in, field_config_json)
    VALUES
    ('General', 'app_name', 'Application Name', 'The visible name of the SaaS platform', ft_text, '"Noolva SaaS"', '"Noolva SaaS"', 'global', true, '{}'::jsonb),
    ('Branding', 'brand_color', 'Primary Brand Color', 'Main accent color', ft_color, '"#007bff"', '"#007bff"', 'global', true, '{}'::jsonb),
    
    -- 1.1 Theme Default Selection (actual themes in themes table)
    ('Theme', 'default_saas_theme', 'Default SAAS Theme', 'Default theme for SAAS UI', ft_single_choice, '"default"', '"default"', 'global', true,
        '{"options":[{"label":"Default Corporate","value":"default"},{"label":"Slate Corporate","value":"slate"}]}'::jsonb
    ),
    ('Theme', 'default_tenant_theme', 'Default Tenant Theme', 'Default theme for Tenant UI', ft_single_choice, '"default"', '"default"', 'global', true,
        '{"options":[{"label":"Default Corporate","value":"default"},{"label":"Slate Corporate","value":"slate"}]}'::jsonb
    ),
    
    -- 2. Security
    ('Security', 'password_min_length', 'Minimum Password Length', 'Enforced complexity', ft_number, '8', '8', 'global', true, '{"min":6,"max":64,"step":1}'::jsonb),
    ('Security', 'enable_2fa', 'Enable 2FA', 'Allow users to enable Two-Factor Auth', ft_bool, 'false', 'false', 'global', true, '{}'::jsonb),
    ('Security', 'idle_timeout_minutes', 'Idle session lock (minutes)', 'Lock session after this many minutes of inactivity; user must re-enter password (and 2FA if enabled). Use -1 for no lock.', ft_duration, '15', '15', 'global', true, '{"min":-1,"max":1440,"step":1,"unit":"minutes"}'::jsonb),
    ('UI', 'auto_hide_sidebar', 'Auto Hide Sidebar', 'When Yes, the app sidebar is hidden by default.', ft_bool, 'false', 'false', 'global', true, '{}'::jsonb),
    ('General', 'current_user_mode', 'Current User Mode', 'When set, auto CRUD list returns only rows whose row_exposure_mode matches this mode and expose_data is Yes. Null = show all.', ft_single_choice, NULL, NULL, 'global', true, '{"options_source": "row_exposure_modes"}'::jsonb)
    ON CONFLICT (setting_key, tenant_id) WHERE user_uuid IS NULL DO NOTHING;
END $$;

-- ==========================================
-- 3.1 Themes (Seed - builtin default and slate)
-- ==========================================
DO $$
DECLARE
    system_user_id INT;
BEGIN
    SELECT user_id INTO system_user_id FROM public.users WHERE user_type = 'system' LIMIT 1;
    
    IF NOT EXISTS (SELECT 1 FROM public.themes WHERE theme_key = 'default' AND scope = 'saas' AND user_id IS NULL) THEN
        INSERT INTO public.themes (theme_name, theme_key, theme_json, user_id, scope, tenant_id, is_builtin, is_default, created_by)
        VALUES (
            'Default Corporate', 'default',
            '{"theme":"default","theme_color_primary":"#1890ff","theme_color_secondary":"#52c41a","theme_mode":"light","font_size_base":14,"font_size_small":12,"font_size_large":16,"header_bg_color":"#2563eb","sidebar_bg_color":"#f1f5f9"}'::jsonb,
            NULL, 'saas', NULL, TRUE, TRUE, system_user_id
        );
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM public.themes WHERE theme_key = 'slate' AND scope = 'saas' AND user_id IS NULL) THEN
        INSERT INTO public.themes (theme_name, theme_key, theme_json, user_id, scope, tenant_id, is_builtin, is_default, created_by)
        VALUES (
            'Slate Corporate', 'slate',
            '{"theme":"slate","theme_color_primary":"#1890ff","theme_color_secondary":"#52c41a","theme_mode":"light","font_size_base":14,"font_size_small":12,"font_size_large":16,"header_bg_color":"#475569","sidebar_bg_color":"#f8fafc"}'::jsonb,
            NULL, 'saas', NULL, TRUE, FALSE, system_user_id
        );
    END IF;
END $$;

-- ==========================================
-- 3.2 Apps & Menus (Seed)
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
    assets_menu_id INT;
    settings_org_menu_id INT;
    org_app_loop_id INT;
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
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=dev_console_app_id AND parent_id IS NULL AND menu_title='Scheduler Workers') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Scheduler Workers',NULL,'item','dev_console_scheduler_workers','team',dev_console_app_id,'saas',TRUE,30,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=dev_console_app_id AND parent_id IS NULL AND menu_title='Job Templates') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Job Templates',NULL,'item','dev_console_job_templates','file-text',dev_console_app_id,'saas',TRUE,40,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=dev_console_app_id AND parent_id IS NULL AND menu_title='Jobs') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Jobs',NULL,'item','dev_console_jobs','unordered-list',dev_console_app_id,'saas',TRUE,50,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=dev_console_app_id AND parent_id IS NULL AND menu_title='Schedulers') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Schedulers',NULL,'item','dev_console_schedulers','clock-circle',dev_console_app_id,'saas',TRUE,55,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=dev_console_app_id AND parent_id IS NULL AND menu_title='Flattened Datas') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Flattened Datas',NULL,'item','dev_console_flattened_datas','table',dev_console_app_id,'saas',TRUE,52,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=dev_console_app_id AND parent_id IS NULL AND menu_title='Data Life Cycles') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Data Life Cycles',NULL,'item','dev_console_data_lifecycle','swap',dev_console_app_id,'saas',TRUE,53,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=dev_console_app_id AND parent_id IS NULL AND menu_title='Lifecycle batch ledger') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Lifecycle batch ledger',NULL,'item','dev_console_data_lifecycle_ledger','database',dev_console_app_id,'saas',TRUE,54,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=dev_console_app_id AND parent_id IS NULL AND route_path='dev_console_client_instances') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Client instances',NULL,'item','dev_console_client_instances','mobile',dev_console_app_id,'saas',TRUE,56,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=dev_console_app_id AND parent_id IS NULL AND route_path='dev_console_instance_menus') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Instance menus',NULL,'item','dev_console_instance_menus','unordered-list',dev_console_app_id,'saas',TRUE,57,system_user_id);
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
    -- Organization > Settings: parent folder + General (settings page). Change password is top-level (same app), not nested under Settings.
    SELECT menu_id INTO settings_org_menu_id FROM public.menus
        WHERE app_id = organization_app_id AND parent_id IS NULL AND menu_title = 'Settings' LIMIT 1;
    IF settings_org_menu_id IS NULL THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Settings',NULL,'item',NULL,'setting',organization_app_id,'saas',TRUE,80,system_user_id)
        RETURNING menu_id INTO settings_org_menu_id;
    END IF;
    IF settings_org_menu_id IS NOT NULL THEN
        UPDATE public.menus SET route_path = NULL, last_updated = CURRENT_TIMESTAMP
        WHERE menu_id = settings_org_menu_id AND route_path = 'settings';
        IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=organization_app_id AND parent_id=settings_org_menu_id AND route_path='settings') THEN
            INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
            VALUES ('General',settings_org_menu_id,'item','settings','setting',organization_app_id,'saas',TRUE,10,system_user_id);
        END IF;
    END IF;
    -- Change password: top-level on every organization app (each tenant/company scope has its own app_id)
    FOR org_app_loop_id IN SELECT a.app_id FROM public.apps a WHERE a.app_name = 'organization'
    LOOP
        UPDATE public.menus SET parent_id = NULL, order_no = 82, last_updated = CURRENT_TIMESTAMP
        WHERE app_id = org_app_loop_id AND route_path = 'change_password' AND menu_title = 'Change password';
        IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id = org_app_loop_id AND parent_id IS NULL AND route_path = 'change_password') THEN
            INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
            VALUES ('Change password',NULL,'item','change_password','key',org_app_loop_id,'saas',TRUE,82,system_user_id);
        END IF;
    END LOOP;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=organization_app_id AND parent_id IS NULL AND menu_title='Themes') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Themes',NULL,'item','themes','bgcolors',organization_app_id,'saas',TRUE,85,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=organization_app_id AND parent_id IS NULL AND menu_title='Personal Access Tokens') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Personal Access Tokens',NULL,'item','personal_access_tokens','key',organization_app_id,'saas',TRUE,86,system_user_id);
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
    -- Asset Gallery as child of Assets (two-level menu)
    SELECT menu_id INTO assets_menu_id FROM public.menus WHERE app_id=appstudio_app_id AND menu_title='Assets' AND parent_id IS NULL LIMIT 1;
    IF assets_menu_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=appstudio_app_id AND parent_id=assets_menu_id AND menu_title='Asset Gallery') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Asset Gallery',assets_menu_id,'item','studio_asset_gallery','picture',appstudio_app_id,'saas',TRUE,1,system_user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=appstudio_app_id AND parent_id IS NULL AND menu_title='Global icons') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Global icons',NULL,'item','studio_global_icons','picture',appstudio_app_id,'saas',TRUE,105,system_user_id);
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

-- ==========================================
-- Persons, Jobs, Tasks: Data Models and Fields (for auto CRUD)
-- ==========================================
-- Registers Life OS / Contacts tables in data_models and data_model_fields so
-- /data-models/auto/{model_name}/records works. Idempotent (ON CONFLICT / WHERE NOT EXISTS).

INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'priorities', 'Priorities', 'priorities', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;
INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'job_areas', 'Job Areas', 'job_areas', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;
INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'jobs', 'Jobs', 'jobs', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;
INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'persons', 'Persons', 'persons', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;
INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'person_attachments', 'Person Attachments', 'person_attachments', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;
INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'person_relationships', 'Person Relationships', 'person_relationships', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;
INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'person_contacts', 'Person Contacts', 'person_contacts', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;
INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'person_addresses', 'Person Addresses', 'person_addresses', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;
INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'businesses', 'Businesses', 'businesses', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;
INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'person_business_roles', 'Person Business Roles', 'person_business_roles', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;
INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'business_contact_methods', 'Business Contact Methods', 'business_contact_methods', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;
INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'business_addresses', 'Business Addresses', 'business_addresses', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;
INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'lessons_learned', 'Lessons Learned', 'lessons_learned', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;
INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'tasks', 'Tasks', 'tasks', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;
INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'task_recurrence', 'Task Recurrence', 'task_recurrence', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;
INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'sprints', 'Sprints', 'sprints', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;
INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'sprint_tasks', 'Sprint Tasks', 'sprint_tasks', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;
INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'task_references', 'Task References', 'task_references', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;
INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'task_notes', 'Task Notes', 'task_notes', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;
INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'task_attachments', 'Task Attachments', 'task_attachments', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;
INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'backlogs', 'Backlogs', 'backlogs', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;
INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'backlog_items', 'Backlog Items', 'backlog_items', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;
INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'notes', 'Notes', 'notes', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;
INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'note_attachments', 'Note Attachments', 'note_attachments', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;
INSERT INTO public.data_models (app_id, model_name, display_name, table_name, model_scope, is_system_model, is_active)
VALUES (NULL, 'password_vault', 'Password Vault', 'password_vault', 'saas', FALSE, TRUE)
ON CONFLICT (app_id, model_name) DO NOTHING;

-- To register field definitions (data_model_fields) for these models so auto CRUD works, run:
--   db-structure/update_old_db_persons_jobs_tasks.sql
-- (Idempotent; safe to run after feeds.)
