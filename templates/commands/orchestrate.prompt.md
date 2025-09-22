---
description: Orchestrate complete project development by identifying features, dependencies, and executing full workflow for each specification.
---

# Project Development Orchestrator

Given the project description provided as an argument, orchestrate the complete development workflow from concept to implementation-ready tasks.

## Overview

This command analyzes your project (greenfield vs brownfield), identifies required features, creates dependency graphs, and executes the complete spec-driven workflow for each feature.

**For Brownfield Projects**: Prioritizes constitutional compliance and completing existing work.
**For Greenfield Projects**: Focuses on feature identification and dependency planning.

**Alternative Names**: This command was formerly known as "Product-to-Full" but now supports complete project orchestration beyond just Product scenarios.

---

## Execution Steps

### 1. Initialize Project Planning
- Run `.specify/scripts/bash/orchestrate.sh --json "$ARGUMENTS"` from repo root
- Parse JSON output for ORCHESTRATION_PLAN_FILE, EXECUTION_PLAN, SPECS_DIR, PROJECT_TYPE, PROJECT_STATE, STATUS
- All file paths must be absolute

### 2. Analyze Project State
   - **Greenfield Projects**: No existing src/, tests/, or docs/ folders
     - Proceed with standard project orchestration planning
     - Create new features from scratch
   - **Brownfield Projects**: Existing implementation detected
     - Compare PROJECT_STATE against constitution.md requirements
     - Identify gaps between constitutional principles and current implementation
     - Focus on missing features and constitutional compliance gaps
     - Account for incomplete features (partial task completion)

3. **Constitutional Analysis for Brownfield**:
   - Review PROJECT_STATE.constitutional_gaps for violations
   - Check PROJECT_STATE.incomplete_features for unfinished work
   - Prioritize constitutional compliance issues (e.g., missing tests if Test-First required)
   - Identify implementation gaps vs constitutional requirements

4. **Feature Planning Based on Project Type**:

   **For Greenfield Projects**:
   - Identify Product features (core functionality needed for basic product)
   - Identify Full Product features (enhancements for complete product)
   - Create feature dependency graph (which features depend on others)

   **For Brownfield Projects**:
   - Review existing specs from PROJECT_STATE.existing_specs
   - Complete any incomplete features first (PROJECT_STATE.incomplete_features)
   - Fill constitutional gaps (PROJECT_STATE.constitutional_gaps)
   - Add missing Product features not yet implemented
   - Plan Full Product features on top of existing + Product baseline

5. **Update Product Plan**:
   - Load ORCHESTRATION_PLAN_FILE and replace placeholders with actual analysis
   - **For Greenfield**: Organize new features by priority: Product (P1) → Full Product (P2) → Advanced (P3)
   - **For Brownfield**:
     - Mark existing completed features as [DONE]
     - Mark incomplete features as [IN PROGRESS] with completion status
     - Mark constitutional gaps as [CRITICAL] - highest priority
     - Add new Product features as [TODO]
   - Define clear dependencies between features
   - Mark which features can be developed in parallel [P]

