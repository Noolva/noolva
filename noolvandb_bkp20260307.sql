--
-- PostgreSQL database dump
--

\restrict THBAItxi3UW7mdQp3UK1fgM5fSvp3x0dtUi2h4Bmh2OHDGaCsYPcPxBC2ggbmIs

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
    is_default boolean,
    row_exposure_mode_id integer
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
    entity_id numeric,
    row_exposure_mode_id integer
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
    location integer,
    row_exposure_mode_id integer
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
    notes text,
    row_exposure_mode_id integer
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
    notes text,
    row_exposure_mode_id integer
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
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    row_exposure_mode_id integer
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
    is_active boolean DEFAULT true NOT NULL,
    row_exposure_mode_id integer
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
    is_active boolean DEFAULT true,
    row_exposure_mode_id integer
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
    business_id integer,
    row_exposure_mode_id integer
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
    service_uuid uuid DEFAULT gen_random_uuid(),
    row_exposure_mode_id integer
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
    location integer,
    row_exposure_mode_id integer
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
    row_exposure_mode_id integer
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
    notes text,
    row_exposure_mode_id integer
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
    notes text,
    row_exposure_mode_id integer
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
    notes text,
    row_exposure_mode_id integer
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
    person_uuid uuid DEFAULT gen_random_uuid(),
    row_exposure_mode_id integer
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
    test_icon character varying(255),
    row_exposure_mode_id integer
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
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    row_exposure_mode_id integer
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
-- Name: row_exposure_modes; Type: TABLE; Schema: public; Owner: noolvan
--

CREATE TABLE public.row_exposure_modes (
    exposure_mode_id integer NOT NULL,
    name character varying(100),
    description text,
    expose_data boolean DEFAULT false
);


ALTER TABLE public.row_exposure_modes OWNER TO noolvan;

--
-- Name: row_exposure_modes_exposure_mode_id_seq; Type: SEQUENCE; Schema: public; Owner: noolvan
--

CREATE SEQUENCE public.row_exposure_modes_exposure_mode_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.row_exposure_modes_exposure_mode_id_seq OWNER TO noolvan;

--
-- Name: row_exposure_modes_exposure_mode_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noolvan
--

ALTER SEQUENCE public.row_exposure_modes_exposure_mode_id_seq OWNED BY public.row_exposure_modes.exposure_mode_id;


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
    field_config_json jsonb DEFAULT '{}'::jsonb,
    user_uuid uuid
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
    task integer,
    row_exposure_mode_id integer
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
    order_no numeric,
    row_exposure_mode_id integer
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
    comment_title character varying(100),
    row_exposure_mode_id integer
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
    regret_level numeric DEFAULT '0'::numeric NOT NULL,
    row_exposure_mode_id integer
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
    is_active boolean DEFAULT true,
    row_exposure_mode_id integer
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
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    row_exposure_mode_id integer
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
    description text,
    row_exposure_mode_id integer
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
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    row_exposure_mode_id integer
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
    row_exposure_mode_id integer,
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
-- Name: row_exposure_modes exposure_mode_id; Type: DEFAULT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.row_exposure_modes ALTER COLUMN exposure_mode_id SET DEFAULT nextval('public.row_exposure_modes_exposure_mode_id_seq'::regclass);


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
7cf35083-4d35-4a37-8803-e5d8b4e708e0	Karan	created	Project Alpha	person:karan	concept:project_alpha	{"method": "web_ui"}	2026-01-05 23:29:01.996018+00	2026-01-15 23:29:01.996018+00	t
42568c16-7893-4fe3-af5a-de3d3901b520	Sundar	committed	Code Change #123	person:sundar	\N	{"lines_added": 50}	2026-01-13 23:29:01.996018+00	2026-01-15 23:29:01.996018+00	t
\.


--
-- Data for Name: ai_knowledge_nodes; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.ai_knowledge_nodes (node_id, node_type, title, description, content, is_active, version, created_at, updated_at) FROM stdin;
person:karan	entity	Karan	A user of the system	{"role": "admin", "email": "karan@example.com"}	t	1	2026-01-15 23:29:01.996018+00	2026-01-15 23:29:01.996018+00
person:sundar	entity	Sundar	A collaborator	{"role": "editor", "email": "sundar@example.com"}	t	1	2026-01-15 23:29:01.996018+00	2026-01-15 23:29:01.996018+00
concept:payment	concept	Payment	Transfer of value	{"methods": ["bank", "upi", "card"]}	t	1	2026-01-15 23:29:01.996018+00	2026-01-15 23:29:01.996018+00
concept:project_alpha	entity	Project Alpha	Top secret initiative	{"budget": 100000, "status": "active"}	t	1	2026-01-15 23:29:01.996018+00	2026-01-15 23:29:01.996018+00
\.


--
-- Data for Name: ai_knowledge_relations; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.ai_knowledge_relations (relation_id, from_node, to_node, relation, attributes, is_active, created_at) FROM stdin;
1	person:karan	concept:project_alpha	manages	{"since": "2025-01-01"}	t	2026-01-15 23:29:01.996018+00
2	person:sundar	concept:project_alpha	contributes_to	{"role": "developer"}	t	2026-01-15 23:29:01.996018+00
3	person:karan	concept:payment	can_approve	{}	t	2026-01-15 23:29:01.996018+00
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
c6e7b16c-b848-4784-98da-b3a424feabe0	High Value Payment Alert	\N	{"op": ">", "field": "amount", "value": 10000}	{"alert": "compliance_team", "severity": "high"}	10	t	2026-01-15 23:29:01.996018+00	2026-01-15 23:29:01.996018+00
aa1330f6-7746-4b82-83ca-46db11a02d7d	Inactive Project Archive	\N	{"op": ">", "days": 90, "field": "last_activity"}	{"status": "archived"}	5	t	2026-01-15 23:29:01.996018+00	2026-01-15 23:29:01.996018+00
\.


--
-- Data for Name: alarm_sounds; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.alarm_sounds (sound_id, created_by, idate, last_updated, alarm_file_path, sound_title, is_default, row_exposure_mode_id) FROM stdin;
1	\N	2026-02-24 18:33:43.858074+00	2026-02-24 18:33:43.858074+00	private/model-attachments/alarm_sounds/e4ec047e0d2d4688a93e3b9c8243bb1d.mp3	Cinematic Sound Effect	\N	\N
2	\N	2026-02-24 18:34:15.187033+00	2026-02-24 18:34:15.187033+00	private/model-attachments/alarm_sounds/3d4dcd798b244bddaa4010ad30604c34.mp3	Riser Hit	t	\N
\.


--
-- Data for Name: alarms; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.alarms (alarm_id, created_by, idate, last_updated, entity_type, alarm_mode, scheduled_for, condition_json, title, message, status, acknowledged_at, entity_id, row_exposure_mode_id) FROM stdin;
2	\N	2026-02-26 08:05:37.544764+00	2026-02-26 08:05:37.544764+00	reminder	condition_based	\N	\N	soap purchase	\N	pending	\N	\N	\N
4	\N	2026-02-26 12:20:07.947746+00	2026-02-26 12:20:07.947746+00	reminder	time_based	2026-02-26 13:30:00+00	\N	utlilization service with prasanna sir	\N	pending	\N	\N	\N
6	\N	2026-02-26 13:39:08.315706+00	2026-02-26 13:39:08.315706+00	reminder	time_based	2026-02-26 13:44:07+00	\N	52 Week PPM for Weeks 1 to 9 in NSDC Instance..	\N	sent	\N	\N	\N
7	\N	2026-02-26 16:39:40.274062+00	2026-02-26 16:39:40.274062+00	reminder	time_based	2026-02-26 16:44:39+00	\N	revert brookfields nginx conf	\N	sent	\N	\N	\N
3	\N	2026-02-26 08:47:40.036382+00	2026-02-26 08:47:40.036382+00	reminder	time_based	2026-02-26 14:30:00+00	\N	connect with reg connect api brookfields from local	\N	sent	2026-02-26 11:58:30+00	\N	\N
8	\N	2026-02-27 04:20:01.529276+00	2026-02-27 04:20:01.529276+00	reminder	time_based	2026-02-27 04:25:00+00	\N	production audit details for the week john	\N	sent	\N	\N	\N
11	\N	2026-02-27 06:46:37.609897+00	2026-02-27 06:46:37.609897+00	reminder	time_based	2026-02-27 06:51:37+00	\N	vivek prs	\N	sent	2026-02-27 08:09:14+00	\N	\N
12	\N	2026-02-27 06:47:13.083356+00	2026-02-27 06:47:13.083356+00	reminder	time_based	2026-02-27 13:30:00+00	\N	external crons, revert and deploy to mcloud,	release/1.7.140.1\nfinish release-deploy	sent	\N	\N	\N
16	\N	2026-02-28 12:37:27.153221+00	2026-02-28 12:37:27.153221+00	reminder	time_based	2026-02-28 12:42:27+00	\N	52 Week PPM for NSDC Instance Week 1 to 9	\N	sent	\N	\N	\N
14	\N	2026-02-27 15:18:28.532159+00	2026-02-27 15:18:28.532159+00	reminder	time_based	2026-02-27 15:23:27+00	\N	jagdeesh ticket update for iot	SR2600256	sent	\N	\N	\N
1	\N	2026-02-26 04:42:46.072836+00	2026-02-26 04:42:46.072836+00	reminder	time_based	2026-02-28 11:30:00+00	\N	check my laptop charge	\N	sent	\N	\N	\N
9	\N	2026-02-27 06:45:14.045173+00	2026-02-27 06:45:14.045173+00	reminder	time_based	2026-03-01 10:45:13+00	\N	john task finalize	\N	pending	\N	\N	\N
13	\N	2026-02-27 06:48:02.980153+00	2026-02-27 06:48:02.980153+00	reminder	time_based	2026-03-01 07:48:02+00	\N	John:tenx:  ticket validation	\N	pending	\N	\N	\N
10	\N	2026-02-27 06:46:06.33163+00	2026-02-27 06:46:06.33163+00	reminder	time_based	2026-02-28 11:00:00+00	\N	branch cut-down	\N	sent	\N	\N	\N
15	\N	2026-02-27 15:19:31.680724+00	2026-02-27 15:19:31.680724+00	reminder	time_based	2026-02-28 14:30:00+00	\N	warehouse pgsync	\N	sent	\N	\N	\N
17	\N	2026-02-28 14:42:24.570781+00	2026-02-28 14:42:24.570781+00	reminder	time_based	2026-03-01 14:47:49+00	\N	warehouse-brookfields pgsync	\N	pending	\N	\N	\N
5	\N	2026-02-26 12:21:03.191559+00	2026-02-26 12:21:03.191559+00	reminder	time_based	2026-03-01 14:48:01+00	\N	inpsection ppm sync sundaram sir	\N	pending	\N	\N	\N
18	\N	2026-03-04 09:27:47.989122+00	2026-03-04 09:27:47.989122+00	reminder	time_based	2026-03-19 18:30:00+00	\N	Ramzan leave	Ramzan	pending	\N	\N	\N
19	\N	2026-03-04 09:29:58.963918+00	2026-03-04 09:29:58.963918+00	reminder	time_based	2026-03-18 18:30:00+00	\N	Telugu New Year Holiday	Telugu New Year's Day	pending	\N	\N	\N
\.


--
-- Data for Name: api_endpoints; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.api_endpoints (endpoint_id, endpoint_uuid, path, method, type, related_model_id, permission_required, is_builtin, created_by, idate, last_updated, reference_model_ids, custom_json) FROM stdin;
1	f29e48e0-7cb7-4496-a10b-61258e38c0d7	/data-models/auto/users/records	GET	auto_crud	1	\N	f	1	2026-01-31 19:23:57.171632+00	2026-01-31 19:23:57.171632+00	{1}	{}
2	87eea253-a68b-4612-aa37-dc6b8d98dbf9	/data-models/auto/users/records	POST	auto_crud	1	\N	f	1	2026-01-31 19:23:57.171632+00	2026-01-31 19:23:57.171632+00	{1}	{}
3	c5ea3438-b572-4c7f-893d-b2ad4b7eaf14	/data-models/auto/teams/records	POST	auto_crud	9	\N	f	1	2026-01-31 19:23:57.171632+00	2026-01-31 19:23:57.171632+00	{9}	{}
4	add6432d-018f-476a-8cd6-d9e7b7321223	/data-models/auto/teams/records	GET	auto_crud	9	\N	f	1	2026-01-31 19:23:57.171632+00	2026-01-31 19:23:57.171632+00	{9}	{}
5	fcf5a80d-b95b-4d74-a437-1090b280e9ef	/data-models/auto/roles/records	GET	auto_crud	7	\N	f	1	2026-01-31 19:23:57.171632+00	2026-01-31 19:23:57.171632+00	{7}	{}
6	b16bf474-4db8-420d-86b1-e442e4876bb3	/data-models/auto/products/records	GET	auto_crud	14	\N	f	1	2026-01-31 19:23:57.171632+00	2026-01-31 19:23:57.171632+00	{14}	{}
7	5bd533a9-a8e4-4746-82cc-00b9539d55a9	/data-models/auto/products/records	POST	auto_crud	14	\N	f	1	2026-01-31 19:23:57.171632+00	2026-01-31 19:23:57.171632+00	{14}	{}
8	8b446fdc-06aa-4cc0-91bc-18b986a2d488	/data-models/auto/roles/records	POST	auto_crud	7	\N	f	1	2026-01-31 19:23:57.171632+00	2026-01-31 19:23:57.171632+00	{7}	{}
9	a666b07a-b583-4c7c-86a8-804a67e44d91	/data-models/auto/user_groups/records	POST	auto_crud	6	\N	f	1	2026-01-31 19:23:57.171632+00	2026-01-31 19:23:57.171632+00	{6}	{}
10	c8128646-cfce-4b92-a9e6-bc7a7ed22ef9	/data-models/auto/user_groups/records	GET	auto_crud	6	\N	f	1	2026-01-31 19:23:57.171632+00	2026-01-31 19:23:57.171632+00	{6}	{}
11	34ac2677-3430-4e3b-bca5-2f7cdedb90ac	/data-models/auto/companies/records	POST	auto_crud	11	\N	f	1	2026-01-31 19:23:57.171632+00	2026-01-31 19:23:57.171632+00	{11}	{}
12	a3eba5b5-99c6-4ab6-ad34-e08c56667c98	/data-models/auto/companies/records	GET	auto_crud	11	\N	f	1	2026-01-31 19:23:57.171632+00	2026-01-31 19:23:57.171632+00	{11}	{}
13	43bbed71-4ce0-462f-9d18-be9b1632b32e	/data-models/auto/roles/records/{record_id}	DELETE	auto_crud	7	\N	f	1	2026-01-31 19:23:57.215984+00	2026-01-31 19:23:57.215984+00	{7}	{}
14	aec42759-d25e-4daf-ad05-4dfb092a8299	/data-models/auto/roles/records/{record_id}	PUT	auto_crud	7	\N	f	1	2026-01-31 19:23:57.215984+00	2026-01-31 19:23:57.215984+00	{7}	{}
15	0b25f31f-8317-4ea0-9a46-4e36f477d38f	/data-models/auto/users/records/{record_id}	DELETE	auto_crud	1	\N	f	1	2026-01-31 19:23:57.215984+00	2026-01-31 19:23:57.215984+00	{1}	{}
16	de344c37-abd7-4b27-8300-d1faa6aeafa9	/data-models/auto/products/records/{record_id}	PUT	auto_crud	14	\N	f	1	2026-01-31 19:23:57.215984+00	2026-01-31 19:23:57.215984+00	{14}	{}
17	375e12f3-854e-48c0-a04e-f11b6f65a29b	/data-models/auto/users/records/{record_id}	PUT	auto_crud	1	\N	f	1	2026-01-31 19:23:57.215984+00	2026-01-31 19:23:57.215984+00	{1}	{}
18	801aa013-a651-415a-acd1-ae2f2d3e7e9f	/data-models/auto/products/records/{record_id}	DELETE	auto_crud	14	\N	f	1	2026-01-31 19:23:57.215984+00	2026-01-31 19:23:57.215984+00	{14}	{}
19	9f948aeb-3a92-4c3a-943a-70d960f209f3	/data-models/auto/companies/records/{record_id}	PUT	auto_crud	11	\N	f	1	2026-01-31 19:23:57.215984+00	2026-01-31 19:23:57.215984+00	{11}	{}
20	3ad99e3b-bcc6-4ade-b9e2-a934ff6d3a45	/data-models/auto/teams/records/{record_id}	PUT	auto_crud	9	\N	f	1	2026-01-31 19:23:57.215984+00	2026-01-31 19:23:57.215984+00	{9}	{}
21	d24a8c05-5bab-4048-8359-67e1cf59ca76	/data-models/auto/user_groups/records/{record_id}	PUT	auto_crud	6	\N	f	1	2026-01-31 19:23:57.215984+00	2026-01-31 19:23:57.215984+00	{6}	{}
22	4e18d567-a104-4797-9ddc-75e658482d7a	/data-models/auto/user_groups/records/{record_id}	DELETE	auto_crud	6	\N	f	1	2026-01-31 19:23:57.215984+00	2026-01-31 19:23:57.215984+00	{6}	{}
23	48fb51f4-531f-44a3-9d2a-75181012fdf8	/data-models/auto/companies/records/{record_id}	DELETE	auto_crud	11	\N	f	1	2026-01-31 19:23:57.215984+00	2026-01-31 19:23:57.215984+00	{11}	{}
24	4079d2d0-a0d7-4d6a-aba0-63ca804018d8	/data-models/auto/teams/records/{record_id}	DELETE	auto_crud	9	\N	f	1	2026-01-31 19:23:57.215984+00	2026-01-31 19:23:57.215984+00	{9}	{}
149	3bdfd560-1cde-4731-91d2-0035ea9e436f	/data-models/auto/person_addresses/records	GET	auto_crud	46	\N	f	2	2026-02-17 01:34:05.581423+00	2026-02-17 01:34:05.581423+00	{46}	{}
150	f60f9028-403c-40f3-844a-23ab0706beec	/data-models/auto/person_addresses/records	POST	auto_crud	46	\N	f	2	2026-02-17 01:34:05.594585+00	2026-02-17 01:34:05.594585+00	{46}	{}
151	07784046-8b44-48ab-8f11-89a8f5b37897	/data-models/auto/person_addresses/records/{record_id}	PUT	auto_crud	46	\N	f	2	2026-02-17 01:34:05.602079+00	2026-02-17 01:34:05.602079+00	{46}	{}
152	3398c8ae-cdfa-424c-8f9f-5d059c767b6f	/data-models/auto/person_addresses/records/{record_id}	DELETE	auto_crud	46	\N	f	2	2026-02-17 01:34:05.609368+00	2026-02-17 01:34:05.609368+00	{46}	{}
153	c4d8b8eb-06e1-4879-80b8-a6f3db33815c	/data-models/auto/person_contacts/records	GET	auto_crud	47	\N	f	2	2026-02-17 01:35:49.112942+00	2026-02-17 01:35:49.112942+00	{47}	{}
154	ace83b11-bb3b-4f63-af86-7c911ce7cca4	/data-models/auto/person_contacts/records	POST	auto_crud	47	\N	f	2	2026-02-17 01:35:49.125727+00	2026-02-17 01:35:49.125727+00	{47}	{}
155	9b6d90ee-2853-4df6-8d2f-b6c98231f32d	/data-models/auto/person_contacts/records/{record_id}	PUT	auto_crud	47	\N	f	2	2026-02-17 01:35:49.136982+00	2026-02-17 01:35:49.136982+00	{47}	{}
156	aa94e07c-70e4-47e3-b82e-83ce4e60ccf7	/data-models/auto/person_contacts/records/{record_id}	DELETE	auto_crud	47	\N	f	2	2026-02-17 01:35:49.147576+00	2026-02-17 01:35:49.147576+00	{47}	{}
161	12b7cf27-2535-4e85-b92a-004d260fa6ee	/data-models/auto/persons/records	GET	auto_crud	49	\N	f	2	2026-02-17 01:46:58.979405+00	2026-02-17 01:46:58.979405+00	{49}	{}
162	18eafd16-a32c-4771-b541-cf9884ed0570	/data-models/auto/persons/records	POST	auto_crud	49	\N	f	2	2026-02-17 01:46:58.987928+00	2026-02-17 01:46:58.987928+00	{49}	{}
163	d40b4ae7-fdc0-4c3b-a0e3-8c8ae7fe3f12	/data-models/auto/persons/records/{record_id}	PUT	auto_crud	49	\N	f	2	2026-02-17 01:46:58.99473+00	2026-02-17 01:46:58.99473+00	{49}	{}
164	8a37528f-29be-440e-9c39-88305fc34f8d	/data-models/auto/persons/records/{record_id}	DELETE	auto_crud	49	\N	f	2	2026-02-17 01:46:59.001124+00	2026-02-17 01:46:59.001124+00	{49}	{}
193	d69d33e4-d2e9-4c2a-bbfd-b1f0446d9648	/data-models/auto/locations/records	GET	auto_crud	57	\N	f	2	2026-02-17 03:52:41.362432+00	2026-02-17 03:52:41.362432+00	{57}	{}
194	0c5d367c-23dd-456d-9068-7219b1d77a31	/data-models/auto/locations/records	POST	auto_crud	57	\N	f	2	2026-02-17 03:52:41.373232+00	2026-02-17 03:52:41.373232+00	{57}	{}
195	c9084dbd-27d1-4611-9144-ae1f6764094c	/data-models/auto/locations/records/{record_id}	PUT	auto_crud	57	\N	f	2	2026-02-17 03:52:41.381083+00	2026-02-17 03:52:41.381083+00	{57}	{}
196	641fa3da-beb4-4906-b7f6-83917cc7edbc	/data-models/auto/locations/records/{record_id}	DELETE	auto_crud	57	\N	f	2	2026-02-17 03:52:41.388001+00	2026-02-17 03:52:41.388001+00	{57}	{}
197	ec145e50-e1a2-4ed4-86a6-a5991cb1b5f1	/data-models/auto/alarm_sounds/records	GET	auto_crud	58	\N	f	2	2026-02-24 17:54:53.878538+00	2026-02-24 17:54:53.878538+00	{58}	{}
198	6857e1e4-4886-4495-a8d5-780a564391de	/data-models/auto/alarm_sounds/records	POST	auto_crud	58	\N	f	2	2026-02-24 17:54:53.898423+00	2026-02-24 17:54:53.898423+00	{58}	{}
199	8cbb7ed4-0d1d-4b60-8a44-2caea57f2b63	/data-models/auto/alarm_sounds/records/{record_id}	PUT	auto_crud	58	\N	f	2	2026-02-24 17:54:53.910852+00	2026-02-24 17:54:53.910852+00	{58}	{}
200	08a116c1-08db-4cbc-ba1e-f2e09d4adb62	/data-models/auto/alarm_sounds/records/{record_id}	DELETE	auto_crud	58	\N	f	2	2026-02-24 17:54:53.921043+00	2026-02-24 17:54:53.921043+00	{58}	{}
165	3964a2c6-4672-49a5-9a8f-c7c87c150b39	/data-models/auto/person_relationships/records	GET	auto_crud	50	\N	f	2	2026-02-17 01:52:31.7001+00	2026-02-17 01:52:31.7001+00	{50}	{}
166	d0156cf6-fe94-47e6-8d90-194283467c2e	/data-models/auto/person_relationships/records	POST	auto_crud	50	\N	f	2	2026-02-17 01:52:31.717742+00	2026-02-17 01:52:31.717742+00	{50}	{}
167	684120f2-b1db-40d9-85e3-61c089a1b052	/data-models/auto/person_relationships/records/{record_id}	PUT	auto_crud	50	\N	f	2	2026-02-17 01:52:31.728537+00	2026-02-17 01:52:31.728537+00	{50}	{}
168	2b2a8de2-dfbb-491b-91ac-126effd37f35	/data-models/auto/person_relationships/records/{record_id}	DELETE	auto_crud	50	\N	f	2	2026-02-17 01:52:31.740076+00	2026-02-17 01:52:31.740076+00	{50}	{}
201	80566fad-6b5a-4471-af27-7208b86d5c47	/data-models/auto/alarms/records	GET	auto_crud	59	\N	f	2	2026-02-24 18:02:52.559221+00	2026-02-24 18:02:52.559221+00	{59}	{}
202	4e624446-ad60-4d14-a77f-680fb2582eed	/data-models/auto/alarms/records	POST	auto_crud	59	\N	f	2	2026-02-24 18:02:52.574036+00	2026-02-24 18:02:52.574036+00	{59}	{}
203	a78e4607-663c-4b01-a4eb-d3f154af851c	/data-models/auto/alarms/records/{record_id}	PUT	auto_crud	59	\N	f	2	2026-02-24 18:02:52.581758+00	2026-02-24 18:02:52.581758+00	{59}	{}
204	f0eaca70-2073-4a9f-a69a-e2310413c4ac	/data-models/auto/alarms/records/{record_id}	DELETE	auto_crud	59	\N	f	2	2026-02-24 18:02:52.589513+00	2026-02-24 18:02:52.589513+00	{59}	{}
169	8b698864-b9cd-4335-8d7f-840968a84559	/data-models/auto/businesses/records	GET	auto_crud	51	\N	f	2	2026-02-17 02:23:41.212284+00	2026-02-17 02:23:41.212284+00	{51}	{}
170	75c52d33-fbca-4c4c-b2da-9c6f2508a7ff	/data-models/auto/businesses/records	POST	auto_crud	51	\N	f	2	2026-02-17 02:23:41.228863+00	2026-02-17 02:23:41.228863+00	{51}	{}
171	c31fad8b-78ad-4a73-8105-9ea8d0f80a86	/data-models/auto/businesses/records/{record_id}	PUT	auto_crud	51	\N	f	2	2026-02-17 02:23:41.238494+00	2026-02-17 02:23:41.238494+00	{51}	{}
172	47999dc3-6f4f-4d55-8d81-64dcd320a131	/data-models/auto/businesses/records/{record_id}	DELETE	auto_crud	51	\N	f	2	2026-02-17 02:23:41.249699+00	2026-02-17 02:23:41.249699+00	{51}	{}
173	d881c5b6-f8d7-4d41-b6c5-6ac32278e3fb	/data-models/auto/person_attachments/records	GET	auto_crud	52	\N	f	2	2026-02-17 02:27:54.627204+00	2026-02-17 02:27:54.627204+00	{52}	{}
174	c9e152a8-98e7-4745-9ab5-84721d9a4644	/data-models/auto/person_attachments/records	POST	auto_crud	52	\N	f	2	2026-02-17 02:27:54.637175+00	2026-02-17 02:27:54.637175+00	{52}	{}
175	ddb0f1f4-1371-4a28-b620-10eebec63419	/data-models/auto/person_attachments/records/{record_id}	PUT	auto_crud	52	\N	f	2	2026-02-17 02:27:54.646749+00	2026-02-17 02:27:54.646749+00	{52}	{}
176	aa6d64ee-cd46-45e8-811e-da6d5c32cba4	/data-models/auto/person_attachments/records/{record_id}	DELETE	auto_crud	52	\N	f	2	2026-02-17 02:27:54.655744+00	2026-02-17 02:27:54.655744+00	{52}	{}
205	bf189fc1-2231-4122-a951-6f766ea322b1	/data-models/auto/time_slots/records	GET	auto_crud	60	\N	f	2	2026-03-01 08:04:26.544459+00	2026-03-01 08:04:26.544459+00	{60}	{}
206	566232a4-e761-4894-968a-c109865e36dd	/data-models/auto/time_slots/records	POST	auto_crud	60	\N	f	2	2026-03-01 08:04:26.565178+00	2026-03-01 08:04:26.565178+00	{60}	{}
207	b08f64fb-6212-49ef-ae70-60b5fddb4668	/data-models/auto/time_slots/records/{record_id}	PUT	auto_crud	60	\N	f	2	2026-03-01 08:04:26.575822+00	2026-03-01 08:04:26.575822+00	{60}	{}
208	224c9f56-cb3e-429a-a29d-ea9989112a29	/data-models/auto/time_slots/records/{record_id}	DELETE	auto_crud	60	\N	f	2	2026-03-01 08:04:26.587137+00	2026-03-01 08:04:26.587137+00	{60}	{}
121	894dd5be-5429-4702-ad19-7f134ea39f67	/data-models/auto/password_vault/records	GET	auto_crud	39	\N	f	\N	2026-02-08 19:12:50.670585+00	2026-02-08 19:12:50.670585+00	{39}	{}
122	0bc05374-18fd-40ca-bb6e-fe4a56b42f1e	/data-models/auto/password_vault/records	POST	auto_crud	39	\N	f	\N	2026-02-08 19:12:50.670585+00	2026-02-08 19:12:50.670585+00	{39}	{}
123	5e1630e8-e93a-4b37-9ab8-0510a60fc5fb	/data-models/auto/password_vault/records/{record_id}	PUT	auto_crud	39	\N	f	\N	2026-02-08 19:12:50.670585+00	2026-02-08 19:12:50.670585+00	{39}	{}
124	76b20ff8-4577-4e30-82ad-ccfca0dfbe65	/data-models/auto/password_vault/records/{record_id}	DELETE	auto_crud	39	\N	f	\N	2026-02-08 19:12:50.670585+00	2026-02-08 19:12:50.670585+00	{39}	{}
125	1d1dff75-725a-41bf-ae64-5f7f05815c35	/data-models/auto/task_priorities/records	GET	auto_crud	40	\N	f	2	2026-02-14 20:54:20.407787+00	2026-02-14 20:54:20.407787+00	{40}	{}
126	ccd29fdc-4cd0-49a5-83dd-1d1af8ccb650	/data-models/auto/task_priorities/records	POST	auto_crud	40	\N	f	2	2026-02-14 20:54:20.430619+00	2026-02-14 20:54:20.430619+00	{40}	{}
127	06218776-b939-4007-a2fb-c8f0aa0cc4bf	/data-models/auto/task_priorities/records/{record_id}	PUT	auto_crud	40	\N	f	2	2026-02-14 20:54:20.445242+00	2026-02-14 20:54:20.445242+00	{40}	{}
128	f824154e-b254-4a9e-9d94-f8d87974be20	/data-models/auto/task_priorities/records/{record_id}	DELETE	auto_crud	40	\N	f	2	2026-02-14 20:54:20.462504+00	2026-02-14 20:54:20.462504+00	{40}	{}
129	9ff62d88-0902-4079-b79e-072b8b36e374	/data-models/auto/task_categories/records	GET	auto_crud	41	\N	f	2	2026-02-14 22:05:16.109834+00	2026-02-14 22:05:16.109834+00	{41}	{}
130	7ddc6e1b-9ba2-4543-a269-0485a4d96c01	/data-models/auto/task_categories/records	POST	auto_crud	41	\N	f	2	2026-02-14 22:05:16.136502+00	2026-02-14 22:05:16.136502+00	{41}	{}
131	574b5a04-caf7-4c6c-bf68-1bcdb6932e74	/data-models/auto/task_categories/records/{record_id}	PUT	auto_crud	41	\N	f	2	2026-02-14 22:05:16.154129+00	2026-02-14 22:05:16.154129+00	{41}	{}
132	afe8268f-0958-4c20-87c4-1371281c766b	/data-models/auto/task_categories/records/{record_id}	DELETE	auto_crud	41	\N	f	2	2026-02-14 22:05:16.173644+00	2026-02-14 22:05:16.173644+00	{41}	{}
133	c9c86844-ef9e-4ce4-8b65-0d0b8bbdb053	/data-models/auto/my_projects/records	GET	auto_crud	42	\N	f	2	2026-02-14 22:23:43.107005+00	2026-02-14 22:23:43.107005+00	{42}	{}
134	39688d8a-9915-4412-98b6-0053d145d377	/data-models/auto/my_projects/records	POST	auto_crud	42	\N	f	2	2026-02-14 22:23:43.124013+00	2026-02-14 22:23:43.124013+00	{42}	{}
135	c83e787b-55be-4d9c-83b3-6c6e6144f5c3	/data-models/auto/my_projects/records/{record_id}	PUT	auto_crud	42	\N	f	2	2026-02-14 22:23:43.136637+00	2026-02-14 22:23:43.136637+00	{42}	{}
136	9d314065-169b-4801-9b60-1b136a2f44c5	/data-models/auto/my_projects/records/{record_id}	DELETE	auto_crud	42	\N	f	2	2026-02-14 22:23:43.149333+00	2026-02-14 22:23:43.149333+00	{42}	{}
177	718d72bb-b904-4869-851e-0ca0d01624c8	/data-models/auto/business_contacts/records	GET	auto_crud	53	\N	f	2	2026-02-17 02:40:08.221845+00	2026-02-17 02:40:08.221845+00	{53}	{}
178	9dff7c7b-f3cc-4994-b1bd-4cc9b049c41c	/data-models/auto/business_contacts/records	POST	auto_crud	53	\N	f	2	2026-02-17 02:40:08.232778+00	2026-02-17 02:40:08.232778+00	{53}	{}
141	9e49e9aa-ca0e-406d-83ee-7232d074deb5	/data-models/auto/task_sprints/records	GET	auto_crud	44	\N	f	2	2026-02-15 07:47:27.484511+00	2026-02-15 07:47:27.484511+00	{44}	{}
142	933f7dd4-0922-4dd5-bc49-eb71ddfcd6e0	/data-models/auto/task_sprints/records	POST	auto_crud	44	\N	f	2	2026-02-15 07:47:27.516915+00	2026-02-15 07:47:27.516915+00	{44}	{}
143	78ef2e28-9960-4e92-bc1b-250962d1fb9e	/data-models/auto/task_sprints/records/{record_id}	PUT	auto_crud	44	\N	f	2	2026-02-15 07:47:27.531441+00	2026-02-15 07:47:27.531441+00	{44}	{}
144	09c026c0-69aa-4c52-80da-defc54cd91e0	/data-models/auto/task_sprints/records/{record_id}	DELETE	auto_crud	44	\N	f	2	2026-02-15 07:47:27.552573+00	2026-02-15 07:47:27.552573+00	{44}	{}
145	e14abb1e-4a4a-4aef-9427-0b1f122dba21	/data-models/auto/my_tasks/records	GET	auto_crud	45	\N	f	2	2026-02-15 19:00:41.160622+00	2026-02-15 19:00:41.160622+00	{45}	{}
146	12498c64-bdfe-49d9-8ad4-b23b76b6f786	/data-models/auto/my_tasks/records	POST	auto_crud	45	\N	f	2	2026-02-15 19:00:41.178386+00	2026-02-15 19:00:41.178386+00	{45}	{}
147	f19a1ae3-f733-4b6f-b393-656b41c169a2	/data-models/auto/my_tasks/records/{record_id}	PUT	auto_crud	45	\N	f	2	2026-02-15 19:00:41.186566+00	2026-02-15 19:00:41.186566+00	{45}	{}
148	72832f08-9f66-4af3-affb-5c5a0d231a02	/data-models/auto/my_tasks/records/{record_id}	DELETE	auto_crud	45	\N	f	2	2026-02-15 19:00:41.194619+00	2026-02-15 19:00:41.194619+00	{45}	{}
179	e7d17d4e-1d75-44ae-aecd-d3df63a817b9	/data-models/auto/business_contacts/records/{record_id}	PUT	auto_crud	53	\N	f	2	2026-02-17 02:40:08.24034+00	2026-02-17 02:40:08.24034+00	{53}	{}
180	3f31923b-9349-48d2-8ec8-cff9f54cc292	/data-models/auto/business_contacts/records/{record_id}	DELETE	auto_crud	53	\N	f	2	2026-02-17 02:40:08.248455+00	2026-02-17 02:40:08.248455+00	{53}	{}
181	970bb21c-c33f-4213-822b-bc9be468a9e8	/data-models/auto/business_addresses/records	GET	auto_crud	54	\N	f	2	2026-02-17 02:43:03.945565+00	2026-02-17 02:43:03.945565+00	{54}	{}
182	d6e0ddc6-4b4a-4c56-aa0f-eace9335f72c	/data-models/auto/business_addresses/records	POST	auto_crud	54	\N	f	2	2026-02-17 02:43:03.955187+00	2026-02-17 02:43:03.955187+00	{54}	{}
183	3b729957-b788-49c2-873d-ef13b8c32732	/data-models/auto/business_addresses/records/{record_id}	PUT	auto_crud	54	\N	f	2	2026-02-17 02:43:03.962623+00	2026-02-17 02:43:03.962623+00	{54}	{}
184	4c1ea9f9-c104-4507-ad32-add87aa09572	/data-models/auto/business_addresses/records/{record_id}	DELETE	auto_crud	54	\N	f	2	2026-02-17 02:43:03.969413+00	2026-02-17 02:43:03.969413+00	{54}	{}
185	c1cbeec4-ae2c-4166-b3ac-ae709cfade5f	/data-models/auto/person_business_roles/records	GET	auto_crud	55	\N	f	2	2026-02-17 02:47:01.957663+00	2026-02-17 02:47:01.957663+00	{55}	{}
186	a02d1596-e283-4d14-83df-0c92cc608ab9	/data-models/auto/person_business_roles/records	POST	auto_crud	55	\N	f	2	2026-02-17 02:47:01.974264+00	2026-02-17 02:47:01.974264+00	{55}	{}
187	20033033-8e14-4d4d-a4fa-138374d83f2e	/data-models/auto/person_business_roles/records/{record_id}	PUT	auto_crud	55	\N	f	2	2026-02-17 02:47:01.984163+00	2026-02-17 02:47:01.984163+00	{55}	{}
188	72e4af55-669c-4b4e-8838-41a974022820	/data-models/auto/person_business_roles/records/{record_id}	DELETE	auto_crud	55	\N	f	2	2026-02-17 02:47:01.997004+00	2026-02-17 02:47:01.997004+00	{55}	{}
209	fd9965e9-dacf-45a9-8c34-ca8a7683c67c	/data-models/auto/task_comments/records	GET	auto_crud	61	\N	f	2	2026-03-02 19:27:52.251677+00	2026-03-02 19:27:52.251677+00	{61}	{}
210	ba3746c2-eb7c-4282-8dad-f844eb5c389b	/data-models/auto/task_comments/records	POST	auto_crud	61	\N	f	2	2026-03-02 19:27:52.278913+00	2026-03-02 19:27:52.278913+00	{61}	{}
211	968f3586-66c9-4c21-9463-1722b0906b45	/data-models/auto/task_comments/records/{record_id}	PUT	auto_crud	61	\N	f	2	2026-03-02 19:27:52.291683+00	2026-03-02 19:27:52.291683+00	{61}	{}
212	29ebda7d-433d-4351-b684-2ad73f0caa77	/data-models/auto/task_comments/records/{record_id}	DELETE	auto_crud	61	\N	f	2	2026-03-02 19:27:52.306515+00	2026-03-02 19:27:52.306515+00	{61}	{}
213	3037ef68-48c2-4b34-a8f3-5c43c27f50d6	/data-models/auto/task_attachments/records	GET	auto_crud	62	\N	f	2	2026-03-02 19:32:53.473847+00	2026-03-02 19:32:53.473847+00	{62}	{}
214	75e7c4d4-8c0c-4b76-a041-5e183ef028b6	/data-models/auto/task_attachments/records	POST	auto_crud	62	\N	f	2	2026-03-02 19:32:53.4947+00	2026-03-02 19:32:53.4947+00	{62}	{}
215	2a65fb5a-2784-490c-ab52-549f3429e325	/data-models/auto/task_attachments/records/{record_id}	PUT	auto_crud	62	\N	f	2	2026-03-02 19:32:53.509919+00	2026-03-02 19:32:53.509919+00	{62}	{}
216	221e966f-8aac-449c-ab4e-e8a75eb6b56c	/data-models/auto/task_attachments/records/{record_id}	DELETE	auto_crud	62	\N	f	2	2026-03-02 19:32:53.524746+00	2026-03-02 19:32:53.524746+00	{62}	{}
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
1	92a19143-3518-4044-91be-b1ffa6b9f950	dashboards	Dashboards	https://cdn.avkaran.com/dashboards_app_icon.png	Dashboard and analytics application	\N	\N	\N	t	t	f	t	1	\N	2026-01-15 23:29:03.114175+00	2026-01-16 01:58:46.119529+00	t
4	05ffd05f-ca56-4dd7-a256-4a60f2d164ed	organization	Organization	/assets/organization_app_icon.svg	Company, users, roles and permissions	\N	\N	\N	t	f	f	t	20	1	2026-01-16 01:58:46.119529+00	2026-01-16 02:14:09.797449+00	t
5	5f3d850a-a769-444d-8884-503411ba2654	app_studio	App Studio	/assets/app_studio_app_icon.svg	Low-code studio (models, views, menus, APIs)	\N	\N	\N	t	f	f	t	30	1	2026-01-16 01:58:46.119529+00	2026-01-16 02:14:09.812012+00	t
6	f56efbee-6e29-4cb3-9eeb-aa4c8f7a011f	settings	Settings	/assets/settings_app_icon.svg	Platform settings	\N	\N	\N	t	f	f	t	40	1	2026-01-16 01:58:46.119529+00	2026-01-16 02:14:09.817599+00	t
7	265ffafa-642e-4d43-aeba-a5924765f618	developer_console	Dev Console	/assets/developer_console_app_icon.svg	Database administration and query tools	\N	\N	\N	t	f	f	t	50	1	2026-01-17 01:47:18.91518+00	2026-01-17 01:47:18.959375+00	t
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
1	335298b3-ba4c-46fe-94ef-22e419419c9a	1	dashboards_app_icon.png	dashboards_app_icon.png	image/png	21746	s3	websites/noolva/assets/dashboards_app_icon.png	https://cdn.avkaran.com/websites/noolva/assets/dashboards_app_icon.png	t	\N	\N	1	2026-01-15 23:30:08.764001+00
2	cca404b5-902c-4bc5-a835-fd152c56db93	1	users_app_icon.png	users_app_icon.png	image/png	47393	s3	websites/noolva/assets/users_app_icon.png	https://cdn.avkaran.com/websites/noolva/assets/users_app_icon.png	t	\N	\N	1	2026-01-15 23:30:09.484509+00
\.


--
-- Data for Name: audit_logs_default; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.audit_logs_default (log_id, event_time, tenant_id, user_id, event_category, event_action, target_model, target_record_id, changes_json, metadata_json) FROM stdin;
\.


--
-- Data for Name: business_addresses; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.business_addresses (address_id, created_by, idate, last_updated, business_id, address_type, address_line1, address_line2, postal_code, is_primary, map_location, location, row_exposure_mode_id) FROM stdin;
1	\N	2026-02-22 18:32:08.927338+00	2026-02-22 18:32:08.927338+00	1	head_office	Share Space Evoma, 88, Borewell Rd	Palm Meadows, Dodsworth Layout	560066	t	(12.968650876502462,77.74778445945935)	2	\N
\.


--
-- Data for Name: business_contacts; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.business_contacts (contact_id, created_by, idate, last_updated, business_id, contact_type, contact_value, label, is_primary, is_verified, verified_at, notes, row_exposure_mode_id) FROM stdin;
\.


--
-- Data for Name: businesses; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.businesses (business_id, created_by, idate, last_updated, name, legal_name, industry, website, is_active, gst_number, notes, row_exposure_mode_id) FROM stdin;
1	\N	2026-02-21 21:02:52.142366+00	2026-02-21 21:02:52.142366+00	Helixsense	Helix Sense Technologies Pvt Ltd	\N	https://helixsense.com	t	\N	\N	\N
\.


--
-- Data for Name: collections; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.collections (collection_id, collection_uuid, collection_name, collection_code, tenant_id, is_system, created_by, created_at, last_updated, field_type_id, field_config_json) FROM stdin;
1	abf30cdd-3771-417b-a649-45e303975f9b	System User Types	system_user_types	\N	t	1	2026-01-25 02:23:32.317886+00	2026-01-25 02:23:32.317886+00	\N	{"items": [{"label": "SaaS Admin", "value": "saas_admin"}, {"label": "SaaS Employee", "value": "saas_employee"}, {"label": "SaaS Reseller", "value": "saas_reseller"}, {"label": "SaaS Promoter", "value": "saas_promoter"}, {"label": "Tenant Admin", "value": "tenant_admin"}, {"label": "Tenant User", "value": "tenant_user"}, {"label": "System", "value": "system"}]}
\.


--
-- Data for Name: companies; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.companies (company_id, company_uuid, tenant_id, company_name, company_code, domain, logo_url, branding_config, parent_company_id, is_default, is_active, created_by, idate, last_updated, row_exposure_mode_id) FROM stdin;
1	e97769dd-eae3-456d-8d84-3923b6b94858	1	Your Company	your-company	\N	\N	\N	\N	t	t	\N	2026-01-15 23:29:03.114175+00	2026-01-15 23:29:03.114175+00	\N
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
272	40	priority_id	ID	4	{}	f	f	t	\N	none	\N	1	2026-02-14 20:54:20.301724+00
273	40	created_by	Created By	3	{}	f	f	f	\N	none	\N	2	2026-02-14 20:54:20.359763+00
3	1	username	Username	1	{"max_length": 100}	t	t	f	\N	none	\N	3	2026-01-18 00:33:45.084095+00
4	1	password	Password	1	{"max_length": 120, "is_password": true}	t	f	f	\N	none	\N	4	2026-01-18 00:33:45.084095+00
5	1	first_name	First Name	1	{"max_length": 100}	f	f	f	\N	none	\N	5	2026-01-18 00:33:45.084095+00
6	1	last_name	Last Name	1	{"max_length": 100}	f	f	f	\N	none	\N	6	2026-01-18 00:33:45.084095+00
7	1	email	Email	1	{"max_length": 100, "validation": "email"}	f	f	f	\N	none	\N	7	2026-01-18 00:33:45.084095+00
8	1	phone	Phone	1	{"max_length": 20}	f	f	f	\N	none	\N	8	2026-01-18 00:33:45.084095+00
9	1	avatar_url	Avatar URL	1	{"validation": "url"}	f	f	f	\N	none	\N	9	2026-01-18 00:33:45.084095+00
10	1	user_type	User Type	1	{"options": ["saas_admin", "saas_employee", "saas_reseller", "saas_promoter", "tenant_admin", "tenant_user", "system"], "max_length": 20}	t	f	f	\N	none	\N	10	2026-01-18 00:33:45.084095+00
11	1	is_super_admin	Is Super Admin	12	{}	f	f	f	false	none	\N	11	2026-01-18 00:33:45.084095+00
12	1	active_status	Active Status	1	{"options": [{"label": "Inactive", "value": 0}, {"label": "Active", "value": 1}, {"label": "Suspended", "value": 2}]}	t	f	f	1	none	\N	12	2026-01-18 00:33:45.084095+00
274	40	idate	Created Date	9	{}	t	f	f	\N	none	\N	3	2026-02-14 20:54:20.380573+00
275	40	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	4	2026-02-14 20:54:20.394595+00
276	40	name	Name	1	{"max_length": 50}	t	t	f	\N	none	\N	2	2026-02-14 21:00:50.094663+00
277	40	weight	Weight	3	{"maximum_digits": 5, "allowed_decimal_places": 0}	t	f	f	\N	none	\N	3	2026-02-14 21:00:50.233516+00
33	6	group_id	Group ID	4	{}	t	t	t	\N	none	\N	1	2026-01-18 01:14:59.269326+00
278	40	importance	Importance	12	{}	t	f	f	false	none	\N	4	2026-02-14 21:00:50.327502+00
35	6	group_name	Group Name	1	{"max_length": 100}	t	f	f	\N	none	\N	3	2026-01-18 01:14:59.269326+00
36	6	group_description	Group Description	1	{"max_length": 1000}	f	f	f	\N	none	\N	4	2026-01-18 01:14:59.269326+00
37	6	company_id	Company ID	4	{}	t	f	f	\N	none	\N	5	2026-01-18 01:14:59.269326+00
38	6	created_by	Created By	4	{}	f	f	f	\N	none	\N	6	2026-01-18 01:14:59.269326+00
39	6	idate	Created Date	9	{}	t	f	f	\N	none	\N	7	2026-01-18 01:14:59.269326+00
40	6	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	8	2026-01-18 01:14:59.269326+00
41	7	role_id	Role ID	4	{}	t	t	t	\N	none	\N	1	2026-01-18 01:14:59.440739+00
279	40	urgency	Urgency	12	{}	t	f	f	false	none	\N	5	2026-02-14 21:00:50.478797+00
43	7	role_name	Role Name	1	{"max_length": 100}	t	f	f	\N	none	\N	3	2026-01-18 01:14:59.440739+00
44	7	role_key	Role Key	1	{"max_length": 100}	t	f	f	\N	none	\N	4	2026-01-18 01:14:59.440739+00
45	7	role_description	Role Description	1	{"max_length": 1000}	f	f	f	\N	none	\N	5	2026-01-18 01:14:59.440739+00
46	7	company_id	Company ID	4	{}	f	f	f	\N	none	\N	6	2026-01-18 01:14:59.440739+00
47	7	is_system_role	Is System Role	12	{}	f	f	f	false	none	\N	7	2026-01-18 01:14:59.440739+00
48	7	created_by	Created By	4	{}	f	f	f	\N	none	\N	8	2026-01-18 01:14:59.440739+00
49	7	idate	Created Date	9	{}	t	f	f	\N	none	\N	9	2026-01-18 01:14:59.440739+00
50	7	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	10	2026-01-18 01:14:59.440739+00
51	6	group_id	Group ID	4	{}	t	t	t	\N	none	\N	1	2026-01-18 01:15:37.550929+00
280	40	is_mandatory	Is Mandatory	12	{}	t	f	f	false	none	\N	6	2026-02-14 21:00:50.648515+00
53	6	group_name	Group Name	1	{"max_length": 100}	t	f	f	\N	none	\N	3	2026-01-18 01:15:37.550929+00
54	6	group_description	Group Description	1	{"max_length": 1000}	f	f	f	\N	none	\N	4	2026-01-18 01:15:37.550929+00
55	6	company_id	Company ID	4	{}	t	f	f	\N	none	\N	5	2026-01-18 01:15:37.550929+00
56	6	created_by	Created By	4	{}	f	f	f	\N	none	\N	6	2026-01-18 01:15:37.550929+00
57	6	idate	Created Date	9	{}	t	f	f	\N	none	\N	7	2026-01-18 01:15:37.550929+00
58	6	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	8	2026-01-18 01:15:37.550929+00
59	9	team_id	Team ID	4	{}	t	t	t	\N	none	\N	1	2026-01-18 01:15:37.595914+00
281	40	is_ignorable	Is Ignorable	12	{}	t	f	f	false	none	\N	7	2026-02-14 21:00:50.745257+00
61	9	team_name	Team Name	1	{"max_length": 100}	t	f	f	\N	none	\N	3	2026-01-18 01:15:37.595914+00
62	9	team_description	Team Description	1	{"max_length": 1000}	f	f	f	\N	none	\N	4	2026-01-18 01:15:37.595914+00
63	9	company_id	Company ID	4	{}	t	f	f	\N	none	\N	5	2026-01-18 01:15:37.595914+00
64	9	parent_team_id	Parent Team ID	4	{}	f	f	f	\N	none	\N	6	2026-01-18 01:15:37.595914+00
65	9	manager_id	Manager ID	4	{}	f	f	f	\N	none	\N	7	2026-01-18 01:15:37.595914+00
66	9	created_by	Created By	4	{}	f	f	f	\N	none	\N	8	2026-01-18 01:15:37.595914+00
67	9	idate	Created Date	9	{}	t	f	f	\N	none	\N	9	2026-01-18 01:15:37.595914+00
68	9	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	10	2026-01-18 01:15:37.595914+00
69	7	role_id	Role ID	4	{}	t	t	t	\N	none	\N	1	2026-01-18 01:15:37.615064+00
282	40	is_delegatable	Is Delegatable	12	{}	t	f	f	false	none	\N	8	2026-02-14 21:00:50.82392+00
71	7	role_name	Role Name	1	{"max_length": 100}	t	f	f	\N	none	\N	3	2026-01-18 01:15:37.615064+00
72	7	role_key	Role Key	1	{"max_length": 100}	t	f	f	\N	none	\N	4	2026-01-18 01:15:37.615064+00
73	7	role_description	Role Description	1	{"max_length": 1000}	f	f	f	\N	none	\N	5	2026-01-18 01:15:37.615064+00
74	7	company_id	Company ID	4	{}	f	f	f	\N	none	\N	6	2026-01-18 01:15:37.615064+00
75	7	is_system_role	Is System Role	12	{}	f	f	f	false	none	\N	7	2026-01-18 01:15:37.615064+00
76	7	created_by	Created By	4	{}	f	f	f	\N	none	\N	8	2026-01-18 01:15:37.615064+00
77	7	idate	Created Date	9	{}	t	f	f	\N	none	\N	9	2026-01-18 01:15:37.615064+00
78	7	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	10	2026-01-18 01:15:37.615064+00
79	11	company_id	Company ID	4	{}	t	t	t	\N	none	\N	1	2026-01-18 01:15:37.637979+00
81	11	tenant_id	Tenant ID	4	{}	t	f	f	\N	none	\N	3	2026-01-18 01:15:37.637979+00
82	11	company_name	Company Name	1	{"max_length": 200}	t	f	f	\N	none	\N	4	2026-01-18 01:15:37.637979+00
83	11	company_code	Company Code	1	{"max_length": 50}	t	t	f	\N	none	\N	5	2026-01-18 01:15:37.637979+00
84	11	domain	Domain	1	{"max_length": 100, "validation": "domain"}	f	f	f	\N	none	\N	6	2026-01-18 01:15:37.637979+00
85	11	logo_url	Logo URL	1	{"validation": "url"}	f	f	f	\N	none	\N	7	2026-01-18 01:15:37.637979+00
87	11	parent_company_id	Parent Company ID	4	{}	f	f	f	\N	none	\N	9	2026-01-18 01:15:37.637979+00
88	11	is_default	Is Default	12	{}	f	f	f	false	none	\N	10	2026-01-18 01:15:37.637979+00
89	11	is_active	Is Active	12	{}	f	f	f	true	none	\N	11	2026-01-18 01:15:37.637979+00
90	11	created_by	Created By	4	{}	f	f	f	\N	none	\N	12	2026-01-18 01:15:37.637979+00
91	11	idate	Created Date	9	{}	t	f	f	\N	none	\N	13	2026-01-18 01:15:37.637979+00
92	11	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	14	2026-01-18 01:15:37.637979+00
97	14	product_id	ID	4	{}	f	f	t	\N	none	\N	1	2026-01-31 00:06:25.993984+00
283	40	regret_level	Regret Level	3	{"maximum_digits": 2, "allowed_decimal_places": 0}	t	f	f	0	none	\N	9	2026-02-14 21:00:50.921925+00
99	14	idate	Created Date	9	{}	t	f	f	\N	none	\N	3	2026-01-31 00:06:26.06297+00
100	14	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	4	2026-01-31 00:06:26.077537+00
102	14	test_paragraph	test paragraph	2	{"max_line_counts": 3}	f	f	f	\N	none	\N	6	2026-01-31 01:03:18.824626+00
103	14	test_number_int	test_number_int	2	{"maximum_digits": 10, "allowed_decimal_places": 0}	f	f	f	\N	none	\N	7	2026-01-31 01:12:56.4294+00
104	14	test_number_float	test number float	3	{"maximum_digits": 10, "allowed_decimal_places": 2}	t	f	f	\N	none	\N	8	2026-01-31 01:13:23.225498+00
106	14	test_percentage	test_percentage	6	{"scale": 2, "precision": 5}	f	f	f	\N	none	\N	10	2026-01-31 01:16:23.365613+00
107	14	test_rating	test rating	7	{"max_stars": 5}	f	f	f	\N	none	\N	11	2026-01-31 01:16:48.620412+00
109	14	test_date	test date	8	{}	f	f	f	\N	none	\N	12	2026-01-31 01:26:58.462228+00
110	14	test_date_time	test date time	9	{}	f	f	f	\N	none	\N	13	2026-01-31 01:27:37.56473+00
111	14	test_time	test time	10	{}	f	f	f	\N	none	\N	14	2026-01-31 01:28:08.134989+00
112	14	test_duration	test duration	11	{}	f	f	f	\N	none	\N	15	2026-01-31 01:29:12.472905+00
113	14	test_yes_no	test_yes_no	12	{}	f	f	f	\N	none	\N	16	2026-01-31 01:31:41.755356+00
117	14	test_single_choice_custom_collection	test single choice custom collection	13	{"options": [{"label": "high", "value": "1"}, {"label": "low", "value": "2"}, {"label": "lowest", "value": "3"}], "options_mode": "custom_collection", "collection_code": ""}	f	f	f	\N	none	\N	18	2026-01-31 01:47:40.377842+00
118	14	test_multiple_choice	test multiple choice	14	{"options": [{"label": "tv", "value": "tv"}, {"label": "fridge", "value": "fridge"}, {"label": "washing machine", "value": "washing_machine"}], "options_mode": "custom_collection"}	f	f	f	\N	none	\N	19	2026-01-31 01:48:47.464841+00
119	14	test_multiple_choice_collections	test multiple choice collections	14	{"options": [], "options_mode": "collections", "collection_id": 1}	f	f	f	\N	none	\N	20	2026-01-31 01:49:26.484475+00
105	14	test_currency	test currency	5	{"maximum_digits": 10, "currency_symbol": "₹", "allowed_decimal_places": 2}	f	f	f	\N	none	\N	9	2026-01-31 01:15:53.25789+00
116	14	test_single_choice_collection	test single choice collection	13	{"options": [], "options_mode": "collections", "collection_id": 1}	f	f	f	\N	none	\N	17	2026-01-31 01:46:42.005422+00
121	14	test_email	test_email	15	{"validation_regex": "^[^@]+@[^@]+\\\\.[^@]+$"}	f	f	f	\N	none	\N	22	2026-01-31 23:15:55.060187+00
101	14	test_text	test_text	1	{"max_length": 100}	t	f	f	\N	none	\N	5	2026-01-31 01:00:30.83642+00
120	14	test_autocode	test_autocode	30	{"pattern": [{"type": "prefix", "value": "CODE"}, {"type": "separator", "value": "-"}, {"type": "date", "format": "YYYY-MM"}, {"type": "separator", "value": "-"}, {"type": "increment", "start": 1, "padding": 4}]}	f	f	f	\N	none	\N	21	2026-01-31 23:14:45.187309+00
122	14	test_phone	test phone	16	{}	f	f	f	\N	none	\N	23	2026-01-31 23:26:07.433107+00
123	14	test_website_link	test_website_link	17	{}	f	f	f	\N	none	\N	24	2026-01-31 23:26:38.491669+00
124	14	test_password	test password	18	{}	f	f	f	\N	aes	\N	25	2026-01-31 23:27:16.56047+00
125	14	test_color	test color	19	{}	f	f	f	\N	none	\N	26	2026-01-31 23:28:07.584067+00
126	14	test_image	test image	20	{"filters": [".jpg", ".png"], "multiple": false, "allow_crop": true, "crop_ratio": "1:1", "crop_shape": "circle", "max_size_mb": 2}	f	f	f	\N	none	\N	27	2026-01-31 23:29:39.47562+00
127	14	test_file	test file	21	{"filters": [".pdf", ".zip"], "multiple": false, "is_multiple": true, "max_size_mb": 2}	f	f	f	\N	none	\N	28	2026-01-31 23:30:53.250585+00
128	14	test_releative_roles	test_releative_roles	26	{"target_field": "role_id", "target_model": "roles", "relation_type": "one_to_many"}	f	f	f	\N	none	\N	29	2026-01-31 23:32:27.547648+00
129	14	test_rich_text	test rich text	27	{"content_type": "html"}	f	f	f	\N	none	\N	30	2026-01-31 23:34:08.696621+00
130	14	test_icon	test_icon	29	{"format": "prefix:name", "examples": ["fa:heart", "antd:download", "smily:thanks", "custom:myhome"]}	f	f	f	\N	none	\N	31	2026-01-31 23:34:30.19503+00
301	42	description	Description	2	{"max_line_counts": 5}	f	f	f	\N	none	\N	4	2026-02-14 22:26:10.453763+00
302	42	status	Status	13	{"options": [{"label": "Planned", "value": "planned"}, {"label": "Active", "value": "active"}, {"label": "Completed", "value": "completed"}, {"label": "Archived", "value": "archived"}], "options_mode": "custom_collection"}	f	f	f	planned	none	\N	5	2026-02-14 22:26:10.543055+00
303	42	start_date	Start Date	8	{}	f	f	f	\N	none	\N	6	2026-02-14 22:26:10.627744+00
304	42	end_date	End Date	8	{}	f	f	f	\N	none	\N	7	2026-02-14 22:26:10.693414+00
528	58	created_by	Created By	3	{}	f	f	f	\N	none	\N	2	2026-02-24 17:54:53.798552+00
305	42	created_at	Created At	9	{}	f	f	f	now()	none	\N	8	2026-02-14 22:26:10.740184+00
306	42	is_active	Is Active	12	{}	f	f	f	true	none	\N	9	2026-02-14 22:26:10.789875+00
443	51	business_id	ID	4	{}	f	f	t	\N	none	\N	1	2026-02-17 02:23:41.141058+00
444	51	created_by	Created By	3	{}	f	f	f	\N	none	\N	2	2026-02-17 02:23:41.180608+00
445	51	idate	Created Date	9	{}	t	f	f	\N	none	\N	3	2026-02-17 02:23:41.193105+00
446	51	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	4	2026-02-17 02:23:41.203617+00
447	51	name	Name	1	{"max_length": 100}	f	f	f	\N	none	\N	2	2026-02-17 02:23:53.750354+00
448	51	legal_name	Legal Name	1	{"max_length": 100}	f	f	f	\N	none	\N	3	2026-02-17 02:23:53.828414+00
449	51	industry	Industry	1	{"max_length": 100}	f	f	f	\N	none	\N	4	2026-02-17 02:23:53.894908+00
450	51	website	Website	17	{}	f	f	f	\N	none	\N	5	2026-02-17 02:23:53.958931+00
451	51	is_active	Is Active	12	{}	f	f	f	\N	none	\N	6	2026-02-17 02:23:54.032441+00
452	51	gst_number	GST Number	1	{"max_length": 100}	f	f	f	\N	none	\N	7	2026-02-17 02:23:54.104819+00
453	51	notes	Notes	2	{"max_line_counts": 3}	f	f	f	\N	none	\N	8	2026-02-17 02:23:54.16617+00
456	52	attachment_id	ID	4	{}	f	f	t	\N	none	\N	1	2026-02-17 02:27:54.586365+00
457	52	created_by	Created By	3	{}	f	f	f	\N	none	\N	2	2026-02-17 02:27:54.604837+00
458	52	idate	Created Date	9	{}	t	f	f	\N	none	\N	3	2026-02-17 02:27:54.612809+00
459	52	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	4	2026-02-17 02:27:54.620132+00
284	41	task_category_id	ID	4	{}	f	f	t	\N	none	\N	1	2026-02-14 22:05:16.030145+00
285	41	created_by	Created By	3	{}	f	f	f	\N	none	\N	2	2026-02-14 22:05:16.069576+00
286	41	idate	Created Date	9	{}	t	f	f	\N	none	\N	3	2026-02-14 22:05:16.085186+00
287	41	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	4	2026-02-14 22:05:16.096262+00
288	41	name	Name	1	{"max_length": 100}	f	f	f	\N	none	\N	3	2026-02-14 22:05:49.711553+00
289	41	description	Description	2	{"max_line_counts": 3}	f	f	f	\N	none	\N	4	2026-02-14 22:05:49.785102+00
200	39	website_or_app_url	Website or App URL	17	{}	f	f	f	\N	none	\N	8	2026-02-08 18:56:36.548075+00
332	45	task_id	ID	4	{}	f	f	t	\N	none	\N	1	2026-02-15 19:00:41.099861+00
293	41	is_active	Is Active	12	{}	f	f	f	\N	none	\N	8	2026-02-14 22:05:50.114675+00
290	41	task_type	Task Type	13	{"options": [{"label": "Life", "value": "life"}, {"label": "Work", "value": "work"}], "options_mode": "custom_collection"}	f	f	f	\N	none	\N	5	2026-02-14 22:05:49.867502+00
291	41	color	Color	19	{}	f	f	f	\N	none	\N	6	2026-02-14 22:05:49.952609+00
199	39	password	Password	18	{}	f	f	f	\N	aes	\N	6	2026-02-08 18:56:36.548075+00
529	58	idate	Created Date	9	{}	t	f	f	\N	none	\N	3	2026-02-24 17:54:53.812762+00
292	41	icon	Icon	29	{"format": "prefix:name", "examples": ["fa:heart", "antd:download", "smily:thanks", "custom:myhome"]}	f	f	f	\N	none	\N	7	2026-02-14 22:05:50.033305+00
461	52	attachment_type	Attachment Type	13	{"options": [{"label": "Document", "value": "document"}, {"label": "ID Proof", "value": "id_proof"}, {"label": "Address Proof", "value": "address_proof"}, {"label": "Photo", "value": "photo"}, {"label": "Contract", "value": "contract"}, {"label": "Certificate", "value": "certificate"}, {"label": "Other", "value": "other"}], "options_mode": "custom_collection", "collection_id": ""}	t	f	f	document	none	\N	3	2026-02-17 02:28:08.836343+00
530	58	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	4	2026-02-24 17:54:53.822138+00
294	41	order_no	Order No	3	{"maximum_digits": 10, "allowed_decimal_places": 0}	f	f	f	\N	none	\N	9	2026-02-14 22:12:05.698533+00
299	42	task_category_id	Task Category	26	{"target_field": "task_category_id", "target_model": "task_categories", "relation_type": "one_to_many"}	f	f	f	\N	none	\N	2	2026-02-14 22:26:10.286861+00
462	52	file_name	File Name	1	{"max_length": 255}	t	f	f	\N	none	\N	4	2026-02-17 02:28:08.891057+00
464	52	file_size	File Size (KB)	3	{}	f	f	f	\N	none	\N	6	2026-02-17 02:28:09.030698+00
465	52	mime_type	MIME Type	1	{"max_length": 100}	f	f	f	\N	none	\N	7	2026-02-17 02:28:09.09885+00
320	44	created_by	Created By	3	{}	f	f	f	\N	none	\N	2	2026-02-15 07:47:27.434573+00
321	44	idate	Created Date	9	{}	t	f	f	\N	none	\N	3	2026-02-15 07:47:27.449013+00
337	45	project_id	Project	26	{"target_field": "project_id", "target_model": "my_projects", "relation_type": "many_to_one", "target_model_id": 42}	f	f	f	\N	none	\N	4	2026-02-15 19:00:50.203516+00
338	45	sprint_id	Sprint	26	{"target_field": "sprint_id", "target_model": "task_sprints", "relation_type": "many_to_one"}	f	f	f	\N	none	\N	5	2026-02-15 19:00:50.28818+00
322	44	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	4	2026-02-15 07:47:27.466757+00
339	45	title	Task Title	1	{"max_length": 300}	t	f	f	\N	none	\N	6	2026-02-15 19:00:50.355569+00
340	45	description	Description	2	{"max_line_counts": 6}	f	f	f	\N	none	\N	7	2026-02-15 19:00:50.433155+00
551	58	is_default	Is Default	12	{}	f	f	f	\N	none	\N	5	2026-02-26 02:09:18.229906+00
562	60	applies_value	Applies Value	1	{"max_length": 20, "description": "specific_weekday → sun, mon, tue... specific_date → YYYY-MM-DD specific_month → 1-12\\n"}	f	f	f	\N	none	\N	8	2026-03-01 08:05:29.168411+00
344	45	priority	Priority	26	{"target_field": "priority_id", "target_model": "task_priorities", "relation_type": "many_to_one"}	f	f	f		none	\N	8	2026-02-15 19:00:50.69234+00
319	44	sprint_id	ID	4	{}	f	f	t	\N	none	\N	1	2026-02-15 07:47:27.397304+00
351	45	due_date	Due Date	8	{}	f	f	f	\N	none	\N	10	2026-02-15 19:00:51.12668+00
323	44	sprint_name	Sprint Name	1	{"max_length": 150}	t	f	f	\N	none	\N	3	2026-02-15 07:47:40.812233+00
563	60	priority_level	Priority Level	3	{"min_value": 1}	f	f	f	1	none	\N	9	2026-03-01 08:05:29.213214+00
564	60	description	Description	2	{}	f	f	f	\N	none	\N	10	2026-03-01 08:05:29.266179+00
324	44	description	Description	2	{"max_line_counts": 5}	f	f	f	\N	none	\N	4	2026-02-15 07:47:40.889651+00
325	44	goal	Sprint Goal	2	{"max_line_counts": 3}	f	f	f	\N	none	\N	5	2026-02-15 07:47:40.965996+00
326	44	start_date	Start Date	8	{}	f	f	f	\N	none	\N	6	2026-02-15 07:47:41.035292+00
327	44	end_date	End Date	8	{}	f	f	f	\N	none	\N	7	2026-02-15 07:47:41.099271+00
328	44	status	Status	13	{"options": [{"label": "Planned", "value": "planned"}, {"label": "Active", "value": "active"}, {"label": "Completed", "value": "completed"}, {"label": "Cancelled", "value": "cancelled"}], "options_mode": "custom_collection"}	f	f	f	planned	none	\N	8	2026-02-15 07:47:41.153684+00
355	45	recurrence_type	Recurrence Type	13	{"options": [{"label": "Daily", "value": "daily"}, {"label": "Weekly", "value": "weekly"}, {"label": "Monthly", "value": "monthly"}, {"label": "Yearly", "value": "yearly"}], "options_mode": "custom_collection"}	f	f	f	\N	none	\N	11	2026-02-15 19:25:01.867061+00
329	44	completed_at	Completed At	9	{}	f	f	f	\N	none	\N	9	2026-02-15 07:47:41.203898+00
330	44	is_active	Is Active	12	{}	f	f	f	true	none	\N	10	2026-02-15 07:47:41.251355+00
333	45	created_by	Created By	3	{}	f	f	f	\N	none	\N	2	2026-02-15 19:00:41.131325+00
334	45	idate	Created Date	9	{}	t	f	f	\N	none	\N	3	2026-02-15 19:00:41.143961+00
335	45	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	4	2026-02-15 19:00:41.152581+00
356	45	recurrence_interval	Recurrence Interval	3	{"min_value": 1}	f	f	f	1	none	\N	12	2026-02-15 19:25:01.937378+00
357	45	recurrence_days	Recurrence Days	14	{"options": [{"label": "Sunday", "value": "sun"}, {"label": "Monday", "value": "mon"}, {"label": "Tuesday", "value": "tue"}, {"label": "Wednesday", "value": "wed"}, {"label": "Thursday", "value": "thu"}, {"label": "Friday", "value": "fri"}, {"label": "Saturday", "value": "sat"}], "options_mode": "custom_collection"}	f	f	f	\N	none	\N	13	2026-02-15 19:25:02.011142+00
360	45	estimated_time	Estimated Time	11	{}	f	f	f	\N	none	\N	16	2026-02-15 19:25:02.23241+00
362	45	actual_time	Actual Time (Minutes)	3	{"min_value": 0}	f	f	f	\N	none	\N	18	2026-02-15 19:25:02.374611+00
352	45	scheduled_at	Scheduled At	9	{}	f	f	f	\N	none	\N	20	2026-02-15 19:00:51.192189+00
353	45	started_at	Started At	9	{}	f	f	f	\N	none	\N	21	2026-02-15 19:00:51.261431+00
354	45	completed_at	Completed At	9	{}	f	f	f	\N	none	\N	22	2026-02-15 19:00:51.332842+00
1	1	user_id	User ID	1	{"max_length": 100}	t	t	t	\N	none	\N	1	2026-01-18 00:33:45.084095+00
2	1	user_uuid	User UUID	1	{"max_length": 100}	t	t	f	\N	none	\N	2	2026-01-18 00:33:45.084095+00
13	1	last_login	Last Login	1	{"max_length": 100}	f	f	f	\N	none	\N	13	2026-01-18 00:33:45.084095+00
14	1	created_by	Created By	1	{"max_length": 100}	f	f	f	\N	none	\N	14	2026-01-18 00:33:45.084095+00
15	1	idate	Created Date	1	{"max_length": 100}	t	f	f	\N	none	\N	15	2026-01-18 00:33:45.084095+00
16	1	last_updated	Last Updated	1	{"max_length": 100}	t	f	f	\N	none	\N	16	2026-01-18 00:33:45.084095+00
34	6	group_uuid	Group UUID	1	{"max_length": 100}	t	t	f	\N	none	\N	2	2026-01-18 01:14:59.269326+00
42	7	role_uuid	Role UUID	1	{"max_length": 100}	t	t	f	\N	none	\N	2	2026-01-18 01:14:59.440739+00
52	6	group_uuid	Group UUID	1	{"max_length": 100}	t	t	f	\N	none	\N	2	2026-01-18 01:15:37.550929+00
60	9	team_uuid	Team UUID	1	{"max_length": 100}	t	t	f	\N	none	\N	2	2026-01-18 01:15:37.595914+00
70	7	role_uuid	Role UUID	1	{"max_length": 100}	t	t	f	\N	none	\N	2	2026-01-18 01:15:37.615064+00
80	11	company_uuid	Company UUID	1	{"max_length": 100}	t	t	f	\N	none	\N	2	2026-01-18 01:15:37.637979+00
86	11	branding_config	Branding Config	14	{"options": [], "options_mode": "custom_collection"}	f	f	f	\N	none	\N	8	2026-01-18 01:15:37.637979+00
98	14	created_by	Created By	3	{"maximum_digits": 10, "allowed_decimal_places": 0}	f	f	f	\N	none	\N	2	2026-01-31 00:06:26.042875+00
527	58	sound_id	ID	4	{}	f	f	t	\N	none	\N	1	2026-02-24 17:54:53.758614+00
532	58	sound_title	Sound Title	1	{"max_length": 100}	f	f	f	\N	none	\N	2	2026-02-24 18:02:03.932566+00
534	59	created_by	Created By	3	{}	f	f	f	\N	none	\N	2	2026-02-24 18:02:52.533174+00
535	59	idate	Created Date	9	{}	t	f	f	\N	none	\N	3	2026-02-24 18:02:52.543363+00
536	59	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	4	2026-02-24 18:02:52.550781+00
533	59	alarm_id	ID	4	{}	f	f	t	\N	none	\N	1	2026-02-24 18:02:52.506928+00
525	39	service_uuid	Service UUID	31	{}	f	f	f	\N	none	\N	2	2026-02-21 19:22:03.628935+00
201	39	login_handler_function	Login Handler	1	{"max_length": 100}	f	f	f	\N	none	\N	9	2026-02-08 18:56:36.548075+00
526	45	task_uuid	Task UUID	31	{}	f	f	f	\N	none	\N	2	2026-02-21 19:22:42.035278+00
537	59	entity_type	Entity Type	1	{"max_length": 50}	f	f	f	\N	none	\N	3	2026-02-24 18:06:01.879378+00
531	58	alarm_file_path	Alarm File Path	21	{"filters": [".mp3"], "multiple": false}	f	f	f	\N	none	\N	3	2026-02-24 18:01:38.874384+00
511	57	location_id	ID	4	{}	f	f	t	\N	none	\N	1	2026-02-17 03:52:41.318308+00
384	47	person_id	Person	26	{"target_field": "person_id", "target_model": "persons", "relation_type": "one_to_many"}	t	f	f	\N	none	\N	2	2026-02-17 01:36:05.698007+00
512	57	created_by	Created By	3	{}	f	f	f	\N	none	\N	2	2026-02-17 03:52:41.33824+00
513	57	idate	Created Date	9	{}	t	f	f	\N	none	\N	3	2026-02-17 03:52:41.34657+00
367	46	created_by	Created By	3	{}	f	f	f	\N	none	\N	2	2026-02-17 01:34:05.520668+00
368	46	idate	Created Date	9	{}	t	f	f	\N	none	\N	3	2026-02-17 01:34:05.533469+00
369	46	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	4	2026-02-17 01:34:05.54058+00
380	47	contact_id	ID	4	{}	f	f	t	\N	none	\N	1	2026-02-17 01:35:49.057044+00
381	47	created_by	Created By	3	{}	f	f	f	\N	none	\N	2	2026-02-17 01:35:49.083422+00
382	47	idate	Created Date	9	{}	t	f	f	\N	none	\N	3	2026-02-17 01:35:49.092275+00
383	47	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	4	2026-02-17 01:35:49.102495+00
385	47	contact_type	Contact Type	13	{"options": [{"label": "Phone", "value": "phone"}, {"label": "Email", "value": "email"}, {"label": "WhatsApp", "value": "whatsapp"}, {"label": "Website", "value": "website"}, {"label": "Other", "value": "other"}], "options_mode": "custom_collection", "collection_id": ""}	t	f	f	\N	none	\N	3	2026-02-17 01:36:05.768461+00
386	47	contact_value	Contact Value	1	{"max_length": 255}	t	f	f	\N	none	\N	4	2026-02-17 01:36:05.840005+00
387	47	label	Label	13	{"options": [{"label": "Personal", "value": "personal"}, {"label": "Work", "value": "work"}, {"label": "Emergency", "value": "emergency"}, {"label": "Other", "value": "other"}], "options_mode": "custom_collection", "collection_id": ""}	f	f	f	personal	none	\N	5	2026-02-17 01:36:05.912947+00
388	47	is_primary	Is Primary	12	{}	f	f	f	false	none	\N	6	2026-02-17 01:36:06.014403+00
389	47	is_verified	Is Verified	12	{}	f	f	f	false	none	\N	7	2026-02-17 01:36:06.114369+00
390	47	verified_at	Verified At	9	{}	f	f	f	\N	none	\N	8	2026-02-17 01:36:06.195132+00
391	47	notes	Notes	2	{"max_line_counts": 3}	f	f	f	\N	none	\N	9	2026-02-17 01:36:06.283617+00
514	57	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	4	2026-02-17 03:52:41.354052+00
515	57	city	City	1	{"max_length": 150}	t	f	f	\N	none	\N	2	2026-02-17 03:55:42.405611+00
516	57	state	State	1	{"max_length": 150}	t	f	f	\N	none	\N	3	2026-02-17 03:55:42.480791+00
517	57	country	Country	1	{"max_length": 150}	t	f	f	\N	none	\N	4	2026-02-17 03:55:42.551697+00
518	57	display_name	Display Name	1	{"max_length": 300, "auto_generate": "city + ', ' + state + ', ' + country"}	t	t	f	\N	none	\N	5	2026-02-17 03:55:42.613333+00
519	57	is_active	Is Active	12	{}	t	f	f	true	none	\N	6	2026-02-17 03:55:42.674247+00
366	46	address_id	ID	4	{}	f	f	t	\N	none	\N	1	2026-02-17 01:34:05.462413+00
371	46	address_type	Address Type	13	{"options": [{"label": "Home", "value": "home"}, {"label": "Work", "value": "work"}, {"label": "Billing", "value": "billing"}, {"label": "Shipping", "value": "shipping"}, {"label": "Other", "value": "other"}], "options_mode": "custom_collection", "collection_id": ""}	t	f	f	home	none	\N	3	2026-02-17 01:34:22.045733+00
372	46	address_line1	Address Line 1	1	{"max_length": 255}	t	f	f	\N	none	\N	4	2026-02-17 01:34:22.095703+00
373	46	address_line2	Address Line 2	1	{"max_length": 255}	f	f	f	\N	none	\N	5	2026-02-17 01:34:22.16037+00
376	46	postal_code	Postal Code	1	{"max_length": 20}	t	f	f	\N	none	\N	6	2026-02-17 01:34:22.345427+00
379	46	is_primary	Is Primary	12	{}	f	f	f	false	none	\N	9	2026-02-17 01:34:22.537331+00
195	39	id	ID	3	{"maximum_digits": 10, "allowed_decimal_places": 0}	f	f	t	\N	none	\N	1	2026-02-08 18:56:36.548075+00
196	39	service_name	Service Name	1	{"max_length": 100}	f	f	f	\N	none	\N	3	2026-02-08 18:56:36.548075+00
197	39	category	Category	1	{"max_length": 100}	f	f	f	\N	none	\N	4	2026-02-08 18:56:36.548075+00
198	39	username_or_email	Username or Email	1	{"max_length": 100}	f	f	f	\N	none	\N	5	2026-02-08 18:56:36.548075+00
364	39	additional_secrets	Additional Secrets	28	{}	f	f	f	\N	aes	\N	7	2026-02-16 18:36:56.077714+00
543	59	title	Title	1	{"max_length": 255}	f	f	f	\N	none	\N	2	2026-02-24 18:06:02.402519+00
539	59	alarm_mode	Alarm Mode	13	{"options": [{"label": "Time Based", "value": "time_based"}, {"label": "Condition Based", "value": "condition_based"}], "options_mode": "custom_collection"}	t	f	f	time_based	none	\N	5	2026-02-24 18:06:02.099429+00
540	59	scheduled_for	Scheduled For	9	{}	f	f	f	\N	none	\N	6	2026-02-24 18:06:02.17895+00
542	59	condition_json	Condition Rule	28	{}	f	f	f	\N	none	\N	7	2026-02-24 18:06:02.335364+00
544	59	message	Message	2	{"max_line_counts": 6}	f	f	f	\N	none	\N	8	2026-02-24 18:06:02.447552+00
545	59	status	Status	13	{"options": [{"label": "Pending", "value": "pending"}, {"label": "Sent", "value": "sent"}, {"label": "Failed", "value": "failed"}, {"label": "Cancelled", "value": "cancelled"}], "options_mode": "custom_collection"}	t	f	f	pending	none	\N	9	2026-02-24 18:06:02.494881+00
547	59	acknowledged_at	Acknowledged At	9	{}	f	f	f	\N	none	\N	10	2026-02-24 18:06:02.670672+00
552	60	time_id	ID	4	{}	f	f	t	\N	none	\N	1	2026-03-01 08:04:26.405408+00
553	60	created_by	Created By	3	{}	f	f	f	\N	none	\N	2	2026-03-01 08:04:26.456566+00
554	60	idate	Created Date	9	{}	t	f	f	\N	none	\N	3	2026-03-01 08:04:26.472431+00
555	60	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	4	2026-03-01 08:04:26.484982+00
556	60	slot_uuid	Slot UUID	31	{}	f	f	f	\N	none	\N	2	2026-03-01 08:05:28.71695+00
557	60	name	Slot Name	1	{"max_length": 150}	t	f	f	\N	none	\N	3	2026-03-01 08:05:28.834718+00
524	54	location	location	26	{"target_field": "location_id", "target_model": "locations", "relation_type": "one_to_many"}	f	f	f	\N	none	\N	6	2026-02-21 18:52:37.652484+00
466	52	description	Description	2	{"max_line_counts": 3}	f	f	f	\N	none	\N	8	2026-02-17 02:28:09.163616+00
460	52	person_id	Person	26	{"target_field": "person_id", "target_model": "persons", "relation_type": "many_to_one", "target_model_id": 49}	t	f	f	\N	none	\N	2	2026-02-17 02:28:08.789284+00
495	55	role_id	ID	4	{}	f	f	t	\N	none	\N	1	2026-02-17 02:47:01.904888+00
496	55	created_by	Created By	3	{}	f	f	f	\N	none	\N	2	2026-02-17 02:47:01.931436+00
497	55	idate	Created Date	9	{}	t	f	f	\N	none	\N	3	2026-02-17 02:47:01.942313+00
498	55	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	4	2026-02-17 02:47:01.949882+00
295	42	project_id	ID	4	{}	f	f	t	\N	none	\N	1	2026-02-14 22:23:43.025239+00
296	42	created_by	Created By	3	{}	f	f	f	\N	none	\N	2	2026-02-14 22:23:43.068121+00
297	42	idate	Created Date	9	{}	t	f	f	\N	none	\N	3	2026-02-14 22:23:43.082484+00
298	42	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	4	2026-02-14 22:23:43.094507+00
300	42	project_name	Project Name	1	{"max_length": 200}	t	f	f	\N	none	\N	3	2026-02-14 22:26:10.373711+00
501	55	role	Role	13	{"options": [{"label": "Owner", "value": "owner"}, {"label": "Director", "value": "director"}, {"label": "Partner", "value": "partner"}, {"label": "Shareholder", "value": "shareholder"}, {"label": "CEO", "value": "ceo"}, {"label": "CFO", "value": "cfo"}, {"label": "Manager", "value": "manager"}, {"label": "Employee", "value": "employee"}, {"label": "Consultant", "value": "consultant"}, {"label": "Authorized Signatory", "value": "authorized_signatory"}, {"label": "Other", "value": "other"}], "options_mode": "custom_collection", "collection_id": ""}	t	f	f	\N	none	\N	4	2026-02-17 02:47:14.287791+00
502	55	from_date	From Date	8	{}	t	f	f	\N	none	\N	5	2026-02-17 02:47:14.355847+00
503	55	to_date	To Date	8	{}	f	f	f	\N	none	\N	6	2026-02-17 02:47:14.422808+00
504	55	is_active	Is Active	12	{}	f	f	f	true	none	\N	7	2026-02-17 02:47:14.483061+00
505	55	ownership_percentage	Ownership Percentage	6	{"max_value": 100, "min_value": 0, "allowed_decimal_places": 2}	f	f	f	\N	none	\N	8	2026-02-17 02:47:14.530374+00
506	55	notes	Notes	2	{"max_line_counts": 3}	f	f	f	\N	none	\N	9	2026-02-17 02:47:14.579757+00
499	55	person_id	Person	26	{"target_field": "person_id", "target_model": "persons", "relation_type": "many_to_one", "target_model_id": 49}	t	f	f	\N	none	\N	2	2026-02-17 02:47:14.128354+00
500	55	business_id	Business	26	{"target_field": "business_id", "target_model": "businesses", "relation_type": "many_to_one", "target_model_id": 51}	t	f	f	\N	none	\N	3	2026-02-17 02:47:14.218023+00
520	49	person_uuid	Person UUID	31	{}	f	f	f	\N	none	\N	2	2026-02-21 18:39:51.45812+00
416	49	marital_status	Marital Status	13	{"options": [{"label": "Single", "value": "single"}, {"label": "Married", "value": "Married"}, {"label": "Divorced", "value": "divorced"}, {"label": "Widowed", "value": "widowed"}, {"label": "Separated", "value": "separated"}], "options_mode": "custom_collection", "collection_id": ""}	f	f	f	\N	none	\N	7	2026-02-17 01:47:11.790973+00
370	46	person_id	Person	26	{"target_field": "person_id", "target_model": "persons", "relation_type": "one_to_many"}	t	f	f	\N	none	\N	2	2026-02-17 01:34:21.992898+00
522	46	location	location	26	{"target_field": "location_id", "target_model": "locations", "relation_type": "one_to_many"}	f	f	f	\N	none	\N	7	2026-02-21 18:50:44.847666+00
521	46	map_location	Map Location	25	{}	f	f	f	\N	none	\N	8	2026-02-21 18:50:02.750935+00
523	54	map_location	Map Location	25	{}	f	f	f	\N	none	\N	8	2026-02-21 18:52:09.365597+00
494	54	is_primary	Is Primary	12	{}	f	f	f	false	none	\N	9	2026-02-17 02:43:14.205105+00
202	39	recovery_info	Recovery Info	2	{"max_line_counts": 3}	f	f	f	\N	aes	\N	10	2026-02-08 18:56:36.548075+00
203	39	notes	Notes	2	{"max_line_counts": 3}	f	f	f	\N	none	\N	11	2026-02-08 18:56:36.548075+00
441	50	relation_type	Relation Type	13	{"options": [{"label": "Father", "value": "father"}, {"label": "Mother", "value": "mother"}, {"label": "Son", "value": "son"}, {"label": "Daughter", "value": "daughter"}, {"label": "Brother", "value": "brother"}, {"label": "Sister", "value": "sister"}, {"label": "Spouse", "value": "spouse"}, {"label": "Grandfather", "value": "grandfather"}, {"label": "Grandmother", "value": "grandmother"}, {"label": "friend", "value": "friend"}, {"label": "colleague", "value": "colleague"}, {"label": "mother-in-law", "value": "mother-in-law"}, {"label": "father-in-law", "value": "father-in-law"}, {"label": "vendor", "value": "vendor"}, {"label": "other", "value": "other"}], "options_mode": "custom_collection", "collection_id": ""}	t	f	f	\N	none	\N	4	2026-02-17 01:55:07.499667+00
363	45	assigned_to	Assigned To	1	{"max_length": 100}	f	f	f	\N	none	\N	19	2026-02-15 19:25:02.437085+00
408	49	created_by	Created By	3	{}	f	f	f	\N	none	\N	2	2026-02-17 01:46:58.959448+00
409	49	idate	Created Date	9	{}	t	f	f	\N	none	\N	3	2026-02-17 01:46:58.966449+00
410	49	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	4	2026-02-17 01:46:58.972921+00
548	59	entity_id	Entity Id	3	{"maximum_digits": 10, "allowed_decimal_places": 0}	f	f	f	\N	none	\N	4	2026-02-24 18:08:32.207146+00
550	45	alarm_id	Alarm	26	{"target_field": "alarm_id", "target_model": "alarms", "relation_type": "one_to_many"}	f	f	f	\N	none	\N	23	2026-02-24 18:14:06.174554+00
419	50	relationship_id	ID	4	{}	f	f	t	\N	none	\N	1	2026-02-17 01:52:31.62059+00
420	50	created_by	Created By	3	{}	f	f	f	\N	none	\N	2	2026-02-17 01:52:31.665107+00
421	50	idate	Created Date	9	{}	t	f	f	\N	none	\N	3	2026-02-17 01:52:31.677999+00
422	50	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	4	2026-02-17 01:52:31.68888+00
558	60	slot_type	Slot Type	13	{"options": [{"label": "Core", "value": "core"}, {"label": "Growth", "value": "growth"}, {"label": "Operational", "value": "operational"}, {"label": "Open", "value": "open"}], "options_mode": "custom_collection"}	f	f	f	\N	none	\N	4	2026-03-01 08:05:28.907978+00
559	60	start_time	Start Time	10	{}	t	f	f	\N	none	\N	5	2026-03-01 08:05:28.981859+00
560	60	end_time	End Time	10	{}	t	f	f	\N	none	\N	6	2026-03-01 08:05:29.053186+00
561	60	applies_type	Applies Type	13	{"options": [{"label": "Everyday", "value": "everyday"}, {"label": "Specific Weekday", "value": "specific_weekday"}, {"label": "Specific Date", "value": "specific_date"}, {"label": "Specific Month", "value": "specific_month"}], "options_mode": "custom_collection"}	f	f	f	\N	none	\N	7	2026-03-01 08:05:29.115456+00
442	50	notes	Notes	2	{"max_line_counts": 3}	f	f	f	\N	none	\N	5	2026-02-17 01:55:07.544987+00
439	50	person_id	Person	26	{"target_field": "person_id", "target_model": "persons", "relation_type": "many_to_one", "target_model_id": 49}	t	f	f	\N	none	\N	2	2026-02-17 01:55:07.38948+00
440	50	related_person_id	Related Person	26	{"target_field": "person_id", "target_model": "persons", "relation_type": "many_to_one", "target_model_id": 49}	t	f	f	\N	none	\N	3	2026-02-17 01:55:07.456573+00
469	53	contact_id	ID	4	{}	f	f	t	\N	none	\N	1	2026-02-17 02:40:08.131424+00
470	53	created_by	Created By	3	{}	f	f	f	\N	none	\N	2	2026-02-17 02:40:08.164579+00
471	53	idate	Created Date	9	{}	t	f	f	\N	none	\N	3	2026-02-17 02:40:08.174266+00
472	53	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	4	2026-02-17 02:40:08.181363+00
473	53	business_id	Business	26	{"target_field": "id", "target_model": "businesses", "relation_type": "many_to_one", "target_model_id": 51}	t	f	f	\N	none	\N	2	2026-02-17 02:40:16.880366+00
474	53	contact_type	Contact Type	13	{"options": [{"label": "Phone", "value": "phone"}, {"label": "Email", "value": "email"}, {"label": "WhatsApp", "value": "whatsapp"}, {"label": "Website", "value": "website"}, {"label": "Other", "value": "other"}], "options_mode": "custom_collection", "collection_id": ""}	t	f	f	\N	none	\N	3	2026-02-17 02:40:16.928238+00
475	53	contact_value	Contact Value	1	{"max_length": 255}	t	f	f	\N	none	\N	4	2026-02-17 02:40:16.976262+00
476	53	label	Label	13	{"options": [{"label": "Head Office", "value": "head_office"}, {"label": "Branch", "value": "branch"}, {"label": "Accounts", "value": "accounts"}, {"label": "Support", "value": "support"}, {"label": "Sales", "value": "sales"}, {"label": "Other", "value": "other"}], "options_mode": "custom_collection", "collection_id": ""}	f	f	f	work	none	\N	5	2026-02-17 02:40:17.029806+00
477	53	is_primary	Is Primary	12	{}	f	f	f	false	none	\N	6	2026-02-17 02:40:17.080588+00
478	53	is_verified	Is Verified	12	{}	f	f	f	false	none	\N	7	2026-02-17 02:40:17.140787+00
479	53	verified_at	Verified At	9	{}	f	f	f	\N	none	\N	8	2026-02-17 02:40:17.216035+00
480	53	notes	Notes	2	{"max_line_counts": 3}	f	f	f	\N	none	\N	9	2026-02-17 02:40:17.274282+00
482	54	created_by	Created By	3	{}	f	f	f	\N	none	\N	2	2026-02-17 02:43:03.923967+00
483	54	idate	Created Date	9	{}	t	f	f	\N	none	\N	3	2026-02-17 02:43:03.931522+00
484	54	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	4	2026-02-17 02:43:03.9383+00
407	49	person_id	ID	4	{}	f	f	t	\N	none	\N	1	2026-02-17 01:46:58.940576+00
411	49	name	Name	1	{"max_length": 100}	f	f	f	\N	none	\N	3	2026-02-17 01:47:11.545306+00
412	49	alias_names	Alias Names	2	{"max_line_counts": 3}	f	f	f	\N	none	\N	4	2026-02-17 01:47:11.613382+00
414	49	dob	DOB	8	{}	f	f	f	\N	none	\N	6	2026-02-17 01:47:11.706639+00
417	49	anniversary_date	Anniversary Date	8	{}	f	f	f	\N	none	\N	8	2026-02-17 01:47:11.837102+00
418	49	notes	Notes	2	{"max_line_counts": 3}	f	f	f	\N	none	\N	9	2026-02-17 01:47:11.893725+00
481	54	address_id	ID	4	{}	f	f	t	\N	none	\N	1	2026-02-17 02:43:03.907194+00
485	54	business_id	Business	26	{"target_field": "id", "target_model": "businesses", "relation_type": "many_to_one", "target_model_id": 51}	t	f	f	\N	none	\N	2	2026-02-17 02:43:13.688692+00
486	54	address_type	Address Type	13	{"options": [{"label": "Head Office", "value": "head_office"}, {"label": "Branch", "value": "branch"}, {"label": "Billing", "value": "billing"}, {"label": "Shipping", "value": "shipping"}, {"label": "Registered Office", "value": "registered_office"}, {"label": "Other", "value": "other"}], "options_mode": "custom_collection", "collection_id": ""}	t	f	f	head_office	none	\N	3	2026-02-17 02:43:13.766899+00
487	54	address_line1	Address Line 1	1	{"max_length": 255}	t	f	f	\N	none	\N	4	2026-02-17 02:43:13.832003+00
488	54	address_line2	Address Line 2	1	{"max_length": 255}	f	f	f	\N	none	\N	5	2026-02-17 02:43:13.889175+00
491	54	postal_code	Postal Code	1	{"max_length": 20}	t	f	f	\N	none	\N	7	2026-02-17 02:43:14.023577+00
336	45	task_category_id	Task Category	26	{"target_field": "task_category_id", "target_model": "task_categories", "relation_type": "many_to_one", "target_model_id": 41}	f	f	f	\N	none	\N	3	2026-02-15 19:00:50.120218+00
361	45	timebox	Timebox	11	{}	f	f	f	\N	none	\N	17	2026-02-15 19:25:02.307386+00
413	49	profile_photo	Profile photo	20	{"filters": [".jpg", ".png", ".jpeg"], "multiple": false, "allow_crop": true, "crop_ratio": "1:1", "crop_shape": "circle", "max_size_mb": 2, "generate_thumbnail": true}	f	f	f	\N	none	\N	5	2026-02-17 01:47:11.663944+00
566	45	person_id	Person Id	26	{"target_field": "person_id", "target_model": "persons", "relation_type": "many_to_one"}	f	f	f	\N	none	\N	25	2026-03-01 10:37:06.970522+00
567	45	business_id	Business Id	26	{"target_field": "business_id", "target_model": "businesses", "relation_type": "many_to_one"}	f	f	f	\N	none	\N	26	2026-03-01 16:49:08.767358+00
569	61	created_by	Created By	3	{}	f	f	f	\N	none	\N	2	2026-03-02 19:27:52.178839+00
570	61	idate	Created Date	9	{}	t	f	f	\N	none	\N	3	2026-03-02 19:27:52.193101+00
571	61	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	4	2026-03-02 19:27:52.201491+00
568	61	comment_id	ID	4	{}	f	f	t	\N	none	\N	1	2026-03-02 19:27:52.14372+00
572	61	task	Task	26	{"target_field": "task_id", "target_model": "my_tasks", "relation_type": "one_to_many"}	f	f	f	\N	none	\N	2	2026-03-02 19:29:38.782415+00
574	61	comment_title	Comment Title	1	{"max_length": 100}	f	f	f	\N	none	\N	3	2026-03-02 19:31:41.985558+00
573	61	message	Message	27	{"content_type": "markdown"}	f	f	f	\N	none	\N	4	2026-03-02 19:30:21.091413+00
575	62	attachment_id	ID	4	{}	f	f	t	\N	none	\N	1	2026-03-02 19:32:53.374843+00
576	62	created_by	Created By	3	{}	f	f	f	\N	none	\N	2	2026-03-02 19:32:53.430342+00
577	62	idate	Created Date	9	{}	t	f	f	\N	none	\N	3	2026-03-02 19:32:53.449209+00
578	62	last_updated	Last Updated	9	{}	t	f	f	\N	none	\N	4	2026-03-02 19:32:53.460876+00
579	62	attachment_uuid	attachment_uuid	31	{}	f	f	f	\N	none	\N	5	2026-03-02 19:33:23.802251+00
581	62	attachment_title	Attachment Title	1	{"max_length": 100}	f	f	f	\N	none	\N	6	2026-03-02 19:35:31.678473+00
583	62	task	task	26	{"target_field": "task_id", "target_model": "my_tasks", "relation_type": "one_to_many"}	f	f	f	\N	none	\N	8	2026-03-03 17:32:59.710921+00
582	62	file_path	File Path	21	{"filters": [".pdf", ".doc", ".docx", ".tsv", ".xls", ".xlsx", ".txt", ".csv", ".jpg", ".png", ".gif"], "multiple": false, "generate_thumbnail": true}	f	f	f	\N	none	\N	7	2026-03-02 19:36:25.520066+00
591	14	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	32	2026-03-07 08:50:49.227364+00
592	1	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	17	2026-03-07 08:50:49.227364+00
593	6	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	9	2026-03-07 08:50:49.227364+00
594	7	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	11	2026-03-07 08:50:49.227364+00
595	9	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	11	2026-03-07 08:50:49.227364+00
596	11	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	15	2026-03-07 08:50:49.227364+00
597	60	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	11	2026-03-07 08:50:49.227364+00
598	61	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	5	2026-03-07 08:50:49.227364+00
599	62	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	9	2026-03-07 08:50:49.227364+00
600	39	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	12	2026-03-07 08:50:49.227364+00
601	40	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	10	2026-03-07 08:50:49.227364+00
602	41	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	10	2026-03-07 08:50:49.227364+00
603	42	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	10	2026-03-07 08:50:49.227364+00
604	44	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	11	2026-03-07 08:50:49.227364+00
605	45	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	27	2026-03-07 08:50:49.227364+00
606	46	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	10	2026-03-07 08:50:49.227364+00
607	47	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	10	2026-03-07 08:50:49.227364+00
608	49	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	10	2026-03-07 08:50:49.227364+00
609	50	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	6	2026-03-07 08:50:49.227364+00
610	51	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	9	2026-03-07 08:50:49.227364+00
611	52	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	11	2026-03-07 08:50:49.227364+00
612	53	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	10	2026-03-07 08:50:49.227364+00
613	54	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	10	2026-03-07 08:50:49.227364+00
614	55	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	10	2026-03-07 08:50:49.227364+00
615	57	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	7	2026-03-07 08:50:49.227364+00
616	59	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	11	2026-03-07 08:50:49.227364+00
617	58	row_exposure_mode_id	Row Exposure Mode	3	{}	f	f	f	\N	none	\N	6	2026-03-07 08:50:49.227364+00
463	52	file	File	21	{"filters": [".pdf", ".doc", ".docx", ".tsv", ".xls", ".xlsx", ".txt", ".csv", ".jpg", ".png", ".gif"], "multiple": false, "generate_thumbnail": true}	t	f	f	\N	aes	\N	5	2026-02-17 02:28:08.960187+00
345	45	status	Status	13	{"options": [{"label": "Inbox", "value": "inbox"}, {"label": "Clarified", "value": "clarified"}, {"label": "Scheduled", "value": "scheduled"}, {"label": "In Progress", "value": "in_progress"}, {"label": "Waiting", "value": "waiting"}, {"label": "Completed", "value": "completed"}, {"label": "Cancelled", "value": "cancelled"}, {"label": "Backlog", "value": "backlog"}], "options_mode": "custom_collection", "collection_id": ""}	f	f	f	inbox	none	\N	9	2026-02-15 19:00:50.739233+00
\.


--
-- Data for Name: data_models; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.data_models (model_id, model_uuid, app_id, model_name, display_name, table_name, is_public, is_system_model, is_active, description, created_by, idate, last_updated, table_alias, model_scope) FROM stdin;
14	eec58720-7d8a-49b9-97bd-c71175e1a2a1	\N	products	products	products	f	f	t	\N	2	2026-01-31 00:06:25.832581+00	2026-01-31 00:06:25.832581+00	p	saas
1	da70d8e4-da66-45a1-8195-d357f2aa5a00	5	users	Users	users	f	t	t	User management table - stores user accounts and authentication information	1	2026-01-18 00:33:45.084095+00	2026-01-18 00:33:45.084095+00	u	saas
6	bfc3ed66-459e-4db5-8cc0-19ec28ffe6a2	5	user_groups	User Groups	user_groups	f	t	t	User groups table - organizes users into groups within a company	1	2026-01-18 01:14:59.269326+00	2026-01-18 01:14:59.269326+00	ug	saas
7	73a08e4d-2faf-4216-8f44-f179f7c64b38	5	roles	Roles	roles	f	t	t	Roles table - defines role-based access control roles	1	2026-01-18 01:14:59.440739+00	2026-01-18 01:14:59.440739+00	r	saas
9	ca3b0fa1-08e2-4d48-9fbe-ca60beb3914c	5	teams	Teams	teams	f	t	t	Teams table - organizes users into teams with hierarchy and management	1	2026-01-18 01:15:37.595914+00	2026-01-18 01:15:37.595914+00	t	saas
11	3245e49b-28f5-4e1e-8da4-398a524326fc	5	companies	Companies	companies	f	t	t	Companies table - manages company/organization entities within tenants	1	2026-01-18 01:15:37.637979+00	2026-01-18 01:15:37.637979+00	c	saas
60	7c683665-07c4-44c1-a934-b9e9b6af7d8d	\N	time_slots	Time Slots	time_slots	f	f	t	time_slots = personal boundary definition (24-hour model)\n- core        # Never disturb (sleep, health, family, deep focus)\n- growth      # Important but movable (learning, planning)\n- operational # Daily maintenance (work admin, errands)\n- open        # Free / social / flexible	2	2026-03-01 08:04:26.122919+00	2026-03-01 08:04:26.122919+00	tt	saas
61	d7be0513-2f37-4d6b-b801-759d57d72480	\N	task_comments	Task Comments	task_comments	f	f	t	to store comments related to task	2	2026-03-02 19:27:51.940632+00	2026-03-02 19:27:51.940632+00	tcm	saas
62	63cf83c0-9524-4bf0-b265-b36706023c79	\N	task_attachments	Task Attachments	task_attachments	f	f	t	\N	2	2026-03-02 19:32:53.295037+00	2026-03-02 19:32:53.295037+00	ta	saas
39	c042736a-d20a-41a0-88a2-85d0736819d2	\N	password_vault	Password Vault	password_vault	f	f	t	pk manager	\N	2026-02-08 18:56:36.545076+00	2026-02-14 08:18:46.351275+00	\N	saas
40	3a453f11-9fd0-4678-bd16-0e8e807767df	\N	task_priorities	Task Priorities	task_priorities	f	f	t	pk manager	2	2026-02-14 20:54:20.181459+00	2026-02-14 20:54:20.181459+00	tp	saas
41	0f4ac677-9b29-4942-a952-25e4c83cf8aa	\N	task_categories	Task Categories	task_categories	f	f	t	pk manager	2	2026-02-14 22:05:15.871756+00	2026-02-14 22:05:15.871756+00	tc	saas
42	5ba726a4-7ae0-4086-ab57-41f05303036e	\N	my_projects	My Projects	my_projects	f	f	t	pk manager	2	2026-02-14 22:23:42.914072+00	2026-02-14 22:23:42.914072+00	mp	saas
44	04e0399b-1c0f-4c60-bac7-e506ccd476b8	\N	task_sprints	Task Sprints	task_sprints	f	f	t	pk manager	2	2026-02-15 07:47:27.346732+00	2026-02-15 07:47:27.346732+00	ts	saas
45	e8df8e89-c6a0-41f0-bfb8-6ae888aec7e7	\N	my_tasks	My Tasks	my_tasks	f	f	t	\N	2	2026-02-15 19:00:41.009103+00	2026-02-15 19:00:41.009103+00	mt	saas
46	5a76fbba-284f-48e2-8935-2cc11e718f20	\N	person_addresses	Person Addresses	person_addresses	f	f	t	\N	2	2026-02-17 01:34:05.324179+00	2026-02-17 01:34:05.324179+00	a	saas
47	6181b9aa-f840-4729-a86a-20b8ed361da5	\N	person_contacts	Person Contacts	person_contacts	f	f	t	pk manager	2	2026-02-17 01:35:49.006818+00	2026-02-17 01:35:49.006818+00	pc	saas
49	c316b105-fe59-4637-a326-516c0a26a76d	\N	persons	Persons	persons	f	f	t	pk manager	2	2026-02-17 01:46:58.904342+00	2026-02-17 01:46:58.904342+00	ps	saas
50	3ca3647c-8719-41a1-8408-57bac852f1fc	\N	person_relationships	Person relationships	person_relationships	f	f	t	pk manager	2	2026-02-17 01:52:31.566703+00	2026-02-17 01:52:31.566703+00	pr	saas
51	ee402ef4-6bbe-4d41-b151-8349150bd0c2	\N	businesses	Businesses	businesses	f	f	t	pk manager	2	2026-02-17 02:23:41.075064+00	2026-02-17 02:23:41.075064+00	bs	saas
52	d0866961-326d-469c-91c6-d7c601075dd7	\N	person_attachments	Person Attachments	person_attachments	f	f	t	pk manager	2	2026-02-17 02:27:54.545845+00	2026-02-17 02:27:54.545845+00	pa	saas
53	eb974857-3cdc-47f8-ba5f-9c984fe66650	\N	business_contacts	Business Contacts	business_contacts	f	f	t	pk manager	2	2026-02-17 02:40:08.026268+00	2026-02-17 02:40:08.026268+00	bc	saas
54	231ed024-956b-47ac-8838-bdf9afe37025	\N	business_addresses	Business Addresses	business_addresses	f	f	t	pk manager	2	2026-02-17 02:43:03.86844+00	2026-02-17 02:43:03.86844+00	ba	saas
55	7f749e78-7bc6-4142-a9c7-d84bfc190a5e	\N	person_business_roles	Person Business Roles	person_business_roles	f	f	t	pk manager	2	2026-02-17 02:47:01.84665+00	2026-02-17 02:47:01.84665+00	br	saas
57	9fcc780c-207f-4acc-a427-0a851653a79d	\N	locations	Locations	locations	f	f	t	pk manager	2	2026-02-17 03:52:41.267089+00	2026-02-17 03:52:41.267089+00	l	saas
59	08957260-2864-4033-a075-521959440006	\N	alarms	Alarms	alarms	f	f	t	pk manager	2	2026-02-24 18:02:52.450084+00	2026-02-24 18:02:52.450084+00	al	saas
58	4d6abfbd-ba9d-4f22-aac2-01713a5c0d9b	\N	alarm_sounds	Alarm Sounds	alarm_sounds	f	f	t	pk manager	2	2026-02-24 17:54:53.552186+00	2026-02-26 02:01:11.201147+00	ass	saas
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
5	Currency	currency	advanced	NUMERIC	8	{"maximum_digits": 10, "currency_symbol": "₹", "allowed_decimal_places": 2}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_currency.svg	5
13	Single Choice	single_choice	advanced	VARCHAR	6	{"options": [], "options_mode": "custom_collection", "collection_id": ""}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_single_choice.svg	13
30	Auto Code	auto_code	advanced	VARCHAR	6	{"pattern": [{"type": "prefix", "value": "CODE"}, {"type": "separator", "value": "-"}, {"type": "date", "format": "YYYY-MM"}, {"type": "separator", "value": "-"}, {"type": "increment", "start": 1, "padding": 4}]}	\N	t	2026-01-19 00:56:42.607067+00	field_types/field_type_auto_code.svg	15
26	Relative Field	relation	relational	INTEGER	9	{"target_model": null, "relation_type": "one_to_many"}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_relation.svg	27
27	Rich Text	rich_text	advanced	TEXT	7	{"content_type": "markdown"}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_rich_text.svg	28
28	JSON	json	advanced	JSONB	7	{}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_json.svg	29
29	Icon	icon	media	VARCHAR	9	{"format": "prefix:name", "examples": ["fa:heart", "antd:download", "smily:thanks", "custom:myhome"]}	icon	t	2026-01-18 17:53:48.668856+00	field_types/field_type_icon.svg	30
15	Email Address	email	basic	VARCHAR	6	{"validation_regex": "^[^@]+@[^@]+\\\\.[^@]+$"}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_email.svg	16
16	Phone Number	phone	basic	VARCHAR	6	{}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_phone.svg	17
17	Website Link	url	basic	VARCHAR	6	{}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_url.svg	18
18	Password	password	advanced	VARCHAR	6	{}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_password.svg	19
19	Color	color	advanced	VARCHAR	6	{}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_color.svg	20
20	Image	image	media	VARCHAR	14	{"multiple": false}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_image.svg	21
21	File	file	media	VARCHAR	14	{"multiple": false}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_file.svg	22
22	Video	video	media	VARCHAR	14	{}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_video.svg	23
23	Audio	audio	media	VARCHAR	14	{"storage_provider": "s3"}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_audio.svg	24
24	Address	address	advanced	JSONB	4	{"fields": ["street", "city", "zip", "country"]}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_address.svg	25
25	Map Location	location	advanced	POINT	6	{}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_location.svg	26
3	Number	number	basic	NUMERIC	8	{"maximum_digits": 10, "allowed_decimal_places": 0}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_number.svg	3
1	Text	text	basic	VARCHAR	6	{"max_length": 100}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_text.svg	1
2	Paragraph	paragraph	basic	TEXT	7	{"max_line_counts": 3}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_paragraph.svg	2
14	Multiple Choice	multi_choice	basic	TEXT[]	9	{"options": [], "options_mode": "custom_collection"}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_multi_choice.svg	14
4	Auto Number	auto_number	advanced	SERIAL	15	{}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_auto_number.svg	4
6	Percentage	percentage	advanced	NUMERIC	8	{"scale": 2, "precision": 5}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_percentage.svg	6
7	Rating	rating	advanced	INTEGER	8	{"max_stars": 5}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_rating.svg	7
8	Date	date	basic	DATE	10	{}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_date.svg	8
10	Time	time	basic	TIME	10	{}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_time.svg	10
11	Duration	duration	advanced	INTERVAL	6	{}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_duration.svg	11
12	Yes/No	boolean	basic	BOOLEAN	11	{}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_boolean.svg	12
9	DateTime	datetime	basic	TIMESTAMPTZ	10	{}	\N	t	2026-01-15 23:29:03.114175+00	field_types/field_type_datetime.svg	9
31	Auto UUID	auto_uuid	advanced	UUID	15	{}	\N	t	2026-02-17 05:03:28.503414+00	field_types/field_type_auto_number.svg	5
\.


--
-- Data for Name: icons; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.icons (icon_id, icon_uuid, icon_code, icon_type, icon_name, category, description, tags, icon_data, usage_count, is_popular, is_free, is_active, created_by, created_at, last_updated) FROM stdin;
1	c50397a5-d043-4791-8888-bc506d4175e4	fa:home	fa	Home	navigation	Home icon	{home,house,main,dashboard}	{"class": "fas fa-home"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
2	aef58295-76db-47aa-b492-856e0bb971f8	fa:user	fa	User	users	User profile icon	{user,person,profile,account}	{"class": "fas fa-user"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
3	165ba39f-16f3-475a-beda-eb0907e28ea7	fa:users	fa	Users	users	Multiple users icon	{users,people,team,group}	{"class": "fas fa-users"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
4	7c117ced-6868-41d7-8104-a1880ef1c8e7	fa:cog	fa	Settings	settings	Settings/gear icon	{settings,gear,config,preferences}	{"class": "fas fa-cog"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
5	51067c60-bbb5-4a0f-9fd7-d5a930ca455e	fa:search	fa	Search	actions	Search icon	{search,find,magnify}	{"class": "fas fa-search"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
6	0df02935-4491-4e66-88d9-3df4a9f027cf	fa:bell	fa	Notifications	notifications	Bell/notification icon	{bell,notification,alert}	{"class": "fas fa-bell"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
7	052c0c21-23c4-4463-9035-43c248147021	fa:heart	fa	Heart	social	Heart/like icon	{heart,like,love,favorite}	{"class": "fas fa-heart"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
8	08adfa05-02b7-4e84-8042-9c0c085a82d4	fa:star	fa	Star	ratings	Star icon	{star,favorite,rating}	{"class": "fas fa-star"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
9	bec768c6-768b-4b51-897f-59b68062297a	fa:envelope	fa	Email	communication	Email/envelope icon	{email,mail,message}	{"class": "fas fa-envelope"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
10	24f283b0-afd7-4aed-8b1b-23181e059a5a	fa:phone	fa	Phone	communication	Phone icon	{phone,call,telephone}	{"class": "fas fa-phone"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
11	fe629972-de72-4909-9d4e-b423042fad54	fa:plus	fa	Add	actions	Plus/add icon	{add,plus,new,create}	{"class": "fas fa-plus"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
12	5a3ff3ca-1eea-48f1-a873-78d620c42590	fa:edit	fa	Edit	actions	Edit/pencil icon	{edit,modify,pencil,update}	{"class": "fas fa-edit"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
13	46a72879-e5f6-4889-a5ec-c227afefbf1c	fa:trash	fa	Delete	actions	Delete/trash icon	{delete,trash,remove}	{"class": "fas fa-trash"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
14	f78f48c1-9a5e-45b0-b01a-8c8e79d7eb3e	fa:save	fa	Save	actions	Save icon	{save,store,disk}	{"class": "fas fa-save"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
15	1c86b441-40a9-4c65-9bc3-d45c2a681b0b	fa:download	fa	Download	actions	Download icon	{download,get,export}	{"class": "fas fa-download"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
16	9164ff91-d1c2-4ff1-92fa-6be97d7a79e0	fa:upload	fa	Upload	actions	Upload icon	{upload,send,import}	{"class": "fas fa-upload"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
17	d63687d2-b897-4df2-9bcb-08acb2c0bebb	fa:check	fa	Check	actions	Checkmark icon	{check,done,success,approve}	{"class": "fas fa-check"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
18	a11991a0-cd3c-4ead-b25c-e0cab7c8ea29	fa:times	fa	Close	actions	Close/cancel icon	{close,cancel,times,x}	{"class": "fas fa-times"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
19	58e668b5-9c9e-443f-b365-ff9fc7f05607	fa:database	fa	Database	data	Database icon	{database,data,storage}	{"class": "fas fa-database"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
20	ce103cda-1bfd-4166-81ee-ddecc8b66f90	fa:chart-bar	fa	Chart	data	Bar chart icon	{chart,graph,analytics,statistics}	{"class": "fas fa-chart-bar"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
21	574d1527-3147-4094-8e18-6a147956a8e0	fa:file	fa	File	documents	File icon	{file,document}	{"class": "fas fa-file"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
22	14cccd52-591a-47c5-9b18-f32a4ad2e679	fa:folder	fa	Folder	documents	Folder icon	{folder,directory}	{"class": "fas fa-folder"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
23	869c9be7-f4e1-44c3-8c8e-3c51d0c96063	fa:building	fa	Building	business	Building/company icon	{building,company,office}	{"class": "fas fa-building"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
24	da55492d-8c67-4e5d-96b3-e504e933484a	fa:briefcase	fa	Briefcase	business	Briefcase/business icon	{briefcase,business,work}	{"class": "fas fa-briefcase"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
25	5ce958a7-919c-4468-859e-5bab89cb9bbf	fa:arrow-left	fa	Arrow Left	navigation	Left arrow icon	{arrow,left,back,previous}	{"class": "fas fa-arrow-left"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
26	6b550208-7c76-4110-bbaf-71f99d042f07	fa:arrow-right	fa	Arrow Right	navigation	Right arrow icon	{arrow,right,next,forward}	{"class": "fas fa-arrow-right"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
27	43a5be3f-1df1-4a23-a256-197907774cb7	fa:arrow-up	fa	Arrow Up	navigation	Up arrow icon	{arrow,up,top}	{"class": "fas fa-arrow-up"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
28	e9ff0a0e-11a8-4cca-8ec7-46b20c2c6bd0	fa:arrow-down	fa	Arrow Down	navigation	Down arrow icon	{arrow,down,bottom}	{"class": "fas fa-arrow-down"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
29	20122d51-1201-476e-9cee-b934c1a6ca43	fa:facebook	fa	Facebook	social	Facebook icon	{facebook,social,fb}	{"class": "fab fa-facebook"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
30	11dbbbf1-7c72-4973-810b-9457746314f0	fa:twitter	fa	Twitter	social	Twitter icon	{twitter,social,tweet}	{"class": "fab fa-twitter"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
31	f3d44fe5-33e9-45e2-bf69-711ed74f5cf1	fa:linkedin	fa	LinkedIn	social	LinkedIn icon	{linkedin,social,professional}	{"class": "fab fa-linkedin"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
32	945f2ecb-ec3c-468b-b5e4-0d53a1a194c3	fa:instagram	fa	Instagram	social	Instagram icon	{instagram,social,ig}	{"class": "fab fa-instagram"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
33	6a41c9d1-c389-4ebb-9d7b-25a403057d0e	fa:lock	fa	Lock	security	Lock/security icon	{lock,security,protected}	{"class": "fas fa-lock"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
34	f5f68719-74fc-48f1-be97-777e746cd9de	fa:unlock	fa	Unlock	security	Unlock icon	{unlock,open,access}	{"class": "fas fa-unlock"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
35	6861b789-aafb-4733-8b52-baa4e0386319	fa:shield	fa	Shield	security	Shield/security icon	{shield,security,protection}	{"class": "fas fa-shield-alt"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
36	8f9388c9-457c-4ecd-b2f3-0337543d8bdf	fa:key	fa	Key	security	Key icon	{key,access,permission}	{"class": "fas fa-key"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
37	2a3c3f2c-765a-484b-a01c-accb7b0401bf	fa:check-circle	fa	Success	status	Success/check circle icon	{success,check,done,complete}	{"class": "fas fa-check-circle"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
74	9c76f958-59a5-45f6-ad1a-29208c31d33f	smily:fire	smily	Fire	emotions	Fire emoji	{fire,hot,🔥}	{"emoji": "🔥", "unicode": "U+1F525"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
38	ce2ed2e7-5bde-45b3-be73-d4d57e72d4e9	fa:exclamation-circle	fa	Warning	status	Warning icon	{warning,alert,caution}	{"class": "fas fa-exclamation-circle"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
39	bb07a1b6-5cd1-4886-8775-6fdcc3f1ee0b	fa:times-circle	fa	Error	status	Error/close circle icon	{error,close,fail}	{"class": "fas fa-times-circle"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
40	fc10c324-a5c6-4408-9f69-388e85869461	fa:info-circle	fa	Info	status	Information icon	{info,information,help}	{"class": "fas fa-info-circle"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
41	1db45012-86a7-4680-ae12-bbd6079eeefb	antd:home	antd	Home	navigation	Home icon (Ant Design)	{home,house,main}	{"component": "HomeOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
42	d308ea30-39c4-48f3-aa04-ef367bb046e6	antd:user	antd	User	users	User icon (Ant Design)	{user,person,profile}	{"component": "UserOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
43	b5e44453-3057-4ac4-a89b-8f41ee164f58	antd:users	antd	Users	users	Users icon (Ant Design)	{users,people,team}	{"component": "UsergroupAddOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
44	63e159e2-3aae-4d4f-8a29-248a863c7c1a	antd:setting	antd	Settings	settings	Settings icon (Ant Design)	{settings,config}	{"component": "SettingOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
45	5522894a-6ae5-4b4f-ad9a-227b97bfd942	antd:search	antd	Search	actions	Search icon (Ant Design)	{search,find}	{"component": "SearchOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
46	d66ee2f9-f6af-40f6-a98b-679f055a726f	antd:bell	antd	Notifications	notifications	Bell icon (Ant Design)	{bell,notification}	{"component": "BellOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
47	db6031fb-415f-4cc6-9734-4f9f9dd7940e	antd:heart	antd	Heart	social	Heart icon (Ant Design)	{heart,like}	{"component": "HeartOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
48	ef987f07-3ffe-4932-8868-43be9790833e	antd:star	antd	Star	ratings	Star icon (Ant Design)	{star,favorite}	{"component": "StarOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
49	218243f5-d2f3-4c9d-bd69-2b4d639a9ec0	antd:plus	antd	Add	actions	Plus icon (Ant Design)	{add,plus,new}	{"component": "PlusOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
50	534f120a-1999-44f1-9935-81c5d2456c2d	antd:edit	antd	Edit	actions	Edit icon (Ant Design)	{edit,modify}	{"component": "EditOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
51	cb0923ff-ea0b-4981-af14-425cbb5ad7f5	antd:delete	antd	Delete	actions	Delete icon (Ant Design)	{delete,remove}	{"component": "DeleteOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
52	f626d4da-719d-4760-abe7-11c31a0af925	antd:save	antd	Save	actions	Save icon (Ant Design)	{save,store}	{"component": "SaveOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
53	0990106c-0e82-4664-9d24-5de3f3b52f40	antd:download	antd	Download	actions	Download icon (Ant Design)	{download,export}	{"component": "DownloadOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
54	1bcf301a-b430-4c88-9892-001026e45639	antd:upload	antd	Upload	actions	Upload icon (Ant Design)	{upload,import}	{"component": "UploadOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
55	a41f1da4-bb25-4632-9ec5-1c6a86d4fcba	antd:check	antd	Check	actions	Check icon (Ant Design)	{check,done}	{"component": "CheckOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
56	faebaaad-8827-40ed-8531-2ac224202142	antd:close	antd	Close	actions	Close icon (Ant Design)	{close,cancel}	{"component": "CloseOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
57	8851c046-2099-46f9-9411-7d6a144161da	antd:database	antd	Database	data	Database icon (Ant Design)	{database,data}	{"component": "DatabaseOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
58	580735ff-fa24-479d-abfe-355b99c906c8	antd:file	antd	File	documents	File icon (Ant Design)	{file,document}	{"component": "FileOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
59	378b08c9-7f0c-4f0a-b7d8-3eed42b0a98d	antd:folder	antd	Folder	documents	Folder icon (Ant Design)	{folder,directory}	{"component": "FolderOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
60	e9db258e-4ccd-4c17-816a-f2fbceb61369	antd:appstore	antd	App Store	navigation	App store icon (Ant Design)	{app,store,grid}	{"component": "AppstoreOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
61	4c323254-1aa6-4a01-88c7-7b4848e4b5ff	antd:arrow-left	antd	Arrow Left	navigation	Left arrow (Ant Design)	{arrow,left,back}	{"component": "ArrowLeftOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
62	71d8b4c8-b0dd-457f-846b-1f67853480c8	antd:arrow-right	antd	Arrow Right	navigation	Right arrow (Ant Design)	{arrow,right,next}	{"component": "ArrowRightOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
63	0d3439e3-c20b-4a53-97a0-d80b42a8a44f	antd:arrow-up	antd	Arrow Up	navigation	Up arrow (Ant Design)	{arrow,up}	{"component": "ArrowUpOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
64	576ddf71-4595-4259-b275-e253fedcf6f3	antd:arrow-down	antd	Arrow Down	navigation	Down arrow (Ant Design)	{arrow,down}	{"component": "ArrowDownOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
65	2ba402a0-52c9-4226-8eca-1857860a160b	antd:check-circle	antd	Success	status	Success icon (Ant Design)	{success,check}	{"component": "CheckCircleOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
66	77a619ae-f291-4ec7-97e9-56cbbb90df6a	antd:exclamation-circle	antd	Warning	status	Warning icon (Ant Design)	{warning,alert}	{"component": "ExclamationCircleOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
67	b8025e9a-d6bd-4249-8249-e52ffa85c4c0	antd:close-circle	antd	Error	status	Error icon (Ant Design)	{error,close}	{"component": "CloseCircleOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
68	fdd83fa3-c327-44a4-8edf-ef1478858a6f	antd:info-circle	antd	Info	status	Info icon (Ant Design)	{info,information}	{"component": "InfoCircleOutlined"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
69	fc807af8-a369-40e0-993a-a1df7066422d	smily:thanks	smily	Thanks	emotions	Thank you emoji	{thanks,thank,gratitude,appreciate}	{"emoji": "🙏", "unicode": "U+1F64F"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
70	1e177531-6eac-45b1-afd5-d6498abce22f	smily:smile	smily	Smile	emotions	Happy smile emoji	{smile,happy,joy,😊}	{"emoji": "😊", "unicode": "U+1F60A"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
71	9a41f9c2-2e66-427a-959d-0c7a7f740337	smily:thumbs-up	smily	Thumbs Up	emotions	Thumbs up emoji	{thumbs,up,like,good,👍}	{"emoji": "👍", "unicode": "U+1F44D"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
72	b4435b9e-ec86-4933-9eda-fb7947a80b85	smily:heart	smily	Heart	emotions	Heart emoji	{heart,love,❤️}	{"emoji": "❤️", "unicode": "U+2764"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
73	f66b4b67-0d1f-4ed1-9937-cbfebe6f5591	smily:star	smily	Star	emotions	Star emoji	{star,favorite,⭐}	{"emoji": "⭐", "unicode": "U+2B50"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
75	443f6c2a-3201-4324-b10b-041dab212224	smily:rocket	smily	Rocket	emotions	Rocket emoji	{rocket,launch,🚀}	{"emoji": "🚀", "unicode": "U+1F680"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
76	df49c8c1-8b56-49d2-bfac-a2cd97f2c000	smily:party	smily	Party	emotions	Party emoji	{party,celebration,🎉}	{"emoji": "🎉", "unicode": "U+1F389"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
77	4b391eca-1887-492a-b51c-54101978f267	smily:check	smily	Check Mark	emotions	Check mark emoji	{check,done,✅}	{"emoji": "✅", "unicode": "U+2705"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
78	1329c377-e08c-498a-8cf7-b543d14707bd	smily:warning	smily	Warning	emotions	Warning emoji	{warning,alert,⚠️}	{"emoji": "⚠️", "unicode": "U+26A0"}	0	t	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
79	d2498152-e184-47dd-b49f-462cf38384a6	custom:myhome	custom	My Home	custom	Custom home icon	{custom,home,myhome}	{"svg": "<svg viewBox=\\"0 0 24 24\\"><path d=\\"M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z\\"/></svg>"}	0	f	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
80	1fce68c9-17e1-4477-8841-3c46c9594513	custom:logo	custom	Logo	custom	Custom logo icon	{custom,logo}	{"svg": "<svg viewBox=\\"0 0 24 24\\"><circle cx=\\"12\\" cy=\\"12\\" r=\\"10\\"/></svg>"}	0	f	t	t	1	2026-01-18 17:56:15.059046+00	2026-01-18 17:56:15.059046+00
161	7644d85f-982f-49d4-86b8-0ba0bea5c837	fa:copy	fa	Copy	actions	Copy icon	{copy,duplicate}	{"class": "fas fa-copy"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
162	7c694acb-a270-48f7-80dc-295f149310e9	fa:cut	fa	Cut	actions	Cut icon	{cut,scissors}	{"class": "fas fa-cut"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
163	d7f4a06f-f275-4047-9dd7-80727010caae	fa:paste	fa	Paste	actions	Paste icon	{paste,clipboard}	{"class": "fas fa-paste"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
164	1c4d4c7d-09c9-4a58-b62c-e6a33d89a5ef	fa:undo	fa	Undo	actions	Undo icon	{undo,revert}	{"class": "fas fa-undo"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
165	9f1da851-e7e8-455b-8aca-1a707957e474	fa:redo	fa	Redo	actions	Redo icon	{redo,repeat}	{"class": "fas fa-redo"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
166	a42db808-fe41-44e8-a1d8-9fd0549cb320	fa:refresh	fa	Refresh	actions	Refresh icon	{refresh,reload}	{"class": "fas fa-sync"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
167	68639839-8317-44e8-a4da-c7218005a971	fa:filter	fa	Filter	actions	Filter icon	{filter,sort}	{"class": "fas fa-filter"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
168	40d892d8-6fc9-43ba-8b18-b6495f7d5527	fa:eye	fa	View	actions	Eye/view icon	{eye,view}	{"class": "fas fa-eye"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
169	cd6f3a8d-49c9-4190-bbbc-7781e9e81f4e	fa:eye-slash	fa	Hide	actions	Eye slash/hide icon	{hide,invisible}	{"class": "fas fa-eye-slash"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
170	40c9de62-2988-4b1b-b694-eae40fdd9a61	fa:print	fa	Print	actions	Print icon	{print,printer}	{"class": "fas fa-print"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
171	dff02df5-159e-4248-a6d8-6e8d77b20696	fa:share	fa	Share	actions	Share icon	{share,send}	{"class": "fas fa-share"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
172	45dfa6cf-8550-40eb-a933-80bdf09031a7	fa:link	fa	Link	actions	Link icon	{link,url}	{"class": "fas fa-link"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
173	902a2b98-a825-4000-8c64-2c31ed636b56	fa:calendar	fa	Calendar	time	Calendar icon	{calendar,date}	{"class": "fas fa-calendar"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
174	794b0433-6b2f-41b1-b4c0-ad599eeda56a	fa:clock	fa	Clock	time	Clock icon	{clock,time}	{"class": "fas fa-clock"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
175	b0d1e670-a2b7-4650-a862-74f15ee26503	fa:money-bill	fa	Money	business	Money bill icon	{money,cash}	{"class": "fas fa-money-bill"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
176	dbac8767-fddd-4d73-8417-a5b492c4c693	fa:credit-card	fa	Credit Card	business	Credit card icon	{credit,card}	{"class": "fas fa-credit-card"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
177	cf5326ff-887e-4648-8083-c256ccb9fb58	fa:chart-line	fa	Chart Line	data	Line chart icon	{chart,line}	{"class": "fas fa-chart-line"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
178	bd152174-7b68-4e9b-82ca-4b627ed59862	fa:chart-pie	fa	Chart Pie	data	Pie chart icon	{chart,pie}	{"class": "fas fa-chart-pie"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
179	07c2c268-b9c5-4af2-b5ae-af0aa87daa81	fa:calculator	fa	Calculator	tools	Calculator icon	{calculator,math}	{"class": "fas fa-calculator"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
180	eb769e44-f140-47e3-887a-a506771cab0a	fa:comment	fa	Comment	communication	Comment icon	{comment,message}	{"class": "fas fa-comment"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
181	69be1714-44d9-42eb-8bb9-18b40b733726	fa:comments	fa	Comments	communication	Comments icon	{comments,messages}	{"class": "fas fa-comments"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
182	3c354600-184f-46c3-bba9-d76679d31d3f	fa:video	fa	Video	media	Video icon	{video,camera}	{"class": "fas fa-video"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
183	46be489b-0025-4e66-88f9-1a1766757c6c	fa:microphone	fa	Microphone	media	Microphone icon	{microphone,audio}	{"class": "fas fa-microphone"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
184	e81b127b-3030-41ea-ba16-e761f239e1ef	fa:image	fa	Image	media	Image icon	{image,picture}	{"class": "fas fa-image"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
185	c34d464f-e333-4243-b33d-375739a26035	fa:camera	fa	Camera	media	Camera icon	{camera,photo}	{"class": "fas fa-camera"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
186	1393e33b-52b8-4032-b256-f3dad5b63cdc	fa:bars	fa	Menu	navigation	Bars/menu icon	{menu,bars}	{"class": "fas fa-bars"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
187	52da52ab-300f-4e99-b31a-cbea6abdab9e	fa:list	fa	List	navigation	List icon	{list,items}	{"class": "fas fa-list"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
188	47ba8ff9-c1a6-433e-b807-83005ee112b3	fa:table	fa	Table	data	Table icon	{table,grid}	{"class": "fas fa-table"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
189	b57f41e1-e437-44e9-b85e-6db4fc441845	fa:angle-left	fa	Angle Left	navigation	Angle left icon	{angle,left}	{"class": "fas fa-angle-left"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
190	b6ca6ec4-a873-4ac8-8273-34d0a2d295fb	fa:angle-right	fa	Angle Right	navigation	Angle right icon	{angle,right}	{"class": "fas fa-angle-right"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
191	9298ed92-ea92-4e84-9feb-d1d84e28f455	fa:chevron-left	fa	Chevron Left	navigation	Chevron left icon	{chevron,left}	{"class": "fas fa-chevron-left"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
192	cd772d6e-6fd0-4bd7-af01-de4d623866d7	fa:chevron-right	fa	Chevron Right	navigation	Chevron right icon	{chevron,right}	{"class": "fas fa-chevron-right"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
193	b605d098-cc85-4ca2-b172-705725405f3c	fa:file-pdf	fa	PDF	documents	PDF file icon	{pdf,file}	{"class": "fas fa-file-pdf"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
194	453806b6-969f-414f-a9b3-c9116a2479e1	fa:file-word	fa	Word	documents	Word file icon	{word,doc}	{"class": "fas fa-file-word"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
195	e998856f-cc4e-4ee4-ae7b-20aed777b2f2	fa:file-excel	fa	Excel	documents	Excel file icon	{excel,xls}	{"class": "fas fa-file-excel"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
196	2d36a2ae-4db4-4a05-aaa8-7f8399040425	fa:youtube	fa	YouTube	social	YouTube icon	{youtube,video}	{"class": "fab fa-youtube"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
197	54f57b1b-2d60-46b6-b313-0062f06bcd27	fa:github	fa	GitHub	social	GitHub icon	{github,code}	{"class": "fab fa-github"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
198	cf5618db-4769-4dcf-b875-8d34d8277c97	fa:whatsapp	fa	WhatsApp	social	WhatsApp icon	{whatsapp,chat}	{"class": "fab fa-whatsapp"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
199	e6354564-f378-4988-a2fd-e6e226aa9b80	fa:slack	fa	Slack	social	Slack icon	{slack,chat}	{"class": "fab fa-slack"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
200	eeabb467-ce69-4797-82e8-0a6b01c182e0	fa:spinner	fa	Spinner	status	Spinner/loading icon	{spinner,loading}	{"class": "fas fa-spinner"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
201	96db2ec4-e013-4f45-9c77-17db29e2da5d	fa:question-circle	fa	Question	status	Question circle icon	{question,help}	{"class": "far fa-circle-question"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
202	b66bbd0f-5d76-446a-830b-3e68e98cd509	fa:wrench	fa	Wrench	tools	Wrench icon	{wrench,tool}	{"class": "fas fa-wrench"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
203	329e5a89-2fbf-4740-832d-fd0f78ac65ab	fa:map	fa	Map	location	Map icon	{map,location}	{"class": "fas fa-map"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
204	e16723df-961c-4616-ad32-9d2915f6cf38	fa:globe	fa	Globe	location	Globe icon	{globe,world}	{"class": "fas fa-globe"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
205	4405e67d-ab4b-4131-8f3c-76624ff872f1	fa:shopping-cart	fa	Shopping Cart	shopping	Shopping cart icon	{cart,shopping}	{"class": "fas fa-shopping-cart"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
206	c0e929bb-ceba-4350-a640-f5eb611dab7e	fa:tag	fa	Tag	shopping	Tag icon	{tag,label}	{"class": "fas fa-tag"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
207	b20dd748-1e5b-4c9f-a02d-4c8c1f41321e	fa:gift	fa	Gift	shopping	Gift icon	{gift,present}	{"class": "fas fa-gift"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
208	d341b316-c2f5-463d-a8c3-534ed0db0d6f	fa:graduation-cap	fa	Graduation Cap	education	Graduation cap icon	{graduation,education}	{"class": "fas fa-graduation-cap"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
209	5bb4f41e-c8b1-4485-b336-307ec3c7d376	fa:utensils	fa	Utensils	food	Utensils icon	{utensils,food}	{"class": "fas fa-utensils"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
210	5971f650-df34-4b68-bbf4-373138d74ca0	fa:coffee	fa	Coffee	food	Coffee icon	{coffee,drink}	{"class": "fas fa-mug-hot"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
211	bd4af73a-8f3b-47a8-aa00-b61ac165502e	fa:laptop	fa	Laptop	technology	Laptop icon	{laptop,computer}	{"class": "fas fa-laptop"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
212	f84d4eec-583c-45a3-afeb-cbc477d261dc	fa:mobile-alt	fa	Mobile	technology	Mobile icon	{mobile,phone}	{"class": "fas fa-mobile-screen-button"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
213	51909e56-5b90-431e-a00e-db546c45599d	fa:wifi	fa	WiFi	technology	WiFi icon	{wifi,wireless}	{"class": "fas fa-wifi"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
214	02182f0a-f028-46a4-82f7-3a7cae07d7d3	fa:code	fa	Code	development	Code icon	{code,programming}	{"class": "fas fa-code"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
215	f2c90c88-282a-44a3-b90f-509fce271787	fa:terminal	fa	Terminal	development	Terminal icon	{terminal,command}	{"class": "fas fa-terminal"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
216	2397284a-7e50-419c-bad9-455ba3469ac1	fa:sort	fa	Sort	actions	Sort icon	{sort,order}	{"class": "fas fa-sort"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
217	cc9c81ad-dcbe-4daf-96f6-e52c000a0705	fa:expand	fa	Expand	navigation	Expand icon	{expand,fullscreen}	{"class": "fas fa-expand"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
218	365a16d0-8c86-4128-87a3-16749901662f	fa:compress	fa	Compress	navigation	Compress icon	{compress}	{"class": "fas fa-compress"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
219	15276bfe-fc31-494d-a293-a554046d04cf	fa:caret-down	fa	Caret Down	navigation	Caret down icon	{caret,down}	{"class": "fas fa-caret-down"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
220	1931032e-f8c7-4c44-84d4-6b61384e0660	fa:caret-up	fa	Caret Up	navigation	Caret up icon	{caret,up}	{"class": "fas fa-caret-up"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
221	b4c8beb8-c7cd-4a3d-9ff4-fa31c44f8453	fa:folder-open	fa	Folder Open	documents	Folder open icon	{folder,open}	{"class": "fas fa-folder-open"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
222	d1854c68-066c-4b15-97fa-f0201a88e15a	fa:book	fa	Book	documents	Book icon	{book,read}	{"class": "fas fa-book"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
223	e0f5d750-f804-49e7-bd4f-543715e1c96d	fa:bookmark	fa	Bookmark	documents	Bookmark icon	{bookmark,save}	{"class": "fas fa-bookmark"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
224	a9fe2b7a-8d5c-40d7-8ef2-6a649d7583f5	fa:newspaper	fa	Newspaper	documents	Newspaper icon	{newspaper,news}	{"class": "far fa-newspaper"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
225	49a400fb-342f-4c0c-9af2-58cc301401bc	fa:reddit	fa	Reddit	social	Reddit icon	{reddit,social}	{"class": "fab fa-reddit"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
226	2a2503e2-b9f5-49fc-b3c8-8e8f39a117dc	fa:discord	fa	Discord	social	Discord icon	{discord,chat}	{"class": "fab fa-discord"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
227	f414e3e1-0d0a-41ea-b9ab-9638dc8936dd	fa:telegram	fa	Telegram	social	Telegram icon	{telegram,chat}	{"class": "fab fa-telegram"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
228	60d6b2b1-947a-40dd-b637-11fbeb4111fb	fa:skype	fa	Skype	social	Skype icon	{skype,chat}	{"class": "fab fa-skype"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
229	73943ff0-fcbc-4b6a-8f44-1226671a28fe	fa:pinterest	fa	Pinterest	social	Pinterest icon	{pinterest,social}	{"class": "fab fa-pinterest"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
230	9691fdb1-3a2e-4c85-936f-af791a5b0c10	fa:dribbble	fa	Dribbble	social	Dribbble icon	{dribbble,design}	{"class": "fab fa-dribbble"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
231	557396c0-396c-4ef0-ba40-1333a9b154ed	fa:behance	fa	Behance	social	Behance icon	{behance,design}	{"class": "fab fa-behance"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
232	b1ec61d7-d126-4f3c-a906-7dc5c09d3e06	fa:circle	fa	Circle	status	Circle icon	{circle,dot}	{"class": "far fa-circle"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
233	74d97247-f38c-4215-bb8b-9ff2d25323f8	fa:ban	fa	Ban	status	Ban icon	{ban,block}	{"class": "fas fa-ban"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
234	e8ac622e-c40d-4e1e-95ad-88c7bf973809	fa:play-circle	fa	Play	media	Play circle icon	{play,video}	{"class": "far fa-circle-play"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
235	3cbe59c2-20cf-44f6-8c50-fae4ea3122f1	fa:pause-circle	fa	Pause	media	Pause circle icon	{pause,video}	{"class": "far fa-circle-pause"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
236	077c4495-9a0e-4d78-9250-80cf6309ad34	fa:stop-circle	fa	Stop	media	Stop circle icon	{stop,video}	{"class": "far fa-circle-stop"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
237	643579bf-c3a3-44e1-90b0-977976f47816	fa:paint-brush	fa	Paint Brush	tools	Paint brush icon	{paint,brush}	{"class": "fas fa-paint-brush"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
238	8bd3309b-b6aa-437a-a828-84ef3e986b7a	fa:palette	fa	Palette	tools	Palette icon	{palette,color}	{"class": "fas fa-palette"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
239	a37f654b-f88b-475a-a7e7-5f82ac0ee9fa	fa:sliders-h	fa	Sliders	settings	Sliders icon	{sliders,settings}	{"class": "fas fa-sliders"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
240	9c1612ec-0a01-4145-837f-161087b34dca	fa:toggle-on	fa	Toggle On	settings	Toggle on icon	{toggle,on}	{"class": "fas fa-toggle-on"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
241	60763961-25bd-4fe3-96f3-0c009913cdac	fa:toggle-off	fa	Toggle Off	settings	Toggle off icon	{toggle,off}	{"class": "fas fa-toggle-off"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
242	11dd1ace-1717-49cc-9c72-23d3a17fb0a2	fa:power-off	fa	Power Off	settings	Power off icon	{power,off}	{"class": "fas fa-power-off"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
243	ad13025d-b852-44c3-824d-4d713ec9c511	fa:lightbulb	fa	Lightbulb	tools	Lightbulb icon	{lightbulb,idea}	{"class": "far fa-lightbulb"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
244	fabaf401-4967-4321-9abd-e5ccd6d9e09d	fa:map-marker	fa	Map Marker	location	Map marker icon	{map,marker}	{"class": "fas fa-location-dot"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
245	70a4955f-7231-41c3-b65f-9dd34f789bbb	fa:plane	fa	Plane	travel	Plane icon	{plane,airplane}	{"class": "fas fa-plane"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
246	05120b55-70a6-4c1e-9602-2b4891b9c27e	fa:car	fa	Car	travel	Car icon	{car,vehicle}	{"class": "fas fa-car"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
247	4b8dc8fc-b283-494a-8589-ee2487d4e39b	fa:bus	fa	Bus	travel	Bus icon	{bus,vehicle}	{"class": "fas fa-bus"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
248	e6e6cebd-ab18-45bd-b96c-dba961b4e646	fa:train	fa	Train	travel	Train icon	{train,vehicle}	{"class": "fas fa-train"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
249	194e37b8-b77e-400d-8a8c-ec01f72aef56	fa:shipping-fast	fa	Shipping Fast	shopping	Fast shipping icon	{shipping,fast}	{"class": "fas fa-shipping-fast"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
250	d7f20b9b-9c60-4063-93dd-2073d218244e	fa:truck	fa	Truck	shopping	Truck icon	{truck,delivery}	{"class": "fas fa-truck"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
251	40fcd8af-4c72-4f28-a2df-e3b0933d9f8c	fa:heartbeat	fa	Heartbeat	health	Heartbeat icon	{heartbeat,health}	{"class": "fas fa-heartbeat"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
252	baa9f21e-fd7f-4da4-90a7-f0b1b0c5e4ac	fa:stethoscope	fa	Stethoscope	health	Stethoscope icon	{stethoscope,medical}	{"class": "fas fa-stethoscope"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
253	b5ce7327-ef76-4687-a156-113dc023c27f	fa:hospital	fa	Hospital	health	Hospital icon	{hospital,medical}	{"class": "fas fa-hospital"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
254	797ed4f4-62f1-4897-a0b4-7456202fdf54	fa:school	fa	School	education	School icon	{school,education}	{"class": "fas fa-school"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
255	65070f3b-1a61-4a4c-b609-4abd0858fe5d	fa:university	fa	University	education	University icon	{university,education}	{"class": "fas fa-building-columns"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
256	25d825c8-70b1-47e1-a304-39b8f78d1b1e	fa:wine-glass	fa	Wine Glass	food	Wine glass icon	{wine,drink}	{"class": "fas fa-wine-glass"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
257	b517020b-94e6-48e6-ae61-46353b591708	fa:pizza-slice	fa	Pizza	food	Pizza slice icon	{pizza,food}	{"class": "fas fa-pizza-slice"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
258	cc04bcca-68ad-4601-b119-e38b9dce1d32	fa:football-ball	fa	Football	sports	Football icon	{football,sports}	{"class": "fas fa-football"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
259	1e2beeeb-7c80-4b67-b842-462b95562c2e	fa:basketball-ball	fa	Basketball	sports	Basketball icon	{basketball,sports}	{"class": "fas fa-basketball"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
260	c99a8b7e-6f92-485e-9ef2-95666ee86f4b	fa:gamepad	fa	Gamepad	games	Gamepad icon	{gamepad,game}	{"class": "fas fa-gamepad"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
261	6bd2cee4-9de5-45fd-af66-5ed73cd9802e	fa:sun	fa	Sun	weather	Sun icon	{sun,weather}	{"class": "far fa-sun"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
262	beba0bee-2c7e-4785-a0c6-f099821e8d72	fa:moon	fa	Moon	weather	Moon icon	{moon,night}	{"class": "far fa-moon"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
263	100f72dc-a948-4ed8-923d-1635486fa323	fa:cloud	fa	Cloud	weather	Cloud icon	{cloud,weather}	{"class": "fas fa-cloud"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
264	0b367da3-c47e-4062-ad7f-dc5dbe5a81a1	fa:cloud-rain	fa	Rain	weather	Cloud rain icon	{rain,weather}	{"class": "fas fa-cloud-rain"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
265	6b7b1f8b-050b-42d0-94d4-b4dd7795cb73	fa:snowflake	fa	Snowflake	weather	Snowflake icon	{snowflake,snow}	{"class": "far fa-snowflake"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
266	cbfab670-909c-4a04-b529-781465cf5238	fa:umbrella	fa	Umbrella	weather	Umbrella icon	{umbrella,rain}	{"class": "fas fa-umbrella"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
267	047a77ab-ba40-444e-ab8f-6141f3ca387b	fa:bolt	fa	Bolt	weather	Bolt/lightning icon	{bolt,lightning}	{"class": "fas fa-bolt"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
268	4171bb6f-143e-4708-9a62-041d464bc5e3	fa:gem	fa	Gem	objects	Gem icon	{gem,diamond}	{"class": "far fa-gem"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
269	f5e74055-3733-4db6-b73f-d54f68ced4dd	fa:crown	fa	Crown	objects	Crown icon	{crown,royal}	{"class": "fas fa-crown"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
270	36ba62a8-d84a-412a-af71-3a92c17dd46a	fa:trophy	fa	Trophy	objects	Trophy icon	{trophy,award}	{"class": "fas fa-trophy"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
271	eed3b940-0f12-4818-8f75-a24cce4b4e7e	fa:medal	fa	Medal	objects	Medal icon	{medal,award}	{"class": "fas fa-medal"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
272	596b248d-8d47-4b67-8672-dd9ddb623c79	fa:award	fa	Award	objects	Award icon	{award,prize}	{"class": "fas fa-award"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
273	60015da2-5daf-4040-8388-588928199979	fa:flag	fa	Flag	objects	Flag icon	{flag,country}	{"class": "fas fa-flag"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
274	bca15bd5-7245-4fd5-93b5-ceedc435a929	fa:hand-paper	fa	Hand Paper	actions	Hand paper/stop icon	{hand,stop}	{"class": "far fa-hand"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
275	9bc4d645-2fbb-4ac0-aff4-918a6451c8a1	fa:thumbs-down	fa	Thumbs Down	actions	Thumbs down icon	{thumbs,down}	{"class": "far fa-thumbs-down"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
276	e5ee7b2e-4adc-429c-8d42-796e0e367312	fa:handshake	fa	Handshake	business	Handshake icon	{handshake,deal}	{"class": "far fa-handshake"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
277	f6c9c83d-a9d9-417a-bc72-7fbc0fd3aced	fa:user-tie	fa	User Tie	business	User tie icon	{user,tie}	{"class": "fas fa-user-tie"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
278	31baae0d-f7be-4ff2-b36a-a4af2c8edb45	fa:user-graduate	fa	User Graduate	education	User graduate icon	{user,graduate}	{"class": "fas fa-user-graduate"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
279	00da7e8d-b917-4ffe-9d08-b2a647b2e585	fa:user-shield	fa	User Shield	security	User shield icon	{user,shield}	{"class": "fas fa-user-shield"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
280	8511159a-0346-480c-9ca5-7e5e6847405c	fa:user-plus	fa	User Plus	users	User plus icon	{user,plus}	{"class": "fas fa-user-plus"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
281	62eea63e-1b25-4e15-a958-c0122ae5d84d	fa:user-minus	fa	User Minus	users	User minus icon	{user,minus}	{"class": "fas fa-user-minus"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
282	fe4fd4d6-5a0c-4ddc-832a-42bad3c10f6f	fa:id-card	fa	ID Card	users	ID card icon	{id,card}	{"class": "far fa-id-card"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
283	781da65b-2b28-4cff-98cc-e45df2dccb54	fa:desktop	fa	Desktop	technology	Desktop icon	{desktop,computer}	{"class": "fas fa-desktop"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
284	66186799-6de4-4992-895d-812b034932c0	fa:tablet	fa	Tablet	technology	Tablet icon	{tablet,device}	{"class": "fas fa-tablet"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
285	2d3b08e0-0c1f-4f0b-b507-518635b99d13	fa:server	fa	Server	technology	Server icon	{server,computer}	{"class": "fas fa-server"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
286	a8014be4-1e93-4a73-855b-61d22c97b3bc	fa:keyboard	fa	Keyboard	technology	Keyboard icon	{keyboard,input}	{"class": "far fa-keyboard"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
287	cede8a0d-1f9f-4f9f-96a9-cd4b248d19fd	fa:mouse	fa	Mouse	technology	Mouse icon	{mouse,input}	{"class": "fas fa-computer-mouse"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
288	77fad5d5-50d3-468b-9825-0c3344c5d781	fa:headset	fa	Headset	technology	Headset icon	{headset,audio}	{"class": "fas fa-headset"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
289	db03cc9b-d9ea-4fa7-a523-c15528bcc1ed	fa:tv	fa	TV	technology	TV icon	{tv,television}	{"class": "fas fa-tv"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
290	374b52ce-cd22-4c81-adcb-7b45db2f226b	fa:fingerprint	fa	Fingerprint	security	Fingerprint icon	{fingerprint,biometric}	{"class": "fas fa-fingerprint"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
291	47535b3e-6cff-472b-80f8-a6d89eeff53d	fa:lock-open	fa	Lock Open	security	Lock open icon	{lock,open}	{"class": "fas fa-lock-open"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
292	d0af7de8-0690-410d-a409-d34e179f7d04	fa:sync	fa	Sync	actions	Sync icon	{sync,synchronize}	{"class": "fas fa-arrows-rotate"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
293	08289a83-5790-415a-8c5d-655c8abe64bd	fa:random	fa	Random	actions	Random icon	{random,shuffle}	{"class": "fas fa-shuffle"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
294	56104350-f580-487d-93f0-1c52cddce70b	fa:external-link-alt	fa	External Link	navigation	External link icon	{external,link}	{"class": "fas fa-arrow-up-right-from-square"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
295	ca62494c-ad00-458d-bb06-eb1bc25fc91a	fa:sign-in-alt	fa	Sign In	authentication	Sign in icon	{sign,in}	{"class": "fas fa-right-to-bracket"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
296	18d9b992-ef54-46c0-b6b3-23ec3e2dc5c6	fa:sign-out-alt	fa	Sign Out	authentication	Sign out icon	{sign,out}	{"class": "fas fa-right-from-bracket"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
297	699aa2c7-f533-4a51-9919-fc0c02fe022e	fa:language	fa	Language	communication	Language icon	{language,translate}	{"class": "fas fa-language"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
298	83a627d9-4d5d-4fba-90dc-ac8e321af22e	fa:bold	fa	Bold	text	Bold icon	{bold,text}	{"class": "fas fa-bold"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
299	ff06d927-5e51-43b0-b305-a53cd29c3edd	fa:italic	fa	Italic	text	Italic icon	{italic,text}	{"class": "fas fa-italic"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
300	9ecbb732-3c1c-4e1c-a876-5042b179a390	fa:underline	fa	Underline	text	Underline icon	{underline,text}	{"class": "fas fa-underline"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
301	2a12cf2f-4472-4197-a1e6-443580eeb044	fa:bug	fa	Bug	development	Bug icon	{bug,error}	{"class": "fas fa-bug"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
302	3d364813-c809-460d-9125-b42325ba26d1	fa:code-branch	fa	Code Branch	development	Code branch icon	{branch,git}	{"class": "fas fa-code-branch"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
303	02f77141-bf5d-404a-8ba4-50a9f5fee0de	fa:html5	fa	HTML5	development	HTML5 icon	{html5,web}	{"class": "fab fa-html5"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
304	8736662f-9b2d-4014-bc78-14ad049a5188	fa:css3	fa	CSS3	development	CSS3 icon	{css3,web}	{"class": "fab fa-css3-alt"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
305	49b2eb22-cc76-43fa-aad1-3f34e57d5ecf	fa:js	fa	JavaScript	development	JavaScript icon	{javascript,js}	{"class": "fab fa-js"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
306	2d95c94d-e959-4214-ae99-22c185d72fc8	fa:python	fa	Python	development	Python icon	{python,programming}	{"class": "fab fa-python"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
307	c39360b2-acbc-46ff-93cf-b1ddbab6947c	fa:node-js	fa	Node.js	development	Node.js icon	{nodejs,javascript}	{"class": "fab fa-node-js"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
308	6692fad5-54d1-4bf2-aad2-09518de932df	fa:react	fa	React	development	React icon	{react,javascript}	{"class": "fab fa-react"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
309	d92158b1-06c5-4ddb-939d-4e60c16c04c0	fa:vue	fa	Vue	development	Vue icon	{vue,javascript}	{"class": "fab fa-vuejs"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
310	36b9041d-2cf9-408c-ab33-8deba443456f	fa:angular	fa	Angular	development	Angular icon	{angular,javascript}	{"class": "fab fa-angular"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
311	908e080b-51e1-4552-8aa3-0b1bd80c5611	fa:bootstrap	fa	Bootstrap	development	Bootstrap icon	{bootstrap,css}	{"class": "fab fa-bootstrap"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
312	b6095a3c-f620-42cf-abd0-7d8192f556e8	fa:npm	fa	NPM	development	NPM icon	{npm,package}	{"class": "fab fa-npm"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
313	abbe8a16-3896-4c5f-ad05-5e35b5a600ed	fa:docker	fa	Docker	development	Docker icon	{docker,container}	{"class": "fab fa-docker"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
314	84800079-0995-49fa-9f8f-fd35890e7a89	fa:aws	fa	AWS	development	AWS icon	{aws,cloud}	{"class": "fab fa-aws"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
315	e5b0fe84-b411-4bd3-a0c8-b704f92b7dd8	fa:linux	fa	Linux	development	Linux icon	{linux,os}	{"class": "fab fa-linux"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
316	a580578d-bc31-44c1-a9fe-c80406b66deb	fa:windows	fa	Windows	development	Windows icon	{windows,os}	{"class": "fab fa-windows"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
317	368f638e-5abd-4b7f-ae15-e8a7a7de1357	fa:apple	fa	Apple	development	Apple icon	{apple,os}	{"class": "fab fa-apple"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
318	033901ed-4259-4346-85b9-b71e418378f8	fa:android	fa	Android	development	Android icon	{android,mobile}	{"class": "fab fa-android"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
319	c1822cc7-670e-42ad-99ad-635c7ed20714	fa:chrome	fa	Chrome	development	Chrome icon	{chrome,browser}	{"class": "fab fa-chrome"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
320	0b66d108-e6b8-49ab-ab06-de22d9aa36fc	fa:firefox	fa	Firefox	development	Firefox icon	{firefox,browser}	{"class": "fab fa-firefox"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
321	a74e2e8d-a14f-4827-9769-633f9c34ee1f	fa:safari	fa	Safari	development	Safari icon	{safari,browser}	{"class": "fab fa-safari"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
322	d3b013cf-f0ef-4931-9215-bf4aff5a3e74	antd:copy	antd	Copy	actions	Copy icon (Ant Design)	{copy,duplicate}	{"component": "CopyOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
323	4f69d467-dcd9-4ef0-9e64-e4b78a2330c3	antd:cut	antd	Cut	actions	Cut icon (Ant Design)	{cut}	{"component": "ScissorOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
324	693d4d42-ec9a-4081-865c-771fa3249d94	antd:paste	antd	Paste	actions	Paste icon (Ant Design)	{paste}	{"component": "SnippetsOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
325	5fcca6b9-c434-4dc6-8d91-e04fee57ec2a	antd:undo	antd	Undo	actions	Undo icon (Ant Design)	{undo}	{"component": "UndoOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
326	58f5da18-15bf-4b13-a7e0-96a69b5c0c92	antd:redo	antd	Redo	actions	Redo icon (Ant Design)	{redo}	{"component": "RedoOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
327	7c5a2779-a40f-401a-aeaf-e863641c5ea6	antd:reload	antd	Reload	actions	Reload icon (Ant Design)	{reload,refresh}	{"component": "ReloadOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
328	abe2ed33-c4d7-4977-89c0-3f05c4be47ab	antd:filter	antd	Filter	actions	Filter icon (Ant Design)	{filter}	{"component": "FilterOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
329	4a112c91-726c-4997-b629-65f325edbd08	antd:eye	antd	View	actions	Eye/view icon (Ant Design)	{eye,view}	{"component": "EyeOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
330	b3e7a807-9b9a-4683-9db4-c36ee91c1273	antd:eye-invisible	antd	Hide	actions	Eye invisible icon (Ant Design)	{hide}	{"component": "EyeInvisibleOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
331	2faf5e54-7763-4270-a795-e2f4e5ae7e83	antd:printer	antd	Print	actions	Print icon (Ant Design)	{print}	{"component": "PrinterOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
332	540e8c62-f970-4ab8-9d75-3d5f06e52aca	antd:share-alt	antd	Share	actions	Share icon (Ant Design)	{share}	{"component": "ShareAltOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
333	f8b02703-1ee1-404e-a125-103a7fbf6a9e	antd:link	antd	Link	actions	Link icon (Ant Design)	{link}	{"component": "LinkOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
334	bc523b80-345c-47f2-af6e-67dbb70da4a0	antd:calendar	antd	Calendar	time	Calendar icon (Ant Design)	{calendar}	{"component": "CalendarOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
335	60be5a7f-cfe9-43ae-99ef-4af95475fd12	antd:clock-circle	antd	Clock	time	Clock icon (Ant Design)	{clock,time}	{"component": "ClockCircleOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
336	87262fa7-96e0-4e67-adac-37033c9fd9c8	antd:dollar	antd	Dollar	business	Dollar icon (Ant Design)	{dollar,money}	{"component": "DollarOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
337	75c4916d-719e-4c60-a84f-081240fbc193	antd:credit-card	antd	Credit Card	business	Credit card icon (Ant Design)	{credit,card}	{"component": "CreditCardOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
338	b41b8ed5-ce3a-4cac-a101-1500b6a3d9aa	antd:line-chart	antd	Line Chart	data	Line chart icon (Ant Design)	{chart,line}	{"component": "LineChartOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
339	de17f13b-c2e2-420d-bb8d-64a7c4bfc3db	antd:pie-chart	antd	Pie Chart	data	Pie chart icon (Ant Design)	{chart,pie}	{"component": "PieChartOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
340	959ad26c-8990-428c-b002-239cf60da3fd	antd:bar-chart	antd	Bar Chart	data	Bar chart icon (Ant Design)	{chart,bar}	{"component": "BarChartOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
341	25de48ad-b2d7-4074-89d9-fdd652ff15f7	antd:calculator	antd	Calculator	tools	Calculator icon (Ant Design)	{calculator}	{"component": "CalculatorOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
342	b914dc02-025b-4e0c-ab39-591b07bf1569	antd:message	antd	Message	communication	Message icon (Ant Design)	{message}	{"component": "MessageOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
343	df25d52b-36ad-4d27-ac1d-6b9f7948d163	antd:comment	antd	Comment	communication	Comment icon (Ant Design)	{comment}	{"component": "CommentOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
344	a9082f97-b9c7-4892-97a5-1374ccef4f70	antd:video-camera	antd	Video	media	Video camera icon (Ant Design)	{video}	{"component": "VideoCameraOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
345	e892c3f3-f41e-4aae-8230-6a752f9487f7	antd:audio	antd	Audio	media	Audio icon (Ant Design)	{audio}	{"component": "AudioOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
346	8eae96fe-557c-4ad9-a344-1b7c93e7f116	antd:picture	antd	Picture	media	Picture icon (Ant Design)	{picture,image}	{"component": "PictureOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
347	61d3bda8-16a8-4bbc-8c9a-d4a075221c66	antd:camera	antd	Camera	media	Camera icon (Ant Design)	{camera}	{"component": "CameraOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
348	c75cf49c-c40e-41da-8549-639ae4bfdbec	antd:menu	antd	Menu	navigation	Menu icon (Ant Design)	{menu}	{"component": "MenuOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
349	ecdd17fc-6615-4f39-9695-3c82a907bbf7	antd:unordered-list	antd	List	navigation	List icon (Ant Design)	{list}	{"component": "UnorderedListOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
350	5819ecf3-06ce-4188-9396-f4e2d476ce0a	antd:table	antd	Table	data	Table icon (Ant Design)	{table}	{"component": "TableOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
351	258e71ee-26f5-4f4c-b39e-a75089876b75	antd:left	antd	Left	navigation	Left icon (Ant Design)	{left}	{"component": "LeftOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
352	732209b1-0278-4c88-8a21-a43f971812f7	antd:right	antd	Right	navigation	Right icon (Ant Design)	{right}	{"component": "RightOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
353	d466ab32-d3cb-4893-8b9f-3d5821d503c1	antd:up	antd	Up	navigation	Up icon (Ant Design)	{up}	{"component": "UpOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
354	f2e7a8cc-78ec-4e45-9eea-17626330e7ef	antd:down	antd	Down	navigation	Down icon (Ant Design)	{down}	{"component": "DownOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
355	47b5b29c-b9a5-4621-8c8b-b3123437d90c	antd:double-left	antd	Double Left	navigation	Double left icon (Ant Design)	{left,double}	{"component": "DoubleLeftOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
356	6b51edff-51bb-404f-9e73-346b9f705457	antd:double-right	antd	Double Right	navigation	Double right icon (Ant Design)	{right,double}	{"component": "DoubleRightOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
357	9cacc949-50f7-4dcf-9326-fc4545a4a1da	antd:file-text	antd	File Text	documents	File text icon (Ant Design)	{file,text}	{"component": "FileTextOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
358	4dfe260e-00b7-4e14-85d3-cb0f467f4dc5	antd:folder-open	antd	Folder Open	documents	Folder open icon (Ant Design)	{folder,open}	{"component": "FolderOpenOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
359	6e52d986-1ec7-4f40-a685-8bc92b4d9120	antd:book	antd	Book	documents	Book icon (Ant Design)	{book}	{"component": "BookOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
360	c0b245f6-95a7-491d-98a2-4ad62295b021	antd:youtube	antd	YouTube	social	YouTube icon (Ant Design)	{youtube}	{"component": "YoutubeOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
361	388e61ac-9d93-482d-bb7c-6bf5207d6f42	antd:github	antd	GitHub	social	GitHub icon (Ant Design)	{github}	{"component": "GithubOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
362	c7bf38df-5eea-4bb8-8128-eb376fe4b928	antd:loading	antd	Loading	status	Loading icon (Ant Design)	{loading,spinner}	{"component": "LoadingOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
363	69bca948-dc03-4fa4-868e-def296abbacd	antd:question-circle	antd	Question	status	Question circle icon (Ant Design)	{question}	{"component": "QuestionCircleOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
364	28d7e3bf-dc7f-4081-9bc8-3b8fb8bbf495	antd:tool	antd	Tool	tools	Tool icon (Ant Design)	{tool}	{"component": "ToolOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
365	1d5c4434-4132-4d89-a612-f59cec9b50db	antd:global	antd	Global	location	Global icon (Ant Design)	{global,world}	{"component": "GlobalOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
366	5544011d-2257-466c-a01b-2e1cf40aa7bc	antd:shopping-cart	antd	Shopping Cart	shopping	Shopping cart icon (Ant Design)	{cart}	{"component": "ShoppingCartOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
367	3c98eec4-39ec-44c1-b0f1-7f519305b4c9	antd:tag	antd	Tag	shopping	Tag icon (Ant Design)	{tag}	{"component": "TagOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
368	e8f58755-ec33-4ed9-a19e-9486c30bdcb5	antd:gift	antd	Gift	shopping	Gift icon (Ant Design)	{gift}	{"component": "GiftOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
369	f68a2fe1-a70d-4406-9633-e6d0309f363d	antd:graduation-cap	antd	Graduation	education	Graduation cap icon (Ant Design)	{graduation}	{"component": "ReadOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
370	f2f32e56-7547-4276-b8f0-db1e97e9d323	antd:laptop	antd	Laptop	technology	Laptop icon (Ant Design)	{laptop}	{"component": "LaptopOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
371	05bd3ea3-6009-4f6e-b93d-69d579364bde	antd:mobile	antd	Mobile	technology	Mobile icon (Ant Design)	{mobile}	{"component": "MobileOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
372	4b360579-3281-4d0d-a575-e4f1e36e873c	antd:tablet	antd	Tablet	technology	Tablet icon (Ant Design)	{tablet}	{"component": "TabletOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
373	711f2225-c354-429e-b9f4-1aea14eb62de	antd:code	antd	Code	development	Code icon (Ant Design)	{code}	{"component": "CodeOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
374	7b990b0b-deed-4660-ab33-831617dad2eb	antd:bug	antd	Bug	development	Bug icon (Ant Design)	{bug}	{"component": "BugOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
375	1dbc7744-7fab-46b9-906c-13225822d3fa	antd:api	antd	API	development	API icon (Ant Design)	{api}	{"component": "ApiOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
376	962bea87-749f-4044-adfd-13870023f89b	antd:thunderbolt	antd	Thunderbolt	tools	Thunderbolt icon (Ant Design)	{thunderbolt}	{"component": "ThunderboltOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
377	25ad2c1b-d8f0-4cc7-a317-9fb901cc45e3	antd:rocket	antd	Rocket	tools	Rocket icon (Ant Design)	{rocket}	{"component": "RocketOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
378	619bc669-e216-4dd9-b0e1-8fa1330c4a1c	antd:fire	antd	Fire	tools	Fire icon (Ant Design)	{fire}	{"component": "FireOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
379	d7d823eb-f639-44da-93cc-82079f934aed	antd:bulb	antd	Bulb	tools	Bulb icon (Ant Design)	{bulb,idea}	{"component": "BulbOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
380	e55aba67-c5d4-46f4-853d-11c626e025fa	antd:compass	antd	Compass	location	Compass icon (Ant Design)	{compass}	{"component": "CompassOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
381	7e16edf4-ec4a-430d-bb40-f5b35f83838b	antd:environment	antd	Environment	location	Environment/location icon (Ant Design)	{environment,location}	{"component": "EnvironmentOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
382	c0f240ce-b1a2-4f61-bdbd-4ad5d28485ae	antd:car	antd	Car	travel	Car icon (Ant Design)	{car}	{"component": "CarOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
383	a9f6271b-c9c0-44e3-b935-c99803e7293f	antd:medicine-box	antd	Medicine	health	Medicine box icon (Ant Design)	{medicine}	{"component": "MedicineBoxOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
385	d1f9e864-1337-42ba-bb61-4d783c72bf52	antd:coffee	antd	Coffee	food	Coffee icon (Ant Design)	{coffee}	{"component": "CoffeeOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
386	78fe1b24-2fbf-4cf8-956f-06bdc60d327e	antd:shop	antd	Shop	shopping	Shop icon (Ant Design)	{shop}	{"component": "ShopOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
387	0d94712e-5ab7-4fe3-af08-4c1aae4e1573	antd:bank	antd	Bank	business	Bank icon (Ant Design)	{bank}	{"component": "BankOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
388	20539cbd-1a2c-411a-ab2a-fe84e517a416	antd:wallet	antd	Wallet	business	Wallet icon (Ant Design)	{wallet}	{"component": "WalletOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
389	7db1607d-e441-4e45-ab8e-1d5737ee7760	antd:file-pdf	antd	PDF	documents	PDF icon (Ant Design)	{pdf}	{"component": "FilePdfOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
390	157da7e7-c280-4970-a193-93aba3c7bcb5	antd:file-excel	antd	Excel	documents	Excel icon (Ant Design)	{excel}	{"component": "FileExcelOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
391	c2b5c3d5-3514-4c3b-8761-32279641fead	antd:file-word	antd	Word	documents	Word icon (Ant Design)	{word}	{"component": "FileWordOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
392	60969432-024d-4843-b674-c0a1d603c322	antd:file-image	antd	Image File	documents	Image file icon (Ant Design)	{image,file}	{"component": "FileImageOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
393	66e1964c-426a-4622-8f19-c6d8b4d8f01a	antd:file-zip	antd	Zip	documents	Zip file icon (Ant Design)	{zip}	{"component": "FileZipOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
394	66cd8e91-1d3d-4847-9934-6a66bde2505e	antd:cloud	antd	Cloud	technology	Cloud icon (Ant Design)	{cloud}	{"component": "CloudOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
395	59a1dfad-f9f0-49d1-b54b-4078e436b949	antd:cloud-upload	antd	Cloud Upload	technology	Cloud upload icon (Ant Design)	{cloud,upload}	{"component": "CloudUploadOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
396	2a5e1616-a620-4ce4-8303-1a7e77783e11	antd:cloud-download	antd	Cloud Download	technology	Cloud download icon (Ant Design)	{cloud,download}	{"component": "CloudDownloadOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
397	bc3be367-a22f-469d-827d-0df4196b5361	antd:sync	antd	Sync	actions	Sync icon (Ant Design)	{sync}	{"component": "SyncOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
398	fb5d98b7-e25a-499f-9190-48edb980180d	antd:swap	antd	Swap	actions	Swap icon (Ant Design)	{swap}	{"component": "SwapOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
399	ffc0cb51-0568-4afd-8c7f-9a4d3a0db051	antd:retweet	antd	Retweet	actions	Retweet icon (Ant Design)	{retweet}	{"component": "RetweetOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
400	3f54ffd9-3219-4a2b-95ac-b9c1118c4fb2	antd:enter	antd	Enter	navigation	Enter icon (Ant Design)	{enter}	{"component": "EnterOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
401	5e4efe16-4675-4fba-97f9-05acc5f1747a	antd:logout	antd	Logout	authentication	Logout icon (Ant Design)	{logout}	{"component": "LogoutOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
402	1613c11d-c541-4ebe-8aab-df75c758a5ca	antd:login	antd	Login	authentication	Login icon (Ant Design)	{login}	{"component": "LoginOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
403	cdb5c870-5212-429a-98f2-2e23c8fed26e	antd:translation	antd	Translation	communication	Translation icon (Ant Design)	{translation}	{"component": "TranslationOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
404	40d583c3-426a-4df8-ac49-d7ce96160a67	antd:font-size	antd	Font Size	text	Font size icon (Ant Design)	{font}	{"component": "FontSizeOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
405	2632d0ed-1f3e-4903-8e31-8f3c6dba546a	antd:bold	antd	Bold	text	Bold icon (Ant Design)	{bold}	{"component": "BoldOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
406	c8e9ae3f-6a87-4038-a872-71a67aed2c5f	antd:italic	antd	Italic	text	Italic icon (Ant Design)	{italic}	{"component": "ItalicOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
407	6f0c296a-464f-4dcd-a776-df3bbcc78212	antd:underline	antd	Underline	text	Underline icon (Ant Design)	{underline}	{"component": "UnderlineOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
408	791bb903-7a43-461e-9053-ace267036aa4	antd:strikethrough	antd	Strikethrough	text	Strikethrough icon (Ant Design)	{strikethrough}	{"component": "StrikethroughOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
409	01f5ef67-8a10-49e3-8c34-89623e6d6f32	antd:highlight	antd	Highlight	text	Highlight icon (Ant Design)	{highlight}	{"component": "HighlightOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
410	4d8c11c4-3bc9-4ed0-ba4f-a5f86c24a067	antd:align-left	antd	Align Left	text	Align left icon (Ant Design)	{align,left}	{"component": "AlignLeftOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
411	a7fd2358-541d-4638-a6c5-fb0d95f6c225	antd:align-center	antd	Align Center	text	Align center icon (Ant Design)	{align,center}	{"component": "AlignCenterOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
412	8aab8ccd-c3bb-457a-b331-52bd60c34f4d	antd:align-right	antd	Align Right	text	Align right icon (Ant Design)	{align,right}	{"component": "AlignRightOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
413	3e531713-0184-4081-ae6d-a8be743d7875	antd:ordered-list	antd	Ordered List	text	Ordered list icon (Ant Design)	{list,ordered}	{"component": "OrderedListOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
416	102f9af5-9de4-4141-9a8c-a5e7d97319f3	antd:console-sql	antd	SQL	development	SQL console icon (Ant Design)	{sql}	{"component": "ConsoleSqlOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
417	79e6973b-a8de-4f45-ba95-aa63f318b94b	antd:branches	antd	Branches	development	Branches icon (Ant Design)	{branches,git}	{"component": "BranchesOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
418	c05b1f00-fa59-4d15-a72a-6af909863bd8	antd:gitlab	antd	GitLab	development	GitLab icon (Ant Design)	{gitlab}	{"component": "GitlabOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
419	ce070fe7-9b2a-435c-94db-d981d55f43a0	antd:html5	antd	HTML5	development	HTML5 icon (Ant Design)	{html5}	{"component": "Html5Outlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
420	45d53168-3f36-4026-836b-4aab27995369	antd:css3	antd	CSS3	development	CSS3 icon (Ant Design)	{css3}	{"component": "Css3Outlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
421	7f3c91a9-35a7-4443-863b-54119e79df23	antd:js	antd	JavaScript	development	JavaScript icon (Ant Design)	{javascript}	{"component": "JavascriptOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
422	916b1526-5b7a-48fe-96c7-0d766ec69527	antd:python	antd	Python	development	Python icon (Ant Design)	{python}	{"component": "PythonOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
423	bd4333aa-716d-4220-8c99-724f49fcb7f6	antd:java	antd	Java	development	Java icon (Ant Design)	{java}	{"component": "JavaOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
424	76701c11-6e4c-48e9-9cb3-0d4f1c321397	antd:node	antd	Node	development	Node icon (Ant Design)	{node}	{"component": "NodeIndexOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
425	9d0c18f2-fea4-4050-9534-58015208b041	antd:react	antd	React	development	React icon (Ant Design)	{react}	{"component": "ReactOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
426	ce584806-a352-482c-8b03-a1170adcd26b	antd:vue	antd	Vue	development	Vue icon (Ant Design)	{vue}	{"component": "VueOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
427	7473d900-c330-4fc6-8cd7-f77a8af9bcb3	antd:angular	antd	Angular	development	Angular icon (Ant Design)	{angular}	{"component": "AngularOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
428	2f5eba5a-0de8-4a06-8b17-c72fa429f4b2	antd:docker	antd	Docker	development	Docker icon (Ant Design)	{docker}	{"component": "DockerOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
429	0485ce6a-3732-486c-a4c0-91016723c96c	antd:linux	antd	Linux	development	Linux icon (Ant Design)	{linux}	{"component": "LinuxOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
430	565e4ed7-ad36-40da-9b37-6d52349cda7c	antd:windows	antd	Windows	development	Windows icon (Ant Design)	{windows}	{"component": "WindowsOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
431	7bc1f3ea-db34-4871-a02d-1ba7fc326c13	antd:apple	antd	Apple	development	Apple icon (Ant Design)	{apple}	{"component": "AppleOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
432	bc933b54-240c-4516-9e2d-14b1d3bf50a2	antd:android	antd	Android	development	Android icon (Ant Design)	{android}	{"component": "AndroidOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
433	bfb1577a-9c8a-4bc6-b790-eb97f082333d	antd:chrome	antd	Chrome	development	Chrome icon (Ant Design)	{chrome}	{"component": "ChromeOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
434	eb7c9d0f-8469-460b-864b-244bfcc4daaa	antd:firefox	antd	Firefox	development	Firefox icon (Ant Design)	{firefox}	{"component": "FirefoxOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
435	634f30db-b3df-4b1b-a81c-1d7a20786a3d	antd:safari	antd	Safari	development	Safari icon (Ant Design)	{safari}	{"component": "SafariOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
436	95ae85fc-c060-4c2a-8b65-2344013e28d6	antd:edge	antd	Edge	development	Edge icon (Ant Design)	{edge}	{"component": "EdgeOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
437	27390672-670d-4ccf-b2cb-a33c2fb798d7	antd:opera	antd	Opera	development	Opera icon (Ant Design)	{opera}	{"component": "OperaOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
438	c49d6d5d-a72d-4c48-afd6-2822db72372a	antd:ie	antd	Internet Explorer	development	IE icon (Ant Design)	{ie}	{"component": "IeOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
439	e8279eed-9fe0-4ed8-90e0-79434371b650	antd:brave	antd	Brave	development	Brave icon (Ant Design)	{brave}	{"component": "BraveOutlined"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
440	12ce0691-08a0-4876-8c39-f3476c4f0e3e	smily:laughing	smily	Laughing	emotions	Laughing emoji	{laughing,lol,😂}	{"emoji": "😂", "unicode": "U+1F602"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
441	e12ff978-3b0b-4021-b20c-d07f930db500	smily:joy	smily	Joy	emotions	Joy emoji	{joy,tears,😂}	{"emoji": "😂", "unicode": "U+1F602"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
442	d793f4db-2bb0-4681-93d1-0c6c4c40e227	smily:grinning	smily	Grinning	emotions	Grinning emoji	{grinning,😀}	{"emoji": "😀", "unicode": "U+1F600"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
443	87466880-0352-4525-b456-849e41b24810	smily:wink	smily	Wink	emotions	Wink emoji	{wink,😉}	{"emoji": "😉", "unicode": "U+1F609"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
444	e770aac0-802a-4be5-bda4-f9e18443fce2	smily:kiss	smily	Kiss	emotions	Kiss emoji	{kiss,😘}	{"emoji": "😘", "unicode": "U+1F618"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
445	8eafe67c-ba5a-44fe-9d3a-a12dab3fc060	smily:love	smily	Love Eyes	emotions	Love eyes emoji	{love,eyes,😍}	{"emoji": "😍", "unicode": "U+1F60D"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
446	37d05978-120a-43b0-94fd-885585f6c4b1	smily:cool	smily	Cool	emotions	Cool emoji	{cool,😎}	{"emoji": "😎", "unicode": "U+1F60E"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
447	1e6256b1-4da9-4803-a912-36a76504662d	smily:thinking	smily	Thinking	emotions	Thinking emoji	{thinking,🤔}	{"emoji": "🤔", "unicode": "U+1F914"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
448	3cde03d9-3076-4994-b450-7c4199edb23f	smily:shushing	smily	Shushing	emotions	Shushing emoji	{shushing,🤫}	{"emoji": "🤫", "unicode": "U+1F92B"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
449	c2a486cf-d4f0-460f-8d02-a3fb6fd354ff	smily:zipper-mouth	smily	Zipper Mouth	emotions	Zipper mouth emoji	{zipper,🤐}	{"emoji": "🤐", "unicode": "U+1F910"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
450	edea2332-26f2-4c6c-84cd-36781e36871c	smily:raised-eyebrow	smily	Raised Eyebrow	emotions	Raised eyebrow emoji	{raised,eyebrow,🤨}	{"emoji": "🤨", "unicode": "U+1F928"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
451	a8ed4f39-eed1-4013-8ea1-670ab900ea65	smily:neutral	smily	Neutral	emotions	Neutral face emoji	{neutral,😐}	{"emoji": "😐", "unicode": "U+1F610"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
452	056bb106-df44-40c3-8c65-de9dbc40303a	smily:expressionless	smily	Expressionless	emotions	Expressionless emoji	{expressionless,😑}	{"emoji": "😑", "unicode": "U+1F611"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
453	55f0c8b5-733a-4c81-a614-ccd9b175c585	smily:rolling-eyes	smily	Rolling Eyes	emotions	Rolling eyes emoji	{rolling,eyes,🙄}	{"emoji": "🙄", "unicode": "U+1F644"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
454	7027035d-6872-4378-947e-49232acd88d8	smily:sad	smily	Sad	emotions	Sad emoji	{sad,😢}	{"emoji": "😢", "unicode": "U+1F622"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
455	5a016936-bd01-4887-9b03-24ef56c1485b	smily:crying	smily	Crying	emotions	Crying emoji	{crying,😭}	{"emoji": "😭", "unicode": "U+1F62D"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
456	c7e3c35c-e4f4-48a6-8beb-5f1e07747ea9	smily:angry	smily	Angry	emotions	Angry emoji	{angry,😠}	{"emoji": "😠", "unicode": "U+1F620"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
457	4e187d9e-2f10-4a0e-a17e-ae8f88e23bc4	smily:rage	smily	Rage	emotions	Rage emoji	{rage,😡}	{"emoji": "😡", "unicode": "U+1F621"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
458	93f71e37-ef24-4c55-b8ee-766914ca5179	smily:confused	smily	Confused	emotions	Confused emoji	{confused,😕}	{"emoji": "😕", "unicode": "U+1F615"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
459	36b04689-9515-4ab2-9222-276c7972319b	smily:worried	smily	Worried	emotions	Worried emoji	{worried,😟}	{"emoji": "😟", "unicode": "U+1F61F"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
460	55439628-91c5-4357-bc86-798a37b9a07f	smily:slightly-frowning	smily	Slightly Frowning	emotions	Slightly frowning emoji	{frowning,🙁}	{"emoji": "🙁", "unicode": "U+1F641"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
461	fd8e7d66-4919-4e44-9623-a73653afa339	smily:open-mouth	smily	Open Mouth	emotions	Open mouth emoji	{open,mouth,😮}	{"emoji": "😮", "unicode": "U+1F62E"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
462	6bc55001-56d1-4b78-b229-6abe68632944	smily:hushed	smily	Hushed	emotions	Hushed emoji	{hushed,😯}	{"emoji": "😯", "unicode": "U+1F62F"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
463	2eb60672-9348-4e95-9b42-a496bf6011e1	smily:astonished	smily	Astonished	emotions	Astonished emoji	{astonished,😲}	{"emoji": "😲", "unicode": "U+1F632"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
464	a94f86c7-3cb9-426e-9409-c9ab615b8382	smily:flushed	smily	Flushed	emotions	Flushed emoji	{flushed,😳}	{"emoji": "😳", "unicode": "U+1F633"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
465	ff461912-d1ac-481c-baeb-6fef2bd5becf	smily:pleading	smily	Pleading	emotions	Pleading emoji	{pleading,🥺}	{"emoji": "🥺", "unicode": "U+1F97A"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
466	a568aba9-4627-4b70-b4df-b549104e5301	smily:relieved	smily	Relieved	emotions	Relieved emoji	{relieved,😌}	{"emoji": "😌", "unicode": "U+1F60C"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
467	799347f3-ebfb-43cd-ad6e-7daeb64b1891	smily:pensive	smily	Pensive	emotions	Pensive emoji	{pensive,😔}	{"emoji": "😔", "unicode": "U+1F614"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
468	99ca5870-6c79-4509-902b-39c34edd785d	smily:sleepy	smily	Sleepy	emotions	Sleepy emoji	{sleepy,😪}	{"emoji": "😪", "unicode": "U+1F62A"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
469	b7c0781f-9c73-41d8-8e6e-f717abf05ebe	smily:drooling	smily	Drooling	emotions	Drooling emoji	{drooling,🤤}	{"emoji": "🤤", "unicode": "U+1F924"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
470	82ec7f64-1c57-421b-8d3b-37eed71678d8	smily:sleeping	smily	Sleeping	emotions	Sleeping emoji	{sleeping,😴}	{"emoji": "😴", "unicode": "U+1F634"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
471	83623bdc-4dcb-4020-9e00-4ffc438aa8a3	smily:mask	smily	Mask	emotions	Mask emoji	{mask,😷}	{"emoji": "😷", "unicode": "U+1F637"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
472	ae2c58d4-4ad4-4190-bb65-9394258afa4a	smily:face-with-thermometer	smily	Sick	emotions	Sick emoji	{sick,thermometer,🤒}	{"emoji": "🤒", "unicode": "U+1F912"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
473	ff6ba749-7333-445b-952c-2c8a1b18b89f	smily:face-with-head-bandage	smily	Injured	emotions	Injured emoji	{injured,bandage,🤕}	{"emoji": "🤕", "unicode": "U+1F915"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
474	3cd86580-7849-48de-b3d5-a73d236d5bbb	smily:nauseated	smily	Nauseated	emotions	Nauseated emoji	{nauseated,🤢}	{"emoji": "🤢", "unicode": "U+1F922"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
475	dd4a1c88-aed7-4b5d-8453-9881c088755d	smily:vomiting	smily	Vomiting	emotions	Vomiting emoji	{vomiting,🤮}	{"emoji": "🤮", "unicode": "U+1F92E"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
476	700b4046-25ec-4f38-9854-7035b686ab5e	smily:sneezing	smily	Sneezing	emotions	Sneezing emoji	{sneezing,🤧}	{"emoji": "🤧", "unicode": "U+1F927"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
477	bb66465a-61c9-4ca3-9297-23b22d6ab489	smily:hot	smily	Hot	emotions	Hot face emoji	{hot,🥵}	{"emoji": "🥵", "unicode": "U+1F975"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
478	a859b795-11de-4e80-a427-b196bb7acc0a	smily:cold	smily	Cold	emotions	Cold face emoji	{cold,🥶}	{"emoji": "🥶", "unicode": "U+1F976"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
479	22a35397-f182-41e9-94b7-401927af857a	smily:woozy	smily	Woozy	emotions	Woozy emoji	{woozy,🥴}	{"emoji": "🥴", "unicode": "U+1F974"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
480	a5cb6903-809c-44d1-80c5-64eb1db14b87	smily:dizzy	smily	Dizzy	emotions	Dizzy emoji	{dizzy,😵}	{"emoji": "😵", "unicode": "U+1F635"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
481	a21b03aa-8118-4610-8138-ba35793f031e	smily:exploding-head	smily	Exploding Head	emotions	Exploding head emoji	{exploding,head,🤯}	{"emoji": "🤯", "unicode": "U+1F92F"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
482	2edbd900-702d-4829-9975-179efda14573	smily:cowboy	smily	Cowboy	emotions	Cowboy emoji	{cowboy,🤠}	{"emoji": "🤠", "unicode": "U+1F920"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
483	e6ee883f-be31-4b15-bd57-f94de46ed350	smily:partying	smily	Partying	emotions	Partying emoji	{partying,🥳}	{"emoji": "🥳", "unicode": "U+1F973"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
484	39f9535f-0924-421e-979f-efc8b2f2daa0	smily:disguised	smily	Disguised	emotions	Disguised emoji	{disguised,🥸}	{"emoji": "🥸", "unicode": "U+1F978"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
485	9951d4bf-3996-47ca-9caa-bfb8c06ec93e	smily:sunglasses	smily	Sunglasses	emotions	Sunglasses emoji	{sunglasses,😎}	{"emoji": "😎", "unicode": "U+1F60E"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
486	dc32d579-80f5-480f-bead-1e67caed4095	smily:nerd	smily	Nerd	emotions	Nerd emoji	{nerd,🤓}	{"emoji": "🤓", "unicode": "U+1F913"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
487	ef114eef-1ccf-40ef-8252-0102f9388285	smily:monocle	smily	Monocle	emotions	Monocle emoji	{monocle,🧐}	{"emoji": "🧐", "unicode": "U+1F9D0"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
488	a69e7f47-4faa-4c2d-8287-6f2ea207856e	smily:confused-face	smily	Confused Face	emotions	Confused face emoji	{confused,😕}	{"emoji": "😕", "unicode": "U+1F615"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
489	a508cf58-d1ef-469c-8931-8b71178f7c53	smily:worried-face	smily	Worried Face	emotions	Worried face emoji	{worried,😟}	{"emoji": "😟", "unicode": "U+1F61F"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
490	d7557de4-d8d2-4780-95c1-4ef9fc04a614	smily:slightly-frowning-face	smily	Slightly Frowning Face	emotions	Slightly frowning face emoji	{frowning,🙁}	{"emoji": "🙁", "unicode": "U+1F641"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
491	0f8ab8bb-d8c1-4b38-804d-5a3c746e68d9	smily:open-mouth-face	smily	Open Mouth Face	emotions	Open mouth face emoji	{open,mouth,😮}	{"emoji": "😮", "unicode": "U+1F62E"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
492	a2cce378-1028-43fd-9e1f-224d6770d066	smily:hushed-face	smily	Hushed Face	emotions	Hushed face emoji	{hushed,😯}	{"emoji": "😯", "unicode": "U+1F62F"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
493	c0913804-e141-4ade-84c0-fc58a36e4422	smily:astonished-face	smily	Astonished Face	emotions	Astonished face emoji	{astonished,😲}	{"emoji": "😲", "unicode": "U+1F632"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
494	026fc4f1-8e1f-497d-a3cb-079819867caf	smily:flushed-face	smily	Flushed Face	emotions	Flushed face emoji	{flushed,😳}	{"emoji": "😳", "unicode": "U+1F633"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
495	d04033b1-f983-47ba-bf72-098a39be2f24	smily:pleading-face	smily	Pleading Face	emotions	Pleading face emoji	{pleading,🥺}	{"emoji": "🥺", "unicode": "U+1F97A"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
496	cbd4f404-57d0-4b1e-8dd6-8ffa2d9bb009	smily:frowning-face	smily	Frowning Face	emotions	Frowning face emoji	{frowning,☹️}	{"emoji": "☹️", "unicode": "U+2639"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
497	4d6bd4aa-3734-4211-9cc8-b25a5e371955	smily:anguished	smily	Anguished	emotions	Anguished emoji	{anguished,😧}	{"emoji": "😧", "unicode": "U+1F627"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
498	263bed3b-97b1-4132-99cc-4118db3f4f3d	smily:fearful	smily	Fearful	emotions	Fearful emoji	{fearful,😨}	{"emoji": "😨", "unicode": "U+1F628"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
499	a1455ff4-bffe-4618-939a-f8906b0dd09e	smily:cold-sweat	smily	Cold Sweat	emotions	Cold sweat emoji	{cold,sweat,😰}	{"emoji": "😰", "unicode": "U+1F630"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
500	32e972c8-f4a6-408c-9c1c-97b39a4b5b8e	smily:disappointed-relieved	smily	Disappointed Relieved	emotions	Disappointed relieved emoji	{disappointed,relieved,😥}	{"emoji": "😥", "unicode": "U+1F625"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
501	f0ba5588-356c-40e2-abb8-668d3576fbe5	smily:cry	smily	Cry	emotions	Cry emoji	{cry,😢}	{"emoji": "😢", "unicode": "U+1F622"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
502	c70da891-f12a-42a0-8a0d-894e05056163	smily:sob	smily	Sob	emotions	Sob emoji	{sob,😭}	{"emoji": "😭", "unicode": "U+1F62D"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
503	94d1c505-d0f8-4087-a131-cb761e055885	smily:scream	smily	Scream	emotions	Scream emoji	{scream,😱}	{"emoji": "😱", "unicode": "U+1F631"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
505	a2ee515c-4791-4a27-850f-10bf6a0928f5	smily:persevere	smily	Persevere	emotions	Persevere emoji	{persevere,😣}	{"emoji": "😣", "unicode": "U+1F623"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
506	2578fbad-7977-46f7-bdea-f88b519e9d44	smily:disappointed	smily	Disappointed	emotions	Disappointed emoji	{disappointed,😞}	{"emoji": "😞", "unicode": "U+1F61E"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
507	18a98b59-692c-4781-a94f-a08c534390e7	smily:sweat	smily	Sweat	emotions	Sweat emoji	{sweat,😓}	{"emoji": "😓", "unicode": "U+1F613"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
508	1be8fa54-90ca-4f4a-a4fa-03d63868c119	smily:weary	smily	Weary	emotions	Weary emoji	{weary,😩}	{"emoji": "😩", "unicode": "U+1F629"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
509	3dcd4d08-98fc-487f-a0bf-11b99bfe3037	smily:tired	smily	Tired	emotions	Tired emoji	{tired,😫}	{"emoji": "😫", "unicode": "U+1F62B"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
510	fef0a562-3c43-47cd-b557-a4370a7bed03	smily:yawning	smily	Yawning	emotions	Yawning emoji	{yawning,🥱}	{"emoji": "🥱", "unicode": "U+1F971"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
511	3c0b9a46-6087-4ffb-bfde-a87a4bd7285c	smily:steam-nose	smily	Steam Nose	emotions	Steam nose emoji	{steam,nose,😤}	{"emoji": "😤", "unicode": "U+1F624"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
512	192e0ac2-ad81-4666-9231-ed67553aabee	smily:pouting	smily	Pouting	emotions	Pouting emoji	{pouting,😡}	{"emoji": "😡", "unicode": "U+1F621"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
513	8add6b7d-de3b-4b26-9dad-4d0e6e1295f4	smily:angry-face	smily	Angry Face	emotions	Angry face emoji	{angry,😠}	{"emoji": "😠", "unicode": "U+1F620"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
514	57241d95-caaa-4e05-9776-075f2f70766a	smily:cursing	smily	Cursing	emotions	Cursing emoji	{cursing,🤬}	{"emoji": "🤬", "unicode": "U+1F92C"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
515	38e42855-5c4b-4f0b-946d-6de061cd174d	smily:symbols-over-mouth	smily	Symbols Over Mouth	emotions	Symbols over mouth emoji	{symbols,mouth,🤭}	{"emoji": "🤭", "unicode": "U+1F92D"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
516	1641666f-14c7-4872-91c6-04fbf9fb1bf1	smily:hand-over-mouth	smily	Hand Over Mouth	emotions	Hand over mouth emoji	{hand,mouth,🤭}	{"emoji": "🤭", "unicode": "U+1F92D"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
517	796caeaf-b957-4f54-9175-e28f33e874f6	smily:shushing-face	smily	Shushing Face	emotions	Shushing face emoji	{shushing,🤫}	{"emoji": "🤫", "unicode": "U+1F92B"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
518	7786702c-8404-4c50-b0db-73c2ca31aa92	smily:lying	smily	Lying	emotions	Lying emoji	{lying,🤥}	{"emoji": "🤥", "unicode": "U+1F925"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
519	e26e67f1-4b88-42fa-9ace-93955b6ab454	smily:no-mouth	smily	No Mouth	emotions	No mouth emoji	{no,mouth,😶}	{"emoji": "😶", "unicode": "U+1F636"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
520	50a5f5f9-7ccb-471e-a11c-86601c7951c5	smily:smirk	smily	Smirk	emotions	Smirk emoji	{smirk,😏}	{"emoji": "😏", "unicode": "U+1F60F"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
521	db9b279d-edde-43e9-8bed-265d750a77a0	smily:unamused	smily	Unamused	emotions	Unamused emoji	{unamused,😒}	{"emoji": "😒", "unicode": "U+1F612"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
522	7f74b638-152e-47cd-95aa-1b137c5d7308	smily:roll-eyes	smily	Roll Eyes	emotions	Roll eyes emoji	{roll,eyes,🙄}	{"emoji": "🙄", "unicode": "U+1F644"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
523	2c6ce3cd-3195-44c4-ae57-7ff880066c19	smily:grimacing	smily	Grimacing	emotions	Grimacing emoji	{grimacing,😬}	{"emoji": "😬", "unicode": "U+1F62C"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
524	60c7dfa9-ad37-466c-b885-e30a4c5e55db	smily:lying-face	smily	Lying Face	emotions	Lying face emoji	{lying,🤥}	{"emoji": "🤥", "unicode": "U+1F925"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
525	bf51e065-83d2-4644-bc9e-28638c34eec9	smily:relieved-face	smily	Relieved Face	emotions	Relieved face emoji	{relieved,😌}	{"emoji": "😌", "unicode": "U+1F60C"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
526	c8797e71-b34d-408f-b1bd-f1476fa0cd34	smily:pensive-face	smily	Pensive Face	emotions	Pensive face emoji	{pensive,😔}	{"emoji": "😔", "unicode": "U+1F614"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
527	7a25e754-d2dc-4792-b7d9-9e20169dcc62	smily:sleepy-face	smily	Sleepy Face	emotions	Sleepy face emoji	{sleepy,😪}	{"emoji": "😪", "unicode": "U+1F62A"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
528	6c7853fb-5612-434a-ab3c-0b9714b73528	smily:drooling-face	smily	Drooling Face	emotions	Drooling face emoji	{drooling,🤤}	{"emoji": "🤤", "unicode": "U+1F924"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
529	43339dda-9299-45f4-a630-4e61553a2937	smily:sleeping-face	smily	Sleeping Face	emotions	Sleeping face emoji	{sleeping,😴}	{"emoji": "😴", "unicode": "U+1F634"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
530	d920463b-3d85-4376-b233-dfaddd7c6d65	smily:face-with-medical-mask	smily	Medical Mask	emotions	Medical mask emoji	{mask,medical,😷}	{"emoji": "😷", "unicode": "U+1F637"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
533	a9213bf3-9ed4-4731-aec2-e2885e9e4c88	smily:nauseated-face	smily	Nauseated Face	emotions	Nauseated face emoji	{nauseated,🤢}	{"emoji": "🤢", "unicode": "U+1F922"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
534	82179250-f2a3-4419-8979-bc2459556745	smily:face-vomiting	smily	Vomiting Face	emotions	Face vomiting emoji	{vomiting,🤮}	{"emoji": "🤮", "unicode": "U+1F92E"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
535	a34cbdb4-7590-44af-aae9-87cc3eb9a77b	smily:sneezing-face	smily	Sneezing Face	emotions	Sneezing face emoji	{sneezing,🤧}	{"emoji": "🤧", "unicode": "U+1F927"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
536	2231d8ee-36ef-48d6-a071-a457e93edf4a	smily:hot-face	smily	Hot Face	emotions	Hot face emoji	{hot,🥵}	{"emoji": "🥵", "unicode": "U+1F975"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
537	b8ea86e6-dfb9-4813-9bc0-d4f0a9dcfb86	smily:cold-face	smily	Cold Face	emotions	Cold face emoji	{cold,🥶}	{"emoji": "🥶", "unicode": "U+1F976"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
538	3072039b-0a6b-49a8-be67-6f535d2907dd	smily:woozy-face	smily	Woozy Face	emotions	Woozy face emoji	{woozy,🥴}	{"emoji": "🥴", "unicode": "U+1F974"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
539	0022104f-6915-440d-95d6-f5db25c93522	smily:dizzy-face	smily	Dizzy Face	emotions	Dizzy face emoji	{dizzy,😵}	{"emoji": "😵", "unicode": "U+1F635"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
540	55b7b265-a8ad-4a47-a0a6-b7911a99a518	smily:exploding-head-face	smily	Exploding Head Face	emotions	Exploding head face emoji	{exploding,head,🤯}	{"emoji": "🤯", "unicode": "U+1F92F"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
541	561d804b-a8a6-4a4f-8913-f55edae2dfb7	smily:cowboy-hat-face	smily	Cowboy Hat	emotions	Cowboy hat face emoji	{cowboy,hat,🤠}	{"emoji": "🤠", "unicode": "U+1F920"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
542	15789b6d-3214-47d8-99df-ec4ab4cb9142	smily:partying-face	smily	Partying Face	emotions	Partying face emoji	{partying,🥳}	{"emoji": "🥳", "unicode": "U+1F973"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
543	2a296a37-343b-44ac-8ae1-ff9186c6e359	smily:disguised-face	smily	Disguised Face	emotions	Disguised face emoji	{disguised,🥸}	{"emoji": "🥸", "unicode": "U+1F978"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
544	d5565e7c-68c9-41cc-af71-8299561b6cbd	smily:sunglasses-face	smily	Sunglasses Face	emotions	Sunglasses face emoji	{sunglasses,😎}	{"emoji": "😎", "unicode": "U+1F60E"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
545	919bc578-2c62-4b76-b246-bae7b7a732cc	smily:nerd-face	smily	Nerd Face	emotions	Nerd face emoji	{nerd,🤓}	{"emoji": "🤓", "unicode": "U+1F913"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
546	86ccb59c-45b4-4eb9-8a21-7ddc6a46e95e	smily:face-with-monocle	smily	Monocle	emotions	Face with monocle emoji	{monocle,🧐}	{"emoji": "🧐", "unicode": "U+1F9D0"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
547	0f24687a-3507-4562-b1c5-ef3d67e872bc	smily:confused-face-emoji	smily	Confused Face Emoji	emotions	Confused face emoji	{confused,😕}	{"emoji": "😕", "unicode": "U+1F615"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
548	27a4d98f-ab0b-41e9-b637-870479745d51	smily:worried-face-emoji	smily	Worried Face Emoji	emotions	Worried face emoji	{worried,😟}	{"emoji": "😟", "unicode": "U+1F61F"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
549	b4c80e4c-e0f9-4f56-9655-e5301e1a2420	smily:slightly-frowning-face-emoji	smily	Slightly Frowning Face Emoji	emotions	Slightly frowning face emoji	{frowning,🙁}	{"emoji": "🙁", "unicode": "U+1F641"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
550	42b59f84-7210-480a-b8db-6ee3ed113c1d	smily:open-mouth-face-emoji	smily	Open Mouth Face Emoji	emotions	Open mouth face emoji	{open,mouth,😮}	{"emoji": "😮", "unicode": "U+1F62E"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
551	280ea013-53c8-4075-9c1e-ecb164cbf478	smily:hushed-face-emoji	smily	Hushed Face Emoji	emotions	Hushed face emoji	{hushed,😯}	{"emoji": "😯", "unicode": "U+1F62F"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
552	f0581c2b-3c19-40eb-8570-bc940a1a36c7	smily:astonished-face-emoji	smily	Astonished Face Emoji	emotions	Astonished face emoji	{astonished,😲}	{"emoji": "😲", "unicode": "U+1F632"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
553	c329e809-e56a-47a2-91e9-f8bb7da3f291	smily:flushed-face-emoji	smily	Flushed Face Emoji	emotions	Flushed face emoji	{flushed,😳}	{"emoji": "😳", "unicode": "U+1F633"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
554	056a69d8-562d-4157-bb39-fac1f8d2be98	smily:pleading-face-emoji	smily	Pleading Face Emoji	emotions	Pleading face emoji	{pleading,🥺}	{"emoji": "🥺", "unicode": "U+1F97A"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
555	8adf64b3-765a-4ba2-ad2e-94ad801c108f	smily:frowning-face-emoji	smily	Frowning Face Emoji	emotions	Frowning face emoji	{frowning,☹️}	{"emoji": "☹️", "unicode": "U+2639"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
556	3dad8d89-f285-46af-9c66-2a78e6aa3b4a	smily:anguished-face	smily	Anguished Face	emotions	Anguished face emoji	{anguished,😧}	{"emoji": "😧", "unicode": "U+1F627"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
557	89f297f6-698b-4335-b4b0-61b697ed2fe8	smily:fearful-face	smily	Fearful Face	emotions	Fearful face emoji	{fearful,😨}	{"emoji": "😨", "unicode": "U+1F628"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
558	6f547f36-9436-4011-95d3-589b68432a69	smily:cold-sweat-face	smily	Cold Sweat Face	emotions	Cold sweat face emoji	{cold,sweat,😰}	{"emoji": "😰", "unicode": "U+1F630"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
559	6357e3a2-4141-41b9-aad8-4e99cfeb5257	smily:disappointed-relieved-face	smily	Disappointed Relieved Face	emotions	Disappointed relieved face emoji	{disappointed,relieved,😥}	{"emoji": "😥", "unicode": "U+1F625"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
560	be20d91f-9329-47c3-95db-4990ff37d19b	smily:cry-face	smily	Cry Face	emotions	Cry face emoji	{cry,😢}	{"emoji": "😢", "unicode": "U+1F622"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
561	5f262c38-63bf-457e-b73d-5d92482c91c0	smily:sob-face	smily	Sob Face	emotions	Sob face emoji	{sob,😭}	{"emoji": "😭", "unicode": "U+1F62D"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
562	4a50d531-15a2-461b-b730-1e7afedc8d57	smily:scream-face	smily	Scream Face	emotions	Scream face emoji	{scream,😱}	{"emoji": "😱", "unicode": "U+1F631"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
564	7163842d-ed74-4ffd-be47-4a1874ea5193	smily:persevere-face	smily	Persevere Face	emotions	Persevere face emoji	{persevere,😣}	{"emoji": "😣", "unicode": "U+1F623"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
565	f7ad4da9-74de-4117-a7b0-d3ce709942fe	smily:disappointed-face	smily	Disappointed Face	emotions	Disappointed face emoji	{disappointed,😞}	{"emoji": "😞", "unicode": "U+1F61E"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
566	34f66ed1-032d-45ae-998a-3b67fdf307dd	smily:sweat-face	smily	Sweat Face	emotions	Sweat face emoji	{sweat,😓}	{"emoji": "😓", "unicode": "U+1F613"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
567	9e6f6abb-4944-4154-a4ba-c73111830ac5	smily:weary-face	smily	Weary Face	emotions	Weary face emoji	{weary,😩}	{"emoji": "😩", "unicode": "U+1F629"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
568	90865431-8323-48e4-8732-0ada9c49f755	smily:tired-face	smily	Tired Face	emotions	Tired face emoji	{tired,😫}	{"emoji": "😫", "unicode": "U+1F62B"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
569	cc3ff2de-3610-4c79-b034-a4c593121bec	smily:yawning-face	smily	Yawning Face	emotions	Yawning face emoji	{yawning,🥱}	{"emoji": "🥱", "unicode": "U+1F971"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
570	c584abd8-e3a6-462d-8c1c-c574dd23a11f	smily:steam-nose-face	smily	Steam Nose Face	emotions	Steam nose face emoji	{steam,nose,😤}	{"emoji": "😤", "unicode": "U+1F624"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
571	583bd51e-70bb-4ccb-bcfa-7c36019d95aa	smily:pouting-face	smily	Pouting Face	emotions	Pouting face emoji	{pouting,😡}	{"emoji": "😡", "unicode": "U+1F621"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
572	b7b0a699-d313-44af-a5e1-03310e4e0cf9	smily:angry-face-emoji	smily	Angry Face Emoji	emotions	Angry face emoji	{angry,😠}	{"emoji": "😠", "unicode": "U+1F620"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
573	2633123e-7675-4649-b8d5-4d1b133a7790	smily:cursing-face	smily	Cursing Face	emotions	Cursing face emoji	{cursing,🤬}	{"emoji": "🤬", "unicode": "U+1F92C"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
574	ce636ed3-8336-4aa6-a7a6-6728e7601f36	smily:symbols-over-mouth-face	smily	Symbols Over Mouth Face	emotions	Symbols over mouth face emoji	{symbols,mouth,🤭}	{"emoji": "🤭", "unicode": "U+1F92D"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
575	17a0c531-f7bc-4ab0-9de8-2b8d34872639	smily:hand-over-mouth-face	smily	Hand Over Mouth Face	emotions	Hand over mouth face emoji	{hand,mouth,🤭}	{"emoji": "🤭", "unicode": "U+1F92D"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
576	ba789027-9442-48e9-8833-6a1b99994174	smily:shushing-face-emoji	smily	Shushing Face Emoji	emotions	Shushing face emoji	{shushing,🤫}	{"emoji": "🤫", "unicode": "U+1F92B"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
577	0c1a7bc3-eb39-414b-b273-e87b8aaca254	smily:lying-face-emoji	smily	Lying Face Emoji	emotions	Lying face emoji	{lying,🤥}	{"emoji": "🤥", "unicode": "U+1F925"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
578	25e6a8d5-5ffd-4cf7-9e81-213494d76511	smily:no-mouth-face	smily	No Mouth Face	emotions	No mouth face emoji	{no,mouth,😶}	{"emoji": "😶", "unicode": "U+1F636"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
579	f53fbee9-a4bf-4f4c-979f-65ed2347ccfb	smily:smirk-face	smily	Smirk Face	emotions	Smirk face emoji	{smirk,😏}	{"emoji": "😏", "unicode": "U+1F60F"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
580	4bec1c1c-6855-4332-9064-5db4b4a4c866	smily:unamused-face	smily	Unamused Face	emotions	Unamused face emoji	{unamused,😒}	{"emoji": "😒", "unicode": "U+1F612"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
581	977de3e4-668e-4414-9c7c-46899db0f9c3	smily:roll-eyes-face	smily	Roll Eyes Face	emotions	Roll eyes face emoji	{roll,eyes,🙄}	{"emoji": "🙄", "unicode": "U+1F644"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
582	119a07aa-94f7-4493-af84-4125b9b27200	smily:grimacing-face	smily	Grimacing Face	emotions	Grimacing face emoji	{grimacing,😬}	{"emoji": "😬", "unicode": "U+1F62C"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
583	11661a54-c46c-41ef-b1bf-9fa2c5cf2edc	smily:lying-face-emoji2	smily	Lying Face Emoji 2	emotions	Lying face emoji	{lying,🤥}	{"emoji": "🤥", "unicode": "U+1F925"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
584	9584a218-1a2e-440b-8a87-086df777c2fa	smily:relieved-face-emoji	smily	Relieved Face Emoji	emotions	Relieved face emoji	{relieved,😌}	{"emoji": "😌", "unicode": "U+1F60C"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
585	ead2d2cc-8081-4785-a284-22044ff4eba5	smily:pensive-face-emoji	smily	Pensive Face Emoji	emotions	Pensive face emoji	{pensive,😔}	{"emoji": "😔", "unicode": "U+1F614"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
586	dd09982b-64c9-4893-8737-67e586aad0c4	smily:sleepy-face-emoji	smily	Sleepy Face Emoji	emotions	Sleepy face emoji	{sleepy,😪}	{"emoji": "😪", "unicode": "U+1F62A"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
587	b315a4c9-bf48-4254-b500-69bbf930bbc7	smily:drooling-face-emoji	smily	Drooling Face Emoji	emotions	Drooling face emoji	{drooling,🤤}	{"emoji": "🤤", "unicode": "U+1F924"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
588	c82734b0-3544-4d42-b900-5828d17a6962	smily:sleeping-face-emoji	smily	Sleeping Face Emoji	emotions	Sleeping face emoji	{sleeping,😴}	{"emoji": "😴", "unicode": "U+1F634"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
589	146c55e7-0a8c-492a-8fee-3d630d3f7d8b	smily:face-with-medical-mask-emoji	smily	Medical Mask Emoji	emotions	Medical mask emoji	{mask,medical,😷}	{"emoji": "😷", "unicode": "U+1F637"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
590	5a09a2a1-4cf7-4533-83b1-1f1705766369	smily:face-with-thermometer-emoji	smily	Thermometer Emoji	emotions	Face with thermometer emoji	{thermometer,🤒}	{"emoji": "🤒", "unicode": "U+1F912"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
591	d7934ee6-2a64-4b6b-8cc9-4733b915f0fa	smily:face-with-head-bandage-emoji	smily	Head Bandage Emoji	emotions	Face with head bandage emoji	{bandage,head,🤕}	{"emoji": "🤕", "unicode": "U+1F915"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
592	8d0d8ffb-629a-48a5-b6cd-7a15e9073aea	smily:nauseated-face-emoji	smily	Nauseated Face Emoji	emotions	Nauseated face emoji	{nauseated,🤢}	{"emoji": "🤢", "unicode": "U+1F922"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
593	47b24bd0-96d8-4b35-9ef3-176145259854	smily:face-vomiting-emoji	smily	Vomiting Face Emoji	emotions	Face vomiting emoji	{vomiting,🤮}	{"emoji": "🤮", "unicode": "U+1F92E"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
594	03e8306b-fc0a-45cf-a133-fad6be750dbf	smily:sneezing-face-emoji	smily	Sneezing Face Emoji	emotions	Sneezing face emoji	{sneezing,🤧}	{"emoji": "🤧", "unicode": "U+1F927"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
595	e1ea72e9-102c-4e1e-b210-4675ade523d1	smily:hot-face-emoji	smily	Hot Face Emoji	emotions	Hot face emoji	{hot,🥵}	{"emoji": "🥵", "unicode": "U+1F975"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
596	f6602ae2-9799-4326-89db-ab95882436bb	smily:cold-face-emoji	smily	Cold Face Emoji	emotions	Cold face emoji	{cold,🥶}	{"emoji": "🥶", "unicode": "U+1F976"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
597	7d40a23a-6de5-4a4b-bc05-0c1089c26e87	smily:woozy-face-emoji	smily	Woozy Face Emoji	emotions	Woozy face emoji	{woozy,🥴}	{"emoji": "🥴", "unicode": "U+1F974"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
598	d613b8f5-e74d-43f0-a2e9-3b4646a72903	smily:dizzy-face-emoji	smily	Dizzy Face Emoji	emotions	Dizzy face emoji	{dizzy,😵}	{"emoji": "😵", "unicode": "U+1F635"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
599	54708d1b-95c9-4b54-936a-bd8948a54cbe	smily:exploding-head-face-emoji	smily	Exploding Head Face Emoji	emotions	Exploding head face emoji	{exploding,head,🤯}	{"emoji": "🤯", "unicode": "U+1F92F"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
600	efd42e3b-5967-4dc1-bc43-55f68562dcae	smily:cowboy-hat-face-emoji	smily	Cowboy Hat Emoji	emotions	Cowboy hat face emoji	{cowboy,hat,🤠}	{"emoji": "🤠", "unicode": "U+1F920"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
601	a109302c-8978-406f-93ef-caa3e78fa5c9	smily:partying-face-emoji	smily	Partying Face Emoji	emotions	Partying face emoji	{partying,🥳}	{"emoji": "🥳", "unicode": "U+1F973"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
602	760a8b72-48b7-4c2b-b1b4-53a1295908ec	smily:disguised-face-emoji	smily	Disguised Face Emoji	emotions	Disguised face emoji	{disguised,🥸}	{"emoji": "🥸", "unicode": "U+1F978"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
603	8866b95d-843c-49ad-8be9-2b5aa8f4b850	smily:sunglasses-face-emoji	smily	Sunglasses Face Emoji	emotions	Sunglasses face emoji	{sunglasses,😎}	{"emoji": "😎", "unicode": "U+1F60E"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
604	b09dfe0e-b6d4-4e71-bd72-66356f533cb9	smily:nerd-face-emoji	smily	Nerd Face Emoji	emotions	Nerd face emoji	{nerd,🤓}	{"emoji": "🤓", "unicode": "U+1F913"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
605	33d46cfa-5a4b-4e7a-a709-3bb4c9f45618	smily:face-with-monocle-emoji	smily	Monocle Emoji	emotions	Face with monocle emoji	{monocle,🧐}	{"emoji": "🧐", "unicode": "U+1F9D0"}	0	f	t	t	1	2026-01-18 23:06:17.883283+00	2026-01-18 23:06:17.883283+00
\.


--
-- Data for Name: integration_providers; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.integration_providers (provider_id, provider_uuid, provider_name, provider_display_name, provider_category, description, documentation_url, required_fields_json, optional_fields_json, metadata_json, is_active, is_builtin, created_at, last_updated) FROM stdin;
1	ff751f49-e9ed-4607-a8c5-e2d81816945e	aws_ses	AWS SES	email	Amazon Simple Email Service for sending transactional and marketing emails	\N	[{"is_secret": false, "field_name": "aws_access_key_id", "description": "Your AWS access key ID", "is_required": true, "display_name": "AWS Access Key ID", "field_type_id": 1}, {"is_secret": true, "field_name": "aws_secret_access_key", "description": "Your AWS secret access key", "is_required": true, "display_name": "AWS Secret Access Key", "field_type_id": 1}, {"is_secret": false, "field_name": "aws_region", "description": "AWS region (e.g., us-east-1, ap-south-1)", "is_required": true, "display_name": "AWS Region", "default_value": "us-east-1", "field_type_id": 1}]	[{"field_name": "from_email", "description": "Default sender email address", "is_required": false, "display_name": "Default From Email", "field_type_id": 15}, {"field_name": "from_name", "description": "Default sender name", "is_required": false, "display_name": "Default From Name", "field_type_id": 1}]	{"api_docs": "https://docs.aws.amazon.com/ses/", "service_url": "https://aws.amazon.com/ses/"}	t	t	2026-01-15 23:29:03.114175+00	2026-01-15 23:29:03.114175+00
2	1a4cca81-3534-42ed-80d4-e49f6035a143	aws_s3	AWS S3	storage	Amazon Simple Storage Service for file and asset storage	\N	[{"is_secret": false, "field_name": "aws_access_key_id", "description": "Your AWS access key ID", "is_required": true, "display_name": "AWS Access Key ID", "field_type_id": 1}, {"is_secret": true, "field_name": "aws_secret_access_key", "description": "Your AWS secret access key", "is_required": true, "display_name": "AWS Secret Access Key", "field_type_id": 1}, {"is_secret": false, "field_name": "bucket_name", "description": "Name of the S3 bucket", "is_required": true, "display_name": "S3 Bucket Name", "field_type_id": 1}, {"is_secret": false, "field_name": "aws_region", "description": "AWS region (e.g., us-east-1, ap-south-1)", "is_required": true, "display_name": "AWS Region", "default_value": "us-east-1", "field_type_id": 1}]	[{"field_name": "bucket_prefix", "description": "Optional prefix/folder path in bucket (e.g., \\"production\\", \\"staging\\"). Assets will be stored under {prefix}/assets/", "is_required": false, "display_name": "Bucket Prefix/Folder", "default_value": "", "field_type_id": 1}, {"field_name": "endpoint_url", "description": "Custom S3 endpoint (for S3-compatible services)", "is_required": false, "display_name": "Custom Endpoint URL", "field_type_id": 17}, {"field_name": "cdn_url", "description": "CDN URL for public asset access", "is_required": false, "display_name": "CDN URL", "field_type_id": 17}]	{"api_docs": "https://docs.aws.amazon.com/s3/", "service_url": "https://aws.amazon.com/s3/"}	t	t	2026-01-15 23:29:03.114175+00	2026-01-15 23:29:03.114175+00
3	19ee2db9-fe43-4856-a35a-908613c432ed	aws_sms	AWS SMS (SNS)	sms	Amazon Simple Notification Service for sending SMS messages	\N	[{"is_secret": false, "field_name": "aws_access_key_id", "description": "Your AWS access key ID", "is_required": true, "display_name": "AWS Access Key ID", "field_type_id": 1}, {"is_secret": true, "field_name": "aws_secret_access_key", "description": "Your AWS secret access key", "is_required": true, "display_name": "AWS Secret Access Key", "field_type_id": 1}, {"is_secret": false, "field_name": "aws_region", "description": "AWS region (e.g., us-east-1, ap-south-1)", "is_required": true, "display_name": "AWS Region", "default_value": "us-east-1", "field_type_id": 1}]	[{"field_name": "sender_id", "description": "Default SMS sender ID", "is_required": false, "display_name": "Sender ID", "field_type_id": 1}]	{"api_docs": "https://docs.aws.amazon.com/sns/", "service_url": "https://aws.amazon.com/sns/"}	t	t	2026-01-15 23:29:03.114175+00	2026-01-15 23:29:03.114175+00
4	c68bf17d-17d6-43ca-9147-7fe381826e5a	ccavenue	CCAvenue	payment	CCAvenue payment gateway for processing online payments	\N	[{"is_secret": false, "field_name": "merchant_id", "description": "Your CCAvenue merchant ID", "is_required": true, "display_name": "Merchant ID", "field_type_id": 1}, {"is_secret": true, "field_name": "access_code", "description": "Your CCAvenue access code", "is_required": true, "display_name": "Access Code", "field_type_id": 1}, {"is_secret": true, "field_name": "working_key", "description": "Your CCAvenue working key (encryption key)", "is_required": true, "display_name": "Working Key", "field_type_id": 1}]	[{"options": ["test", "production"], "field_name": "environment", "description": "Payment environment: test or production", "is_required": false, "display_name": "Environment", "default_value": "test", "field_type_id": 1}, {"field_name": "currency", "description": "Default currency code (e.g., INR, USD)", "is_required": false, "display_name": "Default Currency", "default_value": "INR", "field_type_id": 1}]	{"api_docs": "https://www.ccavenue.com/supportcenter/knowledgebase", "service_url": "https://www.ccavenue.com/"}	t	t	2026-01-15 23:29:03.114175+00	2026-01-15 23:29:03.114175+00
\.


--
-- Data for Name: integrations; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.integrations (integration_id, integration_uuid, company_id, provider_id, provider_name, integration_name, encrypted_credentials, credentials_version, config, integration_type, metadata, is_active, is_default, created_by, last_updated) FROM stdin;
1	ecc260c3-3281-4543-ac5a-aec33e5a34e3	1	2	aws_s3	Default S3 Bucket	+KSUNn9amlUuG51Af4pX08gQmnb4MqUubpTZyZL0WFDJNLH4LqeWqI7nOquSh83y+ucFm+Jwk89rj7ghqT+HaCcnidhMuAdOeT/Z0P4gq0BC9Jtzv2i/T/OcH2wH1Z7xw81P4LuXlhuj70rCg425bB3e4TJswhjEM290ZIfmu7PawajuCVqlrcjOU5yXj9E8ULSBgHPfiH/kjpGYyqEUudPMDtlJP0SJBWIstsfmqGC8NqnimhARAz3CFgmgWoI8bfArz0mAMMeHN7Ac0Y3pqFSIOjDKWdSB2UnFZtN903F7q2m/4j+RzI6vFdQkklwgRCiiSHgLeegMq33Px4X+ZpU//6L+8rAF5gnoCOk=	1	{"url": "https://cdn.avkaran.com", "region": "us-east-1", "bucket_name": "avkaran", "bucket_prefix": "websites/noolva"}	api	{}	t	t	1	2026-01-15 23:30:07.827518+00
\.


--
-- Data for Name: job_queue; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.job_queue (job_id, job_uuid, company_id, action_id, related_workflow_id, related_workflow_run_id, status, priority, retry_count, payload, result, started_at, completed_at, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: locations; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.locations (location_id, created_by, idate, last_updated, city, state, country, display_name, is_active, row_exposure_mode_id) FROM stdin;
1	\N	2026-02-22 16:32:23.80535+00	2026-02-22 16:32:23.80535+00	Vannarpettai, Tirunelveli	Tamil Nadu	India	Vannarpettai, Tirunelveli,Tamilnadu,India	t	\N
2	\N	2026-02-22 18:33:59.639165+00	2026-02-22 18:33:59.639165+00	Whitefield,Bengaluru	Karnataka	India	Whitefield, Bengaluru, Karnataka, India	t	\N
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
1	aed3dcc2-ad20-4918-a0fc-38b00da76b40	Overview	\N	item	/dashboards/overview	dashboard	\N	1	\N	both	t	1	f	\N	2026-01-15 23:29:03.114175+00	2026-01-15 23:29:03.114175+00
2	1b84b43b-bf3e-417d-a0b0-8e6e2a1be26a	Dashboard Stats	\N	item	/dashboards/stats	chart-bar	\N	1	\N	both	t	1	f	\N	2026-01-15 23:29:03.114175+00	2026-01-15 23:29:03.114175+00
3	bdd8be6a-a45c-4e7f-9bd6-78e81f71b32c	Reports	\N	item	/dashboards/reports	file	\N	1	\N	both	t	2	f	\N	2026-01-15 23:29:03.114175+00	2026-01-15 23:29:03.114175+00
8	91c29d00-04c1-464e-8b31-996a51a0b3fc	Companies	\N	item	org_companies	bank	\N	4	\N	saas	t	10	f	1	2026-01-16 01:58:46.119529+00	2026-01-16 01:58:46.119529+00
9	3b5ff474-b2be-49ff-96ce-67eec63840fa	App Menus	\N	item	org_app_menus	appstore	\N	4	\N	saas	t	20	f	1	2026-01-16 01:58:46.119529+00	2026-01-16 01:58:46.119529+00
10	63260d82-1fa2-420d-b7c6-6f323a0536ba	Users	\N	item	org_users	user	\N	4	\N	saas	t	30	f	1	2026-01-16 01:58:46.119529+00	2026-01-16 01:58:46.119529+00
11	576c2036-c1e5-4d63-9755-e8ea2c82caec	User Groups	\N	item	org_user_groups	users	\N	4	\N	saas	t	40	f	1	2026-01-16 01:58:46.119529+00	2026-01-16 01:58:46.119529+00
12	c336f401-8128-4a57-a79b-bf34d279a7a0	Teams	\N	item	org_teams	team	\N	4	\N	saas	t	50	f	1	2026-01-16 01:58:46.119529+00	2026-01-16 01:58:46.119529+00
13	3de463d1-2061-47d1-9858-5527bbd7047b	Roles	\N	item	org_roles	safety	\N	4	\N	saas	t	60	f	1	2026-01-16 01:58:46.119529+00	2026-01-16 01:58:46.119529+00
14	af70b096-cb91-4695-a116-d6413990f519	Permissions	\N	item	org_permissions	key	\N	4	\N	saas	t	70	f	1	2026-01-16 01:58:46.119529+00	2026-01-16 01:58:46.119529+00
15	01264678-9044-406e-9936-f13ffd31373d	Settings	\N	item	settings	setting	\N	6	\N	saas	t	80	f	1	2026-01-16 01:58:46.119529+00	2026-01-16 01:58:46.119529+00
17	51fed74b-2109-460a-b985-a93f7b70f459	App Store	\N	item	studio_app_store	shop	\N	5	\N	saas	t	10	f	1	2026-01-16 01:58:46.119529+00	2026-01-16 01:58:46.119529+00
18	bec8fe34-602b-4035-87e6-6cdb52739cb9	My Apps	\N	item	studio_my_apps	appstore	\N	5	\N	saas	t	20	f	1	2026-01-16 01:58:46.119529+00	2026-01-16 01:58:46.119529+00
19	4d796dc5-d5fa-4d14-99ab-5a22206b8ef2	Modules	\N	item	studio_modules	blocks	\N	5	\N	saas	t	30	f	1	2026-01-16 01:58:46.119529+00	2026-01-16 01:58:46.119529+00
20	c92aaa56-13ba-42e4-b9ce-cc9dfe7500d9	Features	\N	item	studio_features	star	\N	5	\N	saas	t	40	f	1	2026-01-16 01:58:46.119529+00	2026-01-16 01:58:46.119529+00
21	6a9ffc47-290e-4611-8979-09e0636af0b2	Api Endpoints	\N	item	studio_api_endpoints	api	\N	5	\N	saas	t	50	f	1	2026-01-16 01:58:46.119529+00	2026-01-16 01:58:46.119529+00
22	63ea863d-ba73-4ff5-a190-99145be2928b	Data Models	\N	item	studio_data_models	database	\N	5	\N	saas	t	60	f	1	2026-01-16 01:58:46.119529+00	2026-01-16 01:58:46.119529+00
23	615bcd3f-dc11-4b5f-9a65-edb28b965691	UI Views	\N	item	studio_ui_views	layout	\N	5	\N	saas	t	70	f	1	2026-01-16 01:58:46.119529+00	2026-01-16 01:58:46.119529+00
24	72079ecc-07c6-4489-a858-b7cf09a63f05	Jobs/Actions	\N	item	studio_jobs_actions	rocket	\N	5	\N	saas	t	80	f	1	2026-01-16 01:58:46.119529+00	2026-01-16 01:58:46.119529+00
25	b991ca66-c8e8-4545-9722-0b7da2da02b3	Integration Manager	\N	item	studio_integrations	link	\N	5	\N	saas	t	90	f	1	2026-01-16 01:58:46.119529+00	2026-01-16 01:58:46.119529+00
26	737df92c-67f9-4731-8b4e-bdbc5168f851	Assets	\N	item	studio_assets	picture	\N	5	\N	saas	t	100	f	1	2026-01-16 01:58:46.119529+00	2026-01-16 01:58:46.119529+00
27	c8cd1158-1506-4c43-bdfd-f51f1bc8506e	UI Components	\N	item	studio_ui_components	build	\N	5	\N	saas	t	110	f	1	2026-01-16 01:58:46.119529+00	2026-01-16 01:58:46.119529+00
29	a0d64f52-7d21-43df-a478-41fe60b9a81b	Database	\N	item	dev_console_database	database	\N	7	\N	saas	t	10	f	1	2026-01-17 01:47:18.959375+00	2026-01-17 01:47:18.959375+00
30	7882cf29-fff8-490a-b148-950b9822a109	Db Query	\N	item	dev_console_db_query	code	\N	7	\N	saas	t	20	f	1	2026-01-17 01:47:18.959375+00	2026-01-17 01:47:18.959375+00
31	14582847-c4d2-4d4d-b498-76a3e368ff98	Icons	\N	item	studio_icons	star	\N	5	\N	saas	t	120	f	1	2026-01-19 02:12:31.872374+00	2026-01-19 02:12:31.872374+00
32	324c81b2-475b-4541-bc07-c5dc411880a2	Collections	\N	item	studio_collections	chart-bar	\N	5	\N	saas	t	65	f	1	2026-01-25 02:23:32.317886+00	2026-01-25 02:23:32.317886+00
33	e784e469-7460-4760-93e5-9466aac95d30	Themes	\N	item	themes	bgcolors	\N	6	\N	saas	t	85	f	1	2026-02-01 18:23:06.878529+00	2026-02-01 18:23:06.878529+00
34	e771d7c2-3292-42e5-aa58-d4aea79c3783	Asset Gallery	26	item	studio_asset_gallery	picture	\N	5	\N	saas	t	1	f	1	2026-02-05 20:56:40.230036+00	2026-02-05 20:56:40.230036+00
35	c6cdf773-9691-4dbe-b156-c12fcbcb13d2	Personal Access Tokens	\N	item	personal_access_tokens	key	\N	6	\N	saas	t	86	f	1	2026-02-08 04:58:07.188713+00	2026-02-08 04:58:07.188713+00
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
-- Data for Name: my_projects; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.my_projects (project_id, created_by, idate, last_updated, task_category_id, project_name, description, status, start_date, end_date, created_at, is_active, row_exposure_mode_id) FROM stdin;
4	\N	2026-03-01 10:51:28.440533+00	2026-03-01 10:51:28.440533+00	1	PKManager	\N	active	2026-02-01	\N	2026-02-14 22:26:10.746709+00	t	\N
3	\N	2026-03-01 10:50:42.274068+00	2026-03-01 10:50:42.274068+00	1	Noolva	\N	active	2026-03-01	\N	2026-02-14 22:26:10.746709+00	t	\N
\.


--
-- Data for Name: my_tasks; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.my_tasks (task_id, created_by, idate, last_updated, task_category_id, project_id, sprint_id, title, description, priority, status, due_date, scheduled_at, started_at, completed_at, recurrence_type, recurrence_interval, recurrence_days, estimated_time, timebox, actual_time, assigned_to, task_uuid, alarm_id, person_id, business_id, row_exposure_mode_id) FROM stdin;
6	\N	2026-03-02 08:59:16.793184+00	2026-03-02 08:59:16.793184+00	1	\N	\N	hs-cicd, setup azure deveps agent inside	\N	4	completed	2026-03-02	2026-03-02 09:29:16+00	\N	2026-03-03 03:26:31+00	\N	\N	\N	\N	\N	\N	1	98bc6248-b8f1-4a6b-83bf-2d24dda86862	\N	\N	1	\N
1	\N	2026-03-01 16:51:41.279828+00	2026-03-01 16:51:41.279828+00	1	\N	\N	test	test	4	cancelled	2026-03-01	2026-03-01 17:21:41+00	\N	\N	\N	\N	\N	\N	\N	\N	1	4e5d37de-fbc7-4151-a42c-42778fe2f278	\N	\N	1	\N
11	\N	2026-03-03 03:10:10.5786+00	2026-03-03 03:10:10.5786+00	1	\N	\N	inspection re-synch brookfields	\N	4	completed	2026-03-03	2026-03-03 03:15:10+00	\N	2026-03-03 07:35:27+00	\N	\N	\N	\N	\N	\N	1	efd1f8c0-4df9-4e8d-919a-5894c4ed5e87	\N	\N	1	\N
9	\N	2026-03-02 17:17:17.430724+00	2026-03-02 17:17:17.430724+00	1	\N	1	data-security link for helixsense	waiting for ticket-creation	4	completed	2026-03-02	2026-03-02 11:30:00+00	\N	2026-03-04 19:25:56+00	\N	\N	\N	\N	\N	\N	1	32558e23-7af8-4fac-8800-9973c078f511	\N	\N	1	\N
25	\N	2026-03-04 12:38:01.860623+00	2026-03-04 12:38:01.860623+00	1	\N	\N	mro gatepass web icon issue,	ls /opt/odoo12/hsense-erpv3/mro_addons/mro_gatepass/static/description/home.png\nls /opt/apiqa/hsense-erpv3/mro_addons/mro_gatepass/static/description/home.png\n\n\nSELECT id, name\nFROM ir_ui_menu\nWHERE name = 'Gatepass';\nSELECT m.id, m.name, p.name AS parent\nFROM ir_ui_menu m\nLEFT JOIN ir_ui_menu p ON m.parent_id = p.id\nWHERE m.name = 'Gatepass';\n\n\napidevdb=> SELECT module, name, res_id\nFROM ir_model_data\nWHERE model = 'ir.ui.menu'\nAND name = 'menu_gatepass_root';\n\n\napidevdb: res_id = 1089\napiqadb_new: res_id = 965\n\nSELECT COUNT(*) AS attachment_count\nFROM ir_attachment\nWHERE res_model = 'ir.ui.menu'\nAND res_field = 'web_icon_data'\nAND res_id = 1089;\n\n\n\n\nDELETE FROM ir_attachment\nWHERE res_model='ir.ui.menu'\nAND res_field='web_icon_data'\nAND res_id=1089\nAND id NOT IN (\n    SELECT MAX(id)\n    FROM ir_attachment\n    WHERE res_model='ir.ui.menu'\n    AND res_field='web_icon_data'\n    AND res_id=1089\n);	4	completed	2026-03-04	2026-03-04 13:08:01+00	\N	2026-03-04 12:38:34+00	\N	\N	\N	\N	\N	\N	1	7ef35568-6140-491a-8bd0-b49942da3883	\N	\N	1	\N
23	\N	2026-03-04 06:34:14.19942+00	2026-03-04 06:34:14.19942+00	1	\N	\N	create hx.waste_tracker_log SR2600268	create hx.waste_tracker_log\n\nSR2600268\n26 Feb 2026 9:00 PM IST \n\t=>2026-02-26 15:30:00 UTC\n26 Feb 2026 10:00 PM IST\n\t=>2026-02-26 16:30:00 UTC	4	in_progress	2026-03-04	2026-03-04 07:04:13+00	\N	2026-03-04 09:38:06+00	\N	\N	\N	\N	\N	\N	1	703feb64-6737-4d0d-8aa9-d328853fa963	\N	\N	1	\N
13	\N	2026-03-03 07:53:27.140621+00	2026-03-03 07:53:27.140621+00	1	\N	\N	SR2600149 utlization report	delegated to Adithan to work on it.	4	completed	2026-03-03	2026-03-03 08:23:26+00	\N	2026-03-03 09:56:28+00	\N	\N	\N	\N	\N	\N	1	ad34803e-0aa6-4fc0-bd12-57e4e3368b04	\N	\N	1	\N
29	\N	2026-03-05 07:17:07.381488+00	2026-03-05 07:17:07.381488+00	1	\N	\N	waiting tickets with ubikaa	1) api dev pipeline, ignore Addon upgrade when changes on "controllers" path\n2) mro_gatepass, mro_maintenace_extended upgrade issue only on api-dev\n3) azure devops agent replace with aws hs-cicd	4	completed	2026-03-05	2026-03-05 07:47:07+00	\N	2026-03-05 08:45:14+00	\N	\N	\N	\N	\N	\N	1	38ac76ab-4621-4c2a-9dc8-c42a59fa19bf	\N	\N	1	\N
10	\N	2026-03-03 03:01:12.023752+00	2026-03-03 03:01:12.023752+00	1	\N	\N	apiqa local changes for adhi	mro_addons/mro_tenant_employee/models/res_company.py  +19\nstate_id = fields.Many2one('res.country.state',store=True)	1	completed	2026-03-03	2026-03-03 03:06:11+00	\N	2026-03-03 03:24:32+00	\N	\N	\N	\N	\N	\N	1	9c26010d-1a3a-4e3b-ace6-0574cc89efb4	\N	\N	1	\N
7	\N	2026-03-02 09:00:22.703403+00	2026-03-02 09:00:22.703403+00	1	\N	\N	android app share current build	VERSION_CODE           = 110\nVERSION_NAME           = 1.7.141.1\nACCOUNT_ACTIVATION_URL = erp.helixsense.com\nAPK  : http://20.127.165.58:8081/repository/artifacts/android-app/1.7.141.1/helixsenseAndroid_1.7.141.1_020326_08_30.apk\nAAB  : http://20.127.165.58:8081/repository/artifacts/android-app/1.7.141.1/helixsenseAndroid_1.7.141.1.110_020326_08_38.aab\n\n\nadd tag and prs	4	completed	2026-03-02	2026-03-02 09:30:22+00	\N	2026-03-03 03:24:58+00	\N	\N	\N	\N	\N	\N	1	0c7f0ab1-2b8d-457b-b15a-e6bf038c7bfd	\N	\N	1	\N
4	\N	2026-03-02 04:01:29.634472+00	2026-03-02 04:01:29.634472+00	1	\N	\N	apiqa,web qa deployment	\N	4	completed	2026-03-02	2026-03-02 14:01:49+00	\N	2026-03-03 03:26:11+00	\N	\N	\N	\N	\N	\N	1	18409738-7a68-411e-bfe7-07d02dae4142	\N	\N	1	\N
5	\N	2026-03-02 08:57:49.46451+00	2026-03-02 08:57:49.46451+00	1	\N	\N	take old audits and delete on notes	take old audits and delete on notes	4	completed	2026-03-02	2026-03-02 11:01:03+00	\N	2026-03-03 03:26:16+00	\N	\N	\N	\N	\N	\N	1	a7f8890b-cd12-4682-b52d-9a25cc7df28a	\N	\N	1	\N
3	\N	2026-03-01 18:23:05.661892+00	2026-03-01 18:23:05.661892+00	1	\N	1	warehouse-brookfields pgsync	warehouse-brookfields pgsync	4	completed	2026-03-01	2026-03-02 13:12:45+00	\N	2026-03-03 03:26:21+00	\N	\N	\N	\N	\N	\N	1	90c55576-e912-4a41-8729-285bce5b0d00	\N	\N	1	\N
2	\N	2026-03-01 18:22:25.638421+00	2026-03-01 18:22:25.638421+00	1	\N	1	warehouse-brookfields pgsync	warehouse-brookfields pgsync	4	completed	2026-03-01	2026-03-01 18:52:25+00	\N	2026-03-03 03:26:26+00	\N	\N	\N	\N	\N	\N	1	24186711-3b3b-480e-9636-2fbf3180449c	\N	\N	1	\N
17	\N	2026-03-03 14:36:10.071355+00	2026-03-03 14:36:10.071355+00	1	\N	\N	data count mismatch in dw2 brookfields.	helpdesk : 1 record happened at the time of deployment of service\nwork permit: dummy site(floating site with parent),	4	completed	2026-03-03	2026-03-03 15:06:09+00	\N	2026-03-03 14:40:36+00	\N	\N	\N	\N	\N	\N	1	1965f4a4-19b6-43d5-9b1a-8fe1c51e4854	\N	\N	1	\N
18	\N	2026-03-03 14:43:55.918477+00	2026-03-03 14:43:55.918477+00	1	\N	\N	latest scheduler-dev.aforce360 deployed from the release/1.0.3	latest scheduler-dev.aforce360 deployed from the release/1.0.3	4	completed	2026-03-03	2026-03-03 15:13:55+00	\N	2026-03-03 14:44:10+00	\N	\N	\N	\N	\N	\N	1	969c2e23-cd13-40c8-8a0b-a9bc8f6eae1a	\N	\N	1	\N
14	\N	2026-03-03 08:23:24.897259+00	2026-03-03 08:23:24.897259+00	1	\N	\N	SR2600248 Gate Pass - query	SR2600248 Gate Pass - Non-Returnable Gate Pass Displaying Due Days..\nQuery Executed on cbre-preprod.\nEoD at production confirmed by jagdeesh sir.	4	completed	2026-03-03	2026-03-03 13:30:00+00	\N	2026-03-03 15:18:18+00	\N	\N	\N	\N	\N	\N	1	462debb6-e8d2-4bd2-a232-b80679e18266	\N	\N	1	\N
20	\N	2026-03-03 16:27:18.17222+00	2026-03-03 16:27:18.17222+00	1	\N	\N	AWS SES migration GE,Airtel,HCL,MCloud	\N	4	completed	2026-03-03	2026-03-03 16:57:18+00	\N	2026-03-03 16:27:33+00	\N	\N	\N	\N	\N	\N	1	543077fa-4901-45ac-9e7e-32331641d323	\N	\N	1	\N
30	\N	2026-03-05 07:18:18.141592+00	2026-03-05 07:18:18.141592+00	1	\N	\N	API dw2 modules,script files ,status on all env deployment steps,	john working on it	4	waiting	2026-03-05	2026-03-05 07:48:17+00	\N	\N	\N	\N	\N	\N	\N	\N	790	5e5cacc2-c478-4c2a-84eb-b95f70cd0b7e	\N	\N	1	\N
27	\N	2026-03-05 04:20:57.424457+00	2026-03-05 04:20:57.424457+00	1	\N	\N	warehouse-dev-cloudwatch alert: disk>75%	warehouse-dev-cloudwatch alert: disk>75%	4	waiting	2026-03-05	2026-03-05 04:50:57+00	\N	\N	\N	\N	\N	\N	\N	\N	1	a7e5305b-d9a1-4359-88c5-023e7d09bc6c	\N	\N	1	\N
8	\N	2026-03-02 09:12:33.971887+00	2026-03-02 09:12:33.971887+00	1	\N	\N	Alert BROOKFIELD-WAREHOUSE-VM-Memory-High-80	Alert BROOKFIELD-WAREHOUSE-VM-Memory-High-80 on hsn-brookfield-vm-prod-eastus-002 ( microsoft.compute/virtualmachines ) at 3/2/2026 2:20:09 AM\nvaibhav only getting alert,	4	backlog	2026-03-02	2026-03-02 11:12:33+00	\N	\N	\N	\N	\N	\N	\N	\N	1	03a75157-f9a1-4fa0-a097-cc5b1f363679	\N	\N	1	\N
22	\N	2026-03-04 06:03:57.643874+00	2026-03-04 06:03:57.643874+00	1	\N	\N	hs-dev-vm assets cleanup	have to get idea from sundaram sir	4	in_progress	2026-03-04	2026-03-04 06:33:57+00	\N	2026-03-04 20:37:03+00	\N	\N	\N	\N	\N	\N	790	3dbb2ea6-bfbb-474e-9e13-e9eb86a28fa6	\N	\N	1	\N
12	\N	2026-03-03 07:38:52.612312+00	2026-03-03 07:38:52.612312+00	1	\N	\N	replace selfhost hs-cicd to aws HP2600152	add aws tags,\ntest major builds,\nstop the azure vm\ntell the plan to vaibhav,\ncreate ticket for it.	4	in_progress	2026-03-03	2026-03-03 08:08:52+00	\N	\N	\N	\N	\N	\N	\N	\N	1	87a64289-3297-416f-81a4-d70d83f03a71	\N	\N	1	\N
24	\N	2026-03-04 12:24:29.471755+00	2026-03-04 12:24:29.471755+00	1	\N	\N	52 Week PPM for CBRE - Weeks 1 to 10....	52 Week PPM for CBRE - Weeks 1 to 10....	4	completed	2026-03-04	2026-03-04 12:54:28+00	\N	2026-03-04 19:17:28+00	\N	\N	\N	\N	\N	\N	1	b9845bce-de45-465a-ab1f-41c47106e39a	\N	\N	1	\N
21	\N	2026-03-04 05:41:28.087497+00	2026-03-04 05:41:28.087497+00	1	\N	\N	Ignore: /controllers/**.py  on dev deployment HP2600150	motive to avoid manual changes on dev.	4	completed	2026-03-04	2026-03-04 06:11:27+00	\N	2026-03-05 19:34:34+00	\N	\N	\N	\N	\N	\N	1	75ee7ba6-5585-4018-92bf-c065cf3890df	\N	\N	1	\N
26	\N	2026-03-04 13:53:32.959535+00	2026-03-04 13:53:32.959535+00	1	\N	\N	brookfield preprod job queue failed HP2600157	\N	4	completed	2026-03-04	2026-03-04 14:23:32+00	\N	2026-03-05 11:06:42+00	\N	\N	\N	\N	\N	\N	1	1ac26e6e-3c30-4d51-943e-3d631050f345	\N	\N	1	\N
15	\N	2026-03-03 08:25:03.295316+00	2026-03-03 08:25:03.295316+00	1	\N	\N	script for latest data brookfield preprod	for both api, and warehouse	4	backlog	2026-03-03	2026-03-03 11:25:03+00	\N	\N	\N	\N	\N	\N	\N	\N	1	b42a3cfc-c48b-4dcc-81d3-e5e6ce89bb94	\N	\N	1	\N
16	\N	2026-03-03 09:52:15.750283+00	2026-03-03 09:52:15.750283+00	1	\N	\N	HP2600124 RDS DB maintenance Patch Upgrade	\N	4	backlog	2026-03-03	2026-03-03 10:22:15+00	\N	\N	\N	\N	\N	\N	\N	\N	1	24a5e62d-795a-4b48-a795-ba88bb8323fb	\N	\N	1	\N
34	\N	2026-03-06 03:01:28.348129+00	2026-03-06 03:01:28.348129+00	1	\N	\N	brookfields resync	brookfields resync	4	completed	2026-03-06	2026-03-06 03:31:28+00	\N	2026-03-06 18:26:24+00	\N	\N	\N	\N	\N	\N	1	e50c8157-d910-42f9-9742-7d520d7fbd53	\N	\N	1	\N
19	\N	2026-03-03 16:24:09.556997+00	2026-03-03 16:24:09.556997+00	1	\N	\N	Cherry-pick failure to UAE-Enhancement	6056=>done\n6096\n6097\n6101\n6102	4	completed	2026-03-04	2026-03-04 04:30:00+00	\N	2026-03-05 08:35:17+00	\N	\N	\N	\N	\N	\N	1	871a51ce-2a92-404f-b610-0ccd05bc239f	\N	\N	1	\N
36	\N	2026-03-06 07:58:42.965014+00	2026-03-06 07:58:42.965014+00	1	\N	\N	api-preprod and wipro s3 attachment issue SR2600288	port of s3 container forward for preprod : 5144\n\ndocker or preprod : 4269fff11eab\n\n10.1.83.250 - - [06/Mar/2026:05:35:45 +0000] "POST /api/create/ir.attachment HTTP/1.1" 500 290 "https://app-cbreppv3.helixsense.com/sla-audits" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36"\n\nproduction,wipro is moving where, by loadbalancer, then reach sundaram sir.	4	waiting	2026-03-06	2026-03-06 08:28:42+00	\N	\N	\N	\N	\N	\N	\N	\N	1	9935f99a-5636-406e-8aa5-804adca71f29	\N	\N	1	\N
33	\N	2026-03-05 11:01:28.68645+00	2026-03-05 11:01:28.68645+00	1	\N	\N	local changes on hs-dev-warehouse helpers.js	dir : custom-addons/spreadsheet_enhancement/static/src/spreadsheet/bundle\nhelpers.js newly created with attached file,\n\n custom-addons/spreadsheet_enhancement/. ..changed on .py added line,\n"spreadsheet_enhancement/static/src/spreadsheet/bundle/helpers.js",	4	completed	2026-03-05	2026-03-05 11:31:28+00	\N	2026-03-05 11:03:07+00	\N	\N	\N	\N	\N	\N	1	dd51bc6a-72b0-4b97-84f6-456492398d0c	\N	\N	1	\N
31	\N	2026-03-05 07:20:09.695707+00	2026-03-05 07:20:09.695707+00	1	\N	\N	deploy on brookfields preprod by cherry pick req. PRS, vinoth wont know	vaibav have to give pr list	4	completed	2026-03-05	2026-03-05 07:50:09+00	\N	2026-03-05 18:24:57+00	\N	\N	\N	\N	\N	\N	1	e9cb5b03-1ddf-4222-b3bc-4f1d3174c0a9	\N	\N	1	\N
40	\N	2026-03-07 02:18:04.083024+00	2026-03-07 02:18:04.083024+00	1	\N	\N	selenium tester for scim count && dw2 count test	\N	4	scheduled	2026-03-07	2026-03-07 02:48:03+00	\N	\N	\N	\N	\N	\N	\N	\N	1	5592e6ce-b275-4176-af52-919c91868924	\N	\N	1	\N
32	\N	2026-03-05 07:30:12.46821+00	2026-03-05 07:30:12.46821+00	1	\N	\N	ge warehouse reading history and web dashboards getting too slow takes 16s to 20s	\N	4	in_progress	2026-03-05	2026-03-05 08:00:12+00	\N	\N	\N	\N	\N	\N	\N	\N	1	b75d165a-c266-46a9-9b6a-48f312c9a935	\N	\N	1	\N
35	\N	2026-03-06 07:47:42.280268+00	2026-03-06 07:47:42.280268+00	1	\N	\N	api nttds on any new booking, some other person ics/calendar file is creating issue HP2600160	/opt/testnttdsv2/odoo-custom-addons/mro_addons/mro_tenant_employee/models/mro_shift_employee.py\nlocal changes done on preprod nttds and production also	4	completed	2026-03-06	2026-03-06 08:17:41+00	\N	2026-03-06 18:21:05+00	\N	\N	\N	\N	\N	\N	1	f9317faf-af28-43b2-9401-fae14e0c72fc	\N	\N	1	\N
43	\N	2026-03-07 13:58:24.548061+00	2026-03-07 13:58:24.548061+00	1	\N	\N	warehouse-api-DB-diskutilization-alert	check archival can be done	4	scheduled	2026-03-07	2026-03-07 14:28:24+00	\N	\N	\N	\N	\N	\N	\N	\N	1	945d9360-da77-42c4-9c9d-08203271664c	\N	\N	1	\N
28	\N	2026-03-05 07:15:57.963927+00	2026-03-05 07:15:57.963927+00	1	\N	\N	review_status mro_maintenance_extended upgrade issue api-dev only HP2600151	review_status issue resolved,\n2:04 AM\nWithout dependency declared, module loading order becomes unpredictable.\n\nvim mro_maintenance_extended/manifest.py add at last depends,:=> 'hx_inspection_checklist', # ← missing dependency Because QA likely installed modules historically in this order: mro_maintenance, hx_inspection_checklist, mro_maintenance_extended\n\nQA (works) → still works DEV (failed) → now works future deployments → stable	4	in_progress	2026-03-05	2026-03-05 07:45:57+00	\N	\N	\N	\N	\N	\N	\N	\N	1	1111a1fb-f051-4e92-855e-b5daa88c89c7	\N	\N	1	\N
38	\N	2026-03-06 18:25:27.552938+00	2026-03-06 18:25:27.552938+00	1	\N	\N	brookfields resync	brookfields resync	4	completed	2026-03-06	2026-03-07 03:00:00+00	\N	2026-03-07 18:10:34+00	\N	\N	\N	\N	\N	\N	1	6dcfba7d-bf4c-41cc-8c79-7681b2f0a452	\N	\N	1	\N
37	\N	2026-03-06 11:41:28.060357+00	2026-03-06 11:41:28.060357+00	1	\N	\N	branch cut-down	\N	4	completed	2026-03-06	2026-03-06 12:11:27+00	\N	2026-03-07 18:10:44+00	\N	\N	\N	\N	\N	\N	1	bafe838a-f29b-4cec-b986-37fe62118de9	\N	\N	1	\N
42	\N	2026-03-07 13:06:47.506787+00	2026-03-07 13:06:47.506787+00	1	\N	\N	52 Week PPM for NSDC  - Weeks 1 to 10....	\N	4	completed	2026-03-07	2026-03-07 13:36:47+00	\N	2026-03-07 18:10:52+00	\N	\N	\N	\N	\N	\N	1	df4c37ed-c01e-40db-aa90-c08a298c55be	\N	\N	1	\N
39	\N	2026-03-06 19:00:36.180159+00	2026-03-06 19:00:36.180159+00	1	\N	\N	52 Week PPM for Brookfields - Weeks - 1 to 10	\N	4	completed	2026-03-07	2026-03-06 19:30:35+00	\N	2026-03-07 18:11:02+00	\N	\N	\N	\N	\N	\N	1	9442de2b-e2ae-49e6-a84a-6384453426dd	\N	\N	1	\N
41	\N	2026-03-07 02:20:34.713267+00	2026-03-07 02:20:34.713267+00	1	\N	\N	Inspection is going to Missed Status (Network Response is Null)  HP00024	\N	4	scheduled	2026-03-07	2026-03-07 02:50:34+00	\N	\N	\N	\N	\N	\N	\N	\N	790	0be94cbb-2314-476b-ac13-aa6fa5960352	\N	\N	1	\N
\.


--
-- Data for Name: password_vault; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.password_vault (id, service_name, category, username_or_email, password, website_or_app_url, login_handler_function, recovery_info, notes, additional_secrets, service_uuid, row_exposure_mode_id) FROM stdin;
\.


--
-- Data for Name: person_addresses; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.person_addresses (address_id, created_by, idate, last_updated, person_id, address_type, address_line1, address_line2, postal_code, is_primary, map_location, location, row_exposure_mode_id) FROM stdin;
1	\N	2026-02-22 16:43:42.842649+00	2026-02-22 16:43:42.842649+00	1	home	54H/2	Thirukkurippu Thondar Street,Vannarpettai	627003	f	(8.7361308,77.7195449)	1	\N
\.


--
-- Data for Name: person_attachments; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.person_attachments (attachment_id, created_by, idate, last_updated, person_id, attachment_type, file_name, file, file_size, mime_type, description, row_exposure_mode_id) FROM stdin;
4	\N	2026-03-07 11:45:36.323811+00	2026-03-07 11:45:36.323811+00	1	document	pasted-1772883934537.txt	private/model-attachments/person_attachments/946692126f9846e3b822e09879aba1e7.txt	\N	\N	\N	\N
6	\N	2026-03-07 12:01:07.685579+00	2026-03-07 12:01:07.685579+00	593	document	pasted-1772884865474.png	private/model-attachments/person_attachments/de82b1223774461ca60d17929a2ee7fb.png	\N	\N	\N	2
7	\N	2026-03-07 12:04:33.185262+00	2026-03-07 12:04:33.185262+00	593	document	pasted-1772885070609.png	private/model-attachments/person_attachments/aa440b662e654cebb5a1c6fbd7c9a9ce.png	\N	\N	\N	2
8	\N	2026-03-07 12:06:35.142729+00	2026-03-07 12:06:35.142729+00	593	document	pasted-1772885191594.png	private/model-attachments/person_attachments/e462eeb3f2b049dea6b088581af1cac6.png	\N	\N	\N	2
\.


--
-- Data for Name: person_business_roles; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.person_business_roles (role_id, created_by, idate, last_updated, person_id, business_id, role, from_date, to_date, is_active, ownership_percentage, notes, row_exposure_mode_id) FROM stdin;
1	\N	2026-02-22 17:14:40.204002+00	2026-02-22 17:14:40.204002+00	1	1	employee	2025-04-25	\N	t	0	Devops Engineer	\N
\.


--
-- Data for Name: person_contacts; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.person_contacts (contact_id, created_by, idate, last_updated, person_id, contact_type, contact_value, label, is_primary, is_verified, verified_at, notes, row_exposure_mode_id) FROM stdin;
1	\N	2026-02-22 16:59:05.465395+00	2026-02-22 16:59:05.465395+00	1	phone	9943604103	personal	t	t	2026-02-21 18:30:00+00	\N	\N
2	\N	2026-02-22 18:49:27.629869+00	2026-02-22 18:49:27.629869+00	1	email	avkarannellai@gmail.com	personal	t	t	2026-02-22 18:30:00+00	\N	\N
592	\N	2026-03-06 20:45:44.256298+00	2026-03-06 20:45:44.256298+00	593	phone	919487900120	personal	f	f	\N	\N	\N
593	\N	2026-03-06 20:45:44.403235+00	2026-03-06 20:45:44.403235+00	594	phone	919487900140	personal	f	f	\N	\N	\N
594	\N	2026-03-06 20:45:44.500806+00	2026-03-06 20:45:44.500806+00	595	phone	919080560195	personal	f	f	\N	\N	\N
595	\N	2026-03-06 20:45:44.586072+00	2026-03-06 20:45:44.586072+00	596	phone	919787233377	personal	f	f	\N	\N	\N
596	\N	2026-03-06 20:45:44.704629+00	2026-03-06 20:45:44.704629+00	597	phone	917373229777	personal	f	f	\N	\N	\N
597	\N	2026-03-06 20:45:44.834099+00	2026-03-06 20:45:44.834099+00	598	phone	9865011426	personal	f	f	\N	\N	\N
598	\N	2026-03-06 20:45:44.955911+00	2026-03-06 20:45:44.955911+00	599	phone	9865911426	personal	f	f	\N	\N	\N
599	\N	2026-03-06 20:45:45.089587+00	2026-03-06 20:45:45.089587+00	600	phone	917708503610	personal	f	f	\N	\N	\N
600	\N	2026-03-06 20:45:45.192203+00	2026-03-06 20:45:45.192203+00	601	phone	919947801407	personal	f	f	\N	\N	\N
601	\N	2026-03-06 20:45:45.293528+00	2026-03-06 20:45:45.293528+00	602	phone	918807130095	personal	f	f	\N	\N	\N
602	\N	2026-03-06 20:45:45.48578+00	2026-03-06 20:45:45.48578+00	603	phone	919791680586	personal	f	f	\N	\N	\N
603	\N	2026-03-06 20:45:45.627012+00	2026-03-06 20:45:45.627012+00	604	phone	919445728914	personal	f	f	\N	\N	\N
604	\N	2026-03-06 20:45:45.781705+00	2026-03-06 20:45:45.781705+00	605	phone	919443078682	personal	f	f	\N	\N	\N
605	\N	2026-03-06 20:45:45.988683+00	2026-03-06 20:45:45.988683+00	606	phone	*111#	personal	f	f	\N	\N	\N
606	\N	2026-03-06 20:45:46.137806+00	2026-03-06 20:45:46.137806+00	607	phone	918838274736	personal	f	f	\N	\N	\N
607	\N	2026-03-06 20:45:46.273364+00	2026-03-06 20:45:46.273364+00	608	phone	919994148293	personal	f	f	\N	\N	\N
608	\N	2026-03-06 20:45:46.530323+00	2026-03-06 20:45:46.530323+00	609	phone	919600400916	personal	f	f	\N	\N	\N
609	\N	2026-03-06 20:45:46.648469+00	2026-03-06 20:45:46.648469+00	610	phone	9789976696	personal	f	f	\N	\N	\N
610	\N	2026-03-06 20:45:46.783724+00	2026-03-06 20:45:46.783724+00	611	phone	+91 77365 49297	personal	f	f	\N	\N	\N
611	\N	2026-03-06 20:45:46.878313+00	2026-03-06 20:45:46.878313+00	612	phone	6385775970	personal	f	f	\N	\N	\N
612	\N	2026-03-06 20:45:46.9644+00	2026-03-06 20:45:46.9644+00	613	phone	916369782187	personal	f	f	\N	\N	\N
613	\N	2026-03-06 20:45:47.049012+00	2026-03-06 20:45:47.049012+00	614	phone	919791886019	personal	f	f	\N	\N	\N
614	\N	2026-03-06 20:45:47.166628+00	2026-03-06 20:45:47.166628+00	615	phone	919994847670	personal	f	f	\N	\N	\N
615	\N	2026-03-06 20:45:47.292096+00	2026-03-06 20:45:47.292096+00	616	phone	918754687194	personal	f	f	\N	\N	\N
616	\N	2026-03-06 20:45:47.419888+00	2026-03-06 20:45:47.419888+00	617	phone	919366666674	personal	f	f	\N	\N	\N
617	\N	2026-03-06 20:45:47.532991+00	2026-03-06 20:45:47.532991+00	618	phone	918903027696	personal	f	f	\N	\N	\N
618	\N	2026-03-06 20:45:47.638436+00	2026-03-06 20:45:47.638436+00	619	phone	919962888729	personal	f	f	\N	\N	\N
619	\N	2026-03-06 20:45:47.728578+00	2026-03-06 20:45:47.728578+00	620	phone	102	personal	f	f	\N	\N	\N
620	\N	2026-03-06 20:45:47.814613+00	2026-03-06 20:45:47.814613+00	621	phone	919539796104	personal	f	f	\N	\N	\N
621	\N	2026-03-06 20:45:47.93606+00	2026-03-06 20:45:47.93606+00	622	phone	919489797698	personal	f	f	\N	\N	\N
622	\N	2026-03-06 20:45:48.052217+00	2026-03-06 20:45:48.052217+00	623	phone	917397008774	personal	f	f	\N	\N	\N
623	\N	2026-03-06 20:45:48.179215+00	2026-03-06 20:45:48.179215+00	624	phone	918610964954	personal	f	f	\N	\N	\N
624	\N	2026-03-06 20:45:48.301371+00	2026-03-06 20:45:48.301371+00	625	phone	919786920094	personal	f	f	\N	\N	\N
625	\N	2026-03-06 20:45:48.406114+00	2026-03-06 20:45:48.406114+00	626	phone	918124557429	personal	f	f	\N	\N	\N
626	\N	2026-03-06 20:45:48.496783+00	2026-03-06 20:45:48.496783+00	627	phone	9942153355	personal	f	f	\N	\N	\N
627	\N	2026-03-06 20:45:48.58531+00	2026-03-06 20:45:48.58531+00	628	phone	919884909355	personal	f	f	\N	\N	\N
628	\N	2026-03-06 20:45:48.707212+00	2026-03-06 20:45:48.707212+00	629	phone	918056985007	personal	f	f	\N	\N	\N
629	\N	2026-03-06 20:45:48.824739+00	2026-03-06 20:45:48.824739+00	630	phone	9841275361	personal	f	f	\N	\N	\N
630	\N	2026-03-06 20:45:48.950098+00	2026-03-06 20:45:48.950098+00	631	phone	919497347341	personal	f	f	\N	\N	\N
631	\N	2026-03-06 20:45:49.077719+00	2026-03-06 20:45:49.077719+00	632	phone	918129871159	personal	f	f	\N	\N	\N
632	\N	2026-03-06 20:45:49.177568+00	2026-03-06 20:45:49.177568+00	633	phone	9745127341	personal	f	f	\N	\N	\N
633	\N	2026-03-06 20:45:49.273895+00	2026-03-06 20:45:49.273895+00	634	phone	090481 89997	personal	f	f	\N	\N	\N
634	\N	2026-03-06 20:45:49.372921+00	2026-03-06 20:45:49.372921+00	635	phone	919444445684	personal	f	f	\N	\N	\N
635	\N	2026-03-06 20:45:49.515073+00	2026-03-06 20:45:49.515073+00	636	phone	7867975511	personal	f	f	\N	\N	\N
636	\N	2026-03-06 20:45:49.631595+00	2026-03-06 20:45:49.631595+00	637	phone	9597399071	personal	f	f	\N	\N	\N
637	\N	2026-03-06 20:45:49.759011+00	2026-03-06 20:45:49.759011+00	638	phone	9842399322	personal	f	f	\N	\N	\N
638	\N	2026-03-06 20:45:49.87964+00	2026-03-06 20:45:49.87964+00	639	phone	917397373521	personal	f	f	\N	\N	\N
639	\N	2026-03-06 20:45:49.970963+00	2026-03-06 20:45:49.970963+00	640	phone	919543070737	personal	f	f	\N	\N	\N
640	\N	2026-03-06 20:45:50.058829+00	2026-03-06 20:45:50.058829+00	641	phone	918300070101	personal	f	f	\N	\N	\N
641	\N	2026-03-06 20:45:50.15096+00	2026-03-06 20:45:50.15096+00	642	phone	917010132689	personal	f	f	\N	\N	\N
642	\N	2026-03-06 20:45:50.286684+00	2026-03-06 20:45:50.286684+00	643	phone	917200400486	personal	f	f	\N	\N	\N
643	\N	2026-03-06 20:45:50.41523+00	2026-03-06 20:45:50.41523+00	644	phone	917200000483	personal	f	f	\N	\N	\N
644	\N	2026-03-06 20:45:50.53712+00	2026-03-06 20:45:50.53712+00	645	phone	7200000486	personal	f	f	\N	\N	\N
645	\N	2026-03-06 20:45:50.660233+00	2026-03-06 20:45:50.660233+00	646	phone	7200000486	personal	f	f	\N	\N	\N
646	\N	2026-03-06 20:45:50.75297+00	2026-03-06 20:45:50.75297+00	647	phone	8086646028	personal	f	f	\N	\N	\N
647	\N	2026-03-06 20:45:50.839332+00	2026-03-06 20:45:50.839332+00	648	phone	51717	personal	f	f	\N	\N	\N
648	\N	2026-03-06 20:45:50.957979+00	2026-03-06 20:45:50.957979+00	649	phone	919629702411	personal	f	f	\N	\N	\N
649	\N	2026-03-06 20:45:51.086919+00	2026-03-06 20:45:51.086919+00	650	phone	918754484137	personal	f	f	\N	\N	\N
650	\N	2026-03-06 20:45:51.20881+00	2026-03-06 20:45:51.20881+00	651	phone	9842752004	personal	f	f	\N	\N	\N
651	\N	2026-03-06 20:45:51.320454+00	2026-03-06 20:45:51.320454+00	652	phone	8754031829	personal	f	f	\N	\N	\N
652	\N	2026-03-06 20:45:51.425707+00	2026-03-06 20:45:51.425707+00	653	phone	8973876066	personal	f	f	\N	\N	\N
653	\N	2026-03-06 20:45:51.51631+00	2026-03-06 20:45:51.51631+00	654	phone	9946989902	personal	f	f	\N	\N	\N
654	\N	2026-03-06 20:45:51.657849+00	2026-03-06 20:45:51.657849+00	655	phone	9544173737	personal	f	f	\N	\N	\N
655	\N	2026-03-06 20:45:51.881357+00	2026-03-06 20:45:51.881357+00	656	phone	917904661090	personal	f	f	\N	\N	\N
656	\N	2026-03-06 20:45:52.052426+00	2026-03-06 20:45:52.052426+00	657	phone	916382339524	personal	f	f	\N	\N	\N
657	\N	2026-03-06 20:45:52.207783+00	2026-03-06 20:45:52.207783+00	658	phone	919443125833	personal	f	f	\N	\N	\N
658	\N	2026-03-06 20:45:52.452239+00	2026-03-06 20:45:52.452239+00	659	phone	918072224099	personal	f	f	\N	\N	\N
659	\N	2026-03-06 20:45:52.558105+00	2026-03-06 20:45:52.558105+00	660	phone	918300289392	personal	f	f	\N	\N	\N
660	\N	2026-03-06 20:45:52.64935+00	2026-03-06 20:45:52.64935+00	661	phone	8973108302	personal	f	f	\N	\N	\N
661	\N	2026-03-06 20:45:52.770283+00	2026-03-06 20:45:52.770283+00	662	phone	7594884161	personal	f	f	\N	\N	\N
662	\N	2026-03-06 20:45:52.89797+00	2026-03-06 20:45:52.89797+00	663	phone	919500269015	personal	f	f	\N	\N	\N
663	\N	2026-03-06 20:45:53.020616+00	2026-03-06 20:45:53.020616+00	664	phone	6380998577	personal	f	f	\N	\N	\N
664	\N	2026-03-06 20:45:53.141258+00	2026-03-06 20:45:53.141258+00	665	phone	9750162257	personal	f	f	\N	\N	\N
665	\N	2026-03-06 20:45:53.235106+00	2026-03-06 20:45:53.235106+00	666	phone	919442394658	personal	f	f	\N	\N	\N
666	\N	2026-03-06 20:45:53.320388+00	2026-03-06 20:45:53.320388+00	667	phone	9042404647	personal	f	f	\N	\N	\N
667	\N	2026-03-06 20:45:53.43243+00	2026-03-06 20:45:53.43243+00	668	phone	917708816164	personal	f	f	\N	\N	\N
668	\N	2026-03-06 20:45:53.557603+00	2026-03-06 20:45:53.557603+00	669	phone	919500848406	personal	f	f	\N	\N	\N
669	\N	2026-03-06 20:45:53.710903+00	2026-03-06 20:45:53.710903+00	670	phone	919884769961	personal	f	f	\N	\N	\N
670	\N	2026-03-06 20:45:53.83838+00	2026-03-06 20:45:53.83838+00	671	phone	141	personal	f	f	\N	\N	\N
671	\N	2026-03-06 20:45:53.925315+00	2026-03-06 20:45:53.925315+00	672	phone	918939339096	personal	f	f	\N	\N	\N
672	\N	2026-03-06 20:45:54.01211+00	2026-03-06 20:45:54.01211+00	673	phone	919486507542	personal	f	f	\N	\N	\N
673	\N	2026-03-06 20:45:54.106958+00	2026-03-06 20:45:54.106958+00	674	phone	919363116542	personal	f	f	\N	\N	\N
674	\N	2026-03-06 20:45:54.237105+00	2026-03-06 20:45:54.237105+00	675	phone	919486427784	personal	f	f	\N	\N	\N
675	\N	2026-03-06 20:45:54.367145+00	2026-03-06 20:45:54.367145+00	676	phone	918072412078	personal	f	f	\N	\N	\N
676	\N	2026-03-06 20:45:54.494817+00	2026-03-06 20:45:54.494817+00	677	phone	121	personal	f	f	\N	\N	\N
677	\N	2026-03-06 20:45:54.617966+00	2026-03-06 20:45:54.617966+00	678	phone	919791204824	personal	f	f	\N	\N	\N
678	\N	2026-03-06 20:45:54.708527+00	2026-03-06 20:45:54.708527+00	679	phone	9791365670	personal	f	f	\N	\N	\N
679	\N	2026-03-06 20:45:54.797314+00	2026-03-06 20:45:54.797314+00	680	phone	+91 86108 55308	personal	f	f	\N	\N	\N
680	\N	2026-03-06 20:45:54.901007+00	2026-03-06 20:45:54.901007+00	681	phone	917010857953	personal	f	f	\N	\N	\N
681	\N	2026-03-06 20:45:55.028534+00	2026-03-06 20:45:55.028534+00	682	phone	52000	personal	f	f	\N	\N	\N
682	\N	2026-03-06 20:45:55.1568+00	2026-03-06 20:45:55.1568+00	683	phone	*444#	personal	f	f	\N	\N	\N
683	\N	2026-03-06 20:45:55.290005+00	2026-03-06 20:45:55.290005+00	684	phone	9943534288	personal	f	f	\N	\N	\N
684	\N	2026-03-06 20:45:55.41194+00	2026-03-06 20:45:55.41194+00	685	phone	7092656870	personal	f	f	\N	\N	\N
685	\N	2026-03-06 20:45:55.498343+00	2026-03-06 20:45:55.498343+00	686	phone	919585058033	personal	f	f	\N	\N	\N
686	\N	2026-03-06 20:45:55.583631+00	2026-03-06 20:45:55.583631+00	687	phone	917904823904	personal	f	f	\N	\N	\N
687	\N	2026-03-06 20:45:55.695233+00	2026-03-06 20:45:55.695233+00	688	phone	918608704147	personal	f	f	\N	\N	\N
688	\N	2026-03-06 20:45:55.828632+00	2026-03-06 20:45:55.828632+00	689	phone	*567*333#	personal	f	f	\N	\N	\N
689	\N	2026-03-06 20:45:55.955682+00	2026-03-06 20:45:55.955682+00	690	phone	55655	personal	f	f	\N	\N	\N
690	\N	2026-03-06 20:45:56.075575+00	2026-03-06 20:45:56.075575+00	691	phone	917010493897	personal	f	f	\N	\N	\N
691	\N	2026-03-06 20:45:56.192902+00	2026-03-06 20:45:56.192902+00	692	phone	9092611203	personal	f	f	\N	\N	\N
692	\N	2026-03-06 20:45:56.285306+00	2026-03-06 20:45:56.285306+00	693	phone	57373	personal	f	f	\N	\N	\N
693	\N	2026-03-06 20:45:56.372836+00	2026-03-06 20:45:56.372836+00	694	phone	919894254010	personal	f	f	\N	\N	\N
694	\N	2026-03-06 20:45:56.476511+00	2026-03-06 20:45:56.476511+00	695	phone	9626250862	personal	f	f	\N	\N	\N
695	\N	2026-03-06 20:45:56.618887+00	2026-03-06 20:45:56.618887+00	696	phone	9842640920	personal	f	f	\N	\N	\N
696	\N	2026-03-06 20:45:56.745769+00	2026-03-06 20:45:56.745769+00	697	phone	919442540920	personal	f	f	\N	\N	\N
697	\N	2026-03-06 20:45:56.875566+00	2026-03-06 20:45:56.875566+00	698	phone	7845332138	personal	f	f	\N	\N	\N
698	\N	2026-03-06 20:45:56.97881+00	2026-03-06 20:45:56.97881+00	699	phone	919600413191	personal	f	f	\N	\N	\N
699	\N	2026-03-06 20:45:57.068311+00	2026-03-06 20:45:57.068311+00	700	phone	8056433865	personal	f	f	\N	\N	\N
700	\N	2026-03-06 20:45:57.156617+00	2026-03-06 20:45:57.156617+00	701	phone	919894509892	personal	f	f	\N	\N	\N
701	\N	2026-03-06 20:45:57.266859+00	2026-03-06 20:45:57.266859+00	702	phone	919940181493	personal	f	f	\N	\N	\N
702	\N	2026-03-06 20:45:57.39529+00	2026-03-06 20:45:57.39529+00	703	phone	9443697008	personal	f	f	\N	\N	\N
703	\N	2026-03-06 20:45:57.525551+00	2026-03-06 20:45:57.525551+00	704	phone	916379160446	personal	f	f	\N	\N	\N
704	\N	2026-03-06 20:45:57.761217+00	2026-03-06 20:45:57.761217+00	705	phone	918124610004	personal	f	f	\N	\N	\N
705	\N	2026-03-06 20:45:57.915309+00	2026-03-06 20:45:57.915309+00	706	phone	919791222194	personal	f	f	\N	\N	\N
706	\N	2026-03-06 20:45:58.048749+00	2026-03-06 20:45:58.048749+00	707	phone	5670330	personal	f	f	\N	\N	\N
707	\N	2026-03-06 20:45:58.237609+00	2026-03-06 20:45:58.237609+00	708	phone	198	personal	f	f	\N	\N	\N
708	\N	2026-03-06 20:45:58.444314+00	2026-03-06 20:45:58.444314+00	709	phone	*500*1#	personal	f	f	\N	\N	\N
709	\N	2026-03-06 20:45:58.615575+00	2026-03-06 20:45:58.615575+00	710	phone	4622560298	personal	f	f	\N	\N	\N
710	\N	2026-03-06 20:45:58.735455+00	2026-03-06 20:45:58.735455+00	711	phone	9443194890	personal	f	f	\N	\N	\N
711	\N	2026-03-06 20:45:58.82576+00	2026-03-06 20:45:58.82576+00	712	phone	9244220890	personal	f	f	\N	\N	\N
712	\N	2026-03-06 20:45:58.916777+00	2026-03-06 20:45:58.916777+00	713	phone	918682036507	personal	f	f	\N	\N	\N
713	\N	2026-03-06 20:45:59.022043+00	2026-03-06 20:45:59.022043+00	714	phone	9843074213	personal	f	f	\N	\N	\N
714	\N	2026-03-06 20:45:59.150864+00	2026-03-06 20:45:59.150864+00	715	phone	919444077703	personal	f	f	\N	\N	\N
715	\N	2026-03-06 20:45:59.271956+00	2026-03-06 20:45:59.271956+00	716	phone	9688636375	personal	f	f	\N	\N	\N
716	\N	2026-03-06 20:45:59.406902+00	2026-03-06 20:45:59.406902+00	717	phone	917339193186	personal	f	f	\N	\N	\N
717	\N	2026-03-06 20:45:59.518508+00	2026-03-06 20:45:59.518508+00	718	phone	919791851740	personal	f	f	\N	\N	\N
718	\N	2026-03-06 20:45:59.613616+00	2026-03-06 20:45:59.613616+00	719	phone	7200737306	personal	f	f	\N	\N	\N
719	\N	2026-03-06 20:45:59.700463+00	2026-03-06 20:45:59.700463+00	720	phone	919629252069	personal	f	f	\N	\N	\N
720	\N	2026-03-06 20:45:59.814971+00	2026-03-06 20:45:59.814971+00	721	phone	112	personal	f	f	\N	\N	\N
721	\N	2026-03-06 20:45:59.934849+00	2026-03-06 20:45:59.934849+00	722	phone	919345841228	personal	f	f	\N	\N	\N
722	\N	2026-03-06 20:46:00.067272+00	2026-03-06 20:46:00.067272+00	723	phone	91462233320	personal	f	f	\N	\N	\N
723	\N	2026-03-06 20:46:00.199475+00	2026-03-06 20:46:00.199475+00	724	phone	+91 98842 17242	personal	f	f	\N	\N	\N
724	\N	2026-03-06 20:46:00.289347+00	2026-03-06 20:46:00.289347+00	725	phone	918610241607	personal	f	f	\N	\N	\N
725	\N	2026-03-06 20:46:00.383167+00	2026-03-06 20:46:00.383167+00	726	phone	+91 94445 32133	personal	f	f	\N	\N	\N
726	\N	2026-03-06 20:46:00.491961+00	2026-03-06 20:46:00.491961+00	727	phone	919444614236	personal	f	f	\N	\N	\N
727	\N	2026-03-06 20:46:00.615775+00	2026-03-06 20:46:00.615775+00	728	phone	(979) 052-6918	personal	f	f	\N	\N	\N
728	\N	2026-03-06 20:46:00.733628+00	2026-03-06 20:46:00.733628+00	729	phone	919894961433	personal	f	f	\N	\N	\N
729	\N	2026-03-06 20:46:00.858908+00	2026-03-06 20:46:00.858908+00	730	phone	917708503419	personal	f	f	\N	\N	\N
730	\N	2026-03-06 20:46:00.985321+00	2026-03-06 20:46:00.985321+00	731	phone	8110868195	personal	f	f	\N	\N	\N
731	\N	2026-03-06 20:46:01.07182+00	2026-03-06 20:46:01.07182+00	732	phone	919994027859	personal	f	f	\N	\N	\N
732	\N	2026-03-06 20:46:01.156298+00	2026-03-06 20:46:01.156298+00	733	phone	56789	personal	f	f	\N	\N	\N
733	\N	2026-03-06 20:46:01.24914+00	2026-03-06 20:46:01.24914+00	734	phone	918973732632	personal	f	f	\N	\N	\N
734	\N	2026-03-06 20:46:01.371756+00	2026-03-06 20:46:01.371756+00	735	phone	6380 513 846	personal	f	f	\N	\N	\N
735	\N	2026-03-06 20:46:01.501552+00	2026-03-06 20:46:01.501552+00	736	phone	918220010019	personal	f	f	\N	\N	\N
736	\N	2026-03-06 20:46:01.617659+00	2026-03-06 20:46:01.617659+00	737	phone	917094289149	personal	f	f	\N	\N	\N
737	\N	2026-03-06 20:46:01.750569+00	2026-03-06 20:46:01.750569+00	738	phone	919994715101	personal	f	f	\N	\N	\N
738	\N	2026-03-06 20:46:01.842287+00	2026-03-06 20:46:01.842287+00	739	phone	917598165404	personal	f	f	\N	\N	\N
739	\N	2026-03-06 20:46:01.959731+00	2026-03-06 20:46:01.959731+00	740	phone	919790120545	personal	f	f	\N	\N	\N
740	\N	2026-03-06 20:46:02.063012+00	2026-03-06 20:46:02.063012+00	741	phone	101	personal	f	f	\N	\N	\N
741	\N	2026-03-06 20:46:02.197161+00	2026-03-06 20:46:02.197161+00	742	phone	919945108781	personal	f	f	\N	\N	\N
742	\N	2026-03-06 20:46:02.32286+00	2026-03-06 20:46:02.32286+00	743	phone	918754040875	personal	f	f	\N	\N	\N
743	\N	2026-03-06 20:46:02.446596+00	2026-03-06 20:46:02.446596+00	744	phone	916382385431	personal	f	f	\N	\N	\N
744	\N	2026-03-06 20:46:02.562018+00	2026-03-06 20:46:02.562018+00	745	phone	9750469984	personal	f	f	\N	\N	\N
745	\N	2026-03-06 20:46:02.660176+00	2026-03-06 20:46:02.660176+00	746	phone	9003463488	personal	f	f	\N	\N	\N
746	\N	2026-03-06 20:46:02.753404+00	2026-03-06 20:46:02.753404+00	747	phone	9944913908	personal	f	f	\N	\N	\N
747	\N	2026-03-06 20:46:02.871881+00	2026-03-06 20:46:02.871881+00	748	phone	9994898638	personal	f	f	\N	\N	\N
748	\N	2026-03-06 20:46:02.998438+00	2026-03-06 20:46:02.998438+00	749	phone	9944873848	personal	f	f	\N	\N	\N
749	\N	2026-03-06 20:46:03.121418+00	2026-03-06 20:46:03.121418+00	750	phone	8838512824	personal	f	f	\N	\N	\N
750	\N	2026-03-06 20:46:03.238591+00	2026-03-06 20:46:03.238591+00	751	phone	8681968839	personal	f	f	\N	\N	\N
751	\N	2026-03-06 20:46:03.353206+00	2026-03-06 20:46:03.353206+00	752	phone	9361043361	personal	f	f	\N	\N	\N
752	\N	2026-03-06 20:46:03.486901+00	2026-03-06 20:46:03.486901+00	753	phone	918248602880	personal	f	f	\N	\N	\N
753	\N	2026-03-06 20:46:03.65147+00	2026-03-06 20:46:03.65147+00	754	phone	918148815071	personal	f	f	\N	\N	\N
754	\N	2026-03-06 20:46:03.830862+00	2026-03-06 20:46:03.830862+00	755	phone	919942323533	personal	f	f	\N	\N	\N
755	\N	2026-03-06 20:46:03.995086+00	2026-03-06 20:46:03.995086+00	756	phone	9655444344	personal	f	f	\N	\N	\N
756	\N	2026-03-06 20:46:04.205709+00	2026-03-06 20:46:04.205709+00	757	phone	919865113689	personal	f	f	\N	\N	\N
757	\N	2026-03-06 20:46:04.390814+00	2026-03-06 20:46:04.390814+00	758	phone	919787893299	personal	f	f	\N	\N	\N
758	\N	2026-03-06 20:46:04.481869+00	2026-03-06 20:46:04.481869+00	759	phone	919994631430	personal	f	f	\N	\N	\N
759	\N	2026-03-06 20:46:04.567078+00	2026-03-06 20:46:04.567078+00	760	phone	918072273078	personal	f	f	\N	\N	\N
760	\N	2026-03-06 20:46:04.668315+00	2026-03-06 20:46:04.668315+00	761	phone	9994732750	personal	f	f	\N	\N	\N
761	\N	2026-03-06 20:46:04.800062+00	2026-03-06 20:46:04.800062+00	762	phone	7305420822	personal	f	f	\N	\N	\N
762	\N	2026-03-06 20:46:04.919926+00	2026-03-06 20:46:04.919926+00	763	phone	919442160531	personal	f	f	\N	\N	\N
763	\N	2026-03-06 20:46:05.039563+00	2026-03-06 20:46:05.039563+00	764	phone	919629252256	personal	f	f	\N	\N	\N
764	\N	2026-03-06 20:46:05.156611+00	2026-03-06 20:46:05.156611+00	765	phone	9677633000	personal	f	f	\N	\N	\N
765	\N	2026-03-06 20:46:05.252867+00	2026-03-06 20:46:05.252867+00	766	phone	8754424242	personal	f	f	\N	\N	\N
766	\N	2026-03-06 20:46:05.341118+00	2026-03-06 20:46:05.341118+00	767	phone	918220506161	personal	f	f	\N	\N	\N
767	\N	2026-03-06 20:46:05.459175+00	2026-03-06 20:46:05.459175+00	768	phone	919894216096	personal	f	f	\N	\N	\N
768	\N	2026-03-06 20:46:05.596439+00	2026-03-06 20:46:05.596439+00	769	phone	919080663707	personal	f	f	\N	\N	\N
769	\N	2026-03-06 20:46:05.731069+00	2026-03-06 20:46:05.731069+00	770	phone	919791426280	personal	f	f	\N	\N	\N
770	\N	2026-03-06 20:46:05.850146+00	2026-03-06 20:46:05.850146+00	771	phone	917010662971	personal	f	f	\N	\N	\N
771	\N	2026-03-06 20:46:05.947223+00	2026-03-06 20:46:05.947223+00	772	phone	917094353363	personal	f	f	\N	\N	\N
772	\N	2026-03-06 20:46:06.038237+00	2026-03-06 20:46:06.038237+00	773	phone	919442774788	personal	f	f	\N	\N	\N
773	\N	2026-03-06 20:46:06.137082+00	2026-03-06 20:46:06.137082+00	774	phone	917676989995	personal	f	f	\N	\N	\N
774	\N	2026-03-06 20:46:06.264282+00	2026-03-06 20:46:06.264282+00	775	phone	918122714900	personal	f	f	\N	\N	\N
775	\N	2026-03-06 20:46:06.399295+00	2026-03-06 20:46:06.399295+00	776	phone	9976724848	personal	f	f	\N	\N	\N
776	\N	2026-03-06 20:46:06.52273+00	2026-03-06 20:46:06.52273+00	777	phone	8438176686	personal	f	f	\N	\N	\N
777	\N	2026-03-06 20:46:06.632794+00	2026-03-06 20:46:06.632794+00	778	phone	916380308935	personal	f	f	\N	\N	\N
778	\N	2026-03-06 20:46:06.723265+00	2026-03-06 20:46:06.723265+00	779	phone	919344317098	personal	f	f	\N	\N	\N
779	\N	2026-03-06 20:46:06.816872+00	2026-03-06 20:46:06.816872+00	780	phone	917339673918	personal	f	f	\N	\N	\N
780	\N	2026-03-06 20:46:06.923975+00	2026-03-06 20:46:06.923975+00	781	phone	918778117642	personal	f	f	\N	\N	\N
781	\N	2026-03-06 20:46:07.046895+00	2026-03-06 20:46:07.046895+00	782	phone	919445378232	personal	f	f	\N	\N	\N
782	\N	2026-03-06 20:46:07.175177+00	2026-03-06 20:46:07.175177+00	783	phone	918883650899	personal	f	f	\N	\N	\N
783	\N	2026-03-06 20:46:07.303628+00	2026-03-06 20:46:07.303628+00	784	phone	9894294561	personal	f	f	\N	\N	\N
784	\N	2026-03-06 20:46:07.414663+00	2026-03-06 20:46:07.414663+00	785	phone	9443314145	personal	f	f	\N	\N	\N
785	\N	2026-03-06 20:46:07.502162+00	2026-03-06 20:46:07.502162+00	786	phone	919095379895	personal	f	f	\N	\N	\N
786	\N	2026-03-06 20:46:07.591927+00	2026-03-06 20:46:07.591927+00	787	phone	917010977982	personal	f	f	\N	\N	\N
787	\N	2026-03-06 20:46:07.719698+00	2026-03-06 20:46:07.719698+00	788	phone	8248293945	personal	f	f	\N	\N	\N
788	\N	2026-03-06 20:46:07.850836+00	2026-03-06 20:46:07.850836+00	789	phone	54701	personal	f	f	\N	\N	\N
789	\N	2026-03-06 20:46:07.974875+00	2026-03-06 20:46:07.974875+00	790	phone	919751367793	personal	f	f	\N	\N	\N
790	\N	2026-03-06 20:46:08.102504+00	2026-03-06 20:46:08.102504+00	791	phone	918825669348	personal	f	f	\N	\N	\N
791	\N	2026-03-06 20:46:08.21534+00	2026-03-06 20:46:08.21534+00	792	phone	918903202640	personal	f	f	\N	\N	\N
792	\N	2026-03-06 20:46:08.300845+00	2026-03-06 20:46:08.300845+00	793	phone	918778507780	personal	f	f	\N	\N	\N
793	\N	2026-03-06 20:46:08.390621+00	2026-03-06 20:46:08.390621+00	794	phone	+91 93456 76191	personal	f	f	\N	\N	\N
794	\N	2026-03-06 20:46:08.507757+00	2026-03-06 20:46:08.507757+00	795	phone	4622572218	personal	f	f	\N	\N	\N
795	\N	2026-03-06 20:46:08.645353+00	2026-03-06 20:46:08.645353+00	796	phone	9597442284	personal	f	f	\N	\N	\N
796	\N	2026-03-06 20:46:08.76792+00	2026-03-06 20:46:08.76792+00	797	phone	919080556623	personal	f	f	\N	\N	\N
797	\N	2026-03-06 20:46:08.896233+00	2026-03-06 20:46:08.896233+00	798	phone	919842189171	personal	f	f	\N	\N	\N
798	\N	2026-03-06 20:46:08.999358+00	2026-03-06 20:46:08.999358+00	799	phone	919443747038	personal	f	f	\N	\N	\N
799	\N	2026-03-06 20:46:09.088024+00	2026-03-06 20:46:09.088024+00	800	phone	919600954182	personal	f	f	\N	\N	\N
800	\N	2026-03-06 20:46:09.175252+00	2026-03-06 20:46:09.175252+00	801	phone	918754263484	personal	f	f	\N	\N	\N
801	\N	2026-03-06 20:46:09.296068+00	2026-03-06 20:46:09.296068+00	802	phone	+91 95976 17249	personal	f	f	\N	\N	\N
802	\N	2026-03-06 20:46:09.540854+00	2026-03-06 20:46:09.540854+00	803	phone	9750386546	personal	f	f	\N	\N	\N
803	\N	2026-03-06 20:46:09.749497+00	2026-03-06 20:46:09.749497+00	804	phone	919487900130	personal	f	f	\N	\N	\N
804	\N	2026-03-06 20:46:09.940386+00	2026-03-06 20:46:09.940386+00	805	phone	9500675956	personal	f	f	\N	\N	\N
805	\N	2026-03-06 20:46:10.102514+00	2026-03-06 20:46:10.102514+00	806	phone	9677983566	personal	f	f	\N	\N	\N
806	\N	2026-03-06 20:46:10.203044+00	2026-03-06 20:46:10.203044+00	807	phone	919488677374	personal	f	f	\N	\N	\N
807	\N	2026-03-06 20:46:10.31124+00	2026-03-06 20:46:10.31124+00	808	phone	919543218687	personal	f	f	\N	\N	\N
808	\N	2026-03-06 20:46:10.442626+00	2026-03-06 20:46:10.442626+00	809	phone	918056185754	personal	f	f	\N	\N	\N
809	\N	2026-03-06 20:46:10.569404+00	2026-03-06 20:46:10.569404+00	810	phone	4752317270	personal	f	f	\N	\N	\N
810	\N	2026-03-06 20:46:10.692024+00	2026-03-06 20:46:10.692024+00	811	phone	9600816938	personal	f	f	\N	\N	\N
811	\N	2026-03-06 20:46:10.802511+00	2026-03-06 20:46:10.802511+00	812	phone	919003293880	personal	f	f	\N	\N	\N
812	\N	2026-03-06 20:46:10.891247+00	2026-03-06 20:46:10.891247+00	813	phone	918015560164	personal	f	f	\N	\N	\N
813	\N	2026-03-06 20:46:10.979691+00	2026-03-06 20:46:10.979691+00	814	phone	9976489403	personal	f	f	\N	\N	\N
814	\N	2026-03-06 20:46:11.084876+00	2026-03-06 20:46:11.084876+00	815	phone	919790122755	personal	f	f	\N	\N	\N
815	\N	2026-03-06 20:46:11.214941+00	2026-03-06 20:46:11.214941+00	816	phone	919788673392	personal	f	f	\N	\N	\N
816	\N	2026-03-06 20:46:11.338962+00	2026-03-06 20:46:11.338962+00	817	phone	916379977906	personal	f	f	\N	\N	\N
817	\N	2026-03-06 20:46:11.475982+00	2026-03-06 20:46:11.475982+00	818	phone	919495351203	personal	f	f	\N	\N	\N
818	\N	2026-03-06 20:46:11.588542+00	2026-03-06 20:46:11.588542+00	819	phone	919362050002	personal	f	f	\N	\N	\N
819	\N	2026-03-06 20:46:11.677549+00	2026-03-06 20:46:11.677549+00	820	phone	+919995479833 ::: +918921536494	personal	f	f	\N	\N	\N
820	\N	2026-03-06 20:46:11.765044+00	2026-03-06 20:46:11.765044+00	821	phone	8056718430	personal	f	f	\N	\N	\N
821	\N	2026-03-06 20:46:11.87706+00	2026-03-06 20:46:11.87706+00	822	phone	918637426226	personal	f	f	\N	\N	\N
822	\N	2026-03-06 20:46:12.004788+00	2026-03-06 20:46:12.004788+00	823	phone	9788239089	personal	f	f	\N	\N	\N
823	\N	2026-03-06 20:46:12.128262+00	2026-03-06 20:46:12.128262+00	824	phone	9043722700	personal	f	f	\N	\N	\N
824	\N	2026-03-06 20:46:12.252194+00	2026-03-06 20:46:12.252194+00	825	phone	919751229551	personal	f	f	\N	\N	\N
825	\N	2026-03-06 20:46:12.373407+00	2026-03-06 20:46:12.373407+00	826	phone	918220609729	personal	f	f	\N	\N	\N
826	\N	2026-03-06 20:46:12.547157+00	2026-03-06 20:46:12.547157+00	827	phone	9787174866	personal	f	f	\N	\N	\N
827	\N	2026-03-06 20:46:12.688894+00	2026-03-06 20:46:12.688894+00	828	phone	919952469828	personal	f	f	\N	\N	\N
828	\N	2026-03-06 20:46:12.85076+00	2026-03-06 20:46:12.85076+00	829	phone	919003948636	personal	f	f	\N	\N	\N
829	\N	2026-03-06 20:46:12.978855+00	2026-03-06 20:46:12.978855+00	830	phone	9188933734	personal	f	f	\N	\N	\N
830	\N	2026-03-06 20:46:13.104742+00	2026-03-06 20:46:13.104742+00	831	phone	9894786148	personal	f	f	\N	\N	\N
831	\N	2026-03-06 20:46:13.234249+00	2026-03-06 20:46:13.234249+00	832	phone	918220005822	personal	f	f	\N	\N	\N
832	\N	2026-03-06 20:46:13.330184+00	2026-03-06 20:46:13.330184+00	833	phone	+91 88075 87156	personal	f	f	\N	\N	\N
833	\N	2026-03-06 20:46:13.421401+00	2026-03-06 20:46:13.421401+00	834	phone	918870937278	personal	f	f	\N	\N	\N
834	\N	2026-03-06 20:46:13.531977+00	2026-03-06 20:46:13.531977+00	835	phone	919150898832	personal	f	f	\N	\N	\N
835	\N	2026-03-06 20:46:13.68494+00	2026-03-06 20:46:13.68494+00	836	phone	917401299381	personal	f	f	\N	\N	\N
836	\N	2026-03-06 20:46:13.805782+00	2026-03-06 20:46:13.805782+00	837	phone	8072799364	personal	f	f	\N	\N	\N
837	\N	2026-03-06 20:46:13.915064+00	2026-03-06 20:46:13.915064+00	838	phone	919442404802	personal	f	f	\N	\N	\N
838	\N	2026-03-06 20:46:14.032699+00	2026-03-06 20:46:14.032699+00	839	phone	9994764675	personal	f	f	\N	\N	\N
839	\N	2026-03-06 20:46:14.123458+00	2026-03-06 20:46:14.123458+00	840	phone	8260875356	personal	f	f	\N	\N	\N
840	\N	2026-03-06 20:46:14.212056+00	2026-03-06 20:46:14.212056+00	841	phone	919942993304	personal	f	f	\N	\N	\N
841	\N	2026-03-06 20:46:14.317444+00	2026-03-06 20:46:14.317444+00	842	phone	+91 90802 08860	personal	f	f	\N	\N	\N
842	\N	2026-03-06 20:46:14.448711+00	2026-03-06 20:46:14.448711+00	843	phone	919443195922	personal	f	f	\N	\N	\N
843	\N	2026-03-06 20:46:14.583897+00	2026-03-06 20:46:14.583897+00	844	phone	917584865633	personal	f	f	\N	\N	\N
844	\N	2026-03-06 20:46:14.719992+00	2026-03-06 20:46:14.719992+00	845	phone	919487654489	personal	f	f	\N	\N	\N
845	\N	2026-03-06 20:46:14.83809+00	2026-03-06 20:46:14.83809+00	846	phone	180030002013	personal	f	f	\N	\N	\N
846	\N	2026-03-06 20:46:14.953279+00	2026-03-06 20:46:14.953279+00	847	phone	919500171448	personal	f	f	\N	\N	\N
847	\N	2026-03-06 20:46:15.040299+00	2026-03-06 20:46:15.040299+00	848	phone	89039 84336	personal	f	f	\N	\N	\N
848	\N	2026-03-06 20:46:15.213544+00	2026-03-06 20:46:15.213544+00	849	phone	919750404633	personal	f	f	\N	\N	\N
849	\N	2026-03-06 20:46:15.426289+00	2026-03-06 20:46:15.426289+00	850	phone	917530014817	personal	f	f	\N	\N	\N
850	\N	2026-03-06 20:46:15.612963+00	2026-03-06 20:46:15.612963+00	851	phone	9629212524	personal	f	f	\N	\N	\N
851	\N	2026-03-06 20:46:15.787186+00	2026-03-06 20:46:15.787186+00	852	phone	919605192368	personal	f	f	\N	\N	\N
852	\N	2026-03-06 20:46:15.960832+00	2026-03-06 20:46:15.960832+00	853	phone	919663201703	personal	f	f	\N	\N	\N
853	\N	2026-03-06 20:46:16.08257+00	2026-03-06 20:46:16.08257+00	854	phone	9946355831	personal	f	f	\N	\N	\N
854	\N	2026-03-06 20:46:16.226619+00	2026-03-06 20:46:16.226619+00	855	phone	9944027434	personal	f	f	\N	\N	\N
855	\N	2026-03-06 20:46:16.349624+00	2026-03-06 20:46:16.349624+00	856	phone	917012952562	personal	f	f	\N	\N	\N
856	\N	2026-03-06 20:46:16.484893+00	2026-03-06 20:46:16.484893+00	857	phone	919962661996	personal	f	f	\N	\N	\N
857	\N	2026-03-06 20:46:16.609964+00	2026-03-06 20:46:16.609964+00	858	phone	9791396391	personal	f	f	\N	\N	\N
858	\N	2026-03-06 20:46:16.737405+00	2026-03-06 20:46:16.737405+00	859	phone	9659361291	personal	f	f	\N	\N	\N
859	\N	2026-03-06 20:46:16.828997+00	2026-03-06 20:46:16.828997+00	860	phone	9489242525	personal	f	f	\N	\N	\N
860	\N	2026-03-06 20:46:16.914832+00	2026-03-06 20:46:16.914832+00	861	phone	917397566252	personal	f	f	\N	\N	\N
861	\N	2026-03-06 20:46:17.014286+00	2026-03-06 20:46:17.014286+00	862	phone	919791679926	personal	f	f	\N	\N	\N
862	\N	2026-03-06 20:46:17.159426+00	2026-03-06 20:46:17.159426+00	863	phone	919600768376	personal	f	f	\N	\N	\N
863	\N	2026-03-06 20:46:17.285737+00	2026-03-06 20:46:17.285737+00	864	phone	916369938036	personal	f	f	\N	\N	\N
864	\N	2026-03-06 20:46:17.417297+00	2026-03-06 20:46:17.417297+00	865	phone	917094588759	personal	f	f	\N	\N	\N
865	\N	2026-03-06 20:46:17.533366+00	2026-03-06 20:46:17.533366+00	866	phone	7358417174	personal	f	f	\N	\N	\N
866	\N	2026-03-06 20:46:17.64595+00	2026-03-06 20:46:17.64595+00	867	phone	547012	personal	f	f	\N	\N	\N
867	\N	2026-03-06 20:46:17.757703+00	2026-03-06 20:46:17.757703+00	868	phone	917708988088	personal	f	f	\N	\N	\N
868	\N	2026-03-06 20:46:17.887101+00	2026-03-06 20:46:17.887101+00	869	phone	56700	personal	f	f	\N	\N	\N
869	\N	2026-03-06 20:46:18.019562+00	2026-03-06 20:46:18.019562+00	870	phone	919500484208	personal	f	f	\N	\N	\N
870	\N	2026-03-06 20:46:18.142256+00	2026-03-06 20:46:18.142256+00	871	phone	919944692247	personal	f	f	\N	\N	\N
871	\N	2026-03-06 20:46:18.268927+00	2026-03-06 20:46:18.268927+00	872	phone	919080414004	personal	f	f	\N	\N	\N
872	\N	2026-03-06 20:46:18.36493+00	2026-03-06 20:46:18.36493+00	873	phone	918610464807	personal	f	f	\N	\N	\N
873	\N	2026-03-06 20:46:18.452864+00	2026-03-06 20:46:18.452864+00	874	phone	919159147614	personal	f	f	\N	\N	\N
874	\N	2026-03-06 20:46:18.547092+00	2026-03-06 20:46:18.547092+00	875	phone	919486712901	personal	f	f	\N	\N	\N
875	\N	2026-03-06 20:46:18.658384+00	2026-03-06 20:46:18.658384+00	876	phone	9159147614	personal	f	f	\N	\N	\N
876	\N	2026-03-06 20:46:18.797906+00	2026-03-06 20:46:18.797906+00	877	phone	919159147614	personal	f	f	\N	\N	\N
877	\N	2026-03-06 20:46:18.923253+00	2026-03-06 20:46:18.923253+00	878	phone	9159404049	personal	f	f	\N	\N	\N
878	\N	2026-03-06 20:46:19.039051+00	2026-03-06 20:46:19.039051+00	879	phone	919739681115	personal	f	f	\N	\N	\N
879	\N	2026-03-06 20:46:19.143368+00	2026-03-06 20:46:19.143368+00	880	phone	918754304884	personal	f	f	\N	\N	\N
880	\N	2026-03-06 20:46:19.236909+00	2026-03-06 20:46:19.236909+00	881	phone	918072909492	personal	f	f	\N	\N	\N
881	\N	2026-03-06 20:46:19.32567+00	2026-03-06 20:46:19.32567+00	882	phone	918122296350	personal	f	f	\N	\N	\N
882	\N	2026-03-06 20:46:19.448889+00	2026-03-06 20:46:19.448889+00	883	phone	919566943391	personal	f	f	\N	\N	\N
883	\N	2026-03-06 20:46:19.588229+00	2026-03-06 20:46:19.588229+00	884	phone	919048218201	personal	f	f	\N	\N	\N
884	\N	2026-03-06 20:46:19.718772+00	2026-03-06 20:46:19.718772+00	885	phone	919539028178	personal	f	f	\N	\N	\N
885	\N	2026-03-06 20:46:19.83894+00	2026-03-06 20:46:19.83894+00	886	phone	918921874363	personal	f	f	\N	\N	\N
886	\N	2026-03-06 20:46:19.939957+00	2026-03-06 20:46:19.939957+00	887	phone	918754763527	personal	f	f	\N	\N	\N
887	\N	2026-03-06 20:46:20.029164+00	2026-03-06 20:46:20.029164+00	888	phone	918208306391	personal	f	f	\N	\N	\N
888	\N	2026-03-06 20:46:20.114403+00	2026-03-06 20:46:20.114403+00	889	phone	917034401823	personal	f	f	\N	\N	\N
889	\N	2026-03-06 20:46:20.231156+00	2026-03-06 20:46:20.231156+00	890	phone	9486608812	personal	f	f	\N	\N	\N
890	\N	2026-03-06 20:46:20.345853+00	2026-03-06 20:46:20.345853+00	891	phone	9843251505	personal	f	f	\N	\N	\N
891	\N	2026-03-06 20:46:20.503073+00	2026-03-06 20:46:20.503073+00	892	phone	918015931119	personal	f	f	\N	\N	\N
892	\N	2026-03-06 20:46:20.640849+00	2026-03-06 20:46:20.640849+00	893	phone	7639837016	personal	f	f	\N	\N	\N
893	\N	2026-03-06 20:46:20.739306+00	2026-03-06 20:46:20.739306+00	894	phone	917010028742	personal	f	f	\N	\N	\N
894	\N	2026-03-06 20:46:20.830831+00	2026-03-06 20:46:20.830831+00	895	phone	919655090501	personal	f	f	\N	\N	\N
895	\N	2026-03-06 20:46:20.915388+00	2026-03-06 20:46:20.915388+00	896	phone	919566546509	personal	f	f	\N	\N	\N
896	\N	2026-03-06 20:46:21.029766+00	2026-03-06 20:46:21.029766+00	897	phone	919789510577	personal	f	f	\N	\N	\N
897	\N	2026-03-06 20:46:21.152383+00	2026-03-06 20:46:21.152383+00	898	phone	918675220522	personal	f	f	\N	\N	\N
898	\N	2026-03-06 20:46:21.350571+00	2026-03-06 20:46:21.350571+00	899	phone	9442144650	personal	f	f	\N	\N	\N
899	\N	2026-03-06 20:46:21.594332+00	2026-03-06 20:46:21.594332+00	900	phone	9786475426	personal	f	f	\N	\N	\N
900	\N	2026-03-06 20:46:21.754844+00	2026-03-06 20:46:21.754844+00	901	phone	919655960747	personal	f	f	\N	\N	\N
901	\N	2026-03-06 20:46:21.883529+00	2026-03-06 20:46:21.883529+00	902	phone	94475 23690	personal	f	f	\N	\N	\N
902	\N	2026-03-06 20:46:22.068015+00	2026-03-06 20:46:22.068015+00	903	phone	*111*1#	personal	f	f	\N	\N	\N
903	\N	2026-03-06 20:46:22.23551+00	2026-03-06 20:46:22.23551+00	904	phone	919080084610	personal	f	f	\N	\N	\N
904	\N	2026-03-06 20:46:22.361345+00	2026-03-06 20:46:22.361345+00	905	phone	9965332520	personal	f	f	\N	\N	\N
905	\N	2026-03-06 20:46:22.474347+00	2026-03-06 20:46:22.474347+00	906	phone	9629759533	personal	f	f	\N	\N	\N
906	\N	2026-03-06 20:46:22.565515+00	2026-03-06 20:46:22.565515+00	907	phone	9488678138	personal	f	f	\N	\N	\N
907	\N	2026-03-06 20:46:22.656354+00	2026-03-06 20:46:22.656354+00	908	phone	919645820066	personal	f	f	\N	\N	\N
908	\N	2026-03-06 20:46:22.763977+00	2026-03-06 20:46:22.763977+00	909	phone	918593942341	personal	f	f	\N	\N	\N
909	\N	2026-03-06 20:46:22.876724+00	2026-03-06 20:46:22.876724+00	910	phone	917339167149	personal	f	f	\N	\N	\N
910	\N	2026-03-06 20:46:23.01199+00	2026-03-06 20:46:23.01199+00	911	phone	9443080249	personal	f	f	\N	\N	\N
911	\N	2026-03-06 20:46:23.134789+00	2026-03-06 20:46:23.134789+00	912	phone	919361281968	personal	f	f	\N	\N	\N
912	\N	2026-03-06 20:46:23.259075+00	2026-03-06 20:46:23.259075+00	913	phone	919500960729	personal	f	f	\N	\N	\N
913	\N	2026-03-06 20:46:23.361394+00	2026-03-06 20:46:23.361394+00	914	phone	*123*30#	personal	f	f	\N	\N	\N
914	\N	2026-03-06 20:46:23.47237+00	2026-03-06 20:46:23.47237+00	915	phone	918056882284	personal	f	f	\N	\N	\N
915	\N	2026-03-06 20:46:23.606097+00	2026-03-06 20:46:23.606097+00	916	phone	8220623277	personal	f	f	\N	\N	\N
916	\N	2026-03-06 20:46:23.725629+00	2026-03-06 20:46:23.725629+00	917	phone	9443433508	personal	f	f	\N	\N	\N
917	\N	2026-03-06 20:46:23.859305+00	2026-03-06 20:46:23.859305+00	918	phone	919944967729	personal	f	f	\N	\N	\N
918	\N	2026-03-06 20:46:23.985518+00	2026-03-06 20:46:23.985518+00	919	phone	919865642205	personal	f	f	\N	\N	\N
919	\N	2026-03-06 20:46:24.097821+00	2026-03-06 20:46:24.097821+00	920	phone	9366709007	personal	f	f	\N	\N	\N
920	\N	2026-03-06 20:46:24.186086+00	2026-03-06 20:46:24.186086+00	921	phone	916379468940	personal	f	f	\N	\N	\N
921	\N	2026-03-06 20:46:24.275396+00	2026-03-06 20:46:24.275396+00	922	phone	919994914556	personal	f	f	\N	\N	\N
922	\N	2026-03-06 20:46:24.382161+00	2026-03-06 20:46:24.382161+00	923	phone	918593069418	personal	f	f	\N	\N	\N
923	\N	2026-03-06 20:46:24.503092+00	2026-03-06 20:46:24.503092+00	924	phone	919847310767	personal	f	f	\N	\N	\N
924	\N	2026-03-06 20:46:24.623129+00	2026-03-06 20:46:24.623129+00	925	phone	7907182568	personal	f	f	\N	\N	\N
925	\N	2026-03-06 20:46:24.755712+00	2026-03-06 20:46:24.755712+00	926	phone	919443983202	personal	f	f	\N	\N	\N
926	\N	2026-03-06 20:46:24.881912+00	2026-03-06 20:46:24.881912+00	927	phone	919597850680	personal	f	f	\N	\N	\N
927	\N	2026-03-06 20:46:24.969903+00	2026-03-06 20:46:24.969903+00	928	phone	919994881929	personal	f	f	\N	\N	\N
928	\N	2026-03-06 20:46:25.056679+00	2026-03-06 20:46:25.056679+00	929	phone	919442081290	personal	f	f	\N	\N	\N
929	\N	2026-03-06 20:46:25.142528+00	2026-03-06 20:46:25.142528+00	930	phone	916374395863	personal	f	f	\N	\N	\N
930	\N	2026-03-06 20:46:25.264861+00	2026-03-06 20:46:25.264861+00	931	phone	919842817977	personal	f	f	\N	\N	\N
931	\N	2026-03-06 20:46:25.382948+00	2026-03-06 20:46:25.382948+00	932	phone	919566765672	personal	f	f	\N	\N	\N
932	\N	2026-03-06 20:46:25.51854+00	2026-03-06 20:46:25.51854+00	933	phone	9790625475	personal	f	f	\N	\N	\N
933	\N	2026-03-06 20:46:25.652958+00	2026-03-06 20:46:25.652958+00	934	phone	918667304156	personal	f	f	\N	\N	\N
934	\N	2026-03-06 20:46:25.748548+00	2026-03-06 20:46:25.748548+00	935	phone	919842164300	personal	f	f	\N	\N	\N
935	\N	2026-03-06 20:46:25.837305+00	2026-03-06 20:46:25.837305+00	936	phone	9865164300	personal	f	f	\N	\N	\N
936	\N	2026-03-06 20:46:25.9267+00	2026-03-06 20:46:25.9267+00	937	phone	9865164300	personal	f	f	\N	\N	\N
937	\N	2026-03-06 20:46:26.051449+00	2026-03-06 20:46:26.051449+00	938	phone	919087556460	personal	f	f	\N	\N	\N
938	\N	2026-03-06 20:46:26.17171+00	2026-03-06 20:46:26.17171+00	939	phone	919894753144	personal	f	f	\N	\N	\N
939	\N	2026-03-06 20:46:26.289591+00	2026-03-06 20:46:26.289591+00	940	phone	917010972268	personal	f	f	\N	\N	\N
940	\N	2026-03-06 20:46:26.429211+00	2026-03-06 20:46:26.429211+00	941	phone	919500342939	personal	f	f	\N	\N	\N
941	\N	2026-03-06 20:46:26.528828+00	2026-03-06 20:46:26.528828+00	942	phone	+919840233626 ::: +919840233626	personal	f	f	\N	\N	\N
942	\N	2026-03-06 20:46:26.630176+00	2026-03-06 20:46:26.630176+00	943	phone	9788558146	personal	f	f	\N	\N	\N
943	\N	2026-03-06 20:46:26.740231+00	2026-03-06 20:46:26.740231+00	944	phone	919655666697	personal	f	f	\N	\N	\N
944	\N	2026-03-06 20:46:26.864269+00	2026-03-06 20:46:26.864269+00	945	phone	8825716823	personal	f	f	\N	\N	\N
945	\N	2026-03-06 20:46:26.986785+00	2026-03-06 20:46:26.986785+00	946	phone	919092771262	personal	f	f	\N	\N	\N
946	\N	2026-03-06 20:46:27.108625+00	2026-03-06 20:46:27.108625+00	947	phone	3192	personal	f	f	\N	\N	\N
947	\N	2026-03-06 20:46:27.257534+00	2026-03-06 20:46:27.257534+00	948	phone	100	personal	f	f	\N	\N	\N
948	\N	2026-03-06 20:46:27.38292+00	2026-03-06 20:46:27.38292+00	949	phone	919003745251	personal	f	f	\N	\N	\N
949	\N	2026-03-06 20:46:27.541501+00	2026-03-06 20:46:27.541501+00	950	phone	+91 95668 92966	personal	f	f	\N	\N	\N
950	\N	2026-03-06 20:46:27.728276+00	2026-03-06 20:46:27.728276+00	951	phone	9244222269	personal	f	f	\N	\N	\N
951	\N	2026-03-06 20:46:27.913501+00	2026-03-06 20:46:27.913501+00	952	phone	919843714411	personal	f	f	\N	\N	\N
952	\N	2026-03-06 20:46:28.108557+00	2026-03-06 20:46:28.108557+00	953	phone	918951879955	personal	f	f	\N	\N	\N
953	\N	2026-03-06 20:46:28.233463+00	2026-03-06 20:46:28.233463+00	954	phone	9843876576	personal	f	f	\N	\N	\N
954	\N	2026-03-06 20:46:28.327433+00	2026-03-06 20:46:28.327433+00	955	phone	9443809408	personal	f	f	\N	\N	\N
955	\N	2026-03-06 20:46:28.416596+00	2026-03-06 20:46:28.416596+00	956	phone	918903122122	personal	f	f	\N	\N	\N
956	\N	2026-03-06 20:46:28.52011+00	2026-03-06 20:46:28.52011+00	957	phone	919791663418	personal	f	f	\N	\N	\N
957	\N	2026-03-06 20:46:28.645054+00	2026-03-06 20:46:28.645054+00	958	phone	919487900170	personal	f	f	\N	\N	\N
958	\N	2026-03-06 20:46:28.778355+00	2026-03-06 20:46:28.778355+00	959	phone	8825842417	personal	f	f	\N	\N	\N
959	\N	2026-03-06 20:46:28.907812+00	2026-03-06 20:46:28.907812+00	960	phone	9442132191	personal	f	f	\N	\N	\N
960	\N	2026-03-06 20:46:29.027213+00	2026-03-06 20:46:29.027213+00	961	phone	919092801079	personal	f	f	\N	\N	\N
961	\N	2026-03-06 20:46:29.117711+00	2026-03-06 20:46:29.117711+00	962	phone	+91 96009 87958	personal	f	f	\N	\N	\N
962	\N	2026-03-06 20:46:29.202887+00	2026-03-06 20:46:29.202887+00	963	phone	58000	personal	f	f	\N	\N	\N
963	\N	2026-03-06 20:46:29.300773+00	2026-03-06 20:46:29.300773+00	964	phone	9947595123	personal	f	f	\N	\N	\N
964	\N	2026-03-06 20:46:29.438885+00	2026-03-06 20:46:29.438885+00	965	phone	917904098437	personal	f	f	\N	\N	\N
965	\N	2026-03-06 20:46:29.565217+00	2026-03-06 20:46:29.565217+00	966	phone	918248787689	personal	f	f	\N	\N	\N
966	\N	2026-03-06 20:46:29.699614+00	2026-03-06 20:46:29.699614+00	967	phone	918056822906	personal	f	f	\N	\N	\N
967	\N	2026-03-06 20:46:29.81681+00	2026-03-06 20:46:29.81681+00	968	phone	139	personal	f	f	\N	\N	\N
968	\N	2026-03-06 20:46:29.914698+00	2026-03-06 20:46:29.914698+00	969	phone	*139*1#	personal	f	f	\N	\N	\N
969	\N	2026-03-06 20:46:30.002397+00	2026-03-06 20:46:30.002397+00	970	phone	919486450475	personal	f	f	\N	\N	\N
970	\N	2026-03-06 20:46:30.102964+00	2026-03-06 20:46:30.102964+00	971	phone	7448520144	personal	f	f	\N	\N	\N
971	\N	2026-03-06 20:46:30.22973+00	2026-03-06 20:46:30.22973+00	972	phone	919047032191	personal	f	f	\N	\N	\N
972	\N	2026-03-06 20:46:30.360979+00	2026-03-06 20:46:30.360979+00	973	phone	7708436508	personal	f	f	\N	\N	\N
973	\N	2026-03-06 20:46:30.478911+00	2026-03-06 20:46:30.478911+00	974	phone	918012398889	personal	f	f	\N	\N	\N
974	\N	2026-03-06 20:46:30.602846+00	2026-03-06 20:46:30.602846+00	975	phone	9842873458	personal	f	f	\N	\N	\N
975	\N	2026-03-06 20:46:30.696805+00	2026-03-06 20:46:30.696805+00	976	phone	919495433505	personal	f	f	\N	\N	\N
976	\N	2026-03-06 20:46:30.788672+00	2026-03-06 20:46:30.788672+00	977	phone	919048369586	personal	f	f	\N	\N	\N
977	\N	2026-03-06 20:46:30.883436+00	2026-03-06 20:46:30.883436+00	978	phone	9946574521	personal	f	f	\N	\N	\N
978	\N	2026-03-06 20:46:30.999466+00	2026-03-06 20:46:30.999466+00	979	phone	919048574958	personal	f	f	\N	\N	\N
979	\N	2026-03-06 20:46:31.124645+00	2026-03-06 20:46:31.124645+00	980	phone	918610753428	personal	f	f	\N	\N	\N
980	\N	2026-03-06 20:46:31.246763+00	2026-03-06 20:46:31.246763+00	981	phone	+91 98416 05245	personal	f	f	\N	\N	\N
981	\N	2026-03-06 20:46:31.375108+00	2026-03-06 20:46:31.375108+00	982	phone	8056115888	personal	f	f	\N	\N	\N
982	\N	2026-03-06 20:46:31.480668+00	2026-03-06 20:46:31.480668+00	983	phone	917591907183	personal	f	f	\N	\N	\N
983	\N	2026-03-06 20:46:31.574582+00	2026-03-06 20:46:31.574582+00	984	phone	919655721770	personal	f	f	\N	\N	\N
984	\N	2026-03-06 20:46:31.659133+00	2026-03-06 20:46:31.659133+00	985	phone	918012801213	personal	f	f	\N	\N	\N
985	\N	2026-03-06 20:46:31.839882+00	2026-03-06 20:46:31.839882+00	987	phone	918072922340	personal	f	f	\N	\N	\N
986	\N	2026-03-06 20:46:31.965816+00	2026-03-06 20:46:31.965816+00	988	phone	918940150880	personal	f	f	\N	\N	\N
987	\N	2026-03-06 20:46:32.091128+00	2026-03-06 20:46:32.091128+00	989	phone	918056926926	personal	f	f	\N	\N	\N
988	\N	2026-03-06 20:46:32.219782+00	2026-03-06 20:46:32.219782+00	990	phone	9788125125	personal	f	f	\N	\N	\N
989	\N	2026-03-06 20:46:32.317163+00	2026-03-06 20:46:32.317163+00	991	phone	919745464595	personal	f	f	\N	\N	\N
990	\N	2026-03-06 20:46:32.411201+00	2026-03-06 20:46:32.411201+00	992	phone	919442593813	personal	f	f	\N	\N	\N
991	\N	2026-03-06 20:46:32.512091+00	2026-03-06 20:46:32.512091+00	993	phone	9894962842	personal	f	f	\N	\N	\N
992	\N	2026-03-06 20:46:32.656197+00	2026-03-06 20:46:32.656197+00	994	phone	9486804995	personal	f	f	\N	\N	\N
993	\N	2026-03-06 20:46:32.776311+00	2026-03-06 20:46:32.776311+00	995	phone	94469 76641	personal	f	f	\N	\N	\N
994	\N	2026-03-06 20:46:32.902454+00	2026-03-06 20:46:32.902454+00	996	phone	919488669309	personal	f	f	\N	\N	\N
995	\N	2026-03-06 20:46:33.019861+00	2026-03-06 20:46:33.019861+00	997	phone	919894531502	personal	f	f	\N	\N	\N
996	\N	2026-03-06 20:46:33.129151+00	2026-03-06 20:46:33.129151+00	998	phone	918056966285	personal	f	f	\N	\N	\N
997	\N	2026-03-06 20:46:33.252579+00	2026-03-06 20:46:33.252579+00	999	phone	9843815198	personal	f	f	\N	\N	\N
998	\N	2026-03-06 20:46:33.440123+00	2026-03-06 20:46:33.440123+00	1000	phone	140	personal	f	f	\N	\N	\N
999	\N	2026-03-06 20:46:33.650454+00	2026-03-06 20:46:33.650454+00	1001	phone	916382500387	personal	f	f	\N	\N	\N
1000	\N	2026-03-06 20:46:33.898324+00	2026-03-06 20:46:33.898324+00	1002	phone	8754840875	personal	f	f	\N	\N	\N
1001	\N	2026-03-06 20:46:34.032471+00	2026-03-06 20:46:34.032471+00	1003	phone	918939862859	personal	f	f	\N	\N	\N
1002	\N	2026-03-06 20:46:34.154673+00	2026-03-06 20:46:34.154673+00	1004	phone	918072820824	personal	f	f	\N	\N	\N
1003	\N	2026-03-06 20:46:34.240478+00	2026-03-06 20:46:34.240478+00	1005	phone	+91 99420 16170	personal	f	f	\N	\N	\N
1004	\N	2026-03-06 20:46:34.326793+00	2026-03-06 20:46:34.326793+00	1006	phone	918825460428	personal	f	f	\N	\N	\N
1005	\N	2026-03-06 20:46:34.443071+00	2026-03-06 20:46:34.443071+00	1007	phone	919585750787	personal	f	f	\N	\N	\N
1006	\N	2026-03-06 20:46:34.577829+00	2026-03-06 20:46:34.577829+00	1008	phone	917305005554	personal	f	f	\N	\N	\N
1007	\N	2026-03-06 20:46:34.702265+00	2026-03-06 20:46:34.702265+00	1009	phone	9344476660	personal	f	f	\N	\N	\N
1008	\N	2026-03-06 20:46:34.822861+00	2026-03-06 20:46:34.822861+00	1010	phone	9842117929	personal	f	f	\N	\N	\N
1009	\N	2026-03-06 20:46:34.938327+00	2026-03-06 20:46:34.938327+00	1011	phone	918220387048	personal	f	f	\N	\N	\N
1010	\N	2026-03-06 20:46:35.026899+00	2026-03-06 20:46:35.026899+00	1012	phone	9962862300	personal	f	f	\N	\N	\N
1011	\N	2026-03-06 20:46:35.109774+00	2026-03-06 20:46:35.109774+00	1013	phone	918668135148	personal	f	f	\N	\N	\N
1012	\N	2026-03-06 20:46:35.22889+00	2026-03-06 20:46:35.22889+00	1014	phone	919677190166	personal	f	f	\N	\N	\N
1013	\N	2026-03-06 20:46:35.359611+00	2026-03-06 20:46:35.359611+00	1015	phone	919629742566	personal	f	f	\N	\N	\N
1014	\N	2026-03-06 20:46:35.495252+00	2026-03-06 20:46:35.495252+00	1016	phone	919952129147	personal	f	f	\N	\N	\N
1015	\N	2026-03-06 20:46:35.628841+00	2026-03-06 20:46:35.628841+00	1017	phone	9994500675	personal	f	f	\N	\N	\N
1016	\N	2026-03-06 20:46:35.740545+00	2026-03-06 20:46:35.740545+00	1018	phone	919688639323	personal	f	f	\N	\N	\N
1017	\N	2026-03-06 20:46:35.832901+00	2026-03-06 20:46:35.832901+00	1019	phone	916382320754	personal	f	f	\N	\N	\N
1018	\N	2026-03-06 20:46:35.919158+00	2026-03-06 20:46:35.919158+00	1020	phone	8124803866	personal	f	f	\N	\N	\N
1019	\N	2026-03-06 20:46:36.04188+00	2026-03-06 20:46:36.04188+00	1021	phone	919677395388	personal	f	f	\N	\N	\N
1020	\N	2026-03-06 20:46:36.173007+00	2026-03-06 20:46:36.173007+00	1022	phone	918943829452	personal	f	f	\N	\N	\N
1021	\N	2026-03-06 20:46:36.303139+00	2026-03-06 20:46:36.303139+00	1023	phone	919061132872	personal	f	f	\N	\N	\N
1022	\N	2026-03-06 20:46:36.421238+00	2026-03-06 20:46:36.421238+00	1024	phone	919495472652	personal	f	f	\N	\N	\N
1023	\N	2026-03-06 20:46:36.536698+00	2026-03-06 20:46:36.536698+00	1025	phone	+91 80863 49116	personal	f	f	\N	\N	\N
1024	\N	2026-03-06 20:46:36.629661+00	2026-03-06 20:46:36.629661+00	1026	phone	918489800195	personal	f	f	\N	\N	\N
1025	\N	2026-03-06 20:46:36.719977+00	2026-03-06 20:46:36.719977+00	1027	phone	918883424102	personal	f	f	\N	\N	\N
1026	\N	2026-03-06 20:46:36.837053+00	2026-03-06 20:46:36.837053+00	1028	phone	916385815747	personal	f	f	\N	\N	\N
1027	\N	2026-03-06 20:46:36.95681+00	2026-03-06 20:46:36.95681+00	1029	phone	9847039045	personal	f	f	\N	\N	\N
1028	\N	2026-03-06 20:46:37.09041+00	2026-03-06 20:46:37.09041+00	1030	phone	918939490776	personal	f	f	\N	\N	\N
1029	\N	2026-03-06 20:46:37.211795+00	2026-03-06 20:46:37.211795+00	1031	phone	918098253060	personal	f	f	\N	\N	\N
1030	\N	2026-03-06 20:46:37.305293+00	2026-03-06 20:46:37.305293+00	1032	phone	919597052810	personal	f	f	\N	\N	\N
1031	\N	2026-03-06 20:46:37.393544+00	2026-03-06 20:46:37.393544+00	1033	phone	917045719909	personal	f	f	\N	\N	\N
1032	\N	2026-03-06 20:46:37.493287+00	2026-03-06 20:46:37.493287+00	1034	phone	918111942259	personal	f	f	\N	\N	\N
1033	\N	2026-03-06 20:46:37.614874+00	2026-03-06 20:46:37.614874+00	1035	phone	919072955212	personal	f	f	\N	\N	\N
1034	\N	2026-03-06 20:46:37.736624+00	2026-03-06 20:46:37.736624+00	1036	phone	917560964232	personal	f	f	\N	\N	\N
1035	\N	2026-03-06 20:46:37.86077+00	2026-03-06 20:46:37.86077+00	1037	phone	917012494170	personal	f	f	\N	\N	\N
1036	\N	2026-03-06 20:46:37.989728+00	2026-03-06 20:46:37.989728+00	1038	phone	919791814292	personal	f	f	\N	\N	\N
1037	\N	2026-03-06 20:46:38.085022+00	2026-03-06 20:46:38.085022+00	1039	phone	918078108247	personal	f	f	\N	\N	\N
1038	\N	2026-03-06 20:46:38.187897+00	2026-03-06 20:46:38.187897+00	1040	phone	9944744968	personal	f	f	\N	\N	\N
1039	\N	2026-03-06 20:46:38.293021+00	2026-03-06 20:46:38.293021+00	1041	phone	919943062625	personal	f	f	\N	\N	\N
1040	\N	2026-03-06 20:46:38.426918+00	2026-03-06 20:46:38.426918+00	1042	phone	919443695817	personal	f	f	\N	\N	\N
1041	\N	2026-03-06 20:46:38.556477+00	2026-03-06 20:46:38.556477+00	1043	phone	919940270288	personal	f	f	\N	\N	\N
1042	\N	2026-03-06 20:46:38.69021+00	2026-03-06 20:46:38.69021+00	1044	phone	+91 98425 63868	personal	f	f	\N	\N	\N
1043	\N	2026-03-06 20:46:38.81134+00	2026-03-06 20:46:38.81134+00	1045	phone	919500660575	personal	f	f	\N	\N	\N
1044	\N	2026-03-06 20:46:38.906593+00	2026-03-06 20:46:38.906593+00	1046	phone	919443854694	personal	f	f	\N	\N	\N
1045	\N	2026-03-06 20:46:39.035549+00	2026-03-06 20:46:39.035549+00	1047	phone	9994440202	personal	f	f	\N	\N	\N
1046	\N	2026-03-06 20:46:39.24641+00	2026-03-06 20:46:39.24641+00	1048	phone	9842183572	personal	f	f	\N	\N	\N
1047	\N	2026-03-06 20:46:39.42901+00	2026-03-06 20:46:39.42901+00	1049	phone	919655555711	personal	f	f	\N	\N	\N
1048	\N	2026-03-06 20:46:39.642036+00	2026-03-06 20:46:39.642036+00	1050	phone	9000529830	personal	f	f	\N	\N	\N
1049	\N	2026-03-06 20:46:39.848981+00	2026-03-06 20:46:39.848981+00	1051	phone	9585122156	personal	f	f	\N	\N	\N
1050	\N	2026-03-06 20:46:39.946626+00	2026-03-06 20:46:39.946626+00	1052	phone	919952873330	personal	f	f	\N	\N	\N
1051	\N	2026-03-06 20:46:40.036878+00	2026-03-06 20:46:40.036878+00	1053	phone	9894400956	personal	f	f	\N	\N	\N
1052	\N	2026-03-06 20:46:40.120579+00	2026-03-06 20:46:40.120579+00	1054	phone	919087688738	personal	f	f	\N	\N	\N
1053	\N	2026-03-06 20:46:40.240768+00	2026-03-06 20:46:40.240768+00	1055	phone	971528448661	personal	f	f	\N	\N	\N
1054	\N	2026-03-06 20:46:40.358811+00	2026-03-06 20:46:40.358811+00	1056	phone	914652359130	personal	f	f	\N	\N	\N
1055	\N	2026-03-06 20:46:40.492923+00	2026-03-06 20:46:40.492923+00	1057	phone	919150504103	personal	f	f	\N	\N	\N
1056	\N	2026-03-06 20:46:40.623476+00	2026-03-06 20:46:40.623476+00	1058	phone	9003336855	personal	f	f	\N	\N	\N
1057	\N	2026-03-06 20:46:40.731356+00	2026-03-06 20:46:40.731356+00	1059	phone	9744044197	personal	f	f	\N	\N	\N
1058	\N	2026-03-06 20:46:40.820966+00	2026-03-06 20:46:40.820966+00	1060	phone	919500148131	personal	f	f	\N	\N	\N
1059	\N	2026-03-06 20:46:40.912579+00	2026-03-06 20:46:40.912579+00	1061	phone	9443344161	personal	f	f	\N	\N	\N
1060	\N	2026-03-06 20:46:41.040115+00	2026-03-06 20:46:41.040115+00	1062	phone	9786143733	personal	f	f	\N	\N	\N
1061	\N	2026-03-06 20:46:41.15281+00	2026-03-06 20:46:41.15281+00	1063	phone	+91 77082 30177	personal	f	f	\N	\N	\N
1062	\N	2026-03-06 20:46:41.279319+00	2026-03-06 20:46:41.279319+00	1064	phone	917010561438	personal	f	f	\N	\N	\N
1063	\N	2026-03-06 20:46:41.411045+00	2026-03-06 20:46:41.411045+00	1065	phone	918012285739	personal	f	f	\N	\N	\N
1064	\N	2026-03-06 20:46:41.512425+00	2026-03-06 20:46:41.512425+00	1066	phone	9790286875	personal	f	f	\N	\N	\N
1065	\N	2026-03-06 20:46:41.619584+00	2026-03-06 20:46:41.619584+00	1067	phone	9629000476	personal	f	f	\N	\N	\N
1066	\N	2026-03-06 20:46:41.73087+00	2026-03-06 20:46:41.73087+00	1068	phone	8300040795	personal	f	f	\N	\N	\N
1067	\N	2026-03-06 20:46:41.858081+00	2026-03-06 20:46:41.858081+00	1069	phone	919677281829	personal	f	f	\N	\N	\N
1068	\N	2026-03-06 20:46:41.967365+00	2026-03-06 20:46:41.967365+00	1070	phone	919176822551	personal	f	f	\N	\N	\N
1069	\N	2026-03-06 20:46:42.091491+00	2026-03-06 20:46:42.091491+00	1071	phone	919840640382	personal	f	f	\N	\N	\N
1070	\N	2026-03-06 20:46:42.218821+00	2026-03-06 20:46:42.218821+00	1072	phone	7708130300	personal	f	f	\N	\N	\N
1071	\N	2026-03-06 20:46:42.304321+00	2026-03-06 20:46:42.304321+00	1073	phone	916369876018	personal	f	f	\N	\N	\N
1072	\N	2026-03-06 20:46:42.39556+00	2026-03-06 20:46:42.39556+00	1074	phone	919884967777	personal	f	f	\N	\N	\N
1073	\N	2026-03-06 20:46:42.499057+00	2026-03-06 20:46:42.499057+00	1075	phone	918248029022	personal	f	f	\N	\N	\N
1074	\N	2026-03-06 20:46:42.636663+00	2026-03-06 20:46:42.636663+00	1076	phone	919488045997	personal	f	f	\N	\N	\N
1075	\N	2026-03-06 20:46:42.758436+00	2026-03-06 20:46:42.758436+00	1077	phone	917305357664	personal	f	f	\N	\N	\N
1076	\N	2026-03-06 20:46:42.87526+00	2026-03-06 20:46:42.87526+00	1078	phone	919488423771	personal	f	f	\N	\N	\N
1077	\N	2026-03-06 20:46:42.997361+00	2026-03-06 20:46:42.997361+00	1079	phone	918220041586	personal	f	f	\N	\N	\N
1078	\N	2026-03-06 20:46:43.090835+00	2026-03-06 20:46:43.090835+00	1080	phone	918248575288	personal	f	f	\N	\N	\N
1079	\N	2026-03-06 20:46:43.175533+00	2026-03-06 20:46:43.175533+00	1081	phone	9042483767	personal	f	f	\N	\N	\N
1080	\N	2026-03-06 20:46:43.272505+00	2026-03-06 20:46:43.272505+00	1082	phone	917558146945	personal	f	f	\N	\N	\N
1081	\N	2026-03-06 20:46:43.402006+00	2026-03-06 20:46:43.402006+00	1083	phone	919952260617	personal	f	f	\N	\N	\N
1082	\N	2026-03-06 20:46:43.533511+00	2026-03-06 20:46:43.533511+00	1084	phone	919944485757	personal	f	f	\N	\N	\N
1083	\N	2026-03-06 20:46:43.663564+00	2026-03-06 20:46:43.663564+00	1085	phone	9788939660	personal	f	f	\N	\N	\N
1084	\N	2026-03-06 20:46:43.775789+00	2026-03-06 20:46:43.775789+00	1086	phone	917339084252	personal	f	f	\N	\N	\N
1085	\N	2026-03-06 20:46:43.865321+00	2026-03-06 20:46:43.865321+00	1087	phone	9487943020	personal	f	f	\N	\N	\N
1086	\N	2026-03-06 20:46:43.957436+00	2026-03-06 20:46:43.957436+00	1088	phone	9566812999	personal	f	f	\N	\N	\N
1087	\N	2026-03-06 20:46:44.061299+00	2026-03-06 20:46:44.061299+00	1089	phone	919715029454	personal	f	f	\N	\N	\N
1088	\N	2026-03-06 20:46:44.18154+00	2026-03-06 20:46:44.18154+00	1090	phone	919994939329	personal	f	f	\N	\N	\N
1089	\N	2026-03-06 20:46:44.314843+00	2026-03-06 20:46:44.314843+00	1091	phone	914639220610	personal	f	f	\N	\N	\N
1090	\N	2026-03-06 20:46:44.434229+00	2026-03-06 20:46:44.434229+00	1092	phone	919449857949	personal	f	f	\N	\N	\N
1091	\N	2026-03-06 20:46:44.558768+00	2026-03-06 20:46:44.558768+00	1093	phone	919629147390	personal	f	f	\N	\N	\N
1092	\N	2026-03-06 20:46:44.660874+00	2026-03-06 20:46:44.660874+00	1094	phone	7708770227	personal	f	f	\N	\N	\N
1093	\N	2026-03-06 20:46:44.753253+00	2026-03-06 20:46:44.753253+00	1095	phone	8124165501	personal	f	f	\N	\N	\N
1094	\N	2026-03-06 20:46:44.85364+00	2026-03-06 20:46:44.85364+00	1096	phone	919894381088	personal	f	f	\N	\N	\N
1095	\N	2026-03-06 20:46:45.055875+00	2026-03-06 20:46:45.055875+00	1097	phone	9047403789	personal	f	f	\N	\N	\N
1096	\N	2026-03-06 20:46:45.274779+00	2026-03-06 20:46:45.274779+00	1098	phone	919894928342	personal	f	f	\N	\N	\N
1097	\N	2026-03-06 20:46:45.471813+00	2026-03-06 20:46:45.471813+00	1099	phone	919080973818	personal	f	f	\N	\N	\N
1098	\N	2026-03-06 20:46:45.66181+00	2026-03-06 20:46:45.66181+00	1100	phone	9500433864	personal	f	f	\N	\N	\N
1099	\N	2026-03-06 20:46:45.803516+00	2026-03-06 20:46:45.803516+00	1101	phone	917034716374	personal	f	f	\N	\N	\N
1100	\N	2026-03-06 20:46:45.892094+00	2026-03-06 20:46:45.892094+00	1102	phone	919061887362	personal	f	f	\N	\N	\N
1101	\N	2026-03-06 20:46:46.004781+00	2026-03-06 20:46:46.004781+00	1103	phone	919539107362	personal	f	f	\N	\N	\N
1102	\N	2026-03-06 20:46:46.136603+00	2026-03-06 20:46:46.136603+00	1104	phone	919567084502	personal	f	f	\N	\N	\N
1103	\N	2026-03-06 20:46:46.258687+00	2026-03-06 20:46:46.258687+00	1105	phone	9443178460	personal	f	f	\N	\N	\N
1104	\N	2026-03-06 20:46:46.37895+00	2026-03-06 20:46:46.37895+00	1106	phone	*123*40#	personal	f	f	\N	\N	\N
1105	\N	2026-03-06 20:46:46.47959+00	2026-03-06 20:46:46.47959+00	1107	phone	9443671258	personal	f	f	\N	\N	\N
1106	\N	2026-03-06 20:46:46.568203+00	2026-03-06 20:46:46.568203+00	1108	phone	918778119089	personal	f	f	\N	\N	\N
1107	\N	2026-03-06 20:46:46.659187+00	2026-03-06 20:46:46.659187+00	1109	phone	916379705440	personal	f	f	\N	\N	\N
1108	\N	2026-03-06 20:46:46.781004+00	2026-03-06 20:46:46.781004+00	1110	phone	919787305668	personal	f	f	\N	\N	\N
1109	\N	2026-03-06 20:46:46.912797+00	2026-03-06 20:46:46.912797+00	1111	phone	919688927889	personal	f	f	\N	\N	\N
1110	\N	2026-03-06 20:46:47.030049+00	2026-03-06 20:46:47.030049+00	1112	phone	919500582643	personal	f	f	\N	\N	\N
1111	\N	2026-03-06 20:46:47.153678+00	2026-03-06 20:46:47.153678+00	1113	phone	+91 85890 83656	personal	f	f	\N	\N	\N
1112	\N	2026-03-06 20:46:47.25464+00	2026-03-06 20:46:47.25464+00	1114	phone	+91 98433 22932	personal	f	f	\N	\N	\N
1113	\N	2026-03-06 20:46:47.342692+00	2026-03-06 20:46:47.342692+00	1115	phone	918056272777	personal	f	f	\N	\N	\N
1114	\N	2026-03-06 20:46:47.434885+00	2026-03-06 20:46:47.434885+00	1116	phone	919566921992	personal	f	f	\N	\N	\N
1115	\N	2026-03-06 20:46:47.550544+00	2026-03-06 20:46:47.550544+00	1117	phone	9626113655	personal	f	f	\N	\N	\N
1116	\N	2026-03-06 20:46:47.70308+00	2026-03-06 20:46:47.70308+00	1118	phone	918883790610	personal	f	f	\N	\N	\N
1117	\N	2026-03-06 20:46:47.827891+00	2026-03-06 20:46:47.827891+00	1119	phone	8526211306	personal	f	f	\N	\N	\N
1118	\N	2026-03-06 20:46:47.951121+00	2026-03-06 20:46:47.951121+00	1120	phone	919994439803	personal	f	f	\N	\N	\N
1119	\N	2026-03-06 20:46:48.050347+00	2026-03-06 20:46:48.050347+00	1121	phone	919567976471	personal	f	f	\N	\N	\N
1120	\N	2026-03-06 20:46:48.137621+00	2026-03-06 20:46:48.137621+00	1122	phone	919500466915	personal	f	f	\N	\N	\N
1121	\N	2026-03-06 20:46:48.223138+00	2026-03-06 20:46:48.223138+00	1123	phone	918610006747	personal	f	f	\N	\N	\N
1122	\N	2026-03-06 20:46:48.336893+00	2026-03-06 20:46:48.336893+00	1124	phone	9629575465	personal	f	f	\N	\N	\N
1123	\N	2026-03-06 20:46:48.563887+00	2026-03-06 20:46:48.563887+00	1125	phone	9789392188	personal	f	f	\N	\N	\N
1124	\N	2026-03-06 20:46:48.698736+00	2026-03-06 20:46:48.698736+00	1126	phone	4622333328	personal	f	f	\N	\N	\N
1125	\N	2026-03-06 20:46:48.825472+00	2026-03-06 20:46:48.825472+00	1127	phone	+91 78249 34181	personal	f	f	\N	\N	\N
1126	\N	2026-03-06 20:46:48.934058+00	2026-03-06 20:46:48.934058+00	1128	phone	9486558242	personal	f	f	\N	\N	\N
1127	\N	2026-03-06 20:46:49.02508+00	2026-03-06 20:46:49.02508+00	1129	phone	919500742247	personal	f	f	\N	\N	\N
1128	\N	2026-03-06 20:46:49.131294+00	2026-03-06 20:46:49.131294+00	1130	phone	919524132377	personal	f	f	\N	\N	\N
1129	\N	2026-03-06 20:46:49.252533+00	2026-03-06 20:46:49.252533+00	1131	phone	919566752572	personal	f	f	\N	\N	\N
1130	\N	2026-03-06 20:46:49.375166+00	2026-03-06 20:46:49.375166+00	1132	phone	917305652051	personal	f	f	\N	\N	\N
1131	\N	2026-03-06 20:46:49.498076+00	2026-03-06 20:46:49.498076+00	1133	phone	+91 93612 22399	personal	f	f	\N	\N	\N
1132	\N	2026-03-06 20:46:49.622319+00	2026-03-06 20:46:49.622319+00	1134	phone	914637220250	personal	f	f	\N	\N	\N
1133	\N	2026-03-06 20:46:49.725717+00	2026-03-06 20:46:49.725717+00	1135	phone	918925185200	personal	f	f	\N	\N	\N
1134	\N	2026-03-06 20:46:49.817662+00	2026-03-06 20:46:49.817662+00	1136	phone	919442830676	personal	f	f	\N	\N	\N
1135	\N	2026-03-06 20:46:49.908905+00	2026-03-06 20:46:49.908905+00	1137	phone	919500242761	personal	f	f	\N	\N	\N
1136	\N	2026-03-06 20:46:50.043473+00	2026-03-06 20:46:50.043473+00	1138	phone	918610773162	personal	f	f	\N	\N	\N
1137	\N	2026-03-06 20:46:50.15709+00	2026-03-06 20:46:50.15709+00	1139	phone	919486793312	personal	f	f	\N	\N	\N
1138	\N	2026-03-06 20:46:50.281011+00	2026-03-06 20:46:50.281011+00	1140	phone	7397 670 338	personal	f	f	\N	\N	\N
1139	\N	2026-03-06 20:46:50.450664+00	2026-03-06 20:46:50.450664+00	1141	phone	99658 16091	personal	f	f	\N	\N	\N
1140	\N	2026-03-06 20:46:50.542502+00	2026-03-06 20:46:50.542502+00	1142	phone	7010443001	personal	f	f	\N	\N	\N
1141	\N	2026-03-06 20:46:50.643698+00	2026-03-06 20:46:50.643698+00	1143	phone	919645007871	personal	f	f	\N	\N	\N
1142	\N	2026-03-06 20:46:50.769613+00	2026-03-06 20:46:50.769613+00	1144	phone	+91 80564 03386	personal	f	f	\N	\N	\N
1143	\N	2026-03-06 20:46:50.928624+00	2026-03-06 20:46:50.928624+00	1145	phone	9442769556	personal	f	f	\N	\N	\N
1144	\N	2026-03-06 20:46:51.124458+00	2026-03-06 20:46:51.124458+00	1146	phone	919841311301	personal	f	f	\N	\N	\N
1145	\N	2026-03-06 20:46:51.338795+00	2026-03-06 20:46:51.338795+00	1147	phone	919789516608	personal	f	f	\N	\N	\N
1146	\N	2026-03-06 20:46:51.500979+00	2026-03-06 20:46:51.500979+00	1148	phone	18003001947	personal	f	f	\N	\N	\N
1147	\N	2026-03-06 20:46:51.650489+00	2026-03-06 20:46:51.650489+00	1149	phone	9597080034	personal	f	f	\N	\N	\N
1148	\N	2026-03-06 20:46:51.749574+00	2026-03-06 20:46:51.749574+00	1150	phone	9940478061	personal	f	f	\N	\N	\N
1149	\N	2026-03-06 20:46:51.876952+00	2026-03-06 20:46:51.876952+00	1151	phone	919902383325	personal	f	f	\N	\N	\N
1150	\N	2026-03-06 20:46:51.997096+00	2026-03-06 20:46:51.997096+00	1152	phone	912231229089	personal	f	f	\N	\N	\N
1151	\N	2026-03-06 20:46:52.129849+00	2026-03-06 20:46:52.129849+00	1153	phone	918778262187	personal	f	f	\N	\N	\N
1152	\N	2026-03-06 20:46:52.221511+00	2026-03-06 20:46:52.221511+00	1154	phone	919843085010	personal	f	f	\N	\N	\N
1153	\N	2026-03-06 20:46:52.309495+00	2026-03-06 20:46:52.309495+00	1155	phone	919487869314	personal	f	f	\N	\N	\N
1154	\N	2026-03-06 20:46:52.393532+00	2026-03-06 20:46:52.393532+00	1156	phone	919840978382	personal	f	f	\N	\N	\N
1155	\N	2026-03-06 20:46:52.54579+00	2026-03-06 20:46:52.54579+00	1157	phone	93616 65997	personal	f	f	\N	\N	\N
1156	\N	2026-03-06 20:46:52.671618+00	2026-03-06 20:46:52.671618+00	1158	phone	919025963171	personal	f	f	\N	\N	\N
1157	\N	2026-03-06 20:46:52.795698+00	2026-03-06 20:46:52.795698+00	1159	phone	916385776300	personal	f	f	\N	\N	\N
1158	\N	2026-03-06 20:46:52.925461+00	2026-03-06 20:46:52.925461+00	1160	phone	918668102456	personal	f	f	\N	\N	\N
1159	\N	2026-03-06 20:46:53.023873+00	2026-03-06 20:46:53.023873+00	1161	phone	919443555529	personal	f	f	\N	\N	\N
1160	\N	2026-03-06 20:46:53.116+00	2026-03-06 20:46:53.116+00	1162	phone	919048130041	personal	f	f	\N	\N	\N
1161	\N	2026-03-06 20:46:53.204104+00	2026-03-06 20:46:53.204104+00	1163	phone	918610594130	personal	f	f	\N	\N	\N
1162	\N	2026-03-06 20:46:53.339812+00	2026-03-06 20:46:53.339812+00	1164	phone	9841733377	personal	f	f	\N	\N	\N
1163	\N	2026-03-06 20:46:53.478763+00	2026-03-06 20:46:53.478763+00	1165	phone	+91 89032 78178	personal	f	f	\N	\N	\N
1164	\N	2026-03-06 20:46:53.609801+00	2026-03-06 20:46:53.609801+00	1166	phone	919074753699	personal	f	f	\N	\N	\N
1165	\N	2026-03-06 20:46:53.742613+00	2026-03-06 20:46:53.742613+00	1167	phone	919345281193	personal	f	f	\N	\N	\N
1166	\N	2026-03-06 20:46:53.83766+00	2026-03-06 20:46:53.83766+00	1168	phone	919943190029	personal	f	f	\N	\N	\N
1167	\N	2026-03-06 20:46:53.921293+00	2026-03-06 20:46:53.921293+00	1169	phone	919108107292	personal	f	f	\N	\N	\N
1168	\N	2026-03-06 20:46:54.009068+00	2026-03-06 20:46:54.009068+00	1170	phone	9944089090	personal	f	f	\N	\N	\N
1169	\N	2026-03-06 20:46:54.150406+00	2026-03-06 20:46:54.150406+00	1171	phone	919442066186	personal	f	f	\N	\N	\N
1170	\N	2026-03-06 20:46:54.291622+00	2026-03-06 20:46:54.291622+00	1172	phone	919361601151	personal	f	f	\N	\N	\N
1171	\N	2026-03-06 20:46:54.416217+00	2026-03-06 20:46:54.416217+00	1173	phone	919025633664	personal	f	f	\N	\N	\N
1172	\N	2026-03-06 20:46:54.540172+00	2026-03-06 20:46:54.540172+00	1174	phone	919095240778	personal	f	f	\N	\N	\N
1173	\N	2026-03-06 20:46:54.638334+00	2026-03-06 20:46:54.638334+00	1175	phone	916381008776	personal	f	f	\N	\N	\N
1174	\N	2026-03-06 20:46:54.728597+00	2026-03-06 20:46:54.728597+00	1176	phone	918939450449	personal	f	f	\N	\N	\N
1175	\N	2026-03-06 20:46:54.821857+00	2026-03-06 20:46:54.821857+00	1177	phone	919384218533	personal	f	f	\N	\N	\N
1176	\N	2026-03-06 20:46:54.941535+00	2026-03-06 20:46:54.941535+00	1178	phone	918754454413	personal	f	f	\N	\N	\N
1177	\N	2026-03-06 20:46:55.084411+00	2026-03-06 20:46:55.084411+00	1179	phone	8056622401	personal	f	f	\N	\N	\N
1178	\N	2026-03-06 20:46:55.213832+00	2026-03-06 20:46:55.213832+00	1180	phone	917094761000	personal	f	f	\N	\N	\N
1179	\N	2026-03-06 20:46:55.329+00	2026-03-06 20:46:55.329+00	1181	phone	7708566979	personal	f	f	\N	\N	\N
1180	\N	2026-03-06 20:46:55.423586+00	2026-03-06 20:46:55.423586+00	1182	phone	918883045959	personal	f	f	\N	\N	\N
\.


--
-- Data for Name: person_relationships; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.person_relationships (relationship_id, created_by, idate, last_updated, person_id, related_person_id, relation_type, notes, row_exposure_mode_id) FROM stdin;
\.


--
-- Data for Name: personal_access_tokens; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.personal_access_tokens (pat_id, pat_uuid, user_id, company_id, name, token_hash, scopes_json, expires_at, last_used_at, created_at) FROM stdin;
1	b3a25496-7a71-4f32-af85-2cb960c58df4	2	\N	thinker-app	be03bbd66e3ad16ca0a8bde5374174e290c76b273c05fff9439478e70fccd985	[]	2026-05-08 23:49:01.705124+00	2026-03-07 18:11:34.947933+00	2026-02-08 05:19:01.882554+00
\.


--
-- Data for Name: persons; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.persons (person_id, created_by, idate, last_updated, name, alias_names, profile_photo, dob, marital_status, anniversary_date, notes, person_uuid, row_exposure_mode_id) FROM stdin;
593	\N	2026-03-06 20:45:44.179452+00	2026-03-06 20:45:44.179452+00	120 pstoffice	\N	\N	\N	\N	\N	\N	0af167b8-cc67-47a3-a5a2-ec88a462465a	\N
594	\N	2026-03-06 20:45:44.339736+00	2026-03-06 20:45:44.339736+00	140 pstoffice	\N	\N	\N	\N	\N	\N	d52c534d-a3ab-4b55-bf80-7397729171ee	\N
595	\N	2026-03-06 20:45:44.456335+00	2026-03-06 20:45:44.456335+00	195 pstoffice	\N	\N	\N	\N	\N	\N	e40af64d-ca5e-4948-ac00-9a327599f215	\N
596	\N	2026-03-06 20:45:44.543125+00	2026-03-06 20:45:44.543125+00	24 star 2 pstclient	\N	\N	\N	\N	\N	\N	9481a233-8981-4131-a4a3-a503b41b3478	\N
597	\N	2026-03-06 20:45:44.641191+00	2026-03-06 20:45:44.641191+00	7days Bakery mymoclient	\N	\N	\N	\N	\N	\N	6210c1fe-2c16-4139-8ddb-3f59e3f34965	\N
598	\N	2026-03-06 20:45:44.77511+00	2026-03-06 20:45:44.77511+00	a1 computer 2	\N	\N	\N	\N	\N	\N	626dc495-9275-4a43-b4be-85205d0d5b2e	\N
599	\N	2026-03-06 20:45:44.89284+00	2026-03-06 20:45:44.89284+00	a1  computers	\N	\N	\N	\N	\N	\N	e71e2974-3b1a-4f6c-b137-6c5459a586b2	\N
600	\N	2026-03-06 20:45:45.022456+00	2026-03-06 20:45:45.022456+00	AAA College meet	\N	\N	\N	\N	\N	\N	342b5703-9d7a-4de3-bb5b-7c3fd6110b75	\N
601	\N	2026-03-06 20:45:45.144043+00	2026-03-06 20:45:45.144043+00	Aadhar  akshaya	\N	\N	\N	\N	\N	\N	88416a6c-2142-4c96-b954-5e3726e9bc86	\N
602	\N	2026-03-06 20:45:45.241181+00	2026-03-06 20:45:45.241181+00	abdul Grafin Laser asan	\N	\N	\N	\N	\N	\N	8ec5f4e4-3c2d-4f8a-8b21-67baa485c3c7	\N
603	\N	2026-03-06 20:45:45.338244+00	2026-03-06 20:45:45.338244+00	abdulrahman  asan	\N	\N	\N	\N	\N	\N	2b8ea837-6de9-4d14-bbed-0c83158eec8d	\N
604	\N	2026-03-06 20:45:45.566831+00	2026-03-06 20:45:45.566831+00	abul hasan real estate 1	\N	\N	\N	\N	\N	\N	59877782-5e19-4926-9d7b-34b9716d4172	\N
605	\N	2026-03-06 20:45:45.692005+00	2026-03-06 20:45:45.692005+00	abul hasan real estate 2	\N	\N	\N	\N	\N	\N	642c14e0-29b2-4549-852f-8ce545b90fbe	\N
606	\N	2026-03-06 20:45:45.890611+00	2026-03-06 20:45:45.890611+00	Account  Info	\N	\N	\N	\N	\N	\N	cac4a5a3-dc9a-4074-8cc5-13004c075269	\N
607	\N	2026-03-06 20:45:46.070375+00	2026-03-06 20:45:46.070375+00	Afrin pstoffice	\N	\N	\N	\N	\N	\N	9a5118d2-132b-4d47-ad10-a0062968cab6	\N
1	\N	2026-02-21 21:00:23.43858+00	2026-02-21 21:00:23.43858+00	Vijayakaran	karan,vijay,muraly	private/model-attachments/persons/4070b2d2402641ebb309ff64bcfef25c.jpg	1985-10-27	Married	2017-11-27	\N	3a734566-e01c-4bb2-9a48-45739a473a02	\N
2	\N	2026-03-01 10:28:07.390158+00	2026-03-01 10:28:07.390158+00	Iswaya	\N	\N	1990-02-20	Married	2017-10-27	\N	7c99387a-f8f2-4d4a-9fb1-e57dc6e09eed	\N
608	\N	2026-03-06 20:45:46.212271+00	2026-03-06 20:45:46.212271+00	Aik 2 mymoclient	\N	\N	\N	\N	\N	\N	db17315e-15ac-4f62-a60c-8439c2070043	\N
609	\N	2026-03-06 20:45:46.37764+00	2026-03-06 20:45:46.37764+00	aik rubbani 2 mymoclient	\N	\N	\N	\N	\N	\N	aea44f1b-e89a-41c8-a524-767acd8a08d5	\N
610	\N	2026-03-06 20:45:46.592385+00	2026-03-06 20:45:46.592385+00	Aik Rubbani mymoclient	\N	\N	\N	\N	\N	\N	7bd4155e-3f51-43eb-aa46-90b6276f6316	\N
611	\N	2026-03-06 20:45:46.716933+00	2026-03-06 20:45:46.716933+00	airtel modem psclient	\N	\N	\N	\N	\N	\N	b48859c3-92df-4404-8892-fd61e7ba702b	\N
612	\N	2026-03-06 20:45:46.834825+00	2026-03-06 20:45:46.834825+00	Ajin g2g	\N	\N	\N	\N	\N	\N	ec6902c3-2c7a-4e1d-afb6-4e74713e0fd2	\N
613	\N	2026-03-06 20:45:46.922166+00	2026-03-06 20:45:46.922166+00	akbar pstoffice	\N	\N	\N	\N	\N	\N	31a05020-ca86-4ae2-8986-68f798a7fdb2	\N
614	\N	2026-03-06 20:45:47.005168+00	2026-03-06 20:45:47.005168+00	alagu spc pstclient	\N	\N	\N	\N	\N	\N	7dcb3cfc-65a6-4ac9-84fb-9a6b6ca994a6	\N
615	\N	2026-03-06 20:45:47.104522+00	2026-03-06 20:45:47.104522+00	Alagukumar anjac pstclient	\N	\N	\N	\N	\N	\N	d21f3e4a-8dc0-4964-bfdf-2a36f4baca19	\N
616	\N	2026-03-06 20:45:47.232706+00	2026-03-06 20:45:47.232706+00	Alex	\N	\N	\N	\N	\N	\N	c65fb701-20ba-45b3-83e5-d23a74852fcc	\N
617	\N	2026-03-06 20:45:47.362242+00	2026-03-06 20:45:47.362242+00	alwyn faster	\N	\N	\N	\N	\N	\N	dee0892a-45cf-4c56-8a94-bdf51c3ac499	\N
618	\N	2026-03-06 20:45:47.472744+00	2026-03-06 20:45:47.472744+00	amalan	\N	\N	\N	\N	\N	\N	57e40df7-77dd-405c-9849-c3895de16966	\N
619	\N	2026-03-06 20:45:47.588449+00	2026-03-06 20:45:47.588449+00	Ambika Jesus ð¥°ð	\N	\N	\N	\N	\N	\N	29740921-2163-4175-a750-b030bd84d518	\N
620	\N	2026-03-06 20:45:47.682347+00	2026-03-06 20:45:47.682347+00	Ambulance	\N	\N	\N	\N	\N	\N	ec607198-3ddc-4df4-9c79-ce5988306ed9	\N
621	\N	2026-03-06 20:45:47.771648+00	2026-03-06 20:45:47.771648+00	amma	\N	\N	\N	\N	\N	\N	34b032bf-41a8-4975-8f03-46375d68b7f5	\N
622	\N	2026-03-06 20:45:47.874801+00	2026-03-06 20:45:47.874801+00	Android  sir	\N	\N	\N	\N	\N	\N	d5a79d6d-c919-4142-911d-283ad65bf99e	\N
623	\N	2026-03-06 20:45:47.991545+00	2026-03-06 20:45:47.991545+00	Anitha  Explore	\N	\N	\N	\N	\N	\N	8dd49c2e-0775-4a04-9525-71e3084b7d43	\N
624	\N	2026-03-06 20:45:48.114884+00	2026-03-06 20:45:48.114884+00	anjac alaguraj sir	\N	\N	\N	\N	\N	\N	78871df1-ec99-4c32-bb61-61d2c182aa53	\N
625	\N	2026-03-06 20:45:48.240691+00	2026-03-06 20:45:48.240691+00	anjac velmurugan sir	\N	\N	\N	\N	\N	\N	685e9034-b707-4481-959e-ad52a07ed56c	\N
626	\N	2026-03-06 20:45:48.359823+00	2026-03-06 20:45:48.359823+00	antony stc pstclient	\N	\N	\N	\N	\N	\N	2bc5709a-ee8b-4b0e-9abf-fe45d53c10c8	\N
627	\N	2026-03-06 20:45:48.450251+00	2026-03-06 20:45:48.450251+00	ao christopher isrel	\N	\N	\N	\N	\N	\N	d72255ee-afde-4013-b29f-949c23a1df54	\N
628	\N	2026-03-06 20:45:48.540471+00	2026-03-06 20:45:48.540471+00	ao lakshmi soel	\N	\N	\N	\N	\N	\N	d2f9429a-7ffb-4a2e-84d9-8fef5d61af7d	\N
629	\N	2026-03-06 20:45:48.645541+00	2026-03-06 20:45:48.645541+00	apex  ravi	\N	\N	\N	\N	\N	\N	579e6c3b-bdd5-4d57-aaa8-dfe246f4a2c1	\N
630	\N	2026-03-06 20:45:48.771588+00	2026-03-06 20:45:48.771588+00	ar valliammai soel	\N	\N	\N	\N	\N	\N	e8ea6f42-4071-4c01-bb1e-19e78d29fdd9	\N
631	\N	2026-03-06 20:45:48.885143+00	2026-03-06 20:45:48.885143+00	Aravind	\N	\N	\N	\N	\N	\N	66047de2-8c11-4c19-a8c8-fc5831f7548a	\N
632	\N	2026-03-06 20:45:49.015809+00	2026-03-06 20:45:49.015809+00	Aravind  2	\N	\N	\N	\N	\N	\N	55060636-7e1f-4245-a768-a8430edfaa7f	\N
633	\N	2026-03-06 20:45:49.134075+00	2026-03-06 20:45:49.134075+00	Aravind  ker	\N	\N	\N	\N	\N	\N	f12e8ebb-9d18-49f7-bfd7-bfcb225cd76d	\N
634	\N	2026-03-06 20:45:49.226303+00	2026-03-06 20:45:49.226303+00	araye kerala	\N	\N	\N	\N	\N	\N	a7053c9b-0f01-49e8-a653-9dfc88098462	\N
635	\N	2026-03-06 20:45:49.324039+00	2026-03-06 20:45:49.324039+00	arul  soel	\N	\N	\N	\N	\N	\N	8f4d499c-d641-4539-9ee1-4b5e7b5b54a0	\N
636	\N	2026-03-06 20:45:49.445513+00	2026-03-06 20:45:49.445513+00	Arumugam  thatc	\N	\N	\N	\N	\N	\N	5b62f38e-3150-4b23-bde9-9ef5cd74c27a	\N
637	\N	2026-03-06 20:45:49.572688+00	2026-03-06 20:45:49.572688+00	Arumugam  ulavar	\N	\N	\N	\N	\N	\N	2de1021c-2a47-4d22-b691-9d0adf61d438	\N
638	\N	2026-03-06 20:45:49.689963+00	2026-03-06 20:45:49.689963+00	Arun	\N	\N	\N	\N	\N	\N	c245872c-11ab-4fd8-b0f9-a9d99328b113	\N
639	\N	2026-03-06 20:45:49.822567+00	2026-03-06 20:45:49.822567+00	arun city union bank ccavenu	\N	\N	\N	\N	\N	\N	60228652-b876-47e2-bbc3-6d3eb37cb0ad	\N
640	\N	2026-03-06 20:45:49.929328+00	2026-03-06 20:45:49.929328+00	Arun CUB Chennai Ccsr	\N	\N	\N	\N	\N	\N	4d0a7133-5d9a-4a27-80b4-8a6502ff61f2	\N
641	\N	2026-03-06 20:45:50.015164+00	2026-03-06 20:45:50.015164+00	arun ragland kvlpt	\N	\N	\N	\N	\N	\N	d82660ea-adc1-4b59-b8ab-d256509cf008	\N
642	\N	2026-03-06 20:45:50.103463+00	2026-03-06 20:45:50.103463+00	Asan  2	\N	\N	\N	\N	\N	\N	0128ad0d-a305-49a5-91b2-e1f30a1f2652	\N
643	\N	2026-03-06 20:45:50.21758+00	2026-03-06 20:45:50.21758+00	asan  3	\N	\N	\N	\N	\N	\N	4ea65808-8127-4132-9024-8270191b4ebf	\N
644	\N	2026-03-06 20:45:50.353068+00	2026-03-06 20:45:50.353068+00	Asan  buddy	\N	\N	\N	\N	\N	\N	1bc23652-2c3b-4817-b188-44088b3247fc	\N
645	\N	2026-03-06 20:45:50.480092+00	2026-03-06 20:45:50.480092+00	Asan  kdnl	\N	\N	\N	\N	\N	\N	74b837c0-e31c-4c83-a390-aee2073fec6e	\N
646	\N	2026-03-06 20:45:50.604442+00	2026-03-06 20:45:50.604442+00	Asan  Mobicare	\N	\N	\N	\N	\N	\N	3c78a651-8271-489b-9fb9-520e6b4a9212	\N
647	\N	2026-03-06 20:45:50.708158+00	2026-03-06 20:45:50.708158+00	Asok	\N	\N	\N	\N	\N	\N	384a11af-9d8b-4a5b-9282-6cbb20265582	\N
648	\N	2026-03-06 20:45:50.796327+00	2026-03-06 20:45:50.796327+00	Astrology	\N	\N	\N	\N	\N	\N	325a1ca6-1c63-498d-a92e-dd76beac3fa7	\N
649	\N	2026-03-06 20:45:50.895093+00	2026-03-06 20:45:50.895093+00	Aswald Thomas shibani	\N	\N	\N	\N	\N	\N	214cd27d-9739-462e-9ab5-2661ef9d6b46	\N
650	\N	2026-03-06 20:45:51.019808+00	2026-03-06 20:45:51.019808+00	Aswin  Raj	\N	\N	\N	\N	\N	\N	99361a69-e2ef-4625-afe6-47342e83325f	\N
651	\N	2026-03-06 20:45:51.145725+00	2026-03-06 20:45:51.145725+00	Athavan  Printer	\N	\N	\N	\N	\N	\N	cdf2b4a0-4078-4796-abae-b1823e7e5da7	\N
652	\N	2026-03-06 20:45:51.267542+00	2026-03-06 20:45:51.267542+00	Audit  robin	\N	\N	\N	\N	\N	\N	10686bd6-0c8f-4450-b858-f4752a602b4f	\N
653	\N	2026-03-06 20:45:51.381097+00	2026-03-06 20:45:51.381097+00	Auto  chelakuti	\N	\N	\N	\N	\N	\N	f78c6fea-5e05-4061-a5ad-b5c24ea62f97	\N
654	\N	2026-03-06 20:45:51.47347+00	2026-03-06 20:45:51.47347+00	Auto  Kalimuthu	\N	\N	\N	\N	\N	\N	e1d1f0a1-12df-4c85-952c-934839e6442f	\N
655	\N	2026-03-06 20:45:51.585075+00	2026-03-06 20:45:51.585075+00	Auto  santhosh	\N	\N	\N	\N	\N	\N	f26530f1-5c33-446f-9586-6c012a8f8c98	\N
656	\N	2026-03-06 20:45:51.763467+00	2026-03-06 20:45:51.763467+00	Azam  jio	\N	\N	\N	\N	\N	\N	6b8bac94-e20d-49ae-8796-402941bfce4b	\N
657	\N	2026-03-06 20:45:51.976184+00	2026-03-06 20:45:51.976184+00	azam  new	\N	\N	\N	\N	\N	\N	6737d0fa-ddd6-4b7a-8405-2865b42061e0	\N
658	\N	2026-03-06 20:45:52.126046+00	2026-03-06 20:45:52.126046+00	Azam  Sir	\N	\N	\N	\N	\N	\N	aeb133f6-8480-4e3b-85e7-0679b5ccad99	\N
659	\N	2026-03-06 20:45:52.313656+00	2026-03-06 20:45:52.313656+00	Azam son mudassir	\N	\N	\N	\N	\N	\N	782385c2-1630-4872-b954-9ffa5aab7aa7	\N
660	\N	2026-03-06 20:45:52.514807+00	2026-03-06 20:45:52.514807+00	Babu Ageency 2	\N	\N	\N	\N	\N	\N	42e9b8be-59d0-42e7-ab05-910894263147	\N
661	\N	2026-03-06 20:45:52.605509+00	2026-03-06 20:45:52.605509+00	Babu  Agencies	\N	\N	\N	\N	\N	\N	24c88c33-a4c4-4eef-97a8-5d78b8290da3	\N
662	\N	2026-03-06 20:45:52.701854+00	2026-03-06 20:45:52.701854+00	bala  2f	\N	\N	\N	\N	\N	\N	ae42295d-931d-4020-8c6d-e4c794c224b3	\N
663	\N	2026-03-06 20:45:52.840183+00	2026-03-06 20:45:52.840183+00	bala  chennai	\N	\N	\N	\N	\N	\N	b7e7689c-6e3d-49aa-8ba4-7c7ddfc40ad1	\N
664	\N	2026-03-06 20:45:52.954531+00	2026-03-06 20:45:52.954531+00	bala data incharge st xavier	\N	\N	\N	\N	\N	\N	51f99feb-9f3e-49ba-9415-b04befe5fa81	\N
665	\N	2026-03-06 20:45:53.079714+00	2026-03-06 20:45:53.079714+00	bala  st xaviers	\N	\N	\N	\N	\N	\N	fdb9e98f-630c-4ed1-aeae-09594fa3076c	\N
666	\N	2026-03-06 20:45:53.187856+00	2026-03-06 20:45:53.187856+00	Balachandran  TDMNS	\N	\N	\N	\N	\N	\N	e8918613-1023-499e-9335-4d925927daca	\N
667	\N	2026-03-06 20:45:53.279497+00	2026-03-06 20:45:53.279497+00	balagan  saraswathi	\N	\N	\N	\N	\N	\N	36f3b673-d77b-4d44-a92d-51b6e6efd37e	\N
668	\N	2026-03-06 20:45:53.366982+00	2026-03-06 20:45:53.366982+00	Balaji  Finance	\N	\N	\N	\N	\N	\N	db61ec30-76a7-4f4d-b842-f91819e0613d	\N
669	\N	2026-03-06 20:45:53.494322+00	2026-03-06 20:45:53.494322+00	balaji kamaraj clg	\N	\N	\N	\N	\N	\N	3167b060-1835-456b-be0e-1b4d193fb1c4	\N
670	\N	2026-03-06 20:45:53.642119+00	2026-03-06 20:45:53.642119+00	Balakumar.G dial 4 college	\N	\N	\N	\N	\N	\N	40356143-4270-4c6d-b96f-41dac3937cde	\N
671	\N	2026-03-06 20:45:53.773803+00	2026-03-06 20:45:53.773803+00	Balance  Info	\N	\N	\N	\N	\N	\N	c4aa3b8d-fc2a-44ac-9aff-2e5fa26417a5	\N
672	\N	2026-03-06 20:45:53.88247+00	2026-03-06 20:45:53.88247+00	Balasubramaniam soel prof	\N	\N	\N	\N	\N	\N	8b6ca054-7584-4b9a-9b2a-3f3b0696ebc2	\N
673	\N	2026-03-06 20:45:53.97008+00	2026-03-06 20:45:53.97008+00	Banu Mam Kamaraj Coe	\N	\N	\N	\N	\N	\N	50d0cd8d-5358-472f-b885-c52f0b5b9e08	\N
674	\N	2026-03-06 20:45:54.058713+00	2026-03-06 20:45:54.058713+00	Baskar apex	\N	\N	\N	\N	\N	\N	16bbfae9-81d9-4767-b7d1-ffcfa0e285cb	\N
675	\N	2026-03-06 20:45:54.174045+00	2026-03-06 20:45:54.174045+00	baskar apex  sir	\N	\N	\N	\N	\N	\N	8b0e9e09-95e5-449f-8395-46d5d1895999	\N
676	\N	2026-03-06 20:45:54.303094+00	2026-03-06 20:45:54.303094+00	Beny	\N	\N	\N	\N	\N	\N	d93be61f-1f80-477d-816d-0eda5d645c69	\N
677	\N	2026-03-06 20:45:54.430549+00	2026-03-06 20:45:54.430549+00	Best  Deals	\N	\N	\N	\N	\N	\N	44a04ab1-1f55-4c52-9e38-b693010504a8	\N
678	\N	2026-03-06 20:45:54.557964+00	2026-03-06 20:45:54.557964+00	Bharathi  chenna	\N	\N	\N	\N	\N	\N	a5ee88cd-8383-4e1f-ae2c-c5c2382def0c	\N
679	\N	2026-03-06 20:45:54.664851+00	2026-03-06 20:45:54.664851+00	Bharathi  Raja	\N	\N	\N	\N	\N	\N	12df2f5c-7a29-4743-8e69-68fa87bd2746	\N
680	\N	2026-03-06 20:45:54.752607+00	2026-03-06 20:45:54.752607+00	Bio sir xavier coe psclient	\N	\N	\N	\N	\N	\N	50f5a5f3-1103-451c-9e0e-fdcbd6c0b169	\N
681	\N	2026-03-06 20:45:54.842573+00	2026-03-06 20:45:54.842573+00	birahatha spc pstclient	\N	\N	\N	\N	\N	\N	9a18adf7-3233-4361-93d5-624396d95637	\N
682	\N	2026-03-06 20:45:54.967223+00	2026-03-06 20:45:54.967223+00	Blog	\N	\N	\N	\N	\N	\N	76d77a56-e8a0-441e-99bc-58965a341d7b	\N
683	\N	2026-03-06 20:45:55.093442+00	2026-03-06 20:45:55.093442+00	Bonus  Cards	\N	\N	\N	\N	\N	\N	b069d12d-9d4e-4d59-bb95-7d87672eef16	\N
684	\N	2026-03-06 20:45:55.222003+00	2026-03-06 20:45:55.222003+00	Boss  lbs	\N	\N	\N	\N	\N	\N	4e926d99-ec45-45c3-9fc7-3dc089b5189a	\N
685	\N	2026-03-06 20:45:55.359315+00	2026-03-06 20:45:55.359315+00	Boss  Mariappan	\N	\N	\N	\N	\N	\N	9cf46ea8-8c0e-4214-ba69-72a65c2e947f	\N
686	\N	2026-03-06 20:45:55.456536+00	2026-03-06 20:45:55.456536+00	Britto Mr. Maram DB north	\N	\N	\N	\N	\N	\N	c096f372-9ce3-4cdb-ba37-60f8ac7bdf24	\N
687	\N	2026-03-06 20:45:55.542581+00	2026-03-06 20:45:55.542581+00	Bulk  Sms	\N	\N	\N	\N	\N	\N	531a83e2-e19d-46bb-8547-1a61241d2c03	\N
688	\N	2026-03-06 20:45:55.629721+00	2026-03-06 20:45:55.629721+00	Bulk Sms. kavith	\N	\N	\N	\N	\N	\N	4dad52de-dbe3-4079-874d-9e07d21f5f17	\N
689	\N	2026-03-06 20:45:55.768827+00	2026-03-06 20:45:55.768827+00	Busy  Tunes	\N	\N	\N	\N	\N	\N	694d3af6-58da-4cbd-b9eb-cb024c3d02e4	\N
690	\N	2026-03-06 20:45:55.889657+00	2026-03-06 20:45:55.889657+00	Callertunes	\N	\N	\N	\N	\N	\N	18c3c322-d9da-42a5-9d2f-4f651952795e	\N
691	\N	2026-03-06 20:45:56.018488+00	2026-03-06 20:45:56.018488+00	Cand  new	\N	\N	\N	\N	\N	\N	0fbf66ef-85a6-4aae-8a43-b721936a49d3	\N
692	\N	2026-03-06 20:45:56.142729+00	2026-03-06 20:45:56.142729+00	Carpender  azam	\N	\N	\N	\N	\N	\N	f05829c2-be81-4145-9e63-29dd544373b1	\N
693	\N	2026-03-06 20:45:56.2395+00	2026-03-06 20:45:56.2395+00	Catch a Song	\N	\N	\N	\N	\N	\N	45d4309c-da99-4ccc-81df-de42d00d1f3f	\N
694	\N	2026-03-06 20:45:56.327336+00	2026-03-06 20:45:56.327336+00	CCF  Prabhu	\N	\N	\N	\N	\N	\N	1339bce7-2949-433d-9c78-5317af81e399	\N
695	\N	2026-03-06 20:45:56.416368+00	2026-03-06 20:45:56.416368+00	Chandan	\N	\N	\N	\N	\N	\N	2d3efee2-182a-415d-99e7-7e11c3798319	\N
696	\N	2026-03-06 20:45:56.542881+00	2026-03-06 20:45:56.542881+00	Chandrakanth	\N	\N	\N	\N	\N	\N	5dca23e7-f1da-4334-ab22-49d09774aa10	\N
697	\N	2026-03-06 20:45:56.686743+00	2026-03-06 20:45:56.686743+00	chandrakanth  kovai	\N	\N	\N	\N	\N	\N	5c04c706-4c90-4161-a2b4-403edfdfe78f	\N
698	\N	2026-03-06 20:45:56.811376+00	2026-03-06 20:45:56.811376+00	Chellasamy  audi	\N	\N	\N	\N	\N	\N	7fa55990-967b-4a02-aca0-0acec29fbe80	\N
699	\N	2026-03-06 20:45:56.932346+00	2026-03-06 20:45:56.932346+00	Chenda Melam Ja	\N	\N	\N	\N	\N	\N	db953f95-4402-4a76-b23a-14629a9d4327	\N
700	\N	2026-03-06 20:45:57.021976+00	2026-03-06 20:45:57.021976+00	chinnu soel time table	\N	\N	\N	\N	\N	\N	ecf8e901-9349-460d-85a3-6506d354d87f	\N
701	\N	2026-03-06 20:45:57.112174+00	2026-03-06 20:45:57.112174+00	chitra kcollege pstclient	\N	\N	\N	\N	\N	\N	18ba350a-2532-47b5-8f57-105df589f806	\N
702	\N	2026-03-06 20:45:57.212675+00	2026-03-06 20:45:57.212675+00	christopher  jenit	\N	\N	\N	\N	\N	\N	d6427046-d397-42f8-a83f-3f09114b8d95	\N
703	\N	2026-03-06 20:45:57.327694+00	2026-03-06 20:45:57.327694+00	christopher meenakshi english	\N	\N	\N	\N	\N	\N	baac043d-21d8-4cd9-840b-f433914729e6	\N
704	\N	2026-03-06 20:45:57.45865+00	2026-03-06 20:45:57.45865+00	christopher vise principle	\N	\N	\N	\N	\N	\N	735df020-9a44-43e3-bceb-3192f33b8b57	\N
705	\N	2026-03-06 20:45:57.609917+00	2026-03-06 20:45:57.609917+00	churchmatrimony  mam	\N	\N	\N	\N	\N	\N	fd300d00-c3b1-420e-8957-65a083ad1e12	\N
706	\N	2026-03-06 20:45:57.839747+00	2026-03-06 20:45:57.839747+00	coe spc pstclient	\N	\N	\N	\N	\N	\N	451f494b-6a48-4ec8-b566-65814f026187	\N
707	\N	2026-03-06 20:45:57.984827+00	2026-03-06 20:45:57.984827+00	Competition	\N	\N	\N	\N	\N	\N	cb688b88-c762-40a6-bb71-b900360a9676	\N
708	\N	2026-03-06 20:45:58.140193+00	2026-03-06 20:45:58.140193+00	Complaints	\N	\N	\N	\N	\N	\N	ebd6bd26-b838-4040-b415-818ba441deba	\N
709	\N	2026-03-06 20:45:58.339781+00	2026-03-06 20:45:58.339781+00	Cricket	\N	\N	\N	\N	\N	\N	2c1bad9e-13a7-4204-a9ec-41f130a732b3	\N
710	\N	2026-03-06 20:45:58.547407+00	2026-03-06 20:45:58.547407+00	Csi  Eben	\N	\N	\N	\N	\N	\N	b782c632-7bb1-41ef-9d75-f1a226ce2b01	\N
711	\N	2026-03-06 20:45:58.684585+00	2026-03-06 20:45:58.684585+00	Ctk	\N	\N	\N	\N	\N	\N	54873d8a-4241-4411-a68a-5a8d53a64f91	\N
712	\N	2026-03-06 20:45:58.781988+00	2026-03-06 20:45:58.781988+00	Ctk  2	\N	\N	\N	\N	\N	\N	3307f5d7-eeff-4253-a641-0067c69d1f56	\N
713	\N	2026-03-06 20:45:58.869902+00	2026-03-06 20:45:58.869902+00	cur house owner udp	\N	\N	\N	\N	\N	\N	7db1edd2-491c-4351-a12b-84471c0ad889	\N
714	\N	2026-03-06 20:45:58.963444+00	2026-03-06 20:45:58.963444+00	daniel  sir	\N	\N	\N	\N	\N	\N	58787721-c43a-479a-b2fe-4e866a9d9544	\N
715	\N	2026-03-06 20:45:59.08593+00	2026-03-06 20:45:59.08593+00	dean dr. ambedkar	\N	\N	\N	\N	\N	\N	63878745-f662-4b62-b348-b92ce1ed5e69	\N
716	\N	2026-03-06 20:45:59.210011+00	2026-03-06 20:45:59.210011+00	Deivendran	\N	\N	\N	\N	\N	\N	261fe42a-1b99-494e-99a6-591f4f7b76d7	\N
717	\N	2026-03-06 20:45:59.33877+00	2026-03-06 20:45:59.33877+00	Deva Ech New	\N	\N	\N	\N	\N	\N	1c938b61-f77f-43dd-9476-43f51528c23a	\N
718	\N	2026-03-06 20:45:59.470594+00	2026-03-06 20:45:59.470594+00	devi  mdu	\N	\N	\N	\N	\N	\N	ea88079f-268a-40f9-9459-9a2be4ff332a	\N
719	\N	2026-03-06 20:45:59.562188+00	2026-03-06 20:45:59.562188+00	Dhameem  Fathusa	\N	\N	\N	\N	\N	\N	eedd3615-88e0-4c4a-baa2-f00fb59cbcd1	\N
720	\N	2026-03-06 20:45:59.657365+00	2026-03-06 20:45:59.657365+00	dhanalakshmi AAA college sivakasi	\N	\N	\N	\N	\N	\N	8003fc7d-78e2-4da0-b88e-bf39bd95b167	\N
721	\N	2026-03-06 20:45:59.750733+00	2026-03-06 20:45:59.750733+00	Distress  Number	\N	\N	\N	\N	\N	\N	01ba76f6-99d4-4810-9b27-664ddb5d5ac8	\N
722	\N	2026-03-06 20:45:59.873608+00	2026-03-06 20:45:59.873608+00	divya rac rac library	\N	\N	\N	\N	\N	\N	d63de13a-3bb0-44c7-9edb-ba46fbc5c4f3	\N
723	\N	2026-03-06 20:45:59.999686+00	2026-03-06 20:45:59.999686+00	dmns  nellai	\N	\N	\N	\N	\N	\N	0cf99021-ac9f-41a4-b63e-983bfe2dfe49	\N
724	\N	2026-03-06 20:46:00.132126+00	2026-03-06 20:46:00.132126+00	dr Rajasekaran jain psclient	\N	\N	\N	\N	\N	\N	f9f89afa-a82b-4dc7-b382-84fcba40fc04	\N
725	\N	2026-03-06 20:46:00.246406+00	2026-03-06 20:46:00.246406+00	Dr Uma Baskar Principal Mam Mcw	\N	\N	\N	\N	\N	\N	b65df6c3-fd04-4fe1-9c72-6dbaecf4ea30	\N
726	\N	2026-03-06 20:46:00.332251+00	2026-03-06 20:46:00.332251+00	dr. jegatheesan jain psclient	\N	\N	\N	\N	\N	\N	6ca7d4a9-b589-4de0-9f84-779e3ff1b0ee	\N
727	\N	2026-03-06 20:46:00.429304+00	2026-03-06 20:46:00.429304+00	Dra  Habidulla	\N	\N	\N	\N	\N	\N	c06aab40-8db2-4dbb-a9ae-05864706b5d2	\N
728	\N	2026-03-06 20:46:00.554487+00	2026-03-06 20:46:00.554487+00	dry fruit shop	\N	\N	\N	\N	\N	\N	02c0b159-c8fb-434a-9424-c1e1950f8b02	\N
729	\N	2026-03-06 20:46:00.671988+00	2026-03-06 20:46:00.671988+00	Duraisingh	\N	\N	\N	\N	\N	\N	56525a0b-7c62-406e-84dd-a50d5a8d79e4	\N
730	\N	2026-03-06 20:46:00.795774+00	2026-03-06 20:46:00.795774+00	Eben	\N	\N	\N	\N	\N	\N	fc95acb2-8427-43c2-acb7-47b35e1f8156	\N
731	\N	2026-03-06 20:46:00.926027+00	2026-03-06 20:46:00.926027+00	edwin pstoffice	\N	\N	\N	\N	\N	\N	d2800283-df02-49cf-bb79-6259068a1a31	\N
732	\N	2026-03-06 20:46:01.032238+00	2026-03-06 20:46:01.032238+00	elavarasan  helixsense	\N	\N	\N	\N	\N	\N	5c7962b2-f659-4bfc-8577-2718b3f2dfd8	\N
733	\N	2026-03-06 20:46:01.114675+00	2026-03-06 20:46:01.114675+00	Entertainment	\N	\N	\N	\N	\N	\N	e4cff239-f229-427b-94d7-b8769ea38944	\N
734	\N	2026-03-06 20:46:01.199604+00	2026-03-06 20:46:01.199604+00	Er. JD darwin soel	\N	\N	\N	\N	\N	\N	7641421f-7763-4643-98b4-7fb0e7a2d720	\N
735	\N	2026-03-06 20:46:01.309053+00	2026-03-06 20:46:01.309053+00	esakkimuthu rajmatri	\N	\N	\N	\N	\N	\N	6e662c82-9e5c-4805-bbd3-e0fdb313edcd	\N
736	\N	2026-03-06 20:46:01.439637+00	2026-03-06 20:46:01.439637+00	faizia dental dr, azam	\N	\N	\N	\N	\N	\N	cfab6117-dcd6-475a-8cc7-4ffe665657a7	\N
737	\N	2026-03-06 20:46:01.557154+00	2026-03-06 20:46:01.557154+00	Farook dhabab C	\N	\N	\N	\N	\N	\N	1b9b0cdd-693b-4878-8737-f42289661a95	\N
738	\N	2026-03-06 20:46:01.683422+00	2026-03-06 20:46:01.683422+00	Fathima  Halith	\N	\N	\N	\N	\N	\N	09a3f13c-a42d-45c3-879d-eeb3ea885c88	\N
739	\N	2026-03-06 20:46:01.798349+00	2026-03-06 20:46:01.798349+00	Felin sujith paulstaff	\N	\N	\N	\N	\N	\N	9a379a97-e66c-4fb2-ad0a-b3abc4fbfa72	\N
740	\N	2026-03-06 20:46:01.889729+00	2026-03-06 20:46:01.889729+00	Finny pstoffice	\N	\N	\N	\N	\N	\N	c0f73dd0-6b54-4ff8-98c2-1f90aa2efa38	\N
741	\N	2026-03-06 20:46:02.002097+00	2026-03-06 20:46:02.002097+00	Fire	\N	\N	\N	\N	\N	\N	5ec74b26-c89c-4f20-afff-86312dc8892d	\N
742	\N	2026-03-06 20:46:02.133448+00	2026-03-06 20:46:02.133448+00	G2g	\N	\N	\N	\N	\N	\N	819fb1a2-e818-4c72-92bc-2821190f24bc	\N
743	\N	2026-03-06 20:46:02.26457+00	2026-03-06 20:46:02.26457+00	G2g  Phone	\N	\N	\N	\N	\N	\N	53af7496-45b5-4262-87f1-38cdda138fe9	\N
744	\N	2026-03-06 20:46:02.386078+00	2026-03-06 20:46:02.386078+00	Ganesh pstoffice	\N	\N	\N	\N	\N	\N	338ea987-e07a-46f1-a74c-a42904577503	\N
745	\N	2026-03-06 20:46:02.514096+00	2026-03-06 20:46:02.514096+00	Ganeshan  Lbs	\N	\N	\N	\N	\N	\N	e240cb83-d197-4eb9-bc5e-7d301f53a4fc	\N
746	\N	2026-03-06 20:46:02.616606+00	2026-03-06 20:46:02.616606+00	Ganthimathi	\N	\N	\N	\N	\N	\N	40b0b581-b70a-4090-9d6f-0ea8e187941e	\N
747	\N	2026-03-06 20:46:02.705944+00	2026-03-06 20:46:02.705944+00	Geetha  Coim	\N	\N	\N	\N	\N	\N	0b4e4613-73ab-42f1-8306-9d5d70393ffc	\N
748	\N	2026-03-06 20:46:02.809085+00	2026-03-06 20:46:02.809085+00	Gobinath	\N	\N	\N	\N	\N	\N	481e7326-2ebe-4c91-a143-f638a4811d59	\N
749	\N	2026-03-06 20:46:02.93503+00	2026-03-06 20:46:02.93503+00	Gobinath  2	\N	\N	\N	\N	\N	\N	5e7b88e9-5bbb-4af9-b918-4351b5a005d5	\N
750	\N	2026-03-06 20:46:03.063844+00	2026-03-06 20:46:03.063844+00	Gobinath  sahul	\N	\N	\N	\N	\N	\N	648180ae-2021-4435-9bdb-881bad6f9bbd	\N
751	\N	2026-03-06 20:46:03.178662+00	2026-03-06 20:46:03.178662+00	Gobinath  sahul2	\N	\N	\N	\N	\N	\N	677ae323-457c-4cc6-85dc-57d5fb406de5	\N
752	\N	2026-03-06 20:46:03.303989+00	2026-03-06 20:46:03.303989+00	Gobinath2  sahul	\N	\N	\N	\N	\N	\N	c25b7faf-2baa-40be-9223-cd406c59d343	\N
753	\N	2026-03-06 20:46:03.421263+00	2026-03-06 20:46:03.421263+00	Gold  Rahman	\N	\N	\N	\N	\N	\N	87e3c7fa-65d1-444f-8491-91b145aa203c	\N
754	\N	2026-03-06 20:46:03.559137+00	2026-03-06 20:46:03.559137+00	Gold rahman 2	\N	\N	\N	\N	\N	\N	4076f7a6-d6c7-404b-ae6b-c8b3ad2eff7c	\N
755	\N	2026-03-06 20:46:03.734851+00	2026-03-06 20:46:03.734851+00	Gomathi ns college theni pstclient	\N	\N	\N	\N	\N	\N	6c203cb6-75f8-4a08-a7d0-1b5e1c7192a2	\N
756	\N	2026-03-06 20:46:03.91004+00	2026-03-06 20:46:03.91004+00	Gopal  Makvin	\N	\N	\N	\N	\N	\N	abe62589-ca14-4581-875e-8a06d231bc46	\N
757	\N	2026-03-06 20:46:04.105201+00	2026-03-06 20:46:04.105201+00	Gopal  Tuticori	\N	\N	\N	\N	\N	\N	9ee6a5b9-ad56-426e-a130-83a9b3c3cd1e	\N
758	\N	2026-03-06 20:46:04.310439+00	2026-03-06 20:46:04.310439+00	Gopal  uncle	\N	\N	\N	\N	\N	\N	f607b285-8aa4-40d1-b026-e441f593bbdd	\N
759	\N	2026-03-06 20:46:04.438982+00	2026-03-06 20:46:04.438982+00	guna auto lodge	\N	\N	\N	\N	\N	\N	910f8afe-1230-4a61-9a79-3625db8c292d	\N
760	\N	2026-03-06 20:46:04.523272+00	2026-03-06 20:46:04.523272+00	haneefa	\N	\N	\N	\N	\N	\N	93f2b1da-0ecf-48fc-b542-df2e386e5b03	\N
761	\N	2026-03-06 20:46:04.607854+00	2026-03-06 20:46:04.607854+00	Holy  priya	\N	\N	\N	\N	\N	\N	7ffb8e21-a996-4487-be46-7a573ae8e5eb	\N
762	\N	2026-03-06 20:46:04.736531+00	2026-03-06 20:46:04.736531+00	hyma mam soel	\N	\N	\N	\N	\N	\N	03dcc7fa-229f-46b3-bb4e-ce2ef793cd86	\N
763	\N	2026-03-06 20:46:04.860117+00	2026-03-06 20:46:04.860117+00	immanuel  computers	\N	\N	\N	\N	\N	\N	09fc509d-3020-4647-8a51-469f7ee4514c	\N
764	\N	2026-03-06 20:46:04.975939+00	2026-03-06 20:46:04.975939+00	Immanuel  Studen	\N	\N	\N	\N	\N	\N	9d3c135d-2df5-4dcd-ad5a-c9c3d1262a77	\N
765	\N	2026-03-06 20:46:05.103817+00	2026-03-06 20:46:05.103817+00	indian bank get balance	\N	\N	\N	\N	\N	\N	ffb6e359-6513-44bc-ac10-5cba010c2dab	\N
766	\N	2026-03-06 20:46:05.205297+00	2026-03-06 20:46:05.205297+00	indian bank whatsapp banking	\N	\N	\N	\N	\N	\N	a7da1df1-e5d5-4661-90b5-a1e078a8f850	\N
767	\N	2026-03-06 20:46:05.298427+00	2026-03-06 20:46:05.298427+00	infant pstoffice	\N	\N	\N	\N	\N	\N	c2299117-70cb-4204-bde7-84717b809973	\N
768	\N	2026-03-06 20:46:05.393071+00	2026-03-06 20:46:05.393071+00	Insurance  sakun	\N	\N	\N	\N	\N	\N	581c202a-b7f6-4fa4-b440-126aefdea9f7	\N
769	\N	2026-03-06 20:46:05.525344+00	2026-03-06 20:46:05.525344+00	iruthayaraj matri chennai	\N	\N	\N	\N	\N	\N	8d25b62c-37b9-45aa-b746-ee0359fe3d44	\N
770	\N	2026-03-06 20:46:05.666891+00	2026-03-06 20:46:05.666891+00	iswarya  airtel	\N	\N	\N	\N	\N	\N	a4481992-732d-42cb-ab80-f3fcc75e0fa9	\N
771	\N	2026-03-06 20:46:05.788955+00	2026-03-06 20:46:05.788955+00	Iswarya  jio	\N	\N	\N	\N	\N	\N	02490cf3-d5bf-4db5-96f2-706d96f43de2	\N
772	\N	2026-03-06 20:46:05.902538+00	2026-03-06 20:46:05.902538+00	Iswarya  wife	\N	\N	\N	\N	\N	\N	84fe685a-954e-4e56-994f-0ca54a596ac1	\N
773	\N	2026-03-06 20:46:05.993887+00	2026-03-06 20:46:05.993887+00	Jaganathan Anjac Pstclient  R	\N	\N	\N	\N	\N	\N	75803d23-1872-4feb-b608-32e3906cde21	\N
774	\N	2026-03-06 20:46:06.085257+00	2026-03-06 20:46:06.085257+00	jagdeesh  helixsense	\N	\N	\N	\N	\N	\N	a61df6e6-c8e1-46f7-a844-ffe29639cbb2	\N
775	\N	2026-03-06 20:46:06.197378+00	2026-03-06 20:46:06.197378+00	Jain spc pstclient	\N	\N	\N	\N	\N	\N	acf50ed8-3589-4d93-ab81-49020a6fb1a9	\N
776	\N	2026-03-06 20:46:06.327329+00	2026-03-06 20:46:06.327329+00	Jam Jam Jewel M	\N	\N	\N	\N	\N	\N	209b5fea-3c04-45fd-8713-8578feb39533	\N
777	\N	2026-03-06 20:46:06.465049+00	2026-03-06 20:46:06.465049+00	James  g2g	\N	\N	\N	\N	\N	\N	100bcb98-b0c0-428b-9eae-6364a1617ce5	\N
778	\N	2026-03-06 20:46:06.584012+00	2026-03-06 20:46:06.584012+00	james g2g samraj	\N	\N	\N	\N	\N	\N	f2adb8c3-36f8-4423-b1c6-5d14ed59b3a1	\N
779	\N	2026-03-06 20:46:06.675422+00	2026-03-06 20:46:06.675422+00	jayaraj pstoffice	\N	\N	\N	\N	\N	\N	101bbdf5-6f54-4ef5-8fe9-40fd80e9805f	\N
780	\N	2026-03-06 20:46:06.771483+00	2026-03-06 20:46:06.771483+00	JAYARAJ wapp pstoffice	\N	\N	\N	\N	\N	\N	e5e01115-4517-4b0a-82f7-91d48b899663	\N
781	\N	2026-03-06 20:46:06.860075+00	2026-03-06 20:46:06.860075+00	Jegan S agri st group	\N	\N	\N	\N	\N	\N	d3602b39-bed5-47a4-b1a3-2b6275db5902	\N
782	\N	2026-03-06 20:46:06.983194+00	2026-03-06 20:46:06.983194+00	Jegarajan Sir sip friends	\N	\N	\N	\N	\N	\N	1fb48d0f-7033-48ac-bf91-e5e24bc93159	\N
783	\N	2026-03-06 20:46:07.110942+00	2026-03-06 20:46:07.110942+00	Jeni pstoffice	\N	\N	\N	\N	\N	\N	81fd4eb7-e7a8-4f18-9459-5dce9ac6853e	\N
784	\N	2026-03-06 20:46:07.242587+00	2026-03-06 20:46:07.242587+00	Jenifer	\N	\N	\N	\N	\N	\N	7eae7d66-7794-4c44-bfe8-a4a3712f2fd7	\N
785	\N	2026-03-06 20:46:07.364677+00	2026-03-06 20:46:07.364677+00	jerome milton pstclient	\N	\N	\N	\N	\N	\N	81e7f9fb-1177-4bb2-9c9e-dc0241ff0dc3	\N
786	\N	2026-03-06 20:46:07.457581+00	2026-03-06 20:46:07.457581+00	jimjoe	\N	\N	\N	\N	\N	\N	235840b1-9934-4651-8ed0-c3ccf4a689b9	\N
787	\N	2026-03-06 20:46:07.546741+00	2026-03-06 20:46:07.546741+00	Jio Modem Gopal	\N	\N	\N	\N	\N	\N	3e073aaf-87c2-49da-9a41-f39c479e5c03	\N
788	\N	2026-03-06 20:46:07.653255+00	2026-03-06 20:46:07.653255+00	jio modem karan	\N	\N	\N	\N	\N	\N	a5ea18d2-1249-4f0c-b271-2d16e5a0e210	\N
789	\N	2026-03-06 20:46:07.785695+00	2026-03-06 20:46:07.785695+00	Jobs	\N	\N	\N	\N	\N	\N	b6804d8d-e259-4b42-a694-63ae5d14dd64	\N
790	\N	2026-03-06 20:46:07.911068+00	2026-03-06 20:46:07.911068+00	John immanuel helixsense	\N	\N	\N	\N	\N	\N	04f96887-f580-4163-8877-ef1868005e07	\N
791	\N	2026-03-06 20:46:08.037027+00	2026-03-06 20:46:08.037027+00	John Stc Pstclient  Official	\N	\N	\N	\N	\N	\N	3ff17035-16fb-4760-b9f1-89273cf9d4af	\N
792	\N	2026-03-06 20:46:08.165611+00	2026-03-06 20:46:08.165611+00	johns  jeni	\N	\N	\N	\N	\N	\N	b12a962d-9043-426b-98ec-f22df56bf376	\N
793	\N	2026-03-06 20:46:08.258468+00	2026-03-06 20:46:08.258468+00	johns Kamaraj Flex 2	\N	\N	\N	\N	\N	\N	a1ac29ac-e221-4b13-b5e8-280c8c320e3c	\N
794	\N	2026-03-06 20:46:08.346329+00	2026-03-06 20:46:08.346329+00	johns librarian	\N	\N	\N	\N	\N	\N	ed80a4ef-187a-4eb0-8df7-2e313f445b01	\N
795	\N	2026-03-06 20:46:08.440211+00	2026-03-06 20:46:08.440211+00	johns reception landline	\N	\N	\N	\N	\N	\N	8f683044-b440-4511-9d52-6b99335dfeb1	\N
796	\N	2026-03-06 20:46:08.569621+00	2026-03-06 20:46:08.569621+00	johns vijayakumar library	\N	\N	\N	\N	\N	\N	62a03029-fc15-495d-b0b9-27e65381b598	\N
797	\N	2026-03-06 20:46:08.701861+00	2026-03-06 20:46:08.701861+00	johnson 2 pstoffice	\N	\N	\N	\N	\N	\N	86f4f561-9d2a-4bd4-9028-c5d0a76cf44c	\N
798	\N	2026-03-06 20:46:08.828132+00	2026-03-06 20:46:08.828132+00	johnson pstoffice	\N	\N	\N	\N	\N	\N	ecb0eaa0-28dd-4ed7-b960-28cf98528c2f	\N
799	\N	2026-03-06 20:46:08.955626+00	2026-03-06 20:46:08.955626+00	Johnson  Raj	\N	\N	\N	\N	\N	\N	174accd4-c07f-4b8f-a603-78d20b025810	\N
800	\N	2026-03-06 20:46:09.044608+00	2026-03-06 20:46:09.044608+00	johnson raj 2	\N	\N	\N	\N	\N	\N	1172da68-318a-4dab-b979-edfa5f15c6c8	\N
801	\N	2026-03-06 20:46:09.131354+00	2026-03-06 20:46:09.131354+00	Johny  g2g	\N	\N	\N	\N	\N	\N	0792e0d6-0b3c-4367-b3fa-8fc2e3f5f488	\N
802	\N	2026-03-06 20:46:09.229466+00	2026-03-06 20:46:09.229466+00	Jonna's psclient	\N	\N	\N	\N	\N	\N	1b302807-2fe8-4824-a926-01af93175eff	\N
803	\N	2026-03-06 20:46:09.377835+00	2026-03-06 20:46:09.377835+00	joseph sir psn pstclient	\N	\N	\N	\N	\N	\N	b33d3012-7aa6-4898-8cc8-9b2c0559f5cb	\N
804	\N	2026-03-06 20:46:09.638297+00	2026-03-06 20:46:09.638297+00	jothi pstoffice	\N	\N	\N	\N	\N	\N	b078c456-1269-49af-8bd4-53c8bc10af5b	\N
805	\N	2026-03-06 20:46:09.847092+00	2026-03-06 20:46:09.847092+00	Jovita	\N	\N	\N	\N	\N	\N	42c07089-1744-49f0-9185-3fe07c8eedcd	\N
806	\N	2026-03-06 20:46:10.035049+00	2026-03-06 20:46:10.035049+00	Jyothi  Alangula	\N	\N	\N	\N	\N	\N	7449e1d8-4c38-440b-9861-2042c65bac94	\N
807	\N	2026-03-06 20:46:10.156961+00	2026-03-06 20:46:10.156961+00	K VIJAYAKUMAR, SOCIALIST	\N	\N	\N	\N	\N	\N	c7980baf-ac8f-4d61-a958-a10a4158339b	\N
808	\N	2026-03-06 20:46:10.249081+00	2026-03-06 20:46:10.249081+00	Kalvi  Franchise	\N	\N	\N	\N	\N	\N	40cd2f4b-df20-42cd-8e14-e3facb76499c	\N
809	\N	2026-03-06 20:46:10.369907+00	2026-03-06 20:46:10.369907+00	kamaal pstoffice	\N	\N	\N	\N	\N	\N	3ce4bc0e-96c7-4f61-b5ce-da48776b3a57	\N
810	\N	2026-03-06 20:46:10.502117+00	2026-03-06 20:46:10.502117+00	kannan gas agency kpz	\N	\N	\N	\N	\N	\N	5cae4599-a993-447c-a5b5-977a801aa0cc	\N
811	\N	2026-03-06 20:46:10.632885+00	2026-03-06 20:46:10.632885+00	kannan  helixsense	\N	\N	\N	\N	\N	\N	8ed3b6f4-022c-426f-a3db-c3ae9034662c	\N
812	\N	2026-03-06 20:46:10.753472+00	2026-03-06 20:46:10.753472+00	karan airtel new	\N	\N	\N	\N	\N	\N	0f811f23-3d3d-416c-ac0b-62d3aa6f82c0	\N
813	\N	2026-03-06 20:46:10.845588+00	2026-03-06 20:46:10.845588+00	Kartheesan  pett	\N	\N	\N	\N	\N	\N	7c56445f-cc04-429e-8e06-95bc2a08a7d8	\N
814	\N	2026-03-06 20:46:10.93593+00	2026-03-06 20:46:10.93593+00	Karthi  Solar	\N	\N	\N	\N	\N	\N	03eedc42-77c7-42f8-a2aa-f4207721b56e	\N
815	\N	2026-03-06 20:46:11.028454+00	2026-03-06 20:46:11.028454+00	Karthick	\N	\N	\N	\N	\N	\N	06457a21-60fd-4f9a-b1d8-a3d9d296a743	\N
816	\N	2026-03-06 20:46:11.14966+00	2026-03-06 20:46:11.14966+00	karthick 2 anjac pstclient	\N	\N	\N	\N	\N	\N	0d4f6e95-b39c-4b0d-99f9-fe5fb0665607	\N
817	\N	2026-03-06 20:46:11.279034+00	2026-03-06 20:46:11.279034+00	karthick sir anjac pstclient	\N	\N	\N	\N	\N	\N	77cd4f5c-0cf7-4aeb-b50a-1c41c5a72987	\N
818	\N	2026-03-06 20:46:11.403652+00	2026-03-06 20:46:11.403652+00	Karthikeyan  2	\N	\N	\N	\N	\N	\N	56d204b2-6a07-4d2a-bb5b-69ea1c45c9c4	\N
819	\N	2026-03-06 20:46:11.538624+00	2026-03-06 20:46:11.538624+00	Karthikeyan Aa	\N	\N	\N	\N	\N	\N	ec469e18-1b04-4ce4-b0fb-a13deee62442	\N
820	\N	2026-03-06 20:46:11.633921+00	2026-03-06 20:46:11.633921+00	Karthikeyan  Kerala	\N	\N	\N	\N	\N	\N	045b67a2-3574-4aa3-bbee-403017ddee64	\N
821	\N	2026-03-06 20:46:11.721246+00	2026-03-06 20:46:11.721246+00	Kasi  Auto	\N	\N	\N	\N	\N	\N	8ad1bd72-3d24-49f0-b91c-852ead5ce4bf	\N
822	\N	2026-03-06 20:46:11.813246+00	2026-03-06 20:46:11.813246+00	kathir  bbb	\N	\N	\N	\N	\N	\N	114da8cd-d138-48d6-8c58-4fe251639fb5	\N
823	\N	2026-03-06 20:46:11.938064+00	2026-03-06 20:46:11.938064+00	kdnl  Ejaz	\N	\N	\N	\N	\N	\N	ab2928a2-724e-4dd9-afaf-c867927ccba4	\N
824	\N	2026-03-06 20:46:12.064187+00	2026-03-06 20:46:12.064187+00	Kdnl  Friend	\N	\N	\N	\N	\N	\N	c357f3b8-d179-46a4-946c-324e39e8f2f0	\N
825	\N	2026-03-06 20:46:12.185861+00	2026-03-06 20:46:12.185861+00	Kingsly  ravikum	\N	\N	\N	\N	\N	\N	9567ac43-9f9b-4560-9234-1b0cdf341ab3	\N
826	\N	2026-03-06 20:46:12.320774+00	2026-03-06 20:46:12.320774+00	Kiruba  Mam	\N	\N	\N	\N	\N	\N	810a9728-f4f0-42a4-bc8e-776a73c2ae96	\N
827	\N	2026-03-06 20:46:12.416721+00	2026-03-06 20:46:12.416721+00	krishna jerome ngl pstclient	\N	\N	\N	\N	\N	\N	2036ea5c-bd44-4551-96b6-e4e420abe003	\N
828	\N	2026-03-06 20:46:12.620018+00	2026-03-06 20:46:12.620018+00	Krishnan  g2g	\N	\N	\N	\N	\N	\N	90393c66-57d1-4ac0-bf31-54cd2b5a6015	\N
829	\N	2026-03-06 20:46:12.76822+00	2026-03-06 20:46:12.76822+00	Krishnaveni Mam Principal Balagan College	\N	\N	\N	\N	\N	\N	f28684e7-c99f-4d78-9a96-a65735a48c01	\N
830	\N	2026-03-06 20:46:12.916755+00	2026-03-06 20:46:12.916755+00	kulathupuzha bus stand	\N	\N	\N	\N	\N	\N	7b3f0159-b841-4d8a-ac78-96670e54a1e5	\N
831	\N	2026-03-06 20:46:13.038874+00	2026-03-06 20:46:13.038874+00	Kumeresh  Tiruch	\N	\N	\N	\N	\N	\N	a49a2143-03a9-40d2-a81b-3026c04abd2f	\N
832	\N	2026-03-06 20:46:13.17257+00	2026-03-06 20:46:13.17257+00	kurinjimalar rac library	\N	\N	\N	\N	\N	\N	33b3b9bf-ded1-49b8-aec7-3be742a30959	\N
833	\N	2026-03-06 20:46:13.282361+00	2026-03-06 20:46:13.282361+00	lak 2 pstoffice	\N	\N	\N	\N	\N	\N	86dbdb43-e926-4f30-9586-9e0f2758c284	\N
834	\N	2026-03-06 20:46:13.3753+00	2026-03-06 20:46:13.3753+00	lak3	\N	\N	\N	\N	\N	\N	f6a4da21-20e9-48a5-b523-2c09d2cbdfca	\N
835	\N	2026-03-06 20:46:13.468273+00	2026-03-06 20:46:13.468273+00	lakshmi pstoffice	\N	\N	\N	\N	\N	\N	71c6a8e6-99d1-45db-9182-32af6d673544	\N
836	\N	2026-03-06 20:46:13.613792+00	2026-03-06 20:46:13.613792+00	leolin fr St. xaviers Clg cs staff	\N	\N	\N	\N	\N	\N	5daedb3b-6054-479f-872f-d6ea1efab2e0	\N
837	\N	2026-03-06 20:46:13.747746+00	2026-03-06 20:46:13.747746+00	lib balagan saraswathi mam	\N	\N	\N	\N	\N	\N	682d7c23-2bee-4d3a-bb49-d0eef2b4316b	\N
838	\N	2026-03-06 20:46:13.860034+00	2026-03-06 20:46:13.860034+00	Lic  muthuraj	\N	\N	\N	\N	\N	\N	d0c897f1-8d86-468a-9a52-4b3325b6c3c3	\N
839	\N	2026-03-06 20:46:13.975272+00	2026-03-06 20:46:13.975272+00	Lodge  Labour	\N	\N	\N	\N	\N	\N	8376adf7-a788-4a42-9718-5ec5d943622f	\N
840	\N	2026-03-06 20:46:14.080584+00	2026-03-06 20:46:14.080584+00	lodge  recp	\N	\N	\N	\N	\N	\N	3deb758f-e2ec-4ed4-9312-bdd130fc6eba	\N
841	\N	2026-03-06 20:46:14.168896+00	2026-03-06 20:46:14.168896+00	Lodge  saravanan	\N	\N	\N	\N	\N	\N	51ef71ac-7464-4412-96cb-4b97732c4925	\N
842	\N	2026-03-06 20:46:14.259389+00	2026-03-06 20:46:14.259389+00	loganathan 24mtc	\N	\N	\N	\N	\N	\N	29a351cf-b0c2-422f-9fe4-a0b9561e7607	\N
843	\N	2026-03-06 20:46:14.385763+00	2026-03-06 20:46:14.385763+00	LOGANATHAN.S wpp pstclient	\N	\N	\N	\N	\N	\N	2bbae31c-7fe2-421c-97fc-2b730d87fc11	\N
844	\N	2026-03-06 20:46:14.517899+00	2026-03-06 20:46:14.517899+00	Lucilla philips ad	\N	\N	\N	\N	\N	\N	f730e3c0-f216-4f9a-b0ba-1ebca03a9424	\N
845	\N	2026-03-06 20:46:14.658707+00	2026-03-06 20:46:14.658707+00	M Senthil Kumar pt sur stgroup agri	\N	\N	\N	\N	\N	\N	93e25446-a5a7-41c8-975c-0cfc4e9324f7	\N
846	\N	2026-03-06 20:46:14.783455+00	2026-03-06 20:46:14.783455+00	MAFE  CARE	\N	\N	\N	\N	\N	\N	d98cd2e0-9263-4822-a04d-79973ab6cf24	\N
847	\N	2026-03-06 20:46:14.896628+00	2026-03-06 20:46:14.896628+00	Mahalakshmi Law soel	\N	\N	\N	\N	\N	\N	6ba569ed-d163-4ee2-b4a6-809933fa0891	\N
848	\N	2026-03-06 20:46:14.99798+00	2026-03-06 20:46:14.99798+00	maheshwaran spc alagu	\N	\N	\N	\N	\N	\N	3acf398b-bace-48d1-bf35-83d9e7fcffa5	\N
849	\N	2026-03-06 20:46:15.115884+00	2026-03-06 20:46:15.115884+00	malar  tuticorin	\N	\N	\N	\N	\N	\N	010ed88a-d60a-4955-b3c1-4d1bb74fecee	\N
850	\N	2026-03-06 20:46:15.305042+00	2026-03-06 20:46:15.305042+00	malathi pstoffice	\N	\N	\N	\N	\N	\N	524b0240-73ea-4067-8804-c4cb213c0628	\N
851	\N	2026-03-06 20:46:15.532104+00	2026-03-06 20:46:15.532104+00	Mallika  advacat	\N	\N	\N	\N	\N	\N	4dfb6e51-1434-42e4-b6b9-3c08de503ca7	\N
852	\N	2026-03-06 20:46:15.69201+00	2026-03-06 20:46:15.69201+00	Mallika  kerala	\N	\N	\N	\N	\N	\N	7eeda8fd-87f1-4b4c-acab-8a1b1631310a	\N
853	\N	2026-03-06 20:46:15.876228+00	2026-03-06 20:46:15.876228+00	mam  kolkatha	\N	\N	\N	\N	\N	\N	616fa2dd-c4c6-49e0-a400-ef3b410f4bcd	\N
854	\N	2026-03-06 20:46:16.021908+00	2026-03-06 20:46:16.021908+00	Mani  dam	\N	\N	\N	\N	\N	\N	01a217e6-437f-4108-8926-3dc32b4fdc51	\N
855	\N	2026-03-06 20:46:16.156874+00	2026-03-06 20:46:16.156874+00	Mani  Ktcnagar	\N	\N	\N	\N	\N	\N	e040d1a3-4f23-4b4c-aba5-e2e510dffb11	\N
856	\N	2026-03-06 20:46:16.289608+00	2026-03-06 20:46:16.289608+00	Mani  sand	\N	\N	\N	\N	\N	\N	93989e7e-f47b-4fa9-882c-30b88f00ac78	\N
857	\N	2026-03-06 20:46:16.41371+00	2026-03-06 20:46:16.41371+00	mani. raj. gane. developer	\N	\N	\N	\N	\N	\N	a0a50df1-6f42-45c3-a936-3c9f7d5e1732	\N
858	\N	2026-03-06 20:46:16.54703+00	2026-03-06 20:46:16.54703+00	Manikam  sivagan	\N	\N	\N	\N	\N	\N	b7dac961-7ae2-4692-b726-0f740fd8be7d	\N
859	\N	2026-03-06 20:46:16.677027+00	2026-03-06 20:46:16.677027+00	Manikumar	\N	\N	\N	\N	\N	\N	5da093cc-3001-4223-99f1-aedcf94a2c1a	\N
860	\N	2026-03-06 20:46:16.783103+00	2026-03-06 20:46:16.783103+00	Manju	\N	\N	\N	\N	\N	\N	a9d75b45-ee38-471e-a67b-bef60d9335a6	\N
861	\N	2026-03-06 20:46:16.873025+00	2026-03-06 20:46:16.873025+00	manoj pstclient	\N	\N	\N	\N	\N	\N	460a4c10-f8b0-4892-b96a-83783bad0820	\N
862	\N	2026-03-06 20:46:16.95889+00	2026-03-06 20:46:16.95889+00	manokaran  soel	\N	\N	\N	\N	\N	\N	2ff2eab5-ad35-4b49-8815-0b2a524f228c	\N
863	\N	2026-03-06 20:46:17.096848+00	2026-03-06 20:46:17.096848+00	mariappan pstoffice	\N	\N	\N	\N	\N	\N	2ffbe4eb-7e7a-4391-83dd-b2729d55cdba	\N
864	\N	2026-03-06 20:46:17.225377+00	2026-03-06 20:46:17.225377+00	mariselvam  edwin	\N	\N	\N	\N	\N	\N	905e5593-67ad-4d16-a270-a3bb40cda90d	\N
865	\N	2026-03-06 20:46:17.352187+00	2026-03-06 20:46:17.352187+00	martin  helixsense	\N	\N	\N	\N	\N	\N	f3892921-8ebe-4973-8145-108a259bb831	\N
866	\N	2026-03-06 20:46:17.485034+00	2026-03-06 20:46:17.485034+00	Mathan  g2g	\N	\N	\N	\N	\N	\N	4f159169-62ae-4b01-a54e-b1d1a69c03d8	\N
867	\N	2026-03-06 20:46:17.576217+00	2026-03-06 20:46:17.576217+00	Matrimony	\N	\N	\N	\N	\N	\N	78d4b976-544e-4c23-9ce0-15b41f3dfe99	\N
868	\N	2026-03-06 20:46:17.697397+00	2026-03-06 20:46:17.697397+00	Maze Workforce Development	\N	\N	\N	\N	\N	\N	5f3905c4-8c04-429c-8bf8-3dd1f09d0a44	\N
869	\N	2026-03-06 20:46:17.81603+00	2026-03-06 20:46:17.81603+00	MBO	\N	\N	\N	\N	\N	\N	dea7dd66-7433-4c90-93ae-83ec1fb69ed5	\N
870	\N	2026-03-06 20:46:17.955156+00	2026-03-06 20:46:17.955156+00	mdu job iswarya contact	\N	\N	\N	\N	\N	\N	24078f14-52d8-4e2e-ac1f-3736b34e1885	\N
871	\N	2026-03-06 20:46:18.082338+00	2026-03-06 20:46:18.082338+00	med bill payroll	\N	\N	\N	\N	\N	\N	99252d6c-89d0-4783-828d-4c8fe581aac2	\N
872	\N	2026-03-06 20:46:18.205622+00	2026-03-06 20:46:18.205622+00	Meena Sheik Kdn	\N	\N	\N	\N	\N	\N	9ee12919-ef23-4488-9d4a-c8ba70a1c514	\N
873	\N	2026-03-06 20:46:18.321457+00	2026-03-06 20:46:18.321457+00	Merlin.M pstclient	\N	\N	\N	\N	\N	\N	2b077006-a6f2-4826-9b26-3bbfb3617df3	\N
874	\N	2026-03-06 20:46:18.407609+00	2026-03-06 20:46:18.407609+00	Milton  2	\N	\N	\N	\N	\N	\N	41748d58-07ed-4782-8103-581b99623908	\N
875	\N	2026-03-06 20:46:18.498723+00	2026-03-06 20:46:18.498723+00	Milton  bsnl	\N	\N	\N	\N	\N	\N	5b7b942a-185c-445b-9338-cc9fe9fa5fa9	\N
876	\N	2026-03-06 20:46:18.604082+00	2026-03-06 20:46:18.604082+00	Milton  postpaid	\N	\N	\N	\N	\N	\N	3674211b-ae49-4ddc-addd-eae0261b4da5	\N
877	\N	2026-03-06 20:46:18.72496+00	2026-03-06 20:46:18.72496+00	Milton recent xavier	\N	\N	\N	\N	\N	\N	09b977c9-b7fe-49f8-bc06-66c2033c9743	\N
878	\N	2026-03-06 20:46:18.861308+00	2026-03-06 20:46:18.861308+00	Milton  whatsup	\N	\N	\N	\N	\N	\N	06aba851-f8a1-4fb8-a60d-6c51c59ffc38	\N
879	\N	2026-03-06 20:46:18.976556+00	2026-03-06 20:46:18.976556+00	Mohan Seshadri sankarlingam	\N	\N	\N	\N	\N	\N	6e19019a-a1cd-495c-aaa8-962de032fedd	\N
880	\N	2026-03-06 20:46:19.09855+00	2026-03-06 20:46:19.09855+00	moniha rrc mdu  v	\N	\N	\N	\N	\N	\N	d8024969-f63c-48c3-b86a-f2bc5c70fffe	\N
881	\N	2026-03-06 20:46:19.192216+00	2026-03-06 20:46:19.192216+00	Moon  light	\N	\N	\N	\N	\N	\N	31f334a7-c68c-4f0c-a31e-938224868f10	\N
882	\N	2026-03-06 20:46:19.279436+00	2026-03-06 20:46:19.279436+00	Moon Light 3	\N	\N	\N	\N	\N	\N	19ac004b-d51e-4acc-abd7-2cfea5f6a13c	\N
883	\N	2026-03-06 20:46:19.381881+00	2026-03-06 20:46:19.381881+00	Moon Light 4	\N	\N	\N	\N	\N	\N	cefab539-8d4a-437a-a19e-1ec7af1556e1	\N
884	\N	2026-03-06 20:46:19.512363+00	2026-03-06 20:46:19.512363+00	Moses  dam	\N	\N	\N	\N	\N	\N	874428ed-b9cb-426c-b29c-6af7d344b513	\N
885	\N	2026-03-06 20:46:19.662183+00	2026-03-06 20:46:19.662183+00	Moses  friend	\N	\N	\N	\N	\N	\N	46f85ec4-70a1-4a84-b128-1ea4c3c9a475	\N
886	\N	2026-03-06 20:46:19.778077+00	2026-03-06 20:46:19.778077+00	Moses friend 2	\N	\N	\N	\N	\N	\N	6f46f70c-0429-4707-8338-85e780b45a0c	\N
887	\N	2026-03-06 20:46:19.894901+00	2026-03-06 20:46:19.894901+00	moses  helixsense	\N	\N	\N	\N	\N	\N	86a98643-82bb-406d-95f0-138f3643dd63	\N
888	\N	2026-03-06 20:46:19.984299+00	2026-03-06 20:46:19.984299+00	Moses  mumbai	\N	\N	\N	\N	\N	\N	3a6b6133-bba1-4cf9-8f2e-69a27f32ece1	\N
889	\N	2026-03-06 20:46:20.074086+00	2026-03-06 20:46:20.074086+00	Moses2	\N	\N	\N	\N	\N	\N	e3968360-a4f2-4a9e-8e80-f81853c88946	\N
890	\N	2026-03-06 20:46:20.16993+00	2026-03-06 20:46:20.16993+00	mugesan dmns nellai	\N	\N	\N	\N	\N	\N	d107dce9-0db2-4308-b485-0f7d91b7e1f2	\N
891	\N	2026-03-06 20:46:20.289903+00	2026-03-06 20:46:20.289903+00	Munish	\N	\N	\N	\N	\N	\N	29c72a42-f252-4371-a61c-dfbbfef00c29	\N
892	\N	2026-03-06 20:46:20.422546+00	2026-03-06 20:46:20.422546+00	murugan 3	\N	\N	\N	\N	\N	\N	81cea21d-fb17-4691-a322-e9eb4e83b473	\N
893	\N	2026-03-06 20:46:20.566989+00	2026-03-06 20:46:20.566989+00	Murugan g. barbe	\N	\N	\N	\N	\N	\N	6fab158d-5c62-444a-a4ef-bfadd278e9ae	\N
894	\N	2026-03-06 20:46:20.695899+00	2026-03-06 20:46:20.695899+00	Murugan lodge 2	\N	\N	\N	\N	\N	\N	d9712152-59cd-43f6-97fe-ad007e1fb4fa	\N
895	\N	2026-03-06 20:46:20.784664+00	2026-03-06 20:46:20.784664+00	Murugan son ldg	\N	\N	\N	\N	\N	\N	278eeeb7-8ea4-4fb2-89a2-7f127d07e8f2	\N
896	\N	2026-03-06 20:46:20.874023+00	2026-03-06 20:46:20.874023+00	murugeshwari	\N	\N	\N	\N	\N	\N	573e89ff-2518-4138-96e4-1b038c85a128	\N
897	\N	2026-03-06 20:46:20.970735+00	2026-03-06 20:46:20.970735+00	Mustafa	\N	\N	\N	\N	\N	\N	d3e568a2-84c2-40ed-98bc-da3fdf3c8440	\N
898	\N	2026-03-06 20:46:21.086019+00	2026-03-06 20:46:21.086019+00	MUTHU SHIVA thangapazham medical college	\N	\N	\N	\N	\N	\N	3befe51f-2cd5-4ab5-9e49-bed7db8c12fe	\N
899	\N	2026-03-06 20:46:21.241478+00	2026-03-06 20:46:21.241478+00	muthumariappan  esl	\N	\N	\N	\N	\N	\N	4f2f1ca1-abb0-456a-8058-1e5088c3f426	\N
900	\N	2026-03-06 20:46:21.471127+00	2026-03-06 20:46:21.471127+00	muthupandi svn pstclient	\N	\N	\N	\N	\N	\N	7214f19e-edf4-4524-bee5-ed71bb2e5fe7	\N
901	\N	2026-03-06 20:46:21.67226+00	2026-03-06 20:46:21.67226+00	muthuprakash  pst	\N	\N	\N	\N	\N	\N	3dfb246b-4c59-4f78-b8cc-4b3ecf1314fb	\N
902	\N	2026-03-06 20:46:21.818319+00	2026-03-06 20:46:21.818319+00	muthuraj munnar sarath	\N	\N	\N	\N	\N	\N	880b0c67-9ce7-41ec-a50f-4face5e46c74	\N
903	\N	2026-03-06 20:46:21.96648+00	2026-03-06 20:46:21.96648+00	My  Delights	\N	\N	\N	\N	\N	\N	85099724-9bd1-4d6a-a2b7-f22a19e2d636	\N
904	\N	2026-03-06 20:46:22.160901+00	2026-03-06 20:46:22.160901+00	My  Jio	\N	\N	\N	\N	\N	\N	975832b3-76e3-4967-802d-316317019228	\N
905	\N	2026-03-06 20:46:22.301481+00	2026-03-06 20:46:22.301481+00	Mydeen Fert. kdn	\N	\N	\N	\N	\N	\N	228f1374-e5b0-4daa-94e3-78d17ba9a396	\N
906	\N	2026-03-06 20:46:22.425516+00	2026-03-06 20:46:22.425516+00	Mydeen fert. wha	\N	\N	\N	\N	\N	\N	a6461c07-a282-4b46-8f29-6c97e404f281	\N
907	\N	2026-03-06 20:46:22.519765+00	2026-03-06 20:46:22.519765+00	nambirajan  Flex	\N	\N	\N	\N	\N	\N	93e0cef7-4f5d-4eee-9a9e-66cf57d7d388	\N
908	\N	2026-03-06 20:46:22.613832+00	2026-03-06 20:46:22.613832+00	Narayanan	\N	\N	\N	\N	\N	\N	3aca95a7-ff03-4f13-8ccd-7313e0f36dd3	\N
909	\N	2026-03-06 20:46:22.702879+00	2026-03-06 20:46:22.702879+00	Nathan	\N	\N	\N	\N	\N	\N	030ce1d0-1b67-428c-a3ad-c99866a02542	\N
910	\N	2026-03-06 20:46:22.8213+00	2026-03-06 20:46:22.8213+00	Natural Beauty yes bill customer	\N	\N	\N	\N	\N	\N	c8f87590-bc1f-47e1-b445-6c2f9108068f	\N
911	\N	2026-03-06 20:46:22.93386+00	2026-03-06 20:46:22.93386+00	naturo foods gnanaraj	\N	\N	\N	\N	\N	\N	a1c2b0f3-266b-4c14-864f-b0b2929b58ad	\N
912	\N	2026-03-06 20:46:23.074495+00	2026-03-06 20:46:23.074495+00	neela pstoffice	\N	\N	\N	\N	\N	\N	a96cc159-3ec1-4ec7-bef9-154a8419efb7	\N
913	\N	2026-03-06 20:46:23.198969+00	2026-03-06 20:46:23.198969+00	neela  rac	\N	\N	\N	\N	\N	\N	7ad579ab-8951-48b1-a9bc-69e501613ed4	\N
914	\N	2026-03-06 20:46:23.30846+00	2026-03-06 20:46:23.30846+00	News  Update	\N	\N	\N	\N	\N	\N	c5a9e897-382f-4687-ac87-07c1220ccece	\N
915	\N	2026-03-06 20:46:23.418071+00	2026-03-06 20:46:23.418071+00	Nivetha kader raj matri	\N	\N	\N	\N	\N	\N	652d7138-6676-4c9a-9d8b-c9afc93f006c	\N
916	\N	2026-03-06 20:46:23.535318+00	2026-03-06 20:46:23.535318+00	Nizha comlex 2	\N	\N	\N	\N	\N	\N	17374d27-1c53-479d-810b-883fe3820739	\N
917	\N	2026-03-06 20:46:23.665014+00	2026-03-06 20:46:23.665014+00	Nizha  complex	\N	\N	\N	\N	\N	\N	47f4ecb1-4024-47c2-9688-fe77e2c833a9	\N
918	\N	2026-03-06 20:46:23.782718+00	2026-03-06 20:46:23.782718+00	nmcp  juliana	\N	\N	\N	\N	\N	\N	e90b7a95-8ae8-433e-82f0-4210c80c6249	\N
919	\N	2026-03-06 20:46:23.924306+00	2026-03-06 20:46:23.924306+00	nmcp pakyaraj sir	\N	\N	\N	\N	\N	\N	2d0de9a2-dd6a-4db9-bce2-a8a6737c5b24	\N
920	\N	2026-03-06 20:46:24.047192+00	2026-03-06 20:46:24.047192+00	notary  Arumugam	\N	\N	\N	\N	\N	\N	dcbe1553-8818-4e8b-800d-c21a286e5133	\N
921	\N	2026-03-06 20:46:24.143314+00	2026-03-06 20:46:24.143314+00	oliver  sir	\N	\N	\N	\N	\N	\N	3081a900-3db3-444b-a1d8-0450d79f1501	\N
922	\N	2026-03-06 20:46:24.232307+00	2026-03-06 20:46:24.232307+00	Os	\N	\N	\N	\N	\N	\N	daaeed1d-3a5b-42a9-9bf8-c8308e399fec	\N
923	\N	2026-03-06 20:46:24.31979+00	2026-03-06 20:46:24.31979+00	padmanabhan  kerala	\N	\N	\N	\N	\N	\N	0eb5ba17-231d-469a-af99-51953a2e77b3	\N
924	\N	2026-03-06 20:46:24.443058+00	2026-03-06 20:46:24.443058+00	palakkad  sithappa	\N	\N	\N	\N	\N	\N	bd98dce2-7c11-4c29-a6b7-d005bf56fdd7	\N
925	\N	2026-03-06 20:46:24.562407+00	2026-03-06 20:46:24.562407+00	palakkad1	\N	\N	\N	\N	\N	\N	e59dd6ca-647b-4c35-a96b-3d18e4e88c14	\N
926	\N	2026-03-06 20:46:24.691663+00	2026-03-06 20:46:24.691663+00	parasakthi chem dep	\N	\N	\N	\N	\N	\N	a5b3c50a-5f66-4295-9a63-3436ab2346be	\N
927	\N	2026-03-06 20:46:24.818159+00	2026-03-06 20:46:24.818159+00	parasakthi coe mam	\N	\N	\N	\N	\N	\N	e6922571-b3a7-426d-a94f-985dfb6d670b	\N
928	\N	2026-03-06 20:46:24.926888+00	2026-03-06 20:46:24.926888+00	parasakthi maths dept	\N	\N	\N	\N	\N	\N	8c0cc0a1-0c34-47d0-9305-9934d6593e1e	\N
929	\N	2026-03-06 20:46:25.013603+00	2026-03-06 20:46:25.013603+00	parasakthi  muthumari	\N	\N	\N	\N	\N	\N	02598026-47a6-4288-8331-9b53cfd560f6	\N
930	\N	2026-03-06 20:46:25.096367+00	2026-03-06 20:46:25.096367+00	parasakthi muthumari 2	\N	\N	\N	\N	\N	\N	cd6ec7ce-3136-4794-a0e5-af66d5d8e722	\N
931	\N	2026-03-06 20:46:25.20604+00	2026-03-06 20:46:25.20604+00	parasakthi  principal	\N	\N	\N	\N	\N	\N	01461202-2bb6-4d0e-bec5-9f62aeb33e88	\N
932	\N	2026-03-06 20:46:25.324567+00	2026-03-06 20:46:25.324567+00	parasakthi tamil dept mam	\N	\N	\N	\N	\N	\N	e0fe1d2e-d88b-4dee-990c-019cfa5c1d16	\N
933	\N	2026-03-06 20:46:25.445125+00	2026-03-06 20:46:25.445125+00	parasakthi zoology vasanthi	\N	\N	\N	\N	\N	\N	97d5d3a1-8675-4ad8-a2fe-c2c243484b3c	\N
934	\N	2026-03-06 20:46:25.58711+00	2026-03-06 20:46:25.58711+00	partha  Parvin	\N	\N	\N	\N	\N	\N	11e897e6-76b1-4033-b10e-64c1b223e8cc	\N
935	\N	2026-03-06 20:46:25.700765+00	2026-03-06 20:46:25.700765+00	Parvin  3	\N	\N	\N	\N	\N	\N	6ac9c212-83f3-4ebd-b3e2-e8743bc8c095	\N
936	\N	2026-03-06 20:46:25.793914+00	2026-03-06 20:46:25.793914+00	Parvin  Main	\N	\N	\N	\N	\N	\N	f80506a0-3760-405e-a288-9b354c5e5a74	\N
937	\N	2026-03-06 20:46:25.879339+00	2026-03-06 20:46:25.879339+00	Parvin  partha	\N	\N	\N	\N	\N	\N	fd54d134-57ae-463b-907c-555207192393	\N
938	\N	2026-03-06 20:46:25.985943+00	2026-03-06 20:46:25.985943+00	parwathi pstoffice	\N	\N	\N	\N	\N	\N	4d200333-158a-4725-8a7d-11d8dfabdc30	\N
939	\N	2026-03-06 20:46:26.11014+00	2026-03-06 20:46:26.11014+00	Pasu  2	\N	\N	\N	\N	\N	\N	17663581-47b3-4959-8c5c-f24a581ed67c	\N
940	\N	2026-03-06 20:46:26.230502+00	2026-03-06 20:46:26.230502+00	paul  staff	\N	\N	\N	\N	\N	\N	3c224743-9974-44cb-b84d-1ba1ce842d11	\N
941	\N	2026-03-06 20:46:26.354991+00	2026-03-06 20:46:26.354991+00	paulraj 2 wtmu pstclient	\N	\N	\N	\N	\N	\N	bac36f38-91e5-4bb8-b0fc-e6940e7596ab	\N
942	\N	2026-03-06 20:46:26.478548+00	2026-03-06 20:46:26.478548+00	Paulraj wtmu pstclient	\N	\N	\N	\N	\N	\N	c87334b2-0c50-47a7-9138-6e8876088379	\N
943	\N	2026-03-06 20:46:26.576812+00	2026-03-06 20:46:26.576812+00	Pavanraj	\N	\N	\N	\N	\N	\N	00e5f3d6-d611-4300-bde2-c17aa7a33b1b	\N
944	\N	2026-03-06 20:46:26.675207+00	2026-03-06 20:46:26.675207+00	Pavanraj  2	\N	\N	\N	\N	\N	\N	f9982422-79ad-46f0-8cc2-de0d69a22b1d	\N
945	\N	2026-03-06 20:46:26.801368+00	2026-03-06 20:46:26.801368+00	peer pstoffice	\N	\N	\N	\N	\N	\N	06bdec31-e8a1-4cb1-b523-ad3ced9a0469	\N
946	\N	2026-03-06 20:46:26.923082+00	2026-03-06 20:46:26.923082+00	Phd  Soel	\N	\N	\N	\N	\N	\N	473fea80-d513-4bbb-b0ec-26136113f1ac	\N
947	\N	2026-03-06 20:46:27.041205+00	2026-03-06 20:46:27.041205+00	Pin	\N	\N	\N	\N	\N	\N	a303d247-452d-4972-85e2-1d0a12bbb07b	\N
948	\N	2026-03-06 20:46:27.166835+00	2026-03-06 20:46:27.166835+00	Police	\N	\N	\N	\N	\N	\N	054c03aa-77b3-4205-9036-c0242a508670	\N
949	\N	2026-03-06 20:46:27.327785+00	2026-03-06 20:46:27.327785+00	Prabakaran Sir Hod Sasurie eng	\N	\N	\N	\N	\N	\N	e783de31-5428-48c0-bfdd-f858ce41b091	\N
950	\N	2026-03-06 20:46:27.447629+00	2026-03-06 20:46:27.447629+00	prabhu puthukkottai	\N	\N	\N	\N	\N	\N	7834d103-4e13-4abc-b04c-43474f30181a	\N
951	\N	2026-03-06 20:46:27.635797+00	2026-03-06 20:46:27.635797+00	prakash  furniture	\N	\N	\N	\N	\N	\N	7f5a6229-d86e-4d9b-8d2e-5bb2501cff81	\N
952	\N	2026-03-06 20:46:27.821452+00	2026-03-06 20:46:27.821452+00	prasanna helixsense 2	\N	\N	\N	\N	\N	\N	3d11e08c-85d5-4278-823b-fa10258ee27c	\N
953	\N	2026-03-06 20:46:28.038904+00	2026-03-06 20:46:28.038904+00	prasanna  sir	\N	\N	\N	\N	\N	\N	4e9d7e49-fa14-4bf6-b2d5-af3e6d727eba	\N
954	\N	2026-03-06 20:46:28.171979+00	2026-03-06 20:46:28.171979+00	premkumar naas incharge	\N	\N	\N	\N	\N	\N	70ff189b-eb36-4229-985b-3092a5c3179c	\N
955	\N	2026-03-06 20:46:28.282394+00	2026-03-06 20:46:28.282394+00	Priya  Kalvi	\N	\N	\N	\N	\N	\N	c3dfdc1f-4861-432e-a1af-26de771bd0c8	\N
956	\N	2026-03-06 20:46:28.371534+00	2026-03-06 20:46:28.371534+00	project  Rubini	\N	\N	\N	\N	\N	\N	326df8ec-1365-496b-ac2f-409da5aa2afc	\N
957	\N	2026-03-06 20:46:28.462433+00	2026-03-06 20:46:28.462433+00	PSN Santhana Mahalingam Sir pstclient	\N	\N	\N	\N	\N	\N	3a8bc8b3-dd7d-450c-bc2c-0db874c39b5b	\N
958	\N	2026-03-06 20:46:28.577962+00	2026-03-06 20:46:28.577962+00	Pst 170	\N	\N	\N	\N	\N	\N	cc4a09b8-b527-434c-8c38-b2570b506968	\N
959	\N	2026-03-06 20:46:28.717012+00	2026-03-06 20:46:28.717012+00	Puliangudi2	\N	\N	\N	\N	\N	\N	9b5967d4-652f-4e67-8904-980234e99fee	\N
960	\N	2026-03-06 20:46:28.838607+00	2026-03-06 20:46:28.838607+00	Raaja  Balakrish	\N	\N	\N	\N	\N	\N	c3654251-3944-44b8-84f0-2a0876be43c8	\N
961	\N	2026-03-06 20:46:28.976175+00	2026-03-06 20:46:28.976175+00	rac kavya mam	\N	\N	\N	\N	\N	\N	954fc1ed-ec58-47d3-ac78-2f586cf13fe9	\N
962	\N	2026-03-06 20:46:29.074353+00	2026-03-06 20:46:29.074353+00	rac new co ordinator	\N	\N	\N	\N	\N	\N	b95f498e-6eca-4b0d-a91b-a42c6defffee	\N
963	\N	2026-03-06 20:46:29.160375+00	2026-03-06 20:46:29.160375+00	Radio	\N	\N	\N	\N	\N	\N	8f2abc5d-8128-415a-b713-2626122ec6b8	\N
964	\N	2026-03-06 20:46:29.244515+00	2026-03-06 20:46:29.244515+00	raghu  dam	\N	\N	\N	\N	\N	\N	c09018af-d023-498e-a944-0f5ac6c95f92	\N
965	\N	2026-03-06 20:46:29.366311+00	2026-03-06 20:46:29.366311+00	Ragl Mohana Sug	\N	\N	\N	\N	\N	\N	80592313-9d60-43aa-ae77-c8ae0fb143c8	\N
966	\N	2026-03-06 20:46:29.505088+00	2026-03-06 20:46:29.505088+00	Ragland	\N	\N	\N	\N	\N	\N	1c9e1868-854e-461c-9f95-1cc1c21649db	\N
967	\N	2026-03-06 20:46:29.6385+00	2026-03-06 20:46:29.6385+00	Ragland  2	\N	\N	\N	\N	\N	\N	10360066-b9bf-4a91-891b-88e0cb5098cd	\N
968	\N	2026-03-06 20:46:29.762788+00	2026-03-06 20:46:29.762788+00	Rail  Enquiry	\N	\N	\N	\N	\N	\N	2f5ee1ea-e293-4804-ba2f-326b03741bf8	\N
969	\N	2026-03-06 20:46:29.867219+00	2026-03-06 20:46:29.867219+00	RailPNR  Status	\N	\N	\N	\N	\N	\N	80c3a48c-cb98-4598-a650-cb863a82a7e6	\N
970	\N	2026-03-06 20:46:29.959934+00	2026-03-06 20:46:29.959934+00	raj ganeshan 3	\N	\N	\N	\N	\N	\N	e98ac027-2f38-4089-817b-7dc2f0d67257	\N
971	\N	2026-03-06 20:46:30.044892+00	2026-03-06 20:46:30.044892+00	raj  soel	\N	\N	\N	\N	\N	\N	2e3f550e-0088-45a6-910c-a24019c3cd4b	\N
972	\N	2026-03-06 20:46:30.162861+00	2026-03-06 20:46:30.162861+00	Raja Comp Bala	\N	\N	\N	\N	\N	\N	a91d7344-1ae3-4626-8b76-69d282d55a91	\N
973	\N	2026-03-06 20:46:30.296127+00	2026-03-06 20:46:30.296127+00	Raja  esi	\N	\N	\N	\N	\N	\N	a4d9d7f6-3795-423f-98b6-33e400c195b8	\N
974	\N	2026-03-06 20:46:30.420144+00	2026-03-06 20:46:30.420144+00	Raja scatting 2	\N	\N	\N	\N	\N	\N	41518b12-69dc-424b-8f9e-baa23803afab	\N
975	\N	2026-03-06 20:46:30.540519+00	2026-03-06 20:46:30.540519+00	Raja  skating	\N	\N	\N	\N	\N	\N	184fce27-3472-4255-9251-ef938d3b652a	\N
976	\N	2026-03-06 20:46:30.651732+00	2026-03-06 20:46:30.651732+00	Rajakannu  keral	\N	\N	\N	\N	\N	\N	94653fe5-5d52-4764-a217-2572352936d1	\N
977	\N	2026-03-06 20:46:30.742476+00	2026-03-06 20:46:30.742476+00	rajamanikkam  2f	\N	\N	\N	\N	\N	\N	fcc7a8b5-e521-4ee8-8539-42b318ab6c0f	\N
978	\N	2026-03-06 20:46:30.829217+00	2026-03-06 20:46:30.829217+00	rajasekar  2f	\N	\N	\N	\N	\N	\N	7b11527f-8d04-4297-b5bf-65c45064a1ae	\N
979	\N	2026-03-06 20:46:30.938702+00	2026-03-06 20:46:30.938702+00	rajasekar ker friend	\N	\N	\N	\N	\N	\N	071f35b1-dbbd-4c11-ada2-c6c0375ef559	\N
980	\N	2026-03-06 20:46:31.059455+00	2026-03-06 20:46:31.059455+00	rajashakthi8681	\N	\N	\N	\N	\N	\N	2609f5d1-dd6c-4110-b4f8-4679181bd4b1	\N
981	\N	2026-03-06 20:46:31.186871+00	2026-03-06 20:46:31.186871+00	Rajesh K R jain clg pstclient	\N	\N	\N	\N	\N	\N	1f8cfd8b-23c5-4afa-a805-10cb7d548644	\N
982	\N	2026-03-06 20:46:31.312182+00	2026-03-06 20:46:31.312182+00	rajesh sir soel	\N	\N	\N	\N	\N	\N	14fd6a4d-5694-478a-b6b7-17b8001d9529	\N
983	\N	2026-03-06 20:46:31.435741+00	2026-03-06 20:46:31.435741+00	rajeshwari dam susileela	\N	\N	\N	\N	\N	\N	6b00233b-6ce3-421d-8288-46c691dd2019	\N
984	\N	2026-03-06 20:46:31.529338+00	2026-03-06 20:46:31.529338+00	rajmatri gan bbb	\N	\N	\N	\N	\N	\N	336ec94b-15eb-4ea7-9b37-19fb47150756	\N
985	\N	2026-03-06 20:46:31.617451+00	2026-03-06 20:46:31.617451+00	rajmatri ganesan 3	\N	\N	\N	\N	\N	\N	1c342fbc-d512-4ae3-9b1f-de28f1bcd7a4	\N
986	\N	2026-03-06 20:46:31.720046+00	2026-03-06 20:46:31.720046+00	rajmatri ganesan bbb	\N	\N	\N	\N	\N	\N	328ac5cc-37b4-46c1-9f3c-c3bfe567793c	\N
987	\N	2026-03-06 20:46:31.780667+00	2026-03-06 20:46:31.780667+00	rajmatri  maniraj	\N	\N	\N	\N	\N	\N	dad4310b-2994-4013-a6ff-89e30172bdb0	\N
988	\N	2026-03-06 20:46:31.908146+00	2026-03-06 20:46:31.908146+00	rajmatri office staff	\N	\N	\N	\N	\N	\N	4083dd16-bb6e-4ef8-9b7c-2331b60376b0	\N
989	\N	2026-03-06 20:46:32.036492+00	2026-03-06 20:46:32.036492+00	rajmatrimony staff 3	\N	\N	\N	\N	\N	\N	e1f74c06-7d86-4b3b-b28a-5cb66281bcb7	\N
990	\N	2026-03-06 20:46:32.152529+00	2026-03-06 20:46:32.152529+00	Ram  itech	\N	\N	\N	\N	\N	\N	61a23982-ed56-4f02-a80e-f30e17d30678	\N
991	\N	2026-03-06 20:46:32.273203+00	2026-03-06 20:46:32.273203+00	Ramesh  kerala	\N	\N	\N	\N	\N	\N	8c33802c-cb63-41c3-b9aa-b012ec53aecf	\N
992	\N	2026-03-06 20:46:32.361512+00	2026-03-06 20:46:32.361512+00	ramkumar sasuri PRINCIPAL	\N	\N	\N	\N	\N	\N	20f749c4-8aea-45c1-abe9-33ce50006e03	\N
993	\N	2026-03-06 20:46:32.459727+00	2026-03-06 20:46:32.459727+00	rangasamy sir tdmns	\N	\N	\N	\N	\N	\N	973e5ab8-9bc4-4965-beb2-b050170de4d0	\N
994	\N	2026-03-06 20:46:32.576709+00	2026-03-06 20:46:32.576709+00	Ravathy  Oracle2	\N	\N	\N	\N	\N	\N	6d82415e-b840-4d72-8854-cef3dcd0f115	\N
995	\N	2026-03-06 20:46:32.714942+00	2026-03-06 20:46:32.714942+00	ravi munnar	\N	\N	\N	\N	\N	\N	b990158d-15c1-4dce-8e4a-0fe077b10736	\N
996	\N	2026-03-06 20:46:32.834628+00	2026-03-06 20:46:32.834628+00	Ravi sasthiri N	\N	\N	\N	\N	\N	\N	89be1e7e-d10a-4ad5-9a2b-b690ca8758d6	\N
997	\N	2026-03-06 20:46:32.958911+00	2026-03-06 20:46:32.958911+00	Ravi  seranmahad	\N	\N	\N	\N	\N	\N	79363750-4804-4a8c-ad6c-b1c47e5c050e	\N
998	\N	2026-03-06 20:46:33.070294+00	2026-03-06 20:46:33.070294+00	ravichandran AA tvl	\N	\N	\N	\N	\N	\N	41a53423-7514-49f8-840c-a33ad24298ab	\N
999	\N	2026-03-06 20:46:33.191432+00	2026-03-06 20:46:33.191432+00	Ravikumar	\N	\N	\N	\N	\N	\N	6bc57688-dfa5-4532-8a8a-4aa214c7546d	\N
1000	\N	2026-03-06 20:46:33.340066+00	2026-03-06 20:46:33.340066+00	Recharge	\N	\N	\N	\N	\N	\N	1ec1be5d-904d-4dca-aa89-4db32521b7a8	\N
1001	\N	2026-03-06 20:46:33.536832+00	2026-03-06 20:46:33.536832+00	Renil pstoffice	\N	\N	\N	\N	\N	\N	48cde974-7a81-4f67-903e-49cf57fe4604	\N
1002	\N	2026-03-06 20:46:33.765852+00	2026-03-06 20:46:33.765852+00	reshma  pststaff	\N	\N	\N	\N	\N	\N	3041b905-c650-4e0d-9745-b013d8fab1bd	\N
1003	\N	2026-03-06 20:46:33.966097+00	2026-03-06 20:46:33.966097+00	residency oyo ch velacheri	\N	\N	\N	\N	\N	\N	9aceb4d6-cfa9-4316-aec2-18e60b1886a6	\N
1004	\N	2026-03-06 20:46:34.1043+00	2026-03-06 20:46:34.1043+00	Rubini  Project	\N	\N	\N	\N	\N	\N	100eff83-5504-4df8-b9b4-915a8fed5bb6	\N
1005	\N	2026-03-06 20:46:34.197601+00	2026-03-06 20:46:34.197601+00	s.velmurugan asan lodge kdnl	\N	\N	\N	\N	\N	\N	2780fdf7-07b5-4d5b-b659-9b33790011fa	\N
1006	\N	2026-03-06 20:46:34.282385+00	2026-03-06 20:46:34.282385+00	sabari  2	\N	\N	\N	\N	\N	\N	5da29a0e-3583-4e27-8e51-1e5bf162b464	\N
1007	\N	2026-03-06 20:46:34.378048+00	2026-03-06 20:46:34.378048+00	sabari  pst	\N	\N	\N	\N	\N	\N	0825e50f-e69e-4c34-b2a1-a504ad5db916	\N
1008	\N	2026-03-06 20:46:34.51108+00	2026-03-06 20:46:34.51108+00	Sahul  halith	\N	\N	\N	\N	\N	\N	316b6eef-de49-45e6-9c1c-8cb97a5990f6	\N
1009	\N	2026-03-06 20:46:34.639629+00	2026-03-06 20:46:34.639629+00	Sahul wapp. hali	\N	\N	\N	\N	\N	\N	fde8e344-4c8a-44a9-a41c-5b4ff9401ed3	\N
1010	\N	2026-03-06 20:46:34.764851+00	2026-03-06 20:46:34.764851+00	Sahul  zumana	\N	\N	\N	\N	\N	\N	03929520-eafe-48e2-afdd-c1b67e00d573	\N
1011	\N	2026-03-06 20:46:34.885721+00	2026-03-06 20:46:34.885721+00	SAM DAVIDRAJAS st group poly in2	\N	\N	\N	\N	\N	\N	8e6775e4-08e4-4860-9594-74d9a4748b31	\N
1012	\N	2026-03-06 20:46:34.982767+00	2026-03-06 20:46:34.982767+00	Samraj	\N	\N	\N	\N	\N	\N	b135b684-3b99-4f1d-97fa-2739fa4191b3	\N
1013	\N	2026-03-06 20:46:35.070503+00	2026-03-06 20:46:35.070503+00	Samraj  2	\N	\N	\N	\N	\N	\N	3bdc3038-38c6-4391-ba1f-bed401533cde	\N
1014	\N	2026-03-06 20:46:35.171674+00	2026-03-06 20:46:35.171674+00	sangli pstoffice	\N	\N	\N	\N	\N	\N	ab48458a-f84b-4eb2-883e-4c6eec875a76	\N
1015	\N	2026-03-06 20:46:35.296243+00	2026-03-06 20:46:35.296243+00	sangli pstoffice 2	\N	\N	\N	\N	\N	\N	02ca1379-6013-4a3f-ba9a-0815cb243c81	\N
1016	\N	2026-03-06 20:46:35.431126+00	2026-03-06 20:46:35.431126+00	Sankar	\N	\N	\N	\N	\N	\N	236d418d-2843-4675-ba47-941b1303df12	\N
1017	\N	2026-03-06 20:46:35.559798+00	2026-03-06 20:46:35.559798+00	sankar  machan	\N	\N	\N	\N	\N	\N	fd45047d-e066-4e64-ad58-1c78278e566f	\N
1018	\N	2026-03-06 20:46:35.690101+00	2026-03-06 20:46:35.690101+00	sankaralingam	\N	\N	\N	\N	\N	\N	8b99dff4-dee2-4c8f-9ec3-8514562f22e9	\N
1019	\N	2026-03-06 20:46:35.786915+00	2026-03-06 20:46:35.786915+00	Sara  office	\N	\N	\N	\N	\N	\N	6b10b92c-f563-4076-a5b9-610dc2e98260	\N
1020	\N	2026-03-06 20:46:35.878539+00	2026-03-06 20:46:35.878539+00	Sarabuthin	\N	\N	\N	\N	\N	\N	5894510c-4b67-4a7a-b83c-51ceef194868	\N
1021	\N	2026-03-06 20:46:35.978772+00	2026-03-06 20:46:35.978772+00	Sarabutin  2	\N	\N	\N	\N	\N	\N	087ffc8c-d6b4-44c2-a11b-0a47df89f265	\N
1022	\N	2026-03-06 20:46:36.105041+00	2026-03-06 20:46:36.105041+00	SARATH  2	\N	\N	\N	\N	\N	\N	6c909643-1631-4737-9784-7a781e271a8e	\N
1023	\N	2026-03-06 20:46:36.240262+00	2026-03-06 20:46:36.240262+00	Sarath  Jio	\N	\N	\N	\N	\N	\N	4228cf7e-f5e7-4943-b82c-16f32aefe73f	\N
1024	\N	2026-03-06 20:46:36.364153+00	2026-03-06 20:46:36.364153+00	Sarath  sir	\N	\N	\N	\N	\N	\N	016750ac-36ab-4e81-b42f-b9842a895158	\N
1025	\N	2026-03-06 20:46:36.486961+00	2026-03-06 20:46:36.486961+00	sarath sir brother kerala	\N	\N	\N	\N	\N	\N	d9f245c0-b669-455f-b3cd-115d6e366677	\N
1026	\N	2026-03-06 20:46:36.58478+00	2026-03-06 20:46:36.58478+00	Saravanan abmatri	\N	\N	\N	\N	\N	\N	102f80da-e1ad-4ca9-8fb6-3a88102e4d06	\N
1027	\N	2026-03-06 20:46:36.674564+00	2026-03-06 20:46:36.674564+00	saravanan sir sasuri	\N	\N	\N	\N	\N	\N	4cfd36fa-743e-4bde-a075-eed632fb3135	\N
1028	\N	2026-03-06 20:46:36.774933+00	2026-03-06 20:46:36.774933+00	satham pstoffice	\N	\N	\N	\N	\N	\N	17ebe2f9-8f8a-4471-b029-43976ae69092	\N
1029	\N	2026-03-06 20:46:36.899232+00	2026-03-06 20:46:36.899232+00	sathyan. arun cib reference	\N	\N	\N	\N	\N	\N	05df98d0-3a58-40a8-bc2d-bf61a69fabed	\N
1030	\N	2026-03-06 20:46:37.022089+00	2026-03-06 20:46:37.022089+00	Savith mam soel ug office	\N	\N	\N	\N	\N	\N	8a4c4614-a7dc-43da-b241-e7ba3112a9d7	\N
1031	\N	2026-03-06 20:46:37.15176+00	2026-03-06 20:46:37.15176+00	School  ananth	\N	\N	\N	\N	\N	\N	0056b33b-9f3f-4fc3-915d-2dc759cef186	\N
1032	\N	2026-03-06 20:46:37.258061+00	2026-03-06 20:46:37.258061+00	Seetha Lakshmi Mam Library svn pstclient	\N	\N	\N	\N	\N	\N	a66c0a27-adc3-4616-9be4-d4f81adf9abc	\N
1033	\N	2026-03-06 20:46:37.34793+00	2026-03-06 20:46:37.34793+00	Seetharaman Sir Ccavenue	\N	\N	\N	\N	\N	\N	f2b77246-2f05-4e79-b973-542c22f21fcf	\N
1034	\N	2026-03-06 20:46:37.441422+00	2026-03-06 20:46:37.441422+00	Selva	\N	\N	\N	\N	\N	\N	9fd1011f-60d7-4a78-bec7-6febeb10acc8	\N
1035	\N	2026-03-06 20:46:37.559181+00	2026-03-06 20:46:37.559181+00	selva kerala 2	\N	\N	\N	\N	\N	\N	2c5c70c3-3794-42d2-991a-71a2cebc1f0a	\N
1036	\N	2026-03-06 20:46:37.677173+00	2026-03-06 20:46:37.677173+00	Selva  sand	\N	\N	\N	\N	\N	\N	bfcdc456-6ea4-4279-91f6-2669f524e9df	\N
1037	\N	2026-03-06 20:46:37.796742+00	2026-03-06 20:46:37.796742+00	selvakumar  kerala	\N	\N	\N	\N	\N	\N	30c0e56f-9a5b-455d-9757-7120483d1793	\N
1038	\N	2026-03-06 20:46:37.92576+00	2026-03-06 20:46:37.92576+00	Selvakumar  vpp	\N	\N	\N	\N	\N	\N	061197a7-3450-4e7f-9060-7118fae971d8	\N
1039	\N	2026-03-06 20:46:38.035484+00	2026-03-06 20:46:38.035484+00	Selvam	\N	\N	\N	\N	\N	\N	b07c77e0-a7ed-4cc1-b4b9-655738ee28f9	\N
1040	\N	2026-03-06 20:46:38.145219+00	2026-03-06 20:46:38.145219+00	Selvam  gas	\N	\N	\N	\N	\N	\N	de536583-18ec-4164-a56a-9910a4bf6632	\N
1041	\N	2026-03-06 20:46:38.232799+00	2026-03-06 20:46:38.232799+00	Selvam house Ow	\N	\N	\N	\N	\N	\N	03f229b5-5dc3-473c-a204-c6b03e358fce	\N
1042	\N	2026-03-06 20:46:38.358675+00	2026-03-06 20:46:38.358675+00	selvam junction vetrilai shop	\N	\N	\N	\N	\N	\N	36ee6968-a98a-4e2c-862f-293dbaa8e718	\N
1043	\N	2026-03-06 20:46:38.489013+00	2026-03-06 20:46:38.489013+00	Selvganpa  jdial	\N	\N	\N	\N	\N	\N	4588f4a7-5474-4704-a9a0-3b69746c2c09	\N
1044	\N	2026-03-06 20:46:38.630567+00	2026-03-06 20:46:38.630567+00	Senbaga meenakshi svn psclient	\N	\N	\N	\N	\N	\N	5cf44e4e-3ad6-492f-8efb-937ee6ec744e	\N
1045	\N	2026-03-06 20:46:38.750981+00	2026-03-06 20:46:38.750981+00	senthil vadivu spc pstclient	\N	\N	\N	\N	\N	\N	4889da98-00fe-4666-8b2d-77e22b2d10fa	\N
1046	\N	2026-03-06 20:46:38.857717+00	2026-03-06 20:46:38.857717+00	Senthilkumar Anjac Pstclient	\N	\N	\N	\N	\N	\N	4451d4b6-1234-4158-9a3e-bf4b4dcec293	\N
1047	\N	2026-03-06 20:46:38.965586+00	2026-03-06 20:46:38.965586+00	Service  kumar	\N	\N	\N	\N	\N	\N	eedf801b-4b4a-430f-b2bc-7051598aa9eb	\N
1048	\N	2026-03-06 20:46:39.125737+00	2026-03-06 20:46:39.125737+00	Service  pugazh	\N	\N	\N	\N	\N	\N	7ee53988-03ec-40bc-a7ce-ea5035926b05	\N
1049	\N	2026-03-06 20:46:39.334122+00	2026-03-06 20:46:39.334122+00	Shakeel Glc Madurai biometric	\N	\N	\N	\N	\N	\N	14ead2e2-afe6-4bae-9f54-6801dc426bec	\N
1050	\N	2026-03-06 20:46:39.526281+00	2026-03-06 20:46:39.526281+00	Shankar Has Aca	\N	\N	\N	\N	\N	\N	83287916-b10a-4f10-b85f-4afc2405fe2b	\N
1051	\N	2026-03-06 20:46:39.737777+00	2026-03-06 20:46:39.737777+00	shanmuga priya mam anjac pstclient	\N	\N	\N	\N	\N	\N	2d45114a-aa00-4001-9aff-8233d60128fd	\N
1052	\N	2026-03-06 20:46:39.900709+00	2026-03-06 20:46:39.900709+00	Shanthi  Akka	\N	\N	\N	\N	\N	\N	8eb632e7-c07d-45fa-88bc-637fe6ac6952	\N
1053	\N	2026-03-06 20:46:39.990364+00	2026-03-06 20:46:39.990364+00	shanthi mam kallanai	\N	\N	\N	\N	\N	\N	6635fddf-91d9-4339-8ee9-1d34aa65665c	\N
1054	\N	2026-03-06 20:46:40.075747+00	2026-03-06 20:46:40.075747+00	Sheik pstoffice	\N	\N	\N	\N	\N	\N	f8ac4e5c-9453-464f-8436-d749f8e42221	\N
1055	\N	2026-03-06 20:46:40.180931+00	2026-03-06 20:46:40.180931+00	Sheik  soudi	\N	\N	\N	\N	\N	\N	3d3cb233-ad77-4038-9e21-fbe3112a158e	\N
1056	\N	2026-03-06 20:46:40.297757+00	2026-03-06 20:46:40.297757+00	shibani fashion 2	\N	\N	\N	\N	\N	\N	65c235f7-826c-4b9c-8a4c-aafbeeb7334e	\N
1057	\N	2026-03-06 20:46:40.426584+00	2026-03-06 20:46:40.426584+00	shivani  daughter	\N	\N	\N	\N	\N	\N	07fe1360-59b5-4887-9e4b-b0e0ac90872b	\N
1058	\N	2026-03-06 20:46:40.565733+00	2026-03-06 20:46:40.565733+00	Shyam  bb	\N	\N	\N	\N	\N	\N	e8abbea2-3f86-4841-b2d9-d3c80af44273	\N
1059	\N	2026-03-06 20:46:40.682569+00	2026-03-06 20:46:40.682569+00	Sibu  chendamela	\N	\N	\N	\N	\N	\N	bbd4514c-6348-4b7e-91cc-dd093ef7b902	\N
1060	\N	2026-03-06 20:46:40.774846+00	2026-03-06 20:46:40.774846+00	sinduja soel prof	\N	\N	\N	\N	\N	\N	78b5f392-ccdb-4ca9-8fb7-780a8c306311	\N
1061	\N	2026-03-06 20:46:40.864385+00	2026-03-06 20:46:40.864385+00	Sir	\N	\N	\N	\N	\N	\N	ae1415ea-3b90-427c-a574-daa2bbd98bd8	\N
1062	\N	2026-03-06 20:46:40.976655+00	2026-03-06 20:46:40.976655+00	sister vannarpettai gh	\N	\N	\N	\N	\N	\N	5e650a7d-645a-4e26-9198-722f046b5c1f	\N
1063	\N	2026-03-06 20:46:41.094968+00	2026-03-06 20:46:41.094968+00	siththi pudukkottai	\N	\N	\N	\N	\N	\N	37026b49-c7ca-4dee-b6ad-f255f9ac1c32	\N
1064	\N	2026-03-06 20:46:41.215209+00	2026-03-06 20:46:41.215209+00	Siva  itech	\N	\N	\N	\N	\N	\N	38958381-ae4e-4276-bde6-fd1d9ec52895	\N
1065	\N	2026-03-06 20:46:41.349613+00	2026-03-06 20:46:41.349613+00	Siva  Office	\N	\N	\N	\N	\N	\N	48b5ae71-eb93-42c7-942b-3c6a6e3afa6d	\N
1066	\N	2026-03-06 20:46:41.460045+00	2026-03-06 20:46:41.460045+00	Sivakasi,vijaya	\N	\N	\N	\N	\N	\N	62cd99a2-caad-4788-b2e6-b07fd8842e33	\N
1067	\N	2026-03-06 20:46:41.560327+00	2026-03-06 20:46:41.560327+00	sivalingam bbb 2	\N	\N	\N	\N	\N	\N	24fd6163-ec1a-47cf-b633-018b3c5d6ef3	\N
1068	\N	2026-03-06 20:46:41.664973+00	2026-03-06 20:46:41.664973+00	sn cars rental	\N	\N	\N	\N	\N	\N	67d9ac36-ec25-415d-a76b-799674e2fb77	\N
1069	\N	2026-03-06 20:46:41.797078+00	2026-03-06 20:46:41.797078+00	soel  3	\N	\N	\N	\N	\N	\N	abeb7f0d-4638-42f2-86bc-82607fa3b2f8	\N
1070	\N	2026-03-06 20:46:41.912168+00	2026-03-06 20:46:41.912168+00	soel cs dept	\N	\N	\N	\N	\N	\N	44ed96f9-b10e-4976-a2bb-cd4c005a79b9	\N
1071	\N	2026-03-06 20:46:42.030245+00	2026-03-06 20:46:42.030245+00	soel guest faculty	\N	\N	\N	\N	\N	\N	082197a5-f158-4360-884e-caa4104c9821	\N
1072	\N	2026-03-06 20:46:42.154903+00	2026-03-06 20:46:42.154903+00	soel prof 3	\N	\N	\N	\N	\N	\N	accc84c7-9b79-49ff-aa7d-efd9f858dd93	\N
1073	\N	2026-03-06 20:46:42.261443+00	2026-03-06 20:46:42.261443+00	soel  staff5	\N	\N	\N	\N	\N	\N	19a9e396-1e4c-4497-be9c-e7da002404c0	\N
1074	\N	2026-03-06 20:46:42.349253+00	2026-03-06 20:46:42.349253+00	soel  student	\N	\N	\N	\N	\N	\N	b34c332f-0ca0-4eca-99f5-ae4ddb0da7ae	\N
1076	\N	2026-03-06 20:46:42.562936+00	2026-03-06 20:46:42.562936+00	spc admission rg pstclient	\N	\N	\N	\N	\N	\N	d1b82235-9377-4e6c-b0a9-fe3e63cc717c	\N
1077	\N	2026-03-06 20:46:42.697817+00	2026-03-06 20:46:42.697817+00	spc clg 3 pstclient	\N	\N	\N	\N	\N	\N	285a8598-df0c-4777-90cf-16f82a950a03	\N
1078	\N	2026-03-06 20:46:42.817181+00	2026-03-06 20:46:42.817181+00	spc clg self pstclient	\N	\N	\N	\N	\N	\N	1e60c855-43f5-4af6-9eaa-1f853321dbf4	\N
1079	\N	2026-03-06 20:46:42.934324+00	2026-03-06 20:46:42.934324+00	spc coe assist pstclient	\N	\N	\N	\N	\N	\N	d287ce70-d272-434b-a9d3-7a2b320e6eaf	\N
1080	\N	2026-03-06 20:46:43.045714+00	2026-03-06 20:46:43.045714+00	spc msc it mam 2 pstclient	\N	\N	\N	\N	\N	\N	9d80713a-066f-45d8-831e-00cec7fa027f	\N
1081	\N	2026-03-06 20:46:43.130295+00	2026-03-06 20:46:43.130295+00	spc msc it mam pstclient	\N	\N	\N	\N	\N	\N	1ba2ae83-029b-45ee-a91a-153fd36da7f6	\N
1082	\N	2026-03-06 20:46:43.218829+00	2026-03-06 20:46:43.218829+00	spc office malliga pstclient	\N	\N	\N	\N	\N	\N	f44f3d66-876e-40de-9f89-103ce2054ecd	\N
1083	\N	2026-03-06 20:46:43.332905+00	2026-03-06 20:46:43.332905+00	spc pta pstclient	\N	\N	\N	\N	\N	\N	be62cf9e-9216-415e-8861-97c79190affc	\N
1084	\N	2026-03-06 20:46:43.468839+00	2026-03-06 20:46:43.468839+00	spc Rajaselvarani pstclient	\N	\N	\N	\N	\N	\N	34ea2ba7-2777-4f47-933c-293443f2f7dc	\N
1085	\N	2026-03-06 20:46:43.603783+00	2026-03-06 20:46:43.603783+00	spc renuka library pstclient	\N	\N	\N	\N	\N	\N	2af2978c-23b1-4f4a-848a-9b574fbb02b9	\N
1086	\N	2026-03-06 20:46:43.724412+00	2026-03-06 20:46:43.724412+00	spc rg mam	\N	\N	\N	\N	\N	\N	7f7093cb-0686-403e-b545-d41a6fcda663	\N
1087	\N	2026-03-06 20:46:43.820116+00	2026-03-06 20:46:43.820116+00	spc subbulakshmi self pstclient	\N	\N	\N	\N	\N	\N	ab1d0bf0-3708-4e91-a14a-40c1a1fb7281	\N
1088	\N	2026-03-06 20:46:43.911735+00	2026-03-06 20:46:43.911735+00	spc subburaj sir pstclient	\N	\N	\N	\N	\N	\N	08061025-af0a-41e4-859c-709cda5764d7	\N
1089	\N	2026-03-06 20:46:43.99895+00	2026-03-06 20:46:43.99895+00	spc thilaga mam sf pstclient	\N	\N	\N	\N	\N	\N	86cc1465-f12a-4307-be3a-31f6d3117bdf	\N
1090	\N	2026-03-06 20:46:44.123117+00	2026-03-06 20:46:44.123117+00	Sripriya	\N	\N	\N	\N	\N	\N	122fdd1a-035f-4ae1-a019-2766e9c6635d	\N
1091	\N	2026-03-06 20:46:44.246948+00	2026-03-06 20:46:44.246948+00	Sripriya  land	\N	\N	\N	\N	\N	\N	af12d017-79cd-4c6f-886d-9e30a52a54d6	\N
1092	\N	2026-03-06 20:46:44.377059+00	2026-03-06 20:46:44.377059+00	Sripriya  Sasika	\N	\N	\N	\N	\N	\N	e347bce0-1eb0-4007-83da-10f627d09685	\N
1093	\N	2026-03-06 20:46:44.489923+00	2026-03-06 20:46:44.489923+00	Sriram  2	\N	\N	\N	\N	\N	\N	5cc1737c-54de-47b6-ad79-9274b6491506	\N
1094	\N	2026-03-06 20:46:44.616456+00	2026-03-06 20:46:44.616456+00	Sriram  chits	\N	\N	\N	\N	\N	\N	76421d5f-015a-42e1-8a11-62731a97aac6	\N
1095	\N	2026-03-06 20:46:44.705711+00	2026-03-06 20:46:44.705711+00	Sriram  saravana	\N	\N	\N	\N	\N	\N	7c2e6bbd-d80a-4312-ab67-f4a97f73ed0b	\N
1096	\N	2026-03-06 20:46:44.797973+00	2026-03-06 20:46:44.797973+00	stc antony sir 2	\N	\N	\N	\N	\N	\N	1043addf-1173-49b5-bb51-d6e8ceb5dbf1	\N
1097	\N	2026-03-06 20:46:44.962692+00	2026-03-06 20:46:44.962692+00	stc librarian pstclient	\N	\N	\N	\N	\N	\N	81375c26-9b9d-4a5c-977f-19233676538f	\N
1098	\N	2026-03-06 20:46:45.153327+00	2026-03-06 20:46:45.153327+00	stc ruby mam pstclient	\N	\N	\N	\N	\N	\N	e8a9f929-b8c6-49db-a44b-20840f1c2efe	\N
1099	\N	2026-03-06 20:46:45.38185+00	2026-03-06 20:46:45.38185+00	stc subathra adm pstclient	\N	\N	\N	\N	\N	\N	7a2d70a9-28fb-42d5-a48a-72c33e620797	\N
1100	\N	2026-03-06 20:46:45.557239+00	2026-03-06 20:46:45.557239+00	stc subha coe pstclient	\N	\N	\N	\N	\N	\N	fad64fcc-09bc-4a85-a533-653b6de7a9d5	\N
1101	\N	2026-03-06 20:46:45.73371+00	2026-03-06 20:46:45.73371+00	Stephan	\N	\N	\N	\N	\N	\N	0ffe2590-b049-4fb2-90a9-281aa5ab6c33	\N
1102	\N	2026-03-06 20:46:45.84597+00	2026-03-06 20:46:45.84597+00	Stephan  2	\N	\N	\N	\N	\N	\N	796ed1fb-89ae-491d-a2c1-bb71ac3f1dea	\N
1103	\N	2026-03-06 20:46:45.943615+00	2026-03-06 20:46:45.943615+00	stephan 2f 2	\N	\N	\N	\N	\N	\N	7077e68c-2e47-433c-bd15-df01f0ea93af	\N
1104	\N	2026-03-06 20:46:46.071966+00	2026-03-06 20:46:46.071966+00	stephan now 2	\N	\N	\N	\N	\N	\N	ad898da8-46c1-4a48-a1a5-cdb75cf07fb9	\N
1105	\N	2026-03-06 20:46:46.200375+00	2026-03-06 20:46:46.200375+00	Sticker	\N	\N	\N	\N	\N	\N	015ce899-3576-4c46-9b8a-2a679720e2b1	\N
1106	\N	2026-03-06 20:46:46.321583+00	2026-03-06 20:46:46.321583+00	Stock  Update	\N	\N	\N	\N	\N	\N	20a8b422-4045-4def-a70f-046ac925829d	\N
1107	\N	2026-03-06 20:46:46.432857+00	2026-03-06 20:46:46.432857+00	Studio  order	\N	\N	\N	\N	\N	\N	003e7994-c697-4f98-acc7-cfa93157e0ff	\N
1108	\N	2026-03-06 20:46:46.523601+00	2026-03-06 20:46:46.523601+00	Subash Subash thangapazham warden	\N	\N	\N	\N	\N	\N	e417d251-243d-4863-b3e6-3bfb747dd844	\N
1109	\N	2026-03-06 20:46:46.613253+00	2026-03-06 20:46:46.613253+00	Subbiah pstoffice	\N	\N	\N	\N	\N	\N	5755d68d-24e9-4c3a-88fd-ace2a518e996	\N
1110	\N	2026-03-06 20:46:46.712351+00	2026-03-06 20:46:46.712351+00	sudalai manickam  manickam	\N	\N	\N	\N	\N	\N	6eea5856-fc08-45eb-90ef-a8303723292f	\N
1111	\N	2026-03-06 20:46:46.848909+00	2026-03-06 20:46:46.848909+00	Sudalai Mathi stgroup law incharge	\N	\N	\N	\N	\N	\N	d306b96c-c791-4d1d-8021-ceefa41214c8	\N
1112	\N	2026-03-06 20:46:46.971765+00	2026-03-06 20:46:46.971765+00	sudharson  dxc	\N	\N	\N	\N	\N	\N	0191a5d1-c2c2-4b63-aee1-f13d985ed0e7	\N
1113	\N	2026-03-06 20:46:47.093255+00	2026-03-06 20:46:47.093255+00	sudhas kerala	\N	\N	\N	\N	\N	\N	9f3dea57-e332-4207-b733-2c257b3eb4b0	\N
1114	\N	2026-03-06 20:46:47.20582+00	2026-03-06 20:46:47.20582+00	sugumar puliyarai	\N	\N	\N	\N	\N	\N	93df111f-0117-4899-a758-bd7e50b0ad95	\N
1115	\N	2026-03-06 20:46:47.297384+00	2026-03-06 20:46:47.297384+00	sumaiya  helixsense	\N	\N	\N	\N	\N	\N	6e3b55aa-a726-4411-b20e-ca839ba66f40	\N
1116	\N	2026-03-06 20:46:47.389263+00	2026-03-06 20:46:47.389263+00	sumathi com help desk sneka hos	\N	\N	\N	\N	\N	\N	40cd8c1f-13d8-4261-9489-c1dde5e4bc0d	\N
1117	\N	2026-03-06 20:46:47.490468+00	2026-03-06 20:46:47.490468+00	sundaram  helixsense	\N	\N	\N	\N	\N	\N	004a52be-ff6f-4832-92fb-0b62094e53e2	\N
1118	\N	2026-03-06 20:46:47.637211+00	2026-03-06 20:46:47.637211+00	Suresh  vpp	\N	\N	\N	\N	\N	\N	3725813a-4547-4d34-948c-2b6f6c9f6dc7	\N
1119	\N	2026-03-06 20:46:47.766233+00	2026-03-06 20:46:47.766233+00	Suresh  Water	\N	\N	\N	\N	\N	\N	ec3545b7-2ee3-4073-ab9d-485020b6a2e8	\N
1120	\N	2026-03-06 20:46:47.891501+00	2026-03-06 20:46:47.891501+00	Surya pstoffice	\N	\N	\N	\N	\N	\N	fa986aba-abf7-41bf-b5ec-7a5be5190356	\N
1121	\N	2026-03-06 20:46:48.00676+00	2026-03-06 20:46:48.00676+00	Susila  kerala	\N	\N	\N	\N	\N	\N	3d46a8e4-190e-47cf-887d-a8a771cc79e0	\N
1122	\N	2026-03-06 20:46:48.09479+00	2026-03-06 20:46:48.09479+00	svn college vinoth sir	\N	\N	\N	\N	\N	\N	89b0dcd6-436a-4a57-9557-878176bbea8e	\N
1123	\N	2026-03-06 20:46:48.177571+00	2026-03-06 20:46:48.177571+00	swetha alagappa univ	\N	\N	\N	\N	\N	\N	8ad7aef4-7ede-4083-a56b-920f5e1158fd	\N
1124	\N	2026-03-06 20:46:48.275927+00	2026-03-06 20:46:48.275927+00	Swetha  tvl	\N	\N	\N	\N	\N	\N	e3ad6b4b-27c7-461d-92a1-a6d12f2b8d81	\N
1125	\N	2026-03-06 20:46:48.399946+00	2026-03-06 20:46:48.399946+00	Syamala	\N	\N	\N	\N	\N	\N	aa000d72-d7e5-4460-a9aa-99c4dbdd04ac	\N
1126	\N	2026-03-06 20:46:48.635143+00	2026-03-06 20:46:48.635143+00	Syed  Lodge	\N	\N	\N	\N	\N	\N	6a1fb371-c39f-449b-b973-fa09b7b7b55d	\N
1127	\N	2026-03-06 20:46:48.76413+00	2026-03-06 20:46:48.76413+00	syed sulaiman .asan.kdnl	\N	\N	\N	\N	\N	\N	3baa98e3-df5f-4ddb-8894-37a8338aca0e	\N
1128	\N	2026-03-06 20:46:48.885413+00	2026-03-06 20:46:48.885413+00	Tailor	\N	\N	\N	\N	\N	\N	86399628-639a-40f2-b91e-80e9efc890fe	\N
1129	\N	2026-03-06 20:46:48.979334+00	2026-03-06 20:46:48.979334+00	tailor  now	\N	\N	\N	\N	\N	\N	f52b007f-c045-4e64-9e67-fbcda32bab2b	\N
1130	\N	2026-03-06 20:46:49.085355+00	2026-03-06 20:46:49.085355+00	tdmns  admission	\N	\N	\N	\N	\N	\N	00f5b224-a15a-458d-87eb-54d74f27e375	\N
1131	\N	2026-03-06 20:46:49.193011+00	2026-03-06 20:46:49.193011+00	tdmns  allen	\N	\N	\N	\N	\N	\N	7ec791d9-3039-4149-98a2-d337aeea4af3	\N
1132	\N	2026-03-06 20:46:49.316979+00	2026-03-06 20:46:49.316979+00	tdmns  kanaka	\N	\N	\N	\N	\N	\N	c4a2c0d2-1773-4c2c-931b-22e29c52e182	\N
1133	\N	2026-03-06 20:46:49.433613+00	2026-03-06 20:46:49.433613+00	tdmns lakshmi kannan	\N	\N	\N	\N	\N	\N	abac2229-8574-448c-9702-6a6edc4757e9	\N
1134	\N	2026-03-06 20:46:49.561028+00	2026-03-06 20:46:49.561028+00	tdmns  landline	\N	\N	\N	\N	\N	\N	4630d5d4-ad9b-4e37-ab82-49f6b9d79530	\N
1135	\N	2026-03-06 20:46:49.679291+00	2026-03-06 20:46:49.679291+00	tdmns library catherin	\N	\N	\N	\N	\N	\N	2c72ec6f-7186-48a6-ad22-c4ba04c29b5a	\N
1136	\N	2026-03-06 20:46:49.772194+00	2026-03-06 20:46:49.772194+00	tdmns library Catherin Beula 2	\N	\N	\N	\N	\N	\N	b13002e0-18f3-4507-8c7f-3c8ebe2f0cff	\N
1137	\N	2026-03-06 20:46:49.860474+00	2026-03-06 20:46:49.860474+00	tdmns library manju	\N	\N	\N	\N	\N	\N	2becbd2e-a571-4a5a-9469-7aad23944ea7	\N
1138	\N	2026-03-06 20:46:49.976047+00	2026-03-06 20:46:49.976047+00	tdmns store mam	\N	\N	\N	\N	\N	\N	04ecea82-7a68-416a-8c99-0251ebef90fa	\N
1139	\N	2026-03-06 20:46:50.105082+00	2026-03-06 20:46:50.105082+00	tdmns store mam new	\N	\N	\N	\N	\N	\N	94738f21-db9e-4104-8584-43f40c696559	\N
1140	\N	2026-03-06 20:46:50.221726+00	2026-03-06 20:46:50.221726+00	tenkasi yni	\N	\N	\N	\N	\N	\N	22ae7015-92d4-4744-ad5e-e6b84f82b38e	\N
1141	\N	2026-03-06 20:46:50.388674+00	2026-03-06 20:46:50.388674+00	tenkasi yni agnt man	\N	\N	\N	\N	\N	\N	2a21cfff-25f9-4176-9bb3-317c9f44cd70	\N
1142	\N	2026-03-06 20:46:50.496772+00	2026-03-06 20:46:50.496772+00	thangapazham principal subramanian	\N	\N	\N	\N	\N	\N	76048cc7-91a9-4cdf-877e-a31e69d59acb	\N
1143	\N	2026-03-06 20:46:50.592835+00	2026-03-06 20:46:50.592835+00	thangavel  mama	\N	\N	\N	\N	\N	\N	8cf18e65-b146-40d7-aee9-4810bb8a5576	\N
1144	\N	2026-03-06 20:46:50.69131+00	2026-03-06 20:46:50.69131+00	Thirunavukkarasu stgroup psclient	\N	\N	\N	\N	\N	\N	7441082d-a96b-43ab-bd2a-3d8fce22ff4b	\N
1145	\N	2026-03-06 20:46:50.846987+00	2026-03-06 20:46:50.846987+00	thurgambiga lodge highground	\N	\N	\N	\N	\N	\N	e806a06c-6da6-4dbd-a941-caa6e29d6cb8	\N
1146	\N	2026-03-06 20:46:51.016254+00	2026-03-06 20:46:51.016254+00	tnpesu sasi sir	\N	\N	\N	\N	\N	\N	2d3abadc-7a41-462e-a3a5-bd5fc95467bb	\N
1147	\N	2026-03-06 20:46:51.237391+00	2026-03-06 20:46:51.237391+00	Tntj	\N	\N	\N	\N	\N	\N	609c218c-4cf8-4297-a533-1aef3e501743	\N
1148	\N	2026-03-06 20:46:51.425142+00	2026-03-06 20:46:51.425142+00	UIDAI	\N	\N	\N	\N	\N	\N	eed28bf2-ad18-49ae-b4f0-cbee064594a4	\N
1149	\N	2026-03-06 20:46:51.567155+00	2026-03-06 20:46:51.567155+00	Umar	\N	\N	\N	\N	\N	\N	587a2158-0136-4e35-8c27-86907fca1726	\N
1150	\N	2026-03-06 20:46:51.698424+00	2026-03-06 20:46:51.698424+00	uthayamani  soel	\N	\N	\N	\N	\N	\N	bc2b9c23-2a64-4a21-a7a6-a64a67538741	\N
1152	\N	2026-03-06 20:46:51.935573+00	2026-03-06 20:46:51.935573+00	vainav sir helixsense	\N	\N	\N	\N	\N	\N	bccdacb1-f8bd-4704-a435-db31927e8854	\N
1153	\N	2026-03-06 20:46:52.063062+00	2026-03-06 20:46:52.063062+00	valli mam soel	\N	\N	\N	\N	\N	\N	07f1a8e0-7a64-488f-a8a7-d4128f7399fe	\N
1154	\N	2026-03-06 20:46:52.176784+00	2026-03-06 20:46:52.176784+00	vc stjudechurch	\N	\N	\N	\N	\N	\N	b805a6f1-0806-4575-ab0c-5a99f3dd4765	\N
1155	\N	2026-03-06 20:46:52.267475+00	2026-03-06 20:46:52.267475+00	velammal spc pstclient	\N	\N	\N	\N	\N	\N	c5a87bbf-484d-44c1-ae30-e374e65f9153	\N
1156	\N	2026-03-06 20:46:52.350661+00	2026-03-06 20:46:52.350661+00	VENGATESH anjac  KUMAR	\N	\N	\N	\N	\N	\N	09be3c7a-1ace-4a0f-99e0-e038d6aea1be	\N
1157	\N	2026-03-06 20:46:52.474801+00	2026-03-06 20:46:52.474801+00	venkateshwari apex	\N	\N	\N	\N	\N	\N	decac1b4-2c75-4821-8412-70c473394a86	\N
1158	\N	2026-03-06 20:46:52.601918+00	2026-03-06 20:46:52.601918+00	vennila mam balagan saras clg	\N	\N	\N	\N	\N	\N	581d7ed6-3616-4c0e-8281-5ff1d7b1fbe9	\N
1159	\N	2026-03-06 20:46:52.732476+00	2026-03-06 20:46:52.732476+00	Vetha pstoffice	\N	\N	\N	\N	\N	\N	59581b83-ffd0-42c6-b3f8-adef4330f0b6	\N
1160	\N	2026-03-06 20:46:52.859089+00	2026-03-06 20:46:52.859089+00	vetrivel sir vsn mdu	\N	\N	\N	\N	\N	\N	4816dce3-fb0c-4b1e-accc-937e1e821598	\N
1161	\N	2026-03-06 20:46:52.979866+00	2026-03-06 20:46:52.979866+00	Victor Jesudoss xavier att aided	\N	\N	\N	\N	\N	\N	946f73db-7e19-475c-9147-45f4d42a09c2	\N
1162	\N	2026-03-06 20:46:53.069969+00	2026-03-06 20:46:53.069969+00	Vigneshwaran	\N	\N	\N	\N	\N	\N	27ba0ee0-1ef2-426f-aad2-87bcf2b254b0	\N
1163	\N	2026-03-06 20:46:53.159775+00	2026-03-06 20:46:53.159775+00	Vinoth pstoffice  Solomon	\N	\N	\N	\N	\N	\N	3334f2e1-7afa-4784-9167-2a7ba86869da	\N
1164	\N	2026-03-06 20:46:53.266329+00	2026-03-06 20:46:53.266329+00	vinoth  soel	\N	\N	\N	\N	\N	\N	2f26a141-4f89-442e-9020-d821b8207733	\N
1165	\N	2026-03-06 20:46:53.412312+00	2026-03-06 20:46:53.412312+00	Virumandy svn psclient	\N	\N	\N	\N	\N	\N	e12773f5-b154-4a80-9460-a987b0992205	\N
1166	\N	2026-03-06 20:46:53.540959+00	2026-03-06 20:46:53.540959+00	vishnu dam	\N	\N	\N	\N	\N	\N	a74a6435-4eaa-4068-b944-b19b17dce89b	\N
1167	\N	2026-03-06 20:46:53.675951+00	2026-03-06 20:46:53.675951+00	vivek  helixsense	\N	\N	\N	\N	\N	\N	229bbaab-a189-4d59-a387-5e6606dc827d	\N
1168	\N	2026-03-06 20:46:53.79004+00	2026-03-06 20:46:53.79004+00	Vivekanandan st group plytchnick	\N	\N	\N	\N	\N	\N	0e4964e3-8045-4265-a72f-086627adaa64	\N
1169	\N	2026-03-06 20:46:53.881101+00	2026-03-06 20:46:53.881101+00	W Guna Peace Madurai	\N	\N	\N	\N	\N	\N	172020a0-d30c-4579-b97f-8b12674b3adc	\N
1170	\N	2026-03-06 20:46:53.95989+00	2026-03-06 20:46:53.95989+00	W Johns Asst Librarian	\N	\N	\N	\N	\N	\N	9442b7f6-324c-48bb-ba2b-0a06beb78b77	\N
1171	\N	2026-03-06 20:46:54.075656+00	2026-03-06 20:46:54.075656+00	W Kamaraj College Cash Vp	\N	\N	\N	\N	\N	\N	042380cc-9de9-4d01-9a55-916132a49056	\N
1172	\N	2026-03-06 20:46:54.222219+00	2026-03-06 20:46:54.222219+00	W Mukila Mam Bswomens	\N	\N	\N	\N	\N	\N	6532a112-2453-4b35-9719-6002d839be76	\N
1173	\N	2026-03-06 20:46:54.35057+00	2026-03-06 20:46:54.35057+00	W Muthu Selvi Mam Spc regular pstclient	\N	\N	\N	\N	\N	\N	3b8c382b-cd73-47af-962e-7ebf11bad037	\N
1174	\N	2026-03-06 20:46:54.477614+00	2026-03-06 20:46:54.477614+00	W NAAS clg Principal	\N	\N	\N	\N	\N	\N	e9cd65e4-bdb4-461d-aefe-bfccb1a2a116	\N
1175	\N	2026-03-06 20:46:54.585394+00	2026-03-06 20:46:54.585394+00	W Rac Cs bajira mam bDept Mam	\N	\N	\N	\N	\N	\N	9c6cbb4f-5870-4976-a2bc-833a843c2ccd	\N
1176	\N	2026-03-06 20:46:54.685283+00	2026-03-06 20:46:54.685283+00	W Rac Erp Mam	\N	\N	\N	\N	\N	\N	c0f36c66-45fe-40ba-9227-3db9d9ebea84	\N
1177	\N	2026-03-06 20:46:54.769193+00	2026-03-06 20:46:54.769193+00	W Shakina Mam coa Stc pstclient  work	\N	\N	\N	\N	\N	\N	ef65d382-436c-4cda-8fd9-10d0f0242aec	\N
1178	\N	2026-03-06 20:46:54.88133+00	2026-03-06 20:46:54.88133+00	W Suresh Sir MBA Annai Clg	\N	\N	\N	\N	\N	\N	6b9733f6-24a8-4d74-aada-a0bb4cbb3155	\N
1179	\N	2026-03-06 20:46:55.014877+00	2026-03-06 20:46:55.014877+00	water  can	\N	\N	\N	\N	\N	\N	ca5423a1-0398-4d88-b855-d46397b57594	\N
1180	\N	2026-03-06 20:46:55.151337+00	2026-03-06 20:46:55.151337+00	wtmu babu vinayagam pstclient developer	\N	\N	\N	\N	\N	\N	f9b68886-0bf4-4abe-8553-eb5a7ac82d1f	\N
1181	\N	2026-03-06 20:46:55.272093+00	2026-03-06 20:46:55.272093+00	xerox  highground	\N	\N	\N	\N	\N	\N	fc87b525-d3cc-4e7e-bd51-26bbceabbc69	\N
1182	\N	2026-03-06 20:46:55.374852+00	2026-03-06 20:46:55.374852+00	YAZHINI RAJU rac	\N	\N	\N	\N	\N	\N	618189cb-0432-4a9b-880c-451a7f4d1f45	\N
1151	\N	2026-03-06 20:46:51.812896+00	2026-03-06 20:46:51.812896+00	vaibhav sir helixsense	\N	\N	\N	\N	\N	\N	8f685ff7-c0c9-416a-90a6-63231fa61f9e	\N
1075	\N	2026-03-06 20:46:42.443658+00	2026-03-06 20:46:42.443658+00	Sowmiya pststafff	\N	\N	\N	\N	\N	\N	be4303fc-ced7-43f1-957b-90064bec4283	2
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.products (product_id, created_by, idate, last_updated, test_text, test_paragraph, test_number_int, test_number_float, test_currency, test_percentage, test_rating, test_date, test_date_time, test_time, test_duration, test_yes_no, test_single_choice_collection, test_single_choice_custom_collection, test_multiple_choice, test_multiple_choice_collections, test_autocode, test_email, test_phone, test_website_link, test_password, test_color, test_image, test_file, test_releative_roles, test_rich_text, test_icon, row_exposure_mode_id) FROM stdin;
\.


--
-- Data for Name: role_module_features; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.role_module_features (role_module_feature_id, role_id, module_feature_id, is_granted, granted_by, granted_at) FROM stdin;
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.roles (role_id, role_uuid, role_name, role_key, role_description, company_id, is_system_role, created_by, idate, last_updated, row_exposure_mode_id) FROM stdin;
\.


--
-- Data for Name: row_exposure_modes; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.row_exposure_modes (exposure_mode_id, name, description, expose_data) FROM stdin;
1	normal	Default / normal visibility	t
2	private	Private mode – restricted visibility	f
3	travel	Travel mode	f
4	near_family	Near family mode	f
5	office_work	Office work mode	f
\.


--
-- Data for Name: settings; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.settings (setting_id, group_name, setting_key, setting_name, description, field_type_id, default_value, value, scope, tenant_id, is_built_in, last_updated, field_config_json, user_uuid) FROM stdin;
2	Branding	brand_color	Primary Brand Color	Main accent color	19	"#007bff"	"#007bff"	global	\N	t	2026-01-17 23:27:17.036866+00	{}	\N
1	General	app_name	Application Name	The visible name of the SaaS platform	1	"Noolva SaaS"	"Noolva SaaS"	global	\N	t	2026-01-17 23:27:29.110978+00	{}	\N
4	Security	enable_2fa	Enable 2FA	Allow users to enable Two-Factor Auth	12	false	"false"	global	\N	t	2026-01-16 15:48:33.595872+00	{}	\N
3	Security	password_min_length	Minimum Password Length	Enforced complexity	3	8	"8"	global	\N	t	2026-01-16 15:48:33.604812+00	{}	\N
21	Theme	default_saas_theme	Default SAAS Theme	Default theme for SAAS UI	13	"default"	"default"	global	\N	t	2026-02-01 18:23:06.854679+00	{"options": [{"label": "Default Corporate", "value": "default"}, {"label": "Slate Corporate", "value": "slate"}]}	\N
22	Theme	default_tenant_theme	Default Tenant Theme	Default theme for Tenant UI	13	"default"	"default"	global	\N	t	2026-02-01 18:23:06.854679+00	{"options": [{"label": "Default Corporate", "value": "default"}, {"label": "Slate Corporate", "value": "slate"}]}	\N
23	Security	idle_timeout_minutes	Idle session lock (minutes)	Lock session after this many minutes of inactivity; user must re-enter password (and 2FA if enabled). Use -1 for no lock.	11	15	15	global	\N	t	2026-02-03 20:44:26.181352+00	{"max": 1440, "min": -1, "step": 1, "unit": "minutes"}	\N
24	UI	auto_hide_sidebar	Auto Hide Sidebar	When Yes, the app sidebar is hidden by default.	12	false	false	global	\N	t	2026-02-08 04:32:35.744051+00	{}	\N
25	General	current_user_mode	Current User Mode	When set, auto CRUD list returns only rows whose row_exposure_mode matches this mode and expose_data is Yes. Null = show all.	13	\N	\N	global	\N	t	2026-03-07 08:50:49.26736+00	{"options_source": "row_exposure_modes"}	\N
26	General	current_user_mode	Current User Mode	When set, auto CRUD list returns only rows whose row_exposure_mode matches this mode and expose_data is Yes. Null = show all.	13	\N	null	global	\N	t	2026-03-07 13:07:31.032969+00	{}	93f32e0d-c9ec-42bc-8cdd-651231135a74
\.


--
-- Data for Name: task_attachments; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.task_attachments (attachment_id, created_by, idate, last_updated, attachment_uuid, attachment_title, file_path, task, row_exposure_mode_id) FROM stdin;
10	\N	2026-03-04 20:51:31.253947+00	2026-03-04 20:51:31.253947+00	f0bb183b-620a-41e4-936a-aa227266742c	image.png	private/model-attachments/task_attachments/36d7dcb368a147f686074e9b25a7491e.png	12	\N
11	\N	2026-03-04 20:54:16.173644+00	2026-03-04 20:54:16.173644+00	49b8749d-34be-4f0e-af74-081e2afabbb7	test.txt	private/model-attachments/task_attachments/9e751cd1d25649faa43ec6130d9c27aa.txt	12	\N
15	\N	2026-03-04 21:16:39.121939+00	2026-03-04 21:16:39.121939+00	26cefac9-2cce-4612-8fb5-ac8b4e5a27d8	pasted-1772658996049.png	private/model-attachments/task_attachments/fe54d67e8bc041bc8709064242d33ab4.png	12	\N
22	\N	2026-03-05 03:05:20.048445+00	2026-03-05 03:05:20.048445+00	04707965-cc04-4470-9b80-58f52c02365e	pasted-1772679917995.tsv	private/model-attachments/task_attachments/041bb8f490a3427fbf03f3d9327588a1.tsv	12	\N
23	\N	2026-03-05 11:02:36.306397+00	2026-03-05 11:02:36.306397+00	36518cd9-dfee-48db-9539-b0c62c7bb2ba	helpers.txt	private/model-attachments/task_attachments/6e574987bdac49d7b8ffaed1c448c823.txt	33	\N
24	\N	2026-03-05 18:26:11.528908+00	2026-03-05 18:26:11.528908+00	1a10045a-0741-4197-a8cc-eb125144225e	star-cicd-vm-lambda	private/model-attachments/task_attachments/246b40e57bf944858c691e3776e8fa99.txt	12	\N
25	\N	2026-03-05 18:28:27.820666+00	2026-03-05 18:28:27.820666+00	b7df6037-8077-46d1-9c24-b9f11b7efbf9	stop_idle_agent.txt	private/model-attachments/task_attachments/2650b86ede1d47b5b0ee2118e53a73b9.txt	12	\N
26	\N	2026-03-05 19:57:38.080637+00	2026-03-05 19:57:38.080637+00	4dceb582-432c-4d10-a422-b4270248c3d7	db-sizes.png	private/model-attachments/task_attachments/ae4089e46c70403593c037dfa9161eae.png	27	\N
28	\N	2026-03-05 19:57:57.456089+00	2026-03-05 19:57:57.456089+00	7bce3a9c-3b4e-49d9-8c41-b4e3fdfca160	chunk-start-and-end-date	private/model-attachments/task_attachments/b33b5915926c4f74b02df785097c23c6.png	27	\N
27	\N	2026-03-05 19:57:48.636866+00	2026-03-05 19:57:48.636866+00	6a5da453-7e25-480c-ae57-3a072f8373c3	large-size-tables	private/model-attachments/task_attachments/6a1c0dfbf8604a94b07f2145a790297d.png	27	\N
29	\N	2026-03-06 03:23:40.953897+00	2026-03-06 03:23:40.953897+00	0d9d2809-3802-41fb-bbbf-d9fe735f2db4	azure devops service hooks	private/model-attachments/task_attachments/52f4a265516847439cb1fe6764bd1275.png	12	\N
30	\N	2026-03-06 03:39:03.696679+00	2026-03-06 03:39:03.696679+00	16e27e99-1c12-45a8-bb36-74bc7351f3b0	Run state changed	private/model-attachments/task_attachments/014581b2714c4521a549e0c9398db08b.png	12	\N
31	\N	2026-03-06 03:52:54.234216+00	2026-03-06 03:52:54.234216+00	b311cd7d-e96b-4868-9797-c34c3ecd73a9	pasted-1772769170723.png	private/model-attachments/task_attachments/78d74443263d47639eab0f8702ad5500.png	21	\N
32	\N	2026-03-06 03:53:03.790925+00	2026-03-06 03:53:03.790925+00	fd963aac-9709-4d63-82a7-070427fef1ca	pasted-1772769178620.png	private/model-attachments/task_attachments/f82ed0d75fe248b8b44668b9e35cc29c.png	21	\N
33	\N	2026-03-06 07:48:04.489334+00	2026-03-06 07:48:04.489334+00	8f7c8ead-7643-4458-b356-203e6cf52bfa	local changes	private/model-attachments/task_attachments/1f40be0ca93943928c1d541bd69322d4.txt	35	\N
34	\N	2026-03-07 02:23:34.086152+00	2026-03-07 02:23:34.086152+00	4a0c8082-737b-4275-816c-fece5a2ceb5e	diagnostics_report_data (5).txt	private/model-attachments/task_attachments/5d1156658653487895ef7645adb5e2b5.txt	41	\N
\.


--
-- Data for Name: task_categories; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.task_categories (task_category_id, created_by, idate, last_updated, name, description, task_type, color, icon, is_active, order_no, row_exposure_mode_id) FROM stdin;
1	\N	2026-02-14 22:09:43.919189+00	2026-02-14 22:09:43.919189+00	Work	Professional and work-related	work	\N	\N	t	\N	\N
2	\N	2026-02-14 22:09:43.919189+00	2026-02-14 22:09:43.919189+00	Personal	Personal life and family	life	\N	\N	t	\N	\N
3	\N	2026-02-14 22:09:43.919189+00	2026-02-14 22:09:43.919189+00	Learning	Learning and skill development	life	\N	\N	t	\N	\N
4	\N	2026-02-14 22:09:43.919189+00	2026-02-14 22:09:43.919189+00	Family	Family and home	life	\N	\N	t	\N	\N
\.


--
-- Data for Name: task_comments; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.task_comments (comment_id, created_by, idate, last_updated, task, message, comment_title, row_exposure_mode_id) FROM stdin;
1	\N	2026-03-02 20:51:32.680049+00	2026-03-02 20:51:32.680049+00	3	completed	Completed	\N
2	\N	2026-03-02 21:10:30.756031+00	2026-03-02 21:10:30.756031+00	2	news creds shared to ubikaa,prajith,jagdeesh sir.	Completed	\N
3	\N	2026-03-03 03:01:23.990308+00	2026-03-03 03:01:23.990308+00	6	completed	Completed	\N
4	\N	2026-03-03 03:24:32.893811+00	2026-03-03 03:24:32.893811+00	10	completed	Completed	\N
5	\N	2026-03-03 03:24:58.458676+00	2026-03-03 03:24:58.458676+00	7	Completed	Completed	\N
6	\N	2026-03-03 03:26:11.42604+00	2026-03-03 03:26:11.42604+00	4		Completed	\N
7	\N	2026-03-03 03:26:16.230775+00	2026-03-03 03:26:16.230775+00	5		Completed	\N
8	\N	2026-03-03 03:26:21.140591+00	2026-03-03 03:26:21.140591+00	3		Completed	\N
9	\N	2026-03-03 03:26:26.6887+00	2026-03-03 03:26:26.6887+00	2		Completed	\N
10	\N	2026-03-03 03:26:31.063606+00	2026-03-03 03:26:31.063606+00	6		Completed	\N
11	\N	2026-03-03 03:28:59.890253+00	2026-03-03 03:28:59.890253+00	9	waiting for ticket with ubikaa	waiting for ticket	\N
12	\N	2026-03-03 03:29:56.436395+00	2026-03-03 03:29:56.436395+00	8	monitoring for next alert	monitoring for next alert	\N
13	\N	2026-03-03 07:35:27.407627+00	2026-03-03 07:35:27.407627+00	11	completed	Completed	\N
14	\N	2026-03-03 07:54:30.242432+00	2026-03-03 07:54:30.242432+00	13	explained details and issues.	delegated to Adithan	\N
15	\N	2026-03-03 08:12:21.576575+00	2026-03-03 08:12:21.576575+00	9	get ticket +manually change production at 5PM	get ticket +manually change production at 5PM	\N
16	\N	2026-03-03 09:56:28.368939+00	2026-03-03 09:56:28.368939+00	13	given access to utlization service user	delegated to Adi	\N
17	\N	2026-03-03 14:40:36.858307+00	2026-03-03 14:40:36.858307+00	17	informed to vaibhav and jagdeesh sir.	Completed	\N
18	\N	2026-03-03 14:41:16.066008+00	2026-03-03 14:41:16.066008+00	9	waiting for ticket	waiting for ticket	\N
19	\N	2026-03-03 14:44:10.059682+00	2026-03-03 14:44:10.059682+00	18		Completed	\N
20	\N	2026-03-03 15:18:18.914443+00	2026-03-03 15:18:18.914443+00	14	id  |  to_be_returned_on\n-----+---------------------\n  36 | 2025-07-31 05:44:47\n  21 | 2025-07-08 04:49:40\n  12 | 2025-06-25 05:53:14\n 136 | 2025-10-22 02:37:24\n 134 | 2025-10-22 02:25:44\n 133 | 2025-10-22 01:51:20\n 135 | 2025-10-22 02:29:05\n 565 | 2026-02-27 02:19:12\n\napinsdc also having same issue	Completed	\N
21	\N	2026-03-03 16:27:33.913356+00	2026-03-03 16:27:33.913356+00	20	completed with jagdeesh sir.	Completed	\N
22	\N	2026-03-04 03:15:12.153609+00	2026-03-04 03:15:12.153609+00	12	/opt/azagent1\n/opt/azagent2\ncd /opt\nsudo mkdir azagent2\nsudo chown ssm-user:ssm-user azagent2\ncd azagent2\n\n\nsudo systemctl status vsts.agent.*\nwill show two....	multi azure agents	\N
23	\N	2026-03-04 03:29:24.153524+00	2026-03-04 03:29:24.153524+00	12	disc 64 GiB\nStandard D2as v4 (2 vcpus, 8 GiB memory)\nself host azure	old azure vm info	\N
24	\N	2026-03-04 03:29:36.024779+00	2026-03-04 03:29:36.024779+00	12	Attachment removed.\n\nAttachment: mro.report.scheduler_mcloud2.csv\nFile: private/model-attachments/task_attachments/b9113b5941fe4da0828a00dd73b43cd6.csv\n\nReason:\ndelete	Attachment removed – mro.report.scheduler_mcloud2.csv	\N
25	\N	2026-03-04 03:29:42.381256+00	2026-03-04 03:29:42.381256+00	12	Attachment removed.\n\nAttachment: image.png\nFile: private/model-attachments/task_attachments/a0936e63a6d94fb6b5ff04536845b159.png\n\nReason:\ndelete	Attachment removed – image.png	\N
26	\N	2026-03-04 03:29:54.800359+00	2026-03-04 03:29:54.800359+00	12	Attachment removed.\n\nAttachment: 7.png\nFile: private/model-attachments/task_attachments/854efbf3541c40018b38e063b4906056.png\n\nReason:\ndelete	Attachment removed – 7.png	\N
27	\N	2026-03-04 03:29:59.739548+00	2026-03-04 03:29:59.739548+00	12	Attachment removed.\n\nAttachment: image.png\nFile: private/model-attachments/task_attachments/1c52dc04898249a98bd40f8c92b63db3.png\n\nReason:\ndelete	Attachment removed – image.png	\N
28	\N	2026-03-04 03:30:04.331166+00	2026-03-04 03:30:04.331166+00	12	Attachment removed.\n\nAttachment: image.png\nFile: private/model-attachments/task_attachments/e905d9a2c6224e1690501794f41c43f6.png\n\nReason:\ndelete	Attachment removed – image.png	\N
29	\N	2026-03-04 03:30:10.532486+00	2026-03-04 03:30:10.532486+00	12	Attachment removed.\n\nAttachment: image.png\nFile: private/model-attachments/task_attachments/a242a60df60a4b2c968203e684ce5f59.png\n\nReason:\ndelete	Attachment removed – image.png	\N
30	\N	2026-03-04 03:44:39.45772+00	2026-03-04 03:44:39.45772+00	12	Attachment removed.\n\nAttachment: image.png\nFile: private/model-attachments/task_attachments/0fa4a18924034c3a82a90dabae5e6ce6.png\n\nReason:\ndelete	Attachment removed – image.png	\N
31	\N	2026-03-04 06:43:13.597162+00	2026-03-04 06:43:13.597162+00	22	said by vaibhav	keep it for last 120 days and delete older	\N
32	\N	2026-03-04 06:43:56.011774+00	2026-03-04 06:43:56.011774+00	23	by cropping that time window.	9pm to 10pm log status given	\N
33	\N	2026-03-04 06:47:27.564664+00	2026-03-04 06:47:27.564664+00	23	root@hsn-brookfield-vm-prod-eastus-001:/var/log/odoo12/brookfields# tar -xOzf apibrookfields.log-2026-02-25-220001.tgz | grep -F "create hx.waste_tracker_log res.users[1089]"\n2026-02-25 11:42:02,450 20026 INFO hsense odoo.addons.mro_tenant_employee.controllers.controller_api: LOG C:/api/v4/create hx.waste_tracker_log res.users[1089]\n2026-02-25 14:18:46,273 16468 INFO hsense odoo.addons.mro_tenant_employee.controllers.controller_api: LOG C:/api/v4/create hx.waste_tracker_log res.users[1089]\n2026-02-25 16:35:16,063 11605 INFO hsense odoo.addons.mro_tenant_employee.controllers.controller_api: LOG C:/api/v4/create hx.waste_tracker_log res.users[1089]\nroot@hsn-brookfield-vm-prod-eastus-001:/var/log/odoo12/brookfields# tar -xOzf apibrookfields.log-2026-02-26-220001.tgz | grep -F "create hx.waste_tracker_log res.users[1089]"\n2026-02-26 10:26:56,292 1558 INFO hsense odoo.addons.mro_tenant_employee.controllers.controller_api: LOG C:/api/v4/create hx.waste_tracker_log res.users[1089]\nroot@hsn-brookfield-vm-prod-eastus-001:/var/log/odoo12/brookfields# tar -xOzf apibrookfields.log-2026-02-27-220001.tgz | grep -F "create hx.waste_tracker_log res.users[1089]"\n2026-02-27 14:19:19,387 7798 INFO hsense odoo.addons.mro_tenant_employee.controllers.controller_api: LOG C:/api/v4/create hx.waste_tracker_log res.users[1089]\n2026-02-27 17:01:31,650 11605 INFO hsense odoo.addons.mro_tenant_employee.controllers.controller_api: LOG C:/api/v4/create hx.waste_tracker_log res.users[1089]\n2026-02-27 21:18:17,857 20597 INFO hsense odoo.addons.mro_tenant_employee.controllers.controller_api: LOG C:/api/v4/create hx.waste_tracker_log res.users[1089]	final- log search approach	\N
34	\N	2026-03-04 08:30:27.024978+00	2026-03-04 08:30:27.024978+00	12	disk increased and debugging, pipelines	disk increased by 64gb	\N
35	\N	2026-03-04 09:34:40.319048+00	2026-03-04 09:34:40.319048+00	9	HP2600147	give pr HP2600147	\N
36	\N	2026-03-04 09:38:06.104683+00	2026-03-04 09:38:06.104683+00	23		Completed	\N
37	\N	2026-03-04 09:45:52.7784+00	2026-03-04 09:45:52.7784+00	9	test and update in ticket HP2600147	test after 6pm by checkout master	\N
38	\N	2026-03-04 10:00:35.126189+00	2026-03-04 10:00:35.126189+00	21	With web_icon\nmenu upgrade\n   ↓\nwrite(menu)\n   ↓\nwrite(web_icon)\n   ↓\nbinary_fields.py override\n   ↓\nattachment search → many results\n   ↓\nExpected singleton ❌\nWithout web_icon\nmenu upgrade\n   ↓\nwrite(menu)\n   ↓\n(no icon write)\n   ↓\nno attachment logic\n   ↓\nupgrade succeeds ✅	web icon-issu	\N
39	\N	2026-03-04 10:11:48.122329+00	2026-03-04 10:11:48.122329+00	21	SELECT id, create_date, res_id\nFROM ir_attachment\nWHERE res_model = 'ir.ui.menu'\nAND res_field = 'web_icon_data'\nAND res_id = 1089\nORDER BY id DESC;	execute this on dev qa, that will different.	\N
40	\N	2026-03-04 12:38:34.92601+00	2026-03-04 12:38:34.92601+00	25		Completed	\N
41	\N	2026-03-04 18:01:09.694098+00	2026-03-04 18:01:09.694098+00	19	waiting for vinoth	waiting for vinoth	\N
42	\N	2026-03-04 19:14:59.665444+00	2026-03-04 19:14:59.665444+00	22	john working on it, taken list to delete.	john working on it	\N
43	\N	2026-03-04 19:15:34.853652+00	2026-03-04 19:15:34.853652+00	26	code temporarily updated on brookfields	waiting for PR	\N
44	\N	2026-03-04 19:16:18.942103+00	2026-03-04 19:16:18.942103+00	16	have to check past updates on aws	have to check past updates on aws	\N
45	\N	2026-03-04 19:17:13.283645+00	2026-03-04 19:17:13.283645+00	12	waiting for ram increase and plan auto shutdown	waiting for ram increase and plan auto shutdown	\N
46	\N	2026-03-04 19:17:28.692404+00	2026-03-04 19:17:28.692404+00	24		Completed	\N
47	\N	2026-03-04 19:19:55.878343+00	2026-03-04 19:19:55.878343+00	21	icon issue resolved, checking another fix review_status	icon issue resolved, checking another fix review_status	\N
48	\N	2026-03-04 19:25:56.334379+00	2026-03-04 19:25:56.334379+00	9	done, pr given, production not git clone.	Completed	\N
49	\N	2026-03-04 20:34:02.163171+00	2026-03-04 20:34:02.163171+00	21	Without dependency declared, module loading order becomes unpredictable.\n\n\nvim mro_maintenance_extended/__manifest__.py\nadd at last depends,:=> 'hx_inspection_checklist',   # ← missing dependency\nBecause QA likely installed modules historically in this order:\nmro_maintenance, hx_inspection_checklist, mro_maintenance_extended\n\nQA (works) → still works\nDEV (failed) → now works\nfuture deployments → stable	review_status issue resolved,	\N
50	\N	2026-03-04 20:34:45.385024+00	2026-03-04 20:34:45.385024+00	21	waiting for confirmation with moses to raise pr	moses sir confirmation	\N
51	\N	2026-03-04 20:37:03.111502+00	2026-03-04 20:37:03.111502+00	22		john finished- receive script or process	\N
52	\N	2026-03-04 21:06:12.334074+00	2026-03-04 21:06:12.334074+00	12	Attachment removed.\n\nAttachment: image.png\nFile: private/model-attachments/task_attachments/c89da31b92434208af98c92b498d4869.png\n\nReason:\ndummy	Attachment removed – image.png	\N
53	\N	2026-03-04 21:06:19.529188+00	2026-03-04 21:06:19.529188+00	12	Attachment removed.\n\nAttachment: image.png\nFile: private/model-attachments/task_attachments/6951698ff65d4df1a8a3ce7cb0b472d7.png\n\nReason:\ndummy	Attachment removed – image.png	\N
54	\N	2026-03-04 21:07:27.637479+00	2026-03-04 21:07:27.637479+00	12	Attachment removed.\n\nAttachment: pasted-1772658429636.png\nFile: private/model-attachments/task_attachments/e8914cd357fc45dd96fdb689fa0534b8.png\n\nReason:\ndummy	Attachment removed – pasted-1772658429636.png	\N
55	\N	2026-03-04 21:07:34.648129+00	2026-03-04 21:07:34.648129+00	12	Attachment removed.\n\nAttachment: pasted-1772658407928.png\nFile: private/model-attachments/task_attachments/1610c80094cf4aef90817c3104028e6d.png\n\nReason:\ndummy	Attachment removed – pasted-1772658407928.png	\N
56	\N	2026-03-05 02:42:22.493386+00	2026-03-05 02:42:22.493386+00	12	Attachment removed.\n\nAttachment: pasted-1772659209716.csv\nFile: private/model-attachments/task_attachments/25deff41d4bf40db949b5f98e776bdd6.csv\n\nReason:\nattachment testing	Attachment removed – pasted-1772659209716.csv	\N
57	\N	2026-03-05 03:01:04.051719+00	2026-03-05 03:01:04.051719+00	12	Attachment removed.\n\nAttachment: pasted-1772679098193.png\nFile: private/model-attachments/task_attachments/3ea227eb5aae4ec9a3bfee2bd7002ac2.png\n\nReason:\nde	Attachment removed – pasted-1772679098193.png	\N
58	\N	2026-03-05 03:01:14.256268+00	2026-03-05 03:01:14.256268+00	12	Attachment removed.\n\nAttachment: pasted-1772679648794.txt\nFile: private/model-attachments/task_attachments/321ff802f4bc4df49d6536d723883c78.txt\n\nReason:\nde	Attachment removed – pasted-1772679648794.txt	\N
59	\N	2026-03-05 03:01:21.191792+00	2026-03-05 03:01:21.191792+00	12	Attachment removed.\n\nAttachment: pasted-1772678461342.png\nFile: private/model-attachments/task_attachments/9d38d336962c489b8b5d2870ce71aa04.png\n\nReason:\nde	Attachment removed – pasted-1772678461342.png	\N
60	\N	2026-03-05 03:01:25.970773+00	2026-03-05 03:01:25.970773+00	12	Attachment removed.\n\nAttachment: pasted-1772678574569.csv\nFile: private/model-attachments/task_attachments/ff92bc7081cb4f78b82e0e8bf7ecd79c.csv\n\nReason:\nde	Attachment removed – pasted-1772678574569.csv	\N
61	\N	2026-03-05 03:01:32.731784+00	2026-03-05 03:01:32.731784+00	12	Attachment removed.\n\nAttachment: pasted-1772659084724.png\nFile: private/model-attachments/task_attachments/cdbbbb6ad76043ed91fca2a8d362a70f.png\n\nReason:\nde	Attachment removed – pasted-1772659084724.png	\N
62	\N	2026-03-05 03:01:38.732778+00	2026-03-05 03:01:38.732778+00	12	Attachment removed.\n\nAttachment: pasted-1772658958266.txt\nFile: private/model-attachments/task_attachments/efe2cf4e4447477489e5f59b04ad2297.txt\n\nReason:\nde	Attachment removed – pasted-1772658958266.txt	\N
63	\N	2026-03-05 07:12:27.952205+00	2026-03-05 07:12:27.952205+00	12	on demand running, by\n1) add one more job to check agent availablity, if not start\nor\n2) is there anything option to trigger something when pipeline searching for agent.	plan for on demand running	\N
64	\N	2026-03-05 07:13:02.833293+00	2026-03-05 07:13:02.833293+00	21	have to work on pipeline	have to work on pipeline	\N
65	\N	2026-03-05 07:14:12.648948+00	2026-03-05 07:14:12.648948+00	26	waiting for ticket to update the info	waiting for ticket	\N
66	\N	2026-03-05 07:52:23.612315+00	2026-03-05 07:52:23.612315+00	32	3862842 |  SELECT measured_ts FROM dw_reading_history WHERE updated_on > '2025-11-02 11:15:04.421219' AND asset_number='WGEHC-E-00003' AND alias_name='KWH' ORDER BY measured_ts ASC LIMIT 1\n 3863400 | SELECT pid,query FROM pg_stat_activity WHERE state = 'active' ORDER BY query_start ASC;\n 3863485 | select datname from pg_database where datdba=(select usesysid from pg_user where usename=current_user) and not datistemplate and datallowconn and datname not in ('template0', 'postgres') order by datname\n\n\n SELECT measured_ts FROM dw_reading_history WHERE updated_on > '2025-07-22 11:16:15.187344' AND asset_number='WGEHC-E-00026' AND alias_name='KWH' ORDER BY measured_ts ASC LIMIT 1\n 3860030 | with ks_list_query as (WITH consumption AS (                +\n         |     SELECT                +\n         |         device_id,                +\n         |         'Today Cons. (kWh)' AS display_name,                +\n         |         CAST(SUM(CASE WHEN mdate::date = CURRENT_DATE THEN eb_consumption ELSE 0 END) AS INTEGER)::text AS answer_value                +\n         |     FROM dmr_stats_eb_consumption                +\n         |     WHERE device_id = '68B6B341A880-1'                +\n         |     GROUP BY device_id                +\n         |                +\n         |     UNION ALL                +\n         |                +\n         |     SELECT                +\n         |         device_id,                +\n         |         'Yesterday (kWh)' AS display_name,                +\n         |         CAST(SUM(CASE WHEN mdate::date = CURRENT_DATE - INTERVAL '1 day' THEN eb_consumption ELSE 0 END) AS INTEGER)::text AS answer_value                +\n         |     FROM dmr_stats_eb_consumption                +\n         |     WHERE device_id = '68B6B341A880-1'                +\n         |     GROUP BY device_id:	query on that time	\N
67	\N	2026-03-05 07:53:26.334707+00	2026-03-05 07:53:26.334707+00	32	have to take count on eb consumption\nlong queries,	requirements of sundaram sir	\N
68	\N	2026-03-05 08:35:17.642095+00	2026-03-05 08:35:17.642095+00	19	done along with vinoth	Completed	\N
69	\N	2026-03-05 08:45:14.269996+00	2026-03-05 08:45:14.269996+00	29	she given all 3 tickets	Completed	\N
70	\N	2026-03-05 09:03:58.011902+00	2026-03-05 09:03:58.011902+00	31	waiting for PRs from vaibhav	waiting for PRs from vaibhav	\N
71	\N	2026-03-05 11:02:53.787749+00	2026-03-05 11:02:53.787749+00	33	attached as .txt	helpers.js	\N
72	\N	2026-03-05 11:03:07.521691+00	2026-03-05 11:03:07.521691+00	33	finished and restarted	Completed	\N
73	\N	2026-03-05 11:06:42.218181+00	2026-03-05 11:06:42.218181+00	26	hsense-erpv3/pull/2542	pr given	\N
74	\N	2026-03-05 18:24:57.710409+00	2026-03-05 18:24:57.710409+00	31		Completed	\N
75	\N	2026-03-05 18:25:34.983831+00	2026-03-05 18:25:34.983831+00	12	Pipeline queued\n      ↓\nAzure DevOps Service Hook\n      ↓\nLambda #1 (start EC2) if not running\n      ↓\nEC2 hs-cicd-vm starts\n      ↓\nAgent runs pipeline\n      ↓\nIdle checker (Lambda #2 every 5 min)\n      ↓\nIf idle >15 min → stop EC2	plan	\N
76	\N	2026-03-05 18:30:40.322343+00	2026-03-05 18:30:40.322343+00	12	start_cicd_vm\nstop_idle_agent\n\nfunction url\nhttps://abc123.lambda-url.ap-south-1.on.aws/\n\n\nAzure DevOps\n → Project Settings\n → Service Hooks\nBuild->Build queued->Any build\nWebhook->https://abc123.lambda-url.ap-south-1.on.aws/\n\nfor stop:\nCreate EventBridge rule\nSchedule expression:\nrate(5 minutes)\nLambda → stop_idle_agent\nAmazonEC2FullAccess\n	\N	\N
77	\N	2026-03-05 19:34:34.742043+00	2026-03-05 19:34:34.742043+00	21		Completed	\N
78	\N	2026-03-05 19:57:15.923856+00	2026-03-05 19:57:15.923856+00	27	494G    /var/lib/postgresql	db size increased	\N
79	\N	2026-03-06 03:00:50.788135+00	2026-03-06 03:00:50.788135+00	22	ticket number?	ticket number?	\N
80	\N	2026-03-06 03:26:50.008158+00	2026-03-06 03:26:50.008158+00	12	the word “Subscription” in Azure DevOps Service Hooks does NOT mean paid subscription.\nIn this context subscription = event subscription (like event listener).	subscription = event subscription 	\N
81	\N	2026-03-06 04:31:00.194929+00	2026-03-06 04:31:00.194929+00	27	CREATE INDEX ON dw_reading_history (asset_id);\nCREATE INDEX ON dw_reading_history (asset_number);	index applied earlier	\N
82	\N	2026-03-06 07:50:08.824984+00	2026-03-06 07:50:08.824984+00	26	pr cherry picked to release/1.7.141	pr cherry picked to release	\N
83	\N	2026-03-06 07:51:16.046737+00	2026-03-06 07:51:16.046737+00	23	24th,25,26,27 backend,frontend,investigate, prepare document,	prepare document	\N
84	\N	2026-03-06 07:52:43.174183+00	2026-03-06 07:52:43.174183+00	11	inspection -resync->can we stop after dw2\nwhen sundaram sir presense	sundaram sir and vaibhav sir	\N
85	\N	2026-03-06 07:53:43.184693+00	2026-03-06 07:53:43.184693+00	16	vaibhav said	we can decide later	\N
86	\N	2026-03-06 17:41:42.601286+00	2026-03-06 17:41:42.601286+00	35	please merge https://github.com/HelixSense/hsense-erpv3/pull/2544\nHP2600160/api-nttds/local-changes-committed/Vijay into release/hspace/1.0.2	pr given	\N
87	\N	2026-03-06 17:42:41.399612+00	2026-03-06 17:42:41.399612+00	35	old tag : hsense-hspace-rc.18\nnew tag to be created and checkout on prod and preprod,\nnew tag : hsense-hspace-rc.19	after merge create tag	\N
88	\N	2026-03-06 17:44:50.32044+00	2026-03-06 17:44:50.32044+00	32	1)  have to check which dashboards using which models\n2) which dashboard is slow\n3) is following filters applied on all the configurations,\na)timestamp\nb)reading name\nc)deviceid/asset number	have to narrow down issue	\N
89	\N	2026-03-06 17:46:21.700135+00	2026-03-06 17:46:21.700135+00	12	1) use event of azure devops\n2) for webhook use own code not lambda function	have to forward to work on it	\N
90	\N	2026-03-06 18:21:05.790076+00	2026-03-06 18:21:05.790076+00	35		Completed	\N
91	\N	2026-03-06 18:24:38.191721+00	2026-03-06 18:24:38.191721+00	30	update two excel files from john	update two excel files from john	\N
92	\N	2026-03-06 18:26:24.353154+00	2026-03-06 18:26:24.353154+00	34		Completed	\N
93	\N	2026-03-06 18:26:48.062815+00	2026-03-06 18:26:48.062815+00	36	sundaram sir have to finalize	sundaram sir have to finalize	\N
94	\N	2026-03-06 18:29:03.290163+00	2026-03-06 18:29:03.290163+00	32	document all low-env, higher env, s3 related details on devops notes.	collect wipro details too	\N
95	\N	2026-03-07 14:56:45.424648+00	2026-03-07 14:56:45.424648+00	42	update report then close	update report then close	\N
96	\N	2026-03-07 18:10:34.936414+00	2026-03-07 18:10:34.936414+00	38		Completed	\N
97	\N	2026-03-07 18:10:44.285856+00	2026-03-07 18:10:44.285856+00	37		Completed	\N
98	\N	2026-03-07 18:10:52.071314+00	2026-03-07 18:10:52.071314+00	42		Completed	\N
99	\N	2026-03-07 18:11:02.533043+00	2026-03-07 18:11:02.533043+00	39		Completed	\N
\.


--
-- Data for Name: task_priorities; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.task_priorities (priority_id, created_by, idate, last_updated, name, weight, importance, urgency, is_mandatory, is_ignorable, is_delegatable, regret_level, row_exposure_mode_id) FROM stdin;
1	\N	2026-02-14 21:34:04.571487+00	2026-02-14 21:34:04.571487+00	non_negotiable	1	t	t	t	f	f	5	\N
2	\N	2026-02-14 21:34:04.571487+00	2026-02-14 21:34:04.571487+00	critical	2	t	t	f	f	f	4	\N
3	\N	2026-02-14 21:34:04.571487+00	2026-02-14 21:34:04.571487+00	important	3	t	f	f	f	f	3	\N
4	\N	2026-02-14 21:34:04.571487+00	2026-02-14 21:34:04.571487+00	normal	4	f	f	f	f	f	2	\N
5	\N	2026-02-14 21:34:04.571487+00	2026-02-14 21:34:04.571487+00	optional	5	f	f	f	t	f	1	\N
6	\N	2026-02-14 21:34:04.571487+00	2026-02-14 21:34:04.571487+00	delegatable	6	f	f	f	f	t	2	\N
7	\N	2026-02-14 21:34:04.571487+00	2026-02-14 21:34:04.571487+00	avoid_or_ignore	7	f	f	f	t	f	1	\N
\.


--
-- Data for Name: task_sprints; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.task_sprints (sprint_id, created_by, idate, last_updated, sprint_name, description, goal, start_date, end_date, status, completed_at, is_active, row_exposure_mode_id) FROM stdin;
1	\N	2026-03-01 10:55:49.386218+00	2026-03-01 10:55:49.386218+00	Helixsense sprint 1.7.141	\N	\N	2026-03-02	2026-03-07	active	\N	t	\N
2	\N	2026-03-01 10:56:26.253163+00	2026-03-01 10:56:26.253163+00	Helixsense sprint 1.7.142	\N	\N	2026-03-09	2026-03-14	active	\N	t	\N
\.


--
-- Data for Name: teams; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.teams (team_id, team_uuid, team_name, team_description, company_id, parent_team_id, manager_id, created_by, idate, last_updated, row_exposure_mode_id) FROM stdin;
\.


--
-- Data for Name: tenants; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.tenants (tenant_id, tenant_uuid, tenant_name, contact_email, subscription_plan, subscription_status, subscription_expires_at, is_active, created_by, created_at, last_updated) FROM stdin;
1	6332d07a-ac4a-4749-a6b5-24c63aec2271	Default Tenant	\N	trial	active	\N	t	\N	2026-01-15 23:29:03.114175+00	2026-01-15 23:29:03.114175+00
\.


--
-- Data for Name: themes; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.themes (theme_id, theme_uuid, theme_name, theme_key, theme_json, user_id, scope, tenant_id, is_builtin, is_default, created_by, created_at, last_updated) FROM stdin;
2	c9e2b293-2e8f-4ed4-8ebc-88c2c719f011	Slate Corporate	slate	{"theme": "slate", "theme_mode": "light", "font_size_base": 14, "font_size_large": 16, "font_size_small": 12, "header_bg_color": "#334155", "sidebar_bg_color": "none", "theme_color_primary": "#1890ff", "theme_color_secondary": "#52c41a"}	\N	saas	\N	t	f	1	2026-02-01 18:23:06.780532+00	2026-02-01 18:23:06.780532+00
1	4cecc474-fbc3-4fca-96d4-d6e4ad78d661	Default Corporate	default	{"theme": "default", "theme_mode": "light", "font_size_base": 14, "font_size_large": 16, "font_size_small": 12, "header_bg_color": "#0F172A", "sidebar_bg_color": "none", "theme_color_primary": "#1890ff", "theme_color_secondary": "#4ba120"}	\N	saas	\N	t	t	1	2026-02-01 18:23:06.780532+00	2026-02-01 18:52:48.752438+00
5	23a24e13-abd6-4500-88b1-98b89ffbdc55	My Theme	user_theme	{"theme": "user_theme", "theme_mode": "light", "font_size_base": 14, "font_size_large": 16, "font_size_small": 12, "header_bg_color": "#0f172a", "sidebar_bg_color": "#261a1a00", "theme_color_primary": "#1890ff", "theme_color_secondary": "#4ba120"}	2	saas	\N	f	f	2	2026-02-01 19:46:10.803448+00	2026-02-01 20:06:16.433971+00
\.


--
-- Data for Name: time_slots; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.time_slots (time_id, created_by, idate, last_updated, slot_uuid, name, slot_type, start_time, end_time, applies_type, applies_value, priority_level, description, row_exposure_mode_id) FROM stdin;
1	\N	2026-03-01 08:54:57.186959+00	2026-03-01 08:54:57.186959+00	0dbc6455-c7f0-4989-bed9-92cb47642695	Wakeup & Refresh & Prayer	core	05:00:00	07:00:00	everyday	\N	1	\N	\N
\.


--
-- Data for Name: ui_component_types; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.ui_component_types (component_type_id, type_code, type_name, category, props_schema_json, is_system, created_at) FROM stdin;
1	row	Row	layout	{"align": {"type": "string"}, "gutter": {"type": "number", "default": 24}, "justify": {"type": "string", "options": ["start", "center", "end"]}}	t	2026-01-15 23:29:03.114175+00
2	column	Column	layout	{"span": {"type": "number", "default": 24}, "offset": {"type": "number"}}	t	2026-01-15 23:29:03.114175+00
3	divider	Divider	layout	{"orientation": {"type": "string", "default": "horizontal"}}	t	2026-01-15 23:29:03.114175+00
4	form	Form	container	{"size": {"type": "string"}, "layout": {"type": "string", "options": ["horizontal", "vertical", "inline"]}}	t	2026-01-15 23:29:03.114175+00
5	card	Card	container	{"title": {"type": "string"}, "bordered": {"type": "boolean"}}	t	2026-01-15 23:29:03.114175+00
6	text	Text Input	input	{"label": "string", "place_holder": "string", "default_value": "string", "validation_type": "string"}	t	2026-01-15 23:29:03.114175+00
7	textarea	Text Area	input	{"rows": "number", "label": "string"}	t	2026-01-15 23:29:03.114175+00
8	number	Number Input	input	{"max": "number", "min": "number", "label": "string"}	t	2026-01-15 23:29:03.114175+00
9	select	Select Dropdown	input	{"mode": "string", "label": "string", "options": "array"}	t	2026-01-15 23:29:03.114175+00
10	date	Date Picker	input	{"label": "string", "format": "string"}	t	2026-01-15 23:29:03.114175+00
11	switch	Switch	input	{"label": "string", "checked_children": "string", "un_checked_children": "string"}	t	2026-01-15 23:29:03.114175+00
12	checkbox	Checkbox	input	{"label": "string"}	t	2026-01-15 23:29:03.114175+00
13	radio	Radio Group	input	{"label": "string", "options": "array"}	t	2026-01-15 23:29:03.114175+00
14	upload	File Upload	input	{"label": "string", "accept": "string", "multiple": "boolean"}	t	2026-01-15 23:29:03.114175+00
15	label	Label	display	{"strong": "boolean", "default_value": "string"}	t	2026-01-15 23:29:03.114175+00
16	table	Table	display	{"columns": "array", "pagination": "boolean"}	t	2026-01-15 23:29:03.114175+00
17	statistic	Statistic	display	{"title": "string", "value": "number", "precision": "number"}	t	2026-01-15 23:29:03.114175+00
18	tag	Tag	display	{"color": "string"}	t	2026-01-15 23:29:03.114175+00
19	badge	Badge	display	{"color": "string", "count": "number"}	t	2026-01-15 23:29:03.114175+00
20	image	Image	display	{"alt": "string", "src": "string", "width": "number"}	t	2026-01-15 23:29:03.114175+00
21	link	Link	display	{"href": "string", "target": "string"}	t	2026-01-15 23:29:03.114175+00
22	progress	Progress	display	{"status": "string", "percent": "number"}	t	2026-01-15 23:29:03.114175+00
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

COPY public.user_groups (group_id, group_uuid, group_name, group_description, company_id, created_by, idate, last_updated, row_exposure_mode_id) FROM stdin;
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
1	db9046e2-e181-4b14-9ec4-fde62524699c	2	\N	password	2026-01-15 23:34:31.18892+00	2026-01-15 23:34:31.18892+00	2026-01-16 18:04:31.210554+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	f	\N
2	697c78c4-4062-4550-8bf6-b262d8d78df9	2	\N	password	2026-01-16 00:57:20.551386+00	2026-01-16 00:57:20.551386+00	2026-01-16 19:27:20.451439+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	f	\N
41	1d83025d-f009-4d20-ae34-390da9bb34a6	2	\N	mfa	2026-02-06 12:35:38.520752+00	2026-02-06 12:35:38.520752+00	2026-02-07 07:05:38.473942+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	t	\N
45	b4a7e0d2-3a29-4ab4-b40e-9492d8046ec1	2	\N	mfa	2026-02-12 03:14:27.837803+00	2026-02-12 03:14:27.837803+00	2026-02-12 21:44:27.828925+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	t	\N
3	adc04488-bbc7-4b97-a193-1ff626c768d5	2	\N	password	2026-01-16 01:07:34.835405+00	2026-01-16 01:07:34.835405+00	2026-01-16 19:37:34.91945+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	f	\N
4	a7d54ddc-320f-48a1-b2d1-2e2be5551dbe	2	\N	password	2026-01-16 01:23:57.039395+00	2026-01-16 01:23:57.039395+00	2026-01-16 19:53:56.917564+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	f	\N
28	589602f1-2823-44af-bd0a-784c9ff8c1ec	2	\N	mfa	2026-02-05 01:46:10.151093+00	2026-02-05 01:46:10.151093+00	2026-02-05 20:16:10.055619+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	f	\N
31	be0d3ba0-6303-467d-84f2-64411ef2589c	3	\N	google_oauth	2026-02-06 09:35:07.029176+00	2026-02-06 09:35:07.029176+00	2026-02-07 04:05:06.988506+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	f	\N
34	113592c5-becf-47ae-b0f1-89496653ebaf	3	\N	google_oauth	2026-02-06 11:30:59.199282+00	2026-02-06 11:30:59.199282+00	2026-02-07 06:00:59.159289+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	f	\N
35	17f1f965-430f-47fc-aff3-de9b94bece86	3	\N	google_oauth	2026-02-06 11:31:19.852352+00	2026-02-06 11:31:19.852352+00	2026-02-07 06:01:19.809148+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	f	\N
47	c26200e0-47e7-4d05-a7c2-ee2c15bb532b	2	\N	mfa	2026-02-16 18:10:15.606498+00	2026-02-16 18:10:15.606498+00	2026-02-17 12:40:15.523721+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	t	\N
49	bc7bc1f8-f51c-4a4e-ac7d-accdabd77a33	2	\N	mfa	2026-02-23 18:55:50.283079+00	2026-02-23 18:55:50.283079+00	2026-02-24 13:25:50.211725+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	t	\N
51	2b4733b7-3eb7-4681-8679-222cb85e4712	2	\N	mfa	2026-02-26 01:56:57.998157+00	2026-02-26 01:56:57.998157+00	2026-02-26 20:26:57.883878+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	t	\N
53	d328048f-14c3-45be-a651-403fe23fae5f	2	\N	mfa	2026-03-01 16:48:12.71384+00	2026-03-01 16:48:12.71384+00	2026-03-02 11:18:12.712133+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	t	\N
56	ec8cb561-574c-446c-adbf-01c606051fef	2	\N	mfa	2026-03-06 20:33:56.709696+00	2026-03-06 20:33:56.709696+00	2026-03-07 15:03:56.61342+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	t	\N
29	623c3442-f56c-46ac-9f03-716781629bc5	2	\N	mfa	2026-02-06 01:41:45.521878+00	2026-02-06 01:41:45.521878+00	2026-02-06 20:11:45.474757+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	f	\N
36	12002edf-9140-41db-a1a0-58f00d597db9	3	\N	google_oauth	2026-02-06 11:32:22.629342+00	2026-02-06 11:32:22.629342+00	2026-02-07 06:02:22.589963+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	f	\N
39	f5cb2776-385a-4c05-847e-919e9226fe7a	3	\N	google_oauth	2026-02-06 12:35:00.978437+00	2026-02-06 12:35:00.978437+00	2026-02-07 07:05:00.930322+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	f	\N
32	ec69d983-1e86-45e7-9b04-e3f8415a516b	3	\N	google_oauth	2026-02-06 10:11:27.482141+00	2026-02-06 10:11:27.482141+00	2026-02-07 04:41:27.443154+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	f	\N
37	bd0a7100-0ed0-4f1b-b9e8-5ff2ba028cc1	3	\N	google_oauth	2026-02-06 11:56:30.030523+00	2026-02-06 11:56:30.030523+00	2026-02-07 06:26:29.994461+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	f	\N
38	45368242-f68e-4acc-9302-a0d70ff4ac1e	3	\N	google_oauth	2026-02-06 11:57:33.744843+00	2026-02-06 11:57:33.744843+00	2026-02-07 06:27:33.706944+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	f	\N
40	652d3e71-2392-4b90-b7aa-4786f17b442d	3	\N	google_oauth	2026-02-06 12:35:09.602382+00	2026-02-06 12:35:09.602382+00	2026-02-07 07:05:09.555451+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	t	\N
42	31f820b1-4db3-433a-bd8c-0fc73f0f8ca7	2	\N	mfa	2026-02-06 18:10:47.400976+00	2026-02-06 18:10:47.400976+00	2026-02-07 12:40:47.379425+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	t	\N
43	59219a1f-4c43-49a1-b3f3-90baa57de77b	3	\N	google_oauth	2026-02-06 18:11:38.846829+00	2026-02-06 18:11:38.846829+00	2026-02-07 12:41:38.827029+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	t	\N
44	e0244d4c-f0a2-4f4b-8478-21eac39cd93d	2	\N	mfa	2026-02-08 03:09:29.627123+00	2026-02-08 03:09:29.627123+00	2026-02-08 21:39:29.527326+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	t	\N
46	c0841019-3df4-4b11-8175-c0194261a534	2	\N	mfa	2026-02-14 08:14:29.56507+00	2026-02-14 08:14:29.56507+00	2026-02-15 02:44:29.481545+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	t	\N
48	2f9391eb-da97-4d8f-a1c8-8a884e2b1466	2	\N	mfa	2026-02-21 18:38:17.921553+00	2026-02-21 18:38:17.921553+00	2026-02-22 13:08:17.850092+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	t	\N
50	72cac85a-0957-4f2c-9133-8067279c3266	2	\N	mfa	2026-02-23 20:13:36.038727+00	2026-02-23 20:13:36.038727+00	2026-02-24 14:43:35.984742+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	t	\N
52	1b80677d-296b-4c0b-b38e-b5635cd2df57	2	\N	mfa	2026-02-28 11:31:13.543795+00	2026-02-28 11:31:13.543795+00	2026-03-01 06:01:13.302598+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	t	\N
54	8bf0e309-5a9a-4812-83db-3c532115580c	2	\N	mfa	2026-03-02 19:21:52.581582+00	2026-03-02 19:21:52.581582+00	2026-03-03 13:51:52.428547+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	t	\N
55	1fd660c6-9175-493c-a9d5-4262069693a8	2	\N	mfa	2026-03-04 17:59:50.677012+00	2026-03-04 17:59:50.677012+00	2026-03-05 12:29:50.603029+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	t	\N
7	6082cee3-9e12-462f-ab1f-6c43f65fba5d	2	\N	password	2026-01-17 03:27:53.325831+00	2026-01-17 03:27:53.325831+00	2026-01-17 21:57:53.280483+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	f	\N
8	c6a4e7b3-713c-4d0b-9e90-8c499f0021f9	2	\N	password	2026-01-17 13:57:38.425488+00	2026-01-17 13:57:38.425488+00	2026-01-18 08:27:38.372698+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	f	\N
9	9c09206c-223f-4869-81c0-773a62c71ea3	2	\N	password	2026-01-18 00:03:26.844929+00	2026-01-18 00:03:26.844929+00	2026-01-18 18:33:26.801166+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	f	\N
10	419d96f0-9dab-475a-918d-c73043f6a049	2	\N	password	2026-01-19 00:19:01.785218+00	2026-01-19 00:19:01.785218+00	2026-01-19 18:49:01.772988+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	f	\N
11	045786c8-d82b-4a22-8cb5-b28d9b98a58f	2	\N	password	2026-01-19 02:00:12.033909+00	2026-01-19 02:00:12.033909+00	2026-01-19 20:30:12.035388+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	f	\N
12	5c605c9a-74ae-47b6-a0b3-8ebee7d1d63d	2	\N	password	2026-01-22 00:14:30.33189+00	2026-01-22 00:14:30.33189+00	2026-01-22 18:44:30.325714+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	f	\N
13	7be1cac1-2abe-4b66-a0ee-84c81c038892	2	\N	password	2026-01-24 14:14:08.712051+00	2026-01-24 14:14:08.712051+00	2026-01-25 08:44:08.707479+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	f	\N
14	bf62d79f-2ac5-468c-bbf7-a053d9ccce3e	2	\N	password	2026-01-25 14:55:55.262441+00	2026-01-25 14:55:55.262441+00	2026-01-26 09:25:55.184629+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	f	\N
15	f57775bf-17bd-4d0e-a274-4aa0491d737c	2	\N	password	2026-01-26 19:08:24.335004+00	2026-01-26 19:08:24.335004+00	2026-01-27 13:38:24.262839+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	f	\N
16	273d335c-d5ef-4d02-91fa-3af6961cc9cb	2	\N	password	2026-01-30 23:59:22.806743+00	2026-01-30 23:59:22.806743+00	2026-01-31 18:29:22.759546+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	f	\N
17	30a3164f-eec0-4b65-8ffb-05e20305af35	2	\N	password	2026-01-31 18:54:43.347045+00	2026-01-31 18:54:43.347045+00	2026-02-01 13:24:43.275402+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	f	\N
18	7dc64f39-e447-4d68-8611-1a1958e04d26	2	\N	password	2026-02-01 18:58:29.941101+00	2026-02-01 18:58:29.941101+00	2026-02-02 13:28:29.847091+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	f	\N
19	367fda47-33e7-4814-88f2-f734afa6193f	2	\N	password	2026-02-01 19:36:27.242046+00	2026-02-01 19:36:27.242046+00	2026-02-02 14:06:27.161646+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	f	\N
20	421ab6d5-2bd1-4d2e-9690-c5dc3a3ff7ee	2	\N	password	2026-02-01 19:41:13.655603+00	2026-02-01 19:41:13.655603+00	2026-02-02 14:11:13.580463+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	f	\N
21	1c59d8fe-2aa7-4fa4-9f4e-76892af6054a	2	\N	password	2026-02-01 20:02:30.927126+00	2026-02-01 20:02:30.927126+00	2026-02-02 14:32:30.862183+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	f	\N
22	d45fabe0-d8d8-4444-9bbd-747bbeb6f0b9	2	\N	password	2026-02-03 19:59:37.118521+00	2026-02-03 19:59:37.118521+00	2026-02-04 14:29:37.070555+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	f	\N
5	a37f2701-28e6-48cd-9ecc-d11f89114677	2	\N	password	2026-01-17 01:24:17.728061+00	2026-01-17 01:24:17.728061+00	2026-01-17 19:54:17.58963+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	f	\N
6	10e48ac4-7c4a-49b1-9d19-5e0444c11804	2	\N	password	2026-01-17 02:49:50.388368+00	2026-01-17 02:49:50.388368+00	2026-01-17 21:19:50.230027+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	f	\N
30	21a2a458-7e20-431a-8d90-b939684ea69c	3	\N	password	2026-02-06 09:34:32.906533+00	2026-02-06 09:34:32.906533+00	2026-02-07 04:04:32.865319+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	f	\N
33	e4d4029e-bca2-45d4-9d86-e8f0f468f35c	3	\N	google_oauth	2026-02-06 11:06:00.899358+00	2026-02-06 11:06:00.899358+00	2026-02-07 05:36:00.8418+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	f	\N
23	bb902563-e3db-49d1-b27f-2f24f381d9e1	2	\N	password	2026-02-03 20:21:48.020225+00	2026-02-03 20:21:48.020225+00	2026-02-04 14:51:47.960432+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	f	\N
24	eca59ea9-feab-436a-a098-54b847def68c	2	\N	password	2026-02-03 20:44:48.658138+00	2026-02-03 20:44:48.658138+00	2026-02-04 15:14:48.601603+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	f	\N
25	fe071d4e-efbc-4a98-b881-6b9760ad665e	2	\N	password	2026-02-04 10:07:15.580502+00	2026-02-04 10:07:15.580502+00	2026-02-05 04:37:15.539378+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	f	\N
26	25eaad75-ef30-40d2-a309-4eb1a88c8a81	2	\N	password	2026-02-04 19:22:12.884579+00	2026-02-04 19:22:12.884579+00	2026-02-05 13:52:12.832725+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	f	\N
27	0f5e0d40-5bf1-43b5-99b7-67a7ec7aa8ff	2	\N	password	2026-02-04 19:47:13.24075+00	2026-02-04 19:47:13.24075+00	2026-02-05 14:17:13.192674+00	{"platform": "\\"macOS\\"", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"}	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	f	\N
\.


--
-- Data for Name: user_teams; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.user_teams (user_team_id, team_id, user_id, role_in_team, joined_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: noolvan
--

COPY public.users (user_id, user_uuid, username, password, first_name, last_name, email, phone, avatar_url, user_type, is_super_admin, ref_table_column, ref_id, ref_uuid, active_status, last_login, deleted_at, created_by, idate, last_updated, enable_2fa, mfa_secret, idle_timeout_minutes, row_exposure_mode_id) FROM stdin;
1	ee69037b-55da-444d-91c9-e4bc70362a31	system	system_internal_locked	\N	\N	\N	\N	\N	system	t	\N	\N	\N	1	\N	\N	\N	2026-01-15 23:29:06.137005+00	2026-01-15 23:29:06.137005+00	f	\N	\N	\N
2	93f32e0d-c9ec-42bc-8cdd-651231135a74	admin	$2b$12$g02erZ8PoPNqaQe8BYkcBue44dd6SaKqGXS9wzD9/Vb8CV.Oj52SO	\N	\N	\N	\N	\N	saas_admin	t	\N	\N	\N	1	2026-03-06 20:33:56.751906+00	\N	\N	2026-01-15 23:29:11.614702+00	2026-01-15 23:29:11.614702+00	f	\N	\N	\N
3	adad5fca-a277-45df-a629-1f7cf4c27d1e	avkarannellai	$2b$12$WovzF7MG/3wVrK32tGgf9egAFgW/Qgj/Yutlhh71HQxCHJVYu/yxq	Vijay	Karan	avkarannellai@gmail.com	9943604103	\N	tenant_user	f	\N	\N	\N	1	2026-02-06 18:11:38.861391+00	\N	\N	2026-02-06 09:34:12.791741+00	2026-02-06 09:34:12.791741+00	f	\N	\N	\N
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
-- Name: alarm_sounds_sound_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.alarm_sounds_sound_id_seq', 2, true);


--
-- Name: alarms_alarm_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.alarms_alarm_id_seq', 19, true);


--
-- Name: api_endpoints_endpoint_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.api_endpoints_endpoint_id_seq', 220, true);


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
-- Name: business_addresses_address_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.business_addresses_address_id_seq', 1, true);


--
-- Name: business_contacts_contact_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.business_contacts_contact_id_seq', 1, false);


--
-- Name: businesses_business_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.businesses_business_id_seq', 1, true);


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

SELECT pg_catalog.setval('public.data_model_fields_field_id_seq', 617, true);


--
-- Name: data_models_model_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.data_models_model_id_seq', 63, true);


--
-- Name: field_permissions_field_permission_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.field_permissions_field_permission_id_seq', 1, false);


--
-- Name: field_types_field_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.field_types_field_type_id_seq', 31, true);


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
-- Name: locations_location_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.locations_location_id_seq', 2, true);


--
-- Name: menu_permissions_menu_permission_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.menu_permissions_menu_permission_id_seq', 1, false);


--
-- Name: menus_menu_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.menus_menu_id_seq', 35, true);


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
-- Name: my_projects_project_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.my_projects_project_id_seq', 4, true);


--
-- Name: my_tasks_task_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.my_tasks_task_id_seq', 43, true);


--
-- Name: password_vault_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.password_vault_id_seq', 1, false);


--
-- Name: person_addresses_address_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.person_addresses_address_id_seq', 1, true);


--
-- Name: person_attachments_attachment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.person_attachments_attachment_id_seq', 8, true);


--
-- Name: person_business_roles_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.person_business_roles_role_id_seq', 1, true);


--
-- Name: person_contacts_contact_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.person_contacts_contact_id_seq', 1180, true);


--
-- Name: person_relationships_relationship_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.person_relationships_relationship_id_seq', 1, false);


--
-- Name: personal_access_tokens_pat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.personal_access_tokens_pat_id_seq', 1, true);


--
-- Name: persons_person_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.persons_person_id_seq', 1182, true);


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
-- Name: row_exposure_modes_exposure_mode_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.row_exposure_modes_exposure_mode_id_seq', 5, true);


--
-- Name: settings_setting_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.settings_setting_id_seq', 26, true);


--
-- Name: task_attachments_attachment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.task_attachments_attachment_id_seq', 34, true);


--
-- Name: task_categories_task_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.task_categories_task_category_id_seq', 4, true);


--
-- Name: task_comments_comment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.task_comments_comment_id_seq', 99, true);


--
-- Name: task_priorities_priority_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.task_priorities_priority_id_seq', 1, false);


--
-- Name: task_sprints_sprint_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.task_sprints_sprint_id_seq', 2, true);


--
-- Name: teams_team_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.teams_team_id_seq', 1, false);


--
-- Name: tenants_tenant_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.tenants_tenant_id_seq', 1, true);


--
-- Name: themes_theme_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.themes_theme_id_seq', 5, true);


--
-- Name: time_slots_time_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.time_slots_time_id_seq', 1, true);


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

SELECT pg_catalog.setval('public.user_sessions_session_id_seq', 56, true);


--
-- Name: user_teams_user_team_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.user_teams_user_team_id_seq', 1, false);


--
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: noolvan
--

SELECT pg_catalog.setval('public.users_user_id_seq', 3, true);


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
-- Name: row_exposure_modes row_exposure_modes_name_key; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.row_exposure_modes
    ADD CONSTRAINT row_exposure_modes_name_key UNIQUE (name);


--
-- Name: row_exposure_modes row_exposure_modes_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.row_exposure_modes
    ADD CONSTRAINT row_exposure_modes_pkey PRIMARY KEY (exposure_mode_id);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (setting_id);


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
-- Name: idx_settings_key_tenant_user_global; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE UNIQUE INDEX idx_settings_key_tenant_user_global ON public.settings USING btree (setting_key, tenant_id) WHERE (user_uuid IS NULL);


--
-- Name: idx_settings_key_tenant_user_specific; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE UNIQUE INDEX idx_settings_key_tenant_user_specific ON public.settings USING btree (setting_key, tenant_id, user_uuid) WHERE (user_uuid IS NOT NULL);


--
-- Name: idx_settings_tenant; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_settings_tenant ON public.settings USING btree (tenant_id);


--
-- Name: idx_settings_user_uuid; Type: INDEX; Schema: public; Owner: noolvan
--

CREATE INDEX idx_settings_user_uuid ON public.settings USING btree (user_uuid);


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
-- Name: alarm_sounds alarm_sounds_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.alarm_sounds
    ADD CONSTRAINT alarm_sounds_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


--
-- Name: alarms alarms_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.alarms
    ADD CONSTRAINT alarms_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: alarms alarms_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.alarms
    ADD CONSTRAINT alarms_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


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
-- Name: business_addresses business_addresses_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.business_addresses
    ADD CONSTRAINT business_addresses_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


--
-- Name: business_contacts business_contacts_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.business_contacts
    ADD CONSTRAINT business_contacts_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: business_contacts business_contacts_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.business_contacts
    ADD CONSTRAINT business_contacts_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


--
-- Name: businesses businesses_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.businesses
    ADD CONSTRAINT businesses_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: businesses businesses_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.businesses
    ADD CONSTRAINT businesses_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


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
-- Name: companies companies_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


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
-- Name: locations locations_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


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
-- Name: my_projects my_projects_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.my_projects
    ADD CONSTRAINT my_projects_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


--
-- Name: my_tasks my_tasks_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.my_tasks
    ADD CONSTRAINT my_tasks_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: my_tasks my_tasks_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.my_tasks
    ADD CONSTRAINT my_tasks_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


--
-- Name: password_vault password_vault_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.password_vault
    ADD CONSTRAINT password_vault_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


--
-- Name: person_addresses person_addresses_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_addresses
    ADD CONSTRAINT person_addresses_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: person_addresses person_addresses_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_addresses
    ADD CONSTRAINT person_addresses_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


--
-- Name: person_attachments person_attachments_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_attachments
    ADD CONSTRAINT person_attachments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: person_attachments person_attachments_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_attachments
    ADD CONSTRAINT person_attachments_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


--
-- Name: person_business_roles person_business_roles_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_business_roles
    ADD CONSTRAINT person_business_roles_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: person_business_roles person_business_roles_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_business_roles
    ADD CONSTRAINT person_business_roles_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


--
-- Name: person_contacts person_contacts_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_contacts
    ADD CONSTRAINT person_contacts_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: person_contacts person_contacts_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_contacts
    ADD CONSTRAINT person_contacts_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


--
-- Name: person_relationships person_relationships_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_relationships
    ADD CONSTRAINT person_relationships_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: person_relationships person_relationships_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.person_relationships
    ADD CONSTRAINT person_relationships_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


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
-- Name: persons persons_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.persons
    ADD CONSTRAINT persons_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


--
-- Name: products products_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: products products_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


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
-- Name: roles roles_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


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
-- Name: settings settings_user_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_user_uuid_fkey FOREIGN KEY (user_uuid) REFERENCES public.users(user_uuid) ON DELETE CASCADE;


--
-- Name: task_attachments task_attachments_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_attachments
    ADD CONSTRAINT task_attachments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: task_attachments task_attachments_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_attachments
    ADD CONSTRAINT task_attachments_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


--
-- Name: task_categories task_categories_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_categories
    ADD CONSTRAINT task_categories_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: task_categories task_categories_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_categories
    ADD CONSTRAINT task_categories_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


--
-- Name: task_comments task_comments_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_comments
    ADD CONSTRAINT task_comments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: task_comments task_comments_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_comments
    ADD CONSTRAINT task_comments_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


--
-- Name: task_priorities task_priorities_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_priorities
    ADD CONSTRAINT task_priorities_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: task_priorities task_priorities_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_priorities
    ADD CONSTRAINT task_priorities_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


--
-- Name: task_sprints task_sprints_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_sprints
    ADD CONSTRAINT task_sprints_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: task_sprints task_sprints_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.task_sprints
    ADD CONSTRAINT task_sprints_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


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
-- Name: teams teams_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


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
-- Name: time_slots time_slots_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.time_slots
    ADD CONSTRAINT time_slots_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


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
-- Name: user_groups user_groups_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.user_groups
    ADD CONSTRAINT user_groups_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


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
-- Name: users users_row_exposure_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noolvan
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_row_exposure_mode_id_fkey FOREIGN KEY (row_exposure_mode_id) REFERENCES public.row_exposure_modes(exposure_mode_id);


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

\unrestrict THBAItxi3UW7mdQp3UK1fgM5fSvp3x0dtUi2h4Bmh2OHDGaCsYPcPxBC2ggbmIs

