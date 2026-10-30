-- ============================================================================
-- Release 1.0.6 — 14: Commitments Schema and Menu Entry
-- Tracks recurring monthly, weekly, quarterly, yearly financial obligations:
-- 1. Bills & Direct Expenses (Rent, EB bill, Mobile, Internet, Subscriptions)
-- 2. Savings Fund Allocations (Land Purchase, Gold Ring, Health Reserves)
-- 3. Loan EMIs / Repayments
-- Idempotent: safe to re-run.
-- ============================================================================

-- 1. commitments table
CREATE TABLE IF NOT EXISTS public.commitments (
    commitment_id SERIAL PRIMARY KEY,
    created_by INTEGER REFERENCES public.users(user_id),
    idate TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    row_exposure_mode_id INTEGER REFERENCES public.row_exposure_modes(exposure_mode_id),
    title VARCHAR(200) NOT NULL,
    commitment_type VARCHAR(50) NOT NULL DEFAULT 'bill_expense',
    expense_account_id INTEGER REFERENCES public.accounts(account_id) ON DELETE SET NULL,
    fund_id INTEGER REFERENCES public.funds(fund_id) ON DELETE SET NULL,
    payment_account_id INTEGER REFERENCES public.accounts(account_id) ON DELETE SET NULL,
    beneficiary_business_id INTEGER REFERENCES public.businesses(business_id) ON DELETE SET NULL,
    frequency VARCHAR(50) NOT NULL DEFAULT 'monthly',
    due_day INTEGER NOT NULL DEFAULT 1,
    expected_amount NUMERIC(14, 2) NOT NULL DEFAULT 0,
    is_variable BOOLEAN NOT NULL DEFAULT false,
    priority VARCHAR(50) NOT NULL DEFAULT 'high',
    auto_pay BOOLEAN NOT NULL DEFAULT false,
    last_fulfilled_date DATE,
    last_fulfilled_amount NUMERIC(14, 2) DEFAULT 0,
    notes TEXT,
    effective_from DATE DEFAULT CURRENT_DATE,
    is_active BOOLEAN NOT NULL DEFAULT true
);

-- Ensure effective_from column exists if table was already created
ALTER TABLE public.commitments ADD COLUMN IF NOT EXISTS effective_from DATE DEFAULT CURRENT_DATE;

CREATE INDEX IF NOT EXISTS idx_commitments_type ON public.commitments(commitment_type);
CREATE INDEX IF NOT EXISTS idx_commitments_due_day ON public.commitments(due_day);
CREATE INDEX IF NOT EXISTS idx_commitments_expense_account ON public.commitments(expense_account_id);
CREATE INDEX IF NOT EXISTS idx_commitments_fund ON public.commitments(fund_id);
CREATE INDEX IF NOT EXISTS idx_commitments_active ON public.commitments(is_active);

-- 2. Add Commitments to Finance submenu in instance_menus
DO $$
DECLARE
    v_instance_id INTEGER := 1;  -- PKManager instance
    v_created_by INTEGER := 2;   -- admin user
    v_finance_menu_id INTEGER;
    v_commitment_menu_id INTEGER;
BEGIN
    SELECT id INTO v_finance_menu_id FROM public.instance_menus
    WHERE instance_id = v_instance_id AND menu_title = 'Finance' AND parent_id IS NULL
    LIMIT 1;

    INSERT INTO public.instance_menus (instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by)
    SELECT v_instance_id, 'Commitments', '/finance/commitments', false, 'schedule', v_finance_menu_id, 15, v_created_by
    WHERE NOT EXISTS (
        SELECT 1 FROM public.instance_menus
        WHERE instance_id = v_instance_id AND menu_title = 'Commitments'
    )
    RETURNING id INTO v_commitment_menu_id;

    IF v_commitment_menu_id IS NULL THEN
        SELECT id INTO v_commitment_menu_id FROM public.instance_menus
        WHERE instance_id = v_instance_id AND menu_title = 'Commitments'
        LIMIT 1;
    END IF;

    IF v_commitment_menu_id IS NOT NULL THEN
        INSERT INTO public.instance_menu_client_config (instance_menu_id, client_type, render_mode, is_enabled, created_by)
        VALUES (v_commitment_menu_id, 'web', 'web', true, v_created_by)
        ON CONFLICT (instance_menu_id, client_type) DO NOTHING;
    END IF;
END $$;
