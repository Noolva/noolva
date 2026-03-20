-- Add/refresh a job template for executing saved Custom Query API endpoints.
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
    'Execute a saved Custom Query API endpoint and return rows',
    'core_function',
    'run_custom_query_endpoint',
    ARRAY['local','remote'],
    300,
    TRUE,
    'parallel',
    0,
    '{
        "type": "object",
        "properties": {
            "endpoint_id": {
                "type": "integer",
                "description": "api_endpoints.endpoint_id of a custom_query endpoint"
            },
            "limit": {
                "type": "integer",
                "minimum": 1,
                "maximum": 1000,
                "default": 100
            },
            "offset": {
                "type": "integer",
                "minimum": 0,
                "default": 0
            },
            "pat": {
                "type": "string",
                "description": "Bearer token / PAT to call the API (optional if CUSTOM_QUERY_PAT env is set)"
            },
            "base_url": {
                "type": "string",
                "description": "Override API base URL; defaults to CUSTOM_QUERY_BASE_URL or API_BASE_URL or localhost:APPLICATION_PORT"
            }
        },
        "required": ["endpoint_id"]
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

