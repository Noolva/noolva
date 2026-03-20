-- Replace old auto_crud_internal / auto_crud_remote templates
-- with four operation-based auto-CRUD templates.
-- Safe to run multiple times (DELETE + ON CONFLICT).

-- 1) Remove old generic templates (no-op if they don't exist)
DELETE FROM public.job_templates
WHERE name IN ('auto_crud_internal', 'auto_crud_remote');

-- 2) Insert / upsert new operation-based templates
INSERT INTO public.job_templates
  (name,
   description,
   handler_type,
   handler_function_name,
   runnable_in,
   default_timeout_seconds,
   is_idempotent,
   queue_concurrency_mode,
   queue_concurrency_limit,
   is_active,
   input_schema)
VALUES
  (
    'auto_crud_get_records',
    'Auto-CRUD GET /data-models/auto/{model_name}/records (list/query records)',
    'core_function',
    'run_auto_crud',
    ARRAY['local','remote'],
    300,
    TRUE,      -- GET is idempotent
    'parallel',
    0,
    TRUE,
    '{
      "model_name": "",
      "filters": {},
      "limit": null,
      "offset": null,
      "order_by": [],
      "creator_user_id": null,
      "run_as_user_id": null,
      "company_id": null
    }'::jsonb
  ),
  (
    'auto_crud_post_records',
    'Auto-CRUD POST /data-models/auto/{model_name}/records (create record)',
    'core_function',
    'run_auto_crud',
    ARRAY['local','remote'],
    300,
    FALSE,     -- create is not idempotent
    'parallel',
    0,
    TRUE,
    '{
      "model_name": "",
      "data": {},
      "creator_user_id": null,
      "run_as_user_id": null,
      "company_id": null
    }'::jsonb
  ),
  (
    'auto_crud_put_record',
    'Auto-CRUD PUT /data-models/auto/{model_name}/records/{record_id} (update record)',
    'core_function',
    'run_auto_crud',
    ARRAY['local','remote'],
    300,
    FALSE,     -- update usually not strictly idempotent in this context
    'parallel',
    0,
    TRUE,
    '{
      "model_name": "",
      "record_id": null,
      "data": {},
      "creator_user_id": null,
      "run_as_user_id": null,
      "company_id": null
    }'::jsonb
  ),
  (
    'auto_crud_delete_record',
    'Auto-CRUD DELETE /data-models/auto/{model_name}/records/{record_id} (delete record)',
    'core_function',
    'run_auto_crud',
    ARRAY['local','remote'],
    300,
    FALSE,     -- delete treated as non-idempotent for safety
    'parallel',
    0,
    TRUE,
    '{
      "model_name": "",
      "record_id": null,
      "creator_user_id": null,
      "run_as_user_id": null,
      "company_id": null
    }'::jsonb
  )
ON CONFLICT (name) DO UPDATE
SET
  description = EXCLUDED.description,
  handler_type = EXCLUDED.handler_type,
  handler_function_name = EXCLUDED.handler_function_name,
  runnable_in = EXCLUDED.runnable_in,
  default_timeout_seconds = EXCLUDED.default_timeout_seconds,
  is_idempotent = EXCLUDED.is_idempotent,
  queue_concurrency_mode = EXCLUDED.queue_concurrency_mode,
  queue_concurrency_limit = EXCLUDED.queue_concurrency_limit,
  is_active = TRUE,
  input_schema = EXCLUDED.input_schema;

