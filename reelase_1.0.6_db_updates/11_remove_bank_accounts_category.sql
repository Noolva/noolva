-- ============================================================================
-- Release 1.0.6 — 11: Remove account_category_id from bank_accounts
-- Bank accounts are classified by account_type (savings, current, cash, etc.).
-- Chart of accounts (accounts table) retains account_category_id.
-- Idempotent: safe to re-run.
-- ============================================================================

DO $$
BEGIN
    -- 1. Remove from data_model_fields for model_id = 70 (bank_accounts)
    DELETE FROM public.data_model_fields
    WHERE model_id = (SELECT model_id FROM public.data_models WHERE table_name = 'bank_accounts' LIMIT 1)
      AND field_name = 'account_category_id';

    -- 2. Drop column from bank_accounts table if exists
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'bank_accounts' AND column_name = 'account_category_id'
    ) THEN
        ALTER TABLE public.bank_accounts DROP COLUMN account_category_id;
    END IF;
END $$;
