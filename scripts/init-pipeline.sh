#!/usr/bin/env bash
set -e

# ==============================================================================
# ACDO Pipeline Initializer
# Usage: ./init-pipeline.sh [options] [target-directory] [project-name]
# ==============================================================================

METHODS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GLOBAL_RULES_DIR="${HOME}/.gemini/config/rules"
GLOBAL_RULE_FILE="${GLOBAL_RULES_DIR}/acdo.md"

# Terminal Formatting
if [ -t 1 ]; then
    BOLD="\033[1m"
    DIM="\033[2m"
    RED="\033[31m"
    GREEN="\033[32m"
    YELLOW="\033[33m"
    BLUE="\033[34m"
    CYAN="\033[36m"
    RESET="\033[0m"
else
    BOLD=""
    DIM=""
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    CYAN=""
    RESET=""
fi

# Default State
ENABLE_PROJECT=true
ENABLE_GLOBAL=false
PROJECT_FLAG_SET=false
GLOBAL_FLAG_SET=false
NON_INTERACTIVE=false
POSITIONAL_ARGS=()

MAIN_BRANCH="main"
TEST_COMMAND="npm test"
LINT_COMMAND="npm run lint"
TARGET_TYPE=1 # 1: Existing, 2: New
TARGET_DIR=""
PROJECT_NAME=""
IS_UPDATE=false

show_help() {
    cat <<EOF
ACDO Pipeline Initializer
Usage:
  $(basename "$0") [options] [target-directory] [project-name]

Interactive Mode:
  Run without arguments to start the interactive wizard:
    $(basename "$0")
  The wizard will guide you through:
    1. Scope selection (Project-level, Global rule, or Both)
    2. Project target type (Existing directory vs New directory)
    3. Path & conflict verification (checks existing paths, avoids folder collisions)
    4. Project naming & pipeline commands
    5. Detailed recap of all resources before creation
    6. Confirmation prompt before any file operations

Options:
  -p, --project          Embed GUIDELINES.md, templates/, and AGENTS.md in project root (default: enabled).
  --no-project           Skip embedding guidelines and AGENTS.md in project root.
  -g, --global           Install or update global Antigravity rule in ~/.gemini/config/rules/acdo.md.
  -b, --both             Apply both project-level embedding and global machine rule.
  -y, --yes,
  --non-interactive      Bypass interactive prompts and confirm resource creation automatically.
  -h, --help             Display this help message.

Examples:
  # Interactive wizard (recommended):
  $(basename "$0")

  # Scaffold a project with pre-filled path and name:
  $(basename "$0") /path/to/my-project kan-shooter

  # Scaffold a project and install global machine rule non-interactively:
  $(basename "$0") --both -y /path/to/my-project kan-shooter

  # Install/update global Antigravity rule only:
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
    echo -e "🌐 Installed global Antigravity rule: ${CYAN}$GLOBAL_RULE_FILE${RESET}"
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
    echo -e "📋 Created self-contained agent directives: ${CYAN}AGENTS.md${RESET} (and ${CYAN}GEMINI.md${RESET} symlink)"
}

expand_path() {
    local p="$1"
    if [[ "$p" =~ ^~(/.*)?$ ]]; then
        p="${HOME}${p:1}"
    fi
    realpath -m "$p"
}

prompt_input() {
    local prompt_msg="$1"
    local default_val="$2"
    local result_var="$3"
    local user_val=""

    if [ -n "$default_val" ]; then
        printf "%b? %s %b[%s]%b: %b" "$BOLD" "$prompt_msg" "$CYAN" "$default_val" "$BOLD" "$RESET" >&2
    else
        printf "%b? %s: %b" "$BOLD" "$prompt_msg" "$RESET" >&2
    fi

    if IFS= read -r user_val; then
        if [ -z "$user_val" ]; then
            user_val="$default_val"
        fi
        printf -v "$result_var" "%s" "$user_val"
        return 0
    else
        echo "" >&2
        printf -v "$result_var" "%s" "$default_val"
        return 1
    fi
}

