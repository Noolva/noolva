-- Add Personal Access Tokens table and menu for existing databases.
-- Run this if your DB was created before PAT was added to the schema.

CREATE TABLE IF NOT EXISTS public.personal_access_tokens (
    pat_id SERIAL PRIMARY KEY,
    pat_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    user_id INTEGER NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    company_id INTEGER REFERENCES public.companies(company_id) ON DELETE SET NULL,
    name VARCHAR(200) NOT NULL,
    token_hash VARCHAR(64) NOT NULL UNIQUE,
    scopes_json JSONB DEFAULT '[]'::jsonb,
    expires_at TIMESTAMPTZ NOT NULL,
    last_used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_personal_access_tokens_user ON public.personal_access_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_personal_access_tokens_token_hash ON public.personal_access_tokens(token_hash);
CREATE INDEX IF NOT EXISTS idx_personal_access_tokens_expires ON public.personal_access_tokens(expires_at);

-- Add "Personal Access Tokens" menu under Organization app (if not exists)
INSERT INTO public.menus (menu_title, parent_id, type, route_path, icon, app_id, scope, is_builtin, order_no, created_by)
SELECT 'Personal Access Tokens', NULL, 'item', 'personal_access_tokens', 'key', a.app_id, 'saas', TRUE, 86, (SELECT user_id FROM public.users WHERE user_type = 'system' LIMIT 1)
FROM public.apps a
WHERE a.app_name = 'organization' AND a.tenant_id IS NULL AND a.company_id IS NULL
  AND NOT EXISTS (SELECT 1 FROM public.menus m WHERE m.app_id = a.app_id AND m.menu_title = 'Personal Access Tokens' AND m.parent_id IS NULL)
LIMIT 1;
