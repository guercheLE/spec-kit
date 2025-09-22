# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/
**Dependencies**: [LIST_DEPENDENT_BRANCHES]
**Parallel Status**: [P] if can run in parallel, Sequential if not
**Allow Task Splitting**: [SPLIT_TASKS] (default: false) - set to true to enable automatic splitting for >12 tasks

## Execution Flow (main)
```
1. Handle branch dependencies and rebasing
   → If dependencies exist: rebase with dependent branches
   → Ensure clean working state before starting
2. Load plan.md from feature directory
   → If not found: ERROR "No implementation plan found"
   → Extract: tech stack, libraries, structure
3. Load optional design documents:
   → data-model.md: Extract entities → model tasks
   → contracts/: Each file → contract test task
   → research.md: Extract decisions → setup tasks
4. Generate tasks by category:
   → Setup: project init, dependencies, linting
   → Tests: contract tests, integration tests
   → Core: models, services, CLI commands
   → Integration: DB, middleware, logging
   → Polish: unit tests, performance, docs
5. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
6. Number tasks sequentially (T001, T002...)
7. Generate dependency graph
8. Create FEATURE_DIR/tasks.md with:
   - Correct feature name (numbered, no prefix) from implementation plan
   - Numbered tasks (T001, T002, etc.)
   - Clear file paths for each task
   - Dependency notes
   - Parallel execution guidance
9. Validate task completeness and logical grouping
10. Check SPLIT_TASKS parameter: 
   → If SPLIT_TASKS=true AND >12 tasks: Apply smart splitting (keeping level 3 sections together)
   → If SPLIT_TASKS=false: Keep all tasks in single file regardless of count
   → If SPLIT_TASKS not specified: Default to false (no splitting)

11. **Final Commit**: After completing the tasks breakdown, commit the changes:
   - CRITICAL: Ensure you're still on feature branch before committing
   - Run `git add .`
   - Run `git commit -m "Complete task breakdown for [feature_name]"` (use numbered feature_name, not branch name)
   - NEVER commit global files on feature branch

12. **Workflow Completion**: 
    - After completing all three phases (specify → plan → tasks), the spec is ready
    - Agent should return to main branch: `git checkout main`
    - Update global files (execution-plan.json, orchestration-plan.md) on main if needed
    - Proceed to next feature only after current spec is complete
```

## Phase 0: Branch Management and Dependencies

### Dependency Rebasing (REQUIRED BEFORE ANY IMPLEMENTATION)
**Only execute if this feature has dependencies on other branches**

- [ ] T000 **Check current branch**: Verify you're on `[###-feature-name]` branch
- [ ] T001 **Rebase with dependencies**: 
  ```bash
  # For each dependent branch (in order):
  git fetch origin
  git rebase origin/[dependent-branch-1]
  git rebase origin/[dependent-branch-2]
  # ... continue for all dependencies
  ```
- [ ] T002 **Resolve conflicts**: If rebasing creates conflicts, resolve them carefully
- [ ] T003 **Verify clean state**: Ensure `git status` shows clean working directory

### Dependency Verification
- [ ] T004 **Verify dependent features**: Check that dependent branches have completed implementation
- [ ] T005 **Test integration points**: Ensure this feature can integrate with dependency features

**⚠️ CRITICAL: Do not proceed to Phase 1 until all dependency rebasing is complete**

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **Dependencies**: [LIST_DEPENDENT_BRANCHES] - branches this feature depends on
- Include exact file paths in descriptions

## Task Size and Splitting Guidelines
**CRITICAL REQUIREMENT**: Each tasks.md file must contain exactly 10-12 tasks, each requiring 2-6 hours of work.
**SPLITTING CONTROL**: Task splitting is DISABLED by default and only occurs when explicitly enabled.

**Task Splitting Parameter**:
- **SPLIT_TASKS**: Boolean parameter (default: false)
- **false**: Keep all tasks in single file regardless of count (default behavior)
- **true**: Enable intelligent splitting when >12 tasks are detected

