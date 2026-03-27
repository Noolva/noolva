-- Mobile agent: FCM registration + pending task queue for alarm sync (FCM wake → pull).
-- Run on existing databases after pulling code that adds utils/fcm.py and routes/mobile_agent.py.

CREATE TABLE IF NOT EXISTS public.agent_device_registrations (
    registration_id BIGSERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    company_id INTEGER REFERENCES public.companies(company_id) ON DELETE SET NULL,
    device_id VARCHAR(512) NOT NULL,
    fcm_token TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_agent_device_user_device UNIQUE (user_id, device_id)
);

CREATE INDEX IF NOT EXISTS idx_agent_device_registrations_device_id
    ON public.agent_device_registrations (device_id);

CREATE INDEX IF NOT EXISTS idx_agent_device_registrations_company_id
    ON public.agent_device_registrations (company_id);

CREATE TABLE IF NOT EXISTS public.agent_pending_tasks (
    pending_task_id BIGSERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    company_id INTEGER REFERENCES public.companies(company_id) ON DELETE SET NULL,
    device_id VARCHAR(512) NOT NULL,
    task_type VARCHAR(64) NOT NULL DEFAULT 'alarm',
    task_id TEXT NOT NULL,
    message TEXT,
    payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_agent_pending_tasks_user_device
    ON public.agent_pending_tasks (user_id, device_id, created_at);
