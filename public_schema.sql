--
-- PostgreSQL database dump
--

\restrict vFTiYNhj3apxKkhz3NJ01f03gJIuKNnMAqXzso3ITYboCwMnb49Kpr3zggodNMx

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
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


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
    occurred_at timestamp with time zone NOT NULL,
    recorded_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
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
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
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
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
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
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
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
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
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
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.ai_rules OWNER TO noolvan;

--
-- Name: alarm_sounds; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.alarm_sounds (
    sound_id integer NOT NULL,
    created_by integer,
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    alarm_file_path character varying(255),
    sound_title character varying(100),
    is_default boolean
);


ALTER TABLE public.alarm_sounds OWNER TO noolvan;

--
-- Name: alarm_sounds_sound_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.alarm_sounds_sound_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.alarm_sounds_sound_id_seq OWNER TO noolvan;

--
-- Name: alarm_sounds_sound_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.alarm_sounds_sound_id_seq OWNED BY public.alarm_sounds.sound_id;


--
-- Name: alarms; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.alarms (
    alarm_id integer NOT NULL,
    created_by integer,
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    entity_type character varying(50),
    alarm_mode character varying(255) DEFAULT 'time_based'::character varying NOT NULL,
    scheduled_for timestamp with time zone,
    condition_json jsonb,
    title character varying(255),
    message text,
    status character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    acknowledged_at timestamp with time zone,
    entity_id numeric
);


ALTER TABLE public.alarms OWNER TO noolvan;

--
-- Name: alarms_alarm_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.alarms_alarm_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.alarms_alarm_id_seq OWNER TO noolvan;

--
-- Name: alarms_alarm_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.alarms_alarm_id_seq OWNED BY public.alarms.alarm_id;


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
    permission_required character varying(100),
    is_builtin boolean DEFAULT false,
    created_by integer,
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    reference_model_ids integer[] DEFAULT '{}'::integer[],
    custom_json jsonb DEFAULT '{}'::jsonb
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
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP
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
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
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
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP
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
    uploaded_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
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
-- Name: business_addresses; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.business_addresses (
    address_id integer NOT NULL,
    created_by integer,
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    business_id integer NOT NULL,
    address_type character varying(255) DEFAULT 'head_office'::character varying NOT NULL,
    address_line1 character varying(255) NOT NULL,
    address_line2 character varying(255),
    postal_code character varying(20) NOT NULL,
    is_primary boolean DEFAULT false,
    map_location point,
    location integer
);


ALTER TABLE public.business_addresses OWNER TO noolvan;

--
-- Name: business_addresses_address_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.business_addresses_address_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.business_addresses_address_id_seq OWNER TO noolvan;

--
-- Name: business_addresses_address_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.business_addresses_address_id_seq OWNED BY public.business_addresses.address_id;


--
-- Name: business_contacts; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.business_contacts (
    contact_id integer NOT NULL,
    created_by integer,
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    business_id integer NOT NULL,
    contact_type character varying(255) NOT NULL,
    contact_value character varying(255) NOT NULL,
    label character varying(255) DEFAULT 'work'::character varying,
    is_primary boolean DEFAULT false,
    is_verified boolean DEFAULT false,
    verified_at timestamp with time zone,
    notes text
);


ALTER TABLE public.business_contacts OWNER TO noolvan;

--
-- Name: business_contacts_contact_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.business_contacts_contact_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.business_contacts_contact_id_seq OWNER TO noolvan;

--
-- Name: business_contacts_contact_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.business_contacts_contact_id_seq OWNED BY public.business_contacts.contact_id;


--
-- Name: businesses; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.businesses (
    business_id integer NOT NULL,
    created_by integer,
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    name character varying(100),
    legal_name character varying(100),
    industry character varying(100),
    website character varying(255),
    is_active boolean,
    gst_number character varying(100),
    notes text
);


ALTER TABLE public.businesses OWNER TO noolvan;

--
-- Name: businesses_business_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.businesses_business_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.businesses_business_id_seq OWNER TO noolvan;

