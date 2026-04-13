--
-- PostgreSQL database dump
--

\restrict yAs1m3dpwSrNx62VcUXco1Exsapl6eA9bphglncexjIHjhHLYomICZurcH99OuS

-- Dumped from database version 16.13 (Ubuntu 16.13-1.pgdg24.04+1)
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
-- Data for Name: flattening_table_policy; Type: TABLE DATA; Schema: public; Owner: karandev
--

COPY public.flattening_table_policy (id, table_name, refresh_strategy, refresh_interval_minutes, batch_size, last_refreshed, last_processed_value, is_snapshot, is_active, created_at, last_updated, destination, is_db_table, is_public_on_s3, target_table_name) FROM stdin;
12	api_endpoints	INCREMENTAL	5	50	2026-04-13 20:10:01.680301+00	2026-04-13 20:00:06.419654+00	f	t	2026-04-02 20:40:53.550074+00	2026-04-13 20:10:01.680301+00	s3	t	f	\N
10	data_models	INCREMENTAL	5	50	2026-04-13 20:10:03.501756+00	2026-04-13 20:00:08.278315+00	f	t	2026-04-02 20:27:57.580864+00	2026-04-13 20:10:03.501756+00	s3	t	f	\N
14	job_templates	INCREMENTAL	5	100	2026-04-13 20:10:04.669825+00	2026-04-13 20:00:09.510133+00	f	t	2026-04-02 20:47:22.264689+00	2026-04-13 20:10:04.669825+00	s3	t	f	\N
8	settings	FULL	5	\N	2026-04-13 20:15:01.291679+00	2026-04-13 20:05:01.194163+00	f	t	2026-04-01 20:06:54.099002+00	2026-04-13 20:15:01.291679+00	s3	t	f	\N
15	instance_menus	FULL	5	\N	2026-04-13 20:15:02.322066+00	2026-04-13 20:05:02.173711+00	f	t	2026-04-06 20:51:34.615366+00	2026-04-13 20:15:02.322066+00	s3	t	f	\N
13	collections	INCREMENTAL	5	50	2026-04-13 20:15:03.31183+00	2026-04-13 20:05:03.175215+00	f	t	2026-04-02 20:43:22.489146+00	2026-04-13 20:15:03.31183+00	s3	t	f	\N
11	field_types	FULL	5	100	2026-04-13 20:15:04.290406+00	2026-04-13 20:05:04.150661+00	f	t	2026-04-02 20:37:17.488576+00	2026-04-13 20:15:04.290406+00	s3	t	f	\N
\.


--
-- Data for Name: flattening_relation_policy; Type: TABLE DATA; Schema: public; Owner: karandev
--

COPY public.flattening_relation_policy (id, table_name, relation_name, relation_type, strategy, include_fields, target_table, is_required, created_at) FROM stdin;
10	data_models	data_model_fields.model_id	o2m	json	\N	\N	f	2026-04-02 20:31:14.860128+00
11	field_types	default_component_type_id	m2o	denormalize	{}	\N	f	2026-04-02 20:38:34.178804+00
12	instance_menus	instance_menu_client_config.instance_menu_id	o2m	json	\N	\N	f	2026-04-06 20:52:10.64076+00
\.


--
-- Name: flattening_relation_policy_id_seq; Type: SEQUENCE SET; Schema: public; Owner: karandev
--

SELECT pg_catalog.setval('public.flattening_relation_policy_id_seq', 12, true);


--
-- Name: flattening_table_policy_id_seq; Type: SEQUENCE SET; Schema: public; Owner: karandev
--

SELECT pg_catalog.setval('public.flattening_table_policy_id_seq', 15, true);


--
-- PostgreSQL database dump complete
--

\unrestrict yAs1m3dpwSrNx62VcUXco1Exsapl6eA9bphglncexjIHjhHLYomICZurcH99OuS

