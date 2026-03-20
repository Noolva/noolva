# Job Templates Guide

This document describes job template categories, structure, and how workflow definitions work in the job engine.

---

## Template category (`template_category`)

Every job template has a **template_category** with one of three values:

| Value      | Description |
|-----------|-------------|
| **task**  | Atomic work executed by a single handler. No orchestration; `workflow_definition` is NULL. |
| **workflow** | Orchestration of multiple tasks. Uses `workflow_definition` to define steps and execution order. |
| **system** | Internal platform operations used by the job engine itself (e.g. delay, health_check, loop, if). |

### Structure by category

```
job_templates
   │
   ├── task template
   │      workflow_definition = NULL
   │      handler_type / handler_function_name define the single unit of work
   │
   ├── workflow template
   │      workflow_definition != NULL
   │      execution: "sequential" | "parallel"
   │      steps[] reference other templates (tasks or sub-workflows)
   │
   └── system template
          Internal use (delay, health_check, loop, if, etc.)
```

### Example: system templates

| Template       | Purpose                |
|----------------|------------------------|
| `delay`        | Wait before next step  |
| `health_check`  | System monitoring      |
| `loop`         | Iterate over items     |
| `if`           | Conditional branching  |

Example payload for a system task:

```json
{
  "task": "delay",
  "input": {
    "seconds": 300
  }
}
```

---

## Workflow definition

Used only when **template_category = 'workflow'**.

### Execution mode

- **`execution`**: `"sequential"` or `"parallel"`
  - **sequential**: steps run one after another; step N can use output of step N-1.
  - **parallel**: steps can run concurrently (when supported by the engine).

### Step structure

Each step has:

- **id**: unique step identifier (e.g. `"step1"`, `"step2"`).
- **task**: template name to run (e.g. `"auto_crud_get_records"`, `"auto_crud_post_records"`).
- **input**: object passed to the task; values can use **expressions** (see below).
- **output**: name to bind this step’s result to (e.g. `"record"`, `"new_record"`) for use in later steps or in `output_schema`.

### Expression references

- **`$input.<key>`** – job payload (e.g. `$input.model_name`, `$input.record_id`).
- **`$step.<step_id>.output`** or **`$<output_name>`** – output from a previous step (e.g. `$record.records[0]`, `$new_record.inserted_id`).

### Sample workflow definition

```json
{
  "version": "1.0",
  "execution": "sequential",
  "steps": [
    {
      "id": "step1",
      "task": "auto_crud_get_records",
      "input": {
        "model_name": "$input.model_name",
        "filters": {
          "id": "$input.record_id"
        }
      },
      "output": "record"
    },
    {
      "id": "step2",
      "task": "auto_crud_post_records",
      "input": {
        "model_name": "$input.model_name",
        "data": "$record.records[0]"
      },
      "output": "new_record"
    }
  ]
}
```

---

## Output schema (workflow result shape)

For workflows, **output_schema** can describe how to map step outputs into the final job result. Properties can reference step outputs via **source**:

```json
{
  "type": "object",
  "properties": {
    "record_id": {
      "source": "$new_record.inserted_id"
    },
    "record_data": {
      "source": "$new_record.inserted_data"
    }
  }
}
```

The job engine uses these `source` expressions to build the returned result object.

---

## Summary

- **task**: single handler, no `workflow_definition`.
- **workflow**: `workflow_definition` with `execution` and `steps`; steps reference task template names and use `$input.*` / `$step.*` (or `$<output_name>`) for data flow.
- **system**: built-in engine operations (delay, health_check, loop, if, etc.).
- **output_schema**: optional mapping of step outputs to the final job result using `source` expressions.
