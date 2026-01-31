--
-- PostgreSQL database dump
--

\restrict VUs42J7fdEDfsffiwSCZaYgRX2DOJmN1zXvloBScbegCjgLKnQ95Zc0KEmR5YZq

-- Dumped from database version 16.11 (Ubuntu 16.11-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: vector; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


--
-- Name: EXTENSION vector; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION vector IS 'vector data type and ivfflat and hnsw access methods';


--
-- Name: encryption_method_enum; Type: TYPE; Schema: public; Owner: noolvan
--

CREATE TYPE public.encryption_method_enum AS ENUM (
    'none',
    'aes',
    'xor_cipher'
);


ALTER TYPE public.encryption_method_enum OWNER TO noolvan;

--
-- Name: model_scope_enum; Type: TYPE; Schema: public; Owner: noolvan
--

CREATE TYPE public.model_scope_enum AS ENUM (
    'saas',
    'tenant',
    'both'
);


ALTER TYPE public.model_scope_enum OWNER TO noolvan;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: actions; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.actions (
    action_id integer NOT NULL,
    action_code character varying(50) NOT NULL,
    action_name character varying(100) NOT NULL,
    description text,
    handler_function character varying(100) NOT NULL,
    inputs_schema_json jsonb DEFAULT '{}'::jsonb,
    outputs_schema_json jsonb DEFAULT '{}'::jsonb,
    is_idempotent boolean DEFAULT false,
    queue_concurrency_mode character varying(20) DEFAULT 'parallel'::character varying,
    queue_concurrency_limit integer DEFAULT 0,
    default_timeout_seconds integer DEFAULT 3600,
    retry_policy_json jsonb DEFAULT '{"backoff": "exponential", "max_retries": 3}'::jsonb,
    is_active boolean DEFAULT true
);


ALTER TABLE public.actions OWNER TO noolvan;

--
-- Name: actions_action_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.actions_action_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.actions_action_id_seq OWNER TO noolvan;

--
-- Name: actions_action_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.actions_action_id_seq OWNED BY public.actions.action_id;


--
-- Name: ai_entity_aliases; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.ai_entity_aliases (
    alias text NOT NULL,
    canonical_node_id character varying(255)
);


ALTER TABLE public.ai_entity_aliases OWNER TO noolvan;

--
-- Name: ai_events; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.ai_events (
    event_id uuid DEFAULT gen_random_uuid() NOT NULL,
    subject character varying(255) NOT NULL,
    predicate character varying(100) NOT NULL,
    object character varying(255),
    subject_node_id character varying(255),
    object_node_id character varying(255),
    attributes jsonb,
    occurred_at timestamp without time zone NOT NULL,
    recorded_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_active boolean DEFAULT true
);


ALTER TABLE public.ai_events OWNER TO noolvan;

--
-- Name: ai_knowledge_nodes; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.ai_knowledge_nodes (
    node_id character varying(255) NOT NULL,
    node_type character varying(50) NOT NULL,
    title character varying(255),
    description text,
    content jsonb,
    is_active boolean DEFAULT true,
    version integer DEFAULT 1,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.ai_knowledge_nodes OWNER TO noolvan;

--
-- Name: ai_knowledge_relations; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.ai_knowledge_relations (
    relation_id integer NOT NULL,
    from_node character varying(255),
    to_node character varying(255),
    relation character varying(100) NOT NULL,
    attributes jsonb DEFAULT '{}'::jsonb,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.ai_knowledge_relations OWNER TO noolvan;

--
-- Name: ai_knowledge_relations_relation_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.ai_knowledge_relations_relation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ai_knowledge_relations_relation_id_seq OWNER TO noolvan;

--
-- Name: ai_knowledge_relations_relation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.ai_knowledge_relations_relation_id_seq OWNED BY public.ai_knowledge_relations.relation_id;


--
-- Name: ai_knowledge_vectors; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.ai_knowledge_vectors (
    vector_id uuid DEFAULT gen_random_uuid() NOT NULL,
    target_node_id character varying(255),
    embedding public.vector(1536),
    embedding_model character varying(100) DEFAULT 'text-embedding-ada-002'::character varying,
    embedding_version character varying(20),
    searchable_text text,
    is_active boolean DEFAULT true,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.ai_knowledge_vectors OWNER TO noolvan;

--
-- Name: ai_query_plans; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.ai_query_plans (
    plan_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_query text NOT NULL,
    planner_json jsonb NOT NULL,
    confidence numeric(3,2),
    execution_type character varying(20),
    generated_sql text,
    status character varying(20) DEFAULT 'planned'::character varying,
    error_message text,
    latency_ms integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.ai_query_plans OWNER TO noolvan;

--
-- Name: ai_rules; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.ai_rules (
    rule_id uuid DEFAULT gen_random_uuid() NOT NULL,
    rule_name text,
    description text,
    condition jsonb,
    action jsonb,
    priority integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.ai_rules OWNER TO noolvan;

--
-- Name: api_endpoints; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.api_endpoints (
    endpoint_id integer NOT NULL,
    endpoint_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    path character varying(200) NOT NULL,
    method character varying(10) DEFAULT 'GET'::character varying,
    type character varying(50) NOT NULL,
    related_model_id integer,
    flattening_rule_id integer,
    custom_logic_json jsonb,
    permission_required character varying(100),
    is_builtin boolean DEFAULT false,
    created_by integer,
    idate timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.api_endpoints OWNER TO noolvan;

--
-- Name: api_endpoints_endpoint_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.api_endpoints_endpoint_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.api_endpoints_endpoint_id_seq OWNER TO noolvan;

--
-- Name: api_endpoints_endpoint_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.api_endpoints_endpoint_id_seq OWNED BY public.api_endpoints.endpoint_id;


--
-- Name: app_views; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.app_views (
    app_view_id integer NOT NULL,
    app_view_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    model_id integer,
    view_type character varying(50) NOT NULL,
    view_name character varying(100) NOT NULL,
    view_config jsonb DEFAULT '{}'::jsonb NOT NULL,
    endpoint_id integer,
    is_default boolean DEFAULT false,
    is_builtin boolean DEFAULT false,
    created_by integer,
    idate timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.app_views OWNER TO noolvan;

--
-- Name: app_views_app_view_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.app_views_app_view_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.app_views_app_view_id_seq OWNER TO noolvan;

--
-- Name: app_views_app_view_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.app_views_app_view_id_seq OWNED BY public.app_views.app_view_id;


--
-- Name: apps; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.apps (
    app_id integer NOT NULL,
    app_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    app_name character varying(100) NOT NULL,
    app_title character varying(150) NOT NULL,
    app_image_url text,
    app_description text,
    tenant_id integer,
    company_id integer,
    cloned_from_app_id integer,
    is_saas_default boolean DEFAULT false,
    is_tenant_default boolean DEFAULT false,
    is_store_app boolean DEFAULT false,
    is_builtin boolean DEFAULT false,
    order_no integer DEFAULT 0,
    created_by integer,
    idate timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_active boolean DEFAULT true
);


ALTER TABLE public.apps OWNER TO noolvan;

--
-- Name: apps_app_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.apps_app_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.apps_app_id_seq OWNER TO noolvan;

--
-- Name: apps_app_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.apps_app_id_seq OWNED BY public.apps.app_id;


--
-- Name: archival_policies; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.archival_policies (
    policy_id integer NOT NULL,
    model_id integer NOT NULL,
    tenant_id uuid,
    l2_criteria_json jsonb,
    archive_table_name character varying(100),
    l3_criteria_json jsonb,
    s3_config_json jsonb,
    is_active boolean DEFAULT true,
    created_by integer,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.archival_policies OWNER TO noolvan;

--
-- Name: archival_policies_policy_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.archival_policies_policy_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.archival_policies_policy_id_seq OWNER TO noolvan;

--
-- Name: archival_policies_policy_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.archival_policies_policy_id_seq OWNED BY public.archival_policies.policy_id;


--
-- Name: assets; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.assets (
    asset_id integer NOT NULL,
    asset_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id integer,
    file_name character varying(200) NOT NULL,
    original_name character varying(200),
    mime_type character varying(100),
    file_size bigint,
    storage_provider character varying(50) DEFAULT 'local'::character varying,
    storage_path text NOT NULL,
    public_url text,
    is_public boolean DEFAULT false,
    related_model character varying(100),
    related_id integer,
    uploaded_by integer,
    uploaded_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.assets OWNER TO noolvan;

--
-- Name: assets_asset_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.assets_asset_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.assets_asset_id_seq OWNER TO noolvan;

--
-- Name: assets_asset_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.assets_asset_id_seq OWNED BY public.assets.asset_id;


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.audit_logs (
    log_id bigint NOT NULL,
    event_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tenant_id uuid,
    user_id integer,
    event_category character varying(50),
    event_action character varying(50),
    target_model character varying(100),
    target_record_id character varying(50),
    changes_json jsonb,
    metadata_json jsonb
)
PARTITION BY RANGE (event_time);


ALTER TABLE public.audit_logs OWNER TO noolvan;

--
-- Name: audit_logs_log_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.audit_logs_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_logs_log_id_seq OWNER TO noolvan;

--
-- Name: audit_logs_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.audit_logs_log_id_seq OWNED BY public.audit_logs.log_id;


--
-- Name: audit_logs_default; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.audit_logs_default (
    log_id bigint DEFAULT nextval('public.audit_logs_log_id_seq'::regclass) NOT NULL,
    event_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tenant_id uuid,
    user_id integer,
    event_category character varying(50),
    event_action character varying(50),
    target_model character varying(100),
    target_record_id character varying(50),
    changes_json jsonb,
    metadata_json jsonb
);


ALTER TABLE public.audit_logs_default OWNER TO noolvan;

--
-- Name: collections; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.collections (
    collection_id integer NOT NULL,
    collection_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    collection_name character varying(100) NOT NULL,
    collection_code character varying(100) NOT NULL,
    tenant_id integer,
    is_system boolean DEFAULT false,
    created_by integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    field_type_id integer,
    field_config_json jsonb DEFAULT '{}'::jsonb NOT NULL
);


ALTER TABLE public.collections OWNER TO noolvan;

--
-- Name: collections_collection_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.collections_collection_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.collections_collection_id_seq OWNER TO noolvan;

--
-- Name: collections_collection_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.collections_collection_id_seq OWNED BY public.collections.collection_id;


--
-- Name: companies; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.companies (
    company_id integer NOT NULL,
    company_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id integer NOT NULL,
    company_name character varying(200) NOT NULL,
    company_code character varying(50) NOT NULL,
    domain character varying(100),
    logo_url text,
    branding_config jsonb,
    parent_company_id integer,
    is_default boolean DEFAULT false,
    is_active boolean DEFAULT true,
    created_by integer,
    idate timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.companies OWNER TO noolvan;

--
-- Name: companies_company_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.companies_company_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.companies_company_id_seq OWNER TO noolvan;

--
-- Name: companies_company_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.companies_company_id_seq OWNED BY public.companies.company_id;


--
-- Name: data_flattening_rules; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.data_flattening_rules (
    rule_id integer NOT NULL,
    rule_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    rule_name character varying(100) NOT NULL,
    rule_code character varying(100) NOT NULL,
    source_model_id integer,
    target_model_name character varying(100),
    computation_config_json jsonb,
    refresh_policy_json jsonb,
    is_active boolean DEFAULT true,
    created_by integer,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.data_flattening_rules OWNER TO noolvan;

--
-- Name: data_flattening_rules_rule_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.data_flattening_rules_rule_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.data_flattening_rules_rule_id_seq OWNER TO noolvan;

--
-- Name: data_flattening_rules_rule_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.data_flattening_rules_rule_id_seq OWNED BY public.data_flattening_rules.rule_id;


--
-- Name: data_model_fields; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.data_model_fields (
    field_id integer NOT NULL,
    model_id integer NOT NULL,
    field_name character varying(100) NOT NULL,
    display_name character varying(100),
    field_type_id integer NOT NULL,
    field_config_json jsonb DEFAULT '{}'::jsonb,
    is_required boolean DEFAULT false,
    is_unique boolean DEFAULT false,
    is_primary_key boolean DEFAULT false,
    default_value text,
    encryption_method public.encryption_method_enum DEFAULT 'none'::public.encryption_method_enum NOT NULL,
    ui_component character varying(50),
    order_no integer DEFAULT 0,
    idate timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.data_model_fields OWNER TO noolvan;

--
-- Name: data_model_fields_field_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.data_model_fields_field_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.data_model_fields_field_id_seq OWNER TO noolvan;

--
-- Name: data_model_fields_field_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.data_model_fields_field_id_seq OWNED BY public.data_model_fields.field_id;


--
-- Name: data_models; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.data_models (
    model_id integer NOT NULL,
    model_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    app_id integer,
    model_name character varying(100) NOT NULL,
    display_name character varying(100),
    table_name character varying(100) NOT NULL,
    is_public boolean DEFAULT false,
    is_system_model boolean DEFAULT false,
    is_active boolean DEFAULT true,
    description text,
    created_by integer,
    idate timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    table_alias character varying(50),
    model_scope public.model_scope_enum DEFAULT 'saas'::public.model_scope_enum NOT NULL
);


ALTER TABLE public.data_models OWNER TO noolvan;

--
-- Name: data_models_model_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.data_models_model_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.data_models_model_id_seq OWNER TO noolvan;

--
-- Name: data_models_model_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.data_models_model_id_seq OWNED BY public.data_models.model_id;


--
-- Name: field_permissions; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.field_permissions (
    field_permission_id integer NOT NULL,
    role_id integer NOT NULL,
    model_id integer NOT NULL,
    field_name character varying(100) NOT NULL,
    action_mask integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.field_permissions OWNER TO noolvan;

--
-- Name: field_permissions_field_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.field_permissions_field_permission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.field_permissions_field_permission_id_seq OWNER TO noolvan;

--
-- Name: field_permissions_field_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.field_permissions_field_permission_id_seq OWNED BY public.field_permissions.field_permission_id;


--
-- Name: field_types; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.field_types (
    field_type_id integer NOT NULL,
    type_name character varying(50) NOT NULL,
    type_code character varying(50) NOT NULL,
    category character varying(50) DEFAULT 'basic'::character varying,
    actual_db_type character varying(50) NOT NULL,
    default_component_type_id integer,
    default_props_json jsonb DEFAULT '{}'::jsonb,
    icon character varying(50),
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    input_type_image character varying(255),
    order_no integer DEFAULT 0
);


ALTER TABLE public.field_types OWNER TO noolvan;

--
-- Name: field_types_field_type_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.field_types_field_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.field_types_field_type_id_seq OWNER TO noolvan;

--
-- Name: field_types_field_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.field_types_field_type_id_seq OWNED BY public.field_types.field_type_id;


--
-- Name: icons; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.icons (
    icon_id integer NOT NULL,
    icon_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    icon_code character varying(100) NOT NULL,
    icon_type character varying(20) NOT NULL,
    icon_name character varying(150) NOT NULL,
    category character varying(50) NOT NULL,
    description text,
    tags text[] DEFAULT '{}'::text[],
    icon_data jsonb DEFAULT '{}'::jsonb,
    usage_count integer DEFAULT 0,
    is_popular boolean DEFAULT false,
    is_free boolean DEFAULT true,
    is_active boolean DEFAULT true,
    created_by integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT icons_icon_type_check CHECK (((icon_type)::text = ANY ((ARRAY['fa'::character varying, 'antd'::character varying, 'smily'::character varying, 'custom'::character varying])::text[])))
);


ALTER TABLE public.icons OWNER TO noolvan;

--
-- Name: icons_icon_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.icons_icon_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.icons_icon_id_seq OWNER TO noolvan;

--
-- Name: icons_icon_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.icons_icon_id_seq OWNED BY public.icons.icon_id;


--
-- Name: integration_providers; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.integration_providers (
    provider_id integer NOT NULL,
    provider_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    provider_name character varying(50) NOT NULL,
    provider_display_name character varying(100) NOT NULL,
    provider_category character varying(50) NOT NULL,
    description text,
    documentation_url text,
    required_fields_json jsonb DEFAULT '[]'::jsonb NOT NULL,
    optional_fields_json jsonb DEFAULT '[]'::jsonb,
    metadata_json jsonb DEFAULT '{}'::jsonb,
    is_active boolean DEFAULT true,
    is_builtin boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.integration_providers OWNER TO noolvan;

--
-- Name: integration_providers_provider_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.integration_providers_provider_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.integration_providers_provider_id_seq OWNER TO noolvan;

--
-- Name: integration_providers_provider_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.integration_providers_provider_id_seq OWNED BY public.integration_providers.provider_id;


--
-- Name: integrations; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.integrations (
    integration_id integer NOT NULL,
    integration_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id integer,
    provider_id integer,
    provider_name character varying(50) NOT NULL,
    integration_name character varying(100),
    encrypted_credentials text,
    credentials_version integer DEFAULT 1,
    config jsonb,
    integration_type character varying(50) DEFAULT 'api'::character varying,
    metadata jsonb DEFAULT '{}'::jsonb,
    is_active boolean DEFAULT true,
    is_default boolean DEFAULT false NOT NULL,
    created_by integer,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.integrations OWNER TO noolvan;

--
-- Name: integrations_integration_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.integrations_integration_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.integrations_integration_id_seq OWNER TO noolvan;

--
-- Name: integrations_integration_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.integrations_integration_id_seq OWNED BY public.integrations.integration_id;


--
-- Name: job_queue; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.job_queue (
    job_id integer NOT NULL,
    job_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id integer,
    action_id integer,
    related_workflow_id integer,
    related_workflow_run_id integer,
    status character varying(20) DEFAULT 'pending'::character varying,
    priority integer DEFAULT 0,
    retry_count integer DEFAULT 0,
    payload jsonb,
    result jsonb,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    created_by integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.job_queue OWNER TO noolvan;

--
-- Name: job_queue_job_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.job_queue_job_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_queue_job_id_seq OWNER TO noolvan;

--
-- Name: job_queue_job_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.job_queue_job_id_seq OWNED BY public.job_queue.job_id;


--
-- Name: menu_permissions; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.menu_permissions (
    menu_permission_id integer NOT NULL,
    menu_id integer NOT NULL,
    role_id integer NOT NULL,
    can_view boolean DEFAULT true
);


ALTER TABLE public.menu_permissions OWNER TO noolvan;

--
-- Name: menu_permissions_menu_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.menu_permissions_menu_permission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.menu_permissions_menu_permission_id_seq OWNER TO noolvan;

--
-- Name: menu_permissions_menu_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.menu_permissions_menu_permission_id_seq OWNED BY public.menu_permissions.menu_permission_id;


--
-- Name: menus; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.menus (
    menu_id integer NOT NULL,
    menu_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    menu_title character varying(150) NOT NULL,
    parent_id integer,
    type character varying(20) DEFAULT 'item'::character varying,
    route_path character varying(150),
    icon character varying(100),
    module_feature_id integer,
    app_id integer,
    view_id integer,
    scope character varying(20) DEFAULT 'tenant'::character varying,
    is_builtin boolean DEFAULT false,
    order_no integer DEFAULT 0,
    is_hidden boolean DEFAULT false,
    created_by integer,
    idate timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.menus OWNER TO noolvan;

--
-- Name: menus_menu_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.menus_menu_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.menus_menu_id_seq OWNER TO noolvan;

--
-- Name: menus_menu_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.menus_menu_id_seq OWNED BY public.menus.menu_id;


--
-- Name: model_row_access_policies; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.model_row_access_policies (
    id integer NOT NULL,
    model_id integer NOT NULL,
    action_mask integer DEFAULT 0 NOT NULL,
    scope_field character varying(100) NOT NULL,
    scope_source character varying(20) NOT NULL,
    required boolean DEFAULT true NOT NULL,
    user_override boolean DEFAULT false NOT NULL,
    CONSTRAINT model_row_access_policies_scope_source_check CHECK (((scope_source)::text = ANY ((ARRAY['AUTH_CONTEXT'::character varying, 'USER'::character varying])::text[])))
);


ALTER TABLE public.model_row_access_policies OWNER TO noolvan;

--
-- Name: model_row_access_policies_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.model_row_access_policies_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.model_row_access_policies_id_seq OWNER TO noolvan;

--
-- Name: model_row_access_policies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.model_row_access_policies_id_seq OWNED BY public.model_row_access_policies.id;


--
-- Name: module_features; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.module_features (
    module_feature_id integer NOT NULL,
    module_feature_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    feature_code character varying(100) NOT NULL,
    feature_name character varying(150) NOT NULL,
    module_id integer NOT NULL,
    cloned_from_feature_id integer,
    type character varying(50) DEFAULT 'page'::character varying,
    allowed_table_columns text[],
    is_builtin boolean DEFAULT false,
    created_by integer,
    idate timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.module_features OWNER TO noolvan;

--
-- Name: module_features_module_feature_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.module_features_module_feature_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.module_features_module_feature_id_seq OWNER TO noolvan;

--
-- Name: module_features_module_feature_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.module_features_module_feature_id_seq OWNED BY public.module_features.module_feature_id;


--
-- Name: modules; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.modules (
    module_id integer NOT NULL,
    module_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    module_code character varying(50) NOT NULL,
    module_name character varying(100) NOT NULL,
    app_id integer NOT NULL,
    cloned_from_module_id integer,
    description text,
    icon character varying(50),
    is_builtin boolean DEFAULT false,
    order_no integer DEFAULT 0,
    created_by integer,
    idate timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.modules OWNER TO noolvan;

--
-- Name: modules_module_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.modules_module_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.modules_module_id_seq OWNER TO noolvan;

--
-- Name: modules_module_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.modules_module_id_seq OWNED BY public.modules.module_id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.products (
    product_id integer NOT NULL,
    created_by integer,
    idate timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    test_text character varying(100) NOT NULL,
    test_paragraph text,
    test_number_int text,
    test_number_float numeric NOT NULL,
    test_currency numeric,
    test_percentage numeric,
    test_rating integer,
    test_date date,
    test_date_time timestamp without time zone,
    test_time time without time zone,
    test_duration interval,
    test_yes_no boolean,
    test_single_choice_collection character varying(255),
    test_single_choice_custom_collection character varying(255),
    test_multiple_choice text[],
    test_multiple_choice_collections text[],
    test_autocode character varying(255),
    test_email character varying(255),
    test_phone character varying(255),
    test_website_link character varying(255),
    test_password character varying(255),
    test_color character varying(255),
    test_image character varying(255),
    test_file character varying(255),
    test_releative_roles integer,
    test_rich_text text,
    test_icon character varying(255)
);


ALTER TABLE public.products OWNER TO noolvan;

--
-- Name: products_product_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.products_product_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.products_product_id_seq OWNER TO noolvan;

--
-- Name: products_product_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.products_product_id_seq OWNED BY public.products.product_id;


--
-- Name: role_module_features; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.role_module_features (
    role_module_feature_id integer NOT NULL,
    role_id integer NOT NULL,
    module_feature_id integer NOT NULL,
    is_granted boolean DEFAULT true,
    granted_by integer,
    granted_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.role_module_features OWNER TO noolvan;

--
-- Name: role_module_features_role_module_feature_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.role_module_features_role_module_feature_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.role_module_features_role_module_feature_id_seq OWNER TO noolvan;

--
-- Name: role_module_features_role_module_feature_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.role_module_features_role_module_feature_id_seq OWNED BY public.role_module_features.role_module_feature_id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.roles (
    role_id integer NOT NULL,
    role_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    role_name character varying(100) NOT NULL,
    role_key character varying(100) NOT NULL,
    role_description text,
    company_id integer,
    is_system_role boolean DEFAULT false,
    created_by integer,
    idate timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.roles OWNER TO noolvan;

--
-- Name: roles_role_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.roles_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.roles_role_id_seq OWNER TO noolvan;

--
-- Name: roles_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.roles_role_id_seq OWNED BY public.roles.role_id;


--
-- Name: settings; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.settings (
    setting_id integer NOT NULL,
    group_name character varying(50) NOT NULL,
    setting_key character varying(100) NOT NULL,
    setting_name character varying(100) NOT NULL,
    description text,
    field_type_id integer,
    default_value jsonb,
    value jsonb,
    scope character varying(20) DEFAULT 'global'::character varying,
    tenant_id integer,
    is_built_in boolean DEFAULT false,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    field_config_json jsonb DEFAULT '{}'::jsonb
);


ALTER TABLE public.settings OWNER TO noolvan;

--
-- Name: settings_setting_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.settings_setting_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.settings_setting_id_seq OWNER TO noolvan;

--
-- Name: settings_setting_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.settings_setting_id_seq OWNED BY public.settings.setting_id;


--
-- Name: teams; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.teams (
    team_id integer NOT NULL,
    team_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    team_name character varying(100) NOT NULL,
    team_description text,
    company_id integer NOT NULL,
    parent_team_id integer,
    manager_id integer,
    created_by integer,
    idate timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.teams OWNER TO noolvan;

--
-- Name: teams_team_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.teams_team_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.teams_team_id_seq OWNER TO noolvan;

--
-- Name: teams_team_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.teams_team_id_seq OWNED BY public.teams.team_id;


--
-- Name: tenants; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.tenants (
    tenant_id integer NOT NULL,
    tenant_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_name character varying(200) NOT NULL,
    contact_email character varying(100),
    subscription_plan character varying(50) DEFAULT 'trial'::character varying,
    subscription_status character varying(20) DEFAULT 'active'::character varying,
    subscription_expires_at timestamp without time zone,
    is_active boolean DEFAULT true,
    created_by integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.tenants OWNER TO noolvan;

--
-- Name: tenants_tenant_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.tenants_tenant_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tenants_tenant_id_seq OWNER TO noolvan;

--
-- Name: tenants_tenant_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.tenants_tenant_id_seq OWNED BY public.tenants.tenant_id;


--
-- Name: ui_component_types; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.ui_component_types (
    component_type_id integer NOT NULL,
    type_code character varying(50) NOT NULL,
    type_name character varying(100) NOT NULL,
    category character varying(50) DEFAULT 'basic'::character varying,
    props_schema_json jsonb DEFAULT '{}'::jsonb,
    is_system boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.ui_component_types OWNER TO noolvan;

--
-- Name: ui_component_types_component_type_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.ui_component_types_component_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ui_component_types_component_type_id_seq OWNER TO noolvan;

--
-- Name: ui_component_types_component_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.ui_component_types_component_type_id_seq OWNED BY public.ui_component_types.component_type_id;


--
-- Name: user_account_profiles; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.user_account_profiles (
    profile_id integer NOT NULL,
    profile_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id integer NOT NULL,
    company_id integer,
    profile_name character varying(100),
    is_default boolean DEFAULT false,
    preferences jsonb DEFAULT '{}'::jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_used timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_account_profiles OWNER TO noolvan;

--
-- Name: user_account_profiles_profile_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.user_account_profiles_profile_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_account_profiles_profile_id_seq OWNER TO noolvan;

--
-- Name: user_account_profiles_profile_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.user_account_profiles_profile_id_seq OWNED BY public.user_account_profiles.profile_id;


--
-- Name: user_companies; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.user_companies (
    user_company_id integer NOT NULL,
    user_id integer NOT NULL,
    company_id integer NOT NULL,
    is_primary boolean DEFAULT false,
    is_active boolean DEFAULT true,
    joined_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_companies OWNER TO noolvan;

--
-- Name: user_companies_user_company_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.user_companies_user_company_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_companies_user_company_id_seq OWNER TO noolvan;

--
-- Name: user_companies_user_company_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.user_companies_user_company_id_seq OWNED BY public.user_companies.user_company_id;


--
-- Name: user_group_members; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.user_group_members (
    member_id integer NOT NULL,
    group_id integer NOT NULL,
    user_id integer NOT NULL,
    added_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_group_members OWNER TO noolvan;

--
-- Name: user_group_members_member_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.user_group_members_member_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_group_members_member_id_seq OWNER TO noolvan;

--
-- Name: user_group_members_member_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.user_group_members_member_id_seq OWNED BY public.user_group_members.member_id;


--
-- Name: user_groups; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.user_groups (
    group_id integer NOT NULL,
    group_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    group_name character varying(100) NOT NULL,
    group_description text,
    company_id integer NOT NULL,
    created_by integer,
    idate timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.user_groups OWNER TO noolvan;

--
-- Name: user_groups_group_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.user_groups_group_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_groups_group_id_seq OWNER TO noolvan;

--
-- Name: user_groups_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.user_groups_group_id_seq OWNED BY public.user_groups.group_id;


--
-- Name: user_module_features; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.user_module_features (
    user_module_feature_id integer NOT NULL,
    user_id integer NOT NULL,
    module_feature_id integer NOT NULL,
    is_granted boolean DEFAULT true,
    expiration timestamp without time zone,
    granted_by integer,
    granted_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_module_features OWNER TO noolvan;

--
-- Name: user_module_features_user_module_feature_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.user_module_features_user_module_feature_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_module_features_user_module_feature_id_seq OWNER TO noolvan;

--
-- Name: user_module_features_user_module_feature_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.user_module_features_user_module_feature_id_seq OWNED BY public.user_module_features.user_module_feature_id;


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.user_roles (
    user_role_id integer NOT NULL,
    user_id integer NOT NULL,
    role_id integer NOT NULL,
    company_id integer,
    assigned_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    assigned_by integer
);


ALTER TABLE public.user_roles OWNER TO noolvan;

--
-- Name: user_roles_user_role_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.user_roles_user_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_roles_user_role_id_seq OWNER TO noolvan;

--
-- Name: user_roles_user_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.user_roles_user_role_id_seq OWNED BY public.user_roles.user_role_id;


--
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.user_sessions (
    session_id integer NOT NULL,
    session_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id integer NOT NULL,
    company_id integer,
    login_method character varying(20) NOT NULL,
    login_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_activity timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    expires_at timestamp without time zone,
    device_info jsonb,
    ip_address character varying(45),
    user_agent text,
    is_active boolean DEFAULT true,
    created_by integer
);


ALTER TABLE public.user_sessions OWNER TO noolvan;

--
-- Name: user_sessions_session_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.user_sessions_session_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_sessions_session_id_seq OWNER TO noolvan;

--
-- Name: user_sessions_session_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.user_sessions_session_id_seq OWNED BY public.user_sessions.session_id;


--
-- Name: user_teams; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.user_teams (
    user_team_id integer NOT NULL,
    team_id integer NOT NULL,
    user_id integer NOT NULL,
    role_in_team character varying(50),
    joined_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_teams OWNER TO noolvan;

--
-- Name: user_teams_user_team_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.user_teams_user_team_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_teams_user_team_id_seq OWNER TO noolvan;

--
-- Name: user_teams_user_team_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.user_teams_user_team_id_seq OWNED BY public.user_teams.user_team_id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    user_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    username character varying(100) NOT NULL,
    password character varying(120) NOT NULL,
    first_name character varying(100),
    last_name character varying(100),
    email character varying(100),
    phone character varying(20),
    avatar_url text,
    user_type character varying(20) NOT NULL,
    is_super_admin boolean DEFAULT false,
    ref_table_column character varying(100),
    ref_id integer,
    ref_uuid uuid,
    active_status smallint DEFAULT 1 NOT NULL,
    last_login timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    idate timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT users_active_status_check CHECK ((active_status = ANY (ARRAY[0, 1, 2]))),
    CONSTRAINT users_user_type_check CHECK (((user_type)::text = ANY ((ARRAY['saas_admin'::character varying, 'saas_employee'::character varying, 'saas_reseller'::character varying, 'saas_promoter'::character varying, 'tenant_admin'::character varying, 'tenant_user'::character varying, 'system'::character varying])::text[])))
);


ALTER TABLE public.users OWNER TO noolvan;

--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_user_id_seq OWNER TO noolvan;

--
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- Name: workflow_runs; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.workflow_runs (
    run_id integer NOT NULL,
    run_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    workflow_id integer,
    status character varying(20) DEFAULT 'pending'::character varying,
    trigger_context_json jsonb,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    error_details jsonb
);


ALTER TABLE public.workflow_runs OWNER TO noolvan;

--
-- Name: workflow_runs_run_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.workflow_runs_run_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.workflow_runs_run_id_seq OWNER TO noolvan;

--
-- Name: workflow_runs_run_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.workflow_runs_run_id_seq OWNED BY public.workflow_runs.run_id;


--
-- Name: workflows; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.workflows (
    workflow_id integer NOT NULL,
    workflow_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id integer,
    workflow_name character varying(100) NOT NULL,
    workflow_code character varying(100),
    trigger_config_json jsonb,
    steps_json jsonb DEFAULT '[]'::jsonb NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.workflows OWNER TO noolvan;

--
-- Name: workflows_workflow_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.workflows_workflow_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.workflows_workflow_id_seq OWNER TO noolvan;

--
-- Name: workflows_workflow_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.workflows_workflow_id_seq OWNED BY public.workflows.workflow_id;


--
-- Name: audit_logs_default; Type: TABLE ATTACH; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.audit_logs ATTACH PARTITION public.audit_logs_default DEFAULT;


--
-- Name: actions action_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.actions ALTER COLUMN action_id SET DEFAULT nextval('public.actions_action_id_seq'::regclass);


--
-- Name: ai_knowledge_relations relation_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.ai_knowledge_relations ALTER COLUMN relation_id SET DEFAULT nextval('public.ai_knowledge_relations_relation_id_seq'::regclass);


--
-- Name: api_endpoints endpoint_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.api_endpoints ALTER COLUMN endpoint_id SET DEFAULT nextval('public.api_endpoints_endpoint_id_seq'::regclass);


--
-- Name: app_views app_view_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.app_views ALTER COLUMN app_view_id SET DEFAULT nextval('public.app_views_app_view_id_seq'::regclass);


--
-- Name: apps app_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.apps ALTER COLUMN app_id SET DEFAULT nextval('public.apps_app_id_seq'::regclass);


--
-- Name: archival_policies policy_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.archival_policies ALTER COLUMN policy_id SET DEFAULT nextval('public.archival_policies_policy_id_seq'::regclass);


--
-- Name: assets asset_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.assets ALTER COLUMN asset_id SET DEFAULT nextval('public.assets_asset_id_seq'::regclass);


--
-- Name: audit_logs log_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN log_id SET DEFAULT nextval('public.audit_logs_log_id_seq'::regclass);


--
-- Name: collections collection_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.collections ALTER COLUMN collection_id SET DEFAULT nextval('public.collections_collection_id_seq'::regclass);


--
-- Name: companies company_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.companies ALTER COLUMN company_id SET DEFAULT nextval('public.companies_company_id_seq'::regclass);


--
-- Name: data_flattening_rules rule_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.data_flattening_rules ALTER COLUMN rule_id SET DEFAULT nextval('public.data_flattening_rules_rule_id_seq'::regclass);


--
-- Name: data_model_fields field_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.data_model_fields ALTER COLUMN field_id SET DEFAULT nextval('public.data_model_fields_field_id_seq'::regclass);


--
-- Name: data_models model_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.data_models ALTER COLUMN model_id SET DEFAULT nextval('public.data_models_model_id_seq'::regclass);


--
-- Name: field_permissions field_permission_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.field_permissions ALTER COLUMN field_permission_id SET DEFAULT nextval('public.field_permissions_field_permission_id_seq'::regclass);


--
-- Name: field_types field_type_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.field_types ALTER COLUMN field_type_id SET DEFAULT nextval('public.field_types_field_type_id_seq'::regclass);


--
-- Name: icons icon_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.icons ALTER COLUMN icon_id SET DEFAULT nextval('public.icons_icon_id_seq'::regclass);


--
-- Name: integration_providers provider_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.integration_providers ALTER COLUMN provider_id SET DEFAULT nextval('public.integration_providers_provider_id_seq'::regclass);


--
-- Name: integrations integration_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.integrations ALTER COLUMN integration_id SET DEFAULT nextval('public.integrations_integration_id_seq'::regclass);


--
-- Name: job_queue job_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.job_queue ALTER COLUMN job_id SET DEFAULT nextval('public.job_queue_job_id_seq'::regclass);


--
-- Name: menu_permissions menu_permission_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.menu_permissions ALTER COLUMN menu_permission_id SET DEFAULT nextval('public.menu_permissions_menu_permission_id_seq'::regclass);


--
-- Name: menus menu_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.menus ALTER COLUMN menu_id SET DEFAULT nextval('public.menus_menu_id_seq'::regclass);


--
-- Name: model_row_access_policies id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.model_row_access_policies ALTER COLUMN id SET DEFAULT nextval('public.model_row_access_policies_id_seq'::regclass);


--
-- Name: module_features module_feature_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.module_features ALTER COLUMN module_feature_id SET DEFAULT nextval('public.module_features_module_feature_id_seq'::regclass);


--
-- Name: modules module_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.modules ALTER COLUMN module_id SET DEFAULT nextval('public.modules_module_id_seq'::regclass);


--
-- Name: products product_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.products ALTER COLUMN product_id SET DEFAULT nextval('public.products_product_id_seq'::regclass);


--
-- Name: role_module_features role_module_feature_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.role_module_features ALTER COLUMN role_module_feature_id SET DEFAULT nextval('public.role_module_features_role_module_feature_id_seq'::regclass);


--
-- Name: roles role_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.roles ALTER COLUMN role_id SET DEFAULT nextval('public.roles_role_id_seq'::regclass);


--
-- Name: settings setting_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.settings ALTER COLUMN setting_id SET DEFAULT nextval('public.settings_setting_id_seq'::regclass);


--
-- Name: teams team_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.teams ALTER COLUMN team_id SET DEFAULT nextval('public.teams_team_id_seq'::regclass);


--
-- Name: tenants tenant_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.tenants ALTER COLUMN tenant_id SET DEFAULT nextval('public.tenants_tenant_id_seq'::regclass);


--
-- Name: ui_component_types component_type_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.ui_component_types ALTER COLUMN component_type_id SET DEFAULT nextval('public.ui_component_types_component_type_id_seq'::regclass);


--
-- Name: user_account_profiles profile_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_account_profiles ALTER COLUMN profile_id SET DEFAULT nextval('public.user_account_profiles_profile_id_seq'::regclass);


--
-- Name: user_companies user_company_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_companies ALTER COLUMN user_company_id SET DEFAULT nextval('public.user_companies_user_company_id_seq'::regclass);


--
-- Name: user_group_members member_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_group_members ALTER COLUMN member_id SET DEFAULT nextval('public.user_group_members_member_id_seq'::regclass);


--
-- Name: user_groups group_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_groups ALTER COLUMN group_id SET DEFAULT nextval('public.user_groups_group_id_seq'::regclass);


--
-- Name: user_module_features user_module_feature_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_module_features ALTER COLUMN user_module_feature_id SET DEFAULT nextval('public.user_module_features_user_module_feature_id_seq'::regclass);


--
-- Name: user_roles user_role_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_roles ALTER COLUMN user_role_id SET DEFAULT nextval('public.user_roles_user_role_id_seq'::regclass);


--
-- Name: user_sessions session_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_sessions ALTER COLUMN session_id SET DEFAULT nextval('public.user_sessions_session_id_seq'::regclass);


--
-- Name: user_teams user_team_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_teams ALTER COLUMN user_team_id SET DEFAULT nextval('public.user_teams_user_team_id_seq'::regclass);


--
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- Name: workflow_runs run_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.workflow_runs ALTER COLUMN run_id SET DEFAULT nextval('public.workflow_runs_run_id_seq'::regclass);


--
-- Name: workflows workflow_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.workflows ALTER COLUMN workflow_id SET DEFAULT nextval('public.workflows_workflow_id_seq'::regclass);


--
-- Data for Name: actions; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.actions (action_id, action_code, action_name, description, handler_function, inputs_schema_json, outputs_schema_json, is_idempotent, queue_concurrency_mode, queue_concurrency_limit, default_timeout_seconds, retry_policy_json, is_active) FROM stdin;
1	app_clone	Clone Application	\N	AppService.clone	{"app_id": {"type": "integer"}, "target_company_id": {"type": "integer"}}	{}	f	sequential	1	600	{"backoff": "exponential", "max_retries": 3}	t
2	tenant_provision	Provision New Tenant	\N	TenantService.provision	{"tenant_name": {"type": "string"}}	{}	f	sequential	2	300	{"backoff": "exponential", "max_retries": 3}	t
3	data_import	Bulk Data Import	\N	DataService.import	{"file_url": {"type": "string"}, "target_model": {"type": "string"}}	{}	f	parallel	3	1800	{"backoff": "exponential", "max_retries": 3}	t
4	data_export	Data Export	\N	DataService.export	{"filters": {"type": "object"}, "model_id": {"type": "integer"}}	{}	t	parallel	5	1800	{"backoff": "exponential", "max_retries": 3}	t
5	send_email	Send Email	\N	CommsService.sendEmail	{"to": {"type": "email"}, "body": {"type": "text"}, "subject": {"type": "string"}}	{}	t	parallel	20	300	{"backoff": "exponential", "max_retries": 3}	t
6	notification_push	Send Push Notification	\N	CommsService.sendPush	{"message": {"type": "string"}, "user_id": {"type": "integer"}}	{}	t	parallel	50	60	{"backoff": "exponential", "max_retries": 3}	t
7	system_cleanup	Daily Cleanup	\N	MaintenanceService.cleanup	{}	{}	t	sequential	1	3600	{"backoff": "exponential", "max_retries": 3}	t
8	search_reindex	Re-index Search	\N	SearchService.reindex	{}	{}	t	sequential	1	7200	{"backoff": "exponential", "max_retries": 3}	t
\.


--
-- Data for Name: ai_entity_aliases; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.ai_entity_aliases (alias, canonical_node_id) FROM stdin;
karan_admin	person:karan
boss_man	person:karan
proj_alpha	concept:project_alpha
\.


--
-- Data for Name: ai_events; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.ai_events (event_id, subject, predicate, object, subject_node_id, object_node_id, attributes, occurred_at, recorded_at, is_active) FROM stdin;
7cf35083-4d35-4a37-8803-e5d8b4e708e0	Karan	created	Project Alpha	person:karan	concept:project_alpha	{"method": "web_ui"}	2026-01-05 23:29:01.996018	2026-01-15 23:29:01.996018	t
42568c16-7893-4fe3-af5a-de3d3901b520	Sundar	committed	Code Change #123	person:sundar	\N	{"lines_added": 50}	2026-01-13 23:29:01.996018	2026-01-15 23:29:01.996018	t
\.


--
-- Data for Name: ai_knowledge_nodes; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.ai_knowledge_nodes (node_id, node_type, title, description, content, is_active, version, created_at, updated_at) FROM stdin;
person:karan	entity	Karan	A user of the system	{"role": "admin", "email": "karan@example.com"}	t	1	2026-01-15 23:29:01.996018	2026-01-15 23:29:01.996018
person:sundar	entity	Sundar	A collaborator	{"role": "editor", "email": "sundar@example.com"}	t	1	2026-01-15 23:29:01.996018	2026-01-15 23:29:01.996018
concept:payment	concept	Payment	Transfer of value	{"methods": ["bank", "upi", "card"]}	t	1	2026-01-15 23:29:01.996018	2026-01-15 23:29:01.996018
concept:project_alpha	entity	Project Alpha	Top secret initiative	{"budget": 100000, "status": "active"}	t	1	2026-01-15 23:29:01.996018	2026-01-15 23:29:01.996018
\.


--
-- Data for Name: ai_knowledge_relations; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.ai_knowledge_relations (relation_id, from_node, to_node, relation, attributes, is_active, created_at) FROM stdin;
1	person:karan	concept:project_alpha	manages	{"since": "2025-01-01"}	t	2026-01-15 23:29:01.996018
2	person:sundar	concept:project_alpha	contributes_to	{"role": "developer"}	t	2026-01-15 23:29:01.996018
3	person:karan	concept:payment	can_approve	{}	t	2026-01-15 23:29:01.996018
\.


--
-- Data for Name: ai_knowledge_vectors; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.ai_knowledge_vectors (vector_id, target_node_id, embedding, embedding_model, embedding_version, searchable_text, is_active, updated_at) FROM stdin;
\.


--
-- Data for Name: ai_query_plans; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.ai_query_plans (plan_id, user_query, planner_json, confidence, execution_type, generated_sql, status, error_message, latency_ms, created_at) FROM stdin;
\.


--
-- Data for Name: ai_rules; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.ai_rules (rule_id, rule_name, description, condition, action, priority, is_active, created_at, updated_at) FROM stdin;
c6e7b16c-b848-4784-98da-b3a424feabe0	High Value Payment Alert	\N	{"op": ">", "field": "amount", "value": 10000}	{"alert": "compliance_team", "severity": "high"}	10	t	2026-01-15 23:29:01.996018	2026-01-15 23:29:01.996018
aa1330f6-7746-4b82-83ca-46db11a02d7d	Inactive Project Archive	\N	{"op": ">", "days": 90, "field": "last_activity"}	{"status": "archived"}	5	t	2026-01-15 23:29:01.996018	2026-01-15 23:29:01.996018
\.


--
-- Data for Name: api_endpoints; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.api_endpoints (endpoint_id, endpoint_uuid, path, method, type, related_model_id, flattening_rule_id, custom_logic_json, permission_required, is_builtin, created_by, idate, last_updated) FROM stdin;
\.


--
-- Data for Name: app_views; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.app_views (app_view_id, app_view_uuid, model_id, view_type, view_name, view_config, endpoint_id, is_default, is_builtin, created_by, idate, last_updated) FROM stdin;
\.


--
-- Data for Name: apps; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.apps (app_id, app_uuid, app_name, app_title, app_image_url, app_description, tenant_id, company_id, cloned_from_app_id, is_saas_default, is_tenant_default, is_store_app, is_builtin, order_no, created_by, idate, last_updated, is_active) FROM stdin;
1	92a19143-3518-4044-91be-b1ffa6b9f950	dashboards	Dashboards	https://cdn.avkaran.com/dashboards_app_icon.png	Dashboard and analytics application	\N	\N	\N	t	t	f	t	1	\N	2026-01-15 23:29:03.114175	2026-01-16 01:58:46.119529	t
4	05ffd05f-ca56-4dd7-a256-4a60f2d164ed	organization	Organization	/assets/organization_app_icon.svg	Company, users, roles and permissions	\N	\N	\N	t	f	f	t	20	1	2026-01-16 01:58:46.119529	2026-01-16 02:14:09.797449	t
5	5f3d850a-a769-444d-8884-503411ba2654	app_studio	App Studio	/assets/app_studio_app_icon.svg	Low-code studio (models, views, menus, APIs)	\N	\N	\N	t	f	f	t	30	1	2026-01-16 01:58:46.119529	2026-01-16 02:14:09.812012	t
6	f56efbee-6e29-4cb3-9eeb-aa4c8f7a011f	settings	Settings	/assets/settings_app_icon.svg	Platform settings	\N	\N	\N	t	f	f	t	40	1	2026-01-16 01:58:46.119529	2026-01-16 02:14:09.817599	t
7	265ffafa-642e-4d43-aeba-a5924765f618	developer_console	Dev Console	/assets/developer_console_app_icon.svg	Database administration and query tools	\N	\N	\N	t	f	f	t	50	1	2026-01-17 01:47:18.91518	2026-01-17 01:47:18.959375	t
\.


--
-- Data for Name: archival_policies; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.archival_policies (policy_id, model_id, tenant_id, l2_criteria_json, archive_table_name, l3_criteria_json, s3_config_json, is_active, created_by, last_updated) FROM stdin;
\.


--
-- Data for Name: assets; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.assets (asset_id, asset_uuid, company_id, file_name, original_name, mime_type, file_size, storage_provider, storage_path, public_url, is_public, related_model, related_id, uploaded_by, uploaded_at) FROM stdin;
1	335298b3-ba4c-46fe-94ef-22e419419c9a	1	dashboards_app_icon.png	dashboards_app_icon.png	image/png	21746	s3	websites/noolva/assets/dashboards_app_icon.png	https://cdn.avkaran.com/websites/noolva/assets/dashboards_app_icon.png	t	\N	\N	1	2026-01-15 23:30:08.764001
2	cca404b5-902c-4bc5-a835-fd152c56db93	1	users_app_icon.png	users_app_icon.png	image/png	47393	s3	websites/noolva/assets/users_app_icon.png	https://cdn.avkaran.com/websites/noolva/assets/users_app_icon.png	t	\N	\N	1	2026-01-15 23:30:09.484509
\.


--
-- Data for Name: audit_logs_default; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.audit_logs_default (log_id, event_time, tenant_id, user_id, event_category, event_action, target_model, target_record_id, changes_json, metadata_json) FROM stdin;
\.


--
-- Data for Name: collections; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.collections (collection_id, collection_uuid, collection_name, collection_code, tenant_id, is_system, created_by, created_at, last_updated, field_type_id, field_config_json) FROM stdin;
1	abf30cdd-3771-417b-a649-45e303975f9b	System User Types	system_user_types	\N	t	1	2026-01-25 02:23:32.317886	2026-01-25 02:23:32.317886	\N	{"items": [{"label": "SaaS Admin", "value": "saas_admin"}, {"label": "SaaS Employee", "value": "saas_employee"}, {"label": "SaaS Reseller", "value": "saas_reseller"}, {"label": "SaaS Promoter", "value": "saas_promoter"}, {"label": "Tenant Admin", "value": "tenant_admin"}, {"label": "Tenant User", "value": "tenant_user"}, {"label": "System", "value": "system"}]}
\.


--
-- Data for Name: companies; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.companies (company_id, company_uuid, tenant_id, company_name, company_code, domain, logo_url, branding_config, parent_company_id, is_default, is_active, created_by, idate, last_updated) FROM stdin;
1	e97769dd-eae3-456d-8d84-3923b6b94858	1	Your Company	your-company	\N	\N	\N	\N	t	t	\N	2026-01-15 23:29:03.114175	2026-01-15 23:29:03.114175
\.


--
-- Data for Name: data_flattening_rules; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.data_flattening_rules (rule_id, rule_uuid, rule_name, rule_code, source_model_id, target_model_name, computation_config_json, refresh_policy_json, is_active, created_by, last_updated) FROM stdin;
\.


--
-- Data for Name: data_model_fields; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.data_model_fields (field_id, model_id, field_name, display_name, field_type_id, field_config_json, is_required, is_unique, is_primary_key, default_value, encryption_method, ui_component, order_no, idate) FROM stdin;
1	1	user_id	User ID	1	{}	t	t	t	\N	none	\N	1	2026-01-18 00:33:45.084095
2	1	user_uuid	User UUID	1	{}	t	t	f	\N	none	\N	2	2026-01-18 00:33:45.084095
3	1	username	Username	1	{"max_length": 100}	t	t	f	\N	none	\N	3	2026-01-18 00:33:45.084095
4	1	password	Password	1	{"max_length": 120, "is_password": true}	t	f	f	\N	none	\N	4	2026-01-18 00:33:45.084095
5	1	first_name	First Name	1	{"max_length": 100}	f	f	f	\N	none	\N	5	2026-01-18 00:33:45.084095
6	1	last_name	Last Name	1	{"max_length": 100}	f	f	f	\N	none	\N	6	2026-01-18 00:33:45.084095
7	1	email	Email	1	{"max_length": 100, "validation": "email"}	f	f	f	\N	none	\N	7	2026-01-18 00:33:45.084095
8	1	phone	Phone	1	{"max_length": 20}	f	f	f	\N	none	\N	8	2026-01-18 00:33:45.084095
9	1	avatar_url	Avatar URL	1	{"validation": "url"}	f	f	f	\N	none	\N	9	2026-01-18 00:33:45.084095
10	1	user_type	User Type	1	{"options": ["saas_admin", "saas_employee", "saas_reseller", "saas_promoter", "tenant_admin", "tenant_user", "system"], "max_length": 20}	t	f	f	\N	none	\N	10	2026-01-18 00:33:45.084095
11	1	is_super_admin	Is Super Admin	12	{}	f	f	f	false	none	\N	11	2026-01-18 00:33:45.084095
12	1	active_status	Active Status	1	{"options": [{"label": "Inactive", "value": 0}, {"label": "Active", "value": 1}, {"label": "Suspended", "value": 2}]}	t	f	f	1	none	\N	12	2026-01-18 00:33:45.084095
13	1	last_login	Last Login	1	{}	f	f	f	\N	none	\N	13	2026-01-18 00:33:45.084095
14	1	created_by	Created By	1	{}	f	f	f	\N	none	\N	14	2026-01-18 00:33:45.084095
15	1	idate	Created Date	1	{}	t	f	f	\N	none	\N	15	2026-01-18 00:33:45.084095
16	1	last_updated	Last Updated	1	{}	t	f	f	\N	none	\N	16	2026-01-18 00:33:45.084095
33	6	group_id	Group ID	4	{}	t	t	t	\N	none	\N	1	2026-01-18 01:14:59.269326
34	6	group_uuid	Group UUID	1	{}	t	t	f	\N	none	\N	2	2026-01-18 01:14:59.269326
35	6	group_name	Group Name	1	{"max_length": 100}	t	f	f	\N	none	\N	3	2026-01-18 01:14:59.269326
36	6	group_description	Group Description	1	{"max_length": 1000}	f	f	f	\N	none	\N	4	2026-01-18 01:14:59.269326
37	6	company_id	Company ID	4	{}	t	f	f	\N	none	\N	5	2026-01-18 01:14:59.269326
38	6	created_by	Created By	4	{}	f	f	f	\N	none	\N	6	2026-01-18 01:14:59.269326
39	6	idate	Created Date	9	{}	t	f	f	\N	none	\N	7	2026-01-18 01:14:59.269326
40	6	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	8	2026-01-18 01:14:59.269326
41	7	role_id	Role ID	4	{}	t	t	t	\N	none	\N	1	2026-01-18 01:14:59.440739
42	7	role_uuid	Role UUID	1	{}	t	t	f	\N	none	\N	2	2026-01-18 01:14:59.440739
43	7	role_name	Role Name	1	{"max_length": 100}	t	f	f	\N	none	\N	3	2026-01-18 01:14:59.440739
44	7	role_key	Role Key	1	{"max_length": 100}	t	f	f	\N	none	\N	4	2026-01-18 01:14:59.440739
45	7	role_description	Role Description	1	{"max_length": 1000}	f	f	f	\N	none	\N	5	2026-01-18 01:14:59.440739
46	7	company_id	Company ID	4	{}	f	f	f	\N	none	\N	6	2026-01-18 01:14:59.440739
47	7	is_system_role	Is System Role	12	{}	f	f	f	false	none	\N	7	2026-01-18 01:14:59.440739
48	7	created_by	Created By	4	{}	f	f	f	\N	none	\N	8	2026-01-18 01:14:59.440739
49	7	idate	Created Date	9	{}	t	f	f	\N	none	\N	9	2026-01-18 01:14:59.440739
50	7	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	10	2026-01-18 01:14:59.440739
51	6	group_id	Group ID	4	{}	t	t	t	\N	none	\N	1	2026-01-18 01:15:37.550929
52	6	group_uuid	Group UUID	1	{}	t	t	f	\N	none	\N	2	2026-01-18 01:15:37.550929
53	6	group_name	Group Name	1	{"max_length": 100}	t	f	f	\N	none	\N	3	2026-01-18 01:15:37.550929
54	6	group_description	Group Description	1	{"max_length": 1000}	f	f	f	\N	none	\N	4	2026-01-18 01:15:37.550929
55	6	company_id	Company ID	4	{}	t	f	f	\N	none	\N	5	2026-01-18 01:15:37.550929
56	6	created_by	Created By	4	{}	f	f	f	\N	none	\N	6	2026-01-18 01:15:37.550929
57	6	idate	Created Date	9	{}	t	f	f	\N	none	\N	7	2026-01-18 01:15:37.550929
58	6	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	8	2026-01-18 01:15:37.550929
59	9	team_id	Team ID	4	{}	t	t	t	\N	none	\N	1	2026-01-18 01:15:37.595914
60	9	team_uuid	Team UUID	1	{}	t	t	f	\N	none	\N	2	2026-01-18 01:15:37.595914
61	9	team_name	Team Name	1	{"max_length": 100}	t	f	f	\N	none	\N	3	2026-01-18 01:15:37.595914
62	9	team_description	Team Description	1	{"max_length": 1000}	f	f	f	\N	none	\N	4	2026-01-18 01:15:37.595914
63	9	company_id	Company ID	4	{}	t	f	f	\N	none	\N	5	2026-01-18 01:15:37.595914
64	9	parent_team_id	Parent Team ID	4	{}	f	f	f	\N	none	\N	6	2026-01-18 01:15:37.595914
65	9	manager_id	Manager ID	4	{}	f	f	f	\N	none	\N	7	2026-01-18 01:15:37.595914
66	9	created_by	Created By	4	{}	f	f	f	\N	none	\N	8	2026-01-18 01:15:37.595914
67	9	idate	Created Date	9	{}	t	f	f	\N	none	\N	9	2026-01-18 01:15:37.595914
68	9	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	10	2026-01-18 01:15:37.595914
69	7	role_id	Role ID	4	{}	t	t	t	\N	none	\N	1	2026-01-18 01:15:37.615064
70	7	role_uuid	Role UUID	1	{}	t	t	f	\N	none	\N	2	2026-01-18 01:15:37.615064
71	7	role_name	Role Name	1	{"max_length": 100}	t	f	f	\N	none	\N	3	2026-01-18 01:15:37.615064
72	7	role_key	Role Key	1	{"max_length": 100}	t	f	f	\N	none	\N	4	2026-01-18 01:15:37.615064
73	7	role_description	Role Description	1	{"max_length": 1000}	f	f	f	\N	none	\N	5	2026-01-18 01:15:37.615064
74	7	company_id	Company ID	4	{}	f	f	f	\N	none	\N	6	2026-01-18 01:15:37.615064
75	7	is_system_role	Is System Role	12	{}	f	f	f	false	none	\N	7	2026-01-18 01:15:37.615064
76	7	created_by	Created By	4	{}	f	f	f	\N	none	\N	8	2026-01-18 01:15:37.615064
77	7	idate	Created Date	9	{}	t	f	f	\N	none	\N	9	2026-01-18 01:15:37.615064
78	7	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	10	2026-01-18 01:15:37.615064
79	11	company_id	Company ID	4	{}	t	t	t	\N	none	\N	1	2026-01-18 01:15:37.637979
80	11	company_uuid	Company UUID	1	{}	t	t	f	\N	none	\N	2	2026-01-18 01:15:37.637979
81	11	tenant_id	Tenant ID	4	{}	t	f	f	\N	none	\N	3	2026-01-18 01:15:37.637979
82	11	company_name	Company Name	1	{"max_length": 200}	t	f	f	\N	none	\N	4	2026-01-18 01:15:37.637979
83	11	company_code	Company Code	1	{"max_length": 50}	t	t	f	\N	none	\N	5	2026-01-18 01:15:37.637979
84	11	domain	Domain	1	{"max_length": 100, "validation": "domain"}	f	f	f	\N	none	\N	6	2026-01-18 01:15:37.637979
85	11	logo_url	Logo URL	1	{"validation": "url"}	f	f	f	\N	none	\N	7	2026-01-18 01:15:37.637979
86	11	branding_config	Branding Config	14	{}	f	f	f	\N	none	\N	8	2026-01-18 01:15:37.637979
87	11	parent_company_id	Parent Company ID	4	{}	f	f	f	\N	none	\N	9	2026-01-18 01:15:37.637979
88	11	is_default	Is Default	12	{}	f	f	f	false	none	\N	10	2026-01-18 01:15:37.637979
89	11	is_active	Is Active	12	{}	f	f	f	true	none	\N	11	2026-01-18 01:15:37.637979
90	11	created_by	Created By	4	{}	f	f	f	\N	none	\N	12	2026-01-18 01:15:37.637979
91	11	idate	Created Date	9	{}	t	f	f	\N	none	\N	13	2026-01-18 01:15:37.637979
92	11	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	14	2026-01-18 01:15:37.637979
97	14	product_id	ID	4	{}	f	f	t	\N	none	\N	1	2026-01-31 00:06:25.993984
98	14	created_by	Created By	3	{}	f	f	f	\N	none	\N	2	2026-01-31 00:06:26.042875
99	14	idate	Created Date	9	{}	t	f	f	\N	none	\N	3	2026-01-31 00:06:26.06297
100	14	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	4	2026-01-31 00:06:26.077537
102	14	test_paragraph	test paragraph	2	{"max_line_counts": 3}	f	f	f	\N	none	\N	6	2026-01-31 01:03:18.824626
103	14	test_number_int	test_number_int	2	{"maximum_digits": 10, "allowed_decimal_places": 0}	f	f	f	\N	none	\N	7	2026-01-31 01:12:56.4294
104	14	test_number_float	test number float	3	{"maximum_digits": 10, "allowed_decimal_places": 2}	t	f	f	\N	none	\N	8	2026-01-31 01:13:23.225498
106	14	test_percentage	test_percentage	6	{"scale": 2, "precision": 5}	f	f	f	\N	none	\N	10	2026-01-31 01:16:23.365613
107	14	test_rating	test rating	7	{"max_stars": 5}	f	f	f	\N	none	\N	11	2026-01-31 01:16:48.620412
109	14	test_date	test date	8	{}	f	f	f	\N	none	\N	12	2026-01-31 01:26:58.462228
110	14	test_date_time	test date time	9	{}	f	f	f	\N	none	\N	13	2026-01-31 01:27:37.56473
111	14	test_time	test time	10	{}	f	f	f	\N	none	\N	14	2026-01-31 01:28:08.134989
112	14	test_duration	test duration	11	{}	f	f	f	\N	none	\N	15	2026-01-31 01:29:12.472905
113	14	test_yes_no	test_yes_no	12	{}	f	f	f	\N	none	\N	16	2026-01-31 01:31:41.755356
117	14	test_single_choice_custom_collection	test single choice custom collection	13	{"options": [{"label": "high", "value": "1"}, {"label": "low", "value": "2"}, {"label": "lowest", "value": "3"}], "options_mode": "custom_collection", "collection_code": ""}	f	f	f	\N	none	\N	18	2026-01-31 01:47:40.377842
118	14	test_multiple_choice	test multiple choice	14	{"options": [{"label": "tv", "value": "tv"}, {"label": "fridge", "value": "fridge"}, {"label": "washing machine", "value": "washing_machine"}], "options_mode": "custom_collection"}	f	f	f	\N	none	\N	19	2026-01-31 01:48:47.464841
119	14	test_multiple_choice_collections	test multiple choice collections	14	{"options": [], "options_mode": "collections", "collection_id": 1}	f	f	f	\N	none	\N	20	2026-01-31 01:49:26.484475
105	14	test_currency	test currency	5	{"maximum_digits": 10, "currency_symbol": "₹", "allowed_decimal_places": 2}	f	f	f	\N	none	\N	9	2026-01-31 01:15:53.25789
116	14	test_single_choice_collection	test single choice collection	13	{"options": [], "options_mode": "collections", "collection_id": 1}	f	f	f	\N	none	\N	17	2026-01-31 01:46:42.005422
121	14	test_email	test_email	15	{"validation_regex": "^[^@]+@[^@]+\\\\.[^@]+$"}	f	f	f	\N	none	\N	22	2026-01-31 23:15:55.060187
101	14	test_text	test_text	1	{"max_length": 100}	t	f	f	\N	none	\N	5	2026-01-31 01:00:30.83642
120	14	test_autocode	test_autocode	30	{"pattern": [{"type": "prefix", "value": "CODE"}, {"type": "separator", "value": "-"}, {"type": "date", "format": "YYYY-MM"}, {"type": "separator", "value": "-"}, {"type": "increment", "start": 1, "padding": 4}]}	f	f	f	\N	none	\N	21	2026-01-31 23:14:45.187309
122	14	test_phone	test phone	16	{}	f	f	f	\N	none	\N	23	2026-01-31 23:26:07.433107
123	14	test_website_link	test_website_link	17	{}	f	f	f	\N	none	\N	24	2026-01-31 23:26:38.491669
124	14	test_password	test password	18	{}	f	f	f	\N	aes	\N	25	2026-01-31 23:27:16.56047
125	14	test_color	test color	19	{}	f	f	f	\N	none	\N	26	2026-01-31 23:28:07.584067
126	14	test_image	test image	20	{"filters": [".jpg", ".png"], "multiple": false, "allow_crop": true, "crop_ratio": "1:1", "crop_shape": "circle", "max_size_mb": 2}	f	f	f	\N	none	\N	27	2026-01-31 23:29:39.47562
127	14	test_file	test file	21	{"filters": [".pdf", ".zip"], "multiple": false, "is_multiple": true, "max_size_mb": 2}	f	f	f	\N	none	\N	28	2026-01-31 23:30:53.250585
128	14	test_releative_roles	test_releative_roles	26	{"target_field": "role_id", "target_model": "roles", "relation_type": "one_to_many"}	f	f	f	\N	none	\N	29	2026-01-31 23:32:27.547648
129	14	test_rich_text	test rich text	27	{"content_type": "html"}	f	f	f	\N	none	\N	30	2026-01-31 23:34:08.696621
130	14	test_icon	test_icon	29	{"format": "prefix:name", "examples": ["fa:heart", "antd:download", "smily:thanks", "custom:myhome"]}	f	f	f	\N	none	\N	31	2026-01-31 23:34:30.19503
\.


--
-- Data for Name: data_models; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.data_models (model_id, model_uuid, app_id, model_name, display_name, table_name, is_public, is_system_model, is_active, description, created_by, idate, last_updated, table_alias, model_scope) FROM stdin;
1	da70d8e4-da66-45a1-8195-d357f2aa5a00	5	users	Users	users	f	t	t	User management table - stores user accounts and authentication information	1	2026-01-18 00:33:45.084095	2026-01-18 00:33:45.084095	\N	saas
6	bfc3ed66-459e-4db5-8cc0-19ec28ffe6a2	5	user_groups	User Groups	user_groups	f	t	t	User groups table - organizes users into groups within a company	1	2026-01-18 01:14:59.269326	2026-01-18 01:14:59.269326	\N	saas
7	73a08e4d-2faf-4216-8f44-f179f7c64b38	5	roles	Roles	roles	f	t	t	Roles table - defines role-based access control roles	1	2026-01-18 01:14:59.440739	2026-01-18 01:14:59.440739	\N	saas
9	ca3b0fa1-08e2-4d48-9fbe-ca60beb3914c	5	teams	Teams	teams	f	t	t	Teams table - organizes users into teams with hierarchy and management	1	2026-01-18 01:15:37.595914	2026-01-18 01:15:37.595914	\N	saas
11	3245e49b-28f5-4e1e-8da4-398a524326fc	5	companies	Companies	companies	f	t	t	Companies table - manages company/organization entities within tenants	1	2026-01-18 01:15:37.637979	2026-01-18 01:15:37.637979	\N	saas
14	eec58720-7d8a-49b9-97bd-c71175e1a2a1	\N	products	products	products	f	f	t	\N	2	2026-01-31 00:06:25.832581	2026-01-31 00:06:25.832581	p	saas
\.


--
-- Data for Name: field_permissions; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.field_permissions (field_permission_id, role_id, model_id, field_name, action_mask) FROM stdin;
\.


--
-- Data for Name: field_types; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.field_types (field_type_id, type_name, type_code, category, actual_db_type, default_component_type_id, default_props_json, icon, is_active, created_at, input_type_image, order_no) FROM stdin;
5	Currency	currency	advanced	NUMERIC	8	{"maximum_digits": 10, "currency_symbol": "₹", "allowed_decimal_places": 2}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_currency.svg	5
13	Single Choice	single_choice	advanced	VARCHAR	6	{"options": [], "options_mode": "custom_collection", "collection_id": ""}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_single_choice.svg	13
30	Auto Code	auto_code	advanced	VARCHAR	6	{"pattern": [{"type": "prefix", "value": "CODE"}, {"type": "separator", "value": "-"}, {"type": "date", "format": "YYYY-MM"}, {"type": "separator", "value": "-"}, {"type": "increment", "start": 1, "padding": 4}]}	\N	t	2026-01-19 00:56:42.607067	field_types/field_type_auto_code.svg	15
26	Relative Field	relation	relational	INTEGER	9	{"target_model": null, "relation_type": "one_to_many"}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_relation.svg	27
27	Rich Text	rich_text	advanced	TEXT	7	{"content_type": "markdown"}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_rich_text.svg	28
28	JSON	json	advanced	JSONB	7	{}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_json.svg	29
29	Icon	icon	media	VARCHAR	9	{"format": "prefix:name", "examples": ["fa:heart", "antd:download", "smily:thanks", "custom:myhome"]}	icon	t	2026-01-18 17:53:48.668856	field_types/field_type_icon.svg	30
15	Email Address	email	basic	VARCHAR	6	{"validation_regex": "^[^@]+@[^@]+\\\\.[^@]+$"}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_email.svg	16
16	Phone Number	phone	basic	VARCHAR	6	{}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_phone.svg	17
17	Website Link	url	basic	VARCHAR	6	{}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_url.svg	18
18	Password	password	advanced	VARCHAR	6	{}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_password.svg	19
19	Color	color	advanced	VARCHAR	6	{}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_color.svg	20
20	Image	image	media	VARCHAR	14	{"multiple": false}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_image.svg	21
21	File	file	media	VARCHAR	14	{"multiple": false}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_file.svg	22
22	Video	video	media	VARCHAR	14	{}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_video.svg	23
23	Audio	audio	media	VARCHAR	14	{"storage_provider": "s3"}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_audio.svg	24
24	Address	address	advanced	JSONB	4	{"fields": ["street", "city", "zip", "country"]}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_address.svg	25
25	Map Location	location	advanced	POINT	6	{}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_location.svg	26
3	Number	number	basic	NUMERIC	8	{"maximum_digits": 10, "allowed_decimal_places": 0}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_number.svg	3
1	Text	text	basic	VARCHAR	6	{"max_length": 100}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_text.svg	1
2	Paragraph	paragraph	basic	TEXT	7	{"max_line_counts": 3}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_paragraph.svg	2
14	Multiple Choice	multi_choice	basic	TEXT[]	9	{"options": [], "options_mode": "custom_collection"}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_multi_choice.svg	14
4	Auto Number	auto_number	advanced	SERIAL	15	{}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_auto_number.svg	4
6	Percentage	percentage	advanced	NUMERIC	8	{"scale": 2, "precision": 5}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_percentage.svg	6
7	Rating	rating	advanced	INTEGER	8	{"max_stars": 5}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_rating.svg	7
8	Date	date	basic	DATE	10	{}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_date.svg	8
9	DateTime	datetime	basic	TIMESTAMP	10	{}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_datetime.svg	9
10	Time	time	basic	TIME	10	{}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_time.svg	10
11	Duration	duration	advanced	INTERVAL	6	{}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_duration.svg	11
12	Yes/No	boolean	basic	BOOLEAN	11	{}	\N	t	2026-01-15 23:29:03.114175	field_types/field_type_boolean.svg	12
\.


--
-- Data for Name: icons; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.icons (icon_id, icon_uuid, icon_code, icon_type, icon_name, category, description, tags, icon_data, usage_count, is_popular, is_free, is_active, created_by, created_at, last_updated) FROM stdin;
1	c50397a5-d043-4791-8888-bc506d4175e4	fa:home	fa	Home	navigation	Home icon	{home,house,main,dashboard}	{"class": "fas fa-home"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
2	aef58295-76db-47aa-b492-856e0bb971f8	fa:user	fa	User	users	User profile icon	{user,person,profile,account}	{"class": "fas fa-user"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
3	165ba39f-16f3-475a-beda-eb0907e28ea7	fa:users	fa	Users	users	Multiple users icon	{users,people,team,group}	{"class": "fas fa-users"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
4	7c117ced-6868-41d7-8104-a1880ef1c8e7	fa:cog	fa	Settings	settings	Settings/gear icon	{settings,gear,config,preferences}	{"class": "fas fa-cog"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
5	51067c60-bbb5-4a0f-9fd7-d5a930ca455e	fa:search	fa	Search	actions	Search icon	{search,find,magnify}	{"class": "fas fa-search"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
6	0df02935-4491-4e66-88d9-3df4a9f027cf	fa:bell	fa	Notifications	notifications	Bell/notification icon	{bell,notification,alert}	{"class": "fas fa-bell"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
7	052c0c21-23c4-4463-9035-43c248147021	fa:heart	fa	Heart	social	Heart/like icon	{heart,like,love,favorite}	{"class": "fas fa-heart"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
8	08adfa05-02b7-4e84-8042-9c0c085a82d4	fa:star	fa	Star	ratings	Star icon	{star,favorite,rating}	{"class": "fas fa-star"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
9	bec768c6-768b-4b51-897f-59b68062297a	fa:envelope	fa	Email	communication	Email/envelope icon	{email,mail,message}	{"class": "fas fa-envelope"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
10	24f283b0-afd7-4aed-8b1b-23181e059a5a	fa:phone	fa	Phone	communication	Phone icon	{phone,call,telephone}	{"class": "fas fa-phone"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
11	fe629972-de72-4909-9d4e-b423042fad54	fa:plus	fa	Add	actions	Plus/add icon	{add,plus,new,create}	{"class": "fas fa-plus"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
12	5a3ff3ca-1eea-48f1-a873-78d620c42590	fa:edit	fa	Edit	actions	Edit/pencil icon	{edit,modify,pencil,update}	{"class": "fas fa-edit"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
13	46a72879-e5f6-4889-a5ec-c227afefbf1c	fa:trash	fa	Delete	actions	Delete/trash icon	{delete,trash,remove}	{"class": "fas fa-trash"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
14	f78f48c1-9a5e-45b0-b01a-8c8e79d7eb3e	fa:save	fa	Save	actions	Save icon	{save,store,disk}	{"class": "fas fa-save"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
15	1c86b441-40a9-4c65-9bc3-d45c2a681b0b	fa:download	fa	Download	actions	Download icon	{download,get,export}	{"class": "fas fa-download"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
16	9164ff91-d1c2-4ff1-92fa-6be97d7a79e0	fa:upload	fa	Upload	actions	Upload icon	{upload,send,import}	{"class": "fas fa-upload"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
17	d63687d2-b897-4df2-9bcb-08acb2c0bebb	fa:check	fa	Check	actions	Checkmark icon	{check,done,success,approve}	{"class": "fas fa-check"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
18	a11991a0-cd3c-4ead-b25c-e0cab7c8ea29	fa:times	fa	Close	actions	Close/cancel icon	{close,cancel,times,x}	{"class": "fas fa-times"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
19	58e668b5-9c9e-443f-b365-ff9fc7f05607	fa:database	fa	Database	data	Database icon	{database,data,storage}	{"class": "fas fa-database"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
20	ce103cda-1bfd-4166-81ee-ddecc8b66f90	fa:chart-bar	fa	Chart	data	Bar chart icon	{chart,graph,analytics,statistics}	{"class": "fas fa-chart-bar"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
21	574d1527-3147-4094-8e18-6a147956a8e0	fa:file	fa	File	documents	File icon	{file,document}	{"class": "fas fa-file"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
22	14cccd52-591a-47c5-9b18-f32a4ad2e679	fa:folder	fa	Folder	documents	Folder icon	{folder,directory}	{"class": "fas fa-folder"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
23	869c9be7-f4e1-44c3-8c8e-3c51d0c96063	fa:building	fa	Building	business	Building/company icon	{building,company,office}	{"class": "fas fa-building"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
24	da55492d-8c67-4e5d-96b3-e504e933484a	fa:briefcase	fa	Briefcase	business	Briefcase/business icon	{briefcase,business,work}	{"class": "fas fa-briefcase"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
25	5ce958a7-919c-4468-859e-5bab89cb9bbf	fa:arrow-left	fa	Arrow Left	navigation	Left arrow icon	{arrow,left,back,previous}	{"class": "fas fa-arrow-left"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
26	6b550208-7c76-4110-bbaf-71f99d042f07	fa:arrow-right	fa	Arrow Right	navigation	Right arrow icon	{arrow,right,next,forward}	{"class": "fas fa-arrow-right"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
27	43a5be3f-1df1-4a23-a256-197907774cb7	fa:arrow-up	fa	Arrow Up	navigation	Up arrow icon	{arrow,up,top}	{"class": "fas fa-arrow-up"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
28	e9ff0a0e-11a8-4cca-8ec7-46b20c2c6bd0	fa:arrow-down	fa	Arrow Down	navigation	Down arrow icon	{arrow,down,bottom}	{"class": "fas fa-arrow-down"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
29	20122d51-1201-476e-9cee-b934c1a6ca43	fa:facebook	fa	Facebook	social	Facebook icon	{facebook,social,fb}	{"class": "fab fa-facebook"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
30	11dbbbf1-7c72-4973-810b-9457746314f0	fa:twitter	fa	Twitter	social	Twitter icon	{twitter,social,tweet}	{"class": "fab fa-twitter"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
31	f3d44fe5-33e9-45e2-bf69-711ed74f5cf1	fa:linkedin	fa	LinkedIn	social	LinkedIn icon	{linkedin,social,professional}	{"class": "fab fa-linkedin"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
32	945f2ecb-ec3c-468b-b5e4-0d53a1a194c3	fa:instagram	fa	Instagram	social	Instagram icon	{instagram,social,ig}	{"class": "fab fa-instagram"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
33	6a41c9d1-c389-4ebb-9d7b-25a403057d0e	fa:lock	fa	Lock	security	Lock/security icon	{lock,security,protected}	{"class": "fas fa-lock"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
34	f5f68719-74fc-48f1-be97-777e746cd9de	fa:unlock	fa	Unlock	security	Unlock icon	{unlock,open,access}	{"class": "fas fa-unlock"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
35	6861b789-aafb-4733-8b52-baa4e0386319	fa:shield	fa	Shield	security	Shield/security icon	{shield,security,protection}	{"class": "fas fa-shield-alt"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
36	8f9388c9-457c-4ecd-b2f3-0337543d8bdf	fa:key	fa	Key	security	Key icon	{key,access,permission}	{"class": "fas fa-key"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
37	2a3c3f2c-765a-484b-a01c-accb7b0401bf	fa:check-circle	fa	Success	status	Success/check circle icon	{success,check,done,complete}	{"class": "fas fa-check-circle"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
74	9c76f958-59a5-45f6-ad1a-29208c31d33f	smily:fire	smily	Fire	emotions	Fire emoji	{fire,hot,🔥}	{"emoji": "🔥", "unicode": "U+1F525"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
38	ce2ed2e7-5bde-45b3-be73-d4d57e72d4e9	fa:exclamation-circle	fa	Warning	status	Warning icon	{warning,alert,caution}	{"class": "fas fa-exclamation-circle"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
39	bb07a1b6-5cd1-4886-8775-6fdcc3f1ee0b	fa:times-circle	fa	Error	status	Error/close circle icon	{error,close,fail}	{"class": "fas fa-times-circle"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
40	fc10c324-a5c6-4408-9f69-388e85869461	fa:info-circle	fa	Info	status	Information icon	{info,information,help}	{"class": "fas fa-info-circle"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
41	1db45012-86a7-4680-ae12-bbd6079eeefb	antd:home	antd	Home	navigation	Home icon (Ant Design)	{home,house,main}	{"component": "HomeOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
42	d308ea30-39c4-48f3-aa04-ef367bb046e6	antd:user	antd	User	users	User icon (Ant Design)	{user,person,profile}	{"component": "UserOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
43	b5e44453-3057-4ac4-a89b-8f41ee164f58	antd:users	antd	Users	users	Users icon (Ant Design)	{users,people,team}	{"component": "UsergroupAddOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
44	63e159e2-3aae-4d4f-8a29-248a863c7c1a	antd:setting	antd	Settings	settings	Settings icon (Ant Design)	{settings,config}	{"component": "SettingOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
45	5522894a-6ae5-4b4f-ad9a-227b97bfd942	antd:search	antd	Search	actions	Search icon (Ant Design)	{search,find}	{"component": "SearchOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
46	d66ee2f9-f6af-40f6-a98b-679f055a726f	antd:bell	antd	Notifications	notifications	Bell icon (Ant Design)	{bell,notification}	{"component": "BellOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
47	db6031fb-415f-4cc6-9734-4f9f9dd7940e	antd:heart	antd	Heart	social	Heart icon (Ant Design)	{heart,like}	{"component": "HeartOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
48	ef987f07-3ffe-4932-8868-43be9790833e	antd:star	antd	Star	ratings	Star icon (Ant Design)	{star,favorite}	{"component": "StarOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
49	218243f5-d2f3-4c9d-bd69-2b4d639a9ec0	antd:plus	antd	Add	actions	Plus icon (Ant Design)	{add,plus,new}	{"component": "PlusOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
50	534f120a-1999-44f1-9935-81c5d2456c2d	antd:edit	antd	Edit	actions	Edit icon (Ant Design)	{edit,modify}	{"component": "EditOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
51	cb0923ff-ea0b-4981-af14-425cbb5ad7f5	antd:delete	antd	Delete	actions	Delete icon (Ant Design)	{delete,remove}	{"component": "DeleteOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
52	f626d4da-719d-4760-abe7-11c31a0af925	antd:save	antd	Save	actions	Save icon (Ant Design)	{save,store}	{"component": "SaveOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
53	0990106c-0e82-4664-9d24-5de3f3b52f40	antd:download	antd	Download	actions	Download icon (Ant Design)	{download,export}	{"component": "DownloadOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
54	1bcf301a-b430-4c88-9892-001026e45639	antd:upload	antd	Upload	actions	Upload icon (Ant Design)	{upload,import}	{"component": "UploadOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
55	a41f1da4-bb25-4632-9ec5-1c6a86d4fcba	antd:check	antd	Check	actions	Check icon (Ant Design)	{check,done}	{"component": "CheckOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
56	faebaaad-8827-40ed-8531-2ac224202142	antd:close	antd	Close	actions	Close icon (Ant Design)	{close,cancel}	{"component": "CloseOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
57	8851c046-2099-46f9-9411-7d6a144161da	antd:database	antd	Database	data	Database icon (Ant Design)	{database,data}	{"component": "DatabaseOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
58	580735ff-fa24-479d-abfe-355b99c906c8	antd:file	antd	File	documents	File icon (Ant Design)	{file,document}	{"component": "FileOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
59	378b08c9-7f0c-4f0a-b7d8-3eed42b0a98d	antd:folder	antd	Folder	documents	Folder icon (Ant Design)	{folder,directory}	{"component": "FolderOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
60	e9db258e-4ccd-4c17-816a-f2fbceb61369	antd:appstore	antd	App Store	navigation	App store icon (Ant Design)	{app,store,grid}	{"component": "AppstoreOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
61	4c323254-1aa6-4a01-88c7-7b4848e4b5ff	antd:arrow-left	antd	Arrow Left	navigation	Left arrow (Ant Design)	{arrow,left,back}	{"component": "ArrowLeftOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
62	71d8b4c8-b0dd-457f-846b-1f67853480c8	antd:arrow-right	antd	Arrow Right	navigation	Right arrow (Ant Design)	{arrow,right,next}	{"component": "ArrowRightOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
63	0d3439e3-c20b-4a53-97a0-d80b42a8a44f	antd:arrow-up	antd	Arrow Up	navigation	Up arrow (Ant Design)	{arrow,up}	{"component": "ArrowUpOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
64	576ddf71-4595-4259-b275-e253fedcf6f3	antd:arrow-down	antd	Arrow Down	navigation	Down arrow (Ant Design)	{arrow,down}	{"component": "ArrowDownOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
65	2ba402a0-52c9-4226-8eca-1857860a160b	antd:check-circle	antd	Success	status	Success icon (Ant Design)	{success,check}	{"component": "CheckCircleOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
66	77a619ae-f291-4ec7-97e9-56cbbb90df6a	antd:exclamation-circle	antd	Warning	status	Warning icon (Ant Design)	{warning,alert}	{"component": "ExclamationCircleOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
67	b8025e9a-d6bd-4249-8249-e52ffa85c4c0	antd:close-circle	antd	Error	status	Error icon (Ant Design)	{error,close}	{"component": "CloseCircleOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
68	fdd83fa3-c327-44a4-8edf-ef1478858a6f	antd:info-circle	antd	Info	status	Info icon (Ant Design)	{info,information}	{"component": "InfoCircleOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
69	fc807af8-a369-40e0-993a-a1df7066422d	smily:thanks	smily	Thanks	emotions	Thank you emoji	{thanks,thank,gratitude,appreciate}	{"emoji": "🙏", "unicode": "U+1F64F"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
70	1e177531-6eac-45b1-afd5-d6498abce22f	smily:smile	smily	Smile	emotions	Happy smile emoji	{smile,happy,joy,😊}	{"emoji": "😊", "unicode": "U+1F60A"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
71	9a41f9c2-2e66-427a-959d-0c7a7f740337	smily:thumbs-up	smily	Thumbs Up	emotions	Thumbs up emoji	{thumbs,up,like,good,👍}	{"emoji": "👍", "unicode": "U+1F44D"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
72	b4435b9e-ec86-4933-9eda-fb7947a80b85	smily:heart	smily	Heart	emotions	Heart emoji	{heart,love,❤️}	{"emoji": "❤️", "unicode": "U+2764"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
73	f66b4b67-0d1f-4ed1-9937-cbfebe6f5591	smily:star	smily	Star	emotions	Star emoji	{star,favorite,⭐}	{"emoji": "⭐", "unicode": "U+2B50"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
75	443f6c2a-3201-4324-b10b-041dab212224	smily:rocket	smily	Rocket	emotions	Rocket emoji	{rocket,launch,🚀}	{"emoji": "🚀", "unicode": "U+1F680"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
76	df49c8c1-8b56-49d2-bfac-a2cd97f2c000	smily:party	smily	Party	emotions	Party emoji	{party,celebration,🎉}	{"emoji": "🎉", "unicode": "U+1F389"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
77	4b391eca-1887-492a-b51c-54101978f267	smily:check	smily	Check Mark	emotions	Check mark emoji	{check,done,✅}	{"emoji": "✅", "unicode": "U+2705"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
78	1329c377-e08c-498a-8cf7-b543d14707bd	smily:warning	smily	Warning	emotions	Warning emoji	{warning,alert,⚠️}	{"emoji": "⚠️", "unicode": "U+26A0"}	0	t	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
79	d2498152-e184-47dd-b49f-462cf38384a6	custom:myhome	custom	My Home	custom	Custom home icon	{custom,home,myhome}	{"svg": "<svg viewBox=\\"0 0 24 24\\"><path d=\\"M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z\\"/></svg>"}	0	f	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
80	1fce68c9-17e1-4477-8841-3c46c9594513	custom:logo	custom	Logo	custom	Custom logo icon	{custom,logo}	{"svg": "<svg viewBox=\\"0 0 24 24\\"><circle cx=\\"12\\" cy=\\"12\\" r=\\"10\\"/></svg>"}	0	f	t	t	1	2026-01-18 17:56:15.059046	2026-01-18 17:56:15.059046
161	7644d85f-982f-49d4-86b8-0ba0bea5c837	fa:copy	fa	Copy	actions	Copy icon	{copy,duplicate}	{"class": "fas fa-copy"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
162	7c694acb-a270-48f7-80dc-295f149310e9	fa:cut	fa	Cut	actions	Cut icon	{cut,scissors}	{"class": "fas fa-cut"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
163	d7f4a06f-f275-4047-9dd7-80727010caae	fa:paste	fa	Paste	actions	Paste icon	{paste,clipboard}	{"class": "fas fa-paste"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
164	1c4d4c7d-09c9-4a58-b62c-e6a33d89a5ef	fa:undo	fa	Undo	actions	Undo icon	{undo,revert}	{"class": "fas fa-undo"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
165	9f1da851-e7e8-455b-8aca-1a707957e474	fa:redo	fa	Redo	actions	Redo icon	{redo,repeat}	{"class": "fas fa-redo"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
166	a42db808-fe41-44e8-a1d8-9fd0549cb320	fa:refresh	fa	Refresh	actions	Refresh icon	{refresh,reload}	{"class": "fas fa-sync"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
167	68639839-8317-44e8-a4da-c7218005a971	fa:filter	fa	Filter	actions	Filter icon	{filter,sort}	{"class": "fas fa-filter"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
168	40d892d8-6fc9-43ba-8b18-b6495f7d5527	fa:eye	fa	View	actions	Eye/view icon	{eye,view}	{"class": "fas fa-eye"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
169	cd6f3a8d-49c9-4190-bbbc-7781e9e81f4e	fa:eye-slash	fa	Hide	actions	Eye slash/hide icon	{hide,invisible}	{"class": "fas fa-eye-slash"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
170	40c9de62-2988-4b1b-b694-eae40fdd9a61	fa:print	fa	Print	actions	Print icon	{print,printer}	{"class": "fas fa-print"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
171	dff02df5-159e-4248-a6d8-6e8d77b20696	fa:share	fa	Share	actions	Share icon	{share,send}	{"class": "fas fa-share"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
172	45dfa6cf-8550-40eb-a933-80bdf09031a7	fa:link	fa	Link	actions	Link icon	{link,url}	{"class": "fas fa-link"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
173	902a2b98-a825-4000-8c64-2c31ed636b56	fa:calendar	fa	Calendar	time	Calendar icon	{calendar,date}	{"class": "fas fa-calendar"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
174	794b0433-6b2f-41b1-b4c0-ad599eeda56a	fa:clock	fa	Clock	time	Clock icon	{clock,time}	{"class": "fas fa-clock"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
175	b0d1e670-a2b7-4650-a862-74f15ee26503	fa:money-bill	fa	Money	business	Money bill icon	{money,cash}	{"class": "fas fa-money-bill"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
176	dbac8767-fddd-4d73-8417-a5b492c4c693	fa:credit-card	fa	Credit Card	business	Credit card icon	{credit,card}	{"class": "fas fa-credit-card"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
177	cf5326ff-887e-4648-8083-c256ccb9fb58	fa:chart-line	fa	Chart Line	data	Line chart icon	{chart,line}	{"class": "fas fa-chart-line"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
178	bd152174-7b68-4e9b-82ca-4b627ed59862	fa:chart-pie	fa	Chart Pie	data	Pie chart icon	{chart,pie}	{"class": "fas fa-chart-pie"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
179	07c2c268-b9c5-4af2-b5ae-af0aa87daa81	fa:calculator	fa	Calculator	tools	Calculator icon	{calculator,math}	{"class": "fas fa-calculator"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
180	eb769e44-f140-47e3-887a-a506771cab0a	fa:comment	fa	Comment	communication	Comment icon	{comment,message}	{"class": "fas fa-comment"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
181	69be1714-44d9-42eb-8bb9-18b40b733726	fa:comments	fa	Comments	communication	Comments icon	{comments,messages}	{"class": "fas fa-comments"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
182	3c354600-184f-46c3-bba9-d76679d31d3f	fa:video	fa	Video	media	Video icon	{video,camera}	{"class": "fas fa-video"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
183	46be489b-0025-4e66-88f9-1a1766757c6c	fa:microphone	fa	Microphone	media	Microphone icon	{microphone,audio}	{"class": "fas fa-microphone"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
184	e81b127b-3030-41ea-ba16-e761f239e1ef	fa:image	fa	Image	media	Image icon	{image,picture}	{"class": "fas fa-image"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
185	c34d464f-e333-4243-b33d-375739a26035	fa:camera	fa	Camera	media	Camera icon	{camera,photo}	{"class": "fas fa-camera"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
186	1393e33b-52b8-4032-b256-f3dad5b63cdc	fa:bars	fa	Menu	navigation	Bars/menu icon	{menu,bars}	{"class": "fas fa-bars"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
187	52da52ab-300f-4e99-b31a-cbea6abdab9e	fa:list	fa	List	navigation	List icon	{list,items}	{"class": "fas fa-list"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
188	47ba8ff9-c1a6-433e-b807-83005ee112b3	fa:table	fa	Table	data	Table icon	{table,grid}	{"class": "fas fa-table"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
189	b57f41e1-e437-44e9-b85e-6db4fc441845	fa:angle-left	fa	Angle Left	navigation	Angle left icon	{angle,left}	{"class": "fas fa-angle-left"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
190	b6ca6ec4-a873-4ac8-8273-34d0a2d295fb	fa:angle-right	fa	Angle Right	navigation	Angle right icon	{angle,right}	{"class": "fas fa-angle-right"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
191	9298ed92-ea92-4e84-9feb-d1d84e28f455	fa:chevron-left	fa	Chevron Left	navigation	Chevron left icon	{chevron,left}	{"class": "fas fa-chevron-left"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
192	cd772d6e-6fd0-4bd7-af01-de4d623866d7	fa:chevron-right	fa	Chevron Right	navigation	Chevron right icon	{chevron,right}	{"class": "fas fa-chevron-right"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
193	b605d098-cc85-4ca2-b172-705725405f3c	fa:file-pdf	fa	PDF	documents	PDF file icon	{pdf,file}	{"class": "fas fa-file-pdf"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
194	453806b6-969f-414f-a9b3-c9116a2479e1	fa:file-word	fa	Word	documents	Word file icon	{word,doc}	{"class": "fas fa-file-word"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
195	e998856f-cc4e-4ee4-ae7b-20aed777b2f2	fa:file-excel	fa	Excel	documents	Excel file icon	{excel,xls}	{"class": "fas fa-file-excel"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
196	2d36a2ae-4db4-4a05-aaa8-7f8399040425	fa:youtube	fa	YouTube	social	YouTube icon	{youtube,video}	{"class": "fab fa-youtube"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
197	54f57b1b-2d60-46b6-b313-0062f06bcd27	fa:github	fa	GitHub	social	GitHub icon	{github,code}	{"class": "fab fa-github"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
198	cf5618db-4769-4dcf-b875-8d34d8277c97	fa:whatsapp	fa	WhatsApp	social	WhatsApp icon	{whatsapp,chat}	{"class": "fab fa-whatsapp"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
199	e6354564-f378-4988-a2fd-e6e226aa9b80	fa:slack	fa	Slack	social	Slack icon	{slack,chat}	{"class": "fab fa-slack"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
200	eeabb467-ce69-4797-82e8-0a6b01c182e0	fa:spinner	fa	Spinner	status	Spinner/loading icon	{spinner,loading}	{"class": "fas fa-spinner"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
201	96db2ec4-e013-4f45-9c77-17db29e2da5d	fa:question-circle	fa	Question	status	Question circle icon	{question,help}	{"class": "far fa-circle-question"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
202	b66bbd0f-5d76-446a-830b-3e68e98cd509	fa:wrench	fa	Wrench	tools	Wrench icon	{wrench,tool}	{"class": "fas fa-wrench"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
203	329e5a89-2fbf-4740-832d-fd0f78ac65ab	fa:map	fa	Map	location	Map icon	{map,location}	{"class": "fas fa-map"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
204	e16723df-961c-4616-ad32-9d2915f6cf38	fa:globe	fa	Globe	location	Globe icon	{globe,world}	{"class": "fas fa-globe"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
205	4405e67d-ab4b-4131-8f3c-76624ff872f1	fa:shopping-cart	fa	Shopping Cart	shopping	Shopping cart icon	{cart,shopping}	{"class": "fas fa-shopping-cart"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
206	c0e929bb-ceba-4350-a640-f5eb611dab7e	fa:tag	fa	Tag	shopping	Tag icon	{tag,label}	{"class": "fas fa-tag"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
207	b20dd748-1e5b-4c9f-a02d-4c8c1f41321e	fa:gift	fa	Gift	shopping	Gift icon	{gift,present}	{"class": "fas fa-gift"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
208	d341b316-c2f5-463d-a8c3-534ed0db0d6f	fa:graduation-cap	fa	Graduation Cap	education	Graduation cap icon	{graduation,education}	{"class": "fas fa-graduation-cap"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
209	5bb4f41e-c8b1-4485-b336-307ec3c7d376	fa:utensils	fa	Utensils	food	Utensils icon	{utensils,food}	{"class": "fas fa-utensils"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
210	5971f650-df34-4b68-bbf4-373138d74ca0	fa:coffee	fa	Coffee	food	Coffee icon	{coffee,drink}	{"class": "fas fa-mug-hot"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
211	bd4af73a-8f3b-47a8-aa00-b61ac165502e	fa:laptop	fa	Laptop	technology	Laptop icon	{laptop,computer}	{"class": "fas fa-laptop"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
212	f84d4eec-583c-45a3-afeb-cbc477d261dc	fa:mobile-alt	fa	Mobile	technology	Mobile icon	{mobile,phone}	{"class": "fas fa-mobile-screen-button"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
213	51909e56-5b90-431e-a00e-db546c45599d	fa:wifi	fa	WiFi	technology	WiFi icon	{wifi,wireless}	{"class": "fas fa-wifi"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
214	02182f0a-f028-46a4-82f7-3a7cae07d7d3	fa:code	fa	Code	development	Code icon	{code,programming}	{"class": "fas fa-code"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
215	f2c90c88-282a-44a3-b90f-509fce271787	fa:terminal	fa	Terminal	development	Terminal icon	{terminal,command}	{"class": "fas fa-terminal"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
216	2397284a-7e50-419c-bad9-455ba3469ac1	fa:sort	fa	Sort	actions	Sort icon	{sort,order}	{"class": "fas fa-sort"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
217	cc9c81ad-dcbe-4daf-96f6-e52c000a0705	fa:expand	fa	Expand	navigation	Expand icon	{expand,fullscreen}	{"class": "fas fa-expand"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
218	365a16d0-8c86-4128-87a3-16749901662f	fa:compress	fa	Compress	navigation	Compress icon	{compress}	{"class": "fas fa-compress"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
219	15276bfe-fc31-494d-a293-a554046d04cf	fa:caret-down	fa	Caret Down	navigation	Caret down icon	{caret,down}	{"class": "fas fa-caret-down"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
220	1931032e-f8c7-4c44-84d4-6b61384e0660	fa:caret-up	fa	Caret Up	navigation	Caret up icon	{caret,up}	{"class": "fas fa-caret-up"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
221	b4c8beb8-c7cd-4a3d-9ff4-fa31c44f8453	fa:folder-open	fa	Folder Open	documents	Folder open icon	{folder,open}	{"class": "fas fa-folder-open"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
222	d1854c68-066c-4b15-97fa-f0201a88e15a	fa:book	fa	Book	documents	Book icon	{book,read}	{"class": "fas fa-book"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
223	e0f5d750-f804-49e7-bd4f-543715e1c96d	fa:bookmark	fa	Bookmark	documents	Bookmark icon	{bookmark,save}	{"class": "fas fa-bookmark"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
224	a9fe2b7a-8d5c-40d7-8ef2-6a649d7583f5	fa:newspaper	fa	Newspaper	documents	Newspaper icon	{newspaper,news}	{"class": "far fa-newspaper"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
225	49a400fb-342f-4c0c-9af2-58cc301401bc	fa:reddit	fa	Reddit	social	Reddit icon	{reddit,social}	{"class": "fab fa-reddit"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
226	2a2503e2-b9f5-49fc-b3c8-8e8f39a117dc	fa:discord	fa	Discord	social	Discord icon	{discord,chat}	{"class": "fab fa-discord"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
227	f414e3e1-0d0a-41ea-b9ab-9638dc8936dd	fa:telegram	fa	Telegram	social	Telegram icon	{telegram,chat}	{"class": "fab fa-telegram"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
228	60d6b2b1-947a-40dd-b637-11fbeb4111fb	fa:skype	fa	Skype	social	Skype icon	{skype,chat}	{"class": "fab fa-skype"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
229	73943ff0-fcbc-4b6a-8f44-1226671a28fe	fa:pinterest	fa	Pinterest	social	Pinterest icon	{pinterest,social}	{"class": "fab fa-pinterest"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
230	9691fdb1-3a2e-4c85-936f-af791a5b0c10	fa:dribbble	fa	Dribbble	social	Dribbble icon	{dribbble,design}	{"class": "fab fa-dribbble"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
231	557396c0-396c-4ef0-ba40-1333a9b154ed	fa:behance	fa	Behance	social	Behance icon	{behance,design}	{"class": "fab fa-behance"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
232	b1ec61d7-d126-4f3c-a906-7dc5c09d3e06	fa:circle	fa	Circle	status	Circle icon	{circle,dot}	{"class": "far fa-circle"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
233	74d97247-f38c-4215-bb8b-9ff2d25323f8	fa:ban	fa	Ban	status	Ban icon	{ban,block}	{"class": "fas fa-ban"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
234	e8ac622e-c40d-4e1e-95ad-88c7bf973809	fa:play-circle	fa	Play	media	Play circle icon	{play,video}	{"class": "far fa-circle-play"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
235	3cbe59c2-20cf-44f6-8c50-fae4ea3122f1	fa:pause-circle	fa	Pause	media	Pause circle icon	{pause,video}	{"class": "far fa-circle-pause"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
236	077c4495-9a0e-4d78-9250-80cf6309ad34	fa:stop-circle	fa	Stop	media	Stop circle icon	{stop,video}	{"class": "far fa-circle-stop"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
237	643579bf-c3a3-44e1-90b0-977976f47816	fa:paint-brush	fa	Paint Brush	tools	Paint brush icon	{paint,brush}	{"class": "fas fa-paint-brush"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
238	8bd3309b-b6aa-437a-a828-84ef3e986b7a	fa:palette	fa	Palette	tools	Palette icon	{palette,color}	{"class": "fas fa-palette"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
239	a37f654b-f88b-475a-a7e7-5f82ac0ee9fa	fa:sliders-h	fa	Sliders	settings	Sliders icon	{sliders,settings}	{"class": "fas fa-sliders"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
240	9c1612ec-0a01-4145-837f-161087b34dca	fa:toggle-on	fa	Toggle On	settings	Toggle on icon	{toggle,on}	{"class": "fas fa-toggle-on"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
241	60763961-25bd-4fe3-96f3-0c009913cdac	fa:toggle-off	fa	Toggle Off	settings	Toggle off icon	{toggle,off}	{"class": "fas fa-toggle-off"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
242	11dd1ace-1717-49cc-9c72-23d3a17fb0a2	fa:power-off	fa	Power Off	settings	Power off icon	{power,off}	{"class": "fas fa-power-off"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
243	ad13025d-b852-44c3-824d-4d713ec9c511	fa:lightbulb	fa	Lightbulb	tools	Lightbulb icon	{lightbulb,idea}	{"class": "far fa-lightbulb"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
244	fabaf401-4967-4321-9abd-e5ccd6d9e09d	fa:map-marker	fa	Map Marker	location	Map marker icon	{map,marker}	{"class": "fas fa-location-dot"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
245	70a4955f-7231-41c3-b65f-9dd34f789bbb	fa:plane	fa	Plane	travel	Plane icon	{plane,airplane}	{"class": "fas fa-plane"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
246	05120b55-70a6-4c1e-9602-2b4891b9c27e	fa:car	fa	Car	travel	Car icon	{car,vehicle}	{"class": "fas fa-car"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
247	4b8dc8fc-b283-494a-8589-ee2487d4e39b	fa:bus	fa	Bus	travel	Bus icon	{bus,vehicle}	{"class": "fas fa-bus"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
248	e6e6cebd-ab18-45bd-b96c-dba961b4e646	fa:train	fa	Train	travel	Train icon	{train,vehicle}	{"class": "fas fa-train"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
249	194e37b8-b77e-400d-8a8c-ec01f72aef56	fa:shipping-fast	fa	Shipping Fast	shopping	Fast shipping icon	{shipping,fast}	{"class": "fas fa-shipping-fast"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
250	d7f20b9b-9c60-4063-93dd-2073d218244e	fa:truck	fa	Truck	shopping	Truck icon	{truck,delivery}	{"class": "fas fa-truck"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
251	40fcd8af-4c72-4f28-a2df-e3b0933d9f8c	fa:heartbeat	fa	Heartbeat	health	Heartbeat icon	{heartbeat,health}	{"class": "fas fa-heartbeat"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
252	baa9f21e-fd7f-4da4-90a7-f0b1b0c5e4ac	fa:stethoscope	fa	Stethoscope	health	Stethoscope icon	{stethoscope,medical}	{"class": "fas fa-stethoscope"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
253	b5ce7327-ef76-4687-a156-113dc023c27f	fa:hospital	fa	Hospital	health	Hospital icon	{hospital,medical}	{"class": "fas fa-hospital"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
254	797ed4f4-62f1-4897-a0b4-7456202fdf54	fa:school	fa	School	education	School icon	{school,education}	{"class": "fas fa-school"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
255	65070f3b-1a61-4a4c-b609-4abd0858fe5d	fa:university	fa	University	education	University icon	{university,education}	{"class": "fas fa-building-columns"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
256	25d825c8-70b1-47e1-a304-39b8f78d1b1e	fa:wine-glass	fa	Wine Glass	food	Wine glass icon	{wine,drink}	{"class": "fas fa-wine-glass"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
257	b517020b-94e6-48e6-ae61-46353b591708	fa:pizza-slice	fa	Pizza	food	Pizza slice icon	{pizza,food}	{"class": "fas fa-pizza-slice"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
258	cc04bcca-68ad-4601-b119-e38b9dce1d32	fa:football-ball	fa	Football	sports	Football icon	{football,sports}	{"class": "fas fa-football"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
259	1e2beeeb-7c80-4b67-b842-462b95562c2e	fa:basketball-ball	fa	Basketball	sports	Basketball icon	{basketball,sports}	{"class": "fas fa-basketball"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
260	c99a8b7e-6f92-485e-9ef2-95666ee86f4b	fa:gamepad	fa	Gamepad	games	Gamepad icon	{gamepad,game}	{"class": "fas fa-gamepad"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
261	6bd2cee4-9de5-45fd-af66-5ed73cd9802e	fa:sun	fa	Sun	weather	Sun icon	{sun,weather}	{"class": "far fa-sun"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
262	beba0bee-2c7e-4785-a0c6-f099821e8d72	fa:moon	fa	Moon	weather	Moon icon	{moon,night}	{"class": "far fa-moon"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
263	100f72dc-a948-4ed8-923d-1635486fa323	fa:cloud	fa	Cloud	weather	Cloud icon	{cloud,weather}	{"class": "fas fa-cloud"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
264	0b367da3-c47e-4062-ad7f-dc5dbe5a81a1	fa:cloud-rain	fa	Rain	weather	Cloud rain icon	{rain,weather}	{"class": "fas fa-cloud-rain"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
265	6b7b1f8b-050b-42d0-94d4-b4dd7795cb73	fa:snowflake	fa	Snowflake	weather	Snowflake icon	{snowflake,snow}	{"class": "far fa-snowflake"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
266	cbfab670-909c-4a04-b529-781465cf5238	fa:umbrella	fa	Umbrella	weather	Umbrella icon	{umbrella,rain}	{"class": "fas fa-umbrella"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
267	047a77ab-ba40-444e-ab8f-6141f3ca387b	fa:bolt	fa	Bolt	weather	Bolt/lightning icon	{bolt,lightning}	{"class": "fas fa-bolt"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
268	4171bb6f-143e-4708-9a62-041d464bc5e3	fa:gem	fa	Gem	objects	Gem icon	{gem,diamond}	{"class": "far fa-gem"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
269	f5e74055-3733-4db6-b73f-d54f68ced4dd	fa:crown	fa	Crown	objects	Crown icon	{crown,royal}	{"class": "fas fa-crown"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
270	36ba62a8-d84a-412a-af71-3a92c17dd46a	fa:trophy	fa	Trophy	objects	Trophy icon	{trophy,award}	{"class": "fas fa-trophy"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
271	eed3b940-0f12-4818-8f75-a24cce4b4e7e	fa:medal	fa	Medal	objects	Medal icon	{medal,award}	{"class": "fas fa-medal"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
272	596b248d-8d47-4b67-8672-dd9ddb623c79	fa:award	fa	Award	objects	Award icon	{award,prize}	{"class": "fas fa-award"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
273	60015da2-5daf-4040-8388-588928199979	fa:flag	fa	Flag	objects	Flag icon	{flag,country}	{"class": "fas fa-flag"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
274	bca15bd5-7245-4fd5-93b5-ceedc435a929	fa:hand-paper	fa	Hand Paper	actions	Hand paper/stop icon	{hand,stop}	{"class": "far fa-hand"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
275	9bc4d645-2fbb-4ac0-aff4-918a6451c8a1	fa:thumbs-down	fa	Thumbs Down	actions	Thumbs down icon	{thumbs,down}	{"class": "far fa-thumbs-down"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
276	e5ee7b2e-4adc-429c-8d42-796e0e367312	fa:handshake	fa	Handshake	business	Handshake icon	{handshake,deal}	{"class": "far fa-handshake"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
277	f6c9c83d-a9d9-417a-bc72-7fbc0fd3aced	fa:user-tie	fa	User Tie	business	User tie icon	{user,tie}	{"class": "fas fa-user-tie"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
278	31baae0d-f7be-4ff2-b36a-a4af2c8edb45	fa:user-graduate	fa	User Graduate	education	User graduate icon	{user,graduate}	{"class": "fas fa-user-graduate"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
279	00da7e8d-b917-4ffe-9d08-b2a647b2e585	fa:user-shield	fa	User Shield	security	User shield icon	{user,shield}	{"class": "fas fa-user-shield"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
280	8511159a-0346-480c-9ca5-7e5e6847405c	fa:user-plus	fa	User Plus	users	User plus icon	{user,plus}	{"class": "fas fa-user-plus"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
281	62eea63e-1b25-4e15-a958-c0122ae5d84d	fa:user-minus	fa	User Minus	users	User minus icon	{user,minus}	{"class": "fas fa-user-minus"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
282	fe4fd4d6-5a0c-4ddc-832a-42bad3c10f6f	fa:id-card	fa	ID Card	users	ID card icon	{id,card}	{"class": "far fa-id-card"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
283	781da65b-2b28-4cff-98cc-e45df2dccb54	fa:desktop	fa	Desktop	technology	Desktop icon	{desktop,computer}	{"class": "fas fa-desktop"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
284	66186799-6de4-4992-895d-812b034932c0	fa:tablet	fa	Tablet	technology	Tablet icon	{tablet,device}	{"class": "fas fa-tablet"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
285	2d3b08e0-0c1f-4f0b-b507-518635b99d13	fa:server	fa	Server	technology	Server icon	{server,computer}	{"class": "fas fa-server"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
286	a8014be4-1e93-4a73-855b-61d22c97b3bc	fa:keyboard	fa	Keyboard	technology	Keyboard icon	{keyboard,input}	{"class": "far fa-keyboard"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
287	cede8a0d-1f9f-4f9f-96a9-cd4b248d19fd	fa:mouse	fa	Mouse	technology	Mouse icon	{mouse,input}	{"class": "fas fa-computer-mouse"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
288	77fad5d5-50d3-468b-9825-0c3344c5d781	fa:headset	fa	Headset	technology	Headset icon	{headset,audio}	{"class": "fas fa-headset"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
289	db03cc9b-d9ea-4fa7-a523-c15528bcc1ed	fa:tv	fa	TV	technology	TV icon	{tv,television}	{"class": "fas fa-tv"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
290	374b52ce-cd22-4c81-adcb-7b45db2f226b	fa:fingerprint	fa	Fingerprint	security	Fingerprint icon	{fingerprint,biometric}	{"class": "fas fa-fingerprint"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
291	47535b3e-6cff-472b-80f8-a6d89eeff53d	fa:lock-open	fa	Lock Open	security	Lock open icon	{lock,open}	{"class": "fas fa-lock-open"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
292	d0af7de8-0690-410d-a409-d34e179f7d04	fa:sync	fa	Sync	actions	Sync icon	{sync,synchronize}	{"class": "fas fa-arrows-rotate"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
293	08289a83-5790-415a-8c5d-655c8abe64bd	fa:random	fa	Random	actions	Random icon	{random,shuffle}	{"class": "fas fa-shuffle"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
294	56104350-f580-487d-93f0-1c52cddce70b	fa:external-link-alt	fa	External Link	navigation	External link icon	{external,link}	{"class": "fas fa-arrow-up-right-from-square"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
295	ca62494c-ad00-458d-bb06-eb1bc25fc91a	fa:sign-in-alt	fa	Sign In	authentication	Sign in icon	{sign,in}	{"class": "fas fa-right-to-bracket"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
296	18d9b992-ef54-46c0-b6b3-23ec3e2dc5c6	fa:sign-out-alt	fa	Sign Out	authentication	Sign out icon	{sign,out}	{"class": "fas fa-right-from-bracket"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
297	699aa2c7-f533-4a51-9919-fc0c02fe022e	fa:language	fa	Language	communication	Language icon	{language,translate}	{"class": "fas fa-language"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
298	83a627d9-4d5d-4fba-90dc-ac8e321af22e	fa:bold	fa	Bold	text	Bold icon	{bold,text}	{"class": "fas fa-bold"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
299	ff06d927-5e51-43b0-b305-a53cd29c3edd	fa:italic	fa	Italic	text	Italic icon	{italic,text}	{"class": "fas fa-italic"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
300	9ecbb732-3c1c-4e1c-a876-5042b179a390	fa:underline	fa	Underline	text	Underline icon	{underline,text}	{"class": "fas fa-underline"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
301	2a12cf2f-4472-4197-a1e6-443580eeb044	fa:bug	fa	Bug	development	Bug icon	{bug,error}	{"class": "fas fa-bug"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
302	3d364813-c809-460d-9125-b42325ba26d1	fa:code-branch	fa	Code Branch	development	Code branch icon	{branch,git}	{"class": "fas fa-code-branch"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
303	02f77141-bf5d-404a-8ba4-50a9f5fee0de	fa:html5	fa	HTML5	development	HTML5 icon	{html5,web}	{"class": "fab fa-html5"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
304	8736662f-9b2d-4014-bc78-14ad049a5188	fa:css3	fa	CSS3	development	CSS3 icon	{css3,web}	{"class": "fab fa-css3-alt"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
305	49b2eb22-cc76-43fa-aad1-3f34e57d5ecf	fa:js	fa	JavaScript	development	JavaScript icon	{javascript,js}	{"class": "fab fa-js"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
306	2d95c94d-e959-4214-ae99-22c185d72fc8	fa:python	fa	Python	development	Python icon	{python,programming}	{"class": "fab fa-python"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
307	c39360b2-acbc-46ff-93cf-b1ddbab6947c	fa:node-js	fa	Node.js	development	Node.js icon	{nodejs,javascript}	{"class": "fab fa-node-js"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
308	6692fad5-54d1-4bf2-aad2-09518de932df	fa:react	fa	React	development	React icon	{react,javascript}	{"class": "fab fa-react"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
309	d92158b1-06c5-4ddb-939d-4e60c16c04c0	fa:vue	fa	Vue	development	Vue icon	{vue,javascript}	{"class": "fab fa-vuejs"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
310	36b9041d-2cf9-408c-ab33-8deba443456f	fa:angular	fa	Angular	development	Angular icon	{angular,javascript}	{"class": "fab fa-angular"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
311	908e080b-51e1-4552-8aa3-0b1bd80c5611	fa:bootstrap	fa	Bootstrap	development	Bootstrap icon	{bootstrap,css}	{"class": "fab fa-bootstrap"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
312	b6095a3c-f620-42cf-abd0-7d8192f556e8	fa:npm	fa	NPM	development	NPM icon	{npm,package}	{"class": "fab fa-npm"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
313	abbe8a16-3896-4c5f-ad05-5e35b5a600ed	fa:docker	fa	Docker	development	Docker icon	{docker,container}	{"class": "fab fa-docker"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
314	84800079-0995-49fa-9f8f-fd35890e7a89	fa:aws	fa	AWS	development	AWS icon	{aws,cloud}	{"class": "fab fa-aws"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
315	e5b0fe84-b411-4bd3-a0c8-b704f92b7dd8	fa:linux	fa	Linux	development	Linux icon	{linux,os}	{"class": "fab fa-linux"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
316	a580578d-bc31-44c1-a9fe-c80406b66deb	fa:windows	fa	Windows	development	Windows icon	{windows,os}	{"class": "fab fa-windows"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
317	368f638e-5abd-4b7f-ae15-e8a7a7de1357	fa:apple	fa	Apple	development	Apple icon	{apple,os}	{"class": "fab fa-apple"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
318	033901ed-4259-4346-85b9-b71e418378f8	fa:android	fa	Android	development	Android icon	{android,mobile}	{"class": "fab fa-android"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
319	c1822cc7-670e-42ad-99ad-635c7ed20714	fa:chrome	fa	Chrome	development	Chrome icon	{chrome,browser}	{"class": "fab fa-chrome"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
320	0b66d108-e6b8-49ab-ab06-de22d9aa36fc	fa:firefox	fa	Firefox	development	Firefox icon	{firefox,browser}	{"class": "fab fa-firefox"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
321	a74e2e8d-a14f-4827-9769-633f9c34ee1f	fa:safari	fa	Safari	development	Safari icon	{safari,browser}	{"class": "fab fa-safari"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
322	d3b013cf-f0ef-4931-9215-bf4aff5a3e74	antd:copy	antd	Copy	actions	Copy icon (Ant Design)	{copy,duplicate}	{"component": "CopyOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
323	4f69d467-dcd9-4ef0-9e64-e4b78a2330c3	antd:cut	antd	Cut	actions	Cut icon (Ant Design)	{cut}	{"component": "ScissorOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
324	693d4d42-ec9a-4081-865c-771fa3249d94	antd:paste	antd	Paste	actions	Paste icon (Ant Design)	{paste}	{"component": "SnippetsOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
325	5fcca6b9-c434-4dc6-8d91-e04fee57ec2a	antd:undo	antd	Undo	actions	Undo icon (Ant Design)	{undo}	{"component": "UndoOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
326	58f5da18-15bf-4b13-a7e0-96a69b5c0c92	antd:redo	antd	Redo	actions	Redo icon (Ant Design)	{redo}	{"component": "RedoOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
327	7c5a2779-a40f-401a-aeaf-e863641c5ea6	antd:reload	antd	Reload	actions	Reload icon (Ant Design)	{reload,refresh}	{"component": "ReloadOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
328	abe2ed33-c4d7-4977-89c0-3f05c4be47ab	antd:filter	antd	Filter	actions	Filter icon (Ant Design)	{filter}	{"component": "FilterOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
329	4a112c91-726c-4997-b629-65f325edbd08	antd:eye	antd	View	actions	Eye/view icon (Ant Design)	{eye,view}	{"component": "EyeOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
330	b3e7a807-9b9a-4683-9db4-c36ee91c1273	antd:eye-invisible	antd	Hide	actions	Eye invisible icon (Ant Design)	{hide}	{"component": "EyeInvisibleOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
331	2faf5e54-7763-4270-a795-e2f4e5ae7e83	antd:printer	antd	Print	actions	Print icon (Ant Design)	{print}	{"component": "PrinterOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
332	540e8c62-f970-4ab8-9d75-3d5f06e52aca	antd:share-alt	antd	Share	actions	Share icon (Ant Design)	{share}	{"component": "ShareAltOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
333	f8b02703-1ee1-404e-a125-103a7fbf6a9e	antd:link	antd	Link	actions	Link icon (Ant Design)	{link}	{"component": "LinkOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
334	bc523b80-345c-47f2-af6e-67dbb70da4a0	antd:calendar	antd	Calendar	time	Calendar icon (Ant Design)	{calendar}	{"component": "CalendarOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
335	60be5a7f-cfe9-43ae-99ef-4af95475fd12	antd:clock-circle	antd	Clock	time	Clock icon (Ant Design)	{clock,time}	{"component": "ClockCircleOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
336	87262fa7-96e0-4e67-adac-37033c9fd9c8	antd:dollar	antd	Dollar	business	Dollar icon (Ant Design)	{dollar,money}	{"component": "DollarOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
337	75c4916d-719e-4c60-a84f-081240fbc193	antd:credit-card	antd	Credit Card	business	Credit card icon (Ant Design)	{credit,card}	{"component": "CreditCardOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
338	b41b8ed5-ce3a-4cac-a101-1500b6a3d9aa	antd:line-chart	antd	Line Chart	data	Line chart icon (Ant Design)	{chart,line}	{"component": "LineChartOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
339	de17f13b-c2e2-420d-bb8d-64a7c4bfc3db	antd:pie-chart	antd	Pie Chart	data	Pie chart icon (Ant Design)	{chart,pie}	{"component": "PieChartOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
340	959ad26c-8990-428c-b002-239cf60da3fd	antd:bar-chart	antd	Bar Chart	data	Bar chart icon (Ant Design)	{chart,bar}	{"component": "BarChartOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
341	25de48ad-b2d7-4074-89d9-fdd652ff15f7	antd:calculator	antd	Calculator	tools	Calculator icon (Ant Design)	{calculator}	{"component": "CalculatorOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
342	b914dc02-025b-4e0c-ab39-591b07bf1569	antd:message	antd	Message	communication	Message icon (Ant Design)	{message}	{"component": "MessageOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
343	df25d52b-36ad-4d27-ac1d-6b9f7948d163	antd:comment	antd	Comment	communication	Comment icon (Ant Design)	{comment}	{"component": "CommentOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
344	a9082f97-b9c7-4892-97a5-1374ccef4f70	antd:video-camera	antd	Video	media	Video camera icon (Ant Design)	{video}	{"component": "VideoCameraOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
345	e892c3f3-f41e-4aae-8230-6a752f9487f7	antd:audio	antd	Audio	media	Audio icon (Ant Design)	{audio}	{"component": "AudioOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
346	8eae96fe-557c-4ad9-a344-1b7c93e7f116	antd:picture	antd	Picture	media	Picture icon (Ant Design)	{picture,image}	{"component": "PictureOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
347	61d3bda8-16a8-4bbc-8c9a-d4a075221c66	antd:camera	antd	Camera	media	Camera icon (Ant Design)	{camera}	{"component": "CameraOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
348	c75cf49c-c40e-41da-8549-639ae4bfdbec	antd:menu	antd	Menu	navigation	Menu icon (Ant Design)	{menu}	{"component": "MenuOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
349	ecdd17fc-6615-4f39-9695-3c82a907bbf7	antd:unordered-list	antd	List	navigation	List icon (Ant Design)	{list}	{"component": "UnorderedListOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
350	5819ecf3-06ce-4188-9396-f4e2d476ce0a	antd:table	antd	Table	data	Table icon (Ant Design)	{table}	{"component": "TableOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
351	258e71ee-26f5-4f4c-b39e-a75089876b75	antd:left	antd	Left	navigation	Left icon (Ant Design)	{left}	{"component": "LeftOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
352	732209b1-0278-4c88-8a21-a43f971812f7	antd:right	antd	Right	navigation	Right icon (Ant Design)	{right}	{"component": "RightOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
353	d466ab32-d3cb-4893-8b9f-3d5821d503c1	antd:up	antd	Up	navigation	Up icon (Ant Design)	{up}	{"component": "UpOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
354	f2e7a8cc-78ec-4e45-9eea-17626330e7ef	antd:down	antd	Down	navigation	Down icon (Ant Design)	{down}	{"component": "DownOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
355	47b5b29c-b9a5-4621-8c8b-b3123437d90c	antd:double-left	antd	Double Left	navigation	Double left icon (Ant Design)	{left,double}	{"component": "DoubleLeftOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
356	6b51edff-51bb-404f-9e73-346b9f705457	antd:double-right	antd	Double Right	navigation	Double right icon (Ant Design)	{right,double}	{"component": "DoubleRightOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
357	9cacc949-50f7-4dcf-9326-fc4545a4a1da	antd:file-text	antd	File Text	documents	File text icon (Ant Design)	{file,text}	{"component": "FileTextOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
358	4dfe260e-00b7-4e14-85d3-cb0f467f4dc5	antd:folder-open	antd	Folder Open	documents	Folder open icon (Ant Design)	{folder,open}	{"component": "FolderOpenOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
359	6e52d986-1ec7-4f40-a685-8bc92b4d9120	antd:book	antd	Book	documents	Book icon (Ant Design)	{book}	{"component": "BookOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
360	c0b245f6-95a7-491d-98a2-4ad62295b021	antd:youtube	antd	YouTube	social	YouTube icon (Ant Design)	{youtube}	{"component": "YoutubeOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
361	388e61ac-9d93-482d-bb7c-6bf5207d6f42	antd:github	antd	GitHub	social	GitHub icon (Ant Design)	{github}	{"component": "GithubOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
362	c7bf38df-5eea-4bb8-8128-eb376fe4b928	antd:loading	antd	Loading	status	Loading icon (Ant Design)	{loading,spinner}	{"component": "LoadingOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
363	69bca948-dc03-4fa4-868e-def296abbacd	antd:question-circle	antd	Question	status	Question circle icon (Ant Design)	{question}	{"component": "QuestionCircleOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
364	28d7e3bf-dc7f-4081-9bc8-3b8fb8bbf495	antd:tool	antd	Tool	tools	Tool icon (Ant Design)	{tool}	{"component": "ToolOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
365	1d5c4434-4132-4d89-a612-f59cec9b50db	antd:global	antd	Global	location	Global icon (Ant Design)	{global,world}	{"component": "GlobalOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
366	5544011d-2257-466c-a01b-2e1cf40aa7bc	antd:shopping-cart	antd	Shopping Cart	shopping	Shopping cart icon (Ant Design)	{cart}	{"component": "ShoppingCartOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
367	3c98eec4-39ec-44c1-b0f1-7f519305b4c9	antd:tag	antd	Tag	shopping	Tag icon (Ant Design)	{tag}	{"component": "TagOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
368	e8f58755-ec33-4ed9-a19e-9486c30bdcb5	antd:gift	antd	Gift	shopping	Gift icon (Ant Design)	{gift}	{"component": "GiftOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
369	f68a2fe1-a70d-4406-9633-e6d0309f363d	antd:graduation-cap	antd	Graduation	education	Graduation cap icon (Ant Design)	{graduation}	{"component": "ReadOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
370	f2f32e56-7547-4276-b8f0-db1e97e9d323	antd:laptop	antd	Laptop	technology	Laptop icon (Ant Design)	{laptop}	{"component": "LaptopOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
371	05bd3ea3-6009-4f6e-b93d-69d579364bde	antd:mobile	antd	Mobile	technology	Mobile icon (Ant Design)	{mobile}	{"component": "MobileOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
372	4b360579-3281-4d0d-a575-e4f1e36e873c	antd:tablet	antd	Tablet	technology	Tablet icon (Ant Design)	{tablet}	{"component": "TabletOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
373	711f2225-c354-429e-b9f4-1aea14eb62de	antd:code	antd	Code	development	Code icon (Ant Design)	{code}	{"component": "CodeOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
374	7b990b0b-deed-4660-ab33-831617dad2eb	antd:bug	antd	Bug	development	Bug icon (Ant Design)	{bug}	{"component": "BugOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
375	1dbc7744-7fab-46b9-906c-13225822d3fa	antd:api	antd	API	development	API icon (Ant Design)	{api}	{"component": "ApiOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
376	962bea87-749f-4044-adfd-13870023f89b	antd:thunderbolt	antd	Thunderbolt	tools	Thunderbolt icon (Ant Design)	{thunderbolt}	{"component": "ThunderboltOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
377	25ad2c1b-d8f0-4cc7-a317-9fb901cc45e3	antd:rocket	antd	Rocket	tools	Rocket icon (Ant Design)	{rocket}	{"component": "RocketOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
378	619bc669-e216-4dd9-b0e1-8fa1330c4a1c	antd:fire	antd	Fire	tools	Fire icon (Ant Design)	{fire}	{"component": "FireOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
379	d7d823eb-f639-44da-93cc-82079f934aed	antd:bulb	antd	Bulb	tools	Bulb icon (Ant Design)	{bulb,idea}	{"component": "BulbOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
380	e55aba67-c5d4-46f4-853d-11c626e025fa	antd:compass	antd	Compass	location	Compass icon (Ant Design)	{compass}	{"component": "CompassOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
381	7e16edf4-ec4a-430d-bb40-f5b35f83838b	antd:environment	antd	Environment	location	Environment/location icon (Ant Design)	{environment,location}	{"component": "EnvironmentOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
382	c0f240ce-b1a2-4f61-bdbd-4ad5d28485ae	antd:car	antd	Car	travel	Car icon (Ant Design)	{car}	{"component": "CarOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
383	a9f6271b-c9c0-44e3-b935-c99803e7293f	antd:medicine-box	antd	Medicine	health	Medicine box icon (Ant Design)	{medicine}	{"component": "MedicineBoxOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
385	d1f9e864-1337-42ba-bb61-4d783c72bf52	antd:coffee	antd	Coffee	food	Coffee icon (Ant Design)	{coffee}	{"component": "CoffeeOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
386	78fe1b24-2fbf-4cf8-956f-06bdc60d327e	antd:shop	antd	Shop	shopping	Shop icon (Ant Design)	{shop}	{"component": "ShopOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
387	0d94712e-5ab7-4fe3-af08-4c1aae4e1573	antd:bank	antd	Bank	business	Bank icon (Ant Design)	{bank}	{"component": "BankOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
388	20539cbd-1a2c-411a-ab2a-fe84e517a416	antd:wallet	antd	Wallet	business	Wallet icon (Ant Design)	{wallet}	{"component": "WalletOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
389	7db1607d-e441-4e45-ab8e-1d5737ee7760	antd:file-pdf	antd	PDF	documents	PDF icon (Ant Design)	{pdf}	{"component": "FilePdfOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
390	157da7e7-c280-4970-a193-93aba3c7bcb5	antd:file-excel	antd	Excel	documents	Excel icon (Ant Design)	{excel}	{"component": "FileExcelOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
391	c2b5c3d5-3514-4c3b-8761-32279641fead	antd:file-word	antd	Word	documents	Word icon (Ant Design)	{word}	{"component": "FileWordOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
392	60969432-024d-4843-b674-c0a1d603c322	antd:file-image	antd	Image File	documents	Image file icon (Ant Design)	{image,file}	{"component": "FileImageOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
393	66e1964c-426a-4622-8f19-c6d8b4d8f01a	antd:file-zip	antd	Zip	documents	Zip file icon (Ant Design)	{zip}	{"component": "FileZipOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
394	66cd8e91-1d3d-4847-9934-6a66bde2505e	antd:cloud	antd	Cloud	technology	Cloud icon (Ant Design)	{cloud}	{"component": "CloudOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
395	59a1dfad-f9f0-49d1-b54b-4078e436b949	antd:cloud-upload	antd	Cloud Upload	technology	Cloud upload icon (Ant Design)	{cloud,upload}	{"component": "CloudUploadOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
396	2a5e1616-a620-4ce4-8303-1a7e77783e11	antd:cloud-download	antd	Cloud Download	technology	Cloud download icon (Ant Design)	{cloud,download}	{"component": "CloudDownloadOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
397	bc3be367-a22f-469d-827d-0df4196b5361	antd:sync	antd	Sync	actions	Sync icon (Ant Design)	{sync}	{"component": "SyncOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
398	fb5d98b7-e25a-499f-9190-48edb980180d	antd:swap	antd	Swap	actions	Swap icon (Ant Design)	{swap}	{"component": "SwapOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
399	ffc0cb51-0568-4afd-8c7f-9a4d3a0db051	antd:retweet	antd	Retweet	actions	Retweet icon (Ant Design)	{retweet}	{"component": "RetweetOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
400	3f54ffd9-3219-4a2b-95ac-b9c1118c4fb2	antd:enter	antd	Enter	navigation	Enter icon (Ant Design)	{enter}	{"component": "EnterOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
401	5e4efe16-4675-4fba-97f9-05acc5f1747a	antd:logout	antd	Logout	authentication	Logout icon (Ant Design)	{logout}	{"component": "LogoutOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
402	1613c11d-c541-4ebe-8aab-df75c758a5ca	antd:login	antd	Login	authentication	Login icon (Ant Design)	{login}	{"component": "LoginOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
403	cdb5c870-5212-429a-98f2-2e23c8fed26e	antd:translation	antd	Translation	communication	Translation icon (Ant Design)	{translation}	{"component": "TranslationOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
404	40d583c3-426a-4df8-ac49-d7ce96160a67	antd:font-size	antd	Font Size	text	Font size icon (Ant Design)	{font}	{"component": "FontSizeOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
405	2632d0ed-1f3e-4903-8e31-8f3c6dba546a	antd:bold	antd	Bold	text	Bold icon (Ant Design)	{bold}	{"component": "BoldOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
406	c8e9ae3f-6a87-4038-a872-71a67aed2c5f	antd:italic	antd	Italic	text	Italic icon (Ant Design)	{italic}	{"component": "ItalicOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
407	6f0c296a-464f-4dcd-a776-df3bbcc78212	antd:underline	antd	Underline	text	Underline icon (Ant Design)	{underline}	{"component": "UnderlineOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
408	791bb903-7a43-461e-9053-ace267036aa4	antd:strikethrough	antd	Strikethrough	text	Strikethrough icon (Ant Design)	{strikethrough}	{"component": "StrikethroughOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
409	01f5ef67-8a10-49e3-8c34-89623e6d6f32	antd:highlight	antd	Highlight	text	Highlight icon (Ant Design)	{highlight}	{"component": "HighlightOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
410	4d8c11c4-3bc9-4ed0-ba4f-a5f86c24a067	antd:align-left	antd	Align Left	text	Align left icon (Ant Design)	{align,left}	{"component": "AlignLeftOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
411	a7fd2358-541d-4638-a6c5-fb0d95f6c225	antd:align-center	antd	Align Center	text	Align center icon (Ant Design)	{align,center}	{"component": "AlignCenterOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
412	8aab8ccd-c3bb-457a-b331-52bd60c34f4d	antd:align-right	antd	Align Right	text	Align right icon (Ant Design)	{align,right}	{"component": "AlignRightOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
413	3e531713-0184-4081-ae6d-a8be743d7875	antd:ordered-list	antd	Ordered List	text	Ordered list icon (Ant Design)	{list,ordered}	{"component": "OrderedListOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
416	102f9af5-9de4-4141-9a8c-a5e7d97319f3	antd:console-sql	antd	SQL	development	SQL console icon (Ant Design)	{sql}	{"component": "ConsoleSqlOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
417	79e6973b-a8de-4f45-ba95-aa63f318b94b	antd:branches	antd	Branches	development	Branches icon (Ant Design)	{branches,git}	{"component": "BranchesOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
418	c05b1f00-fa59-4d15-a72a-6af909863bd8	antd:gitlab	antd	GitLab	development	GitLab icon (Ant Design)	{gitlab}	{"component": "GitlabOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
419	ce070fe7-9b2a-435c-94db-d981d55f43a0	antd:html5	antd	HTML5	development	HTML5 icon (Ant Design)	{html5}	{"component": "Html5Outlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
420	45d53168-3f36-4026-836b-4aab27995369	antd:css3	antd	CSS3	development	CSS3 icon (Ant Design)	{css3}	{"component": "Css3Outlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
421	7f3c91a9-35a7-4443-863b-54119e79df23	antd:js	antd	JavaScript	development	JavaScript icon (Ant Design)	{javascript}	{"component": "JavascriptOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
422	916b1526-5b7a-48fe-96c7-0d766ec69527	antd:python	antd	Python	development	Python icon (Ant Design)	{python}	{"component": "PythonOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
423	bd4333aa-716d-4220-8c99-724f49fcb7f6	antd:java	antd	Java	development	Java icon (Ant Design)	{java}	{"component": "JavaOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
424	76701c11-6e4c-48e9-9cb3-0d4f1c321397	antd:node	antd	Node	development	Node icon (Ant Design)	{node}	{"component": "NodeIndexOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
425	9d0c18f2-fea4-4050-9534-58015208b041	antd:react	antd	React	development	React icon (Ant Design)	{react}	{"component": "ReactOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
426	ce584806-a352-482c-8b03-a1170adcd26b	antd:vue	antd	Vue	development	Vue icon (Ant Design)	{vue}	{"component": "VueOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
427	7473d900-c330-4fc6-8cd7-f77a8af9bcb3	antd:angular	antd	Angular	development	Angular icon (Ant Design)	{angular}	{"component": "AngularOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
428	2f5eba5a-0de8-4a06-8b17-c72fa429f4b2	antd:docker	antd	Docker	development	Docker icon (Ant Design)	{docker}	{"component": "DockerOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
429	0485ce6a-3732-486c-a4c0-91016723c96c	antd:linux	antd	Linux	development	Linux icon (Ant Design)	{linux}	{"component": "LinuxOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
430	565e4ed7-ad36-40da-9b37-6d52349cda7c	antd:windows	antd	Windows	development	Windows icon (Ant Design)	{windows}	{"component": "WindowsOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
431	7bc1f3ea-db34-4871-a02d-1ba7fc326c13	antd:apple	antd	Apple	development	Apple icon (Ant Design)	{apple}	{"component": "AppleOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
432	bc933b54-240c-4516-9e2d-14b1d3bf50a2	antd:android	antd	Android	development	Android icon (Ant Design)	{android}	{"component": "AndroidOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
433	bfb1577a-9c8a-4bc6-b790-eb97f082333d	antd:chrome	antd	Chrome	development	Chrome icon (Ant Design)	{chrome}	{"component": "ChromeOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
434	eb7c9d0f-8469-460b-864b-244bfcc4daaa	antd:firefox	antd	Firefox	development	Firefox icon (Ant Design)	{firefox}	{"component": "FirefoxOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
435	634f30db-b3df-4b1b-a81c-1d7a20786a3d	antd:safari	antd	Safari	development	Safari icon (Ant Design)	{safari}	{"component": "SafariOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
436	95ae85fc-c060-4c2a-8b65-2344013e28d6	antd:edge	antd	Edge	development	Edge icon (Ant Design)	{edge}	{"component": "EdgeOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
437	27390672-670d-4ccf-b2cb-a33c2fb798d7	antd:opera	antd	Opera	development	Opera icon (Ant Design)	{opera}	{"component": "OperaOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
438	c49d6d5d-a72d-4c48-afd6-2822db72372a	antd:ie	antd	Internet Explorer	development	IE icon (Ant Design)	{ie}	{"component": "IeOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
439	e8279eed-9fe0-4ed8-90e0-79434371b650	antd:brave	antd	Brave	development	Brave icon (Ant Design)	{brave}	{"component": "BraveOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
440	12ce0691-08a0-4876-8c39-f3476c4f0e3e	smily:laughing	smily	Laughing	emotions	Laughing emoji	{laughing,lol,😂}	{"emoji": "😂", "unicode": "U+1F602"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
441	e12ff978-3b0b-4021-b20c-d07f930db500	smily:joy	smily	Joy	emotions	Joy emoji	{joy,tears,😂}	{"emoji": "😂", "unicode": "U+1F602"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
442	d793f4db-2bb0-4681-93d1-0c6c4c40e227	smily:grinning	smily	Grinning	emotions	Grinning emoji	{grinning,😀}	{"emoji": "😀", "unicode": "U+1F600"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
443	87466880-0352-4525-b456-849e41b24810	smily:wink	smily	Wink	emotions	Wink emoji	{wink,😉}	{"emoji": "😉", "unicode": "U+1F609"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
444	e770aac0-802a-4be5-bda4-f9e18443fce2	smily:kiss	smily	Kiss	emotions	Kiss emoji	{kiss,😘}	{"emoji": "😘", "unicode": "U+1F618"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
445	8eafe67c-ba5a-44fe-9d3a-a12dab3fc060	smily:love	smily	Love Eyes	emotions	Love eyes emoji	{love,eyes,😍}	{"emoji": "😍", "unicode": "U+1F60D"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
446	37d05978-120a-43b0-94fd-885585f6c4b1	smily:cool	smily	Cool	emotions	Cool emoji	{cool,😎}	{"emoji": "😎", "unicode": "U+1F60E"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
447	1e6256b1-4da9-4803-a912-36a76504662d	smily:thinking	smily	Thinking	emotions	Thinking emoji	{thinking,🤔}	{"emoji": "🤔", "unicode": "U+1F914"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
448	3cde03d9-3076-4994-b450-7c4199edb23f	smily:shushing	smily	Shushing	emotions	Shushing emoji	{shushing,🤫}	{"emoji": "🤫", "unicode": "U+1F92B"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
449	c2a486cf-d4f0-460f-8d02-a3fb6fd354ff	smily:zipper-mouth	smily	Zipper Mouth	emotions	Zipper mouth emoji	{zipper,🤐}	{"emoji": "🤐", "unicode": "U+1F910"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
450	edea2332-26f2-4c6c-84cd-36781e36871c	smily:raised-eyebrow	smily	Raised Eyebrow	emotions	Raised eyebrow emoji	{raised,eyebrow,🤨}	{"emoji": "🤨", "unicode": "U+1F928"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
451	a8ed4f39-eed1-4013-8ea1-670ab900ea65	smily:neutral	smily	Neutral	emotions	Neutral face emoji	{neutral,😐}	{"emoji": "😐", "unicode": "U+1F610"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
452	056bb106-df44-40c3-8c65-de9dbc40303a	smily:expressionless	smily	Expressionless	emotions	Expressionless emoji	{expressionless,😑}	{"emoji": "😑", "unicode": "U+1F611"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
453	55f0c8b5-733a-4c81-a614-ccd9b175c585	smily:rolling-eyes	smily	Rolling Eyes	emotions	Rolling eyes emoji	{rolling,eyes,🙄}	{"emoji": "🙄", "unicode": "U+1F644"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
454	7027035d-6872-4378-947e-49232acd88d8	smily:sad	smily	Sad	emotions	Sad emoji	{sad,😢}	{"emoji": "😢", "unicode": "U+1F622"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
455	5a016936-bd01-4887-9b03-24ef56c1485b	smily:crying	smily	Crying	emotions	Crying emoji	{crying,😭}	{"emoji": "😭", "unicode": "U+1F62D"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
456	c7e3c35c-e4f4-48a6-8beb-5f1e07747ea9	smily:angry	smily	Angry	emotions	Angry emoji	{angry,😠}	{"emoji": "😠", "unicode": "U+1F620"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
457	4e187d9e-2f10-4a0e-a17e-ae8f88e23bc4	smily:rage	smily	Rage	emotions	Rage emoji	{rage,😡}	{"emoji": "😡", "unicode": "U+1F621"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
458	93f71e37-ef24-4c55-b8ee-766914ca5179	smily:confused	smily	Confused	emotions	Confused emoji	{confused,😕}	{"emoji": "😕", "unicode": "U+1F615"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
459	36b04689-9515-4ab2-9222-276c7972319b	smily:worried	smily	Worried	emotions	Worried emoji	{worried,😟}	{"emoji": "😟", "unicode": "U+1F61F"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
460	55439628-91c5-4357-bc86-798a37b9a07f	smily:slightly-frowning	smily	Slightly Frowning	emotions	Slightly frowning emoji	{frowning,🙁}	{"emoji": "🙁", "unicode": "U+1F641"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
461	fd8e7d66-4919-4e44-9623-a73653afa339	smily:open-mouth	smily	Open Mouth	emotions	Open mouth emoji	{open,mouth,😮}	{"emoji": "😮", "unicode": "U+1F62E"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
462	6bc55001-56d1-4b78-b229-6abe68632944	smily:hushed	smily	Hushed	emotions	Hushed emoji	{hushed,😯}	{"emoji": "😯", "unicode": "U+1F62F"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
463	2eb60672-9348-4e95-9b42-a496bf6011e1	smily:astonished	smily	Astonished	emotions	Astonished emoji	{astonished,😲}	{"emoji": "😲", "unicode": "U+1F632"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
464	a94f86c7-3cb9-426e-9409-c9ab615b8382	smily:flushed	smily	Flushed	emotions	Flushed emoji	{flushed,😳}	{"emoji": "😳", "unicode": "U+1F633"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
465	ff461912-d1ac-481c-baeb-6fef2bd5becf	smily:pleading	smily	Pleading	emotions	Pleading emoji	{pleading,🥺}	{"emoji": "🥺", "unicode": "U+1F97A"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
466	a568aba9-4627-4b70-b4df-b549104e5301	smily:relieved	smily	Relieved	emotions	Relieved emoji	{relieved,😌}	{"emoji": "😌", "unicode": "U+1F60C"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
467	799347f3-ebfb-43cd-ad6e-7daeb64b1891	smily:pensive	smily	Pensive	emotions	Pensive emoji	{pensive,😔}	{"emoji": "😔", "unicode": "U+1F614"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
468	99ca5870-6c79-4509-902b-39c34edd785d	smily:sleepy	smily	Sleepy	emotions	Sleepy emoji	{sleepy,😪}	{"emoji": "😪", "unicode": "U+1F62A"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
469	b7c0781f-9c73-41d8-8e6e-f717abf05ebe	smily:drooling	smily	Drooling	emotions	Drooling emoji	{drooling,🤤}	{"emoji": "🤤", "unicode": "U+1F924"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
470	82ec7f64-1c57-421b-8d3b-37eed71678d8	smily:sleeping	smily	Sleeping	emotions	Sleeping emoji	{sleeping,😴}	{"emoji": "😴", "unicode": "U+1F634"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
471	83623bdc-4dcb-4020-9e00-4ffc438aa8a3	smily:mask	smily	Mask	emotions	Mask emoji	{mask,😷}	{"emoji": "😷", "unicode": "U+1F637"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
472	ae2c58d4-4ad4-4190-bb65-9394258afa4a	smily:face-with-thermometer	smily	Sick	emotions	Sick emoji	{sick,thermometer,🤒}	{"emoji": "🤒", "unicode": "U+1F912"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
473	ff6ba749-7333-445b-952c-2c8a1b18b89f	smily:face-with-head-bandage	smily	Injured	emotions	Injured emoji	{injured,bandage,🤕}	{"emoji": "🤕", "unicode": "U+1F915"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
474	3cd86580-7849-48de-b3d5-a73d236d5bbb	smily:nauseated	smily	Nauseated	emotions	Nauseated emoji	{nauseated,🤢}	{"emoji": "🤢", "unicode": "U+1F922"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
475	dd4a1c88-aed7-4b5d-8453-9881c088755d	smily:vomiting	smily	Vomiting	emotions	Vomiting emoji	{vomiting,🤮}	{"emoji": "🤮", "unicode": "U+1F92E"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
476	700b4046-25ec-4f38-9854-7035b686ab5e	smily:sneezing	smily	Sneezing	emotions	Sneezing emoji	{sneezing,🤧}	{"emoji": "🤧", "unicode": "U+1F927"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
477	bb66465a-61c9-4ca3-9297-23b22d6ab489	smily:hot	smily	Hot	emotions	Hot face emoji	{hot,🥵}	{"emoji": "🥵", "unicode": "U+1F975"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
478	a859b795-11de-4e80-a427-b196bb7acc0a	smily:cold	smily	Cold	emotions	Cold face emoji	{cold,🥶}	{"emoji": "🥶", "unicode": "U+1F976"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
479	22a35397-f182-41e9-94b7-401927af857a	smily:woozy	smily	Woozy	emotions	Woozy emoji	{woozy,🥴}	{"emoji": "🥴", "unicode": "U+1F974"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
480	a5cb6903-809c-44d1-80c5-64eb1db14b87	smily:dizzy	smily	Dizzy	emotions	Dizzy emoji	{dizzy,😵}	{"emoji": "😵", "unicode": "U+1F635"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
481	a21b03aa-8118-4610-8138-ba35793f031e	smily:exploding-head	smily	Exploding Head	emotions	Exploding head emoji	{exploding,head,🤯}	{"emoji": "🤯", "unicode": "U+1F92F"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
482	2edbd900-702d-4829-9975-179efda14573	smily:cowboy	smily	Cowboy	emotions	Cowboy emoji	{cowboy,🤠}	{"emoji": "🤠", "unicode": "U+1F920"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
483	e6ee883f-be31-4b15-bd57-f94de46ed350	smily:partying	smily	Partying	emotions	Partying emoji	{partying,🥳}	{"emoji": "🥳", "unicode": "U+1F973"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
484	39f9535f-0924-421e-979f-efc8b2f2daa0	smily:disguised	smily	Disguised	emotions	Disguised emoji	{disguised,🥸}	{"emoji": "🥸", "unicode": "U+1F978"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
485	9951d4bf-3996-47ca-9caa-bfb8c06ec93e	smily:sunglasses	smily	Sunglasses	emotions	Sunglasses emoji	{sunglasses,😎}	{"emoji": "😎", "unicode": "U+1F60E"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
486	dc32d579-80f5-480f-bead-1e67caed4095	smily:nerd	smily	Nerd	emotions	Nerd emoji	{nerd,🤓}	{"emoji": "🤓", "unicode": "U+1F913"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
487	ef114eef-1ccf-40ef-8252-0102f9388285	smily:monocle	smily	Monocle	emotions	Monocle emoji	{monocle,🧐}	{"emoji": "🧐", "unicode": "U+1F9D0"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
488	a69e7f47-4faa-4c2d-8287-6f2ea207856e	smily:confused-face	smily	Confused Face	emotions	Confused face emoji	{confused,😕}	{"emoji": "😕", "unicode": "U+1F615"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
489	a508cf58-d1ef-469c-8931-8b71178f7c53	smily:worried-face	smily	Worried Face	emotions	Worried face emoji	{worried,😟}	{"emoji": "😟", "unicode": "U+1F61F"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
490	d7557de4-d8d2-4780-95c1-4ef9fc04a614	smily:slightly-frowning-face	smily	Slightly Frowning Face	emotions	Slightly frowning face emoji	{frowning,🙁}	{"emoji": "🙁", "unicode": "U+1F641"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
491	0f8ab8bb-d8c1-4b38-804d-5a3c746e68d9	smily:open-mouth-face	smily	Open Mouth Face	emotions	Open mouth face emoji	{open,mouth,😮}	{"emoji": "😮", "unicode": "U+1F62E"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
492	a2cce378-1028-43fd-9e1f-224d6770d066	smily:hushed-face	smily	Hushed Face	emotions	Hushed face emoji	{hushed,😯}	{"emoji": "😯", "unicode": "U+1F62F"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
493	c0913804-e141-4ade-84c0-fc58a36e4422	smily:astonished-face	smily	Astonished Face	emotions	Astonished face emoji	{astonished,😲}	{"emoji": "😲", "unicode": "U+1F632"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
494	026fc4f1-8e1f-497d-a3cb-079819867caf	smily:flushed-face	smily	Flushed Face	emotions	Flushed face emoji	{flushed,😳}	{"emoji": "😳", "unicode": "U+1F633"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
495	d04033b1-f983-47ba-bf72-098a39be2f24	smily:pleading-face	smily	Pleading Face	emotions	Pleading face emoji	{pleading,🥺}	{"emoji": "🥺", "unicode": "U+1F97A"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
496	cbd4f404-57d0-4b1e-8dd6-8ffa2d9bb009	smily:frowning-face	smily	Frowning Face	emotions	Frowning face emoji	{frowning,☹️}	{"emoji": "☹️", "unicode": "U+2639"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
497	4d6bd4aa-3734-4211-9cc8-b25a5e371955	smily:anguished	smily	Anguished	emotions	Anguished emoji	{anguished,😧}	{"emoji": "😧", "unicode": "U+1F627"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
498	263bed3b-97b1-4132-99cc-4118db3f4f3d	smily:fearful	smily	Fearful	emotions	Fearful emoji	{fearful,😨}	{"emoji": "😨", "unicode": "U+1F628"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
499	a1455ff4-bffe-4618-939a-f8906b0dd09e	smily:cold-sweat	smily	Cold Sweat	emotions	Cold sweat emoji	{cold,sweat,😰}	{"emoji": "😰", "unicode": "U+1F630"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
500	32e972c8-f4a6-408c-9c1c-97b39a4b5b8e	smily:disappointed-relieved	smily	Disappointed Relieved	emotions	Disappointed relieved emoji	{disappointed,relieved,😥}	{"emoji": "😥", "unicode": "U+1F625"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
501	f0ba5588-356c-40e2-abb8-668d3576fbe5	smily:cry	smily	Cry	emotions	Cry emoji	{cry,😢}	{"emoji": "😢", "unicode": "U+1F622"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
502	c70da891-f12a-42a0-8a0d-894e05056163	smily:sob	smily	Sob	emotions	Sob emoji	{sob,😭}	{"emoji": "😭", "unicode": "U+1F62D"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
503	94d1c505-d0f8-4087-a131-cb761e055885	smily:scream	smily	Scream	emotions	Scream emoji	{scream,😱}	{"emoji": "😱", "unicode": "U+1F631"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
505	a2ee515c-4791-4a27-850f-10bf6a0928f5	smily:persevere	smily	Persevere	emotions	Persevere emoji	{persevere,😣}	{"emoji": "😣", "unicode": "U+1F623"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
506	2578fbad-7977-46f7-bdea-f88b519e9d44	smily:disappointed	smily	Disappointed	emotions	Disappointed emoji	{disappointed,😞}	{"emoji": "😞", "unicode": "U+1F61E"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
507	18a98b59-692c-4781-a94f-a08c534390e7	smily:sweat	smily	Sweat	emotions	Sweat emoji	{sweat,😓}	{"emoji": "😓", "unicode": "U+1F613"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
508	1be8fa54-90ca-4f4a-a4fa-03d63868c119	smily:weary	smily	Weary	emotions	Weary emoji	{weary,😩}	{"emoji": "😩", "unicode": "U+1F629"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
509	3dcd4d08-98fc-487f-a0bf-11b99bfe3037	smily:tired	smily	Tired	emotions	Tired emoji	{tired,😫}	{"emoji": "😫", "unicode": "U+1F62B"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
510	fef0a562-3c43-47cd-b557-a4370a7bed03	smily:yawning	smily	Yawning	emotions	Yawning emoji	{yawning,🥱}	{"emoji": "🥱", "unicode": "U+1F971"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
511	3c0b9a46-6087-4ffb-bfde-a87a4bd7285c	smily:steam-nose	smily	Steam Nose	emotions	Steam nose emoji	{steam,nose,😤}	{"emoji": "😤", "unicode": "U+1F624"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
512	192e0ac2-ad81-4666-9231-ed67553aabee	smily:pouting	smily	Pouting	emotions	Pouting emoji	{pouting,😡}	{"emoji": "😡", "unicode": "U+1F621"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
513	8add6b7d-de3b-4b26-9dad-4d0e6e1295f4	smily:angry-face	smily	Angry Face	emotions	Angry face emoji	{angry,😠}	{"emoji": "😠", "unicode": "U+1F620"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
514	57241d95-caaa-4e05-9776-075f2f70766a	smily:cursing	smily	Cursing	emotions	Cursing emoji	{cursing,🤬}	{"emoji": "🤬", "unicode": "U+1F92C"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
515	38e42855-5c4b-4f0b-946d-6de061cd174d	smily:symbols-over-mouth	smily	Symbols Over Mouth	emotions	Symbols over mouth emoji	{symbols,mouth,🤭}	{"emoji": "🤭", "unicode": "U+1F92D"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
516	1641666f-14c7-4872-91c6-04fbf9fb1bf1	smily:hand-over-mouth	smily	Hand Over Mouth	emotions	Hand over mouth emoji	{hand,mouth,🤭}	{"emoji": "🤭", "unicode": "U+1F92D"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
517	796caeaf-b957-4f54-9175-e28f33e874f6	smily:shushing-face	smily	Shushing Face	emotions	Shushing face emoji	{shushing,🤫}	{"emoji": "🤫", "unicode": "U+1F92B"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
518	7786702c-8404-4c50-b0db-73c2ca31aa92	smily:lying	smily	Lying	emotions	Lying emoji	{lying,🤥}	{"emoji": "🤥", "unicode": "U+1F925"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
519	e26e67f1-4b88-42fa-9ace-93955b6ab454	smily:no-mouth	smily	No Mouth	emotions	No mouth emoji	{no,mouth,😶}	{"emoji": "😶", "unicode": "U+1F636"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
520	50a5f5f9-7ccb-471e-a11c-86601c7951c5	smily:smirk	smily	Smirk	emotions	Smirk emoji	{smirk,😏}	{"emoji": "😏", "unicode": "U+1F60F"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
521	db9b279d-edde-43e9-8bed-265d750a77a0	smily:unamused	smily	Unamused	emotions	Unamused emoji	{unamused,😒}	{"emoji": "😒", "unicode": "U+1F612"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
522	7f74b638-152e-47cd-95aa-1b137c5d7308	smily:roll-eyes	smily	Roll Eyes	emotions	Roll eyes emoji	{roll,eyes,🙄}	{"emoji": "🙄", "unicode": "U+1F644"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
523	2c6ce3cd-3195-44c4-ae57-7ff880066c19	smily:grimacing	smily	Grimacing	emotions	Grimacing emoji	{grimacing,😬}	{"emoji": "😬", "unicode": "U+1F62C"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
524	60c7dfa9-ad37-466c-b885-e30a4c5e55db	smily:lying-face	smily	Lying Face	emotions	Lying face emoji	{lying,🤥}	{"emoji": "🤥", "unicode": "U+1F925"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
525	bf51e065-83d2-4644-bc9e-28638c34eec9	smily:relieved-face	smily	Relieved Face	emotions	Relieved face emoji	{relieved,😌}	{"emoji": "😌", "unicode": "U+1F60C"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
526	c8797e71-b34d-408f-b1bd-f1476fa0cd34	smily:pensive-face	smily	Pensive Face	emotions	Pensive face emoji	{pensive,😔}	{"emoji": "😔", "unicode": "U+1F614"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
527	7a25e754-d2dc-4792-b7d9-9e20169dcc62	smily:sleepy-face	smily	Sleepy Face	emotions	Sleepy face emoji	{sleepy,😪}	{"emoji": "😪", "unicode": "U+1F62A"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
528	6c7853fb-5612-434a-ab3c-0b9714b73528	smily:drooling-face	smily	Drooling Face	emotions	Drooling face emoji	{drooling,🤤}	{"emoji": "🤤", "unicode": "U+1F924"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
529	43339dda-9299-45f4-a630-4e61553a2937	smily:sleeping-face	smily	Sleeping Face	emotions	Sleeping face emoji	{sleeping,😴}	{"emoji": "😴", "unicode": "U+1F634"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
530	d920463b-3d85-4376-b233-dfaddd7c6d65	smily:face-with-medical-mask	smily	Medical Mask	emotions	Medical mask emoji	{mask,medical,😷}	{"emoji": "😷", "unicode": "U+1F637"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
533	a9213bf3-9ed4-4731-aec2-e2885e9e4c88	smily:nauseated-face	smily	Nauseated Face	emotions	Nauseated face emoji	{nauseated,🤢}	{"emoji": "🤢", "unicode": "U+1F922"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
534	82179250-f2a3-4419-8979-bc2459556745	smily:face-vomiting	smily	Vomiting Face	emotions	Face vomiting emoji	{vomiting,🤮}	{"emoji": "🤮", "unicode": "U+1F92E"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
535	a34cbdb4-7590-44af-aae9-87cc3eb9a77b	smily:sneezing-face	smily	Sneezing Face	emotions	Sneezing face emoji	{sneezing,🤧}	{"emoji": "🤧", "unicode": "U+1F927"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
536	2231d8ee-36ef-48d6-a071-a457e93edf4a	smily:hot-face	smily	Hot Face	emotions	Hot face emoji	{hot,🥵}	{"emoji": "🥵", "unicode": "U+1F975"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
537	b8ea86e6-dfb9-4813-9bc0-d4f0a9dcfb86	smily:cold-face	smily	Cold Face	emotions	Cold face emoji	{cold,🥶}	{"emoji": "🥶", "unicode": "U+1F976"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
538	3072039b-0a6b-49a8-be67-6f535d2907dd	smily:woozy-face	smily	Woozy Face	emotions	Woozy face emoji	{woozy,🥴}	{"emoji": "🥴", "unicode": "U+1F974"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
539	0022104f-6915-440d-95d6-f5db25c93522	smily:dizzy-face	smily	Dizzy Face	emotions	Dizzy face emoji	{dizzy,😵}	{"emoji": "😵", "unicode": "U+1F635"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
540	55b7b265-a8ad-4a47-a0a6-b7911a99a518	smily:exploding-head-face	smily	Exploding Head Face	emotions	Exploding head face emoji	{exploding,head,🤯}	{"emoji": "🤯", "unicode": "U+1F92F"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
541	561d804b-a8a6-4a4f-8913-f55edae2dfb7	smily:cowboy-hat-face	smily	Cowboy Hat	emotions	Cowboy hat face emoji	{cowboy,hat,🤠}	{"emoji": "🤠", "unicode": "U+1F920"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
542	15789b6d-3214-47d8-99df-ec4ab4cb9142	smily:partying-face	smily	Partying Face	emotions	Partying face emoji	{partying,🥳}	{"emoji": "🥳", "unicode": "U+1F973"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
543	2a296a37-343b-44ac-8ae1-ff9186c6e359	smily:disguised-face	smily	Disguised Face	emotions	Disguised face emoji	{disguised,🥸}	{"emoji": "🥸", "unicode": "U+1F978"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
544	d5565e7c-68c9-41cc-af71-8299561b6cbd	smily:sunglasses-face	smily	Sunglasses Face	emotions	Sunglasses face emoji	{sunglasses,😎}	{"emoji": "😎", "unicode": "U+1F60E"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
545	919bc578-2c62-4b76-b246-bae7b7a732cc	smily:nerd-face	smily	Nerd Face	emotions	Nerd face emoji	{nerd,🤓}	{"emoji": "🤓", "unicode": "U+1F913"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
546	86ccb59c-45b4-4eb9-8a21-7ddc6a46e95e	smily:face-with-monocle	smily	Monocle	emotions	Face with monocle emoji	{monocle,🧐}	{"emoji": "🧐", "unicode": "U+1F9D0"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
547	0f24687a-3507-4562-b1c5-ef3d67e872bc	smily:confused-face-emoji	smily	Confused Face Emoji	emotions	Confused face emoji	{confused,😕}	{"emoji": "😕", "unicode": "U+1F615"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
548	27a4d98f-ab0b-41e9-b637-870479745d51	smily:worried-face-emoji	smily	Worried Face Emoji	emotions	Worried face emoji	{worried,😟}	{"emoji": "😟", "unicode": "U+1F61F"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
549	b4c80e4c-e0f9-4f56-9655-e5301e1a2420	smily:slightly-frowning-face-emoji	smily	Slightly Frowning Face Emoji	emotions	Slightly frowning face emoji	{frowning,🙁}	{"emoji": "🙁", "unicode": "U+1F641"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
550	42b59f84-7210-480a-b8db-6ee3ed113c1d	smily:open-mouth-face-emoji	smily	Open Mouth Face Emoji	emotions	Open mouth face emoji	{open,mouth,😮}	{"emoji": "😮", "unicode": "U+1F62E"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
551	280ea013-53c8-4075-9c1e-ecb164cbf478	smily:hushed-face-emoji	smily	Hushed Face Emoji	emotions	Hushed face emoji	{hushed,😯}	{"emoji": "😯", "unicode": "U+1F62F"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
552	f0581c2b-3c19-40eb-8570-bc940a1a36c7	smily:astonished-face-emoji	smily	Astonished Face Emoji	emotions	Astonished face emoji	{astonished,😲}	{"emoji": "😲", "unicode": "U+1F632"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
553	c329e809-e56a-47a2-91e9-f8bb7da3f291	smily:flushed-face-emoji	smily	Flushed Face Emoji	emotions	Flushed face emoji	{flushed,😳}	{"emoji": "😳", "unicode": "U+1F633"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
554	056a69d8-562d-4157-bb39-fac1f8d2be98	smily:pleading-face-emoji	smily	Pleading Face Emoji	emotions	Pleading face emoji	{pleading,🥺}	{"emoji": "🥺", "unicode": "U+1F97A"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
555	8adf64b3-765a-4ba2-ad2e-94ad801c108f	smily:frowning-face-emoji	smily	Frowning Face Emoji	emotions	Frowning face emoji	{frowning,☹️}	{"emoji": "☹️", "unicode": "U+2639"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
556	3dad8d89-f285-46af-9c66-2a78e6aa3b4a	smily:anguished-face	smily	Anguished Face	emotions	Anguished face emoji	{anguished,😧}	{"emoji": "😧", "unicode": "U+1F627"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
557	89f297f6-698b-4335-b4b0-61b697ed2fe8	smily:fearful-face	smily	Fearful Face	emotions	Fearful face emoji	{fearful,😨}	{"emoji": "😨", "unicode": "U+1F628"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
558	6f547f36-9436-4011-95d3-589b68432a69	smily:cold-sweat-face	smily	Cold Sweat Face	emotions	Cold sweat face emoji	{cold,sweat,😰}	{"emoji": "😰", "unicode": "U+1F630"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
559	6357e3a2-4141-41b9-aad8-4e99cfeb5257	smily:disappointed-relieved-face	smily	Disappointed Relieved Face	emotions	Disappointed relieved face emoji	{disappointed,relieved,😥}	{"emoji": "😥", "unicode": "U+1F625"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
560	be20d91f-9329-47c3-95db-4990ff37d19b	smily:cry-face	smily	Cry Face	emotions	Cry face emoji	{cry,😢}	{"emoji": "😢", "unicode": "U+1F622"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
561	5f262c38-63bf-457e-b73d-5d92482c91c0	smily:sob-face	smily	Sob Face	emotions	Sob face emoji	{sob,😭}	{"emoji": "😭", "unicode": "U+1F62D"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
562	4a50d531-15a2-461b-b730-1e7afedc8d57	smily:scream-face	smily	Scream Face	emotions	Scream face emoji	{scream,😱}	{"emoji": "😱", "unicode": "U+1F631"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
564	7163842d-ed74-4ffd-be47-4a1874ea5193	smily:persevere-face	smily	Persevere Face	emotions	Persevere face emoji	{persevere,😣}	{"emoji": "😣", "unicode": "U+1F623"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
565	f7ad4da9-74de-4117-a7b0-d3ce709942fe	smily:disappointed-face	smily	Disappointed Face	emotions	Disappointed face emoji	{disappointed,😞}	{"emoji": "😞", "unicode": "U+1F61E"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
566	34f66ed1-032d-45ae-998a-3b67fdf307dd	smily:sweat-face	smily	Sweat Face	emotions	Sweat face emoji	{sweat,😓}	{"emoji": "😓", "unicode": "U+1F613"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
567	9e6f6abb-4944-4154-a4ba-c73111830ac5	smily:weary-face	smily	Weary Face	emotions	Weary face emoji	{weary,😩}	{"emoji": "😩", "unicode": "U+1F629"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
568	90865431-8323-48e4-8732-0ada9c49f755	smily:tired-face	smily	Tired Face	emotions	Tired face emoji	{tired,😫}	{"emoji": "😫", "unicode": "U+1F62B"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
569	cc3ff2de-3610-4c79-b034-a4c593121bec	smily:yawning-face	smily	Yawning Face	emotions	Yawning face emoji	{yawning,🥱}	{"emoji": "🥱", "unicode": "U+1F971"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
570	c584abd8-e3a6-462d-8c1c-c574dd23a11f	smily:steam-nose-face	smily	Steam Nose Face	emotions	Steam nose face emoji	{steam,nose,😤}	{"emoji": "😤", "unicode": "U+1F624"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
571	583bd51e-70bb-4ccb-bcfa-7c36019d95aa	smily:pouting-face	smily	Pouting Face	emotions	Pouting face emoji	{pouting,😡}	{"emoji": "😡", "unicode": "U+1F621"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
572	b7b0a699-d313-44af-a5e1-03310e4e0cf9	smily:angry-face-emoji	smily	Angry Face Emoji	emotions	Angry face emoji	{angry,😠}	{"emoji": "😠", "unicode": "U+1F620"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
573	2633123e-7675-4649-b8d5-4d1b133a7790	smily:cursing-face	smily	Cursing Face	emotions	Cursing face emoji	{cursing,🤬}	{"emoji": "🤬", "unicode": "U+1F92C"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
574	ce636ed3-8336-4aa6-a7a6-6728e7601f36	smily:symbols-over-mouth-face	smily	Symbols Over Mouth Face	emotions	Symbols over mouth face emoji	{symbols,mouth,🤭}	{"emoji": "🤭", "unicode": "U+1F92D"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
575	17a0c531-f7bc-4ab0-9de8-2b8d34872639	smily:hand-over-mouth-face	smily	Hand Over Mouth Face	emotions	Hand over mouth face emoji	{hand,mouth,🤭}	{"emoji": "🤭", "unicode": "U+1F92D"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
576	ba789027-9442-48e9-8833-6a1b99994174	smily:shushing-face-emoji	smily	Shushing Face Emoji	emotions	Shushing face emoji	{shushing,🤫}	{"emoji": "🤫", "unicode": "U+1F92B"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
577	0c1a7bc3-eb39-414b-b273-e87b8aaca254	smily:lying-face-emoji	smily	Lying Face Emoji	emotions	Lying face emoji	{lying,🤥}	{"emoji": "🤥", "unicode": "U+1F925"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
578	25e6a8d5-5ffd-4cf7-9e81-213494d76511	smily:no-mouth-face	smily	No Mouth Face	emotions	No mouth face emoji	{no,mouth,😶}	{"emoji": "😶", "unicode": "U+1F636"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
579	f53fbee9-a4bf-4f4c-979f-65ed2347ccfb	smily:smirk-face	smily	Smirk Face	emotions	Smirk face emoji	{smirk,😏}	{"emoji": "😏", "unicode": "U+1F60F"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
580	4bec1c1c-6855-4332-9064-5db4b4a4c866	smily:unamused-face	smily	Unamused Face	emotions	Unamused face emoji	{unamused,😒}	{"emoji": "😒", "unicode": "U+1F612"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
581	977de3e4-668e-4414-9c7c-46899db0f9c3	smily:roll-eyes-face	smily	Roll Eyes Face	emotions	Roll eyes face emoji	{roll,eyes,🙄}	{"emoji": "🙄", "unicode": "U+1F644"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
582	119a07aa-94f7-4493-af84-4125b9b27200	smily:grimacing-face	smily	Grimacing Face	emotions	Grimacing face emoji	{grimacing,😬}	{"emoji": "😬", "unicode": "U+1F62C"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
583	11661a54-c46c-41ef-b1bf-9fa2c5cf2edc	smily:lying-face-emoji2	smily	Lying Face Emoji 2	emotions	Lying face emoji	{lying,🤥}	{"emoji": "🤥", "unicode": "U+1F925"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
584	9584a218-1a2e-440b-8a87-086df777c2fa	smily:relieved-face-emoji	smily	Relieved Face Emoji	emotions	Relieved face emoji	{relieved,😌}	{"emoji": "😌", "unicode": "U+1F60C"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
585	ead2d2cc-8081-4785-a284-22044ff4eba5	smily:pensive-face-emoji	smily	Pensive Face Emoji	emotions	Pensive face emoji	{pensive,😔}	{"emoji": "😔", "unicode": "U+1F614"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
586	dd09982b-64c9-4893-8737-67e586aad0c4	smily:sleepy-face-emoji	smily	Sleepy Face Emoji	emotions	Sleepy face emoji	{sleepy,😪}	{"emoji": "😪", "unicode": "U+1F62A"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
587	b315a4c9-bf48-4254-b500-69bbf930bbc7	smily:drooling-face-emoji	smily	Drooling Face Emoji	emotions	Drooling face emoji	{drooling,🤤}	{"emoji": "🤤", "unicode": "U+1F924"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
588	c82734b0-3544-4d42-b900-5828d17a6962	smily:sleeping-face-emoji	smily	Sleeping Face Emoji	emotions	Sleeping face emoji	{sleeping,😴}	{"emoji": "😴", "unicode": "U+1F634"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
589	146c55e7-0a8c-492a-8fee-3d630d3f7d8b	smily:face-with-medical-mask-emoji	smily	Medical Mask Emoji	emotions	Medical mask emoji	{mask,medical,😷}	{"emoji": "😷", "unicode": "U+1F637"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
590	5a09a2a1-4cf7-4533-83b1-1f1705766369	smily:face-with-thermometer-emoji	smily	Thermometer Emoji	emotions	Face with thermometer emoji	{thermometer,🤒}	{"emoji": "🤒", "unicode": "U+1F912"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
591	d7934ee6-2a64-4b6b-8cc9-4733b915f0fa	smily:face-with-head-bandage-emoji	smily	Head Bandage Emoji	emotions	Face with head bandage emoji	{bandage,head,🤕}	{"emoji": "🤕", "unicode": "U+1F915"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
592	8d0d8ffb-629a-48a5-b6cd-7a15e9073aea	smily:nauseated-face-emoji	smily	Nauseated Face Emoji	emotions	Nauseated face emoji	{nauseated,🤢}	{"emoji": "🤢", "unicode": "U+1F922"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
593	47b24bd0-96d8-4b35-9ef3-176145259854	smily:face-vomiting-emoji	smily	Vomiting Face Emoji	emotions	Face vomiting emoji	{vomiting,🤮}	{"emoji": "🤮", "unicode": "U+1F92E"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
594	03e8306b-fc0a-45cf-a133-fad6be750dbf	smily:sneezing-face-emoji	smily	Sneezing Face Emoji	emotions	Sneezing face emoji	{sneezing,🤧}	{"emoji": "🤧", "unicode": "U+1F927"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
595	e1ea72e9-102c-4e1e-b210-4675ade523d1	smily:hot-face-emoji	smily	Hot Face Emoji	emotions	Hot face emoji	{hot,🥵}	{"emoji": "🥵", "unicode": "U+1F975"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
596	f6602ae2-9799-4326-89db-ab95882436bb	smily:cold-face-emoji	smily	Cold Face Emoji	emotions	Cold face emoji	{cold,🥶}	{"emoji": "🥶", "unicode": "U+1F976"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
597	7d40a23a-6de5-4a4b-bc05-0c1089c26e87	smily:woozy-face-emoji	smily	Woozy Face Emoji	emotions	Woozy face emoji	{woozy,🥴}	{"emoji": "🥴", "unicode": "U+1F974"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
598	d613b8f5-e74d-43f0-a2e9-3b4646a72903	smily:dizzy-face-emoji	smily	Dizzy Face Emoji	emotions	Dizzy face emoji	{dizzy,😵}	{"emoji": "😵", "unicode": "U+1F635"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
599	54708d1b-95c9-4b54-936a-bd8948a54cbe	smily:exploding-head-face-emoji	smily	Exploding Head Face Emoji	emotions	Exploding head face emoji	{exploding,head,🤯}	{"emoji": "🤯", "unicode": "U+1F92F"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
600	efd42e3b-5967-4dc1-bc43-55f68562dcae	smily:cowboy-hat-face-emoji	smily	Cowboy Hat Emoji	emotions	Cowboy hat face emoji	{cowboy,hat,🤠}	{"emoji": "🤠", "unicode": "U+1F920"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
601	a109302c-8978-406f-93ef-caa3e78fa5c9	smily:partying-face-emoji	smily	Partying Face Emoji	emotions	Partying face emoji	{partying,🥳}	{"emoji": "🥳", "unicode": "U+1F973"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
602	760a8b72-48b7-4c2b-b1b4-53a1295908ec	smily:disguised-face-emoji	smily	Disguised Face Emoji	emotions	Disguised face emoji	{disguised,🥸}	{"emoji": "🥸", "unicode": "U+1F978"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
603	8866b95d-843c-49ad-8be9-2b5aa8f4b850	smily:sunglasses-face-emoji	smily	Sunglasses Face Emoji	emotions	Sunglasses face emoji	{sunglasses,😎}	{"emoji": "😎", "unicode": "U+1F60E"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
604	b09dfe0e-b6d4-4e71-bd72-66356f533cb9	smily:nerd-face-emoji	smily	Nerd Face Emoji	emotions	Nerd face emoji	{nerd,🤓}	{"emoji": "🤓", "unicode": "U+1F913"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
605	33d46cfa-5a4b-4e7a-a709-3bb4c9f45618	smily:face-with-monocle-emoji	smily	Monocle Emoji	emotions	Face with monocle emoji	{monocle,🧐}	{"emoji": "🧐", "unicode": "U+1F9D0"}	0	f	t	t	1	2026-01-18 23:06:17.883283	2026-01-18 23:06:17.883283
\.


--
-- Data for Name: integration_providers; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.integration_providers (provider_id, provider_uuid, provider_name, provider_display_name, provider_category, description, documentation_url, required_fields_json, optional_fields_json, metadata_json, is_active, is_builtin, created_at, last_updated) FROM stdin;
1	ff751f49-e9ed-4607-a8c5-e2d81816945e	aws_ses	AWS SES	email	Amazon Simple Email Service for sending transactional and marketing emails	\N	[{"is_secret": false, "field_name": "aws_access_key_id", "description": "Your AWS access key ID", "is_required": true, "display_name": "AWS Access Key ID", "field_type_id": 1}, {"is_secret": true, "field_name": "aws_secret_access_key", "description": "Your AWS secret access key", "is_required": true, "display_name": "AWS Secret Access Key", "field_type_id": 1}, {"is_secret": false, "field_name": "aws_region", "description": "AWS region (e.g., us-east-1, ap-south-1)", "is_required": true, "display_name": "AWS Region", "default_value": "us-east-1", "field_type_id": 1}]	[{"field_name": "from_email", "description": "Default sender email address", "is_required": false, "display_name": "Default From Email", "field_type_id": 15}, {"field_name": "from_name", "description": "Default sender name", "is_required": false, "display_name": "Default From Name", "field_type_id": 1}]	{"api_docs": "https://docs.aws.amazon.com/ses/", "service_url": "https://aws.amazon.com/ses/"}	t	t	2026-01-15 23:29:03.114175	2026-01-15 23:29:03.114175
2	1a4cca81-3534-42ed-80d4-e49f6035a143	aws_s3	AWS S3	storage	Amazon Simple Storage Service for file and asset storage	\N	[{"is_secret": false, "field_name": "aws_access_key_id", "description": "Your AWS access key ID", "is_required": true, "display_name": "AWS Access Key ID", "field_type_id": 1}, {"is_secret": true, "field_name": "aws_secret_access_key", "description": "Your AWS secret access key", "is_required": true, "display_name": "AWS Secret Access Key", "field_type_id": 1}, {"is_secret": false, "field_name": "bucket_name", "description": "Name of the S3 bucket", "is_required": true, "display_name": "S3 Bucket Name", "field_type_id": 1}, {"is_secret": false, "field_name": "aws_region", "description": "AWS region (e.g., us-east-1, ap-south-1)", "is_required": true, "display_name": "AWS Region", "default_value": "us-east-1", "field_type_id": 1}]	[{"field_name": "bucket_prefix", "description": "Optional prefix/folder path in bucket (e.g., \\"production\\", \\"staging\\"). Assets will be stored under {prefix}/assets/", "is_required": false, "display_name": "Bucket Prefix/Folder", "default_value": "", "field_type_id": 1}, {"field_name": "endpoint_url", "description": "Custom S3 endpoint (for S3-compatible services)", "is_required": false, "display_name": "Custom Endpoint URL", "field_type_id": 17}, {"field_name": "cdn_url", "description": "CDN URL for public asset access", "is_required": false, "display_name": "CDN URL", "field_type_id": 17}]	{"api_docs": "https://docs.aws.amazon.com/s3/", "service_url": "https://aws.amazon.com/s3/"}	t	t	2026-01-15 23:29:03.114175	2026-01-15 23:29:03.114175
3	19ee2db9-fe43-4856-a35a-908613c432ed	aws_sms	AWS SMS (SNS)	sms	Amazon Simple Notification Service for sending SMS messages	\N	[{"is_secret": false, "field_name": "aws_access_key_id", "description": "Your AWS access key ID", "is_required": true, "display_name": "AWS Access Key ID", "field_type_id": 1}, {"is_secret": true, "field_name": "aws_secret_access_key", "description": "Your AWS secret access key", "is_required": true, "display_name": "AWS Secret Access Key", "field_type_id": 1}, {"is_secret": false, "field_name": "aws_region", "description": "AWS region (e.g., us-east-1, ap-south-1)", "is_required": true, "display_name": "AWS Region", "default_value": "us-east-1", "field_type_id": 1}]	[{"field_name": "sender_id", "description": "Default SMS sender ID", "is_required": false, "display_name": "Sender ID", "field_type_id": 1}]	{"api_docs": "https://docs.aws.amazon.com/sns/", "service_url": "https://aws.amazon.com/sns/"}	t	t	2026-01-15 23:29:03.114175	2026-01-15 23:29:03.114175
4	c68bf17d-17d6-43ca-9147-7fe381826e5a	ccavenue	CCAvenue	payment	CCAvenue payment gateway for processing online payments	\N	[{"is_secret": false, "field_name": "merchant_id", "description": "Your CCAvenue merchant ID", "is_required": true, "display_name": "Merchant ID", "field_type_id": 1}, {"is_secret": true, "field_name": "access_code", "description": "Your CCAvenue access code", "is_required": true, "display_name": "Access Code", "field_type_id": 1}, {"is_secret": true, "field_name": "working_key", "description": "Your CCAvenue working key (encryption key)", "is_required": true, "display_name": "Working Key", "field_type_id": 1}]	[{"options": ["test", "production"], "field_name": "environment", "description": "Payment environment: test or production", "is_required": false, "display_name": "Environment", "default_value": "test", "field_type_id": 1}, {"field_name": "currency", "description": "Default currency code (e.g., INR, USD)", "is_required": false, "display_name": "Default Currency", "default_value": "INR", "field_type_id": 1}]	{"api_docs": "https://www.ccavenue.com/supportcenter/knowledgebase", "service_url": "https://www.ccavenue.com/"}	t	t	2026-01-15 23:29:03.114175	2026-01-15 23:29:03.114175
\.


--
-- Data for Name: integrations; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.integrations (integration_id, integration_uuid, company_id, provider_id, provider_name, integration_name, encrypted_credentials, credentials_version, config, integration_type, metadata, is_active, is_default, created_by, last_updated) FROM stdin;
1	ecc260c3-3281-4543-ac5a-aec33e5a34e3	1	2	aws_s3	Default S3 Bucket	+KSUNn9amlUuG51Af4pX08gQmnb4MqUubpTZyZL0WFDJNLH4LqeWqI7nOquSh83y+ucFm+Jwk89rj7ghqT+HaCcnidhMuAdOeT/Z0P4gq0BC9Jtzv2i/T/OcH2wH1Z7xw81P4LuXlhuj70rCg425bB3e4TJswhjEM290ZIfmu7PawajuCVqlrcjOU5yXj9E8ULSBgHPfiH/kjpGYyqEUudPMDtlJP0SJBWIstsfmqGC8NqnimhARAz3CFgmgWoI8bfArz0mAMMeHN7Ac0Y3pqFSIOjDKWdSB2UnFZtN903F7q2m/4j+RzI6vFdQkklwgRCiiSHgLeegMq33Px4X+ZpU//6L+8rAF5gnoCOk=	1	{"region": "us-east-1", "bucket_name": "avkaran", "bucket_prefix": "websites/noolva"}	api	{}	t	t	1	2026-01-15 23:30:07.827518
\.


--
-- Data for Name: job_queue; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.job_queue (job_id, job_uuid, company_id, action_id, related_workflow_id, related_workflow_run_id, status, priority, retry_count, payload, result, started_at, completed_at, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: menu_permissions; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.menu_permissions (menu_permission_id, menu_id, role_id, can_view) FROM stdin;
\.


--
-- Data for Name: menus; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.menus (menu_id, menu_uuid, menu_title, parent_id, type, route_path, icon, module_feature_id, app_id, view_id, scope, is_builtin, order_no, is_hidden, created_by, idate, last_updated) FROM stdin;
1	aed3dcc2-ad20-4918-a0fc-38b00da76b40	Overview	\N	item	/dashboards/overview	dashboard	\N	1	\N	both	t	1	f	\N	2026-01-15 23:29:03.114175	2026-01-15 23:29:03.114175
2	1b84b43b-bf3e-417d-a0b0-8e6e2a1be26a	Dashboard Stats	\N	item	/dashboards/stats	chart-bar	\N	1	\N	both	t	1	f	\N	2026-01-15 23:29:03.114175	2026-01-15 23:29:03.114175
3	bdd8be6a-a45c-4e7f-9bd6-78e81f71b32c	Reports	\N	item	/dashboards/reports	file	\N	1	\N	both	t	2	f	\N	2026-01-15 23:29:03.114175	2026-01-15 23:29:03.114175
8	91c29d00-04c1-464e-8b31-996a51a0b3fc	Companies	\N	item	org_companies	bank	\N	4	\N	saas	t	10	f	1	2026-01-16 01:58:46.119529	2026-01-16 01:58:46.119529
9	3b5ff474-b2be-49ff-96ce-67eec63840fa	App Menus	\N	item	org_app_menus	appstore	\N	4	\N	saas	t	20	f	1	2026-01-16 01:58:46.119529	2026-01-16 01:58:46.119529
10	63260d82-1fa2-420d-b7c6-6f323a0536ba	Users	\N	item	org_users	user	\N	4	\N	saas	t	30	f	1	2026-01-16 01:58:46.119529	2026-01-16 01:58:46.119529
11	576c2036-c1e5-4d63-9755-e8ea2c82caec	User Groups	\N	item	org_user_groups	users	\N	4	\N	saas	t	40	f	1	2026-01-16 01:58:46.119529	2026-01-16 01:58:46.119529
12	c336f401-8128-4a57-a79b-bf34d279a7a0	Teams	\N	item	org_teams	team	\N	4	\N	saas	t	50	f	1	2026-01-16 01:58:46.119529	2026-01-16 01:58:46.119529
13	3de463d1-2061-47d1-9858-5527bbd7047b	Roles	\N	item	org_roles	safety	\N	4	\N	saas	t	60	f	1	2026-01-16 01:58:46.119529	2026-01-16 01:58:46.119529
14	af70b096-cb91-4695-a116-d6413990f519	Permissions	\N	item	org_permissions	key	\N	4	\N	saas	t	70	f	1	2026-01-16 01:58:46.119529	2026-01-16 01:58:46.119529
15	01264678-9044-406e-9936-f13ffd31373d	Settings	\N	item	settings	setting	\N	6	\N	saas	t	80	f	1	2026-01-16 01:58:46.119529	2026-01-16 01:58:46.119529
17	51fed74b-2109-460a-b985-a93f7b70f459	App Store	\N	item	studio_app_store	shop	\N	5	\N	saas	t	10	f	1	2026-01-16 01:58:46.119529	2026-01-16 01:58:46.119529
18	bec8fe34-602b-4035-87e6-6cdb52739cb9	My Apps	\N	item	studio_my_apps	appstore	\N	5	\N	saas	t	20	f	1	2026-01-16 01:58:46.119529	2026-01-16 01:58:46.119529
19	4d796dc5-d5fa-4d14-99ab-5a22206b8ef2	Modules	\N	item	studio_modules	blocks	\N	5	\N	saas	t	30	f	1	2026-01-16 01:58:46.119529	2026-01-16 01:58:46.119529
20	c92aaa56-13ba-42e4-b9ce-cc9dfe7500d9	Features	\N	item	studio_features	star	\N	5	\N	saas	t	40	f	1	2026-01-16 01:58:46.119529	2026-01-16 01:58:46.119529
21	6a9ffc47-290e-4611-8979-09e0636af0b2	Api Endpoints	\N	item	studio_api_endpoints	api	\N	5	\N	saas	t	50	f	1	2026-01-16 01:58:46.119529	2026-01-16 01:58:46.119529
22	63ea863d-ba73-4ff5-a190-99145be2928b	Data Models	\N	item	studio_data_models	database	\N	5	\N	saas	t	60	f	1	2026-01-16 01:58:46.119529	2026-01-16 01:58:46.119529
23	615bcd3f-dc11-4b5f-9a65-edb28b965691	UI Views	\N	item	studio_ui_views	layout	\N	5	\N	saas	t	70	f	1	2026-01-16 01:58:46.119529	2026-01-16 01:58:46.119529
24	72079ecc-07c6-4489-a858-b7cf09a63f05	Jobs/Actions	\N	item	studio_jobs_actions	rocket	\N	5	\N	saas	t	80	f	1	2026-01-16 01:58:46.119529	2026-01-16 01:58:46.119529
25	b991ca66-c8e8-4545-9722-0b7da2da02b3	Integration Manager	\N	item	studio_integrations	link	\N	5	\N	saas	t	90	f	1	2026-01-16 01:58:46.119529	2026-01-16 01:58:46.119529
26	737df92c-67f9-4731-8b4e-bdbc5168f851	Assets	\N	item	studio_assets	picture	\N	5	\N	saas	t	100	f	1	2026-01-16 01:58:46.119529	2026-01-16 01:58:46.119529
27	c8cd1158-1506-4c43-bdfd-f51f1bc8506e	UI Components	\N	item	studio_ui_components	build	\N	5	\N	saas	t	110	f	1	2026-01-16 01:58:46.119529	2026-01-16 01:58:46.119529
29	a0d64f52-7d21-43df-a478-41fe60b9a81b	Database	\N	item	dev_console_database	database	\N	7	\N	saas	t	10	f	1	2026-01-17 01:47:18.959375	2026-01-17 01:47:18.959375
30	7882cf29-fff8-490a-b148-950b9822a109	Db Query	\N	item	dev_console_db_query	code	\N	7	\N	saas	t	20	f	1	2026-01-17 01:47:18.959375	2026-01-17 01:47:18.959375
31	14582847-c4d2-4d4d-b498-76a3e368ff98	Icons	\N	item	studio_icons	star	\N	5	\N	saas	t	120	f	1	2026-01-19 02:12:31.872374	2026-01-19 02:12:31.872374
32	324c81b2-475b-4541-bc07-c5dc411880a2	Collections	\N	item	studio_collections	chart-bar	\N	5	\N	saas	t	65	f	1	2026-01-25 02:23:32.317886	2026-01-25 02:23:32.317886
\.


--
-- Data for Name: model_row_access_policies; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.model_row_access_policies (id, model_id, action_mask, scope_field, scope_source, required, user_override) FROM stdin;
\.


--
-- Data for Name: module_features; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.module_features (module_feature_id, module_feature_uuid, feature_code, feature_name, module_id, cloned_from_feature_id, type, allowed_table_columns, is_builtin, created_by, idate, last_updated) FROM stdin;
\.


--
-- Data for Name: modules; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.modules (module_id, module_uuid, module_code, module_name, app_id, cloned_from_module_id, description, icon, is_builtin, order_no, created_by, idate, last_updated) FROM stdin;
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.products (product_id, created_by, idate, last_updated, test_text, test_paragraph, test_number_int, test_number_float, test_currency, test_percentage, test_rating, test_date, test_date_time, test_time, test_duration, test_yes_no, test_single_choice_collection, test_single_choice_custom_collection, test_multiple_choice, test_multiple_choice_collections, test_autocode, test_email, test_phone, test_website_link, test_password, test_color, test_image, test_file, test_releative_roles, test_rich_text, test_icon) FROM stdin;
\.


--
-- Data for Name: role_module_features; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.role_module_features (role_module_feature_id, role_id, module_feature_id, is_granted, granted_by, granted_at) FROM stdin;
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.roles (role_id, role_uuid, role_name, role_key, role_description, company_id, is_system_role, created_by, idate, last_updated) FROM stdin;
\.


--
-- Data for Name: settings; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.settings (setting_id, group_name, setting_key, setting_name, description, field_type_id, default_value, value, scope, tenant_id, is_built_in, last_updated, field_config_json) FROM stdin;
6	Theme	theme_color_primary	Theme Primary Color	Primary theme color	19	"#1890ff"	"#1890ff"	tenant	1	t	2026-01-16 01:22:24.794563	{}
7	Theme	theme_color_secondary	Theme Secondary Color	Secondary theme color	19	"#52c41a"	"#52c41a"	tenant	1	t	2026-01-16 01:22:24.817748	{}
13	Theme	font_size_small	Small Font Size	Small font size (px)	3	12	12	tenant	1	t	2026-01-16 01:22:24.835425	{}
14	Theme	font_size_large	Large Font Size	Large font size (px)	3	16	16	tenant	1	t	2026-01-16 01:22:24.841247	{}
8	Theme	theme_mode	Theme Mode	light or dark	1	"light"	"dark"	tenant	1	t	2026-01-16 01:22:43.48797	{}
12	Theme	font_size_base	Base Font Size	Global base font size (px)	3	14	15	tenant	1	t	2026-01-16 01:22:43.49149	{}
2	Branding	brand_color	Primary Brand Color	Main accent color	19	"#007bff"	"#007bff"	global	\N	t	2026-01-17 23:27:17.036866	{}
1	General	app_name	Application Name	The visible name of the SaaS platform	1	"Noolva SaaS"	"Noolva SaaS"	global	\N	t	2026-01-17 23:27:29.110978	{}
18	Theme	font_size_base	Base Font Size	Global base font size (px)	3	14	14	global	\N	t	2026-01-17 23:41:06.946161	{"max": 18, "min": 12, "step": 1}
20	Theme	font_size_large	Large Font Size	Large font size (px)	3	16	16	global	\N	t	2026-01-17 23:41:06.967084	{"max": 22, "min": 14, "step": 1}
19	Theme	font_size_small	Small Font Size	Small font size (px)	3	12	12	global	\N	t	2026-01-17 23:41:06.980206	{"max": 16, "min": 10, "step": 1}
15	Theme	theme_color_primary	Theme Primary Color	Primary theme color	19	"#1890ff"	"#1890ff"	global	\N	t	2026-01-17 23:41:07.029356	{"presets": [{"label": "Blue / Green", "primary": "#1890ff", "secondary": "#52c41a"}, {"label": "Purple / Orange", "primary": "#722ed1", "secondary": "#fa8c16"}, {"label": "Teal / Gold", "primary": "#13c2c2", "secondary": "#faad14"}, {"label": "Pink / Gray", "primary": "#eb2f96", "secondary": "#8c8c8c"}]}
4	Security	enable_2fa	Enable 2FA	Allow users to enable Two-Factor Auth	12	false	"false"	global	\N	t	2026-01-16 15:48:33.595872	{}
3	Security	password_min_length	Minimum Password Length	Enforced complexity	3	8	"8"	global	\N	t	2026-01-16 15:48:33.604812	{}
16	Theme	theme_color_secondary	Theme Secondary Color	Secondary theme color	19	"#52c41a"	"#52c41a"	global	\N	t	2026-01-17 23:41:07.044983	{}
5	Theme	theme	Theme	Selected theme key	13	"default"	"default"	global	\N	t	2026-01-17 23:41:07.001398	{"options": [{"label": "Default Corporate", "value": "default"}, {"label": "Slate Corporate", "value": "slate"}]}
17	Theme	theme_mode	Theme Mode	light or dark	13	"light"	"light"	global	\N	t	2026-01-17 23:41:07.016557	{"options": [{"label": "Light", "value": "light"}, {"label": "Dark", "value": "dark"}]}
\.


--
-- Data for Name: teams; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.teams (team_id, team_uuid, team_name, team_description, company_id, parent_team_id, manager_id, created_by, idate, last_updated) FROM stdin;
\.


--
-- Data for Name: tenants; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.tenants (tenant_id, tenant_uuid, tenant_name, contact_email, subscription_plan, subscription_status, subscription_expires_at, is_active, created_by, created_at, last_updated) FROM stdin;
1	6332d07a-ac4a-4749-a6b5-24c63aec2271	Default Tenant	\N	trial	active	\N	t	\N	2026-01-15 23:29:03.114175	2026-01-15 23:29:03.114175
\.


--
-- Data for Name: ui_component_types; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.ui_component_types (component_type_id, type_code, type_name, category, props_schema_json, is_system, created_at) FROM stdin;
1	row	Row	layout	{"align": {"type": "string"}, "gutter": {"type": "number", "default": 24}, "justify": {"type": "string", "options": ["start", "center", "end"]}}	t	2026-01-15 23:29:03.114175
2	column	Column	layout	{"span": {"type": "number", "default": 24}, "offset": {"type": "number"}}	t	2026-01-15 23:29:03.114175
3	divider	Divider	layout	{"orientation": {"type": "string", "default": "horizontal"}}	t	2026-01-15 23:29:03.114175
4	form	Form	container	{"size": {"type": "string"}, "layout": {"type": "string", "options": ["horizontal", "vertical", "inline"]}}	t	2026-01-15 23:29:03.114175
5	card	Card	container	{"title": {"type": "string"}, "bordered": {"type": "boolean"}}	t	2026-01-15 23:29:03.114175
6	text	Text Input	input	{"label": "string", "place_holder": "string", "default_value": "string", "validation_type": "string"}	t	2026-01-15 23:29:03.114175
7	textarea	Text Area	input	{"rows": "number", "label": "string"}	t	2026-01-15 23:29:03.114175
8	number	Number Input	input	{"max": "number", "min": "number", "label": "string"}	t	2026-01-15 23:29:03.114175
9	select	Select Dropdown	input	{"mode": "string", "label": "string", "options": "array"}	t	2026-01-15 23:29:03.114175
10	date	Date Picker	input	{"label": "string", "format": "string"}	t	2026-01-15 23:29:03.114175
11	switch	Switch	input	{"label": "string", "checked_children": "string", "un_checked_children": "string"}	t	2026-01-15 23:29:03.114175
12	checkbox	Checkbox	input	{"label": "string"}	t	2026-01-15 23:29:03.114175
13	radio	Radio Group	input	{"label": "string", "options": "array"}	t	2026-01-15 23:29:03.114175
14	upload	File Upload	input	{"label": "string", "accept": "string", "multiple": "boolean"}	t	2026-01-15 23:29:03.114175
15	label	Label	display	{"strong": "boolean", "default_value": "string"}	t	2026-01-15 23:29:03.114175
16	table	Table	display	{"columns": "array", "pagination": "boolean"}	t	2026-01-15 23:29:03.114175
17	statistic	Statistic	display	{"title": "string", "value": "number", "precision": "number"}	t	2026-01-15 23:29:03.114175
18	tag	Tag	display	{"color": "string"}	t	2026-01-15 23:29:03.114175
19	badge	Badge	display	{"color": "string", "count": "number"}	t	2026-01-15 23:29:03.114175
20	image	Image	display	{"alt": "string", "src": "string", "width": "number"}	t	2026-01-15 23:29:03.114175
21	link	Link	display	{"href": "string", "target": "string"}	t	2026-01-15 23:29:03.114175
22	progress	Progress	display	{"status": "string", "percent": "number"}	t	2026-01-15 23:29:03.114175
\.


--
-- Data for Name: user_account_profiles; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.user_account_profiles (profile_id, profile_uuid, user_id, company_id, profile_name, is_default, preferences, created_at, last_used) FROM stdin;
\.


--
-- Data for Name: user_companies; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.user_companies (user_company_id, user_id, company_id, is_primary, is_active, joined_at) FROM stdin;
\.


--
-- Data for Name: user_group_members; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.user_group_members (member_id, group_id, user_id, added_at) FROM stdin;
\.


--
-- Data for Name: user_groups; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.user_groups (group_id, group_uuid, group_name, group_description, company_id, created_by, idate, last_updated) FROM stdin;
\.


--
-- Data for Name: user_module_features; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.user_module_features (user_module_feature_id, user_id, module_feature_id, is_granted, expiration, granted_by, granted_at) FROM stdin;
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.user_roles (user_role_id, user_id, role_id, company_id, assigned_at, assigned_by) FROM stdin;
\.


--
-- Data for Name: user_sessions; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.user_sessions (session_id, session_uuid, user_id, company_id, login_method, login_at, last_activity, expires_at, device_info, ip_address, user_agent, is_active, created_by) FROM stdin;
1	db9046e2-e181-4b14-9ec4-fde62524699c	2	\N	password	2026-01-15 23:34:31.18892	2026-01-15 23:34:31.18892	2026-01-16 18:04:31.210554	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	f	\N
2	697c78c4-4062-4550-8bf6-b262d8d78df9	2	\N	password	2026-01-16 00:57:20.551386	2026-01-16 00:57:20.551386	2026-01-16 19:27:20.451439	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	f	\N
3	adc04488-bbc7-4b97-a193-1ff626c768d5	2	\N	password	2026-01-16 01:07:34.835405	2026-01-16 01:07:34.835405	2026-01-16 19:37:34.91945	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	f	\N
4	a7d54ddc-320f-48a1-b2d1-2e2be5551dbe	2	\N	password	2026-01-16 01:23:57.039395	2026-01-16 01:23:57.039395	2026-01-16 19:53:56.917564	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	t	\N
5	a37f2701-28e6-48cd-9ecc-d11f89114677	2	\N	password	2026-01-17 01:24:17.728061	2026-01-17 01:24:17.728061	2026-01-17 19:54:17.58963	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	t	\N
6	10e48ac4-7c4a-49b1-9d19-5e0444c11804	2	\N	password	2026-01-17 02:49:50.388368	2026-01-17 02:49:50.388368	2026-01-17 21:19:50.230027	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	t	\N
7	6082cee3-9e12-462f-ab1f-6c43f65fba5d	2	\N	password	2026-01-17 03:27:53.325831	2026-01-17 03:27:53.325831	2026-01-17 21:57:53.280483	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	t	\N
8	c6a4e7b3-713c-4d0b-9e90-8c499f0021f9	2	\N	password	2026-01-17 13:57:38.425488	2026-01-17 13:57:38.425488	2026-01-18 08:27:38.372698	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	t	\N
9	9c09206c-223f-4869-81c0-773a62c71ea3	2	\N	password	2026-01-18 00:03:26.844929	2026-01-18 00:03:26.844929	2026-01-18 18:33:26.801166	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	t	\N
10	419d96f0-9dab-475a-918d-c73043f6a049	2	\N	password	2026-01-19 00:19:01.785218	2026-01-19 00:19:01.785218	2026-01-19 18:49:01.772988	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	t	\N
11	045786c8-d82b-4a22-8cb5-b28d9b98a58f	2	\N	password	2026-01-19 02:00:12.033909	2026-01-19 02:00:12.033909	2026-01-19 20:30:12.035388	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	t	\N
12	5c605c9a-74ae-47b6-a0b3-8ebee7d1d63d	2	\N	password	2026-01-22 00:14:30.33189	2026-01-22 00:14:30.33189	2026-01-22 18:44:30.325714	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	t	\N
13	7be1cac1-2abe-4b66-a0ee-84c81c038892	2	\N	password	2026-01-24 14:14:08.712051	2026-01-24 14:14:08.712051	2026-01-25 08:44:08.707479	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	t	\N
14	bf62d79f-2ac5-468c-bbf7-a053d9ccce3e	2	\N	password	2026-01-25 14:55:55.262441	2026-01-25 14:55:55.262441	2026-01-26 09:25:55.184629	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	t	\N
15	f57775bf-17bd-4d0e-a274-4aa0491d737c	2	\N	password	2026-01-26 19:08:24.335004	2026-01-26 19:08:24.335004	2026-01-27 13:38:24.262839	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	t	\N
16	273d335c-d5ef-4d02-91fa-3af6961cc9cb	2	\N	password	2026-01-30 23:59:22.806743	2026-01-30 23:59:22.806743	2026-01-31 18:29:22.759546	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	t	\N
\.


--
-- Data for Name: user_teams; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.user_teams (user_team_id, team_id, user_id, role_in_team, joined_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.users (user_id, user_uuid, username, password, first_name, last_name, email, phone, avatar_url, user_type, is_super_admin, ref_table_column, ref_id, ref_uuid, active_status, last_login, deleted_at, created_by, idate, last_updated) FROM stdin;
1	ee69037b-55da-444d-91c9-e4bc70362a31	system	system_internal_locked	\N	\N	\N	\N	\N	system	t	\N	\N	\N	1	\N	\N	\N	2026-01-15 23:29:06.137005	2026-01-15 23:29:06.137005
2	93f32e0d-c9ec-42bc-8cdd-651231135a74	admin	$2b$12$g02erZ8PoPNqaQe8BYkcBue44dd6SaKqGXS9wzD9/Vb8CV.Oj52SO	\N	\N	\N	\N	\N	saas_admin	t	\N	\N	\N	1	2026-01-30 23:59:22.875732	\N	\N	2026-01-15 23:29:11.614702	2026-01-15 23:29:11.614702
\.


--
-- Data for Name: workflow_runs; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.workflow_runs (run_id, run_uuid, workflow_id, status, trigger_context_json, started_at, completed_at, error_details) FROM stdin;
\.


--
-- Data for Name: workflows; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.workflows (workflow_id, workflow_uuid, company_id, workflow_name, workflow_code, trigger_config_json, steps_json, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Name: actions_action_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.actions_action_id_seq', 8, true);


--
-- Name: ai_knowledge_relations_relation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.ai_knowledge_relations_relation_id_seq', 3, true);


--
-- Name: api_endpoints_endpoint_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.api_endpoints_endpoint_id_seq', 1, false);


--
-- Name: app_views_app_view_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.app_views_app_view_id_seq', 1, false);


--
-- Name: apps_app_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.apps_app_id_seq', 8, true);


--
-- Name: archival_policies_policy_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.archival_policies_policy_id_seq', 1, false);


--
-- Name: assets_asset_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.assets_asset_id_seq', 2, true);


--
-- Name: audit_logs_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.audit_logs_log_id_seq', 1, false);


--
-- Name: collections_collection_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.collections_collection_id_seq', 1, true);


--
-- Name: companies_company_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.companies_company_id_seq', 1, true);


--
-- Name: data_flattening_rules_rule_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.data_flattening_rules_rule_id_seq', 1, false);


--
-- Name: data_model_fields_field_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.data_model_fields_field_id_seq', 130, true);


--
-- Name: data_models_model_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.data_models_model_id_seq', 14, true);


--
-- Name: field_permissions_field_permission_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.field_permissions_field_permission_id_seq', 1, false);


--
-- Name: field_types_field_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.field_types_field_type_id_seq', 30, true);


--
-- Name: icons_icon_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.icons_icon_id_seq', 605, true);


--
-- Name: integration_providers_provider_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.integration_providers_provider_id_seq', 4, true);


--
-- Name: integrations_integration_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.integrations_integration_id_seq', 1, true);


--
-- Name: job_queue_job_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.job_queue_job_id_seq', 1, false);


--
-- Name: menu_permissions_menu_permission_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.menu_permissions_menu_permission_id_seq', 1, false);


--
-- Name: menus_menu_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.menus_menu_id_seq', 32, true);


--
-- Name: model_row_access_policies_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.model_row_access_policies_id_seq', 1, false);


--
-- Name: module_features_module_feature_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.module_features_module_feature_id_seq', 1, false);


--
-- Name: modules_module_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.modules_module_id_seq', 1, false);


--
-- Name: products_product_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.products_product_id_seq', 1, false);


--
-- Name: role_module_features_role_module_feature_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.role_module_features_role_module_feature_id_seq', 1, false);


--
-- Name: roles_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.roles_role_id_seq', 1, false);


--
-- Name: settings_setting_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.settings_setting_id_seq', 20, true);


--
-- Name: teams_team_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.teams_team_id_seq', 1, false);


--
-- Name: tenants_tenant_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.tenants_tenant_id_seq', 1, true);


--
-- Name: ui_component_types_component_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.ui_component_types_component_type_id_seq', 22, true);


--
-- Name: user_account_profiles_profile_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.user_account_profiles_profile_id_seq', 1, false);


--
-- Name: user_companies_user_company_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.user_companies_user_company_id_seq', 1, false);


--
-- Name: user_group_members_member_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.user_group_members_member_id_seq', 1, false);


--
-- Name: user_groups_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.user_groups_group_id_seq', 1, false);


--
-- Name: user_module_features_user_module_feature_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.user_module_features_user_module_feature_id_seq', 1, false);


--
-- Name: user_roles_user_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.user_roles_user_role_id_seq', 1, false);


--
-- Name: user_sessions_session_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.user_sessions_session_id_seq', 16, true);


--
-- Name: user_teams_user_team_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.user_teams_user_team_id_seq', 1, false);


--
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.users_user_id_seq', 2, true);


--
-- Name: workflow_runs_run_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.workflow_runs_run_id_seq', 1, false);


--
-- Name: workflows_workflow_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.workflows_workflow_id_seq', 1, false);


--
-- Name: actions actions_action_code_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.actions
    ADD CONSTRAINT actions_action_code_key UNIQUE (action_code);


--
-- Name: actions actions_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.actions
    ADD CONSTRAINT actions_pkey PRIMARY KEY (action_id);


--
-- Name: ai_entity_aliases ai_entity_aliases_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.ai_entity_aliases
    ADD CONSTRAINT ai_entity_aliases_pkey PRIMARY KEY (alias);


--
-- Name: ai_events ai_events_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.ai_events
    ADD CONSTRAINT ai_events_pkey PRIMARY KEY (event_id);


--
-- Name: ai_knowledge_nodes ai_knowledge_nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.ai_knowledge_nodes
    ADD CONSTRAINT ai_knowledge_nodes_pkey PRIMARY KEY (node_id);


--
-- Name: ai_knowledge_relations ai_knowledge_relations_from_node_to_node_relation_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.ai_knowledge_relations
    ADD CONSTRAINT ai_knowledge_relations_from_node_to_node_relation_key UNIQUE (from_node, to_node, relation);


--
-- Name: ai_knowledge_relations ai_knowledge_relations_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.ai_knowledge_relations
    ADD CONSTRAINT ai_knowledge_relations_pkey PRIMARY KEY (relation_id);


--
-- Name: ai_knowledge_vectors ai_knowledge_vectors_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.ai_knowledge_vectors
    ADD CONSTRAINT ai_knowledge_vectors_pkey PRIMARY KEY (vector_id);


--
-- Name: ai_query_plans ai_query_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.ai_query_plans
    ADD CONSTRAINT ai_query_plans_pkey PRIMARY KEY (plan_id);


--
-- Name: ai_rules ai_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.ai_rules
    ADD CONSTRAINT ai_rules_pkey PRIMARY KEY (rule_id);


--
-- Name: api_endpoints api_endpoints_endpoint_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.api_endpoints
    ADD CONSTRAINT api_endpoints_endpoint_uuid_key UNIQUE (endpoint_uuid);


--
-- Name: api_endpoints api_endpoints_path_method_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.api_endpoints
    ADD CONSTRAINT api_endpoints_path_method_key UNIQUE (path, method);


--
-- Name: api_endpoints api_endpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.api_endpoints
    ADD CONSTRAINT api_endpoints_pkey PRIMARY KEY (endpoint_id);


--
-- Name: app_views app_views_app_view_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.app_views
    ADD CONSTRAINT app_views_app_view_uuid_key UNIQUE (app_view_uuid);


--
-- Name: app_views app_views_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.app_views
    ADD CONSTRAINT app_views_pkey PRIMARY KEY (app_view_id);


--
-- Name: apps apps_app_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.apps
    ADD CONSTRAINT apps_app_uuid_key UNIQUE (app_uuid);


--
-- Name: apps apps_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.apps
    ADD CONSTRAINT apps_pkey PRIMARY KEY (app_id);


--
-- Name: archival_policies archival_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.archival_policies
    ADD CONSTRAINT archival_policies_pkey PRIMARY KEY (policy_id);


--
-- Name: assets assets_asset_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_asset_uuid_key UNIQUE (asset_uuid);


--
-- Name: assets assets_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_pkey PRIMARY KEY (asset_id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (event_time, log_id);


--
-- Name: audit_logs_default audit_logs_default_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.audit_logs_default
    ADD CONSTRAINT audit_logs_default_pkey PRIMARY KEY (event_time, log_id);


--
-- Name: collections collections_collection_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_collection_uuid_key UNIQUE (collection_uuid);


--
-- Name: collections collections_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_pkey PRIMARY KEY (collection_id);


--
-- Name: collections collections_tenant_id_collection_code_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_tenant_id_collection_code_key UNIQUE (tenant_id, collection_code);


--
-- Name: companies companies_company_code_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_company_code_key UNIQUE (company_code);


--
-- Name: companies companies_company_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_company_uuid_key UNIQUE (company_uuid);


--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (company_id);


--
-- Name: data_flattening_rules data_flattening_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.data_flattening_rules
    ADD CONSTRAINT data_flattening_rules_pkey PRIMARY KEY (rule_id);


--
-- Name: data_flattening_rules data_flattening_rules_rule_code_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.data_flattening_rules
    ADD CONSTRAINT data_flattening_rules_rule_code_key UNIQUE (rule_code);


--
-- Name: data_flattening_rules data_flattening_rules_rule_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.data_flattening_rules
    ADD CONSTRAINT data_flattening_rules_rule_uuid_key UNIQUE (rule_uuid);


--
-- Name: data_model_fields data_model_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.data_model_fields
    ADD CONSTRAINT data_model_fields_pkey PRIMARY KEY (field_id);


--
-- Name: data_models data_models_app_id_model_name_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.data_models
    ADD CONSTRAINT data_models_app_id_model_name_key UNIQUE (app_id, model_name);


--
-- Name: data_models data_models_model_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.data_models
    ADD CONSTRAINT data_models_model_uuid_key UNIQUE (model_uuid);


--
-- Name: data_models data_models_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.data_models
    ADD CONSTRAINT data_models_pkey PRIMARY KEY (model_id);


--
-- Name: field_permissions field_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.field_permissions
    ADD CONSTRAINT field_permissions_pkey PRIMARY KEY (field_permission_id);


--
-- Name: field_permissions field_permissions_role_id_model_id_field_name_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.field_permissions
    ADD CONSTRAINT field_permissions_role_id_model_id_field_name_key UNIQUE (role_id, model_id, field_name);


--
-- Name: field_types field_types_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.field_types
    ADD CONSTRAINT field_types_pkey PRIMARY KEY (field_type_id);


--
-- Name: field_types field_types_type_code_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.field_types
    ADD CONSTRAINT field_types_type_code_key UNIQUE (type_code);


--
-- Name: field_types field_types_type_name_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.field_types
    ADD CONSTRAINT field_types_type_name_key UNIQUE (type_name);


--
-- Name: icons icons_icon_code_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.icons
    ADD CONSTRAINT icons_icon_code_key UNIQUE (icon_code);


--
-- Name: icons icons_icon_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.icons
    ADD CONSTRAINT icons_icon_uuid_key UNIQUE (icon_uuid);


--
-- Name: icons icons_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.icons
    ADD CONSTRAINT icons_pkey PRIMARY KEY (icon_id);


--
-- Name: integration_providers integration_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.integration_providers
    ADD CONSTRAINT integration_providers_pkey PRIMARY KEY (provider_id);


--
-- Name: integration_providers integration_providers_provider_name_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.integration_providers
    ADD CONSTRAINT integration_providers_provider_name_key UNIQUE (provider_name);


--
-- Name: integration_providers integration_providers_provider_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.integration_providers
    ADD CONSTRAINT integration_providers_provider_uuid_key UNIQUE (provider_uuid);


--
-- Name: integrations integrations_integration_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.integrations
    ADD CONSTRAINT integrations_integration_uuid_key UNIQUE (integration_uuid);


--
-- Name: integrations integrations_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.integrations
    ADD CONSTRAINT integrations_pkey PRIMARY KEY (integration_id);


--
-- Name: job_queue job_queue_job_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.job_queue
    ADD CONSTRAINT job_queue_job_uuid_key UNIQUE (job_uuid);


--
-- Name: job_queue job_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.job_queue
    ADD CONSTRAINT job_queue_pkey PRIMARY KEY (job_id);


--
-- Name: menu_permissions menu_permissions_menu_id_role_id_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.menu_permissions
    ADD CONSTRAINT menu_permissions_menu_id_role_id_key UNIQUE (menu_id, role_id);


--
-- Name: menu_permissions menu_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.menu_permissions
    ADD CONSTRAINT menu_permissions_pkey PRIMARY KEY (menu_permission_id);


--
-- Name: menus menus_menu_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT menus_menu_uuid_key UNIQUE (menu_uuid);


--
-- Name: menus menus_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT menus_pkey PRIMARY KEY (menu_id);


--
-- Name: model_row_access_policies model_row_access_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.model_row_access_policies
    ADD CONSTRAINT model_row_access_policies_pkey PRIMARY KEY (id);


--
-- Name: module_features module_features_module_feature_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.module_features
    ADD CONSTRAINT module_features_module_feature_uuid_key UNIQUE (module_feature_uuid);


--
-- Name: module_features module_features_module_id_feature_code_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.module_features
    ADD CONSTRAINT module_features_module_id_feature_code_key UNIQUE (module_id, feature_code);


--
-- Name: module_features module_features_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.module_features
    ADD CONSTRAINT module_features_pkey PRIMARY KEY (module_feature_id);


--
-- Name: modules modules_app_id_module_code_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.modules
    ADD CONSTRAINT modules_app_id_module_code_key UNIQUE (app_id, module_code);


--
-- Name: modules modules_module_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.modules
    ADD CONSTRAINT modules_module_uuid_key UNIQUE (module_uuid);


--
-- Name: modules modules_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.modules
    ADD CONSTRAINT modules_pkey PRIMARY KEY (module_id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (product_id);


--
-- Name: role_module_features role_module_features_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.role_module_features
    ADD CONSTRAINT role_module_features_pkey PRIMARY KEY (role_module_feature_id);


--
-- Name: role_module_features role_module_features_role_id_module_feature_id_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.role_module_features
    ADD CONSTRAINT role_module_features_role_id_module_feature_id_key UNIQUE (role_id, module_feature_id);


--
-- Name: roles roles_company_id_role_key_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_company_id_role_key_key UNIQUE (company_id, role_key);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (role_id);


--
-- Name: roles roles_role_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_role_uuid_key UNIQUE (role_uuid);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (setting_id);


--
-- Name: settings settings_setting_key_tenant_id_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_setting_key_tenant_id_key UNIQUE (setting_key, tenant_id);


--
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (team_id);


--
-- Name: teams teams_team_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_team_uuid_key UNIQUE (team_uuid);


--
-- Name: tenants tenants_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_pkey PRIMARY KEY (tenant_id);


--
-- Name: tenants tenants_tenant_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_tenant_uuid_key UNIQUE (tenant_uuid);


--
-- Name: ui_component_types ui_component_types_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.ui_component_types
    ADD CONSTRAINT ui_component_types_pkey PRIMARY KEY (component_type_id);


--
-- Name: ui_component_types ui_component_types_type_code_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.ui_component_types
    ADD CONSTRAINT ui_component_types_type_code_key UNIQUE (type_code);


--
-- Name: apps unique_app_per_tenant_scope; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.apps
    ADD CONSTRAINT unique_app_per_tenant_scope UNIQUE NULLS NOT DISTINCT (tenant_id, company_id, app_name);


--
-- Name: user_account_profiles user_account_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_account_profiles
    ADD CONSTRAINT user_account_profiles_pkey PRIMARY KEY (profile_id);


--
-- Name: user_account_profiles user_account_profiles_profile_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_account_profiles
    ADD CONSTRAINT user_account_profiles_profile_uuid_key UNIQUE (profile_uuid);


--
-- Name: user_account_profiles user_account_profiles_user_id_company_id_profile_name_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_account_profiles
    ADD CONSTRAINT user_account_profiles_user_id_company_id_profile_name_key UNIQUE (user_id, company_id, profile_name);


--
-- Name: user_companies user_companies_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_companies
    ADD CONSTRAINT user_companies_pkey PRIMARY KEY (user_company_id);


--
-- Name: user_companies user_companies_user_id_company_id_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_companies
    ADD CONSTRAINT user_companies_user_id_company_id_key UNIQUE (user_id, company_id);


--
-- Name: user_group_members user_group_members_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_group_members
    ADD CONSTRAINT user_group_members_pkey PRIMARY KEY (member_id);


--
-- Name: user_groups user_groups_group_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_groups
    ADD CONSTRAINT user_groups_group_uuid_key UNIQUE (group_uuid);


--
-- Name: user_groups user_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_groups
    ADD CONSTRAINT user_groups_pkey PRIMARY KEY (group_id);


--
-- Name: user_module_features user_module_features_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_module_features
    ADD CONSTRAINT user_module_features_pkey PRIMARY KEY (user_module_feature_id);


--
-- Name: user_module_features user_module_features_user_id_module_feature_id_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_module_features
    ADD CONSTRAINT user_module_features_user_id_module_feature_id_key UNIQUE (user_id, module_feature_id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (user_role_id);


--
-- Name: user_sessions user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (session_id);


--
-- Name: user_sessions user_sessions_session_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_session_uuid_key UNIQUE (session_uuid);


--
-- Name: user_teams user_teams_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_teams
    ADD CONSTRAINT user_teams_pkey PRIMARY KEY (user_team_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: users users_user_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_user_uuid_key UNIQUE (user_uuid);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: workflow_runs workflow_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.workflow_runs
    ADD CONSTRAINT workflow_runs_pkey PRIMARY KEY (run_id);


--
-- Name: workflow_runs workflow_runs_run_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.workflow_runs
    ADD CONSTRAINT workflow_runs_run_uuid_key UNIQUE (run_uuid);


--
-- Name: workflows workflows_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.workflows
    ADD CONSTRAINT workflows_pkey PRIMARY KEY (workflow_id);


--
-- Name: workflows workflows_workflow_code_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.workflows
    ADD CONSTRAINT workflows_workflow_code_key UNIQUE (workflow_code);


--
-- Name: workflows workflows_workflow_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.workflows
    ADD CONSTRAINT workflows_workflow_uuid_key UNIQUE (workflow_uuid);


--
-- Name: idx_audit_logs_event_time; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_audit_logs_event_time ON ONLY public.audit_logs USING btree (event_time);


--
-- Name: audit_logs_default_event_time_idx; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX audit_logs_default_event_time_idx ON public.audit_logs_default USING btree (event_time);


--
-- Name: idx_audit_logs_target; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_audit_logs_target ON ONLY public.audit_logs USING btree (target_model, target_record_id);


--
-- Name: audit_logs_default_target_model_target_record_id_idx; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX audit_logs_default_target_model_target_record_id_idx ON public.audit_logs_default USING btree (target_model, target_record_id);


--
-- Name: idx_audit_logs_tenant; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_audit_logs_tenant ON ONLY public.audit_logs USING btree (tenant_id);


--
-- Name: audit_logs_default_tenant_id_idx; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX audit_logs_default_tenant_id_idx ON public.audit_logs_default USING btree (tenant_id);


--
-- Name: idx_ai_events_attributes; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_ai_events_attributes ON public.ai_events USING gin (attributes);


--
-- Name: idx_ai_events_occurred; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_ai_events_occurred ON public.ai_events USING btree (occurred_at DESC) WHERE (is_active = true);


--
-- Name: idx_ai_events_predicate; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_ai_events_predicate ON public.ai_events USING btree (predicate);


--
-- Name: idx_ai_events_subject; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_ai_events_subject ON public.ai_events USING btree (subject);


--
-- Name: idx_ai_nodes_content; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_ai_nodes_content ON public.ai_knowledge_nodes USING gin (content);


--
-- Name: idx_ai_nodes_type; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_ai_nodes_type ON public.ai_knowledge_nodes USING btree (node_type) WHERE (is_active = true);


--
-- Name: idx_ai_query_plans_created; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_ai_query_plans_created ON public.ai_query_plans USING btree (created_at DESC);


--
-- Name: idx_ai_relations_from; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_ai_relations_from ON public.ai_knowledge_relations USING btree (from_node);


--
-- Name: idx_ai_relations_to; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_ai_relations_to ON public.ai_knowledge_relations USING btree (to_node);


--
-- Name: idx_ai_vectors_embedding; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_ai_vectors_embedding ON public.ai_knowledge_vectors USING hnsw (embedding public.vector_cosine_ops);


--
-- Name: idx_api_endpoints_path; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_api_endpoints_path ON public.api_endpoints USING btree (path);


--
-- Name: idx_app_views_model; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_app_views_model ON public.app_views USING btree (model_id);


--
-- Name: idx_apps_company; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_apps_company ON public.apps USING btree (company_id);


--
-- Name: idx_apps_tenant; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_apps_tenant ON public.apps USING btree (tenant_id);


--
-- Name: idx_archival_model; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_archival_model ON public.archival_policies USING btree (model_id);


--
-- Name: idx_assets_company; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_assets_company ON public.assets USING btree (company_id);


--
-- Name: idx_assets_is_public; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_assets_is_public ON public.assets USING btree (is_public);


--
-- Name: idx_assets_storage_provider; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_assets_storage_provider ON public.assets USING btree (storage_provider);


--
-- Name: idx_collections_field_type; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_collections_field_type ON public.collections USING btree (field_type_id);


--
-- Name: idx_companies_tenant; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_companies_tenant ON public.companies USING btree (tenant_id);


--
-- Name: idx_companies_uuid; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_companies_uuid ON public.companies USING btree (company_uuid);


--
-- Name: idx_data_model_fields_model; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_data_model_fields_model ON public.data_model_fields USING btree (model_id);


--
-- Name: idx_data_models_app; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_data_models_app ON public.data_models USING btree (app_id);


--
-- Name: idx_flattening_rules_source; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_flattening_rules_source ON public.data_flattening_rules USING btree (source_model_id);


--
-- Name: idx_groups_company; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_groups_company ON public.user_groups USING btree (company_id);


--
-- Name: idx_icons_active; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_icons_active ON public.icons USING btree (is_active) WHERE (is_active = true);


--
-- Name: idx_icons_category; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_icons_category ON public.icons USING btree (category);


--
-- Name: idx_icons_code; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_icons_code ON public.icons USING btree (icon_code);


--
-- Name: idx_icons_popular; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_icons_popular ON public.icons USING btree (is_popular) WHERE (is_popular = true);


--
-- Name: idx_icons_tags; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_icons_tags ON public.icons USING gin (tags);


--
-- Name: idx_icons_type; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_icons_type ON public.icons USING btree (icon_type);


--
-- Name: idx_integration_providers_category; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_integration_providers_category ON public.integration_providers USING btree (provider_category);


--
-- Name: idx_integration_providers_name; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_integration_providers_name ON public.integration_providers USING btree (provider_name);


--
-- Name: idx_integrations_company; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_integrations_company ON public.integrations USING btree (company_id);


--
-- Name: idx_integrations_default_unique; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE UNIQUE INDEX idx_integrations_default_unique ON public.integrations USING btree (company_id, provider_name) WHERE (is_default = true);


--
-- Name: idx_integrations_provider; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_integrations_provider ON public.integrations USING btree (provider_id);


--
-- Name: idx_integrations_provider_name; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_integrations_provider_name ON public.integrations USING btree (provider_name);


--
-- Name: idx_menus_app; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_menus_app ON public.menus USING btree (app_id);


--
-- Name: idx_model_row_access_policies_model; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_model_row_access_policies_model ON public.model_row_access_policies USING btree (model_id);


--
-- Name: idx_module_features_module; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_module_features_module ON public.module_features USING btree (module_id);


--
-- Name: idx_modules_app; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_modules_app ON public.modules USING btree (app_id);


--
-- Name: idx_role_module_features_role; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_role_module_features_role ON public.role_module_features USING btree (role_id);


--
-- Name: idx_roles_company; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_roles_company ON public.roles USING btree (company_id);


--
-- Name: idx_settings_key; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_settings_key ON public.settings USING btree (setting_key);


--
-- Name: idx_settings_tenant; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_settings_tenant ON public.settings USING btree (tenant_id);


--
-- Name: idx_task_queue_company; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_task_queue_company ON public.job_queue USING btree (company_id);


--
-- Name: idx_task_queue_status; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_task_queue_status ON public.job_queue USING btree (status);


--
-- Name: idx_teams_company; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_teams_company ON public.teams USING btree (company_id);


--
-- Name: idx_tenants_uuid; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_tenants_uuid ON public.tenants USING btree (tenant_uuid);


--
-- Name: idx_user_account_profiles_company; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_user_account_profiles_company ON public.user_account_profiles USING btree (company_id);


--
-- Name: idx_user_account_profiles_default; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_user_account_profiles_default ON public.user_account_profiles USING btree (user_id, is_default) WHERE (is_default = true);


--
-- Name: idx_user_account_profiles_user; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_user_account_profiles_user ON public.user_account_profiles USING btree (user_id);


--
-- Name: idx_user_companies_cid; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_user_companies_cid ON public.user_companies USING btree (company_id);


--
-- Name: idx_user_companies_uid; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_user_companies_uid ON public.user_companies USING btree (user_id);


--
-- Name: idx_user_module_features_user; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_user_module_features_user ON public.user_module_features USING btree (user_id);


--
-- Name: idx_user_roles_user; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_user_roles_user ON public.user_roles USING btree (user_id);


--
-- Name: idx_user_sessions_active; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_user_sessions_active ON public.user_sessions USING btree (is_active);


--
-- Name: idx_user_sessions_company; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_user_sessions_company ON public.user_sessions USING btree (company_id);


--
-- Name: idx_user_sessions_expires; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_user_sessions_expires ON public.user_sessions USING btree (expires_at);


--
-- Name: idx_user_sessions_user; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_user_sessions_user ON public.user_sessions USING btree (user_id);


--
-- Name: idx_users_active_status; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_users_active_status ON public.users USING btree (active_status);


--
-- Name: idx_users_username; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_users_username ON public.users USING btree (username);


--
-- Name: audit_logs_default_event_time_idx; Type: INDEX ATTACH; Schema: public; Owner: noolvan
--

ALTER INDEX public.idx_audit_logs_event_time ATTACH PARTITION public.audit_logs_default_event_time_idx;


--
-- Name: audit_logs_default_pkey; Type: INDEX ATTACH; Schema: public; Owner: noolvan
--

ALTER INDEX public.audit_logs_pkey ATTACH PARTITION public.audit_logs_default_pkey;


--
-- Name: audit_logs_default_target_model_target_record_id_idx; Type: INDEX ATTACH; Schema: public; Owner: noolvan
--

ALTER INDEX public.idx_audit_logs_target ATTACH PARTITION public.audit_logs_default_target_model_target_record_id_idx;


--
-- Name: audit_logs_default_tenant_id_idx; Type: INDEX ATTACH; Schema: public; Owner: noolvan
--

ALTER INDEX public.idx_audit_logs_tenant ATTACH PARTITION public.audit_logs_default_tenant_id_idx;


--
-- Name: ai_entity_aliases ai_entity_aliases_canonical_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.ai_entity_aliases
    ADD CONSTRAINT ai_entity_aliases_canonical_node_id_fkey FOREIGN KEY (canonical_node_id) REFERENCES public.ai_knowledge_nodes(node_id) ON DELETE CASCADE;


--
-- Name: ai_events ai_events_object_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.ai_events
    ADD CONSTRAINT ai_events_object_node_id_fkey FOREIGN KEY (object_node_id) REFERENCES public.ai_knowledge_nodes(node_id) ON DELETE SET NULL;


--
-- Name: ai_events ai_events_subject_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.ai_events
    ADD CONSTRAINT ai_events_subject_node_id_fkey FOREIGN KEY (subject_node_id) REFERENCES public.ai_knowledge_nodes(node_id) ON DELETE SET NULL;


--
-- Name: ai_knowledge_relations ai_knowledge_relations_from_node_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.ai_knowledge_relations
    ADD CONSTRAINT ai_knowledge_relations_from_node_fkey FOREIGN KEY (from_node) REFERENCES public.ai_knowledge_nodes(node_id) ON DELETE CASCADE;


--
-- Name: ai_knowledge_relations ai_knowledge_relations_to_node_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.ai_knowledge_relations
    ADD CONSTRAINT ai_knowledge_relations_to_node_fkey FOREIGN KEY (to_node) REFERENCES public.ai_knowledge_nodes(node_id) ON DELETE CASCADE;


--
-- Name: ai_knowledge_vectors ai_knowledge_vectors_target_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.ai_knowledge_vectors
    ADD CONSTRAINT ai_knowledge_vectors_target_node_id_fkey FOREIGN KEY (target_node_id) REFERENCES public.ai_knowledge_nodes(node_id) ON DELETE CASCADE;


--
-- Name: api_endpoints api_endpoints_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.api_endpoints
    ADD CONSTRAINT api_endpoints_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: api_endpoints api_endpoints_flattening_rule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.api_endpoints
    ADD CONSTRAINT api_endpoints_flattening_rule_id_fkey FOREIGN KEY (flattening_rule_id) REFERENCES public.data_flattening_rules(rule_id) ON DELETE SET NULL;


--
-- Name: api_endpoints api_endpoints_related_model_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.api_endpoints
    ADD CONSTRAINT api_endpoints_related_model_id_fkey FOREIGN KEY (related_model_id) REFERENCES public.data_models(model_id) ON DELETE SET NULL;


--
-- Name: app_views app_views_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.app_views
    ADD CONSTRAINT app_views_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: app_views app_views_model_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.app_views
    ADD CONSTRAINT app_views_model_id_fkey FOREIGN KEY (model_id) REFERENCES public.data_models(model_id) ON DELETE CASCADE;


--
-- Name: apps apps_cloned_from_app_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.apps
    ADD CONSTRAINT apps_cloned_from_app_id_fkey FOREIGN KEY (cloned_from_app_id) REFERENCES public.apps(app_id) ON DELETE SET NULL;


--
-- Name: apps apps_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.apps
    ADD CONSTRAINT apps_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(company_id) ON DELETE SET NULL;


--
-- Name: apps apps_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.apps
    ADD CONSTRAINT apps_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: apps apps_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.apps
    ADD CONSTRAINT apps_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE CASCADE;


--
-- Name: archival_policies archival_policies_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.archival_policies
    ADD CONSTRAINT archival_policies_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: archival_policies archival_policies_model_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.archival_policies
    ADD CONSTRAINT archival_policies_model_id_fkey FOREIGN KEY (model_id) REFERENCES public.data_models(model_id) ON DELETE CASCADE;


--
-- Name: assets assets_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(company_id) ON DELETE CASCADE;


--
-- Name: assets assets_uploaded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.users(user_id);


--
-- Name: collections collections_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: collections collections_field_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_field_type_id_fkey FOREIGN KEY (field_type_id) REFERENCES public.field_types(field_type_id) ON DELETE SET NULL;


--
-- Name: collections collections_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE CASCADE;


--
-- Name: companies companies_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: companies companies_parent_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_parent_company_id_fkey FOREIGN KEY (parent_company_id) REFERENCES public.companies(company_id);


--
-- Name: companies companies_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE CASCADE;


--
-- Name: data_flattening_rules data_flattening_rules_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.data_flattening_rules
    ADD CONSTRAINT data_flattening_rules_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: data_flattening_rules data_flattening_rules_source_model_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.data_flattening_rules
    ADD CONSTRAINT data_flattening_rules_source_model_id_fkey FOREIGN KEY (source_model_id) REFERENCES public.data_models(model_id) ON DELETE CASCADE;


--
-- Name: data_model_fields data_model_fields_field_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.data_model_fields
    ADD CONSTRAINT data_model_fields_field_type_id_fkey FOREIGN KEY (field_type_id) REFERENCES public.field_types(field_type_id);


--
-- Name: data_model_fields data_model_fields_model_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.data_model_fields
    ADD CONSTRAINT data_model_fields_model_id_fkey FOREIGN KEY (model_id) REFERENCES public.data_models(model_id) ON DELETE CASCADE;


--
-- Name: data_models data_models_app_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.data_models
    ADD CONSTRAINT data_models_app_id_fkey FOREIGN KEY (app_id) REFERENCES public.apps(app_id) ON DELETE CASCADE;


--
-- Name: data_models data_models_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.data_models
    ADD CONSTRAINT data_models_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: field_permissions field_permissions_model_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.field_permissions
    ADD CONSTRAINT field_permissions_model_id_fkey FOREIGN KEY (model_id) REFERENCES public.data_models(model_id) ON DELETE CASCADE;


--
-- Name: field_permissions field_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.field_permissions
    ADD CONSTRAINT field_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(role_id) ON DELETE CASCADE;


--
-- Name: field_types field_types_default_component_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.field_types
    ADD CONSTRAINT field_types_default_component_type_id_fkey FOREIGN KEY (default_component_type_id) REFERENCES public.ui_component_types(component_type_id);


--
-- Name: menus fk_menus_view; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT fk_menus_view FOREIGN KEY (view_id) REFERENCES public.app_views(app_view_id) ON DELETE SET NULL;


--
-- Name: icons icons_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.icons
    ADD CONSTRAINT icons_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: integrations integrations_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.integrations
    ADD CONSTRAINT integrations_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(company_id) ON DELETE CASCADE;


--
-- Name: integrations integrations_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.integrations
    ADD CONSTRAINT integrations_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: integrations integrations_provider_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.integrations
    ADD CONSTRAINT integrations_provider_id_fkey FOREIGN KEY (provider_id) REFERENCES public.integration_providers(provider_id) ON DELETE SET NULL;


--
-- Name: job_queue job_queue_action_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.job_queue
    ADD CONSTRAINT job_queue_action_id_fkey FOREIGN KEY (action_id) REFERENCES public.actions(action_id);


--
-- Name: job_queue job_queue_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.job_queue
    ADD CONSTRAINT job_queue_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(company_id) ON DELETE CASCADE;


--
-- Name: job_queue job_queue_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.job_queue
    ADD CONSTRAINT job_queue_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: job_queue job_queue_related_workflow_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.job_queue
    ADD CONSTRAINT job_queue_related_workflow_id_fkey FOREIGN KEY (related_workflow_id) REFERENCES public.workflows(workflow_id) ON DELETE SET NULL;


--
-- Name: job_queue job_queue_related_workflow_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.job_queue
    ADD CONSTRAINT job_queue_related_workflow_run_id_fkey FOREIGN KEY (related_workflow_run_id) REFERENCES public.workflow_runs(run_id) ON DELETE CASCADE;


--
-- Name: menu_permissions menu_permissions_menu_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.menu_permissions
    ADD CONSTRAINT menu_permissions_menu_id_fkey FOREIGN KEY (menu_id) REFERENCES public.menus(menu_id) ON DELETE CASCADE;


--
-- Name: menu_permissions menu_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.menu_permissions
    ADD CONSTRAINT menu_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(role_id) ON DELETE CASCADE;


--
-- Name: menus menus_app_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT menus_app_id_fkey FOREIGN KEY (app_id) REFERENCES public.apps(app_id) ON DELETE CASCADE;


--
-- Name: menus menus_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT menus_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: menus menus_module_feature_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT menus_module_feature_id_fkey FOREIGN KEY (module_feature_id) REFERENCES public.module_features(module_feature_id) ON DELETE SET NULL;


--
-- Name: menus menus_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT menus_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.menus(menu_id) ON DELETE CASCADE;


--
-- Name: model_row_access_policies model_row_access_policies_model_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.model_row_access_policies
    ADD CONSTRAINT model_row_access_policies_model_id_fkey FOREIGN KEY (model_id) REFERENCES public.data_models(model_id) ON DELETE CASCADE;


--
-- Name: module_features module_features_cloned_from_feature_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.module_features
    ADD CONSTRAINT module_features_cloned_from_feature_id_fkey FOREIGN KEY (cloned_from_feature_id) REFERENCES public.module_features(module_feature_id) ON DELETE SET NULL;


--
-- Name: module_features module_features_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.module_features
    ADD CONSTRAINT module_features_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: module_features module_features_module_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.module_features
    ADD CONSTRAINT module_features_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.modules(module_id) ON DELETE CASCADE;


--
-- Name: modules modules_app_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.modules
    ADD CONSTRAINT modules_app_id_fkey FOREIGN KEY (app_id) REFERENCES public.apps(app_id) ON DELETE CASCADE;


--
-- Name: modules modules_cloned_from_module_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.modules
    ADD CONSTRAINT modules_cloned_from_module_id_fkey FOREIGN KEY (cloned_from_module_id) REFERENCES public.modules(module_id) ON DELETE SET NULL;


--
-- Name: modules modules_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.modules
    ADD CONSTRAINT modules_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: products products_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: role_module_features role_module_features_granted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.role_module_features
    ADD CONSTRAINT role_module_features_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES public.users(user_id);


--
-- Name: role_module_features role_module_features_module_feature_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.role_module_features
    ADD CONSTRAINT role_module_features_module_feature_id_fkey FOREIGN KEY (module_feature_id) REFERENCES public.module_features(module_feature_id) ON DELETE CASCADE;


--
-- Name: role_module_features role_module_features_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.role_module_features
    ADD CONSTRAINT role_module_features_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(role_id) ON DELETE CASCADE;


--
-- Name: roles roles_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(company_id) ON DELETE CASCADE;


--
-- Name: roles roles_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: settings settings_field_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_field_type_id_fkey FOREIGN KEY (field_type_id) REFERENCES public.field_types(field_type_id);


--
-- Name: settings settings_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE CASCADE;


--
-- Name: teams teams_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(company_id) ON DELETE CASCADE;


--
-- Name: teams teams_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: teams teams_manager_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_manager_id_fkey FOREIGN KEY (manager_id) REFERENCES public.users(user_id);


--
-- Name: teams teams_parent_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_parent_team_id_fkey FOREIGN KEY (parent_team_id) REFERENCES public.teams(team_id);


--
-- Name: tenants tenants_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: user_account_profiles user_account_profiles_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_account_profiles
    ADD CONSTRAINT user_account_profiles_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(company_id) ON DELETE CASCADE;


--
-- Name: user_account_profiles user_account_profiles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_account_profiles
    ADD CONSTRAINT user_account_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: user_companies user_companies_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_companies
    ADD CONSTRAINT user_companies_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(company_id) ON DELETE CASCADE;


--
-- Name: user_companies user_companies_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_companies
    ADD CONSTRAINT user_companies_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: user_group_members user_group_members_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_group_members
    ADD CONSTRAINT user_group_members_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.user_groups(group_id) ON DELETE CASCADE;


--
-- Name: user_group_members user_group_members_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_group_members
    ADD CONSTRAINT user_group_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: user_groups user_groups_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_groups
    ADD CONSTRAINT user_groups_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(company_id) ON DELETE CASCADE;


--
-- Name: user_groups user_groups_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_groups
    ADD CONSTRAINT user_groups_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: user_module_features user_module_features_granted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_module_features
    ADD CONSTRAINT user_module_features_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES public.users(user_id);


--
-- Name: user_module_features user_module_features_module_feature_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_module_features
    ADD CONSTRAINT user_module_features_module_feature_id_fkey FOREIGN KEY (module_feature_id) REFERENCES public.module_features(module_feature_id) ON DELETE CASCADE;


--
-- Name: user_module_features user_module_features_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_module_features
    ADD CONSTRAINT user_module_features_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: user_roles user_roles_assigned_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES public.users(user_id);


--
-- Name: user_roles user_roles_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(company_id) ON DELETE CASCADE;


--
-- Name: user_roles user_roles_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(role_id) ON DELETE CASCADE;


--
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: user_sessions user_sessions_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(company_id) ON DELETE CASCADE;


--
-- Name: user_sessions user_sessions_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: user_sessions user_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: user_teams user_teams_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_teams
    ADD CONSTRAINT user_teams_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(team_id) ON DELETE CASCADE;


--
-- Name: user_teams user_teams_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_teams
    ADD CONSTRAINT user_teams_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: users users_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: workflow_runs workflow_runs_workflow_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.workflow_runs
    ADD CONSTRAINT workflow_runs_workflow_id_fkey FOREIGN KEY (workflow_id) REFERENCES public.workflows(workflow_id) ON DELETE CASCADE;


--
-- Name: workflows workflows_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.workflows
    ADD CONSTRAINT workflows_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(company_id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict VUs42J7fdEDfsffiwSCZaYgRX2DOJmN1zXvloBScbegCjgLKnQ95Zc0KEmR5YZq

