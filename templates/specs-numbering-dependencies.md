# Specs Numbering and Hierarchical Dependencies

This document details how specifications are numbered, organized, and how their hierarchical dependency structure works in the orchestration system.

## Numbering System

### Basic Numbering Pattern
Specifications follow a consistent numbering pattern with level-aware assignment:
```
XXX-feature-name
```
Where:
- `XXX` = 3-digit zero-padded sequential number (001, 002, 003, etc.)
- `feature-name` = hyphenated, lowercase feature identifier
- Numbers are assigned sequentially regardless of level for simplicity

### Level-Based Organization Examples
```
LEVEL 1 (Foundation):
001-user-authentication
002-product-catalog  
003-core-api-framework

LEVEL 2 (Secondary):
004-shopping-cart
005-payment-processing
006-user-profile
007-order-management

LEVEL 3 (Advanced):
008-advanced-search
009-recommendation-engine
010-admin-dashboard
011-analytics-system
```

### Level Assignment Strategy

#### Automatic Level Detection
```bash
/specification-creation "User authentication system"
# Analysis: Core functionality, no dependencies
# → Assigned: Level 1 (Foundation)
# → Number: 001 (first available)

/specification-creation "Shopping cart functionality"  
# Analysis: Requires user auth + product catalog
# → Assigned: Level 2 (Secondary)
# → Number: 004 (first available after Level 1 complete)

/specification-creation "ML recommendation engine"
# Analysis: Requires user data + product data + purchase history
# → Assigned: Level 3 (Advanced)  
# → Number: 008 (first available after Level 2 complete)
```

#### Manual Level Assignment
```bash
/specification-creation --level=2 "Advanced user profiles"
# Explicitly assigns to Level 2
# Validates that Level 1 is complete before allowing
# Assigns next available number in sequence
```

### Automatic Number Assignment

#### For Greenfield Projects
```bash
# First feature always gets 001
/orchestrator "Build user authentication system"
# Creates: specs/001-user-authentication/

# Second feature gets 002  
/specification-creation "Product catalog with search"
# Creates: specs/002-product-catalog/
```

#### For Brownfield Projects
The system scans existing specs directory and assigns the next available number:

```bash
# If specs/001-user-auth and specs/003-cart exist
# Next feature automatically gets 004 (skips gaps)
/specification-creation "Payment processing"
# Creates: specs/004-payment-processing/
```

#### Number Calculation Logic
```bash
# From analyze-project-state.sh
HIGHEST_NUMBER=0
for spec_dir in "$SPECS_DIR"/*; do
    BRANCH_NUMBER=$(echo "$SPEC_NAME" | grep -o '^[0-9]+' || echo "0")
    BRANCH_NUMBER=$((10#$BRANCH_NUMBER))  # Force decimal interpretation
    if [ "$BRANCH_NUMBER" -gt "$HIGHEST_NUMBER" ]; then
        HIGHEST_NUMBER=$BRANCH_NUMBER
    fi
done
NEXT_BRANCH_NUMBER=$((HIGHEST_NUMBER + 1))
```

## Directory Structure

### Spec Directory Layout
```
specs/
├── 001-user-authentication/
│   ├── spec.md                    # Feature specification
│   ├── feature-planning.md        # Implementation planning
│   ├── task-breakdown.md          # Detailed tasks
│   ├── contracts/                 # API contracts (optional)
│   ├── research.md               # Research notes (optional)
│   ├── data-model.md            # Data modeling (optional)
│   └── quickstart.md            # Quick implementation guide (optional)
├── 002-product-catalog/
│   ├── spec.md
│   ├── feature-planning.md  
│   ├── task-breakdown.md
│   └── ...
└── 003-shopping-cart/
    ├── spec.md
    ├── feature-planning.md
    ├── task-breakdown.md
    └── ...
```

### Branch Naming Convention
```
feature/XXX-feature-name
```

