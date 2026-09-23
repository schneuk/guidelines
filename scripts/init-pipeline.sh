#!/usr/bin/env bash
set -e

# ==============================================================================
# ACDO Pipeline Initializer
# Usage: ./init-pipeline.sh [options] [target-directory] [project-name]
# ==============================================================================

METHODS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GLOBAL_RULES_DIR="${HOME}/.gemini/config/rules"
GLOBAL_RULE_FILE="${GLOBAL_RULES_DIR}/acdo.md"

ENABLE_PROJECT=true
ENABLE_GLOBAL=false
POSITIONAL_ARGS=()

show_help() {
    cat <<EOF
ACDO Pipeline Initializer
Usage:
  $(basename "$0") [options] [target-directory] [project-name]

Options:
  -p, --project        Embed GUIDELINES.md, templates/, and AGENTS.md directly in the project root for 100% portable discovery (default: enabled).
  --no-project         Skip embedding guidelines and AGENTS.md in the project root.
  -g, --global         Install or update the global Antigravity rule in ~/.gemini/config/rules/acdo.md.
  -b, --both           Apply both project-level embedding (100% portable) and global machine rule.
  -h, --help           Display this help message.

Examples:
  # Scaffold a fully self-contained project (100% portable to any machine)
  $(basename "$0") /path/to/my-project kan-shooter

  # Scaffold a project and also install the global machine rule
  $(basename "$0") --both /path/to/my-project kan-shooter

  # Install the global Antigravity rule only (no project directory required)
  $(basename "$0") --global
EOF
}