prompt_choice() {
    local prompt_msg="$1"
    local default_choice="$2"
    local result_var="$3"
    local user_val=""
    shift 3
    local options=("$@")

    echo -e "\n${BOLD}${prompt_msg}${RESET}" >&2
    for i in "${!options[@]}"; do
        local idx=$((i + 1))
        if [ "$idx" -eq "$default_choice" ]; then
            echo -e "  ${CYAN}${idx})${RESET} ${options[$i]} ${DIM}(default)${RESET}" >&2
        else
            echo -e "  ${CYAN}${idx})${RESET} ${options[$i]}" >&2
        fi
    done

    while true; do
        printf "%b? Enter choice [1-%d] %b[%s]%b: %b" "$BOLD" "${#options[@]}" "$CYAN" "$default_choice" "$BOLD" "$RESET" >&2
        if IFS= read -r user_val; then
            [ -z "$user_val" ] && user_val="$default_choice"
            if [[ "$user_val" =~ ^[0-9]+$ ]] && [ "$user_val" -ge 1 ] && [ "$user_val" -le "${#options[@]}" ]; then
                printf -v "$result_var" "%s" "$user_val"
                return 0
            fi
            echo -e "${RED}❌ Invalid selection. Please enter a number between 1 and ${#options[@]}.${RESET}" >&2
        else
            echo "" >&2
            printf -v "$result_var" "%s" "$default_choice"
            return 1
        fi
    done
}

prompt_confirm() {
    local prompt_msg="$1"
    local default_yn="${2:-Y}" # Y or N
    local user_val=""
    local hint="[Y/n]"
    [ "$default_yn" = "N" ] && hint="[y/N]"

    printf "%b? %s %b%s%b: %b" "$BOLD" "$prompt_msg" "$CYAN" "$hint" "$BOLD" "$RESET" >&2
    if IFS= read -r user_val; then
        [ -z "$user_val" ] && user_val="$default_yn"
        case "$user_val" in
            [yY]|[yY][eE][sS]) return 0 ;;
            *) return 1 ;;
        esac
    else
        echo "" >&2
        [ "$default_yn" = "Y" ] && return 0 || return 1
    fi
}

