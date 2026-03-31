# Noolva Database Structure

This directory contains the complete, classified, and ordered SQL schema definitions for the Noolva SaaS Platform.
The schema is modular, enabling a Multi-Tenant, Dynamic, and AI-Powered architecture.

## 🏗️ Schema Modules & File Order

The SQL files are numbered to ensure correct dependency verification during execution.

| Order | File | Domain | Key Tables & Features |
| :--- | :--- | :--- | :--- |
| **01** | `01_core_identity.sql` | **Identity** | `users` - Central entity for Auth & Profiles. |
| **02** | `02_tenants_and_companies.sql` | **Tenancy** | `tenants` (Billing), `companies` (Org), `user_companies`. Supports Hierarchy. |
| **03** | `03_apps_and_modules.sql` | **Platform** | `apps`, `modules`, `module_features`. Supports Scoping (Global/Tenant) & Cloning logic. |
| **04** | `04_roles_and_permissions.sql` | **Access** | `roles`, `role_module_features`, `user_module_features`. RBAC & Granular Permissions. |
| **05** | `05_data_models.sql` | **Data Engine** | `data_models`, `data_model_fields` (Dynamic Tables). `field_types`, `collections` (Option Sets), `ui_component_types`, `app_views`, `menus`. |
| **06** | `06_api_and_operations.sql` | **Ops & API** | `flattening_table_policy`, `flattening_relation_policy`, `data_lifecycle_policy`, `api_endpoints`, `audit_logs`. |
| **07** | `07_system_utilities.sql` | **Utilities** | `actions`, `workflows`, `workflow_runs`, `job_queue` (Executor). `settings` (Global/Tenant config), `integrations`, `assets`. |
| **08** | `08_ai_model.sql` | **AI Engine** | `ai_knowledge_nodes` (Graph), `ai_knowledge_relations` (Edges), `ai_events` (Fact Store), `ai_knowledge_vectors` (Embeddings). |
| **09** | `09_ai_addons.sql` | **AI Extensions** | `ai_query_plans` (Audit), `ai_rules` (Logic Engine), `ai_entity_aliases`. |

## 🌱 Seed Data

These files populate the system with essential defaults.

| File | Purpose |
| :--- | :--- |
| `95_seed_settings.sql` | Standard System Settings (App Name, Branding, Security Policies). |
| `96_seed_ai_model.sql` | Sample AI Graph Nodes, Facts, and Rules. |
| `97_seed_actions.sql` | System Actions (`send_email`, `app_clone`) with concurrency configs. |
| `98_seed_ui_component_types.sql` | Registry of UI layouts (`Row`, `Table`, `Input`). |
| `99_seed_field_types.sql` | Registry of Data Types (`Text`, `Number`, `Image`). |

## 🚀 Usage

To initialize the database from scratch:

```bash
# 1. (Optional) Reset Database
# dropdb noolva
# createdb noolva

# 2. Run the Master Script (Concatenated)
psql -d noolva -f noolvandb.sql
```

Alternatively, run files individually in the numbered order to debug specific modules.

## 📦 Migrations (Existing Databases)

For databases that were created before schema changes, run the appropriate migration scripts **in order**:

```bash
# 1. Themes refactor (add themes table, migrate settings, add Themes menu)
psql -d noolva -f db-structure/update_old_db_themes.sql

# 2. Add header/sidebar colors to existing themes
psql -d noolva -f db-structure/update_themes_add_header_sidebar_bg.sql
```

Replace `noolva` with your actual database name if different.

## 🌟 Key Features

1.  **Multi-Tenancy**:
    *   **Hierarchy**: Tenant -> Company.
    *   **Scoping**: Apps and Settings can be Global (SaaS Default) or Tenant-Specific.

2.  **Dynamic Data Engine**:
    *   Define Models (Tables) and Fields at runtime.
    *   **Field Types**: Rich types linked to **UI Components**.
    *   **Collections**: Global or Tenant-scoped reusable option sets.

3.  **Workflow & Automation**:
    *   **Actions**: Atomic units of work with schema validation.
    *   **Workflows**: Orchestrated sequences triggered by events or schedules.
    *   **Job Queue**: Robust execution engine supporting Sequential/Parallel modes.

4.  **AI Power**:
    *   **Knowledge Graph**: Semantic Nodes & Relations.
    *   **Event Store**: Immutable "Truth" of system events.
    *   **Vector Search**: Built-in embeddings for RAG.
    *   **Rules Engine**: Deterministic logic layered over the graph.