Examples:
```
feature/001-user-authentication
feature/002-product-catalog  
feature/003-shopping-cart
```

## Hierarchical Dependencies

### Dependency Declaration

#### In Orchestration Plan
```markdown
## Product Features (Priority 1)
- [ ] **User Authentication**: Basic registration, login, logout
  - Dependencies: None
  - Parallel: No (foundation)
  - Status: [TODO]

- [ ] **Product Catalog**: Basic product listing and details
  - Dependencies: User Authentication
  - Parallel: No  
  - Status: [TODO]

- [ ] **Shopping Cart**: Add/remove products, view cart
  - Dependencies: User Authentication, Product Catalog
  - Parallel: No
  - Status: [TODO]
```

#### In Feature Planning
```markdown
# Feature Planning: Shopping Cart

## Dependencies
### Required Features
- **001-user-authentication**: User session management for cart persistence
- **002-product-catalog**: Product data for cart items

### Integration Points
- User Authentication: Cart tied to user sessions
- Product Catalog: Cart items reference product IDs
```

#### In Task Breakdown
```markdown
# Tasks: Shopping Cart

## Prerequisites Verification
- [ ] P001: Verify User Authentication APIs are available
- [ ] P002: Verify Product Catalog database schema exists
- [ ] P003: Test product retrieval endpoints

## Phase 1: Foundation (Dependencies: User Auth)
- [ ] T001: Design cart database schema with user_id foreign key
- [ ] T002: Create cart model with user relationship
```

### Dependency Types

#### 1. Level-Based Dependencies (Breadth-First Enforcement)
**Core Principle**: All specs at a given level must be completed before any spec at the next level can begin.

**Level 1 (Foundation/Core)**: Essential features that everything else builds upon
```markdown
- [ ] **001-user-authentication**: User registration, login, sessions
  - Level: 1 (Foundation)
  - Dependencies: None
  - Parallel: Within Level 1 only
  
- [ ] **002-product-catalog**: Basic product listing and management
  - Level: 1 (Foundation)  
  - Dependencies: None
  - Parallel: With other Level 1 features only
```

**Level 2 (Secondary/Business Logic)**: Features that extend core functionality
```markdown
- [ ] **003-shopping-cart**: Add/remove products, cart management
  - Level: 2 (Secondary)
  - Dependencies: ALL Level 1 specs must be COMPLETED
  - Parallel: With other Level 2 features only
  - Blocked until: 001-user-authentication AND 002-product-catalog = COMPLETE

- [ ] **004-payment-processing**: Secure checkout with payment gateways  
  - Level: 2 (Secondary)
  - Dependencies: ALL Level 1 specs must be COMPLETED
  - Parallel: With other Level 2 features only
  - Blocked until: 001-user-authentication AND 002-product-catalog = COMPLETE
```

**Level 3 (Advanced/Enhancement)**: Polish and competitive advantage features
```markdown
- [ ] **005-advanced-search**: Search filters, faceted search, sorting
  - Level: 3 (Advanced)
  - Dependencies: ALL Level 1 AND Level 2 specs must be COMPLETED  
  - Parallel: With other Level 3 features only
  - Blocked until: ALL specs 001-004 = COMPLETE

- [ ] **006-recommendation-engine**: ML-based product recommendations
  - Level: 3 (Advanced)
  - Dependencies: ALL Level 1 AND Level 2 specs must be COMPLETED
  - Parallel: With other Level 3 features only  
  - Blocked until: ALL specs 001-004 = COMPLETE
```

#### 2. Intra-Level Dependencies (Within Same Level)
Features at the same level can have dependencies on each other:

```markdown
- [ ] **007-order-management**: Order history, status tracking
  - Level: 2 (Secondary)
  - Dependencies: 004-payment-processing (same level)
  - Global Dependencies: ALL Level 1 complete
  - Execution: After payment processing within Level 2
```

