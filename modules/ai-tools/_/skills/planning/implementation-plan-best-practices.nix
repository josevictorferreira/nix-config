{ ... }:
{
  name = "implementation-plan-best-practices";
  description = "Educational guide on best practices for creating implementation plans that prevent drift. Covers style anchors, task sizing, TDD requirements, affirmative instructions, drift handling, and quality gates. Use when creating or improving implementation plans to ensure they follow proven patterns.";
  license = "MIT";
  prompt = ''
    # Implementation Plan Best Practices

    Proven best practices for creating implementation plans that prevent drift and maintain alignment with project standards.

    ## Core Principle

    > Models optimize locally; enforce global constraints with layered verification (prompt → IDE → commit → CI → runtime).

    ## 1. Style Anchors
    - Always include 2-3 exemplary files as templates in prompts
    - Reference exact paths and line numbers (e.g., `src/auth/login.ts:45-78`)
    - Prefer concrete repository examples with code + tests + README
    - Example: `examples/style-anchor/pkg/greeter/greeter.go` (code), `greeter_test.go` (tests), `README.md` (docs)
    - Place anchors early in task instructions to prevent architectural drift

    **Template:**
    ```
    Style Anchors:
    - src/auth/login.ts:45-78 (authentication pattern with proper error handling)
    - src/auth/login.test.ts:12-34 (test structure for auth flows)
    - src/middleware/validation.ts:15-30 (input validation pattern)
    ```

    ## 2. Task Sizing
    - **Target duration:** 30-150 minutes (0.5-2.5 hours)
    - **File scope:** 1-3 files per task (max 5 with justification)
    - **Splitting strategy:** tests + scaffolding → minimal implementation → refactor & polish
    - Commit after each small task; revert immediately on drift
    - If task <30m, document rationale or split it

    **Examples:**
    - Small: Fix bug in `src/utils/parse.ts` — 30-60 mins
    - Medium: Add API endpoint `src/server/user.ts` with tests — 90-150 mins
    - Large: Migrate auth system — Split into design + 3-5 incremental tasks

    ## 3. Affirmative Instructions
    - State permitted actions explicitly (e.g., `ONLY use: cobra, go-playground/validator, sqlite`)
    - Avoid negative framing ("Don't use X" → "ONLY use: Y, Z")
    - Specify exact file scopes: `Touch ONLY: src/api/handlers/user.ts, user.test.ts`

    ## 4. Tiered Rules
    - **Global:** User prefs (format, language, length)
    - **Project:** Persistent rules in `CLAUDE.md` or `.cursor/rules/` (loaded every session)
    - **Context-aware:** Auto-attached rules per directory or file pattern

    ## 5. TDD as Anchor
    - Require TDD checklist: tests → minimal code → more tests → refactor
    - When tests fail: "Revise implementation to pass this test while keeping all previously passing tests. Do not modify the test. Do not add dependencies."
    - Include explicit validation commands:
    ```bash
    npm test src/auth/login.test.ts
    go test ./pkg/auth -v
    pytest tests/test_auth.py -v
    ```

    ## 6. Prompt Positioning
    - Put critical specs, style anchors, and hard rules at the **beginning**
    - Reiterate them at the **end** of prompts
    - Avoid burying requirements in the middle

    ## 7. Model Strategies
    - **Claude:** Use for surgical, minimal-diff edits; request `research → plan → implement`, `minimal diff, no renames, explain each edit`; use thinking triggers (`think`, `think hard`, `ultrathink`)
    - **GPT:** Use for exploratory/greenfield work and code review; ask for tactical plans and side-effect checks

    ## 8. Self-Consistency & AI-on-AI Review
    - Generate 3+ implementations (higher temperature), then ask model to pick most consistent
    - Use multi-model review (e.g., Claude writes, GPT/Gemini reviews) to catch subtle issues

    ## 9. Drift Handling

    **Stop & revert immediately if:**
    - New dependencies introduced (not in allowed list)
    - Files touched outside specified targets (>3 unexpected files)
    - Linting/type errors cannot be resolved within task scope
    - Tests fail and model proposes changing tests instead of implementation

    **Immediate actions:**
    1. Stop the session
    2. Revert to pre-task state (only if changes produced by agent in this session)
    3. Create incident note in `docs/drift-incidents/` with:
       - What happened
       - Files changed unexpectedly
       - New dependencies proposed
       - Remediation steps

    **Allowed deviations:**
    - Minor formatting (editorconfig)
    - Whitespace-only edits
    - Single-line refactors within scope and type-checked

    **Recording learnings:**
    - Update `.cursor/rules/` or `CLAUDE.md` with new rules after each session
    - Add to style anchors if new pattern discovered

    ## 10. Quality Gates

    **Pre-commit:**
    - `make lint` with zero warnings
    - `make test` with all tests passing
    - `make typecheck` with zero errors

    **CI gates:**
    - Count violations (gofmt, lint, typecheck) and fail if threshold exceeded
    - Run tests with race detection (e.g., `go test -race`)

    **Per-task validation:**
    ```yaml
    validation:
      commands:
        - npm run lint
        - npm test src/[module].test.ts
        - npm run typecheck
      expected_output: "All tests passing, 0 lint errors"
      failure_handling: "STOP and report. Do not continue to next task."
    ```

    ## 11. Layered Verification

    1. **Prompt level:** Explicit constraints, style anchors, task sizing
    2. **IDE level:** Linting, type checking, auto-formatting
    3. **Commit level:** Pre-commit hooks, validation scripts
    4. **CI level:** Quality gates, test suites, coverage thresholds
    5. **Runtime level:** Input validation, proper error handling, monitoring

    ## 12. Key Learnings from Milestone 0
    - **Make templates explicit vs concrete:** Include all schema-required top-level fields to avoid validation failures
    - **Enforce concrete style anchors early:** Include 2-3 concrete anchors (code + tests + README) on every planning task
    - **Mark inferred edits:** Use `assumption: true` with rationale for any inferred additions
    - **Respect task-sizing constraints:** Enforce 30-150m task estimates; split shorter tasks with rationale
    - **Keep validation inline:** Add `validation` summary with `quality_score`, `issues`, and `approval`
    - **Prefer concrete execution snippets:** Add explicit validator commands in `instructions`
    - **Scope implementation rules:** Keep implementation-only pattern checks scoped with `when: implementation_phase`
    - **Use repository examples as anchors:** Small, well-scoped examples are high-leverage anchors

    ## Task Template Example

    ```yaml
    task:
      id: t-auth-001
      name: "Add login endpoint with JWT validation"
      estimate_minutes: 90

      files:
        touch_only: [src/api/handlers/auth.ts, src/api/handlers/auth.test.ts]
        modify_only: [src/api/routes.ts]

      style_anchors:
        - {path: src/api/handlers/user.ts, lines: 45-78, pattern: "Handler with proper error handling"}
        - {path: src/api/handlers/user.test.ts, lines: 12-45, pattern: "Test structure for API handlers"}

      constraints:
        dependencies:
          only_use: [jsonwebtoken, express-validator]
        file_scope:
          max_files: 3
          stop_if_exceeded: true

      instructions: |
        ## CRITICAL CONSTRAINTS
        - ONLY modify files listed above
        - ONLY use dependencies: jsonwebtoken, express-validator
        - MUST pass: npm test, npm run lint

        ## Style Anchors
        See src/api/handlers/user.ts:45-78 for handler pattern
        See src/api/handlers/user.test.ts:12-45 for test structure

        ## TDD Checklist
        - [ ] Write failing test for POST /auth/login
        - [ ] Implement minimal handler to pass
        - [ ] Add tests for edge cases
        - [ ] Refactor for clarity

        ## Drift Policy
        STOP if: files touched >3, new dependencies, tests fail

        ## Validation
        npm test src/api/handlers/auth.test.ts && npm run lint && npm run typecheck

      validation:
        commands: [npm test src/api/handlers/auth.test.ts, npm run lint, npm run typecheck]
        expected_output: "All tests passing, 0 errors"
        failure_handling: "STOP. Revise implementation to pass tests."
    ```

    ## Quick Practical Checklist

    When creating implementation plans:

    1. Create `CLAUDE.md` or `.cursor/rules/` with prompt-level rules
    2. Add 2-3 concrete style anchors to prompts (prefer repository examples)
    3. Rescope tasks to 30m-2.5h and commit per task
    4. Convert negative constraints to affirmative instructions
    5. Enforce linting zero-warnings, pre-commit hooks, and CI gates
    6. Require TDD plans and tests before making changes
    7. Use proper error handling for runtime validation
    8. Include all schema-required fields in generated YAML
    9. Mark inferred additions with `assumption: true` and rationale
    10. Place critical constraints at beginning AND end of prompts

    ## Common Anti-Patterns

    | Anti-Pattern | Problem | Fix |
    |--------------|---------|-----|
    | No style anchors | Model introduces inconsistent patterns | Add 2-3 concrete examples with line numbers |
    | Tasks >2.5 hours | Difficult to review, easy to drift | Split into tests + implementation + refactor |
    | Negative framing | "Don't use X" is harder to follow | "ONLY use: Y, Z" |
    | Buried rules | Model misses important constraints | Put at beginning AND end |
    | No validation commands | Unclear when task is complete | Include explicit lint/test/typecheck commands |
    | Allowing test modification | Tests weakened to pass implementation | "Revise implementation, not tests" |
    | No drift policy | Small drifts compound | Explicit stop criteria and revert process |
    | No commit checkpoints | Large uncommitted changes hard to debug | Commit after each task |

    ## Integration with Other Skills

    These are companion skills from the upstream sherpy pack and may not be installed locally -- treat them as concepts to apply, not skills to invoke:

    - **implementation-planner:** Apply these practices when generating plans
    - **implementation-plan-review:** Validate plans against these practices
    - **business-requirements-interview:** Ensure requirements align with these practices
    - **technical-requirements-interview:** Technical specs should follow these practices

    ## Examples

    See the `references/` directory for:
    - Well-structured task with all best practices applied
    - Before/after examples showing improvements
    - Common mistakes and how to fix them
  '';
  references = {
    "well-structured-task" = ''
      # Example: Well-Structured Task

      This example demonstrates all best practices applied to a single task.

      ## Task Definition

      ```yaml
      task:
        id: t-user-api-002
        name: "Add user profile update endpoint"

        estimate_minutes: 90

        files:
          touch_only:
            - src/api/handlers/profile.ts
            - src/api/handlers/profile.test.ts
          modify_only:
            - src/api/routes.ts
            - src/types/api.ts

        style_anchors:
          - path: src/api/handlers/user.ts
            lines: 23-67
            description: "Handler pattern with validation, error handling, and response formatting"

          - path: src/api/handlers/user.test.ts
            lines: 15-52
            description: "Test structure: describe blocks, beforeEach setup, clear assertions"

          - path: src/middleware/validation.ts
            lines: 8-34
            description: "Input validation middleware pattern with express-validator"

        constraints:
          dependencies:
            only_use:
              - express
              - express-validator
              - zod
            do_not_add: true

          file_scope:
            max_files: 4
            stop_if_exceeded: true

          patterns:
            error_handling: "Use Result<T> pattern from src/types/result.ts"
            validation: "Use express-validator middleware chain"
            response: "Use ApiResponse<T> from src/types/api.ts"

        instructions: |
          ## CRITICAL CONSTRAINTS
          - ONLY modify the 4 files listed above
          - ONLY use dependencies: express, express-validator, zod
          - MUST pass: npm test, npm run lint, npm run typecheck

          ## Style Anchors (FOLLOW THESE PATTERNS)

          ### Handler Pattern
          See `src/api/handlers/user.ts:23-67`
          - Use async/await for all handlers
          - Wrap in try/catch with proper error types
          - Validate input before processing
          - Return ApiResponse<T> format

          ### Test Pattern
          See `src/api/handlers/user.test.ts:15-52`
          - Use describe/it blocks for organization
          - beforeEach for setup
          - Test success case + 2-3 error cases
          - Use supertest for HTTP assertions

          ### Validation Pattern
          See `src/middleware/validation.ts:8-34`
          - Use express-validator chain
          - Custom validators in separate file
          - Return 400 with specific error messages

          ## TDD Checklist
          - [ ] Write failing test for PUT /api/profile
          - [ ] Implement minimal handler to pass
          - [ ] Add tests for:
            - [ ] Invalid email format
            - [ ] Missing required fields
            - [ ] Unauthorized access
          - [ ] Refactor for clarity while keeping tests green

          ## Implementation Steps

          1. **Create test file** (src/api/handlers/profile.test.ts)
             - Write test for successful profile update
             - Test should fail (handler doesn't exist)

          2. **Add type definitions** (src/types/api.ts)
             - Add UpdateProfileRequest interface
             - Add UpdateProfileResponse interface

          3. **Implement handler** (src/api/handlers/profile.ts)
             - Create updateProfile function
             - Add input validation
             - Implement business logic
             - Return proper response format

          4. **Register route** (src/api/routes.ts)
             - Add PUT /api/profile route
             - Apply authentication middleware
             - Apply validation middleware

          5. **Add error case tests**
             - Invalid email format
             - Missing required fields
             - Unauthorized user

          ## Drift Policy

          **STOP IMMEDIATELY if:**
          - You need to touch >4 files
          - You need to add new dependencies
          - Tests fail and you're tempted to modify tests
          - Linting errors cannot be fixed within task scope

          **If drift detected:**
          1. Stop current work
          2. Run `git diff` to review changes
          3. Revert with `git checkout .`
          4. Document in `docs/drift-incidents/YYYY-MM-DD-profile-task.md`

          **Allowed deviations:**
          - Minor formatting (prettier auto-fixes)
          - Adding missing type imports in existing files

          ## Validation Commands

          Run after each step:

          ```bash
          # Type checking
          npm run typecheck

          # Linting (must have 0 errors)
          npm run lint

          # Run specific test file
          npm test src/api/handlers/profile.test.ts

          # Run all tests
          npm test
          ```

          Expected output:
          - 0 TypeScript errors
          - 0 lint errors
          - All tests passing
          - Coverage >80% for new files

          If validation fails:
          - STOP
          - Fix the issue
          - Do not continue to next step

          ## HARD RULES (REITERATED)

          1. **Do NOT modify tests to make them pass**
             - Tests define expected behavior
             - Fix implementation, not tests

          2. **Do NOT add new dependencies**
             - Only use: express, express-validator, zod
             - If you need something else, STOP and ask

          3. **Do NOT exceed file scope**
             - Max 4 files
             - If you need more, STOP and discuss

          4. **Commit after each major step**
             - After tests written
             - After implementation complete
             - After refactoring

          5. **Run validation after every change**
             - Don't accumulate errors
             - Fix issues immediately

        validation:
          commands:
            - npm run typecheck
            - npm run lint
            - npm test src/api/handlers/profile.test.ts
            - npm test
          expected_output: |
            ✖ typecheck: 0 errors
            ✖ lint: 0 errors, 0 warnings
            ✓ profile.test.ts: 5 tests passed
            ✓ all tests: 47 tests passed
          failure_handling: |
            STOP immediately.
            Fix the specific issue.
            Do not proceed to next step.
            If cannot fix within 15 minutes, escalate.
      ```

      ## Why This Task Is Well-Structured

      ### ✅ Style Anchors (3 provided)
      - Concrete file paths with line numbers
      - Clear descriptions of what pattern to follow
      - Covers handler + test + validation patterns

      ### ✅ Task Sizing (90 minutes)
      - Within optimal 30-150 minute range
      - Limited to 4 files
      - Clear deliverable (endpoint with tests)

      ### ✅ TDD Requirements
      - Explicit checklist included
      - Test-first approach enforced
      - "Revise implementation, not tests" clearly stated

      ### ✅ Affirmative Instructions
      - "ONLY use" instead of "don't use"
      - "ONLY modify" with explicit file list
      - Clear dependency boundaries

      ### ✅ Drift Prevention
      - Stop criteria clearly defined
      - Revert instructions included
      - Allowed deviations listed
      - Incident documentation process specified

      ### ✅ Quality Gates
      - Explicit validation commands
      - Expected outputs documented
      - Failure handling defined

      ### ✅ Prompt Positioning
      - Critical constraints at beginning
      - Hard rules reiterated at end
      - Clear structure (Constraints → Anchors → Steps → Validation → Rules)

      ### ✅ Layered Verification
      - Prompt level: Explicit constraints and anchors
      - IDE level: Typecheck and lint commands
      - Commit level: "Commit after each major step"
      - Test level: TDD checklist and test commands

      ## What This Prevents

      By following this structure, you prevent:

      1. **Architectural drift:** Style anchors ensure consistent patterns
      2. **Scope creep:** File limits and task sizing prevent overreach
      3. **Test weakening:** "Don't modify tests" rule enforced
      4. **Dependency bloat:** Explicit "ONLY use" list
      5. **Accumulated errors:** Validation after each step
      6. **Large, unreviewable changes:** 90-minute chunks are easy to review
      7. **Unclear completion criteria:** Expected outputs defined
      8. **Mid-stream fixes:** Drift policy stops problems early
    '';
    "before-after-improvements" = ''
      # Before/After: Improving a Task

      This example shows how to transform a poorly structured task into one that follows best practices.

      ## ❌ BEFORE: Poorly Structured Task

      ```yaml
      task:
        id: t-003
        name: "Add authentication"

        estimate_minutes: 240  # TOO LARGE

        # NO STYLE ANGLES

        files:
          - src/auth/  # TOO VAGUE
          - src/middleware/  # COULD TOUCH MANY FILES
          - tests/  # UNCLEAR SCOPE

        instructions: |
          Add authentication to the application using JWT tokens.

          Don't use any new libraries unless absolutely necessary.
          Make sure it's secure and follows best practices.

          Write tests for everything.

          Don't break existing functionality.

          The user should be able to login and get a token.
          The token should be validated on protected routes.
          Invalid tokens should return 401.

          Make sure to handle all edge cases and errors properly.

          Add proper documentation.
      ```

      ### Problems with This Task

      #### 1. **No Style Anchors** ❌
      - No examples of existing patterns to follow
      - Model will guess at conventions
      - Likely to introduce inconsistent patterns

      #### 2. **Too Large (240 minutes)** ❌
      - Exceeds 150-minute maximum
      - Touches unclear number of files
      - Difficult to review in one go
      - High risk of drift

      #### 3. **Vague File Scope** ❌
      - "src/auth/" could mean many files
      - "tests/" is completely unclear
      - No explicit limits on file count
      - No drift prevention

      #### 4. **Negative Framing** ❌
      - "Don't use new libraries"
      - "Don't break existing functionality"
      - Negative constraints are harder to follow

      #### 5. **No TDD Structure** ❌
      - "Write tests for everything" is vague
      - No test-first instruction
      - No explicit test commands
      - Could write tests after (or never)

      #### 6. **No Validation Commands** ❌
      - Unclear how to verify completion
      - No lint/test/typecheck commands
      - No expected outputs defined

      #### 7. **No Drift Policy** ❌
      - What if 10 files need touching?
      - What if new library is genuinely needed?
      - No stop criteria defined

      #### 8. **Burying Requirements** ❌
      - Critical security requirements mixed with suggestions
      - No clear prioritization
      - Easy to miss important constraints

      #### 9. **No Commit Checkpoints** ❌
      - 4-hour uncommitted work is hard to debug
      - No clear milestones within the task

      ---

      ## ✅ AFTER: Well-Structured Task

      ### Split into 3 Tasks

      #### Task 1: Authentication Types & Interfaces (60 minutes)

      ```yaml
      task:
        id: t-auth-001
        name: "Define authentication types and interfaces"

        estimate_minutes: 60

        files:
          touch_only:
            - src/types/auth.ts
            - src/types/auth.test.ts
          modify_only: []

        style_anchors:
          - path: src/types/user.ts
            lines: 1-45
            description: "Type definition pattern with Zod schemas and tests"

          - path: src/types/api.ts
            lines: 12-34
            description: "Request/Response type pattern with validation"

        constraints:
          dependencies:
            only_use:
              - zod
            do_not_add: true

          file_scope:
            max_files: 2
            stop_if_exceeded: true

        instructions: |
          ## CRITICAL CONSTRAINTS
          - ONLY create the 2 files listed above
          - ONLY use: zod (already installed)
          - MUST pass: npm test, npm run lint, npm run typecheck

          ## Style Anchors
          See src/types/user.ts:1-45 for type + Zod schema pattern
          See src/types/api.ts:12-34 for request/response types

          ## TDD Checklist
          - [ ] Write tests for type validation
          - [ ] Implement Zod schemas
          - [ ] Add type exports
          - [ ] Verify all tests pass

          ## Implementation Steps
          1. Create src/types/auth.ts with:
             - LoginRequest schema + type
             - LoginResponse schema + type
             - AuthToken payload schema + type
             - JWTPayload type

          2. Create src/types/auth.test.ts with:
             - Test valid login request
             - Test invalid email format
             - Test missing fields
             - Test token payload validation

          ## Validation
          ```bash
          npm test src/types/auth.test.ts
          npm run typecheck
          npm run lint
          ```

          Expected: All tests passing, 0 errors

          ## HARD RULES
          - ONLY 2 files
          - Do not add dependencies
          - Tests must validate schemas thoroughly

        validation:
          commands:
            - npm test src/types/auth.test.ts
            - npm run typecheck
            - npm run lint
          expected_output: "All tests passing, 0 errors"
      ```

      #### Task 2: JWT Token Service (90 minutes)

      ```yaml
      task:
        id: t-auth-002
        name: "Implement JWT token generation and validation service"

        estimate_minutes: 90

        files:
          touch_only:
            - src/services/tokenService.ts
            - src/services/tokenService.test.ts
          modify_only: []

        style_anchors:
          - path: src/services/userService.ts
            lines: 15-78
            description: "Service pattern with error handling and dependency injection"

          - path: src/services/userService.test.ts
            lines: 20-67
            description: "Service test pattern with mocking"

          - path: src/types/result.ts
            lines: 1-30
            description: "Result<T> pattern for error handling"

        constraints:
          dependencies:
            only_use:
              - jsonwebtoken
              - zod
            do_not_add: true

          file_scope:
            max_files: 2
            stop_if_exceeded: true

          patterns:
            error_handling: "Use Result<T> from src/types/result.ts"
            testing: "Mock dependencies with jest.mock"

        instructions: |
          ## CRITICAL CONSTRAINTS
          - ONLY create the 2 files listed above
          - ONLY use: jsonwebtoken (already installed), zod
          - MUST pass: npm test, npm run lint, npm run typecheck

          ## Style Anchors
          See src/services/userService.ts:15-78 for service pattern
          See src/services/userService.test.ts:20-67 for test pattern
          See src/types/result.ts:1-30 for Result<T> pattern

          ## TDD Checklist
          - [ ] Write failing tests for token generation
          - [ ] Implement minimal tokenService
          - [ ] Add tests for validation
          - [ ] Add tests for expired tokens
          - [ ] Refactor while keeping tests green

          ## Implementation Steps
          1. Create src/services/tokenService.ts:
             - generateToken(payload: JWTPayload): Result<string>
             - validateToken(token: string): Result<JWTPayload>
             - Use jsonwebtoken library
             - Handle all error cases

          2. Create src/services/tokenService.test.ts:
             - Test successful token generation
             - Test token validation
             - Test expired token rejection
             - Test invalid token rejection
             - Test malformed token rejection

          ## Drift Policy
          STOP if:
          - Need to touch >2 files
          - Need new dependencies
          - Tests fail and tempted to modify tests

          ## Validation
          ```bash
          npm test src/services/tokenService.test.ts
          npm run typecheck
          npm run lint
          ```

          Expected: All tests passing, 0 errors

          ## HARD RULES
          - Do NOT modify tests to pass
          - Do NOT add dependencies
          - Use Result<T> for error handling
          - All error cases must be tested

        validation:
          commands:
            - npm test src/services/tokenService.test.ts
            - npm run typecheck
            - npm run lint
          expected_output: "All tests passing, 0 errors"
      ```

      #### Task 3: Authentication Middleware & Login Endpoint (120 minutes)

      ```yaml
      task:
        id: t-auth-003
        name: "Add authentication middleware and login endpoint"

        estimate_minutes: 120

        files:
          touch_only:
            - src/middleware/authMiddleware.ts
            - src/middleware/authMiddleware.test.ts
            - src/api/handlers/auth.ts
            - src/api/handlers/auth.test.ts
          modify_only:
            - src/api/routes.ts

        style_anchors:
          - path: src/middleware/validation.ts
            lines: 8-45
            description: "Middleware pattern with error handling"

          - path: src/middleware/validation.test.ts
            lines: 12-67
            description: "Middleware test pattern"

          - path: src/api/handlers/user.ts
            lines: 23-78
            description: "Handler pattern with validation and error handling"

          - path: src/api/handlers/user.test.ts
            lines: 15-52
            description: "Handler test pattern with supertest"

        constraints:
          dependencies:
            only_use:
              - express
              - express-validator
              - jsonwebtoken
              - zod
            do_not_add: true

          file_scope:
            max_files: 5
            stop_if_exceeded: true

          patterns:
            middleware: "Follow src/middleware/validation.ts pattern"
            handler: "Follow src/api/handlers/user.ts pattern"
            error_handling: "Use Result<T> pattern"

        instructions: |
          ## CRITICAL CONSTRAINTS
          - ONLY modify the 5 files listed above
          - ONLY use: express, express-validator, jsonwebtoken, zod
          - MUST pass: npm test, npm run lint, npm run typecheck

          ## Style Anchors
          See src/middleware/validation.ts:8-45 for middleware pattern
          See src/api/handlers/user.ts:23-78 for handler pattern
          Use services from t-auth-001 and t-auth-002

          ## TDD Checklist
          - [ ] Write failing test for POST /auth/login
          - [ ] Implement login handler
          - [ ] Write failing test for auth middleware
          - [ ] Implement auth middleware
          - [ ] Add tests for error cases
          - [ ] Refactor while keeping tests green

          ## Implementation Steps
          1. Create src/api/handlers/auth.ts:
             - login handler (POST /auth/login)
             - Validate credentials
             - Generate token using tokenService
             - Return LoginResponse

          2. Create src/api/handlers/auth.test.ts:
             - Test successful login
             - Test invalid credentials
             - Test missing fields
             - Test validation errors

          3. Create src/middleware/authMiddleware.ts:
             - Extract token from Authorization header
             - Validate token using tokenService
             - Attach user to request
             - Return 401 for invalid tokens

          4. Create src/middleware/authMiddleware.test.ts:
             - Test valid token
             - Test missing token
             - Test invalid token
             - Test expired token

          5. Modify src/api/routes.ts:
             - Add POST /auth/login route
             - Apply authMiddleware to protected routes

          ## Drift Policy
          STOP if:
          - Need to touch >5 files
          - Need new dependencies
          - Tests fail and tempted to modify tests

          ## Validation
          ```bash
          npm test src/api/handlers/auth.test.ts
          npm test src/middleware/authMiddleware.test.ts
          npm test
          npm run typecheck
          npm run lint
          ```

          Expected: All tests passing, 0 errors

          ## HARD RULES
          - Do NOT modify tests to pass
          - Do NOT add dependencies
          - Use existing services (types, tokenService)
          - Follow middleware and handler patterns exactly

        validation:
          commands:
            - npm test src/api/handlers/auth.test.ts
            - npm test src/middleware/authMiddleware.test.ts
            - npm test
            - npm run typecheck
            - npm run lint
          expected_output: "All tests passing, 0 errors"
      ```

      ### Improvements Summary

      | Aspect | Before | After |
      |--------|--------|-------|
      | **Task Size** | 240 min (too large) | 60 + 90 + 120 = 270 min (properly split) |
      | **Style Anchors** | 0 | 2-3 per task |
      | **File Scope** | Vague ("src/auth/") | Explicit (2-5 files per task) |
      | **Instructions** | Negative ("Don't use") | Affirmative ("ONLY use") |
      | **TDD** | Vague ("write tests") | Explicit checklist + test commands |
      | **Validation** | None | Explicit commands + expected outputs |
      | **Drift Policy** | None | Clear stop criteria + revert process |
      | **Commit Checkpoints** | None | After each task (3 commits) |

      ### Benefits of the Split

      1. **Easier to Review:** Each task is 60-120 minutes, easy to understand
      2. **Lower Risk:** If task 2 drifts, only 90 minutes of work affected
      3. **Clearer Scope:** Exact files listed, no ambiguity
      4. **Better Quality:** TDD enforced at each step
      5. **Easier Debugging:** Problems caught early in 60-min task, not at end of 240-min task
      6. **Parallelization:** Task 1 can be reviewed while task 2 is being implemented
      7. **Incremental Value:** Types can be used even if implementation isn't complete

      ### Key Takeaway

      **The 240-minute "add authentication" task was a recipe for drift:**
      - No guidance → model guesses patterns
      - Large scope → difficult to review
      - Vague boundaries → easy to exceed file limits
      - No checkpoints → errors compound

      **The split tasks are drift-resistant:**
      - Clear patterns → model follows existing code
      - Small scope → easy to review and revert
      - Explicit boundaries → drift detected immediately
      - Multiple checkpoints → errors caught early
    '';
  };
}
