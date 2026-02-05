-- 01_core_identity.sql
-- Classification: Identity & User Management
-- Description: Establishes the core User entity and authentication structure.
-- Relationships: All other modules reference this file.

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================================
-- 1. Users Table
-- ==========================================
-- The central entity for all individuals accessing the platform.
CREATE TABLE public.users (
    user_id SERIAL PRIMARY KEY,
    user_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    username VARCHAR(100) NOT NULL UNIQUE, -- Email or Login ID
    password VARCHAR(120) NOT NULL, -- Hashed password
    
    -- Profile Info
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(100), -- Explicit email field
    phone VARCHAR(20),
    avatar_url TEXT,
    
    -- System Role Triggers
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('saas_admin', 'saas_employee', 'saas_reseller', 'saas_promoter', 'tenant_admin', 'tenant_user', 'system')),
    is_super_admin BOOLEAN DEFAULT FALSE, -- Root access
    
    -- Polymorphic Reference to Profile Tables
    ref_table_column VARCHAR(100), -- e.g., 'saas_employees.employee_id'
    ref_id INTEGER,
    ref_uuid UUID,
    
    -- Account Status
    active_status SMALLINT DEFAULT 1 NOT NULL CHECK (active_status IN (0, 1, 2)), -- 0:Inactive, 1:Active, 2:Suspended
    last_login TIMESTAMPTZ,
    
    -- Two-Factor Authentication (per-user; global enable_2fa in settings table)
    enable_2fa BOOLEAN DEFAULT FALSE,
    mfa_secret VARCHAR(255), -- TOTP secret for authenticator app (stored encrypted in production)
    
    -- Session idle lock: NULL = use global setting; -1 = no lock; >0 = lock after N minutes of inactivity
    idle_timeout_minutes INTEGER DEFAULT NULL,
    
    -- Auditing
    deleted_at TIMESTAMPTZ, -- Soft delete support
    created_by INTEGER REFERENCES public.users(user_id),
    idate TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Indexes
CREATE INDEX idx_users_username ON public.users(username);
CREATE INDEX idx_users_active_status ON public.users(active_status);
-- 02_tenants_and_companies.sql
-- Classification: Organization & Multi-Tenancy
-- Description: Defines the tenant structure (Tenants -> Companies) and how users are grouped within them.
-- Dependencies: users (01_core_identity.sql)

-- ==========================================
-- 0. Tenants (New Top-Level Entity)
-- ==========================================
-- Represents the Billing/Subscription Account. One Tenant can have multiple Companies.
CREATE TABLE public.tenants (
    tenant_id SERIAL PRIMARY KEY,
    tenant_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    
    tenant_name VARCHAR(200) NOT NULL,
    contact_email VARCHAR(100),
    
    -- Billing Info
    subscription_plan VARCHAR(50) DEFAULT 'trial', -- 'free', 'pro', 'enterprise'
    subscription_status VARCHAR(20) DEFAULT 'active',
    subscription_expires_at TIMESTAMPTZ,
    
    is_active BOOLEAN DEFAULT TRUE,
    
    created_by INTEGER REFERENCES public.users(user_id),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- ==========================================
-- 1. Companies / Organizations
-- ==========================================
-- The Organizational Entity. Belongs to a Tenant.
-- Roles and Permissions are scoped here.
CREATE TABLE public.companies (
    company_id SERIAL PRIMARY KEY,
    company_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    
    tenant_id INTEGER NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE CASCADE,
    
    company_name VARCHAR(200) NOT NULL,
    company_code VARCHAR(50) NOT NULL, -- Subdomain/Path identifier (Unique per Tenant?)
    -- Ideally unique globally if used as subdomain, or unique per tenant if used as path.
    -- Keeping UNIQUE constraint globally for safety if used as subdomain.
    
    domain VARCHAR(100), -- e.g. "acme.noolva.com"
    logo_url TEXT,
    branding_config JSONB, 
    
    parent_company_id INTEGER REFERENCES public.companies(company_id), -- Hierarchy within Tenant?
    
    is_default BOOLEAN DEFAULT FALSE, -- Default company for the tenant
    is_active BOOLEAN DEFAULT TRUE,
    
    created_by INTEGER REFERENCES public.users(user_id),
    idate TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,

    UNIQUE(company_code) 
);

-- ==========================================
-- 2. User Companies Association
-- ==========================================
-- Links Users <-> Companies. Access to Tenant is derived from here.
CREATE TABLE public.user_companies (
    user_company_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    company_id INTEGER NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    
    is_primary BOOLEAN DEFAULT FALSE, -- Default login context
    is_active BOOLEAN DEFAULT TRUE,
    
    joined_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, company_id)
);

-- ==========================================
-- 2a. User Sessions Table
-- ==========================================
-- Tracks active user sessions for multi-account support
CREATE TABLE public.user_sessions (
    session_id SERIAL PRIMARY KEY,
    session_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    user_id INTEGER NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    company_id INTEGER REFERENCES public.companies(company_id) ON DELETE CASCADE,
    
    -- Session metadata
    login_method VARCHAR(20) NOT NULL, -- 'password', 'google_oauth', 'mfa'
    login_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ,
    
    -- Client info
    device_info JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    
    is_active BOOLEAN DEFAULT TRUE,
    
    created_by INTEGER REFERENCES public.users(user_id)
);

-- Indexes for user_sessions
CREATE INDEX idx_user_sessions_user ON public.user_sessions(user_id);
CREATE INDEX idx_user_sessions_active ON public.user_sessions(is_active);
CREATE INDEX idx_user_sessions_company ON public.user_sessions(company_id);
CREATE INDEX idx_user_sessions_expires ON public.user_sessions(expires_at);

-- ==========================================
-- 2b. User Account Profiles Table
-- ==========================================
-- Stores multiple account contexts per user
CREATE TABLE public.user_account_profiles (
    profile_id SERIAL PRIMARY KEY,
    profile_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    user_id INTEGER NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    company_id INTEGER REFERENCES public.companies(company_id) ON DELETE CASCADE,
    
    -- Profile metadata
    profile_name VARCHAR(100), -- "Work Account", "Personal"
    is_default BOOLEAN DEFAULT FALSE,
    
    -- Context-specific settings
    preferences JSONB DEFAULT '{}'::jsonb,
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_used TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, company_id, profile_name)
);

-- Indexes for user_account_profiles
CREATE INDEX idx_user_account_profiles_user ON public.user_account_profiles(user_id);
CREATE INDEX idx_user_account_profiles_company ON public.user_account_profiles(company_id);
CREATE INDEX idx_user_account_profiles_default ON public.user_account_profiles(user_id, is_default) WHERE is_default = TRUE;