#### 3. Legacy/Soft Dependencies (Compatibility Only)
For backward compatibility, but overridden by level-based enforcement:

```markdown
- [ ] **Advanced Search**: Search filters, sorting
  - Level: 3 (Advanced)
  - Legacy Dependencies: Product Catalog (now superseded by level-based)
  - Actual Dependencies: ALL Level 1 AND Level 2 complete
  - Note: Level-based dependencies always take precedence
```

### Dependency Resolution

#### Breadth-First Enforcement
Before starting any spec, the system verifies level completion:

```bash
/specification-creation "Advanced search functionality"

# System automatically checks level requirements:
# 
# TARGET: 005-advanced-search (Level 3)
# 
# LEVEL 1 VERIFICATION:
# ✅ 001-user-authentication: COMPLETED (12/12 tasks)
# ✅ 002-product-catalog: COMPLETED (15/15 tasks)
# 
# LEVEL 2 VERIFICATION:  
# ✅ 003-shopping-cart: COMPLETED (10/10 tasks)
# ❌ 004-payment-processing: INCOMPLETE (8/12 tasks)
# 
# ERROR: Level 2 not complete - cannot proceed to Level 3
# Required: Complete ALL Level 2 specs before starting Level 3
# Blocking spec: 004-payment-processing (4 tasks remaining)
```

#### Level-Based Automatic Assignment
```bash
/specification-creation "User profile management"

# System determines level based on dependencies:
# 
# ANALYSIS: User profile management
# - Requires: User authentication (Level 1)
# - Provides: Enhanced user features
# - Classification: Secondary functionality
# 
# ASSIGNED: Level 2 (Secondary)
# NUMBER: Next available in Level 2 range
# 
# VERIFICATION:
# ✅ Level 1 complete: All foundation specs finished
# ✅ Can proceed with Level 2 development
# 
# Creating: specs/004-user-profile/ (Level 2)
```

#### Manual Override (Emergency Only)
```bash
/specification-creation --override-level "Critical bug fix requiring Level 3 feature"
# ⚠️  WARNING: Overriding breadth-first enforcement
# ⚠️  This may create technical debt and integration issues
# ⚠️  Use only for critical production fixes
# 
# Proceeding with Level 3 feature despite incomplete Level 2...
```

## Dependency Graphs

### Breadth-First Level Structure

#### Level-Based Execution Model
```
LEVEL 1 (Foundation) - ALL must complete first
├── 001-user-authentication
├── 002-product-catalog  
├── 003-core-api-framework
└── [ALL Level 1 complete] ✅

LEVEL 2 (Secondary) - Start only after Level 1 complete
├── 004-shopping-cart (depends: 001, 002)
├── 005-payment-processing (depends: 001, 003)
├── 006-user-profile (depends: 001)
└── [ALL Level 2 complete] ✅

LEVEL 3 (Advanced) - Start only after Level 2 complete  
├── 007-advanced-search (depends: ALL previous)
├── 008-recommendation-engine (depends: ALL previous)
├── 009-admin-dashboard (depends: ALL previous)
└── [Project complete] 🎯
```

#### Parallel Opportunities Within Levels
```
LEVEL 1 (Can develop in parallel):
├── 001-user-authentication [P]
├── 002-product-catalog [P]  
└── 003-core-api-framework [P]

LEVEL 2 (Parallel within level, after Level 1):
├── 004-shopping-cart [P] 
├── 005-payment-processing [P]
└── 006-user-profile [P]

LEVEL 3 (Parallel within level, after Level 2):  
├── 007-advanced-search [P]
├── 008-recommendation-engine [P]
└── 009-admin-dashboard [P]
```

