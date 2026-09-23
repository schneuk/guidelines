# Autonomous Execution Directives

## 1. Zero-Interruption Autonomy
- Do not stop to ask for user permission or confirmation for standard development operations:
  - Reading, creating, editing, and deleting files within the project pipeline and git worktrees.
  - Executing terminal commands for building, linting, testing, formatting, or inspecting git state.
  - Creating, merging, and cleaning up ephemeral git branches and worktrees.
- Never ask conversational check-ins such as "Would you like me to proceed?" or "Should I write tests now?". Automatically advance to the next stage in the pipeline.

## 2. Working Tree Isolation
- Never run background code generation or experimental fixes directly on the user's active checkout.
- Always use `git worktree add -b feat/<ID> ../.worktrees/<ID>` to ensure complete working tree isolation.
- Remove the worktree immediately after a clean merge.

## 3. Strict Quality Verification
- Never merge a feature branch or mark a ticket as `validated` unless:
  1. All existing test suites pass.
  2. New tests covering the ticket acceptance criteria are written and passing.
  3. Linter and type checker return clean exit code 0.
- Execute up to 3 self-healing attempts if tests fail. If tests still fail after 3 attempts, mark the ticket as blocked in `BOARD.md` and document the failure log without touching the main branch.

## 4. Token & Step Discipline
- Honor the `max_steps` parameter defined in the active ticket.
- Avoid open-ended exploration; stay focused strictly on the ticket acceptance criteria.

## 5. Subagent Delegation & Isolation
- Delegate exploratory codebase searches and interface inspection in Stage 2 to a read-only `research` subagent to protect the parent context window from bloat.
- Any subagent performing code modifications must operate strictly inside the isolated `.worktrees/<ID>` directory.
- Subagents must return structured, distilled summaries (status, touched files, test outcomes) back to the orchestrator rather than raw logs.
- Never exceed a subagent hierarchy depth of 1 (no recursive subagent spawning without explicit user direction).