-- ==========================================
-- 3. User Groups
-- ==========================================
CREATE TABLE public.user_groups (
    group_id SERIAL PRIMARY KEY,
    group_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    
    group_name VARCHAR(100) NOT NULL,
    group_description TEXT,
    
    company_id INTEGER NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    
    created_by INTEGER REFERENCES public.users(user_id),
    idate TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- ==========================================
-- 4. User Group Members
-- ==========================================
CREATE TABLE public.user_group_members (
    member_id SERIAL PRIMARY KEY,
    group_id INTEGER NOT NULL REFERENCES public.user_groups(group_id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    
    added_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 5. Teams
-- ==========================================
CREATE TABLE public.teams (
    team_id SERIAL PRIMARY KEY,
    team_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    
    team_name VARCHAR(100) NOT NULL,
    team_description TEXT,
    
    company_id INTEGER NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    parent_team_id INTEGER REFERENCES public.teams(team_id), 
    manager_id INTEGER REFERENCES public.users(user_id),
    
    created_by INTEGER REFERENCES public.users(user_id),
    idate TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- ==========================================
-- 6. Team Members
-- ==========================================
CREATE TABLE public.user_teams (
    user_team_id SERIAL PRIMARY KEY,
    team_id INTEGER NOT NULL REFERENCES public.teams(team_id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    
    role_in_team VARCHAR(50), 
    joined_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_tenants_uuid ON public.tenants(tenant_uuid);
CREATE INDEX idx_companies_tenant ON public.companies(tenant_id);
CREATE INDEX idx_companies_uuid ON public.companies(company_uuid);
CREATE INDEX idx_user_companies_uid ON public.user_companies(user_id);
CREATE INDEX idx_user_companies_cid ON public.user_companies(company_id);
CREATE INDEX idx_groups_company ON public.user_groups(company_id);
CREATE INDEX idx_teams_company ON public.teams(company_id);


-- 03_apps_and_modules.sql
-- Classification: Platform Metadata & Structural Definitions
-- Description: Defines the building blocks of the SaaS: Apps, Modules, Features, Menus.
--              Consolidated Schema: No separate "tenant_" tables; Cloning is handled via self-referencing FKs.
-- Dependencies: users (01_core_identity.sql), tenants, companies (02_tenants_and_companies.sql)

-- ==========================================
-- 1. Apps Table
-- ==========================================
-- Represents the top-level deployable units.
-- Scoped to Tenant (subscription) or optionally a specific Company.
CREATE TABLE public.apps (
    app_id SERIAL PRIMARY KEY,
    app_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    
    app_name VARCHAR(100) NOT NULL, -- Logical ID
    app_title VARCHAR(150) NOT NULL,
    app_image_url TEXT,
    app_description TEXT,
    
    -- Multi-Tenancy / Cloning
    -- FKs to 02_tenants_and_companies.sql
    tenant_id INTEGER REFERENCES public.tenants(tenant_id) ON DELETE CASCADE,  -- If SET, belongs to this Tenant. If NULL, System/Global App.
    company_id INTEGER REFERENCES public.companies(company_id) ON DELETE SET NULL, -- If SET, restricted to this specific Company.
    
    cloned_from_app_id INTEGER REFERENCES public.apps(app_id) ON DELETE SET NULL,
    
    -- Flags
    is_saas_default BOOLEAN DEFAULT FALSE, 
    is_tenant_default BOOLEAN DEFAULT FALSE, 
    is_store_app BOOLEAN DEFAULT FALSE, 
    is_builtin BOOLEAN DEFAULT FALSE, 
    is_active BOOLEAN DEFAULT TRUE,
    
    order_no INTEGER DEFAULT 0,
    
    created_by INTEGER REFERENCES public.users(user_id),
    idate TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    -- Unique app name per scope
    CONSTRAINT unique_app_per_tenant_scope UNIQUE NULLS NOT DISTINCT (tenant_id, company_id, app_name)
);

-- ==========================================
-- 2. Modules Table
-- ==========================================
CREATE TABLE public.modules (
    module_id SERIAL PRIMARY KEY,
    module_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    
    module_code VARCHAR(50) NOT NULL, 
    module_name VARCHAR(100) NOT NULL,
    
    app_id INTEGER NOT NULL REFERENCES public.apps(app_id) ON DELETE CASCADE,
    cloned_from_module_id INTEGER REFERENCES public.modules(module_id) ON DELETE SET NULL,
    
    description TEXT,
    icon VARCHAR(50),
    
    is_builtin BOOLEAN DEFAULT FALSE,
    order_no INTEGER DEFAULT 0,
    
    created_by INTEGER REFERENCES public.users(user_id),
    idate TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,

    UNIQUE(app_id, module_code)
);

-- ==========================================
-- 3. Module Features Table
-- ==========================================
CREATE TABLE public.module_features (
    module_feature_id SERIAL PRIMARY KEY,
    module_feature_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    
    feature_code VARCHAR(100) NOT NULL, -- e.g. "invoices.create"
    feature_name VARCHAR(150) NOT NULL,
    
    module_id INTEGER NOT NULL REFERENCES public.modules(module_id) ON DELETE CASCADE,
    cloned_from_feature_id INTEGER REFERENCES public.module_features(module_feature_id) ON DELETE SET NULL,
    
    type VARCHAR(50) DEFAULT 'page', -- 'page', 'action', 'widget'
    
    -- Security Scopes
    allowed_table_columns TEXT[], 
    
    is_builtin BOOLEAN DEFAULT FALSE,
    
    created_by INTEGER REFERENCES public.users(user_id),
    idate TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,

    UNIQUE(module_id, feature_code)
);

-- ==========================================
-- 4. Menus Table
-- ==========================================
CREATE TABLE public.menus (
    menu_id SERIAL PRIMARY KEY,
    menu_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    
    menu_title VARCHAR(150) NOT NULL,
    parent_id INTEGER REFERENCES public.menus(menu_id) ON DELETE CASCADE,
    
    type VARCHAR(20) DEFAULT 'item', 
    route_path VARCHAR(150),
    icon VARCHAR(100), -- Stores icon code like "fa:heart", "antd:download", "smily:thanks", "custom:myhome"
    
    -- Links
    module_feature_id INTEGER REFERENCES public.module_features(module_feature_id) ON DELETE SET NULL, 
    app_id INTEGER REFERENCES public.apps(app_id) ON DELETE CASCADE, 
    
    -- View Connection (FK connected later)
    view_id INTEGER, 
    
    -- Dynamic Context
    scope VARCHAR(20) DEFAULT 'tenant', -- 'saas', 'tenant', 'both'
    
    is_builtin BOOLEAN DEFAULT FALSE,
    
    order_no INTEGER DEFAULT 0,
    is_hidden BOOLEAN DEFAULT FALSE,
    
    created_by INTEGER REFERENCES public.users(user_id),
    idate TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- indexes
CREATE INDEX idx_apps_tenant ON public.apps(tenant_id);
CREATE INDEX idx_apps_company ON public.apps(company_id);
CREATE INDEX idx_modules_app ON public.modules(app_id);
CREATE INDEX idx_module_features_module ON public.module_features(module_id);
CREATE INDEX idx_menus_app ON public.menus(app_id);
-- 04_roles_and_permissions.sql
-- Classification: Security & Access Control
-- Description: Defines the Role-Based Access Control system, including Roles, Permissions (Menu/Feature/Field), and User assignments.
-- Dependencies: users, companies, menus, modules, module_features, data_models

-- ==========================================
-- 1. Roles
-- ==========================================
-- A collection of permissions. Can be System-wide (SAAS Admin) or Company-specific.
CREATE TABLE public.roles (
    role_id SERIAL PRIMARY KEY,
    role_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    
    role_name VARCHAR(100) NOT NULL, -- "Admin", "Manager"
    role_key VARCHAR(100) NOT NULL,  -- "admin", "org_manager" (Standardized key)
    role_description TEXT,
    
    company_id INTEGER REFERENCES public.companies(company_id) ON DELETE CASCADE, -- if null, role is tenant-wide
    is_system_role BOOLEAN DEFAULT FALSE, -- Predefined roles that cannot be deleted
    
    created_by INTEGER REFERENCES public.users(user_id),
    idate TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    UNIQUE(company_id, role_key)
);

-- ==========================================
-- 2. User Roles Assignment
-- ==========================================
-- Assigns a User to a Role within the context of a Company.
CREATE TABLE public.user_roles (
    user_role_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    role_id INTEGER NOT NULL REFERENCES public.roles(role_id) ON DELETE CASCADE,
    company_id INTEGER REFERENCES public.companies(company_id) ON DELETE CASCADE, -- Must match Role's company
    
    assigned_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    assigned_by INTEGER REFERENCES public.users(user_id)
);

-- ==========================================
-- 3. Role Module Features (Capabilities)
-- ==========================================
-- Grants granular access to specific Module Features (Logic/Pages) for a Role.
CREATE TABLE public.role_module_features (
    role_module_feature_id SERIAL PRIMARY KEY,
    role_id INTEGER NOT NULL REFERENCES public.roles(role_id) ON DELETE CASCADE,
    
    module_feature_id INTEGER NOT NULL REFERENCES public.module_features(module_feature_id) ON DELETE CASCADE,
    
    is_granted BOOLEAN DEFAULT TRUE,
    
    granted_by INTEGER REFERENCES public.users(user_id),
    granted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(role_id, module_feature_id)
);

-- ==========================================
-- 4. User Module Features (Explicit Overrides)
-- ==========================================
-- Grants granular access to specific Module Features for a User (override or addition).
CREATE TABLE public.user_module_features (
    user_module_feature_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    
    module_feature_id INTEGER NOT NULL REFERENCES public.module_features(module_feature_id) ON DELETE CASCADE,
    
    is_granted BOOLEAN DEFAULT TRUE,
    expiration TIMESTAMPTZ,
    
    granted_by INTEGER REFERENCES public.users(user_id),
    granted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, module_feature_id)
);

-- ==========================================
-- 5. Menu Permissions (Visibility)
-- ==========================================
-- Overrides default menu visibility.
CREATE TABLE public.menu_permissions (
    menu_permission_id SERIAL PRIMARY KEY,
    menu_id INTEGER NOT NULL REFERENCES public.menus(menu_id) ON DELETE CASCADE,
    role_id INTEGER NOT NULL REFERENCES public.roles(role_id) ON DELETE CASCADE,
    
    can_view BOOLEAN DEFAULT TRUE,
    
    UNIQUE(menu_id, role_id)
);

-- Indexes
CREATE INDEX idx_roles_company ON public.roles(company_id);
CREATE INDEX idx_user_roles_user ON public.user_roles(user_id);
CREATE INDEX idx_role_module_features_role ON public.role_module_features(role_id);
CREATE INDEX idx_user_module_features_user ON public.user_module_features(user_id);
-- 05_data_models.sql
-- Classification: Data Engine & Dynamic CRUD
-- Description: Defines Data Models (merged concept of Tables + Models) and their Fields.
-- dependencies: apps, roles

-- ==========================================
-- 0. Enum Types (Shared)
-- ==========================================
CREATE TYPE public.encryption_method_enum AS ENUM ('none', 'aes', 'xor_cipher');
CREATE TYPE public.model_scope_enum AS ENUM ('saas', 'tenant', 'both');

-- ==========================================
-- 1. Data Models (Merged Model Registry + Tables)
-- ==========================================
CREATE TABLE public.data_models (
    model_id SERIAL PRIMARY KEY,
    model_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    
    -- Ownership/Scope
    app_id INTEGER REFERENCES public.apps(app_id) ON DELETE CASCADE, 
    -- Note: If app_id is NULL, it might be a global system model, but usually linked to an App.
    
    model_name VARCHAR(100) NOT NULL, -- Logical Identifier
    display_name VARCHAR(100), -- Human readable
    
    table_name VARCHAR(100) NOT NULL, -- Physical table in Postgres
    table_alias VARCHAR(50), -- Short alias for queries/joins, e.g. "student_course" => "sc"
    
    -- Metadata (from Tables)
    model_scope public.model_scope_enum DEFAULT 'saas' NOT NULL,
    is_public BOOLEAN DEFAULT FALSE,
    is_system_model BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    description TEXT,
    
    created_by INTEGER REFERENCES public.users(user_id),
    idate TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    UNIQUE(app_id, model_name)
);

-- ==========================================
-- 1.4 UI Component Types (Visual Building Blocks)
-- ==========================================
CREATE TABLE public.ui_component_types (
    component_type_id SERIAL PRIMARY KEY,
    type_code VARCHAR(50) NOT NULL UNIQUE, -- 'row', 'col', 'text', 'button', 'table'
    type_name VARCHAR(100) NOT NULL,
    
    category VARCHAR(50) DEFAULT 'basic', -- 'layout', 'input', 'display', 'action', 'container'
    
    -- Defines the inputs this component accepts (visual props)
    -- e.g. { "span": "number", "gutter": "number", "label": "string" }
    props_schema_json JSONB DEFAULT '{}'::jsonb, 
    
    is_system BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 1.5 Field Types Dictionary
-- ==========================================
CREATE TABLE public.field_types (
    field_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL UNIQUE,  -- 'Text', 'Currency'
    type_code VARCHAR(50) NOT NULL UNIQUE, -- 'text', 'currency'
    
    category VARCHAR(50) DEFAULT 'basic', -- 'basic', 'advanced', 'relational', 'media'
    actual_db_type VARCHAR(50) NOT NULL, -- 'VARCHAR', 'JSONB', 'NUMERIC'
    
    -- UI Linkage
    default_component_type_id INTEGER REFERENCES public.ui_component_types(component_type_id),
    
    default_props_json JSONB DEFAULT '{}'::jsonb, -- Default config schema
    icon VARCHAR(50), 
    input_type_image VARCHAR(255), -- Path to SVG image for field type identification
    
    order_no INTEGER DEFAULT 0, -- Order for displaying field types in UI
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 1.6 Collections (Reusable Option Sets)
-- ==========================================
CREATE TABLE public.collections (
    collection_id SERIAL PRIMARY KEY,
    collection_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    
    collection_name VARCHAR(100) NOT NULL,
    collection_code VARCHAR(100) NOT NULL, -- e.g., 'global_countries', 'org_statuses'
    
    -- Scoping: NULL = Global System Collection, SET = Tenant Specific
    tenant_id INTEGER REFERENCES public.tenants(tenant_id) ON DELETE CASCADE,
    
    -- Field type linkage and config (replaces items_json)
    field_type_id INTEGER REFERENCES public.field_types(field_type_id) ON DELETE SET NULL,
    field_config_json JSONB NOT NULL DEFAULT '{}'::jsonb, -- e.g. { "items": [{ "label": "A", "value": "a" }] }
    
    is_system BOOLEAN DEFAULT FALSE, -- If true, locked from specific edits
    
    created_by INTEGER REFERENCES public.users(user_id),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(tenant_id, collection_code) -- Unique code per tenant (or global if tenant is null)
);

CREATE INDEX idx_collections_field_type ON public.collections(field_type_id);

-- ==========================================
-- 1.7 Icons Table
-- ==========================================
-- Stores icons from FontAwesome, Ant Design, Smilies, and Custom SVG icons
-- Supports tag-based search and categorization
CREATE TABLE public.icons (
    icon_id SERIAL PRIMARY KEY,
    icon_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    
    -- Icon identifier (e.g., "fa:heart", "antd:download", "smily:thanks", "custom:myhome")
    icon_code VARCHAR(100) NOT NULL UNIQUE,
    
    -- Icon type: 'fa' (FontAwesome), 'antd' (Ant Design), 'smily' (Emoji/Smiley), 'custom' (SVG)
    icon_type VARCHAR(20) NOT NULL CHECK (icon_type IN ('fa', 'antd', 'smily', 'custom')),
    
    -- Display name
    icon_name VARCHAR(150) NOT NULL,
    
    -- Category for grouping (e.g., 'navigation', 'actions', 'social', 'business', 'emotions')
    category VARCHAR(50) NOT NULL,
    
    -- Description
    description TEXT,
    
    -- Tags for search (stored as array for easy querying)
    tags TEXT[] DEFAULT '{}',
    
    -- Icon-specific data
    -- For FA: stores the FA class name (e.g., "fas fa-heart")
    -- For Antd: stores the component name (e.g., "HeartOutlined")
    -- For Smily: stores the emoji or unicode (e.g., "😊" or "thanks")
    -- For Custom: stores SVG path or reference
    icon_data JSONB DEFAULT '{}'::jsonb,
    
    -- Popularity/Usage tracking
    usage_count INTEGER DEFAULT 0,
    is_popular BOOLEAN DEFAULT FALSE,
    is_free BOOLEAN DEFAULT TRUE, -- All icons in this table are free
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Metadata
    created_by INTEGER REFERENCES public.users(user_id),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Indexes for icons table
CREATE INDEX idx_icons_type ON public.icons(icon_type);
CREATE INDEX idx_icons_category ON public.icons(category);
CREATE INDEX idx_icons_tags ON public.icons USING GIN(tags);
CREATE INDEX idx_icons_code ON public.icons(icon_code);
CREATE INDEX idx_icons_popular ON public.icons(is_popular) WHERE is_popular = TRUE;
CREATE INDEX idx_icons_active ON public.icons(is_active) WHERE is_active = TRUE;

-- Full-text search index on name, description, and tags
CREATE INDEX idx_icons_search ON public.icons USING GIN(
    to_tsvector('english', 
        COALESCE(icon_name, '') || ' ' || 
        COALESCE(description, '') || ' ' || 
        COALESCE(array_to_string(tags, ' '), '')
    )
);

-- ==========================================
-- 2. Data Model Fields (Merged Model Fields + Table Columns)
-- ==========================================
CREATE TABLE public.data_model_fields (
    field_id SERIAL PRIMARY KEY,
    model_id INTEGER NOT NULL REFERENCES public.data_models(model_id) ON DELETE CASCADE,
    
    field_name VARCHAR(100) NOT NULL, -- Column Name
    display_name VARCHAR(100), -- Title
    
    -- Dynamic Type Definition
    field_type_id INTEGER NOT NULL REFERENCES public.field_types(field_type_id),
    field_config_json JSONB DEFAULT '{}'::jsonb, -- Store specific settings (e.g. max_length, foreign_key_target)
    
    -- Properties
    is_required BOOLEAN DEFAULT FALSE,
    is_unique BOOLEAN DEFAULT FALSE,
    is_primary_key BOOLEAN DEFAULT FALSE,
    default_value TEXT,
    
    -- Security/Privacy
    encryption_method public.encryption_method_enum DEFAULT 'none' NOT NULL,
    
    -- UI Hints
    ui_component VARCHAR(50), -- Can override default from field_type
    order_no INTEGER DEFAULT 0,
    
    idate TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 3. Field Permissions
-- ==========================================
CREATE TABLE public.field_permissions (
    field_permission_id SERIAL PRIMARY KEY,
    role_id INTEGER NOT NULL REFERENCES public.roles(role_id) ON DELETE CASCADE,
    model_id INTEGER NOT NULL REFERENCES public.data_models(model_id) ON DELETE CASCADE,
    field_name VARCHAR(100) NOT NULL,
    
    -- Bitmask of allowed actions on this field:
    -- READ=1, WRITE=2, UPDATE=4, DELETE=8  (ALL=15)
    action_mask INTEGER DEFAULT 0 NOT NULL,
    
    UNIQUE(role_id, model_id, field_name)
);

-- ==========================================
-- 3.1 Model Row Access Policies
-- ==========================================
-- Controls row-level access for auto CRUD on a model.
-- A model can have multiple policy rows (combined as AND).
CREATE TABLE public.model_row_access_policies (
    id SERIAL PRIMARY KEY,
    model_id INTEGER NOT NULL REFERENCES public.data_models(model_id) ON DELETE CASCADE,
    
    -- Bitmask of actions this policy applies to:
    -- READ=1, WRITE=2, UPDATE=4, DELETE=8  (ALL=15)
    action_mask INTEGER DEFAULT 0 NOT NULL,
    
    -- Column in the target table used for scoping, e.g. "company_id"
    scope_field VARCHAR(100) NOT NULL,
    
    -- Where to source the scope value from:
    -- AUTH_CONTEXT: JWT/session context
    -- USER: request parameter/body (validated/enforced by server)
    scope_source VARCHAR(20) NOT NULL CHECK (scope_source IN ('AUTH_CONTEXT', 'USER')),
    
    -- If true, access is denied if scope value cannot be determined.
    required BOOLEAN DEFAULT TRUE NOT NULL,
    
    -- If false, user cannot override/expand scope filter.
    user_override BOOLEAN DEFAULT FALSE NOT NULL
);

-- ==========================================
-- 4. App Views
-- ==========================================
CREATE TABLE public.app_views (
    app_view_id SERIAL PRIMARY KEY,
    app_view_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    
    model_id INTEGER REFERENCES public.data_models(model_id) ON DELETE CASCADE,
    
    view_type VARCHAR(50) NOT NULL, 
    view_name VARCHAR(100) NOT NULL,
    
    view_config JSONB NOT NULL DEFAULT '{}'::jsonb, 
    
    endpoint_id INTEGER, 
    
    is_default BOOLEAN DEFAULT FALSE,
    is_builtin BOOLEAN DEFAULT FALSE,
    
    created_by INTEGER REFERENCES public.users(user_id),
    idate TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_data_models_app ON public.data_models(app_id);
CREATE INDEX idx_data_model_fields_model ON public.data_model_fields(model_id);
CREATE INDEX idx_app_views_model ON public.app_views(model_id);

-- Late Constraints
ALTER TABLE public.menus 
    ADD CONSTRAINT fk_menus_view 
    FOREIGN KEY (view_id) 
    REFERENCES public.app_views(app_view_id) 
    ON DELETE SET NULL;
-- 06_api_and_operations.sql
-- Classification: Connectivity & Operations
-- Description: Manages Data Ops (Archival, Audit) and API/Endpoint Configuration (including Flattened/Computed Views).
-- Dependencies: users, data_models

-- ==========================================
-- 1. Archival Policies
-- ==========================================
-- 3-Level Strategy: Live -> Archive Table (L2) -> S3 Parquet (L3)
CREATE TABLE public.archival_policies (
    policy_id SERIAL PRIMARY KEY,
    model_id INTEGER NOT NULL REFERENCES public.data_models(model_id) ON DELETE CASCADE,
    
    tenant_id UUID, -- Optional: Tenant-specific policy
    
    -- L2: Move to Archive Table
    l2_criteria_json JSONB, -- e.g. { "days_older_than": 90, "status": "closed" }
    archive_table_name VARCHAR(100), -- e.g. "archives.orders_2024"
    
    -- L3: Move to S3 (Cold Storage)
    l3_criteria_json JSONB, -- e.g. { "days_older_than": 365 }
    s3_config_json JSONB, -- { "bucket": "...", "path_pattern": "..." }
    
    is_active BOOLEAN DEFAULT TRUE,
    
    created_by INTEGER REFERENCES public.users(user_id),
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 2. Audit Logs (Time-Partitioned)
-- ==========================================
-- High-volume event tracking. Partitioned by Time Range.
CREATE TABLE public.audit_logs (
    log_id BIGSERIAL, 
    event_time TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    -- Context
    tenant_id UUID, 
    user_id INTEGER,
    
    -- Categorization
    event_category VARCHAR(50), -- 'auth', 'data_change', 'config_change', 'system_job'
    event_action VARCHAR(50), -- 'login', 'update', 'delete', 'archive'
    
    -- Targets
    target_model VARCHAR(100), 
    target_record_id VARCHAR(50),
    
    -- Payload
    changes_json JSONB, -- { "old": ..., "new": ... }
    metadata_json JSONB, -- User Agent, IP, etc.
    
    -- Partition Key requirement
    PRIMARY KEY (event_time, log_id) 
) PARTITION BY RANGE (event_time);

-- Initial Default Partition (Holds data that doesn't fit specific ranges)
CREATE TABLE public.audit_logs_default PARTITION OF public.audit_logs
    DEFAULT;

-- ==========================================
-- 3. Data Flattening Rules
-- ==========================================
-- Configurable denormalization for high-performance read models.
CREATE TABLE public.data_flattening_rules (
    rule_id SERIAL PRIMARY KEY,
    rule_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    
    rule_name VARCHAR(100) NOT NULL,
    rule_code VARCHAR(100) NOT NULL UNIQUE,
    
    source_model_id INTEGER REFERENCES public.data_models(model_id) ON DELETE CASCADE,
    target_model_name VARCHAR(100), -- Name of the physical table/matview if generated
    
    -- Configuration
    computation_config_json JSONB, -- { "joins": [...], "formulas": [...] }
    refresh_policy_json JSONB, -- { "type": "scheduled", "cron": "0 * * * *", "timeout": 300 }
    
    is_active BOOLEAN DEFAULT TRUE,
    
    created_by INTEGER REFERENCES public.users(user_id),
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 4. API Endpoints (Unified Access)
-- ==========================================
-- Central registry for all API routes. 
-- Handles standard CRUD (auto_crud), Custom Queries, and Flattened/Materialized Views.
CREATE TABLE public.api_endpoints (
    endpoint_id SERIAL PRIMARY KEY,
    endpoint_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    
    path VARCHAR(200) NOT NULL, -- e.g. "/data-models/auto/users/records"
    method VARCHAR(10) DEFAULT 'GET',
    
    -- 'auto_crud': Standard REST on a model (GET/POST/PUT/DELETE)
    -- 'flattened_view': Read-Optimized View (Materialized or Computed)
    -- 'custom_query': Ad-hoc SQL with table joins using table_alias
    type VARCHAR(50) NOT NULL, 
    
    -- Main model for auto_crud; primary model for custom_query
    related_model_id INTEGER REFERENCES public.data_models(model_id) ON DELETE SET NULL,
    
    -- Models used in this endpoint (for permission check via model_row_access_policies)
    -- Includes related_model_id and any joined models in custom_query
    reference_model_ids INTEGER[] DEFAULT '{}', -- Array of data_models.model_id
    
    -- Custom query SQL and config (for type = 'custom_query')
    -- Stores: { "query": "SELECT ...", "joins": [...], "params": [...] }
    custom_json JSONB DEFAULT '{}'::jsonb,
    
    -- Security & System
    permission_required VARCHAR(100), -- Role/Permission key
    is_builtin BOOLEAN DEFAULT FALSE, -- System protected
    
    created_by INTEGER REFERENCES public.users(user_id),
    idate TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(path, method)
);

-- Indexes
CREATE INDEX idx_archival_model ON public.archival_policies(model_id);
CREATE INDEX idx_audit_logs_event_time ON public.audit_logs(event_time); -- Partition pruning
CREATE INDEX idx_audit_logs_tenant ON public.audit_logs(tenant_id);
CREATE INDEX idx_audit_logs_target ON public.audit_logs(target_model, target_record_id);
CREATE INDEX idx_flattening_rules_source ON public.data_flattening_rules(source_model_id);
CREATE INDEX idx_api_endpoints_path ON public.api_endpoints(path);
-- 07_system_utilities.sql
-- Classification: Operational Utilities
-- Description: Helper tables for Async Jobs, Third-Party Integrations, and File Assets.
-- Dependencies: users, companies

-- ==========================================
-- 1. Actions & Workflows
-- ==========================================

-- 1.1 Actions Registry (Atomic Units of Work)
CREATE TABLE public.actions (
    action_id SERIAL PRIMARY KEY,
    action_code VARCHAR(50) NOT NULL UNIQUE, -- 'send_email', 'app_clone'
    action_name VARCHAR(100) NOT NULL,
    description TEXT,
    
    handler_function VARCHAR(100) NOT NULL, -- Internal code handler e.g. 'NotificationService.sendEmail'
    
    -- Schemas for Validation
    inputs_schema_json JSONB DEFAULT '{}'::jsonb, -- { "to": { "type": "email" } }
    outputs_schema_json JSONB DEFAULT '{}'::jsonb, -- { "message_id": { "type": "string" } }
    
    is_idempotent BOOLEAN DEFAULT FALSE,
    
    -- Execution / Queue Config
    queue_concurrency_mode VARCHAR(20) DEFAULT 'parallel', -- 'sequential', 'parallel'
    queue_concurrency_limit INTEGER DEFAULT 0,
    default_timeout_seconds INTEGER DEFAULT 3600,
    retry_policy_json JSONB DEFAULT '{"max_retries": 3, "backoff": "exponential"}'::jsonb,
    
    is_active BOOLEAN DEFAULT TRUE
);

-- 1.2 Workflows (Orchestration)
CREATE TABLE public.workflows (
    workflow_id SERIAL PRIMARY KEY,
    workflow_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    company_id INTEGER REFERENCES public.companies(company_id) ON DELETE CASCADE,
    
    workflow_name VARCHAR(100) NOT NULL,
    workflow_code VARCHAR(100) UNIQUE,
    
    -- Triggers: { "type": "event", "event": "user.created" } or { "type": "schedule", "cron": "..." }
    trigger_config_json JSONB,
    
    -- The Logic: Sequence of Actions
    steps_json JSONB NOT NULL DEFAULT '[]'::jsonb, 
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 1.3 Workflow Runs (History)
CREATE TABLE public.workflow_runs (
    run_id SERIAL PRIMARY KEY,
    run_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    workflow_id INTEGER REFERENCES public.workflows(workflow_id) ON DELETE CASCADE,
    
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'running', 'completed', 'failed', 'cancelled'
    trigger_context_json JSONB, -- Event payload that triggered this run
    
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    error_details JSONB
);

-- 1.4 Job Queue (Execution Engine)
CREATE TABLE public.job_queue (
    job_id SERIAL PRIMARY KEY,
    job_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    company_id INTEGER REFERENCES public.companies(company_id) ON DELETE CASCADE,
    
    -- Linkage
    action_id INTEGER REFERENCES public.actions(action_id),
    related_workflow_id INTEGER REFERENCES public.workflows(workflow_id) ON DELETE SET NULL,
    related_workflow_run_id INTEGER REFERENCES public.workflow_runs(run_id) ON DELETE CASCADE,
    
    status VARCHAR(20) DEFAULT 'pending',
    priority INTEGER DEFAULT 0,
    retry_count INTEGER DEFAULT 0,
    
    payload JSONB, -- Execution Arguments
    result JSONB,
    
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    
    created_by INTEGER REFERENCES public.users(user_id),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 2. Integration Providers (Template Registry)
-- ==========================================
-- Defines available integration providers and their required field configurations.
CREATE TABLE public.integration_providers (
    provider_id SERIAL PRIMARY KEY,
    provider_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    
    provider_name VARCHAR(50) NOT NULL UNIQUE, -- 'aws_ses', 'aws_s3', 'aws_sms', 'ccavenue'
    provider_display_name VARCHAR(100) NOT NULL, -- 'AWS SES', 'AWS S3', 'AWS SMS', 'CCAvenue'
    provider_category VARCHAR(50) NOT NULL, -- 'email', 'storage', 'sms', 'payment'
    
    description TEXT,
    documentation_url TEXT,
    
    -- Required fields schema: defines what fields are needed for this provider
    -- Each field references field_types table for validation
    required_fields_json JSONB NOT NULL DEFAULT '[]'::jsonb,
    -- Example: [
    --   {"field_name": "access_key_id", "field_type_id": 1, "is_required": true, "display_name": "Access Key ID"},
    --   {"field_name": "secret_access_key", "field_type_id": 1, "is_required": true, "display_name": "Secret Access Key", "is_secret": true}
    -- ]
    
    -- Optional configuration fields
    optional_fields_json JSONB DEFAULT '[]'::jsonb,
    
    -- Provider-specific metadata
    metadata_json JSONB DEFAULT '{}'::jsonb,
    
    is_active BOOLEAN DEFAULT TRUE,
    is_builtin BOOLEAN DEFAULT TRUE, -- System-provided providers cannot be deleted
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 2a. Integrations
-- ==========================================
-- Stores credentials and configurations for external services (Stripe, Slack, etc.) safely.
CREATE TABLE public.integrations (
    integration_id SERIAL PRIMARY KEY,
    integration_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    company_id INTEGER REFERENCES public.companies(company_id) ON DELETE CASCADE,
    
    provider_id INTEGER REFERENCES public.integration_providers(provider_id) ON DELETE SET NULL,
    provider_name VARCHAR(50) NOT NULL, -- 'aws_ses', 'sendgrid', 'aws_s3' (kept for backward compatibility)
    integration_name VARCHAR(100), -- User defined name
    
    -- Encrypted credentials (encrypted at application layer)
    encrypted_credentials TEXT,
    credentials_version INTEGER DEFAULT 1,
    
    -- Non-sensitive configuration
    config JSONB,
    
    -- Integration metadata
    integration_type VARCHAR(50) DEFAULT 'api', -- 'api', 'oauth', 'webhook'
    metadata JSONB DEFAULT '{}'::jsonb,
    
    is_active BOOLEAN DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE NOT NULL, -- Required: Mark default integration for each provider type
    
    created_by INTEGER REFERENCES public.users(user_id),
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 3. Assets / File Storage
-- ==========================================
-- Metadata references for files stored in S3 or local filesystem.
CREATE TABLE public.assets (
    asset_id SERIAL PRIMARY KEY,
    asset_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    company_id INTEGER REFERENCES public.companies(company_id) ON DELETE CASCADE,
    
    file_name VARCHAR(200) NOT NULL,
    original_name VARCHAR(200),
    mime_type VARCHAR(100),
    file_size BIGINT,
    
    storage_provider VARCHAR(50) DEFAULT 'local', -- 'local', 's3', 'gcs'
    storage_path TEXT NOT NULL, -- Key or Path (S3 key or local path)
    public_url TEXT,
    
    -- Access control
    is_public BOOLEAN DEFAULT FALSE, -- If true, asset is publicly accessible; if false, requires authentication
    
    related_model VARCHAR(100), -- Polymorphic association (optional)
    related_id INTEGER,
    
    uploaded_by INTEGER REFERENCES public.users(user_id),
    uploaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_task_queue_company ON public.job_queue(company_id);
CREATE INDEX idx_task_queue_status ON public.job_queue(status);
CREATE INDEX idx_integration_providers_name ON public.integration_providers(provider_name);
CREATE INDEX idx_integration_providers_category ON public.integration_providers(provider_category);
CREATE INDEX idx_integrations_company ON public.integrations(company_id);
CREATE INDEX idx_integrations_provider ON public.integrations(provider_id);
CREATE INDEX idx_integrations_provider_name ON public.integrations(provider_name);
-- Partial unique index to ensure only one default integration per provider per company
CREATE UNIQUE INDEX idx_integrations_default_unique ON public.integrations(company_id, provider_name) WHERE is_default = TRUE;
CREATE INDEX idx_assets_company ON public.assets(company_id);
CREATE INDEX idx_assets_storage_provider ON public.assets(storage_provider);
CREATE INDEX idx_assets_is_public ON public.assets(is_public);

-- ==========================================
-- 4. Settings Configuration (Global & Tenant)
-- ==========================================
CREATE TABLE public.settings (
    setting_id SERIAL PRIMARY KEY,
    
    group_name VARCHAR(50) NOT NULL, -- 'General', 'Security', 'Branding'
    setting_key VARCHAR(100) NOT NULL, -- 'app_logo', 'password_len'
    setting_name VARCHAR(100) NOT NULL,
    description TEXT,
    
    -- Dynamic Typing
    field_type_id INTEGER REFERENCES public.field_types(field_type_id),
    
    default_value JSONB, -- System Fallback
    value JSONB,         -- Actual Value
    
    -- Scoping
    scope VARCHAR(20) DEFAULT 'global', -- 'global' (SaaS Default), 'tenant' (Override)
    tenant_id INTEGER REFERENCES public.tenants(tenant_id) ON DELETE CASCADE, -- NULL = Global
    
    is_built_in BOOLEAN DEFAULT FALSE,
    
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(setting_key, tenant_id) -- One value per key per tenant (or one global if tenant is null)
);

CREATE INDEX idx_settings_tenant ON public.settings(tenant_id);
CREATE INDEX idx_settings_key ON public.settings(setting_key);

-- ==========================================
-- 4a. Themes Table (Global/User-scoped theme configs)
-- ==========================================
-- Stores theme JSON configs. user_id NULL = global theme. scope: saas | tenant.
CREATE TABLE public.themes (
    theme_id SERIAL PRIMARY KEY,
    theme_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    
    theme_name VARCHAR(100) NOT NULL, -- Display name e.g. "Default Corporate", "My Custom Theme"
    theme_key VARCHAR(100) NOT NULL,   -- Key for reference e.g. "default", "slate", "custom_1"
    
    theme_json JSONB NOT NULL DEFAULT '{}'::jsonb, -- Full theme config (colors, fonts, light/dark palettes)
    
    user_id INTEGER REFERENCES public.users(user_id) ON DELETE CASCADE, -- NULL = global
    scope VARCHAR(20) NOT NULL DEFAULT 'saas' CHECK (scope IN ('saas', 'tenant')),
    tenant_id INTEGER REFERENCES public.tenants(tenant_id) ON DELETE CASCADE, -- For tenant-scoped themes
    
    is_builtin BOOLEAN DEFAULT FALSE, -- default/slate cannot be deleted
    is_default BOOLEAN DEFAULT FALSE, -- default for scope
    
    created_by INTEGER REFERENCES public.users(user_id),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX idx_themes_user ON public.themes(user_id);
CREATE INDEX idx_themes_scope ON public.themes(scope);
CREATE INDEX idx_themes_tenant ON public.themes(tenant_id);
-- 08_ai_model.sql
-- Classification: AI & Knowledge Graph
-- Description: Schema for the AI Engine: Knowledge Graph nodes, Relationships, Facts (Events), and Vector Embeddings.

-- Enable pgvector (Assuming it is available, otherwise error will occur, but standard practice is to enable it)
CREATE EXTENSION IF NOT EXISTS vector;

-- ==========================================
-- 1. Knowledge Graph (Nodes & Relations)
-- ==========================================
-- Nodes represent Entities, Concepts, or Facts.
CREATE TABLE public.ai_knowledge_nodes (
    node_id VARCHAR(255) PRIMARY KEY, -- Semantic ID e.g. 'person:karan', 'concept:freedom'
    node_type VARCHAR(50) NOT NULL,   -- 'entity', 'concept', 'fact', 'rule'
    
    title VARCHAR(255),
    description TEXT,
    content JSONB,                    -- Structured data or unstructured text content
    
    is_active BOOLEAN DEFAULT TRUE,
    version INTEGER DEFAULT 1,
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Edges represent the semantic relationships between nodes.
CREATE TABLE public.ai_knowledge_relations (
    relation_id SERIAL PRIMARY KEY,
    from_node VARCHAR(255) REFERENCES public.ai_knowledge_nodes(node_id) ON DELETE CASCADE,
    to_node VARCHAR(255) REFERENCES public.ai_knowledge_nodes(node_id) ON DELETE CASCADE,
    
    relation VARCHAR(100) NOT NULL,   -- 'is_a', 'has_attribute', 'performed', 'located_in'
    attributes JSONB DEFAULT '{}'::jsonb, -- Edge properties e.g. { "weight": 0.8 }
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(from_node, to_node, relation)
);

-- ==========================================
-- 2. Event Log (Immutable Facts)
-- ==========================================
-- Stores the "Actuality" or "Truth" of what happened.
CREATE TABLE public.ai_events (
    event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    subject VARCHAR(255) NOT NULL,   -- Textual Subject
    predicate VARCHAR(100) NOT NULL, -- Did What
    object VARCHAR(255),             -- Textual Object
    
    -- Optional Strong Liking to Graph Nodes
    subject_node_id VARCHAR(255) REFERENCES public.ai_knowledge_nodes(node_id) ON DELETE SET NULL,
    object_node_id VARCHAR(255) REFERENCES public.ai_knowledge_nodes(node_id) ON DELETE SET NULL,
    
    attributes JSONB,                -- Contextual data e.g. { "amount": 500 }
    
    occurred_at TIMESTAMPTZ NOT NULL,
    recorded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    is_active BOOLEAN DEFAULT TRUE
);

-- ==========================================
-- 3. Vector Embeddings
-- ==========================================
-- Links Knowledge/Facts to High-Dimensional Vectors.
CREATE TABLE public.ai_knowledge_vectors (
    vector_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    target_node_id VARCHAR(255) REFERENCES public.ai_knowledge_nodes(node_id) ON DELETE CASCADE,
    
    embedding VECTOR(1536),           
    embedding_model VARCHAR(100) DEFAULT 'text-embedding-ada-002',
    embedding_version VARCHAR(20),
    
    searchable_text TEXT,             
    
    is_active BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for Performance
CREATE INDEX idx_ai_nodes_type ON public.ai_knowledge_nodes(node_type) WHERE is_active = true;
CREATE INDEX idx_ai_nodes_content ON public.ai_knowledge_nodes USING GIN (content);

CREATE INDEX idx_ai_relations_from ON public.ai_knowledge_relations(from_node);
CREATE INDEX idx_ai_relations_to ON public.ai_knowledge_relations(to_node);

CREATE INDEX idx_ai_events_subject ON public.ai_events(subject);
CREATE INDEX idx_ai_events_predicate ON public.ai_events(predicate);
CREATE INDEX idx_ai_events_occurred ON public.ai_events(occurred_at DESC) WHERE is_active = true;
CREATE INDEX idx_ai_events_attributes ON public.ai_events USING GIN (attributes);

-- Vector Index (HNSW)
CREATE INDEX idx_ai_vectors_embedding ON public.ai_knowledge_vectors USING hnsw (embedding vector_cosine_ops);
-- 09_ai_addons.sql
-- Classification: AI Extensions
-- Description: Additional structures for AI execution planning, safety, and rule-based reasoning.
-- Dependencies: 08_ai_model.sql

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =====================================================
-- 1. Intent / Planner Execution Log (Audit & Debug)
-- =====================================================
CREATE TABLE public.ai_query_plans (
    plan_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_query TEXT NOT NULL,
    planner_json JSONB NOT NULL,
    confidence NUMERIC(3,2),

    execution_type VARCHAR(20),       -- sql | graph | vector | hybrid
    generated_sql TEXT,

    status VARCHAR(20) DEFAULT 'planned', -- planned | executed | failed
    error_message TEXT,

    latency_ms INTEGER,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ai_query_plans_created ON public.ai_query_plans(created_at DESC);

-- =====================================================
-- 2. Canonical Entity Alias Mapping (Anti-Duplication)
-- =====================================================
CREATE TABLE public.ai_entity_aliases (
    alias TEXT PRIMARY KEY,
    canonical_node_id VARCHAR(255) REFERENCES public.ai_knowledge_nodes(node_id) ON DELETE CASCADE
);

-- =====================================================
-- 3. Rule Engine (Deterministic Reasoning)
-- =====================================================
CREATE TABLE public.ai_rules (
    rule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    rule_name TEXT,
    description TEXT,
    
    condition JSONB,        -- deterministic condition e.g. { "field": "amount", "op": ">", "value": 10000 }
    action JSONB,           -- derived impact e.g. { "flag": "review_required" }

    priority INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
-- Note: Seed data (ui_component_types, field_types, settings) has been moved to noolvandb_feeds.sql
-- 96_seed_ai_model.sql
-- Classification: Seed Data
-- Description: Sample Knowledge Graph Nodes, Events, and Rules.

-- 1. Seed Nodes (Entities & Concepts)
INSERT INTO public.ai_knowledge_nodes (node_id, node_type, title, description, content) VALUES
('person:karan', 'entity', 'Karan', 'A user of the system', '{"role": "admin", "email": "karan@example.com"}'),
('person:sundar', 'entity', 'Sundar', 'A collaborator', '{"role": "editor", "email": "sundar@example.com"}'),
('concept:payment', 'concept', 'Payment', 'Transfer of value', '{"methods": ["bank", "upi", "card"]}'),
('concept:project_alpha', 'entity', 'Project Alpha', 'Top secret initiative', '{"status": "active", "budget": 100000}')
ON CONFLICT DO NOTHING;

-- 2. Seed Relations
INSERT INTO public.ai_knowledge_relations (from_node, to_node, relation, attributes) VALUES
('person:karan', 'concept:project_alpha', 'manages', '{"since": "2025-01-01"}'),
('person:sundar', 'concept:project_alpha', 'contributes_to', '{"role": "developer"}'),
('person:karan', 'concept:payment', 'can_approve', '{}')
ON CONFLICT DO NOTHING;

-- 3. Seed Events (Facts)
INSERT INTO public.ai_events (subject, predicate, object, subject_node_id, object_node_id, attributes, occurred_at) VALUES
('Karan', 'created', 'Project Alpha', 'person:karan', 'concept:project_alpha', '{"method": "web_ui"}', NOW() - INTERVAL '10 days'),
('Sundar', 'committed', 'Code Change #123', 'person:sundar', NULL, '{"lines_added": 50}', NOW() - INTERVAL '2 days');

-- 4. Seed Rules
INSERT INTO public.ai_rules (rule_name, condition, action, priority) VALUES
('High Value Payment Alert', '{"field": "amount", "op": ">", "value": 10000}', '{"alert": "compliance_team", "severity": "high"}', 10),
('Inactive Project Archive', '{"field": "last_activity", "op": ">", "days": 90}', '{"status": "archived"}', 5);

-- 5. Seed Aliases
INSERT INTO public.ai_entity_aliases (alias, canonical_node_id) VALUES
('karan_admin', 'person:karan'),
('boss_man', 'person:karan'),
('proj_alpha', 'concept:project_alpha')
ON CONFLICT DO NOTHING;
-- 97_seed_actions.sql
-- Classification: Seed Data
-- Description: Standard System Actions (Atomic Units of Work).

INSERT INTO public.actions (action_code, action_name, handler_function, queue_concurrency_mode, queue_concurrency_limit, default_timeout_seconds, is_idempotent, inputs_schema_json) VALUES
-- Heavy Operations -> Sequential
('app_clone', 'Clone Application', 'AppService.clone', 'sequential', 1, 600, false, '{"app_id": {"type": "integer"}, "target_company_id": {"type": "integer"}}'),
('tenant_provision', 'Provision New Tenant', 'TenantService.provision', 'sequential', 2, 300, false, '{"tenant_name": {"type": "string"}}'),

-- Data Operations -> Limited Parallelism
('data_import', 'Bulk Data Import', 'DataService.import', 'parallel', 3, 1800, false, '{"file_url": {"type": "string"}, "target_model": {"type": "string"}}'),
('data_export', 'Data Export', 'DataService.export', 'parallel', 5, 1800, true, '{"model_id": {"type": "integer"}, "filters": {"type": "object"}}'),

-- Communications -> High Parallelism
('send_email', 'Send Email', 'CommsService.sendEmail', 'parallel', 20, 300, true, '{"to": {"type": "email"}, "subject": {"type": "string"}, "body": {"type": "text"}}'),
('notification_push', 'Send Push Notification', 'CommsService.sendPush', 'parallel', 50, 60, true, '{"user_id": {"type": "integer"}, "message": {"type": "string"}}'),

-- Maintenance
('system_cleanup', 'Daily Cleanup', 'MaintenanceService.cleanup', 'sequential', 1, 3600, true, '{}'),
('search_reindex', 'Re-index Search', 'SearchService.reindex', 'sequential', 1, 7200, true, '{}')

ON CONFLICT (action_code) DO NOTHING;
-- Note: UI Component Types and Field Types seed data has been moved to noolvandb_feeds.sql
