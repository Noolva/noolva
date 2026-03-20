-- Add template_category to job_templates (task | workflow | system).
-- Safe to run multiple times (ADD COLUMN IF NOT EXISTS, constraint once).

ALTER TABLE public.job_templates
ADD COLUMN IF NOT EXISTS template_category TEXT DEFAULT 'task';

UPDATE public.job_templates
SET template_category = 'task'
WHERE template_category IS NULL;

-- Constraint: only allowed values (idempotent: skip if already exists)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'job_templates_template_category_check'
      AND conrelid = 'public.job_templates'::regclass
  ) THEN
    ALTER TABLE public.job_templates
    ADD CONSTRAINT job_templates_template_category_check
    CHECK (template_category IN ('task', 'workflow', 'system'));
  END IF;
END $$;
