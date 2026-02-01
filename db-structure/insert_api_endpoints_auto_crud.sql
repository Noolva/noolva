-- insert_api_endpoints_auto_crud.sql
-- Inserts api_endpoints records for auto_crud on all existing data_models.
-- Run after update_old_db_api_endpoints.sql (or on fresh schema).
-- For each model: GET list, POST create, PUT update, DELETE delete.

-- Insert auto_crud endpoints for each data_model (skip if already exists)
INSERT INTO public.api_endpoints (
    path, method, type, related_model_id, reference_model_ids, permission_required, is_builtin, created_by
)
SELECT
    '/data-models/auto/' || dm.model_name || '/records',
    m.method,
    'auto_crud',
    dm.model_id,
    ARRAY[dm.model_id],
    NULL,
    FALSE,
    (SELECT user_id FROM public.users WHERE user_type = 'system' LIMIT 1)
FROM public.data_models dm
CROSS JOIN (VALUES ('GET'), ('POST')) AS m(method)
WHERE dm.is_active = TRUE
  AND NOT EXISTS (
    SELECT 1 FROM public.api_endpoints ae
    WHERE ae.path = '/data-models/auto/' || dm.model_name || '/records'
      AND ae.method = m.method
  )
ON CONFLICT (path, method) DO NOTHING;

-- Insert PUT and DELETE (path includes {record_id})
INSERT INTO public.api_endpoints (
    path, method, type, related_model_id, reference_model_ids, permission_required, is_builtin, created_by
)
SELECT
    '/data-models/auto/' || dm.model_name || '/records/{record_id}',
    m.method,
    'auto_crud',
    dm.model_id,
    ARRAY[dm.model_id],
    NULL,
    FALSE,
    (SELECT user_id FROM public.users WHERE user_type = 'system' LIMIT 1)
FROM public.data_models dm
CROSS JOIN (VALUES ('PUT'), ('DELETE')) AS m(method)
WHERE dm.is_active = TRUE
  AND NOT EXISTS (
    SELECT 1 FROM public.api_endpoints ae
    WHERE ae.path = '/data-models/auto/' || dm.model_name || '/records/{record_id}'
      AND ae.method = m.method
  )
ON CONFLICT (path, method) DO NOTHING;