#### Level Completion Gates
```
🚪 GATE 1: Foundation Complete
├── Verification: ALL Level 1 specs = 100% complete
├── Quality Gate: All Level 1 tests passing
├── Integration: Core APIs functional
└── ✅ UNLOCK: Level 2 development

🚪 GATE 2: Business Logic Complete  
├── Verification: ALL Level 2 specs = 100% complete
├── Quality Gate: All integration tests passing
├── Product Gate: Product features ready for production
└── ✅ UNLOCK: Level 3 development

🚪 GATE 3: Advanced Features Complete
├── Verification: ALL Level 3 specs = 100% complete  
├── Quality Gate: Full system tests passing
├── Business Gate: Complete product ready
└── 🎯 PROJECT COMPLETE
```

### Dependency Enforcement

#### Branch Strategy
```bash
# Each feature gets its own branch
git checkout main
git checkout -b feature/001-user-authentication

# Complete feature 001
git checkout main  
git merge feature/001-user-authentication

# Start feature 002 (depends on 001)
git checkout main  # Always branch from main to get completed dependencies
git checkout -b feature/002-product-catalog
```

#### Incremental Integration
```bash
# For features with soft dependencies, integration branches:
git checkout feature/002-product-catalog
git checkout -b feature/003-shopping-cart-integration
# Develop cart with real product catalog integration
```

## State Tracking

### Completion Status

#### In Orchestration Plan
```markdown
## Execution Status (Auto-updated)
- [x] **User Authentication**: ✅ COMPLETED (12/12 tasks)
- [ ] **Product Catalog**: 🔄 IN PROGRESS (8/12 tasks)  
- [ ] **Shopping Cart**: ⏳ BLOCKED (waiting for Product Catalog)
- [ ] **Payment Processing**: ⏳ PENDING
```

#### In Project State Analysis
```json
{
  "existing_specs": [
    "001-user-authentication",
    "002-product-catalog", 
    "003-shopping-cart"
  ],
  "completed_features": [
    "001-user-authentication"
  ],
  "incomplete_features": [
    "002-product-catalog:8/12",
    "003-shopping-cart:0/15"
  ],
  "next_branch_number": 4
}
```

### Resumption Logic

#### Level-Aware Resume Point Detection
```bash
/orchestrator --resume "Continue e-commerce development"

# System analyzes by level:
# 
# LEVEL 1 STATUS:
# ✅ 001-user-authentication: COMPLETE 
# ✅ 002-product-catalog: COMPLETE
# ✅ 003-core-api: COMPLETE
# ✅ Level 1 Gate: PASSED
# 
# LEVEL 2 STATUS:
# ✅ 004-shopping-cart: COMPLETE
# 🔄 005-payment-processing: INCOMPLETE (8/12 tasks)
# ⏳ 006-user-profile: NOT STARTED (blocked by Level 2 gate)
# ❌ Level 2 Gate: BLOCKED
# 
# LEVEL 3 STATUS:
# ⏳ ALL Level 3 specs: BLOCKED (Level 2 incomplete)
# 
# RESUME POINT: 005-payment-processing, task T009
# STRATEGY: Complete Level 2 before proceeding to Level 3
```

#### Smart Level Progression
```bash
# User tries to start Level 3 with incomplete Level 2:
/specification-creation "Advanced recommendation engine"

# System response:
# 🚫 LEVEL PROGRESSION BLOCKED
# 
# Target: Level 3 feature (Advanced)
# Current Status: Level 2 incomplete
# 
# LEVEL 2 COMPLETION REQUIRED:
# ✅ 004-shopping-cart: COMPLETE
# ❌ 005-payment-processing: 8/12 tasks (4 remaining)
# ❌ 006-user-profile: 0/10 tasks (not started)
# 
# RECOMMENDED ACTION:
# 1. Complete 005-payment-processing (estimated: 1 day)
# 2. Complete 006-user-profile (estimated: 2 days)  
# 3. Pass Level 2 gate (integration testing)
# 4. Then proceed with Level 3 features
# 
# OPTIONS:
# - Continue Level 2: /task-implementation --resume
# - Override (not recommended): --override-level
```

