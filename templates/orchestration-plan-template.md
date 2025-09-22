# Project Orchestration Plan

**Project**: [PROJECT_NAME]
**Description**: $ARGUMENTS
**Project## Enhanced Product Features (Priority 2)
*Important features for complete product experience*

- [ ] **[FEATURE_4]**: [Brief description]
  - Dependencies: PRODUCT_FEATURE_1, PRODUCT_FEATURE_2
  - Parallel: No
  - Status: [TODO]

- [ ] **[FEATURE_5]**: [Brief description]
  - Dependencies: PRODUCT_FEATURE_3
  - Parallel: [P] (can run with FEATURE_4)
  - Status: [TODO]

## Enhanced Product Features (Priority 3)  
*Advanced features for competitive advantage*CT_TYPE] (greenfield/brownfield)
**Created**: [DATE]
**Status**: Planning

## Execution Flow (main)
```
1. Parse project description and analyze current state
   → For greenfield: Extract core functionality, target users, business goals
   → For brownfield: Compare constitution.md against src/, tests/, docs/ folders
2. Identify current state (for brownfield only)
   → Existing features: [LIST_FROM_PROJECT_STATE]
   → Constitutional gaps: [LIST_FROM_ANALYSIS]
   → Incomplete features: [LIST_WITH_COMPLETION_STATUS]
3. Identify Product features
   → For greenfield: Focus on core value proposition, basic user flow
   → For brownfield: Focus on constitutional compliance + missing Product features
4. Identify Enhanced Product features  
   → Group by priority: P2 (important), P3 (nice-to-have)
   → Build on existing baseline (for brownfield)
5. Create dependency graph
   → Map which features depend on others
   → Account for existing implementations
   → Identify parallel opportunities [P]
6. Generate execution order
   → Constitutional compliance first (brownfield)
   → Complete incomplete features (brownfield)  
   → Dependencies first, then dependents
   → Group parallel features
7. Validate feature completeness
   → Each feature must be spec-able
   → Check for missing dependencies
   → Ensure constitutional compliance
8. Return: SUCCESS (ready for orchestrated execution)
```

---

## Current State Analysis (Brownfield Only)
*Skip this section for greenfield projects*

### Existing Implementation
- **Source files**: [SRC_FILE_COUNT]
- **Test files**: [TEST_FILE_COUNT] 
- **Documentation files**: [DOC_FILE_COUNT]

### Constitutional Compliance Status
**Constitution Principles**: [LIST_CONSTITUTION_PRINCIPLES]

**Compliance Gaps** (CRITICAL - Address First):
- [ ] **[CONSTITUTIONAL_GAP_1]**: [Description and impact]
- [ ] **[CONSTITUTIONAL_GAP_2]**: [Description and impact]

### Existing Features Status
**Completed Features**: [LIST_COMPLETED_FEATURES]
**Incomplete Features** (Complete Before New Work):
- [ ] **[INCOMPLETE_FEATURE_1]**: [Completion status - e.g., 5/10 tasks done]
- [ ] **[INCOMPLETE_FEATURE_2]**: [Completion status]

---

## Product Features (Priority 1)
*Core functionality needed for basic product launch*

### Constitutional Compliance (Brownfield - CRITICAL)
- [ ] **[CONST_FIX_1]**: [Fix constitutional gap]
  - Dependencies: None
  - Parallel: No (affects architecture)
  - Status: [CRITICAL]

### Complete Existing Work (Brownfield)
- [ ] **[INCOMPLETE_1]**: [Complete existing incomplete feature]
  - Dependencies: [CONST_FIX_1]
  - Parallel: No 
  - Status: [IN PROGRESS]

### Core Product Features
- [ ] **[PRODUCT_FEATURE_1]**: [Brief description]
  - Dependencies: [Constitutional fixes, incomplete work]
  - Parallel: [P] (if applicable)
  - Status: [TODO]
  
- [ ] **[PRODUCT_FEATURE_2]**: [Brief description]  
  - Dependencies: PRODUCT_FEATURE_1
  - Parallel: No (depends on PRODUCT_FEATURE_1)
  - Status: [TODO]

- [ ] **[PRODUCT_FEATURE_3]**: [Brief description]
  - Dependencies: None
  - Parallel: [P] (can run with PRODUCT_FEATURE_1)
  - Status: [TODO]

## Full Product Features (Priority 2)
*Important enhancements for complete product*

- [ ] **[FEATURE_4]**: [Brief description]
  - Dependencies: PRODUCT_FEATURE_1, PRODUCT_FEATURE_2
  - Parallel: No
  - Status: [TODO]

- [ ] **[FEATURE_5]**: [Brief description]
  - Dependencies: PRODUCT_FEATURE_3
  - Parallel: [P] (can run with FEATURE_4)
  - Status: [TODO]

