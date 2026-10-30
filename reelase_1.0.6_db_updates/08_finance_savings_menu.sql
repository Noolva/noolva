-- ============================================================================
-- Release 1.0.6 — 08: Finance & Savings menu entries
-- Adds Finance and Savings & Products menu trees to instance_menus for PKManager.
-- Data tables already exist — no schema changes needed.
-- Idempotent: safe to re-run.
-- ============================================================================

DO $$
DECLARE
    v_instance_id INTEGER := 1;  -- PKManager instance
    v_created_by INTEGER := 2;   -- admin user
    v_finance_menu_id INTEGER;
    v_savings_menu_id INTEGER;
BEGIN
    -- 1. Finance parent menu
    INSERT INTO public.instance_menus (instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by)
    SELECT v_instance_id, 'Finance', '/finance', false, 'wallet', NULL, 12, v_created_by
    WHERE NOT EXISTS (
        SELECT 1 FROM public.instance_menus
        WHERE instance_id = v_instance_id AND menu_title = 'Finance' AND parent_id IS NULL
    )
    RETURNING id INTO v_finance_menu_id;

    IF v_finance_menu_id IS NULL THEN
        SELECT id INTO v_finance_menu_id FROM public.instance_menus
        WHERE instance_id = v_instance_id AND menu_title = 'Finance' AND parent_id IS NULL
        LIMIT 1;
    END IF;

    -- Finance child menus
    INSERT INTO public.instance_menus (instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by)
    SELECT v_instance_id, 'My Accounts', '/finance/accounts', false, 'idcard', v_finance_menu_id, 12, v_created_by
    WHERE NOT EXISTS (
        SELECT 1 FROM public.instance_menus
        WHERE instance_id = v_instance_id AND menu_title = 'My Accounts' AND parent_id = v_finance_menu_id
    );

    INSERT INTO public.instance_menus (instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by)
    SELECT v_instance_id, 'Account Categories', '/finance/categories', false, 'tags', v_finance_menu_id, 13, v_created_by
    WHERE NOT EXISTS (
        SELECT 1 FROM public.instance_menus
        WHERE instance_id = v_instance_id AND menu_title = 'Account Categories' AND parent_id = v_finance_menu_id
    );

    INSERT INTO public.instance_menus (instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by)
    SELECT v_instance_id, 'Journal Entries', '/finance/journal', false, 'book', v_finance_menu_id, 14, v_created_by
    WHERE NOT EXISTS (
        SELECT 1 FROM public.instance_menus
        WHERE instance_id = v_instance_id AND menu_title = 'Journal Entries' AND parent_id = v_finance_menu_id
    );

    -- 2. Savings & Funds parent menu
    INSERT INTO public.instance_menus (instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by)
    SELECT v_instance_id, 'Savings & Funds', '/savings', false, 'savings', NULL, 13, v_created_by
    WHERE NOT EXISTS (
        SELECT 1 FROM public.instance_menus
        WHERE instance_id = v_instance_id AND menu_title = 'Savings & Funds' AND parent_id IS NULL
    )
    RETURNING id INTO v_savings_menu_id;

    IF v_savings_menu_id IS NULL THEN
        SELECT id INTO v_savings_menu_id FROM public.instance_menus
        WHERE instance_id = v_instance_id AND menu_title = 'Savings & Funds' AND parent_id IS NULL
        LIMIT 1;
    END IF;

    -- Savings & Funds child menus
    INSERT INTO public.instance_menus (instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by)
    SELECT v_instance_id, 'My Funds', '/savings/funds', false, 'bank', v_savings_menu_id, 13, v_created_by
    WHERE NOT EXISTS (
        SELECT 1 FROM public.instance_menus
        WHERE instance_id = v_instance_id AND menu_title = 'My Funds' AND parent_id = v_savings_menu_id
    );

    INSERT INTO public.instance_menus (instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by)
    SELECT v_instance_id, 'Fund Transactions', '/savings/transactions', false, 'transaction', v_savings_menu_id, 14, v_created_by
    WHERE NOT EXISTS (
        SELECT 1 FROM public.instance_menus
        WHERE instance_id = v_instance_id AND menu_title = 'Fund Transactions' AND parent_id = v_savings_menu_id
    );

    -- 3. Client config for web on all new menus
    INSERT INTO public.instance_menu_client_config (instance_menu_id, client_type, render_mode, is_enabled, created_by)
    SELECT m.id, 'web', 'web', true, v_created_by
    FROM public.instance_menus m
    WHERE m.instance_id = v_instance_id
      AND m.menu_title IN ('Finance', 'My Accounts', 'Account Categories', 'Journal Entries',
                           'Savings & Funds', 'My Funds', 'Fund Transactions')
    ON CONFLICT (instance_menu_id, client_type) DO NOTHING;
END $$;