6. **Execute Workflow for Each Feature**:

   **CRITICAL WORKFLOW RULES - MUST BE ENFORCED**:
   - **Branch Management**:
     - Always verify current branch before any file operations
  - Global files (orchestration-plan.md, execution-plan.json, specify-request.md) ONLY on main branch
     - Spec files (spec.md, plan.md, tasks.md) ONLY on feature branches
     - Complete each spec fully (specify → plan → tasks) before moving to next
     - Always return to main branch after completing a spec
   - **Commit Pattern**:
     - Commit after each phase completion: "Complete {phase} for {feature_name}"
     - Use numbered feature_name (e.g., "001-authentication") not branch_name
     - **CRITICAL GIT FIX**: After every commit, run `git status` to refresh Git working directory cache and prevent untracked file bug when switching branches
   - **No Implementation**:
     - Workflow STOPS at tasks generation - implementation NEVER executed
     - Focus on specification, planning, and task breakdown only
   - **Branch Numbering**:
     - Use next_branch_number from project state analysis
     - Format: feature/{number:03d}-{feature-name} (e.g., feature/001-auth-system)
     - Track numbers in execution-plan.json to prevent conflicts

   **STRICT BRANCH WORKFLOW REQUIREMENTS**:
   - Complete each spec fully (specify → plan → tasks) before moving to next
   - **Branch Management**:
  - GLOBAL FILES (execution-plan.json, orchestration-plan.md, specify-request.md):
       * ALWAYS create/update on main branch ONLY
       * Commit on main after ALL specs complete
     - SPEC FILES (spec.md, plan.md, tasks.md):
       * ALWAYS create on feature branch (branch_name with 'feature/' prefix)
       * Commit on feature branch after each phase completion
     - Always verify current branch before file operations using `git branch --show-current`
     - Use `git checkout main` before working with global files
     - Use `git checkout feature/{number}-{name}` before working with spec files
     - **CRITICAL GIT FIX**: After every checkout, run `git status` to refresh Git working directory cache and prevent untracked file bug
   - **Naming Convention**:
     - feature_name: Numbered plain name without prefix (e.g., "001-authentication-system")
     - branch_name: Prefixed with 'feature/' (e.g., "feature/001-authentication-system")
     - Use next_branch_number from analyze-project-state.sh output

   **Priority Order - Breadth-First Level Completion Strategy**:
   **For Brownfield**:
   1. **Phase 0 (CRITICAL)**: Constitutional compliance gaps first
   2. **Phase 1 (Complete)**: Finish incomplete_features
   3. **Level 1 (Foundation)**: Complete ALL Level 1 specs (001-XXX through 00N-XXX) to 100% before ANY Level 2 work
   4. **Level 2 (Secondary)**: Complete ALL Level 2 specs to 100% before ANY Level 3 work
   5. **Level 3 (Advanced)**: Advanced/enhancement features

   **For Greenfield**:
   1. **Level 1 (Foundation)**: Complete ALL Level 1 specs (001-XXX through 00N-XXX) to 100% before ANY Level 2 work
   2. **Level 2 (Secondary)**: Complete ALL Level 2 specs to 100% before ANY Level 3 work
   3. **Level 3 (Advanced)**: Advanced/enhancement features   **CRITICAL LEVEL GATE ENFORCEMENT**:
   - **Level Gates**: System MUST validate 100% completion of current level before allowing next level work
   - **No Level Jumping**: Cannot start any Level 2 spec until ALL Level 1 specs reach tasks completion
   - **Parallel Development**: Multiple specs within SAME level can be worked simultaneously
   - **Completion Verification**: Check all specs in current level have completed spec → plan → tasks phases
   - **Auto-Level Detection**: System analyzes dependencies to assign appropriate level automatically

   **Level Assignment Examples**:
   ```
   Level 1 (Foundation): 001-user-auth, 002-core-api, 003-database-schema
   Level 2 (Secondary): 004-user-profile, 005-payment-system, 006-order-management
   Level 3 (Advanced): 007-analytics, 008-ml-recommendations, 009-admin-dashboard
   ```

   **Breadth-First Strategy Benefits**:
   - **Architectural Stability**: Complete foundation before building complex features
   - **Early Validation**: Test core functionality before investing in advanced features
   - **Risk Reduction**: Stable base reduces technical debt and integration issues
   - **Resource Efficiency**: Parallel development within levels, sequential between levels
   - **Clear Milestones**: Each level completion provides clear product milestone

   **Manual Approach - For each feature in dependency order**:
   - **Specify**: Run `/specify` command with feature description
     - Script automatically resolves branch/folder naming conflicts
     - Phase 1: Resolves branch conflicts before checkout (renames existing branches)
     - Phase 2: Resolves folder conflicts after checkout (merges existing spec folders)
     - Verify on feature branch (branch_name) before file operations
     - Commit spec files before proceeding
   - **Auto-clarify**: Use best judgment to fix clarification items in spec
   - **Plan**: Run `/plan` command to generate implementation plan
     - Verify on feature branch (branch_name) before file operations
     - Commit plan files after completion
   - **Tasks**: Run `/tasks` command to generate task breakdown
     - Verify on feature branch (branch_name) before file operations
     - Commit task files after completion
     - **If tasks >12**: Command will automatically split into tasks1.md, tasks2.md, etc.
     - **Task splitting**: Each file contains 10-12 tasks (2-6h each)
     - **Split dependencies**: tasks1.md must complete before tasks2.md starts
     - **Logical grouping**: Core functionality in tasks1.md, extensions in tasks2.md, etc.
   - **Branch Management**: After completing all three phases for a spec, checkout to main before starting next spec
     - **CRITICAL GIT FIX**: After checkout to main, run `git status` to refresh Git working directory cache and prevent untracked file bug

   **Automated Orchestration (Optional)**:
   For teams preferring automated workflow execution, use the orchestrated feature workflow scripts:
   - **Linux/macOS**: `.specify/scripts/bash/execute-feature-workflow.sh <feature_name> <feature_description> [dependent_branches]`
   - **Windows**: `.specify/scripts/powershell/execute-feature-workflow.ps1 <feature_name> <feature_description> [dependent_branches]`

   These scripts automate the complete workflow: spec creation → auto-clarification → planning → task generation → execution summary.

7. **Generate Execution Summary**:
   - **For Greenfield**: List all created specs with their branch names
   - **For Brownfield**:
     - Show constitutional gaps addressed
     - List completed vs new specs
     - Highlight incomplete features that were finished
   - Show dependency graph and execution order
   - Identify which tasks can run in parallel
   - Provide next steps for implementation

**Important Notes**:
- **NO IMPLEMENTATION**: This workflow stops at tasks generation - implementation should NEVER be executed
- **Brownfield Priority**: Constitutional compliance gaps are CRITICAL and must be addressed first
- **State Awareness**: Always account for existing implementation when planning new features
- **Incremental Progress**: Build on existing work rather than replacing it
- **Level-Based Progression**: Follow breadth-first completion - see `specs-numbering-dependencies.md` for detailed level assignment rules
- **Branch Workflow**:
  - Always verify branch before file operations
  - Complete each spec fully before moving to next
  - Commit pattern: git add . then git commit after each spec completion
  - Global files only committed on main branch after ALL specs complete
  - Use numbered feature_name vs branch_name (feature/ prefixed) consistently
- Always create branches from develop/main/master (not from feature branches)
- Include rebasing steps in tasks.md for features with dependencies
- Mark parallel-executable tasks with [P] in the task descriptions
- Use best judgment to resolve any clarification items in specs
- Ensure each spec is complete before moving to the next

**Brownfield Specific Notes**:
- Respect existing architecture and patterns
- Ensure new features integrate well with existing codebase
- Prioritize constitutional compliance over new feature development
- Complete incomplete work before starting new features

Report completion with:
- Project type (greenfield/brownfield)
- Constitutional gaps identified and addressed (for brownfield)
- Total features identified (existing + new)
- Execution order with dependencies
- Branch names (feature/ prefixed) for all created specs (e.g., "feature/001-auth", "feature/002-api")
- Feature names (numbered, no prefix) for reference (e.g., "001-auth", "002-api")
- Summary of parallel vs sequential tasks