## Advanced Dependency Patterns

### Level-Based Conditional Dependencies
```markdown
## Level 2 Features (After Level 1 complete)
- [ ] **Email Notifications**: Order confirmations, status updates
  - Level: 2 (Secondary)
  - Dependencies: ALL Level 1 complete (mandatory)
  - Conditional Integration: 
    - IF 004-payment-processing exists: Payment confirmation emails
    - IF 006-user-profile exists: Preference-based notifications
  - Parallel: [P] within Level 2

## Level 3 Features (After Level 2 complete)  
- [ ] **Advanced Analytics**: Usage patterns, conversion tracking
  - Level: 3 (Advanced)
  - Dependencies: ALL Level 1 AND Level 2 complete (mandatory)
  - Conditional Enhancement:
    - Uses ALL available Level 2 data sources
    - Adapts analytics based on implemented features
  - Parallel: [P] within Level 3
```

### Level Gate Prevention of Circular Dependencies
```markdown
# IMPOSSIBLE with level-based system - circular dependencies prevented

# Level 1: Foundation (no dependencies)
- [ ] **User Authentication**: Basic user management
  - Level: 1 (Foundation)
  - Dependencies: None

# Level 2: Business Logic (depends on Level 1)
- [ ] **User Profile**: Extended user features  
  - Level: 2 (Secondary)
  - Dependencies: ALL Level 1 complete
  
- [ ] **Order Management**: Order processing
  - Level: 2 (Secondary)  
  - Dependencies: ALL Level 1 complete
  - Intra-Level: Can reference User Profile via well-defined APIs

# RESULT: No circular dependencies possible across levels
# RESULT: Intra-level dependencies managed through interfaces
```

### Cross-Level Integration Patterns
```markdown
# Level-based integration with clear boundaries

## Level 1 → Level 2 Integration
- Level 1 provides: Stable APIs, core data models, authentication
- Level 2 consumes: Well-defined Level 1 interfaces only
- Rule: Level 2 cannot modify Level 1 core functionality

## Level 2 → Level 3 Integration  
- Level 2 provides: Business logic APIs, enhanced data models
- Level 3 consumes: Level 1 + Level 2 interfaces
- Rule: Level 3 cannot modify Level 1 or Level 2 core functionality

## Integration Testing Strategy
- Level 1 Gate: Unit tests + Level 1 integration tests
- Level 2 Gate: Level 1-2 integration tests + Level 2 business logic tests  
- Level 3 Gate: Full system integration tests + Level 3 feature tests
```

## Best Practices

### 1. **Breadth-First Progression**
- Complete ALL Level 1 specs before starting any Level 2 spec
- Complete ALL Level 2 specs before starting any Level 3 spec
- Never skip levels or create cross-level dependencies
- Use level gates to validate completion before progression

### 2. **Level Design Principles**
- **Level 1**: Core functionality that everything depends on
- **Level 2**: Business logic that extends Level 1 capabilities  
- **Level 3**: Advanced features that enhance the complete system
- Keep levels balanced in scope and complexity

### 3. **Parallel Development Within Levels**
- Features within the same level can develop in parallel
- Use well-defined interfaces for intra-level communication
- Coordinate integration points early in level development
- Maintain clear API contracts between parallel features

### 4. **Level Gate Quality Assurance**
- Level 1 Gate: Core functionality tests + API stability
- Level 2 Gate: Business logic tests + Level 1-2 integration
- Level 3 Gate: Complete system tests + user acceptance tests
- Never compromise gate requirements for speed

### 5. **Clear Level Assignment**
- Assign specs to levels based on dependency analysis
- Document level rationale in spec planning
- Avoid level creep (features growing beyond their assigned level)
- Review level assignments during orchestration planning

### 6. **Level-Aware Tooling**
- Use level-checking in all workflow commands
- Provide clear error messages for level violations
- Support level-based progress reporting
- Enable level-based resumption and planning