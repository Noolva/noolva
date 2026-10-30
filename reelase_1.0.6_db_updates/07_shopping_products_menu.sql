-- ============================================================================
-- Release 1.0.6 — 07: Shopping & Products instance_menus entry
-- Adds single "Shopping & Products" menu entry to instance_menus for PKManager instance.
-- Buttons/modules live on the /shopping page itself (no child menus).
-- Idempotent: safe to re-run.
-- ============================================================================

DO $$
DECLARE
    v_instance_id INTEGER := 1;  -- PKManager instance
    v_created_by INTEGER := 2;   -- admin user
BEGIN
    -- Single parent menu: "Shopping & Products" (routes to /shopping page)
    INSERT INTO public.instance_menus (instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by)
    SELECT v_instance_id, 'Shopping & Products', '/shopping', false, 'shopping', NULL, 11, v_created_by
    WHERE NOT EXISTS (
        SELECT 1 FROM public.instance_menus
        WHERE instance_id = v_instance_id AND menu_title = 'Shopping & Products' AND parent_id IS NULL
    );

    -- Client config for web (render_mode = 'web', enabled)
    INSERT INTO public.instance_menu_client_config (instance_menu_id, client_type, render_mode, is_enabled, created_by)
    SELECT m.id, 'web', 'web', true, v_created_by
    FROM public.instance_menus m
    WHERE m.instance_id = v_instance_id
      AND m.menu_title = 'Shopping & Products'
      AND m.parent_id IS NULL
    ON CONFLICT (instance_menu_id, client_type) DO NOTHING;
END $$;
