-- ============================================================================
-- Release 1.0.6 — 12: Make account_category_id nullable on journal_entries
-- Journal entries link debit and credit accounts, which already classify categories.
-- Idempotent: safe to re-run.
-- ============================================================================

DO $$
BEGIN
    -- 1. Make column nullable on journal_entries table if NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'journal_entries' AND column_name = 'account_category_id'
          AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE public.journal_entries ALTER COLUMN account_category_id DROP NOT NULL;
    END IF;

    -- 2. Update data_model_fields for model_id = 72 (journal_entries)
    UPDATE public.data_model_fields
    SET is_required = false
    WHERE model_id = (SELECT model_id FROM public.data_models WHERE table_name = 'journal_entries' LIMIT 1)
      AND field_name = 'account_category_id';
END $$;
