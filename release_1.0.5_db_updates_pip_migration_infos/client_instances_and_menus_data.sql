--
-- PostgreSQL database dump
--

\restrict KMOWEH9QUNk31m2MeTWQDujGxuewmp7Qa3xvX7uaVenea69ADbhRFzb2j6Y6E2G

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
-- Data for Name: instances; Type: TABLE DATA; Schema: public; Owner: karandev
--

INSERT INTO public.instances (instance_id, instance_uuid, name, description, company_id, is_active, idate, last_updated) VALUES (1, '87e00f26-f11f-4680-92db-f24305533d0e', 'PKManager', 'personal app for karan', NULL, true, '2026-04-04 20:18:02.628796+00', '2026-04-04 20:18:02.628796+00');


--
-- Data for Name: client_offline_dataset; Type: TABLE DATA; Schema: public; Owner: karandev
--

INSERT INTO public.client_offline_dataset (id, instance_id, dataset_key, label, source_kind, model_id, flattening_policy_id, read_endpoint_id, incremental_field, batch_size, local_lifecycle_jsonb, is_active, idate, last_updated) VALUES (1, 1, 'instance_menus', NULL, 'flattened_s3', NULL, 15, NULL, 'last_updated', NULL, '{}', true, '2026-04-06 20:59:42.133864+00', '2026-04-06 20:59:42.133864+00');
INSERT INTO public.client_offline_dataset (id, instance_id, dataset_key, label, source_kind, model_id, flattening_policy_id, read_endpoint_id, incremental_field, batch_size, local_lifecycle_jsonb, is_active, idate, last_updated) VALUES (2, 1, 'collections', NULL, 'flattened_s3', NULL, 13, NULL, 'last_updated', NULL, '{}', true, '2026-04-06 20:59:58.893726+00', '2026-04-06 20:59:58.893726+00');
INSERT INTO public.client_offline_dataset (id, instance_id, dataset_key, label, source_kind, model_id, flattening_policy_id, read_endpoint_id, incremental_field, batch_size, local_lifecycle_jsonb, is_active, idate, last_updated) VALUES (3, 1, 'field_types', NULL, 'flattened_s3', NULL, 11, NULL, 'last_updated', NULL, '{}', true, '2026-04-06 21:00:40.054425+00', '2026-04-06 21:00:40.054425+00');
INSERT INTO public.client_offline_dataset (id, instance_id, dataset_key, label, source_kind, model_id, flattening_policy_id, read_endpoint_id, incremental_field, batch_size, local_lifecycle_jsonb, is_active, idate, last_updated) VALUES (4, 1, 'data_models', NULL, 'flattened_s3', NULL, 10, NULL, 'last_updated', NULL, '{}', true, '2026-04-06 21:00:50.11885+00', '2026-04-06 21:00:50.11885+00');


--
-- Data for Name: client_offline_write_endpoint; Type: TABLE DATA; Schema: public; Owner: karandev
--



--
-- Data for Name: instance_menus; Type: TABLE DATA; Schema: public; Owner: karandev
--

INSERT INTO public.instance_menus (id, instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by, idate, last_updated) VALUES (7, 1, 'Data Privacy', '/data-privacy', false, 'cloud', NULL, 9, 2, '2026-04-07 19:36:58.668038+00', '2026-04-07 19:36:58.668038+00');
INSERT INTO public.instance_menus (id, instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by, idate, last_updated) VALUES (2, 1, 'Businesses', '/businesses', false, 'location', NULL, 4, 2, '2026-04-07 18:43:44.037399+00', '2026-04-07 19:41:26.099512+00');
INSERT INTO public.instance_menus (id, instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by, idate, last_updated) VALUES (3, 1, 'My Tasks', '/my-tasks', false, 'document', NULL, 5, 2, '2026-04-07 19:28:10.112032+00', '2026-04-07 19:42:10.421392+00');
INSERT INTO public.instance_menus (id, instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by, idate, last_updated) VALUES (4, 1, 'Work Reports', '/work-reports', false, 'workflow', NULL, 6, 2, '2026-04-07 19:30:41.30853+00', '2026-04-07 19:42:22.628462+00');
INSERT INTO public.instance_menus (id, instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by, idate, last_updated) VALUES (5, 1, 'Alarms', '/alarms', false, 'bell', NULL, 7, 2, '2026-04-07 19:31:30.316878+00', '2026-04-07 19:42:33.331641+00');
INSERT INTO public.instance_menus (id, instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by, idate, last_updated) VALUES (6, 1, 'Vault', '/vault', false, 'credit-card', NULL, 8, 2, '2026-04-07 19:35:29.609186+00', '2026-04-07 19:42:42.192952+00');
INSERT INTO public.instance_menus (id, instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by, idate, last_updated) VALUES (8, 1, 'Settings', '/settings', false, 'settings', NULL, 10, 2, '2026-04-07 19:38:56.378082+00', '2026-04-07 19:42:55.306408+00');
INSERT INTO public.instance_menus (id, instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by, idate, last_updated) VALUES (9, 1, 'Worker Status', NULL, false, 'bluetooth', NULL, 1, 2, '2026-04-07 19:40:15.868463+00', '2026-04-07 19:43:18.426186+00');
INSERT INTO public.instance_menus (id, instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by, idate, last_updated) VALUES (10, 1, 'WebSocket Log', NULL, false, 'server', NULL, 2, 2, '2026-04-07 19:40:39.199669+00', '2026-04-07 19:44:10.978266+00');
INSERT INTO public.instance_menus (id, instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by, idate, last_updated) VALUES (1, 1, 'Persons', '/persons', false, 'user', NULL, 3, 2, '2026-04-07 18:37:43.735+00', '2026-04-09 20:36:52.233253+00');