**Intelligent Splitting Strategy (when SPLIT_TASKS=true)**:
When more than 12 tasks are identified AND splitting is enabled:
- Split along level 3 sections (### headings) to maintain logical grouping
- Keep related tasks together even if it slightly exceeds 12 tasks per file
- Maintain phase dependencies (Setup → Tests → Core → Integration → Polish)
- Use regex pattern `(### |- \[ ] T[0-9][0-9][0-9] )` to identify section boundaries

**When SPLIT_TASKS=true and feature requires more than 12 tasks**:
- Split into multiple task files: `tasks1.md`, `tasks2.md`, `tasks3.md`, etc.
- Each split should be logical (e.g., Core vs Extensions, Frontend vs Backend)
- Maintain dependencies between task files
- First task file should contain foundational work (Setup + Tests + Core basics)
- Subsequent files build upon previous ones (Extensions, Advanced Features, Polish)

**Task Estimation Guidelines**:
- **2 hours**: Simple model creation, basic test writing
- **3-4 hours**: Service implementation, API endpoint with validation
- **5-6 hours**: Complex integration, performance optimization, comprehensive testing

**Smart Splitting Rules (when enabled)**:
- Level 3 sections (###) stay together in same file when possible
- If a section has >12 tasks, split within the section but preserve logical sub-grouping
- Maintain clear dependencies between split files
- Each split file should have a clear theme/focus

**Default Behavior (SPLIT_TASKS=false)**:
- All tasks remain in single tasks.md file
- No automatic splitting regardless of task count
- Simpler workflow for smaller features or when splitting is not desired

## Path Conventions
- **Single project**: `src/`, `tests/` at repository root
- **Web app**: `backend/src/`, `frontend/src/`
- **Mobile**: `api/src/`, `ios/src/` or `android/src/`
- Paths shown below assume single project - adjust based on plan.md structure

## Phase 1: Setup
- [ ] T010 Create project structure per implementation plan
- [ ] T011 Initialize [language] project with [framework] dependencies
- [ ] T012 [P] Configure linting and formatting tools

## Phase 2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE PHASE 3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**
- [ ] T020 [P] Contract test POST /api/users in tests/contract/test_users_post.py
- [ ] T021 [P] Contract test GET /api/users/{id} in tests/contract/test_users_get.py
- [ ] T022 [P] Integration test user registration in tests/integration/test_registration.py
- [ ] T023 [P] Integration test auth flow in tests/integration/test_auth.py

## Phase 3: Core Implementation (ONLY after tests are failing)
- [ ] T030 [P] User model in src/models/user.py
- [ ] T031 [P] UserService CRUD in src/services/user_service.py
- [ ] T032 [P] CLI --create-user in src/cli/user_commands.py
- [ ] T033 POST /api/users endpoint
- [ ] T034 GET /api/users/{id} endpoint
- [ ] T035 Input validation
- [ ] T036 Error handling and logging

## Phase 4: Integration
- [ ] T040 Connect UserService to DB
- [ ] T041 Auth middleware
- [ ] T042 Request/response logging
- [ ] T043 CORS and security headers

## Phase 5: Polish
- [ ] T050 [P] Unit tests for validation in tests/unit/test_validation.py
- [ ] T051 Performance tests (<200ms)
- [ ] T052 [P] Update docs/api.md
- [ ] T053 Remove duplication
- [ ] T054 Run manual-testing.md

## Dependencies Summary
**This feature depends on**: [LIST_DEPENDENT_BRANCHES]
**Dependent features can run in parallel**: [LIST_PARALLEL_FEATURES]

### Branch Merge Order
1. Complete all dependent branches first
2. Rebase this branch with dependencies (Phase 0)
3. Implement this feature (Phases 1-5)
4. Merge this branch to base branch
5. Notify dependent features of completion

## Dependencies
- Branch rebasing (T000-T005) before any implementation
- Tests (T020-T023) before implementation (T030-T036)
- Core implementation (T030-T036) before integration (T040-T043)
- Integration (T040-T043) before polish (T050-T054)

## Parallel Execution Coordination

### Tasks that CAN run in parallel [P]:
- Different files or components
- Independent test files
- Documentation updates
- Linting and formatting

### Tasks that MUST be sequential:
- Same file modifications
- Database migration dependencies
- API endpoint dependencies
- Integration tests that depend on core implementation

## Post-Implementation Checklist
- [ ] All tests passing
- [ ] Code reviewed and approved
- [ ] Documentation updated
- [ ] Branch ready for merge to base branch
- [ ] Dependent features notified of completion

---

**Note**: This tasks file includes enhanced dependency management for the Project Orchestration workflow. Ensure proper rebasing and coordination with dependent features.
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**
- [ ] T004 [P] Contract test POST /api/users in tests/contract/test_users_post.py
- [ ] T005 [P] Contract test GET /api/users/{id} in tests/contract/test_users_get.py
- [ ] T006 [P] Integration test user registration in tests/integration/test_registration.py
- [ ] T007 [P] Integration test auth flow in tests/integration/test_auth.py

## Phase 3.3: Core Implementation (ONLY after tests are failing)
- [ ] T008 [P] User model in src/models/user.py
- [ ] T009 [P] UserService CRUD in src/services/user_service.py
- [ ] T010 [P] CLI --create-user in src/cli/user_commands.py
- [ ] T011 POST /api/users endpoint
- [ ] T012 GET /api/users/{id} endpoint
- [ ] T013 Input validation
- [ ] T014 Error handling and logging

## Phase 3.4: Integration
- [ ] T015 Connect UserService to DB
- [ ] T016 Auth middleware
- [ ] T017 Request/response logging
- [ ] T018 CORS and security headers

## Phase 3.5: Polish
- [ ] T019 [P] Unit tests for validation in tests/unit/test_validation.py
- [ ] T020 Performance tests (<200ms)
- [ ] T021 [P] Update docs/api.md
- [ ] T022 Remove duplication
- [ ] T023 Run manual-testing.md

## Dependencies
- Tests (T004-T007) before implementation (T008-T014)
- T008 blocks T009, T015
- T016 blocks T018
- Implementation before polish (T019-T023)

## Parallel Example
```
# Launch T004-T007 together:
Task: "Contract test POST /api/users in tests/contract/test_users_post.py"
Task: "Contract test GET /api/users/{id} in tests/contract/test_users_get.py"
Task: "Integration test registration in tests/integration/test_registration.py"
Task: "Integration test auth in tests/integration/test_auth.py"
```

## Notes
- [P] tasks = different files, no dependencies
- Verify tests fail before implementing
- Commit after each task
- Avoid: vague tasks, same file conflicts

## Task Generation Rules
*Applied during main() execution*

**Task Count Validation**:
- Count all generated tasks (excluding branch management T000-T005)
- If count > 12: MUST split into multiple task files
- If count < 10: Add more granular tasks or polish tasks
- Target: exactly 10-12 implementation tasks per file

1. **From Contracts**:
   - Each contract file → contract test task [P] (2-3h each)
   - Each endpoint → implementation task (3-5h each)
   
2. **From Data Model**:
   - Each entity → model creation task [P] (2-3h each)
   - Relationships → service layer tasks (4-6h each)
   
3. **From User Stories**:
   - Each story → integration test [P] (3-4h each)
   - Quickstart scenarios → validation tasks (2-3h each)

4. **Ordering**:
   - Setup → Tests → Models → Services → Endpoints → Polish
   - Dependencies block parallel execution

5. **Smart Task Splitting Logic**:
   - Check SPLIT_TASKS parameter value
   - If SPLIT_TASKS=false (default): Keep all tasks in single file
   - If SPLIT_TASKS=true AND total tasks > 12: Split by logical section boundaries (### headings)
   - Common splits: Core/Extensions, Product/Advanced, Frontend/Backend
   - Maintain clear dependencies between task files
   - Keep related tasks within same level 3 section together

## Validation Checklist
*GATE: Checked by main() before returning*

- [ ] **Task count**: 10-12 implementation tasks (excluding T000-T005 branch management)
- [ ] **Split parameter check**: SPLIT_TASKS parameter evaluated (default: false)
- [ ] **If SPLIT_TASKS=true AND >12 tasks**: Split using smart section-aware strategy
- [ ] **If SPLIT_TASKS=false**: Keep all tasks in single file regardless of count
- [ ] **Task estimates**: Each task is 2-6 hours of work
- [ ] All contracts have corresponding tests
- [ ] All entities have model tasks
- [ ] All tests come before implementation
- [ ] Parallel tasks truly independent
- [ ] Each task specifies exact file path
- [ ] No task modifies same file as another [P] task
- [ ] **Split file dependencies**: If splitting enabled and multiple files created, clear dependencies between them
- [ ] **Section integrity**: If splitting enabled, level 3 sections kept together where possible