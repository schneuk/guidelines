---
id: FEAT-000
project: <project-name>
title: <Short descriptive title>
type: feature              # feature | bug | refactor | chore | perf
priority: medium           # critical | high | medium | low
target_version: minor      # patch | minor | major | vX.Y.Z
depends_on: []             # List of prerequisite ticket IDs, e.g. [CORE-001, FEAT-002]
blocks: []                 # List of downstream ticket IDs blocked by this ticket
max_steps: 12              # Hard tool step limit
autonomous: true           # true: auto-merge upon passing tests; false: halt after RFC for review
---

## 1. Objective
<!-- One or two paragraphs describing what needs to be built and why. -->

## 2. Functional Requirements
1. Requirement 1...
2. Requirement 2...

## 3. Technical Constraints & Architecture Notes
- Target files/modules:
- Guidelines to respect: (e.g. Composition API, State Machine, HSL color tokens)

## 4. Acceptance Criteria
- [ ] AC 1: Core functionality implemented.
- [ ] AC 2: Unit / integration tests passing.
- [ ] AC 3: Zero regression in existing test suite.
- [ ] AC 4: Linter and type-checker passing cleanly.
