# claude-iterate

Spec-driven autonomous iteration for Claude Code. Define a spec, run `iterate.sh`, and Claude works through tasks one at a time — committing, resuming sessions, and signaling when it needs input or is done.

## Quick Start

Bootstrap into any project:

```bash
curl -sL https://raw.githubusercontent.com/thedaneeffect/claude-iterate/main/bootstrap.sh | bash
```

This copies `iterate.sh` and `SPEC.md` into your project, creates a `specs/` directory, and updates `.gitignore`.

## Usage

### 1. Define a spec

Use the `/spec` slash command in Claude Code:

```
/spec my_feature
```

Claude will explore your codebase, ask clarifying questions, and write a structured spec to `specs/my_feature.md`.

Or write one manually:

```markdown
# My Feature

## Description
What this feature is and why it matters.

## Criteria
- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2

## Tasks
- [ ] Task 1
- [ ] Task 2
```

### 2. Run it

```bash
./iterate.sh my_feature        # default 10 iterations
./iterate.sh my_feature 20     # up to 20 iterations
```

Claude will:
- Pick the next unchecked task
- Implement it
- Check it off in the spec
- Commit changes
- Repeat until `[DONE]` or max iterations

### 3. Signals

- **`[DONE]`** — All criteria satisfied, spec complete
- **`[USER]`** — Claude needs human input before continuing

## File Structure

```
your-project/
├── iterate.sh          # Spec executor (committed)
├── SPEC.md             # Spec format reference (committed)
├── .claude/skills/spec/ # /spec slash command (committed)
├── specs/              # Your spec files (committed)
│   ├── my_feature.md
│   └── .sessions/      # Session persistence (gitignored)
└── logs/               # Run logs (gitignored)
    └── 20250208-143022-my_feature/
        ├── step-1.md
        ├── step-2.md
        └── ...
```

## Requirements

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) (`claude` command)
- `jq` for JSON parsing
- `git` for cloning during bootstrap
