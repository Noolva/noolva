-- ============================================================================
-- Release 1.0.6 — 10: Bank Accounts Menu Entry
-- Adds Bank Accounts under Finance menu tree in instance_menus for PKManager.
-- Idempotent: safe to re-run.
-- ============================================================================

DO $$
DECLARE
    v_instance_id INTEGER := 1;  -- PKManager instance
    v_created_by INTEGER := 2;   -- admin user
    v_finance_menu_id INTEGER;
    v_bank_menu_id INTEGER;
BEGIN
    SELECT id INTO v_finance_menu_id FROM public.instance_menus
    WHERE instance_id = v_instance_id AND menu_title = 'Finance' AND parent_id IS NULL
    LIMIT 1;

    INSERT INTO public.instance_menus (instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by)
    SELECT v_instance_id, 'Bank Accounts', '/bank-accounts', false, 'bank', v_finance_menu_id, 12, v_created_by
    WHERE NOT EXISTS (
        SELECT 1 FROM public.instance_menus
        WHERE instance_id = v_instance_id AND menu_title = 'Bank Accounts'
    )
    RETURNING id INTO v_bank_menu_id;

    IF v_bank_menu_id IS NULL THEN
        SELECT id INTO v_bank_menu_id FROM public.instance_menus
        WHERE instance_id = v_instance_id AND menu_title = 'Bank Accounts'
        LIMIT 1;
    END IF;

    IF v_bank_menu_id IS NOT NULL THEN
        INSERT INTO public.instance_menu_client_config (instance_menu_id, client_type, render_mode, is_enabled, created_by)
        VALUES (v_bank_menu_id, 'web', 'web', true, v_created_by)
        ON CONFLICT (instance_menu_id, client_type) DO NOTHING;
    END IF;
END $$;
