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