--
-- Name: businesses_business_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.businesses_business_id_seq OWNED BY public.businesses.business_id;


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
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
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
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
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
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP
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
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP
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
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
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
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
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
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
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
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP
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
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP
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
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    created_by integer,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
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
-- Name: locations; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.locations (
    location_id integer NOT NULL,
    created_by integer,
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    city character varying(150) NOT NULL,
    state character varying(150) NOT NULL,
    country character varying(150) NOT NULL,
    display_name character varying(300) NOT NULL,
    is_active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.locations OWNER TO noolvan;

--
-- Name: locations_location_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.locations_location_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.locations_location_id_seq OWNER TO noolvan;

--
-- Name: locations_location_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.locations_location_id_seq OWNED BY public.locations.location_id;


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
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
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
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
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
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
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
-- Name: my_projects; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.my_projects (
    project_id integer NOT NULL,
    created_by integer,
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    task_category_id integer,
    project_name character varying(200) NOT NULL,
    description text,
    status character varying(255) DEFAULT 'planned'::character varying,
    start_date date,
    end_date date,
    created_at timestamp with time zone DEFAULT '2026-02-14 22:26:10.746709+00'::timestamp with time zone,
    is_active boolean DEFAULT true
);


ALTER TABLE public.my_projects OWNER TO noolvan;

--
-- Name: my_projects_project_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.my_projects_project_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.my_projects_project_id_seq OWNER TO noolvan;

--
-- Name: my_projects_project_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.my_projects_project_id_seq OWNED BY public.my_projects.project_id;


--
-- Name: my_tasks; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.my_tasks (
    task_id integer NOT NULL,
    created_by integer,
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    task_category_id integer,
    project_id integer,
    sprint_id integer,
    title character varying(300) NOT NULL,
    description text,
    priority character varying(255) DEFAULT 'medium'::character varying,
    status character varying(255) DEFAULT 'inbox'::character varying,
    due_date date,
    scheduled_at timestamp with time zone,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    recurrence_type character varying(255),
    recurrence_interval numeric DEFAULT '1'::numeric,
    recurrence_days text[],
    estimated_time numeric,
    timebox numeric,
    actual_time numeric,
    assigned_to integer,
    task_uuid uuid DEFAULT gen_random_uuid(),
    alarm_id integer,
    person_id integer,
    business_id integer
);


ALTER TABLE public.my_tasks OWNER TO noolvan;

--
-- Name: my_tasks_task_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.my_tasks_task_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.my_tasks_task_id_seq OWNER TO noolvan;

--
-- Name: my_tasks_task_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.my_tasks_task_id_seq OWNED BY public.my_tasks.task_id;


--
-- Name: password_vault; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.password_vault (
    id integer NOT NULL,
    service_name character varying(200),
    category character varying(50),
    username_or_email character varying(200),
    password character varying(500),
    website_or_app_url character varying(500),
    login_handler_function character varying(200),
    recovery_info text,
    notes text,
    additional_secrets jsonb,
    service_uuid uuid DEFAULT gen_random_uuid()
);


ALTER TABLE public.password_vault OWNER TO noolvan;

--
-- Name: password_vault_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.password_vault_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.password_vault_id_seq OWNER TO noolvan;

--
-- Name: password_vault_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.password_vault_id_seq OWNED BY public.password_vault.id;


--
-- Name: person_addresses; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.person_addresses (
    address_id integer NOT NULL,
    created_by integer,
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    person_id integer NOT NULL,
    address_type character varying(255) DEFAULT 'home'::character varying NOT NULL,
    address_line1 character varying(255) NOT NULL,
    address_line2 character varying(255),
    postal_code character varying(20) NOT NULL,
    is_primary boolean DEFAULT false,
    map_location point,
    location integer
);


ALTER TABLE public.person_addresses OWNER TO noolvan;

--
-- Name: person_addresses_address_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.person_addresses_address_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.person_addresses_address_id_seq OWNER TO noolvan;

--
-- Name: person_addresses_address_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.person_addresses_address_id_seq OWNED BY public.person_addresses.address_id;


--
-- Name: person_attachments; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.person_attachments (
    attachment_id integer NOT NULL,
    created_by integer,
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    person_id integer NOT NULL,
    attachment_type character varying(255) DEFAULT 'document'::character varying NOT NULL,
    file_name character varying(255) NOT NULL,
    file character varying(255) NOT NULL,
    file_size numeric,
    mime_type character varying(100),
    description text,
    is_private boolean DEFAULT true,
    expiry_date date
);


ALTER TABLE public.person_attachments OWNER TO noolvan;

--
-- Name: person_attachments_attachment_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.person_attachments_attachment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.person_attachments_attachment_id_seq OWNER TO noolvan;

--
-- Name: person_attachments_attachment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.person_attachments_attachment_id_seq OWNED BY public.person_attachments.attachment_id;


--
-- Name: person_business_roles; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.person_business_roles (
    role_id integer NOT NULL,
    created_by integer,
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    person_id integer NOT NULL,
    business_id integer NOT NULL,
    role character varying(255) NOT NULL,
    from_date date NOT NULL,
    to_date date,
    is_active boolean DEFAULT true,
    ownership_percentage numeric,
    notes text
);


ALTER TABLE public.person_business_roles OWNER TO noolvan;

--
-- Name: person_business_roles_role_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.person_business_roles_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.person_business_roles_role_id_seq OWNER TO noolvan;

--
-- Name: person_business_roles_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.person_business_roles_role_id_seq OWNED BY public.person_business_roles.role_id;


--
-- Name: person_contacts; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.person_contacts (
    contact_id integer NOT NULL,
    created_by integer,
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    person_id integer NOT NULL,
    contact_type character varying(255) NOT NULL,
    contact_value character varying(255) NOT NULL,
    label character varying(255) DEFAULT 'personal'::character varying,
    is_primary boolean DEFAULT false,
    is_verified boolean DEFAULT false,
    verified_at timestamp with time zone,
    notes text
);


ALTER TABLE public.person_contacts OWNER TO noolvan;

--
-- Name: person_contacts_contact_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.person_contacts_contact_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.person_contacts_contact_id_seq OWNER TO noolvan;

--
-- Name: person_contacts_contact_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.person_contacts_contact_id_seq OWNED BY public.person_contacts.contact_id;


--
-- Name: person_relationships; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.person_relationships (
    relationship_id integer NOT NULL,
    created_by integer,
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    person_id integer NOT NULL,
    related_person_id integer NOT NULL,
    relation_type character varying(255) NOT NULL,
    notes text
);


ALTER TABLE public.person_relationships OWNER TO noolvan;

--
-- Name: person_relationships_relationship_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.person_relationships_relationship_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.person_relationships_relationship_id_seq OWNER TO noolvan;

--
-- Name: person_relationships_relationship_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.person_relationships_relationship_id_seq OWNED BY public.person_relationships.relationship_id;


--
-- Name: personal_access_tokens; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.personal_access_tokens (
    pat_id integer NOT NULL,
    pat_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id integer NOT NULL,
    company_id integer,
    name character varying(200) NOT NULL,
    token_hash character varying(64) NOT NULL,
    scopes_json jsonb DEFAULT '[]'::jsonb,
    expires_at timestamp with time zone NOT NULL,
    last_used_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.personal_access_tokens OWNER TO noolvan;

--
-- Name: personal_access_tokens_pat_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.personal_access_tokens_pat_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.personal_access_tokens_pat_id_seq OWNER TO noolvan;

--
-- Name: personal_access_tokens_pat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.personal_access_tokens_pat_id_seq OWNED BY public.personal_access_tokens.pat_id;


--
-- Name: persons; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.persons (
    person_id integer NOT NULL,
    created_by integer,
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    name character varying(100),
    alias_names text,
    profile_photo character varying(255),
    dob date,
    marital_status character varying(255),
    anniversary_date date,
    notes text,
    person_uuid uuid DEFAULT gen_random_uuid()
);


ALTER TABLE public.persons OWNER TO noolvan;

--
-- Name: persons_person_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.persons_person_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.persons_person_id_seq OWNER TO noolvan;

--
-- Name: persons_person_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.persons_person_id_seq OWNED BY public.persons.person_id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.products (
    product_id integer NOT NULL,
    created_by integer,
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    test_text character varying(100) NOT NULL,
    test_paragraph text,
    test_number_int text,
    test_number_float numeric NOT NULL,
    test_currency numeric,
    test_percentage numeric,
    test_rating integer,
    test_date date,
    test_date_time timestamp with time zone,
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
    granted_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
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
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
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
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
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
-- Name: task_attachments; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.task_attachments (
    attachment_id integer NOT NULL,
    created_by integer,
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    attachment_uuid uuid DEFAULT gen_random_uuid(),
    attachment_title character varying(100),
    file_path character varying(255),
    task integer
);


ALTER TABLE public.task_attachments OWNER TO noolvan;

--
-- Name: task_attachments_attachment_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.task_attachments_attachment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.task_attachments_attachment_id_seq OWNER TO noolvan;

--
-- Name: task_attachments_attachment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.task_attachments_attachment_id_seq OWNED BY public.task_attachments.attachment_id;


--
-- Name: task_categories; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.task_categories (
    task_category_id integer NOT NULL,
    created_by integer,
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    name character varying(100),
    description text,
    task_type character varying(100),
    color character varying(100),
    icon character varying(100),
    is_active boolean,
    order_no numeric
);


ALTER TABLE public.task_categories OWNER TO noolvan;

--
-- Name: task_categories_task_category_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.task_categories_task_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.task_categories_task_category_id_seq OWNER TO noolvan;

--
-- Name: task_categories_task_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.task_categories_task_category_id_seq OWNED BY public.task_categories.task_category_id;


--
-- Name: task_comments; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.task_comments (
    comment_id integer NOT NULL,
    created_by integer,
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    task integer,
    message text,
    comment_title character varying(100)
);


ALTER TABLE public.task_comments OWNER TO noolvan;

--
-- Name: task_comments_comment_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.task_comments_comment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.task_comments_comment_id_seq OWNER TO noolvan;

--
-- Name: task_comments_comment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.task_comments_comment_id_seq OWNED BY public.task_comments.comment_id;


--
-- Name: task_priorities; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.task_priorities (
    priority_id integer NOT NULL,
    created_by integer,
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    name character varying(50) NOT NULL,
    weight numeric NOT NULL,
    importance boolean DEFAULT false NOT NULL,
    urgency boolean DEFAULT false NOT NULL,
    is_mandatory boolean DEFAULT false NOT NULL,
    is_ignorable boolean DEFAULT false NOT NULL,
    is_delegatable boolean DEFAULT false NOT NULL,
    regret_level numeric DEFAULT '0'::numeric NOT NULL
);


ALTER TABLE public.task_priorities OWNER TO noolvan;

--
-- Name: task_priorities_priority_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.task_priorities_priority_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.task_priorities_priority_id_seq OWNER TO noolvan;

--
-- Name: task_priorities_priority_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.task_priorities_priority_id_seq OWNED BY public.task_priorities.priority_id;


--
-- Name: task_sprints; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.task_sprints (
    sprint_id integer NOT NULL,
    created_by integer,
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    sprint_name character varying(150) NOT NULL,
    description text,
    goal text,
    start_date date,
    end_date date,
    status character varying(255) DEFAULT 'planned'::character varying,
    completed_at timestamp with time zone,
    is_active boolean DEFAULT true
);


ALTER TABLE public.task_sprints OWNER TO noolvan;

--
-- Name: task_sprints_sprint_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.task_sprints_sprint_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.task_sprints_sprint_id_seq OWNER TO noolvan;

--
-- Name: task_sprints_sprint_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.task_sprints_sprint_id_seq OWNED BY public.task_sprints.sprint_id;


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
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
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
    subscription_expires_at timestamp with time zone,
    is_active boolean DEFAULT true,
    created_by integer,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
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
-- Name: themes; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.themes (
    theme_id integer NOT NULL,
    theme_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    theme_name character varying(100) NOT NULL,
    theme_key character varying(100) NOT NULL,
    theme_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    user_id integer,
    scope character varying(20) DEFAULT 'saas'::character varying NOT NULL,
    tenant_id integer,
    is_builtin boolean DEFAULT false,
    is_default boolean DEFAULT false,
    created_by integer,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT themes_scope_check CHECK (((scope)::text = ANY ((ARRAY['saas'::character varying, 'tenant'::character varying])::text[])))
);


ALTER TABLE public.themes OWNER TO noolvan;

--
-- Name: themes_theme_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.themes_theme_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.themes_theme_id_seq OWNER TO noolvan;

--
-- Name: themes_theme_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.themes_theme_id_seq OWNED BY public.themes.theme_id;


--
-- Name: time_slots; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.time_slots (
    time_id integer NOT NULL,
    created_by integer,
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    slot_uuid uuid DEFAULT gen_random_uuid(),
    name character varying(150) NOT NULL,
    slot_type character varying(255),
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    applies_type character varying(255),
    applies_value character varying(20),
    priority_level numeric DEFAULT '1'::numeric,
    description text
);


ALTER TABLE public.time_slots OWNER TO noolvan;

--
-- Name: time_slots_time_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.time_slots_time_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.time_slots_time_id_seq OWNER TO noolvan;

--
-- Name: time_slots_time_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.time_slots_time_id_seq OWNED BY public.time_slots.time_id;


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
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
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
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    last_used timestamp with time zone DEFAULT CURRENT_TIMESTAMP
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
    joined_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
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
    added_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
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
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
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
    expiration timestamp with time zone,
    granted_by integer,
    granted_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
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
    assigned_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
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
    login_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    last_activity timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    expires_at timestamp with time zone,
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
    joined_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
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
    last_login timestamp with time zone,
    deleted_at timestamp with time zone,
    created_by integer,
    idate timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    enable_2fa boolean DEFAULT false,
    mfa_secret character varying(255),
    idle_timeout_minutes integer,
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
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
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
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
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
-- Name: alarm_sounds sound_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.alarm_sounds ALTER COLUMN sound_id SET DEFAULT nextval('public.alarm_sounds_sound_id_seq'::regclass);


--
-- Name: alarms alarm_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.alarms ALTER COLUMN alarm_id SET DEFAULT nextval('public.alarms_alarm_id_seq'::regclass);


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
-- Name: business_addresses address_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.business_addresses ALTER COLUMN address_id SET DEFAULT nextval('public.business_addresses_address_id_seq'::regclass);


--
-- Name: business_contacts contact_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.business_contacts ALTER COLUMN contact_id SET DEFAULT nextval('public.business_contacts_contact_id_seq'::regclass);


--
-- Name: businesses business_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.businesses ALTER COLUMN business_id SET DEFAULT nextval('public.businesses_business_id_seq'::regclass);


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
-- Name: locations location_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.locations ALTER COLUMN location_id SET DEFAULT nextval('public.locations_location_id_seq'::regclass);


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
-- Name: my_projects project_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.my_projects ALTER COLUMN project_id SET DEFAULT nextval('public.my_projects_project_id_seq'::regclass);


--
-- Name: my_tasks task_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.my_tasks ALTER COLUMN task_id SET DEFAULT nextval('public.my_tasks_task_id_seq'::regclass);


--
-- Name: password_vault id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.password_vault ALTER COLUMN id SET DEFAULT nextval('public.password_vault_id_seq'::regclass);


--
-- Name: person_addresses address_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_addresses ALTER COLUMN address_id SET DEFAULT nextval('public.person_addresses_address_id_seq'::regclass);


--
-- Name: person_attachments attachment_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_attachments ALTER COLUMN attachment_id SET DEFAULT nextval('public.person_attachments_attachment_id_seq'::regclass);


--
-- Name: person_business_roles role_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_business_roles ALTER COLUMN role_id SET DEFAULT nextval('public.person_business_roles_role_id_seq'::regclass);


--
-- Name: person_contacts contact_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_contacts ALTER COLUMN contact_id SET DEFAULT nextval('public.person_contacts_contact_id_seq'::regclass);


--
-- Name: person_relationships relationship_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_relationships ALTER COLUMN relationship_id SET DEFAULT nextval('public.person_relationships_relationship_id_seq'::regclass);


--
-- Name: personal_access_tokens pat_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.personal_access_tokens ALTER COLUMN pat_id SET DEFAULT nextval('public.personal_access_tokens_pat_id_seq'::regclass);


--
-- Name: persons person_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.persons ALTER COLUMN person_id SET DEFAULT nextval('public.persons_person_id_seq'::regclass);


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
-- Name: task_attachments attachment_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_attachments ALTER COLUMN attachment_id SET DEFAULT nextval('public.task_attachments_attachment_id_seq'::regclass);


--
-- Name: task_categories task_category_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_categories ALTER COLUMN task_category_id SET DEFAULT nextval('public.task_categories_task_category_id_seq'::regclass);


--
-- Name: task_comments comment_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_comments ALTER COLUMN comment_id SET DEFAULT nextval('public.task_comments_comment_id_seq'::regclass);


--
-- Name: task_priorities priority_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_priorities ALTER COLUMN priority_id SET DEFAULT nextval('public.task_priorities_priority_id_seq'::regclass);


--
-- Name: task_sprints sprint_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_sprints ALTER COLUMN sprint_id SET DEFAULT nextval('public.task_sprints_sprint_id_seq'::regclass);


--
-- Name: teams team_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.teams ALTER COLUMN team_id SET DEFAULT nextval('public.teams_team_id_seq'::regclass);


--
-- Name: tenants tenant_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.tenants ALTER COLUMN tenant_id SET DEFAULT nextval('public.tenants_tenant_id_seq'::regclass);


--
-- Name: themes theme_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.themes ALTER COLUMN theme_id SET DEFAULT nextval('public.themes_theme_id_seq'::regclass);


--
-- Name: time_slots time_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.time_slots ALTER COLUMN time_id SET DEFAULT nextval('public.time_slots_time_id_seq'::regclass);


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
-- Name: alarm_sounds alarm_sounds_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.alarm_sounds
    ADD CONSTRAINT alarm_sounds_pkey PRIMARY KEY (sound_id);


--
-- Name: alarms alarms_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.alarms
    ADD CONSTRAINT alarms_pkey PRIMARY KEY (alarm_id);


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
-- Name: business_addresses business_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.business_addresses
    ADD CONSTRAINT business_addresses_pkey PRIMARY KEY (address_id);


--
-- Name: business_contacts business_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.business_contacts
    ADD CONSTRAINT business_contacts_pkey PRIMARY KEY (contact_id);


--
-- Name: businesses businesses_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.businesses
    ADD CONSTRAINT businesses_pkey PRIMARY KEY (business_id);


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
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (location_id);


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
-- Name: my_projects my_projects_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.my_projects
    ADD CONSTRAINT my_projects_pkey PRIMARY KEY (project_id);


--
-- Name: my_tasks my_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.my_tasks
    ADD CONSTRAINT my_tasks_pkey PRIMARY KEY (task_id);


--
-- Name: password_vault password_vault_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.password_vault
    ADD CONSTRAINT password_vault_pkey PRIMARY KEY (id);


--
-- Name: person_addresses person_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_addresses
    ADD CONSTRAINT person_addresses_pkey PRIMARY KEY (address_id);


--
-- Name: person_attachments person_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_attachments
    ADD CONSTRAINT person_attachments_pkey PRIMARY KEY (attachment_id);


--
-- Name: person_business_roles person_business_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_business_roles
    ADD CONSTRAINT person_business_roles_pkey PRIMARY KEY (role_id);


--
-- Name: person_contacts person_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_contacts
    ADD CONSTRAINT person_contacts_pkey PRIMARY KEY (contact_id);


--
-- Name: person_relationships person_relationships_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_relationships
    ADD CONSTRAINT person_relationships_pkey PRIMARY KEY (relationship_id);


--
-- Name: personal_access_tokens personal_access_tokens_pat_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_pat_uuid_key UNIQUE (pat_uuid);


--
-- Name: personal_access_tokens personal_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_pkey PRIMARY KEY (pat_id);


--
-- Name: personal_access_tokens personal_access_tokens_token_hash_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_token_hash_key UNIQUE (token_hash);


--
-- Name: persons persons_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.persons
    ADD CONSTRAINT persons_pkey PRIMARY KEY (person_id);


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
-- Name: task_attachments task_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_attachments
    ADD CONSTRAINT task_attachments_pkey PRIMARY KEY (attachment_id);


--
-- Name: task_categories task_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_categories
    ADD CONSTRAINT task_categories_pkey PRIMARY KEY (task_category_id);


--
-- Name: task_comments task_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_comments
    ADD CONSTRAINT task_comments_pkey PRIMARY KEY (comment_id);


--
-- Name: task_priorities task_priorities_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_priorities
    ADD CONSTRAINT task_priorities_pkey PRIMARY KEY (priority_id);


--
-- Name: task_sprints task_sprints_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_sprints
    ADD CONSTRAINT task_sprints_pkey PRIMARY KEY (sprint_id);


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
-- Name: themes themes_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.themes
    ADD CONSTRAINT themes_pkey PRIMARY KEY (theme_id);


--
-- Name: themes themes_theme_uuid_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.themes
    ADD CONSTRAINT themes_theme_uuid_key UNIQUE (theme_uuid);


--
-- Name: time_slots time_slots_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.time_slots
    ADD CONSTRAINT time_slots_pkey PRIMARY KEY (time_id);


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
-- Name: idx_personal_access_tokens_expires; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_personal_access_tokens_expires ON public.personal_access_tokens USING btree (expires_at);


--
-- Name: idx_personal_access_tokens_token_hash; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_personal_access_tokens_token_hash ON public.personal_access_tokens USING btree (token_hash);


--
-- Name: idx_personal_access_tokens_user; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_personal_access_tokens_user ON public.personal_access_tokens USING btree (user_id);


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
-- Name: idx_themes_scope; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_themes_scope ON public.themes USING btree (scope);


--
-- Name: idx_themes_tenant; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_themes_tenant ON public.themes USING btree (tenant_id);


--
-- Name: idx_themes_user; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_themes_user ON public.themes USING btree (user_id);


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
-- Name: alarm_sounds alarm_sounds_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.alarm_sounds
    ADD CONSTRAINT alarm_sounds_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: alarms alarms_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.alarms
    ADD CONSTRAINT alarms_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: api_endpoints api_endpoints_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.api_endpoints
    ADD CONSTRAINT api_endpoints_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


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
-- Name: business_addresses business_addresses_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.business_addresses
    ADD CONSTRAINT business_addresses_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: business_contacts business_contacts_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.business_contacts
    ADD CONSTRAINT business_contacts_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: businesses businesses_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.businesses
    ADD CONSTRAINT businesses_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


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
-- Name: locations locations_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


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
-- Name: my_projects my_projects_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.my_projects
    ADD CONSTRAINT my_projects_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: my_tasks my_tasks_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.my_tasks
    ADD CONSTRAINT my_tasks_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: person_addresses person_addresses_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_addresses
    ADD CONSTRAINT person_addresses_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: person_attachments person_attachments_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_attachments
    ADD CONSTRAINT person_attachments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: person_business_roles person_business_roles_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_business_roles
    ADD CONSTRAINT person_business_roles_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: person_contacts person_contacts_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_contacts
    ADD CONSTRAINT person_contacts_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: person_relationships person_relationships_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_relationships
    ADD CONSTRAINT person_relationships_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: personal_access_tokens personal_access_tokens_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(company_id) ON DELETE SET NULL;


--
-- Name: personal_access_tokens personal_access_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: persons persons_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.persons
    ADD CONSTRAINT persons_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


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
-- Name: task_attachments task_attachments_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_attachments
    ADD CONSTRAINT task_attachments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: task_categories task_categories_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_categories
    ADD CONSTRAINT task_categories_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: task_comments task_comments_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_comments
    ADD CONSTRAINT task_comments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: task_priorities task_priorities_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_priorities
    ADD CONSTRAINT task_priorities_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: task_sprints task_sprints_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_sprints
    ADD CONSTRAINT task_sprints_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


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
-- Name: themes themes_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.themes
    ADD CONSTRAINT themes_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: themes themes_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.themes
    ADD CONSTRAINT themes_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE CASCADE;


--
-- Name: themes themes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.themes
    ADD CONSTRAINT themes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: time_slots time_slots_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.time_slots
    ADD CONSTRAINT time_slots_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


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

\unrestrict vFTiYNhj3apxKkhz3NJ01f03gJIuKNnMAqXzso3ITYboCwMnb49Kpr3zggodNMx

