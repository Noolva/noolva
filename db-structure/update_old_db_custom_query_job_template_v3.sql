-- Simplify input_schema for the custom_query_endpoint job template.
-- This version drops endpoint_id/pat/base_url from the example payload
-- and just shows a very simple shape for "select" vs "execute" queries.
-- Safe to run multiple times (ON CONFLICT).

INSERT INTO public.job_templates (
    name,
    description,
    handler_type,
    handler_function_name,
    runnable_in,
    default_timeout_seconds,
    is_idempotent,
    queue_concurrency_mode,
    queue_concurrency_limit,
    input_schema
)
VALUES (
    'custom_query_endpoint',
    'Execute a custom SQL query (SELECT or EXECUTE) via existing custom-query logic',
    'core_function',
    'run_custom_query_endpoint',
    ARRAY['local','remote'],
    300,
    TRUE,
    'parallel',
    0,
    '{
      "type": "",
      "query": "",
      "limit": null,
      "offset": null
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
    input_schema = EXCLUDED.input_schema;