install_global_rule() {
    mkdir -p "$GLOBAL_RULES_DIR"
    cat <<EOF > "$GLOBAL_RULE_FILE"
# Autonomous Continuous Development Organization (ACDO) Rule

When working in any project or workspace that contains a \`.pipeline/\` directory:

1. **Framework Adherence**:
   - Always follow the 6-stage autonomous lifecycle and Git execution protocol defined in the project's embedded \`.pipeline/GUIDELINES.md\` (or fallback to \`file://$METHODS_DIR/GUIDELINES.md\`).

2. **Zero Working-Tree Disruption**:
   - Never write code or run experimental fixes directly on the primary checkout.
   - Always spawn an isolated Git worktree:
     \`git worktree add -b feat/<ID> .worktrees/<ID> HEAD\`
   - All code generation, testing, and conventional commits must occur inside \`.worktrees/<ID>\`.

3. **Pipeline State & Templates**:
   - Use embedded schemas in \`.pipeline/templates/\` (\`ticket.md\`, \`rfc.md\`, \`release.md\`).
   - Read \`.pipeline/config.json\` for project-specific test, lint, and build commands.
   - Track ticket progression across \`.pipeline/tickets/\` (\`inbox/\` -> \`ready/\` -> \`active/\` -> \`validated/\` -> \`archive/\`).
   - Keep \`.pipeline/BOARD.md\` updated with current DAG dependencies.

4. **Quality Gates & Merge Protocol**:
   - Run tests defined in \`.pipeline/config.json\` with up to 3 self-healing correction attempts.
   - Only merge after all quality gates pass, using non-fast-forward merge:
     \`git merge --no-ff feat/<ID> -m "feat(<scope>): merge <ticket-title> [<ID>]"\`
   - Clean up worktree and branch:
     \`git worktree remove .worktrees/<ID> && git worktree prune && git branch -d feat/<ID>\`

5. **Subagent Delegation & Guardrails**:
   - Delegate exploratory codebase searches in Stage 2 to a read-only \`research\` subagent to prevent context window bloat.
   - Subagents modifying code must operate strictly inside \`.worktrees/<ID>\`.
   - Subagents must return distilled summaries, never raw logs. Depth is limited to 1.
EOF
    echo "🌐 Installed global Antigravity rule: $GLOBAL_RULE_FILE"
}

install_project_rule() {
    cat <<EOF > AGENTS.md
# 🤖 Project Directives & Autonomous Engineering Guidelines

This repository is governed by the **ACDO (Autonomous Continuous Development Organization)** framework and is 100% self-contained.

## Core Rules for AI Agents
1. **Framework Specification & Runbook**:
   - All operating rules, ticket schemas, and Git runbooks are embedded in:
     [\`.pipeline/GUIDELINES.md\`](.pipeline/GUIDELINES.md)
2. **Standard Templates**:
   - Ticket Schema: [\`.pipeline/templates/ticket.md\`](.pipeline/templates/ticket.md)
   - Architecture RFC: [\`.pipeline/templates/rfc.md\`](.pipeline/templates/rfc.md)
   - Release Manifest: [\`.pipeline/templates/release.md\`](.pipeline/templates/release.md)
3. **Working Tree Isolation**:
   - Never implement features or modifications directly in this primary checkout directory.
   - Always create and work inside an isolated worktree under \`.worktrees/<ID>\` on branch \`feat/<ID>\`:
     \`\`\`bash
     git worktree add -b feat/<ID> .worktrees/<ID> HEAD
     cd .worktrees/<ID>
     \`\`\`
4. **Pipeline State & Config**:
   - Configuration & Commands: \`.pipeline/config.json\`
   - Active Kanban & Dependency DAG: \`.pipeline/BOARD.md\`
   - Ticket Lifecycles: \`.pipeline/tickets/{inbox,queued,ready,active,validated,archive}\`
5. **Quality Verification & Merging**:
   - Run tests configured in \`.pipeline/config.json\`.
   - Never merge without passing all test and lint quality gates.
   - Merge back to main using non-fast-forward merge: \`git merge --no-ff feat/<ID>\`.
   - Remove the worktree after merging: \`git worktree remove .worktrees/<ID> && git worktree prune\`.
6. **Subagent Delegation & Boundaries**:
   - Delegate Stage 2 codebase exploration to a read-only \`research\` subagent.
   - Restrict code-modifying subagents strictly to \`.worktrees/<ID>\`.
   - Ensure subagents return distilled summaries; maintain depth-1 hierarchy.
EOF
    # Also create GEMINI.md symlink for Antigravity native rule discovery
    ln -sf AGENTS.md GEMINI.md
    echo "📋 Created self-contained agent directives: AGENTS.md (and GEMINI.md symlink)"
}

# ------------------------------------------------------------------------------
# Parse CLI Options
# ------------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -g|--global)
            ENABLE_GLOBAL=true
            shift
            ;;
        -p|--project)
            ENABLE_PROJECT=true
            shift
            ;;
        --no-project)
            ENABLE_PROJECT=false
            shift
            ;;
        -b|--both)
            ENABLE_PROJECT=true
            ENABLE_GLOBAL=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo "❌ Unknown option: $1"
            echo "Run '$(basename "$0") --help' for usage."
            exit 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

# If --global is requested and no project directory is supplied, install rule and exit
if [ ${#POSITIONAL_ARGS[@]} -eq 0 ] && [ "$ENABLE_GLOBAL" = true ]; then
    install_global_rule
    echo "✨ Global rule setup complete! Antigravity will now automatically recognize ACDO in any .pipeline/ project."
    exit 0
fi

TARGET_DIR="${POSITIONAL_ARGS[0]:-.}"
PROJECT_NAME="${POSITIONAL_ARGS[1]:-$(basename "$(cd "$TARGET_DIR" 2>/dev/null && pwd || echo "$TARGET_DIR")")}"

# If --global was specified along with a project directory, install global rule first
if [ "$ENABLE_GLOBAL" = true ]; then
    install_global_rule
fi

echo "🚀 Initializing ACDO Pipeline in: $TARGET_DIR (Project: $PROJECT_NAME)"

mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# 1. Ensure Git is initialized with at least one commit (needed for worktrees)
if [ ! -d ".git" ]; then
    echo "📦 Initializing Git repository..."
    git init -b main
fi

# Ensure .worktrees/ is ignored by git
if ! grep -q "^\.worktrees/" .gitignore 2>/dev/null; then
    echo -e "\n# ACDO Autonomous Worktrees\n.worktrees/\n" >> .gitignore
    echo "🛡️ Added .worktrees/ to .gitignore"
fi

# 2. Scaffold .pipeline directory tree
mkdir -p .pipeline/tickets/{inbox,queued,ready,active,validated,archive}
mkdir -p .pipeline/specs
mkdir -p .pipeline/releases
mkdir -p .pipeline/templates

# Embed guidelines and templates directly into the project repository
cp -r "$METHODS_DIR/templates/"* .pipeline/templates/
cp "$METHODS_DIR/GUIDELINES.md" .pipeline/GUIDELINES.md
echo "📦 Embedded .pipeline/GUIDELINES.md and .pipeline/templates/ (100% self-contained)"

# 3. Create default .pipeline/config.json if not present
if [ ! -f ".pipeline/config.json" ]; then
    cat <<EOF > .pipeline/config.json
{
  "project_name": "$PROJECT_NAME",
  "main_branch": "main",
  "test_command": "npm test",
  "lint_command": "npm run lint",
  "default_max_steps": 12,
  "release_milestone": "v0.1.0",
  "auto_release": false
}
EOF
    echo "⚙️ Created .pipeline/config.json"
fi

# 4. Create initial BOARD.md
if [ ! -f ".pipeline/BOARD.md" ]; then
    cat <<EOF > .pipeline/BOARD.md
# 📋 Project Pipeline Board: $PROJECT_NAME
*Last updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")*

## 📥 Inbox (Needs Triage)
- None

## ⏳ Blocked (Queued by Dependencies)
- None

## 🟢 Ready for Development
- None

## ⚡ Active in Flight
- None

## ✅ Validated (Staged for Next Release)
- None

## 📦 Released Archives
- None
EOF
    echo "📋 Created .pipeline/BOARD.md"
fi

# 5. Copy first starter ticket from embedded templates
if [ -z "$(ls -A .pipeline/tickets/inbox/ 2>/dev/null)" ]; then
    cp .pipeline/templates/ticket.md .pipeline/tickets/inbox/FEAT-001-setup.md
    sed -i "s/<project-name>/$PROJECT_NAME/g" .pipeline/tickets/inbox/FEAT-001-setup.md
    sed -i "s/FEAT-000/FEAT-001/g" .pipeline/tickets/inbox/FEAT-001-setup.md
    sed -i "s/<Short descriptive title>/Initial project baseline and core setup/g" .pipeline/tickets/inbox/FEAT-001-setup.md
    echo "🎫 Created starter ticket: .pipeline/tickets/inbox/FEAT-001-setup.md"
fi

# 6. Install Project-level rule if enabled
if [ "$ENABLE_PROJECT" = true ]; then
    install_project_rule
fi

# 7. Git commit initial scaffolding or updates
if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
    echo "📝 Creating initial commit..."
    git add .gitignore .pipeline/
    [ -f "AGENTS.md" ] && git add AGENTS.md GEMINI.md 2>/dev/null || true
    git commit -m "chore: initial project scaffolding with embedded ACDO pipeline"
else
    # Track any newly created files
    git add .gitignore .pipeline/
    [ -f "AGENTS.md" ] && git add AGENTS.md GEMINI.md 2>/dev/null || true
    if ! git diff --cached --quiet; then
        git commit -m "chore: embed ACDO pipeline guidelines, templates, and directives"
        echo "📝 Committed embedded pipeline and directives to Git"
    fi
fi

echo "✨ Project initialized successfully!"
echo "📦 All guidelines, templates, and agent rules are 100% self-contained in this repo."
echo "👉 You can clone this repository to any computer and Antigravity will automatically run ACDO."
echo "👉 Launch execution with: /goal Process the next ticket in .pipeline/tickets/inbox/ for $PROJECT_NAME"
