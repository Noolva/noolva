-- ============================================================================
-- Release 1.0.6 — 15: Meeting Sessions & Meeting Session Items Schema
-- Model 1: meeting_sessions (Stand-ups, discussions, calls, reviews, work sessions)
-- Model 2: meeting_session_items (Tasks discussed, notes, responses, decisions)
-- Idempotent: safe to re-run.
-- ============================================================================

-- 1. meeting_sessions table
CREATE TABLE IF NOT EXISTS public.meeting_sessions (
    session_id SERIAL PRIMARY KEY,
    session_uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    session_type VARCHAR(50) NOT NULL DEFAULT 'stand_up',
    session_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    participants TEXT[],
    summary TEXT,
    decisions TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'planned',
    created_by INTEGER REFERENCES public.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    row_exposure_mode_id INTEGER REFERENCES public.row_exposure_modes(exposure_mode_id)
);

CREATE INDEX IF NOT EXISTS idx_meeting_sessions_date ON public.meeting_sessions(session_date DESC);
CREATE INDEX IF NOT EXISTS idx_meeting_sessions_status ON public.meeting_sessions(status);
CREATE INDEX IF NOT EXISTS idx_meeting_sessions_type ON public.meeting_sessions(session_type);
CREATE INDEX IF NOT EXISTS idx_meeting_sessions_created_by ON public.meeting_sessions(created_by);

-- 2. meeting_session_items table
CREATE TABLE IF NOT EXISTS public.meeting_session_items (
    session_item_id SERIAL PRIMARY KEY,
    session_id INTEGER NOT NULL REFERENCES public.meeting_sessions(session_id) ON DELETE CASCADE,
    task_id INTEGER NOT NULL REFERENCES public.my_tasks(task_id) ON DELETE CASCADE,
    discussion_note TEXT,
    response TEXT,
    decision TEXT,
    next_action TEXT,
    action_owner VARCHAR(255),
    action_due_date DATE,
    item_status VARCHAR(50) NOT NULL DEFAULT 'discussed',
    comment_id INTEGER REFERENCES public.task_comments(comment_id) ON DELETE SET NULL,
    created_by INTEGER REFERENCES public.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    row_exposure_mode_id INTEGER REFERENCES public.row_exposure_modes(exposure_mode_id)
);

CREATE INDEX IF NOT EXISTS idx_meeting_session_items_session ON public.meeting_session_items(session_id);
CREATE INDEX IF NOT EXISTS idx_meeting_session_items_task ON public.meeting_session_items(task_id);
CREATE INDEX IF NOT EXISTS idx_meeting_session_items_status ON public.meeting_session_items(item_status);

-- 3. Register Data Models in Noolva Auto-CRUD
INSERT INTO public.data_models (model_uuid, model_name, display_name, table_name, is_public, is_system_model, is_active, table_alias, model_scope, created_by)
SELECT gen_random_uuid(), 'meeting_sessions', 'Meeting Sessions', 'meeting_sessions', false, false, true, 'ms', 'saas', 2
WHERE NOT EXISTS (SELECT 1 FROM public.data_models WHERE model_name = 'meeting_sessions');

INSERT INTO public.data_models (model_uuid, model_name, display_name, table_name, is_public, is_system_model, is_active, table_alias, model_scope, created_by)
SELECT gen_random_uuid(), 'meeting_session_items', 'Meeting Session Items', 'meeting_session_items', false, false, true, 'msi', 'saas', 2
WHERE NOT EXISTS (SELECT 1 FROM public.data_models WHERE model_name = 'meeting_session_items');

-- 4. Add Meeting/Sessions menu to instance_menus
DO $$
DECLARE
    v_instance_id INTEGER := 1;  -- PKManager instance
    v_created_by INTEGER := 2;   -- admin user
    v_menu_id INTEGER;
BEGIN
    INSERT INTO public.instance_menus (instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by)
    SELECT v_instance_id, 'Meeting/Sessions', '/meeting-sessions', false, 'team', NULL, 7, v_created_by
    WHERE NOT EXISTS (
        SELECT 1 FROM public.instance_menus
        WHERE instance_id = v_instance_id AND menu_title = 'Meeting/Sessions'
    )
    RETURNING id INTO v_menu_id;

    IF v_menu_id IS NULL THEN
        SELECT id INTO v_menu_id FROM public.instance_menus
        WHERE instance_id = v_instance_id AND menu_title = 'Meeting/Sessions'
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
