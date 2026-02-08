#!/usr/bin/env bash
set -euo pipefail

# iterate.sh — Autonomous spec executor
# Usage: ./iterate.sh <spec_name> [max_iterations]

SPEC_NAME="${1:-}"
MAX_ITERATIONS="${2:-10}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SPEC_FILE="$SCRIPT_DIR/specs/${SPEC_NAME}.md"
META_PROMPT="$SCRIPT_DIR/SPEC.md"
README="$SCRIPT_DIR/README.md"
LOG_DIR="$SCRIPT_DIR/logs"
SESSION_DIR="$SCRIPT_DIR/specs/.sessions"
RUN_ID="$(date +%Y%m%d-%H%M%S)-${SPEC_NAME}"

# --- Validation ---

if [[ -z "$SPEC_NAME" ]]; then
    echo "Usage: ./iterate.sh <spec_name> [max_iterations]"
    echo ""
    echo "  spec_name       Name of the spec file in specs/ (without .md)"
    echo "  max_iterations  Maximum iterations (default: 10)"
    exit 1
fi

if [[ ! -f "$META_PROMPT" ]]; then
    echo "Error: SPEC.md not found at $META_PROMPT"
    exit 1
fi

if [[ ! -f "$SPEC_FILE" ]]; then
    echo "Error: Spec file not found at $SPEC_FILE"
    echo "Create it first: specs/${SPEC_NAME}.md"
    exit 1
fi

# --- Setup ---

mkdir -p "$LOG_DIR/$RUN_ID" "$SESSION_DIR"

SESSION_FILE="$SESSION_DIR/$SPEC_NAME"
SESSION_ID=""
if [[ -f "$SESSION_FILE" ]]; then
    SESSION_ID="$(cat "$SESSION_FILE")"
fi

# Build the initial prompt from SPEC.md + README.md + spec file
build_prompt() {
    local prompt=""

    prompt+="$(cat "$META_PROMPT")"
    prompt+=$'\n\n---\n\n'

    if [[ -f "$README" ]]; then
        prompt+="# Project Context"$'\n\n'
        prompt+="$(cat "$README")"
        prompt+=$'\n\n---\n\n'
    fi

    prompt+="# Current Spec"$'\n\n'
    prompt+="$(cat "$SPEC_FILE")"
    prompt+=$'\n\n---\n\n'
    prompt+="Begin working on the next unchecked task."

    echo "$prompt"
}

# Run claude and extract result text + session ID from JSON output
# Sets: OUTPUT (result text), SESSION_ID (updated)
run_claude() {
    local prompt="$1"
    local flags="$2"

    local raw
    # shellcheck disable=SC2086
    raw=$(echo "$prompt" | claude --dangerously-skip-permissions -p --output-format json $flags 2>&1) || true

    # Extract result text and session_id from JSON
    OUTPUT=$(echo "$raw" | jq -r '.result // empty' 2>/dev/null) || true
    local new_session_id
    new_session_id=$(echo "$raw" | jq -r '.session_id // empty' 2>/dev/null) || true

    # If JSON parsing failed, fall back to raw output
    if [[ -z "$OUTPUT" ]]; then
        OUTPUT="$raw"
    fi

    # Persist session ID
    if [[ -n "$new_session_id" ]]; then
        SESSION_ID="$new_session_id"
        echo "$SESSION_ID" > "$SESSION_FILE"
    fi
}

echo "=== iterate.sh ==="
echo "Spec:       $SPEC_NAME"
echo "Max iters:  $MAX_ITERATIONS"
echo "Run ID:     $RUN_ID"
echo "Log dir:    $LOG_DIR/$RUN_ID"
if [[ -n "$SESSION_ID" ]]; then
    echo "Session:    $SESSION_ID (resuming)"
else
    echo "Session:    (new)"
fi
echo ""

ITERATION=0

while [[ $ITERATION -lt $MAX_ITERATIONS ]]; do
    ITERATION=$((ITERATION + 1))
    STEP_LOG="$LOG_DIR/$RUN_ID/step-${ITERATION}.md"

    echo "--- Iteration $ITERATION / $MAX_ITERATIONS ---"

    if [[ -n "$SESSION_ID" && $ITERATION -gt 1 ]]; then
        # Continuing within a run — resume existing session
        run_claude "Continue with the next task." "--resume $SESSION_ID"
    elif [[ -n "$SESSION_ID" && $ITERATION -eq 1 ]]; then
        # First iteration of a new run, but session exists from prior run
        run_claude "$(build_prompt)" "--resume $SESSION_ID"
    else
        # Brand new session (no prior session file)
        run_claude "$(build_prompt)" ""
    fi

    # Log the step
    {
        echo "# Step $ITERATION"
        echo ""
        echo "## Prompt"
        echo ""
        if [[ $ITERATION -eq 1 ]]; then
            echo "(Initial prompt assembled from SPEC.md + README.md + spec file)"
        else
            echo "Continue with the next task."
        fi
        echo ""
        echo "## Output"
        echo ""
        echo "$OUTPUT"
    } > "$STEP_LOG"

    echo "$OUTPUT"
    echo ""

    # Check for [DONE]
    if echo "$OUTPUT" | grep -q '\[DONE\]'; then
        echo "=== Spec complete! ==="
        exit 0
    fi

    # Check for [USER]
    if echo "$OUTPUT" | grep -q '\[USER\]'; then
        echo ""
        echo "=== Claude needs input ==="
        echo ""
        read -r -p "> " USER_INPUT

        # Don't count [USER] iterations — decrement so it doesn't consume a slot
        ITERATION=$((ITERATION - 1))

        # Log user input
        STEP_LOG_USER="$LOG_DIR/$RUN_ID/step-${ITERATION}-user.md"
        {
            echo "# User Input (after step $ITERATION)"
            echo ""
            echo "$USER_INPUT"
        } > "$STEP_LOG_USER"

        # Feed user input back, resuming the same session
        run_claude "$USER_INPUT" "--resume $SESSION_ID"

        # Log the response
        STEP_LOG_RESPONSE="$LOG_DIR/$RUN_ID/step-$((ITERATION + 1))-response.md"
        {
            echo "# Response to User Input"
            echo ""
            echo "$OUTPUT"
        } > "$STEP_LOG_RESPONSE"

        echo "$OUTPUT"
        echo ""

        # Check signals again after user input response
        if echo "$OUTPUT" | grep -q '\[DONE\]'; then
            echo "=== Spec complete! ==="
            exit 0
        fi
    fi

done

echo "=== Max iterations ($MAX_ITERATIONS) reached ==="
exit 1