display_recap() {
    echo ""
    echo -e "${BOLD}${CYAN}==============================================================================${RESET}"
    echo -e "${BOLD}${CYAN}                     ACDO PIPELINE INITIALIZATION RECAP                       ${RESET}"
    echo -e "${BOLD}${CYAN}==============================================================================${RESET}"

    echo -e "${BOLD}Configuration Summary:${RESET}"
    if [ "$MODE_CHOICE" -eq 2 ]; then
        echo -e "  • ${BOLD}Scope:${RESET}              Global Antigravity Rule only"
        echo -e "  • ${BOLD}Rule Destination:${RESET}   ${CYAN}${GLOBAL_RULE_FILE}${RESET}"
        if [ -f "$GLOBAL_RULE_FILE" ]; then
            echo -e "  • ${BOLD}File Status:${RESET}        ${YELLOW}Existing rule file detected (will update)${RESET}"
        else
            echo -e "  • ${BOLD}File Status:${RESET}        ${GREEN}New file (will create)${RESET}"
        fi
    else
        case "$MODE_CHOICE" in
            1) echo -e "  • ${BOLD}Scope:${RESET}              Project-level Pipeline only" ;;
            3) echo -e "  • ${BOLD}Scope:${RESET}              Both (Project Pipeline + Global Machine Rule)" ;;
        esac
        echo -e "  • ${BOLD}Target Type:${RESET}        $([ "$TARGET_TYPE" -eq 1 ] && echo "Existing directory" || echo "New directory to create")"
        echo -e "  • ${BOLD}Target Directory:${RESET}   ${CYAN}${TARGET_DIR}${RESET}"
        echo -e "  • ${BOLD}Project Name:${RESET}       ${PROJECT_NAME}"
        echo -e "  • ${BOLD}Main Git Branch:${RESET}    ${MAIN_BRANCH}"
        echo -e "  • ${BOLD}Test Command:${RESET}       ${TEST_COMMAND}"
        echo -e "  • ${BOLD}Lint Command:${RESET}       ${LINT_COMMAND}"
        echo -e "  • ${BOLD}Agent Directives:${RESET}   $([ "$ENABLE_PROJECT" = true ] && echo -e "${GREEN}Enabled${RESET} (AGENTS.md & GEMINI.md)" || echo -e "${DIM}Disabled${RESET}")"
        if [ "$ENABLE_GLOBAL" = true ]; then
            echo -e "  • ${BOLD}Global Rule:${RESET}        ${GREEN}Enabled${RESET} (${GLOBAL_RULE_FILE})"
        fi

        echo ""
        echo -e "${BOLD}Git Repository Status:${RESET}"
        if [ -d "$TARGET_DIR/.git" ]; then
            echo -e "  • ${GREEN}Existing Git repository detected.${RESET}"
        else
            echo -e "  • ${YELLOW}No Git repository detected (will initialize 'git init -b ${MAIN_BRANCH}').${RESET}"
        fi

        echo ""
        echo -e "${BOLD}Resources to be created / modified:${RESET}"
        if [ ! -d "$TARGET_DIR" ]; then
            echo -e "  ${GREEN}[+]${RESET} Directory:           ${TARGET_DIR}"
        fi
        echo -e "  ${GREEN}[+]${RESET} Pipeline Dirs:       ${TARGET_DIR}/.pipeline/{tickets/{inbox,queued,ready,active,validated,archive},specs,releases,templates}"
        echo -e "  ${GREEN}[+]${RESET} Templates:           ${TARGET_DIR}/.pipeline/templates/{ticket.md,rfc.md,release.md}"
        echo -e "  ${GREEN}[+]${RESET} Framework Runbook:   ${TARGET_DIR}/.pipeline/GUIDELINES.md"
        if [ -f "$TARGET_DIR/.pipeline/config.json" ]; then
            echo -e "  ${YELLOW}[~]${RESET} Pipeline Config:     ${TARGET_DIR}/.pipeline/config.json ${DIM}(already exists, preserving)${RESET}"
        else
            echo -e "  ${GREEN}[+]${RESET} Pipeline Config:     ${TARGET_DIR}/.pipeline/config.json"
        fi
        if [ -f "$TARGET_DIR/.pipeline/BOARD.md" ]; then
            echo -e "  ${YELLOW}[~]${RESET} Kanban Board:        ${TARGET_DIR}/.pipeline/BOARD.md ${DIM}(already exists, preserving)${RESET}"
        else
            echo -e "  ${GREEN}[+]${RESET} Kanban Board:        ${TARGET_DIR}/.pipeline/BOARD.md"
        fi
        if [ -z "$(ls -A "$TARGET_DIR/.pipeline/tickets/inbox/" 2>/dev/null)" ]; then
            echo -e "  ${GREEN}[+]${RESET} Starter Ticket:      ${TARGET_DIR}/.pipeline/tickets/inbox/FEAT-001-setup.md"
        fi
        if [ "$ENABLE_PROJECT" = true ]; then
            echo -e "  ${GREEN}[+]${RESET} Agent Directives:    ${TARGET_DIR}/AGENTS.md and symlink ${TARGET_DIR}/GEMINI.md"
        fi
        echo -e "  ${GREEN}[+]${RESET} IDE Sandbox Config:  ${TARGET_DIR}/.gemini/settings.json, .agy/settings.json, .agents/settings.json"
        echo -e "  ${GREEN}[+]${RESET} Git Ignore:          ${TARGET_DIR}/.gitignore (.worktrees/ entry)"
        echo -e "  ${GREEN}[+]${RESET} Git Commit:          Scaffolding commit on branch '${MAIN_BRANCH}'"
        if [ "$ENABLE_GLOBAL" = true ]; then
            echo -e "  ${GREEN}[+]${RESET} Global Machine Rule: ${GLOBAL_RULE_FILE}"
        fi
    fi
    echo -e "${BOLD}${CYAN}==============================================================================${RESET}"
    echo ""
}

# ------------------------------------------------------------------------------
# Pre-Flight Checks
# ------------------------------------------------------------------------------
if [ ! -d "$METHODS_DIR/templates" ] || [ ! -f "$METHODS_DIR/GUIDELINES.md" ]; then
    echo -e "${RED}❌ Fatal Error: Source templates or guidelines not found in '${METHODS_DIR}'!${RESET}" >&2
    exit 1
fi