## Enhanced Product Features (Priority 3)  
*Advanced features for competitive advantage*

- [ ] **[FEATURE_6]**: [Brief description]
  - Dependencies: All Product + P2 features
  - Parallel: No
  - Status: [TODO]

## Dependencies Graph

### Brownfield Execution Order
```
CRITICAL (Constitutional Compliance):
├── CONST_FIX_1 (must be first)

IN PROGRESS (Complete Existing):
├── INCOMPLETE_1 (depends on CONST_FIX_1)

Product (P1):
├── PRODUCT_FEATURE_1 [P]
├── PRODUCT_FEATURE_3 [P] (parallel with PRODUCT_FEATURE_1)
└── PRODUCT_FEATURE_2 (depends on PRODUCT_FEATURE_1)

Enhanced Product (P2):
├── FEATURE_4 (depends on PRODUCT_FEATURE_1, PRODUCT_FEATURE_2)
└── FEATURE_5 [P] (depends on PRODUCT_FEATURE_3, parallel with FEATURE_4)

Enhanced Product (P3):
└── FEATURE_6 (depends on all previous)
```

### Greenfield Execution Order
```
Product (P1):
├── PRODUCT_FEATURE_1 [P]
├── PRODUCT_FEATURE_3 [P] (parallel with PRODUCT_FEATURE_1)
└── PRODUCT_FEATURE_2 (depends on PRODUCT_FEATURE_1)

Enhanced Product (P2):
├── FEATURE_4 (depends on PRODUCT_FEATURE_1, PRODUCT_FEATURE_2)
└── FEATURE_5 [P] (depends on PRODUCT_FEATURE_3, parallel with FEATURE_4)

Enhanced Product (P3):
└── FEATURE_6 (depends on all previous)
```

## Execution Order (Breadth-First Maturity Levels)
### Brownfield Priority Order:
1. **Phase 0 (CRITICAL)**: Constitutional compliance fixes
2. **Phase 1 (Complete)**: Finish incomplete features

**Level 1 (Foundation)** - Complete ALL before advancing:
3. **Product Foundation**: PRODUCT_FEATURE_1, PRODUCT_FEATURE_3 [P]
4. **Product Core**: PRODUCT_FEATURE_2 (after foundation complete)

**Level 2 (Core Features)** - Complete ALL before advancing:
5. **Core Features**: FEATURE_4, FEATURE_5 [P] (after Product complete)

**Level 3 (Advanced Features)** - Final enhancement layer:
6. **Advanced**: FEATURE_6 (after core features complete)

### Greenfield Priority Order:
**Level 1 (Foundation)** - Complete ALL before advancing:
1. **Product Foundation**: PRODUCT_FEATURE_1, PRODUCT_FEATURE_3 [P]
2. **Product Core**: PRODUCT_FEATURE_2 (after foundation complete)

**Level 2 (Core Features)** - Complete ALL before advancing:
3. **Core Features**: FEATURE_4, FEATURE_5 [P] (after Product complete)

**Level 3 (Advanced Features)** - Final enhancement layer:
4. **Advanced**: FEATURE_6 (after core features complete)

**Execution Strategy**: Use breadth-first approach to ensure complete maturity at each level before advancing. This provides better product validation, risk distribution, and allows for early user feedback at each maturity milestone.

## Branch Strategy
- **Base branch**: develop (or main/master if develop doesn't exist)
- **Feature branches**: Created from base branch, not from other features
- **Rebasing**: Each tasks.md includes rebasing steps for dependent features
- **Brownfield**: Respect existing branch patterns and merge strategies

## Constitutional Requirements Integration
**For Brownfield Projects**: Each feature must ensure compliance with:
[LIST_CONSTITUTION_REQUIREMENTS]

## Notes for AI Orchestration
- **Brownfield Priority**: Constitutional compliance is NON-NEGOTIABLE and comes first
- **State Awareness**: Always account for existing PROJECT_STATE when planning
- **Incremental Development**: Build on existing work, don't replace unnecessarily
- Use best judgment to resolve [NEEDS CLARIFICATION] items in specs
- Each feature gets its own branch following `###-feature-name` pattern
- Tasks marked [P] can run in parallel (different files/components)
- Sequential tasks require proper branch rebasing before implementation
- All clarifications should be resolved automatically during orchestration

## Brownfield Integration Guidelines
- Analyze existing code patterns and follow them
- Ensure new features integrate seamlessly with existing architecture
- Prioritize fixing constitutional violations over adding new features
- Complete any incomplete work before starting new development
- Maintain backward compatibility where possible

---

*This plan will be executed automatically by the Project Orchestrator with full project state awareness*