-- ============================================================================
-- Release 1.0.6 — 13: Store Plans and Store Plan Items Schema
-- Supports planned shopping trips (weekend, date, place, seller, planned items,
-- and fund readiness / cash availability).
-- Idempotent: safe to re-run.
-- ============================================================================

-- 1. purchase_plans table (Trip header: date, store/place, cash ready, budget)
CREATE TABLE IF NOT EXISTS public.purchase_plans (
    plan_id SERIAL PRIMARY KEY,
    created_by INTEGER REFERENCES public.users(user_id),
    idate TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    row_exposure_mode_id INTEGER REFERENCES public.row_exposure_modes(exposure_mode_id),
    plan_title VARCHAR(200) NOT NULL,
    planned_date DATE NOT NULL,
    business_id INTEGER REFERENCES public.businesses(business_id) ON DELETE SET NULL,
    place_name VARCHAR(150),
    readiness_status VARCHAR(50) NOT NULL DEFAULT 'planning',
    is_cash_ready BOOLEAN NOT NULL DEFAULT false,
    payment_account_id INTEGER REFERENCES public.bank_accounts(bank_account_id) ON DELETE SET NULL,
    estimated_budget NUMERIC(14, 2) DEFAULT 0,
    actual_amount NUMERIC(14, 2) DEFAULT 0,
    priority VARCHAR(50) DEFAULT 'normal',
    journal_entry_id INTEGER REFERENCES public.journal_entries(journal_entry_id) ON DELETE SET NULL,
    items_json JSONB DEFAULT '[]'::jsonb,
    notes TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true
);

CREATE INDEX IF NOT EXISTS idx_purchase_plans_date ON public.purchase_plans(planned_date);
CREATE INDEX IF NOT EXISTS idx_purchase_plans_business ON public.purchase_plans(business_id);
CREATE INDEX IF NOT EXISTS idx_purchase_plans_status ON public.purchase_plans(readiness_status);

-- 2. purchase_plan_items table (Itemized shopping list per plan)
CREATE TABLE IF NOT EXISTS public.purchase_plan_items (
    plan_item_id SERIAL PRIMARY KEY,
    created_by INTEGER REFERENCES public.users(user_id),
    idate TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    row_exposure_mode_id INTEGER REFERENCES public.row_exposure_modes(exposure_mode_id),
    plan_id INTEGER NOT NULL REFERENCES public.purchase_plans(plan_id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES public.products(products_id),
    business_product_id INTEGER REFERENCES public.business_products(business_product_id) ON DELETE SET NULL,
    business_id INTEGER REFERENCES public.businesses(business_id) ON DELETE SET NULL,
    quantity NUMERIC(12, 3) NOT NULL DEFAULT 1,
    unit VARCHAR(50) NOT NULL DEFAULT 'piece',
    estimated_price NUMERIC(14, 2) DEFAULT 0,
    estimated_subtotal NUMERIC(14, 2) DEFAULT 0,
    is_purchased BOOLEAN NOT NULL DEFAULT false,
    actual_price NUMERIC(14, 2) DEFAULT 0,
    notes TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true
);

CREATE INDEX IF NOT EXISTS idx_purchase_plan_items_plan ON public.purchase_plan_items(plan_id);
CREATE INDEX IF NOT EXISTS idx_purchase_plan_items_product ON public.purchase_plan_items(product_id);