# ------------------------------------------------------------------------------
# Parse CLI Options
# ------------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -g|--global)
            ENABLE_GLOBAL=true
            GLOBAL_FLAG_SET=true
            shift
            ;;
        -p|--project)
            ENABLE_PROJECT=true
            PROJECT_FLAG_SET=true
            shift
            ;;
        --no-project)
            ENABLE_PROJECT=false
            PROJECT_FLAG_SET=true
            shift
            ;;
        -b|--both)
            ENABLE_PROJECT=true
            ENABLE_GLOBAL=true
            PROJECT_FLAG_SET=true
            GLOBAL_FLAG_SET=true
            shift
            ;;
        -y|--yes|--non-interactive)
            NON_INTERACTIVE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo -e "${RED}❌ Unknown option: $1${RESET}" >&2
            echo "Run '$(basename "$0") --help' for usage." >&2
            exit 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

# Banner
if [ "$NON_INTERACTIVE" = false ]; then
    echo -e "${BOLD}${CYAN}==============================================================================${RESET}"
    echo -e "${BOLD}${CYAN}                        ACDO Pipeline Initializer                             ${RESET}"
    echo -e "${BOLD}${CYAN}==============================================================================${RESET}"
fi

# ------------------------------------------------------------------------------
# Step 1: Option Choice (Scope Selection)
# ------------------------------------------------------------------------------
# Determine initial MODE_CHOICE: 1=Project, 2=Global, 3=Both
if [ "$GLOBAL_FLAG_SET" = true ] && [ "$PROJECT_FLAG_SET" = true ]; then
    MODE_CHOICE=3
elif [ "$GLOBAL_FLAG_SET" = true ] && [ ${#POSITIONAL_ARGS[@]} -eq 0 ]; then
    MODE_CHOICE=2
elif [ "$GLOBAL_FLAG_SET" = true ]; then
    MODE_CHOICE=3
elif [ "$PROJECT_FLAG_SET" = true ]; then
    MODE_CHOICE=1
else
    MODE_CHOICE=1
fi

if [ "$NON_INTERACTIVE" = false ]; then
    # Prompt user for mode choice if not explicitly passed as CLI flag
    if [ "$GLOBAL_FLAG_SET" = false ] && [ "$PROJECT_FLAG_SET" = false ]; then
        prompt_choice "Select initialization scope:" 1 MODE_CHOICE \
            "Project-level pipeline only (Scaffold .pipeline, templates, directives)" \
            "Global Antigravity rule only (~/.gemini/config/rules/acdo.md)" \
            "Both (Project-level pipeline + Global machine rule)" || {
            echo -e "${RED}❌ Aborted: input stream closed.${RESET}" >&2
            exit 1
        }
    fi
fi

case "$MODE_CHOICE" in
    1)
        ENABLE_PROJECT=true
        ENABLE_GLOBAL=false
        ;;
    2)
        ENABLE_PROJECT=false
        ENABLE_GLOBAL=true
        ;;
    3)
        ENABLE_PROJECT=true
        ENABLE_GLOBAL=true
        ;;
esac

# If Project mode is enabled, prompt for AGENTS.md / GEMINI.md directive embedding
if [ "$ENABLE_PROJECT" = true ] && [ "$PROJECT_FLAG_SET" = false ] && [ "$NON_INTERACTIVE" = false ]; then
    if prompt_confirm "Embed AGENTS.md & GEMINI.md directives in project root?" "Y"; then
        ENABLE_PROJECT=true
    else
        ENABLE_PROJECT=false
    fi
fi

