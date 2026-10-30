-- ============================================================================
-- Release 1.0.6 — 16: Notes & Note Categories Schema
-- Model 1: note_categories (Hierarchical categories with parent_id)
-- Model 2: notes (Structured interactive notes with extended Markdown DSL)
-- Idempotent: safe to re-run.
-- ============================================================================

-- 1. note_categories table
CREATE TABLE IF NOT EXISTS public.note_categories (
    category_id SERIAL PRIMARY KEY,
    category_uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    name VARCHAR(120) NOT NULL,
    slug VARCHAR(120) NOT NULL,
    domain VARCHAR(100) DEFAULT 'General',
    parent_id INTEGER REFERENCES public.note_categories(category_id) ON DELETE SET NULL,
    icon_key VARCHAR(50) DEFAULT 'folder',
    sort_order INTEGER DEFAULT 0,
    description TEXT,
    created_by INTEGER REFERENCES public.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    row_exposure_mode_id INTEGER REFERENCES public.row_exposure_modes(exposure_mode_id)
);

CREATE INDEX IF NOT EXISTS idx_note_categories_parent ON public.note_categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_note_categories_domain ON public.note_categories(domain);
CREATE INDEX IF NOT EXISTS idx_note_categories_slug ON public.note_categories(slug);

-- 2. notes table
CREATE TABLE IF NOT EXISTS public.notes (
    note_id SERIAL PRIMARY KEY,
    note_uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL,
    category_id INTEGER REFERENCES public.note_categories(category_id) ON DELETE SET NULL,
    domain VARCHAR(100) DEFAULT 'General',
    summary TEXT,
    raw_markdown TEXT NOT NULL DEFAULT '',
    parsed_blocks JSONB DEFAULT '[]'::jsonb,
    variables JSONB DEFAULT '{}'::jsonb,
    tags TEXT,
    status VARCHAR(30) NOT NULL DEFAULT 'published',
    is_pinned BOOLEAN DEFAULT false,
    created_by INTEGER REFERENCES public.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    row_exposure_mode_id INTEGER REFERENCES public.row_exposure_modes(exposure_mode_id)
);

CREATE INDEX IF NOT EXISTS idx_notes_category ON public.notes(category_id);
CREATE INDEX IF NOT EXISTS idx_notes_domain ON public.notes(domain);
CREATE INDEX IF NOT EXISTS idx_notes_status ON public.notes(status);
CREATE INDEX IF NOT EXISTS idx_notes_slug ON public.notes(slug);
CREATE INDEX IF NOT EXISTS idx_notes_pinned ON public.notes(is_pinned);

-- 3. Register Data Models in Noolva Auto-CRUD
INSERT INTO public.data_models (model_uuid, model_name, display_name, table_name, is_public, is_system_model, is_active, table_alias, model_scope, created_by)
SELECT gen_random_uuid(), 'note_categories', 'Note Categories', 'note_categories', false, false, true, 'nc', 'saas', 2
WHERE NOT EXISTS (SELECT 1 FROM public.data_models WHERE model_name = 'note_categories');

INSERT INTO public.data_models (model_uuid, model_name, display_name, table_name, is_public, is_system_model, is_active, table_alias, model_scope, created_by)
SELECT gen_random_uuid(), 'notes', 'Notes', 'notes', false, false, true, 'nt', 'saas', 2
WHERE NOT EXISTS (SELECT 1 FROM public.data_models WHERE model_name = 'notes');

-- 4. Add "Notes" menu to instance_menus
DO $$
DECLARE
    v_instance_id INTEGER := 1;  -- PKManager instance
    v_created_by INTEGER := 2;   -- admin user
    v_menu_id INTEGER;
BEGIN
    INSERT INTO public.instance_menus (instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by)
    SELECT v_instance_id, 'Notes', '/notes', false, 'book', NULL, 8, v_created_by
    WHERE NOT EXISTS (
        SELECT 1 FROM public.instance_menus
        WHERE instance_id = v_instance_id AND menu_title = 'Notes'
    )
    RETURNING id INTO v_menu_id;

    IF v_menu_id IS NULL THEN
        SELECT id INTO v_menu_id FROM public.instance_menus
        WHERE instance_id = v_instance_id AND menu_title = 'Notes'
        LIMIT 1;
    END IF;

    IF v_menu_id IS NOT NULL THEN
        INSERT INTO public.instance_menu_client_config (instance_menu_id, client_type, render_mode, is_enabled, created_by)
        VALUES (v_menu_id, 'web', 'web', true, v_created_by)
        ON CONFLICT (instance_menu_id, client_type) DO NOTHING;

        INSERT INTO public.instance_menu_client_config (instance_menu_id, client_type, render_mode, is_enabled, created_by)
        VALUES (v_menu_id, 'android', 'native', true, v_created_by)
        ON CONFLICT (instance_menu_id, client_type) DO NOTHING;
    END IF;
END $$;
