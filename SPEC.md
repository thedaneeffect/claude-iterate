# Spec Format

This document defines the format for spec files and the rules for working with them.
It is used in two modes:

- **Interactive**: Feed this file into a Claude session to collaboratively define a new spec
- **Autonomous**: `iterate.sh` includes this as instructions during autonomous execution

---

## Spec File Format

Spec files live in `specs/{name}.md` and follow this structure:

```markdown
# {Name}

## Description
What this feature is and why it matters. This is the anchor —
criteria and tasks must satisfy this description.

## Criteria
- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2

## Tasks
- [ ] Task 1
- [ ] Task 2
```

**Description** is immutable — it defines the intent and scope of the work.
**Criteria** are the measurable conditions that prove the work is done. They can be
refined during implementation (reworded for clarity, split, made more precise) but
must always satisfy the description.
**Tasks** are the implementation steps. They are freely mutable — check off completed
tasks, add discovered tasks, reorder, split, or remove tasks as understanding evolves.

---

## Interactive Mode — Defining a Spec

When a user asks you to define a spec using this format:

1. Read the project's `README.md` (if it exists) for context about the codebase
2. Ask clarifying questions about the work's scope, goals, and constraints
3. Draft the spec file with a clear description, concrete acceptance criteria,
   and an initial task breakdown
4. Write the result to `specs/{name}.md` where `{name}` is a short snake_case
   identifier agreed upon with the user

Guidelines:
- Criteria should be verifiable — "works correctly" is bad, "returns 200 for valid input" is good
- Tasks should be small enough for a single iteration (~1 commit of work)
- Include tasks for tests where appropriate
- Don't over-plan — 3-7 tasks is typical; more will be discovered during implementation

---

## Autonomous Mode — Executing a Spec

When running autonomously via `iterate.sh`, follow these rules:

### Each Iteration

1. **Read the spec file** in `specs/` to find the current state
2. **Read `README.md`** (if it exists) for project context
3. **Pick the next unchecked task** (`- [ ]`) from the Tasks section
4. **Implement it** — write code, tests, whatever the task requires
5. **Update the spec file**:
   - Check off the completed task: `- [x]`
   - Add any newly discovered tasks
   - Refine criteria wording if needed (must still satisfy the description)
6. **Commit** all changes with a concise message

### Signals

End every response with exactly ONE of:

- `[DONE]` — ALL criteria are checked off (`- [x]`). The feature is complete.
- `[USER]` — you need human input. Follow this format:
  ```
  [USER]
  <your question here>
  1. <option>
  2. <option>
  ```
- Otherwise, end normally — `iterate.sh` will send "Continue with the next task."

### Rules

- Complete exactly ONE task per iteration
- If a task is too large, split it into subtasks in the spec file and work on the first one
- If blocked (missing info, unclear requirement, external dependency), signal `[USER]`
- The spec is NOT done until all criteria are satisfied — don't signal `[DONE]` early
- Do not modify `iterate.sh` or `SPEC.md` unless a task explicitly requires it
- Use `[USER]` when:
  - Multiple valid architectural approaches exist with meaningful tradeoffs
  - A requirement is ambiguous and guessing wrong would waste effort
  - A decision has security or data implications you shouldn't make alone