--
-- Data for Name: instance_menu_client_config; Type: TABLE DATA; Schema: public; Owner: karandev
--

INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (6, 2, 'web', 'web', true, 2, '2026-04-07 19:25:23.86357+00', '2026-04-07 19:25:23.86357+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (7, 2, 'android', 'webview', true, 2, '2026-04-07 19:25:23.866173+00', '2026-04-07 19:25:23.866173+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (8, 2, 'ios', 'webview', true, 2, '2026-04-07 19:25:23.867783+00', '2026-04-07 19:25:23.867783+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (9, 2, 'macos', 'webview', true, 2, '2026-04-07 19:25:23.869392+00', '2026-04-07 19:25:23.869392+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (10, 2, 'linux', 'webview', true, 2, '2026-04-07 19:25:23.870933+00', '2026-04-07 19:25:23.870933+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (11, 9, 'web', 'web', false, 2, '2026-04-07 19:44:42.35071+00', '2026-04-07 19:44:42.35071+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (12, 9, 'android', 'native', true, 2, '2026-04-07 19:44:42.353016+00', '2026-04-07 19:44:42.353016+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (13, 9, 'ios', 'native', true, 2, '2026-04-07 19:44:42.354652+00', '2026-04-07 19:44:42.354652+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (14, 9, 'macos', 'native', true, 2, '2026-04-07 19:44:42.356309+00', '2026-04-07 19:44:42.356309+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (15, 9, 'linux', 'native', true, 2, '2026-04-07 19:44:42.357919+00', '2026-04-07 19:44:42.357919+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (16, 10, 'web', 'web', false, 2, '2026-04-07 19:44:56.991539+00', '2026-04-07 19:44:56.991539+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (17, 10, 'android', 'native', true, 2, '2026-04-07 19:44:56.993283+00', '2026-04-07 19:44:56.993283+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (18, 10, 'ios', 'native', true, 2, '2026-04-07 19:44:56.994824+00', '2026-04-07 19:44:56.994824+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (19, 10, 'macos', 'native', true, 2, '2026-04-07 19:44:56.996249+00', '2026-04-07 19:44:56.996249+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (20, 10, 'linux', 'native', true, 2, '2026-04-07 19:44:56.997679+00', '2026-04-07 19:44:56.997679+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (21, 3, 'web', 'web', true, 2, '2026-04-07 19:45:22.568189+00', '2026-04-07 19:45:22.568189+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (22, 3, 'android', 'webview', true, 2, '2026-04-07 19:45:22.570449+00', '2026-04-07 19:45:22.570449+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (23, 3, 'ios', 'webview', true, 2, '2026-04-07 19:45:22.572199+00', '2026-04-07 19:45:22.572199+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (24, 3, 'macos', 'webview', true, 2, '2026-04-07 19:45:22.573963+00', '2026-04-07 19:45:22.573963+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (25, 3, 'linux', 'webview', true, 2, '2026-04-07 19:45:22.575688+00', '2026-04-07 19:45:22.575688+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (26, 4, 'web', 'web', true, 2, '2026-04-07 19:45:35.688739+00', '2026-04-07 19:45:35.688739+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (27, 4, 'android', 'webview', true, 2, '2026-04-07 19:45:35.690536+00', '2026-04-07 19:45:35.690536+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (28, 4, 'ios', 'webview', true, 2, '2026-04-07 19:45:35.69216+00', '2026-04-07 19:45:35.69216+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (29, 4, 'macos', 'webview', true, 2, '2026-04-07 19:45:35.693641+00', '2026-04-07 19:45:35.693641+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (30, 4, 'linux', 'webview', true, 2, '2026-04-07 19:45:35.695174+00', '2026-04-07 19:45:35.695174+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (31, 5, 'web', 'web', true, 2, '2026-04-07 19:45:50.924424+00', '2026-04-07 19:45:50.924424+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (32, 5, 'android', 'webview', true, 2, '2026-04-07 19:45:50.926074+00', '2026-04-07 19:45:50.926074+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (33, 5, 'ios', 'webview', true, 2, '2026-04-07 19:45:50.927593+00', '2026-04-07 19:45:50.927593+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (34, 5, 'macos', 'webview', true, 2, '2026-04-07 19:45:50.929105+00', '2026-04-07 19:45:50.929105+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (35, 5, 'linux', 'webview', true, 2, '2026-04-07 19:45:50.930674+00', '2026-04-07 19:45:50.930674+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (36, 6, 'web', 'web', true, 2, '2026-04-07 19:46:12.21945+00', '2026-04-07 19:46:12.21945+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (37, 6, 'android', 'webview', true, 2, '2026-04-07 19:46:12.221013+00', '2026-04-07 19:46:12.221013+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (38, 6, 'ios', 'webview', true, 2, '2026-04-07 19:46:12.222677+00', '2026-04-07 19:46:12.222677+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (39, 6, 'macos', 'webview', true, 2, '2026-04-07 19:46:12.22404+00', '2026-04-07 19:46:12.22404+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (40, 6, 'linux', 'webview', true, 2, '2026-04-07 19:46:12.225487+00', '2026-04-07 19:46:12.225487+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (41, 8, 'web', 'web', true, 2, '2026-04-07 19:46:21.218502+00', '2026-04-07 19:46:21.218502+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (42, 8, 'android', 'webview', true, 2, '2026-04-07 19:46:21.220102+00', '2026-04-07 19:46:21.220102+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (43, 8, 'ios', 'webview', true, 2, '2026-04-07 19:46:21.221524+00', '2026-04-07 19:46:21.221524+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (44, 8, 'macos', 'webview', true, 2, '2026-04-07 19:46:21.223089+00', '2026-04-07 19:46:21.223089+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (45, 8, 'linux', 'webview', true, 2, '2026-04-07 19:46:21.224586+00', '2026-04-07 19:46:21.224586+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (1, 1, 'web', 'web', true, 2, '2026-04-07 18:40:03.59422+00', '2026-04-09 20:36:52.225261+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (2, 1, 'android', 'webview', true, 2, '2026-04-07 18:40:03.597952+00', '2026-04-09 20:36:52.227468+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (3, 1, 'ios', 'webview', true, 2, '2026-04-07 18:40:03.599689+00', '2026-04-09 20:36:52.228924+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (4, 1, 'macos', 'webview', true, 2, '2026-04-07 18:40:03.601338+00', '2026-04-09 20:36:52.230404+00');
INSERT INTO public.instance_menu_client_config (id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated) VALUES (5, 1, 'linux', 'webview', true, 2, '2026-04-07 18:40:03.602915+00', '2026-04-09 20:36:52.231794+00');


--
-- Data for Name: instance_offline_settings; Type: TABLE DATA; Schema: public; Owner: karandev
--

INSERT INTO public.instance_offline_settings (instance_id, enable_offline_data, schema_pack_version, operator_notes, last_updated) VALUES (1, true, '1', '', '2026-04-06 20:58:01.952605+00');


--
-- Name: client_offline_dataset_id_seq; Type: SEQUENCE SET; Schema: public; Owner: karandev
--

SELECT pg_catalog.setval('public.client_offline_dataset_id_seq', 4, true);


--
-- Name: client_offline_write_endpoint_id_seq; Type: SEQUENCE SET; Schema: public; Owner: karandev
--

SELECT pg_catalog.setval('public.client_offline_write_endpoint_id_seq', 1, false);


--
-- Name: instance_menu_client_config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: karandev
--

SELECT pg_catalog.setval('public.instance_menu_client_config_id_seq', 65, true);


--
-- Name: instance_menus_id_seq; Type: SEQUENCE SET; Schema: public; Owner: karandev
--

SELECT pg_catalog.setval('public.instance_menus_id_seq', 10, true);


--
-- Name: instances_instance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: karandev
--

SELECT pg_catalog.setval('public.instances_instance_id_seq', 1, true);


--
-- PostgreSQL database dump complete
--

\unrestrict KMOWEH9QUNk31m2MeTWQDujGxuewmp7Qa3xvX7uaVenea69ADbhRFzb2j6Y6E2G