# ------------------------------------------------------------------------------
# Step 2: Input Parameter Checks & Prompts (Target Directory & Project Name)
# ------------------------------------------------------------------------------
if [ "$MODE_CHOICE" -ne 2 ]; then
    # Determine default project target type (1: Existing, 2: New)
    DEFAULT_TARGET_TYPE=1
    if [ ${#POSITIONAL_ARGS[@]} -gt 0 ]; then
        RESOLVED_CLI_PATH="$(expand_path "${POSITIONAL_ARGS[0]}")"
        if [ ! -e "$RESOLVED_CLI_PATH" ]; then
            DEFAULT_TARGET_TYPE=2
        fi
    fi

    if [ "$NON_INTERACTIVE" = false ]; then
        prompt_choice "Select project target type:" "$DEFAULT_TARGET_TYPE" TARGET_TYPE \
            "Existing project (Target directory must already exist)" \
            "New project (Create a new directory; must not conflict with existing folder)" || {
            echo -e "${RED}❌ Aborted: input stream closed.${RESET}" >&2
            exit 1
        }
    else
        TARGET_TYPE="$DEFAULT_TARGET_TYPE"
    fi

    # Target Directory Validation Loop
    DEFAULT_TARGET="${POSITIONAL_ARGS[0]:-.}"
    while true; do
        if [ "$TARGET_TYPE" -eq 1 ]; then
            # ---------------- Existing Project Mode ----------------
            if [ "$NON_INTERACTIVE" = false ]; then
                prompt_input "Enter path to existing project directory (must exist)" "$DEFAULT_TARGET" INPUT_DIR || {
                    echo -e "${RED}❌ Aborted: input stream closed.${RESET}" >&2
                    exit 1
                }
            else
                INPUT_DIR="$DEFAULT_TARGET"
            fi

            TARGET_DIR="$(expand_path "$INPUT_DIR")"

            # Check: Path must exist
            if [ ! -e "$TARGET_DIR" ]; then
                echo -e "${RED}❌ Error: Path '${TARGET_DIR}' does not exist!${RESET}" >&2
                echo -e "${YELLOW}   When initializing an existing project, the directory must already exist.${RESET}" >&2
                if [ "$NON_INTERACTIVE" = true ]; then exit 1; fi
                DEFAULT_TARGET="$INPUT_DIR"
                continue
            fi

            # Check: Path must be a directory
            if [ ! -d "$TARGET_DIR" ]; then
                echo -e "${RED}❌ Error: Path '${TARGET_DIR}' is a file, not a directory.${RESET}" >&2
                if [ "$NON_INTERACTIVE" = true ]; then exit 1; fi
                DEFAULT_TARGET=""
                continue
            fi

            # Check: Directory must be writable
            if [ ! -w "$TARGET_DIR" ]; then
                echo -e "${RED}❌ Error: Directory '${TARGET_DIR}' is not writable (permission denied).${RESET}" >&2
                if [ "$NON_INTERACTIVE" = true ]; then exit 1; fi
                DEFAULT_TARGET=""
                continue
            fi

            # Check: Conflict check for existing .pipeline/
            if [ -d "$TARGET_DIR/.pipeline" ]; then
                echo -e "${YELLOW}⚠️  Conflict warning: '.pipeline/' already exists in '${TARGET_DIR}'.${RESET}" >&2
                if [ "$NON_INTERACTIVE" = false ]; then
                    if ! prompt_confirm "   Overwrite / update existing pipeline configuration in this folder?" "N"; then
                        echo -e "${BLUE}ℹ️  Please specify another directory.${RESET}" >&2
                        DEFAULT_TARGET=""
                        continue
                    fi
                fi
                IS_UPDATE=true
            else
                IS_UPDATE=false
            fi

            break
        else
            # ---------------- New Project Mode ----------------
            if [ "$NON_INTERACTIVE" = false ]; then
                [ "$DEFAULT_TARGET" = "." ] && DEFAULT_TARGET=""
                prompt_input "Enter new project directory path to create" "$DEFAULT_TARGET" INPUT_DIR || {
                    echo -e "${RED}❌ Aborted: input stream closed.${RESET}" >&2
                    exit 1
                }
            else
                INPUT_DIR="$DEFAULT_TARGET"
            fi

            if [ -z "$INPUT_DIR" ]; then
                echo -e "${RED}❌ Error: New project directory path cannot be empty.${RESET}" >&2
                if [ "$NON_INTERACTIVE" = true ]; then exit 1; fi
                continue
            fi

            TARGET_DIR="$(expand_path "$INPUT_DIR")"

            # Check: Conflict check! Path must NOT already exist
            if [ -e "$TARGET_DIR" ]; then
                echo -e "${RED}❌ Conflict Error: Folder or file '${TARGET_DIR}' already exists!${RESET}" >&2
                echo -e "${YELLOW}   Creation will conflict with the existing folder. For a new project, the folder must not exist.${RESET}" >&2
                echo -e "${YELLOW}   Please choose a new path or select 'Existing project' mode.${RESET}" >&2
                if [ "$NON_INTERACTIVE" = true ]; then exit 1; fi
                DEFAULT_TARGET=""
                continue
            fi

            # Check: Parent directory exists or can be created
            PARENT_DIR="$(dirname "$TARGET_DIR")"
            if [ ! -d "$PARENT_DIR" ]; then
                echo -e "${YELLOW}⚠️  Parent directory '${PARENT_DIR}' does not exist.${RESET}" >&2
                if [ "$NON_INTERACTIVE" = false ]; then
                    if ! prompt_confirm "   Create parent directories recursively?" "Y"; then
                        DEFAULT_TARGET="$INPUT_DIR"
                        continue
                    fi
                fi

                # Check ancestor writability
                ANC="$PARENT_DIR"
                while [ ! -d "$ANC" ] && [ "$ANC" != "/" ] && [ "$ANC" != "." ]; do
                    ANC="$(dirname "$ANC")"
                done
                if [ ! -w "$ANC" ]; then
                    echo -e "${RED}❌ Error: Cannot create directories under '${ANC}' (permission denied).${RESET}" >&2
                    if [ "$NON_INTERACTIVE" = true ]; then exit 1; fi
                    DEFAULT_TARGET=""
                    continue
                fi
            else
                if [ ! -w "$PARENT_DIR" ]; then
                    echo -e "${RED}❌ Error: Parent directory '${PARENT_DIR}' is not writable (permission denied).${RESET}" >&2
                    if [ "$NON_INTERACTIVE" = true ]; then exit 1; fi
                    DEFAULT_TARGET=""
                    continue
                fi
            fi

            IS_UPDATE=false
            break
        fi
    done

    # Project Name Validation Loop
    DEFAULT_PROJECT_NAME="${POSITIONAL_ARGS[1]:-$(basename "$TARGET_DIR")}"
    if [ "$DEFAULT_PROJECT_NAME" = "." ] || [ "$DEFAULT_PROJECT_NAME" = "/" ]; then
        DEFAULT_PROJECT_NAME="$(basename "$(pwd)")"
    fi

    while true; do
        if [ "$NON_INTERACTIVE" = false ]; then
            prompt_input "Enter project name" "$DEFAULT_PROJECT_NAME" PROJECT_NAME || {
                echo -e "${RED}❌ Aborted: input stream closed.${RESET}" >&2
                exit 1
            }
        else
            PROJECT_NAME="$DEFAULT_PROJECT_NAME"
        fi

        if [ -z "$PROJECT_NAME" ]; then
            echo -e "${RED}❌ Error: Project name cannot be empty.${RESET}" >&2
            if [ "$NON_INTERACTIVE" = true ]; then exit 1; fi
            continue
        fi

        if [[ "$PROJECT_NAME" =~ [\"/\\$'\n'] ]]; then
            echo -e "${RED}❌ Error: Project name cannot contain '/', '\\', double quotes, or newlines.${RESET}" >&2
            if [ "$NON_INTERACTIVE" = true ]; then exit 1; fi
            continue
        fi

        break
    done

    # Optional Pipeline Commands Configuration
    if [ "$NON_INTERACTIVE" = false ]; then
        if prompt_confirm "Configure custom test and lint commands?" "N"; then
            prompt_input "Main Git branch" "$MAIN_BRANCH" MAIN_BRANCH || true
            prompt_input "Test command" "$TEST_COMMAND" TEST_COMMAND || true
            prompt_input "Lint command" "$LINT_COMMAND" LINT_COMMAND || true
        fi
    fi
fi

# ------------------------------------------------------------------------------
# Step 3: Display Recap Before Executing Resource Creation
# ------------------------------------------------------------------------------
display_recap

# Step 4: Confirmation Prompt Before Execution
if [ "$NON_INTERACTIVE" = false ]; then
    CONFIRM_MSG="Proceed with resource creation?"
    if [ "$MODE_CHOICE" -eq 2 ]; then
        CONFIRM_MSG="Proceed with installing global rule?"
    fi
    if ! prompt_confirm "$CONFIRM_MSG" "Y"; then
        echo -e "\n${YELLOW}🛑 Operation cancelled by user. No resources were created or modified.${RESET}\n" >&2
        exit 0
    fi
fi

# ------------------------------------------------------------------------------
# Step 5: Resource Creation Execution
# ------------------------------------------------------------------------------
# If global rule was requested, install it
if [ "$ENABLE_GLOBAL" = true ]; then
    install_global_rule
fi

# If global-only mode, exit after rule installation
if [ "$MODE_CHOICE" -eq 2 ]; then
    echo -e "\n✨ ${GREEN}Global rule setup complete!${RESET} Antigravity will now automatically recognize ACDO in any .pipeline/ project."
    exit 0
fi

echo -e "\n🚀 ${BOLD}Initializing ACDO Pipeline in: ${CYAN}$TARGET_DIR${RESET} (Project: ${CYAN}$PROJECT_NAME${RESET})"

mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# 1. Ensure Git is initialized with at least one commit (needed for worktrees)
if [ ! -d ".git" ]; then
    echo "📦 Initializing Git repository..."
    git init -b "$MAIN_BRANCH"
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
  "main_branch": "$MAIN_BRANCH",
  "test_command": "$TEST_COMMAND",
  "lint_command": "$LINT_COMMAND",
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
    sed -i "s|<project-name>|$PROJECT_NAME|g" .pipeline/tickets/inbox/FEAT-001-setup.md
    sed -i "s|FEAT-000|FEAT-001|g" .pipeline/tickets/inbox/FEAT-001-setup.md
    sed -i "s|<Short descriptive title>|Initial project baseline and core setup|g" .pipeline/tickets/inbox/FEAT-001-setup.md
    echo "🎫 Created starter ticket: .pipeline/tickets/inbox/FEAT-001-setup.md"
fi

# 6. Install Project-level rule if enabled
if [ "$ENABLE_PROJECT" = true ]; then
    install_project_rule
fi

# 7. Generate agy settings (sandbox mode with all permissions)
if [ ! -f ".gemini/settings.json" ]; then
    mkdir -p .gemini
    cat << 'EOF' > .gemini/settings.json
{
  "enableTerminalSandbox": true,
  "toolPermission": "proceed-in-sandbox",
  "permissions": {
    "allow": [
      "*",
      "command(*)",
      "write_file(*)",
      "read_file(*)",
      "read_url(*)"
    ],
    "ask": [],
    "deny": []
  }
}
EOF
    mkdir -p .agy
    ln -sf ../.gemini/settings.json .agy/settings.json 2>/dev/null || cp .gemini/settings.json .agy/settings.json
    mkdir -p .agents
    ln -sf ../.gemini/settings.json .agents/settings.json 2>/dev/null || cp .gemini/settings.json .agents/settings.json
    echo "⚙️ Created agy settings (sandbox mode + all permissions)"
fi

# 8. Git commit initial scaffolding or updates
if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
    echo "📝 Creating initial commit..."
    git add .gitignore .pipeline/
    [ -d ".gemini" ] && git add .gemini/ 2>/dev/null || true
    [ -d ".agy" ] && git add .agy/ 2>/dev/null || true
    [ -d ".agents" ] && git add .agents/ 2>/dev/null || true
    [ -f "AGENTS.md" ] && git add AGENTS.md GEMINI.md 2>/dev/null || true
    git commit -m "chore: initial project scaffolding with embedded ACDO pipeline" || true
else
    # Track any newly created files
    git add .gitignore .pipeline/
    [ -d ".gemini" ] && git add .gemini/ 2>/dev/null || true
    [ -d ".agy" ] && git add .agy/ 2>/dev/null || true
    [ -d ".agents" ] && git add .agents/ 2>/dev/null || true
    [ -f "AGENTS.md" ] && git add AGENTS.md GEMINI.md 2>/dev/null || true
    if ! git diff --cached --quiet; then
        git commit -m "chore: embed ACDO pipeline guidelines, templates, and directives" || true
        echo "📝 Committed embedded pipeline and directives to Git"
    fi
fi

echo -e "\n✨ ${GREEN}Project initialized successfully!${RESET}"
echo "📦 All guidelines, templates, and agent rules are 100% self-contained in this repo."
echo "👉 You can clone this repository to any computer and Antigravity will automatically run ACDO."
echo "👉 Launch execution with: /goal Process the next ticket in .pipeline/tickets/inbox/ for $PROJECT_NAME"
