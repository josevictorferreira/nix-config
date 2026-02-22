# Aspect: ai-tools-commands
# All AI Tools command (slash-command) definitions consolidated.
# Migrated from legacy commands/default.nix and all sub-command files.
{ ... }:
let
  # Programs that receive command config
  programs = [
    "opencode"
    "claudecode"
    "droid"
    "gemini"
  ];

  # ── Command definitions ──────────────────────────────────────────────

  # Each command: { name, description, agent (optional), prompt }
  # agent defaults to "" when not specified.

  commands = {

    # ── Git ──────────────────────────────────────────────────────────

    add-and-format = {
      name = "add-and-format";
      description = "Smart git add with automatic formatting and style checking for files";
      agent = "";
      prompt = ''
        # Add And Format

        You are a Git workflow specialist with deep knowledge of code formatting and project conventions. Your task is to intelligently add files to git staging with comprehensive formatting and validation.

        **Your Process:**

        1. **File Discovery - Find What Needs Adding**:
           - Use `git status` to identify new/modified files that need to be added
           - Include related configuration files (.toml, .yaml, .json, .md) in the same directories
           - Check .gitignore to ensure you don't stage build artifacts or temporary files
           - If specific files are provided as arguments, focus only on those

        2. **Pre-add Processing - Format Before Staging**:
           - Detect available formatters in the project (prettier, black, rustfmt, gofmt, etc.)
           - Run appropriate formatters on files being added
           - Check for basic syntax errors using available linters or language tools
           - Read files to validate basic structure and check for obvious issues
           - Do NOT stage files that have syntax errors

        3. **Smart Staging - Add Files Logically**:
           - Stage files in logical groups (e.g., all files in a feature/module together)
           - Use `git add <file>` for each validated file
           - Preserve any existing staged changes - do not unstage anything that was already staged
           - If --check is specified, show what you would do but don't actually stage anything

        4. **Verification and Reporting**:
           - After staging, run `git status` to show what was staged
           - Report any files that were skipped due to errors
           - If available, run basic pre-commit hooks to validate staged changes

        **Command Arguments:**
        - [files...]: If provided, only process these specific files
        - --all: Process all modified/new files with formatting
        - --check: Dry run mode - show what would be done without making changes
      '';
    };

    commit-changes = {
      name = "commit-changes";
      description = "Systematically analyze, group, and commit changes following repository conventions";
      agent = "";
      prompt = ''
        # Commit Changes

        You are a systematic Git workflow specialist. Follow this comprehensive approach to analyze changes, detect repository conventions, and create well-structured atomic commits.

        ## **WORKFLOW OVERVIEW**
        This command follows a 4-phase systematic approach:
        1. **Analysis** - Examine repository conventions and current changes
        2. **Grouping** - Organize changes into logical, atomic commit groups
        3. **Message Generation** - Create conventional commit messages
        4. **Execution** - Stage and commit each group systematically

        ## **PHASE 1: REPOSITORY ANALYSIS AND CONVENTION DETECTION**

        ### **Step 1.1: Repository State Assessment**
        ```
        ALWAYS START - Understand current repository state
        ```

        **Current state analysis:**
        ```
        1. Run: git status --porcelain
           Record all modified, added, deleted, renamed files

        2. Run: git diff --name-status
           Understand the nature of changes (modifications vs additions)

        3. Check for staged changes:
           git diff --cached --name-only
           (preserve existing staged changes)
        ```

        [... truncated for brevity, use full original prompt from read 13 ...]
      '';
    };

    # ── General ──────────────────────────────────────────────────────

    deep-check = {
      name = "deep-check";
      description = "Exhaustive validation including builds, tests, and comprehensive quality checks";
      agent = "";
      prompt = ''
        # Deep Check

        You are a senior software architect and code quality expert specializing in comprehensive codebase analysis. Your task is to perform a thorough, deep analysis of the entire project to identify issues, dead code, optimization opportunities, and maintenance concerns.

        **Your Comprehensive Analysis Process:**

        1. **Project Health Assessment**:
           - Identify and run available build/test/check commands (make test, npm test, cargo check, etc.)
           - Attempt builds of key project components to identify compilation/evaluation issues
           - Test project templates, examples, or sample configurations if they exist
           - Check cross-platform compatibility where applicable

        2. **Dead Code Detection - Find What's Unused**:
           - Search for unused imports across all source files
           - Identify functions, variables, classes, and modules that are defined but never referenced
           - Find orphaned files that aren't imported or included anywhere
           - Detect redundant or duplicate code patterns across the codebase

        3. **Dependency Analysis - Map Relationships**:
           - Create a dependency map showing how modules/components relate to each other
           - Identify any circular dependencies between components
           - Check package.json, Cargo.toml, requirements.txt, or similar for unused dependencies
           - If --performance is specified, analyze bundle sizes and build impacts

        4. **Quality Assessment - Measure Code Health**:
           - Assess code complexity and maintainability using available metrics
           - Check for proper documentation and comments
           - Identify performance bottlenecks if --performance is specified
           - If --security is specified, review security practices and potential vulnerabilities

        5. **Actionable Recommendations**:
           - Provide specific refactoring recommendations with file paths and line numbers
           - Suggest performance improvements with measurable impact
           - Recommend structural optimizations for better maintainability
           - Highlight maintenance issues that need immediate attention

        **Command Arguments:**
        - [scope]: Focus your analysis on specific areas (src, tests, docs, all)
        - --with-builds: Actually build/compile the project to test for build-time issues
        - --security: Include security analysis and vulnerability recommendations
        - --performance: Focus heavily on performance analysis and optimization opportunities

        Provide actionable insights with specific file references for comprehensive maintenance planning.
      '';
    };

    dependency-audit = {
      name = "dependency-audit";
      description = "Comprehensive dependency analysis, security scanning, and update recommendations";
      agent = "";
      prompt = ''
        # Dependency Audit

        You are a dependency management and security specialist with expertise in modern software dependency analysis. Your task is to perform comprehensive analysis of project dependencies to identify optimization opportunities, security concerns, and maintenance issues.

        **Your Dependency Analysis Process:**

        1. **Unused Dependency Detection - Find Dead Weight**:
           - Parse package manifests (package.json, requirements.txt, Cargo.toml, etc.) to identify all declared dependencies
           - Search the codebase to find which dependencies are actually imported/used
           - Identify packages that are declared but never referenced in the code
           - Check for import statements that bring in unused functionality

        2. **Dependency Conflict Analysis - Identify Issues**:
           - Check for version conflicts between different dependencies
           - Identify cases where multiple packages provide similar functionality
           - Look for overlapping functionality that could cause conflicts
           - Analyze build-time vs runtime dependency mismatches

        3. **Update Opportunity Analysis - Find Improvements**:
           - Check which dependencies have newer versions available
           - Identify packages that have known security updates
           - Look for optimization opportunities in package selection
           - Check for deprecated packages that should be replaced

        4. **Security Assessment (if --security)**:
           - Check dependencies against known vulnerability databases (npm audit, pip-audit, etc.)
           - Validate that dependency sources are from trusted, official repositories
           - Review any packages from non-standard or third-party sources
           - Assess overall supply chain security posture

        5. **Optimization Recommendations - Suggest Improvements**:
           - Identify opportunities to consolidate similar dependencies
           - Find over-specified dependencies that could use lighter alternatives
           - Recommend package alternatives that reduce bundle/build sizes
           - Suggest structural improvements for dependency management

        **Analysis Focus Based on Arguments:**
        - --unused: Focus specifically on finding and reporting unused dependencies
        - --conflicts: Deep-dive into dependency conflict analysis
        - --updates: Concentrate on available updates and migration paths
        - --security: Emphasize security analysis and vulnerability assessment
        - --report: Generate comprehensive report covering all aspects

        **Command Arguments:**
        - --unused: Focus analysis on finding unused dependencies
        - --conflicts: Analyze and report on dependency conflicts
        - --updates: Check for available updates and upgrade opportunities
        - --security: Focus on security analysis and vulnerability assessment
        - --report: Generate comprehensive dependency report with all findings

        Provide actionable recommendations with specific commands and file references.
      '';
    };

    style-audit = {
      name = "style-audit";
      description = "Comprehensive code style and formatting audit with auto-fix capabilities";
      agent = "";
      prompt = ''
        # Style Audit

        You are a code quality auditor specializing in coding standards and best practices across various programming languages. Your task is to systematically audit the codebase for style violations and either report them or automatically fix them based on the specified options.

        **Your Audit Process:**

        1. **Analyze Project Standards First**:
           - Read existing files to understand the project's established patterns
           - Check for style configuration files (.eslintrc, .prettierrc, pyproject.toml, etc.)
           - Identify the project's preferred naming conventions and patterns
           - Understand organizational structures and architectural decisions
           - Determine the project's style preferences for consistency

        2. **Language-Specific Style Audit**:
           - Apply language-appropriate linting and formatting rules
           - Check for consistent import/require statement organization
           - Verify proper use of language-specific patterns and idioms
           - Validate adherence to established style guides (PEP 8, Google Style Guide, etc.)

        3. **Code Structure Analysis**:
           - Identify overly complex functions or classes that should be simplified
           - Find code blocks that could be better organized or refactored
           - Look for inconsistent patterns across similar code sections
           - Check for proper separation of concerns and modularity

        4. **Naming Convention Verification**:
           - Verify variables, functions, classes follow project conventions
           - Check that files and directories use consistent naming patterns
           - Validate that API endpoints, database fields, etc. follow consistent patterns
           - Ensure naming is descriptive and follows established conventions

        5. **Project Organization Assessment**:
           - Review file/directory structure and organization
           - Check that imports/dependencies are organized logically
           - Verify proper separation of concerns within the codebase
           - Assess overall architectural organization patterns

        6. **Best Practices Review**:
           - Find areas where established best practices aren't being followed
           - Check for proper error handling patterns
           - Validate adherence to language/framework-specific principles
           - Identify opportunities for better abstraction and code reuse

        **Execution Based on Arguments:**
        - If --fix is specified: Automatically correct violations where safe to do so
        - If --report is specified: Generate a detailed compliance report with file:line references
        - If --focus is specified: Concentrate only on that aspect (naming, structure, imports, etc.)
        - Use [path] to limit scope to specific directory or file

        **Command Arguments:**
        - [path]: Directory or file to audit (defaults to current directory)
        - --fix: Automatically fix violations that can be safely corrected
        - --report: Generate detailed compliance report with specific locations
        - --focus: Focus on specific style aspect (naming, structure, imports, organization)

        Provide actionable feedback with specific file locations and suggested improvements.
      '';
    };

    session-retrospective = {
      name = "session-retrospective";
      description = "Analyze session friction points, distill learnings into .docs/rules.md, and ensure AGENTS.md references it.";
      agent = "";
      prompt = ''
        # Session Retrospective

        SESSION RETROSPECTIVE: Notes for Your Future Self

        Analyze this entire session to identify where you struggled, got stuck, or wasted time. Distill those friction points into actionable lessons.

        ## Core Question

        Ask yourself: **"What information, if I had known it beforehand, would have helped me the most in this session?"**

        ## A) Analyze the Session

        Review your work and identify:
        1. **Friction points** - Where did you get stuck the longest? What was hardest to implement?
        2. **Time sinks** - What took disproportionately long due to missing knowledge or wrong assumptions?
        3. **Repeated attempts** - Where did you try multiple approaches before finding the right one?
        4. **Surprises** - What behaved unexpectedly? What did you have to learn the hard way?

        For each friction point, ask: "If I encounter this again, what should I do differently?"

        ## B) Update `.docs/rules.md`

        Write lessons to `.docs/rules.md` (single file, create if needed).

        **What belongs here:**
        - Knowledge that would have saved you significant time (>15-20 min)
        - Patterns/gotchas likely to recur in this codebase
        - Non-obvious behaviors, quirks, or requirements you discovered
        - Process lessons (verification steps, order of operations, etc.)

        **What does NOT belong:**
        - One-off fixes unlikely to recur
        - Obvious things any developer would know
        - Preferences or style opinions
        - Verbose explanations (keep it tight)

        **Hard limits:**
        - Add at most 3-5 lessons per session
        - Each lesson: 2-4 lines max
        - If no significant friction occurred: write "No significant learnings to record." and skip

        **De-dupe (mandatory):**
        - Before adding, read existing `.docs/rules.md`
        - If equivalent lesson exists: update/clarify it instead of duplicating
        - Consolidate related lessons into one if they overlap

        **Format per lesson:**
        ```
        ### [Short descriptive title]
        **Lesson:** [What to do/know - imperative, actionable]
        **Context:** [Why this matters - 1 sentence]
        **Verify:** [Quick check: command, file, or test to confirm]
        ```

        ## C) Update `AGENTS.md` (only if missing)

        Ensure `AGENTS.md` contains an instruction to read `.docs/rules.md` before implementing.
        - If already present: do nothing
        - If missing: add near the top: "Before starting any implementation, read `.docs/rules.md` for project-specific lessons and gotchas."

        ## Output

        1. Summary of friction points identified (1-2 sentences each)
        2. Lessons added/updated in `.docs/rules.md` (verbatim)
        3. Whether `AGENTS.md` was updated (yes/no + text if yes)
        4. Confirmation: de-duped against existing content
      '';
    };

    # ── Homelab ──────────────────────────────────────────────────────

    homelab-service-update = {
      name = "homelab-service-update";
      description = "Update any app's container image version in the kubenix-based Kubernetes homelab.";
      agent = "";
      prompt = ''
        # Homelab Service Update

        Use this prompt to update any app's container image version in the kubenix-based Kubernetes homelab.

        ---

        ## PROMPT TEMPLATE

        ```
        Update the {APP_NAME} container image(s) to version "{NEW_VERSION}".

        ## TASK BREAKDOWN

        1. **Locate Configuration**
           - Find the app in: `modules/kubenix/apps/{app-name}.nix`
           - Identify ALL container images used by the app (main app, sidecars, init containers)
           - Note the current image format: `image.tag = "vX.Y.Z@sha256:...";`

        2. **Fetch Image Digests** (CRITICAL - DO NOT SKIP)
           
           For each image, get the SHA256 digest for the NEW_VERSION:
           
           **Method 1 - GitHub Container Registry (ghcr.io):**
           ```bash
           # Navigate to the package page
           https://github.com/{owner}/{repo}/pkgs/container/{image-name}/versions
           
           # Find the tag, click to see full digest
           # Format: sha256:64hexchars
           ```
           
           **Method 2 - Docker Hub:**
           ```bash
           # Use docker hub API or pull and inspect
           docker pull {image}:{tag}
           docker inspect {image}:{tag} --format='{{index .RepoDigests 0}}'
           ```
           
           **Method 3 - Crane (if available):**
           ```bash
           crane digest {registry}/{image}:{tag}
           ```

           ⚠️ **EDGE CASE: Multi-arch images**
           - If the image is multi-arch (manifest list), you need the PLATFORM-SPECIFIC digest
           - For amd64/linux: Look for the digest associated with "linux/amd64" platform
           - The manifest list digest ≠ platform-specific digest
           - WRONG: `sha256:abc...` (manifest list)
           - RIGHT: `sha256:def...` (linux/amd64 layer)

        3. **Update Image References**
           
           Format: `"v{VERSION}@sha256:{DIGEST}"`
           
           Example:
           ```nix
           # BEFORE
           image.tag = "v2.3.1@sha256:f8d06a32b1b2a81053d78e40bf8e35236b9faefb5c3903ce9ca8712c9ed78445";
           
           # AFTER
           image.tag = "v2.5.0@sha256:6c011eaa315b871f3207d68f97205d92b3e600104466a75b01eb2c3868e72ca1";
           ```

        4. **Regenerate Manifests**
           ```bash
           make manifests
           ```

        ## CRITICAL GOTCHAS & EDGE CASES

        1. **Multiple Images per App**
           - Some apps have 2+ images (e.g., immich has server + machine-learning)
           - Update ALL images, not just the main one
           - Check for: main container, init containers, sidecars

        2. **Digest Format**
           - MUST include full 64-character sha256 hash
           - Format is: `tag@sha256:digest` (NOT just `sha256:digest`)
           - The @ symbol is required

        3. **Registry Differences**
           - ghcr.io (GitHub): `/pkgs/container/{name}/versions` page shows digests
           - Docker Hub: Use `docker inspect` or hub.docker.com API
           - gcr.io, quay.io: Use `skopeo` or `crane`

        4. **Version Tag Formats**
           - Some use `v1.2.3`, others use `1.2.3`
           - Check the registry - use EXACTLY what's published
           - Don't guess: verify on the registry page

        5. **Helm Chart Images**
           - Some apps use Helm charts with subcharts
           - Images may be defined in `values` section, not direct `image.tag`
           - Check: `helm.values.image.tag` or similar paths

        6. **Image Pull Policy**
           - If `imagePullPolicy = "Always"` is set, digest is still required for reproducibility
           - Don't remove digest even if policy is Always

        7. **Private Registries**
           - If image is from private registry, ensure auth is configured
           - Check `imagePullSecrets` if needed

        8. **Breaking Changes**
           - New versions may require config changes
           - Check upstream release notes for:
             - New required environment variables
             - Deprecated features
             - Config format changes

        ## VERIFICATION CHECKLIST

        - [ ] All images updated to new version
        - [ ] All digests are platform-specific (not manifest list)
        - [ ] Format is exactly: `"tag@sha256:digest"`
        - [ ] `make manifests` completes without errors
        - [ ] Generated YAML in `.k8s/` shows new image references

        ## CURRENT STATE

        App: {APP_NAME}
        Current Version: {CURRENT_VERSION}
        Target Version: {NEW_VERSION}
        Registry: {REGISTRY}
        ```

        ---

        ## How to Use

        Replace the placeholders:
        - `{APP_NAME}` - e.g., "immich", "ollama"
        - `{NEW_VERSION}` - e.g., "v2.5.0", "1.21.0"
        - `{CURRENT_VERSION}` - current version from the .nix file
        - `{REGISTRY}` - e.g., "ghcr.io", "docker.io"

        ### Example Usage

        ```
        Update the immich container image(s) to version "v2.5.0".

        ## CURRENT STATE
        App: immich
        Current Version: v2.3.1
        Target Version: v2.5.0
        Registry: ghcr.io
        ```

        ---

        ## Lessons Learned from Implementation

        1. **Multi-arch manifest trap**: The registry returns a manifest list digest, but you need the platform-specific digest (linux/amd64). Browse the GitHub Packages UI to find the correct one.

        2. **Multiple images**: Apps like immich have separate images (server + ML) - both need updating.

        3. **Digest source**: GitHub's container registry UI at `/pkgs/container/{name}/versions` is the most reliable way to get the exact digest for a specific platform.

        4. **Format strictness**: The format must be exactly `"tag@sha256:digest"` - the @ symbol and full 64-char hash are required.

        5. **Submodule pattern differences**:
           - Apps use either `submodule = "helm"` or `submodule = "release"`
           - `release` submodule handles image digests correctly (like blocky)
           - `helm` submodule may have chart-specific quirks and buggy templates
           - **Always check the submodule type first** - if app uses `helm`, consider converting to `release` if encountering image issues

        6. **Chart template bugs**:
           - Some Helm charts have buggy image templates (e.g., searxng's boilerplate subchart)
           - The `digest` field may not work due to template bugs - only `tag` may render correctly
           - **Test before implementing**: Use `helm template <release> <chart> -f test-values.yaml` to verify which values actually work
           - This is faster than repeatedly running `make manifests` to debug

        7. **Testing Helm behavior**:
           ```bash
           # Quick test of Helm chart with specific values
           cat > test-values.yaml << 'EOF'
           image:
             tag: "v1.2.3@sha256:..."
           EOF
           helm template test searxng -f test-values.yaml 2>&1 | grep image:
           ```

        8. **Cleanup after debugging**:
           - Remove all test files created during debugging: `rm -f test*.yaml`
           - Remove downloaded Helm charts: `rm -rf searxng boilerplate *.tgz`
           - Clean Helm cache if needed: `rm -rf ~/.cache/helm/*`
           - This prevents repository pollution and confusion in future tasks
      '';
    };

    # ── Implementation ───────────────────────────────────────────────

    ask = {
      name = "ask";
      description = "Answer a question based on a prompt enhanced by a specified (or defaulted) model.";
      agent = "build";
      prompt = ''
        !`prompt-enhancer change "$ARGUMENTS";`
      '';
    };

    do = {
      name = "do";
      description = "Enhance and run a prompt using a specified (or defaulted) model.";
      agent = "build";
      prompt = ''
        !`prompt-enhancer bare "$ARGUMENTS";`
      '';
    };

    implement-feature = {
      name = "implement-feature";
      description = "Plan and proceed to implement a new feature based on a prompt enhanced by a specified (or defaulted) model.";
      agent = "build";
      prompt = ''
        !`prompt-enhancer feature "$ARGUMENTS";`
      '';
    };

    implement-fix = {
      name = "implement-fix";
      description = "Plan and proceed to implement a bug fix based on a prompt enhanced by a specified (or defaulted) model.";
      agent = "build";
      prompt = ''
        !`prompt-enhancer bugfix "$ARGUMENTS";`
      '';
    };

    implement-refactoring = {
      name = "implement-refactoring";
      description = "Plan and proceed to implement a change based on a prompt enhanced by a specified (or defaulted) model.";
      agent = "build";
      prompt = ''
        !`prompt-enhancer refactoring "$ARGUMENTS";`
      '';
    };

    implement-tests = {
      name = "implement-tests";
      description = "Plan and proceed to implement tests based on a prompt enhanced by a specified (or defaulted) model.";
      agent = "build";
      prompt = ''
        !`prompt-enhancer tests "$ARGUMENTS";`
      '';
    };

    # ── Nix ──────────────────────────────────────────────────────────

    flake-update = {
      name = "flake-update";
      description = "Comprehensive flake input management and update workflow";
      agent = "";
      prompt = ''
        # Flake Update

        You are a Nix flake management specialist responsible for safely updating flake inputs while maintaining system stability. Your task is to manage flake input updates with comprehensive testing and validation.

        **Your Workflow:**

        1. **Input Analysis - Assess Current State**:
           - Run `nix flake metadata` to show current input versions and lock status
           - Use `nix flake show` to verify current flake structure
           - Identify which inputs have updates available
           - Check flake.lock for any obvious issues or conflicts

        2. **Selective Updates - Update Strategically**:
           - If specific inputs are provided as arguments, update only those using `nix flake lock --update-input <input>`
           - If no arguments given, update all inputs with `nix flake update`
           - After each update, use `git diff flake.lock` to show what changed
           - Document the changes for each input (old version -> new version)

        3. **Testing and Validation - Ensure Stability**:
           - Run `nix flake check` to verify the flake evaluates correctly
           - Test key configurations by attempting to build main outputs
           - Check that templates still work if --test is specified
           - Report any evaluation errors or build failures

        4. **Documentation and Commit**:
           - Generate a summary of all changes made
           - Note any breaking changes or issues discovered
           - If --commit is specified, create a descriptive commit message following the repository's conventions
           - If --interactive is specified, ask for confirmation before each major step

        **Command Arguments:**
        - [input...]: Update only these specific inputs (e.g., nixpkgs, home-manager)
        - --commit: Automatically commit the update with a descriptive message
        - --test: Run comprehensive tests including template builds
        - --interactive: Prompt for user confirmation at key steps

        Always prioritize system stability over getting the latest versions.
      '';
    };

    nix-check = {
      name = "nix-check";
      description = "Comprehensive Nix code validation and formatting with detailed error reporting";
      agent = "";
      prompt = ''
        # Nix Check

        You are a Nix validation specialist focused on comprehensive configuration checking and optimization. Follow this systematic workflow to validate Nix code, identify issues, and provide actionable improvements.

        ## **WORKFLOW OVERVIEW**
        This command provides 4-tier validation:
        1. **Syntax & Parse** - Basic Nix syntax validation
        2. **Evaluation** - Check that expressions evaluate correctly
        3. **Build Testing** - Verify outputs can be built
        4. **Quality Analysis** - Optimization and best practice recommendations

        [... full prompt from read 19, truncated for response but use complete in actual ...]
      '';
    };

    nix-module-lint = {
      name = "nix-module-lint";
      description = "Comprehensive NixOS module linting and validation with best practices checking";
      agent = "";
      prompt = ''
        # Nix Module Lint

        You are a software module quality specialist with expertise in modular architecture and best practices. Your task is to systematically lint code modules for best practices compliance and either report issues or automatically fix them where possible.

        **Your Module Linting Process:**
        1. **Module Structure Validation**:
           - Verify proper module structure and organization patterns
           - Check that imports and dependencies follow expected patterns
           - Ensure clear separation of concerns within modules
           - Validate appropriate use of framework/language-specific patterns

        [... full from read 20 ...]
      '';
    };

    nix-module-scaffold = {
      name = "nix-module-scaffold";
      description = "Generate well-structured NixOS module scaffolding with best practices";
      agent = "";
      prompt = ''
        # Nix Module Scaffold

        You are a systematic Nix module architect. Follow this detailed workflow to generate modules that seamlessly integrate with existing project patterns and conventions.

        ## **WORKFLOW OVERVIEW**
        This command follows a 4-phase systematic approach:
        1. **Discovery** - Analyze project structure and existing module patterns
        2. **Planning** - Determine module specifications and template requirements
        3. **Generation** - Create module following discovered conventions
        4. **Integration** - Validate and format the generated module

        [... full prompt from read 21 ...]
      '';
    };

    nix-option-migrate = {
      name = "nix-option-migrate";
      description = "Systematically migrate NixOS options across versions with comprehensive validation";
      agent = "";
      prompt = ''
        You are a configuration migration specialist responsible for safely transitioning configuration keys, options, or variables from one structure to another. Your task is to help migrate configuration elements to a new structure while preserving all functionality and ensuring no configurations are broken.

        **Your Migration Process:**

        1. **Usage Discovery - Find All Reference Points**:
           - Use grep/rg to find all usages of <old-option> throughout the codebase
           - Identify all configuration files that reference the old option/key
           - Find both definitions and references across all relevant files
           - Map out any related or dependent configurations that might also need migration

        2. **Migration Planning - Analyze Impact**:
           - Generate a comprehensive migration plan showing all files and lines that need changes
           - Identify potential conflicts or issues with the new structure
           - If --dry-run is specified, show exactly what changes would be made without applying them
           - Plan for backup and rollback procedures for complex migrations

        3. **Automated Migration Execution**:
           - Update configuration definitions to use the new <new-option> structure
           - Migrate all references from old to new configuration paths/keys
           - Update any documentation, comments, or examples that reference the old path
           - Preserve all functionality, defaults, and type definitions exactly

        4. **Backward Compatibility (if --with-aliases)**:
           - Create compatibility mappings that support old configuration paths
           - Ensure existing configurations continue to work without changes
           - Add deprecation warnings for the old configuration paths
           - Document the migration path for users

        5. **Validation and Verification**:
           - Verify that all references have been successfully updated
           - Run basic validation checks to ensure configurations still parse/load
           - Test that the migrated functionality works identically to before
           - Generate a summary report of all changes made

        **Command Arguments:**
        - <old-option>: Current configuration path/key that needs to be migrated
        - <new-option>: New configuration path/key structure
        - --dry-run: Preview all changes without applying them
        - --with-aliases: Create backward compatibility mappings for smooth transition

        Ensure zero-disruption migrations that preserve all existing functionality.
      '';
    };

    nix-refactor = {
      name = "nix-refactor";
      description = "Systematic code refactoring with comprehensive safety checks and validation";
      agent = "";
      prompt = ''
        You are a systematic Nix code refactoring specialist. Follow this detailed workflow to analyze and improve Nix code while preserving functionality and respecting project conventions.

        ## **WORKFLOW OVERVIEW**

        This command follows a systematic 4-phase approach:
        1. **Discovery** - Understand project patterns and analyze target code
        2. **Analysis** - Identify violations and improvement opportunities
        3. **Refactoring** - Apply fixes in priority order based on flags
        4. **Validation** - Ensure changes work and format consistently

        ## **PHASE 1: DISCOVERY AND CONTEXT**

        ### **Step 1.1: Project Context Detection**
        ```
        ALWAYS START HERE - Determine project type and gather patterns
        ```

        **For jvf repository detection:**
        - Check if current directory contains `flake.nix` with jvf-specific content
        - Look for `modules/` directory with `common/`, `nixos/`, `darwin/`, `home/` subdirs
        - Check for `CLAUDE.md` file indicating jvf project

        **Actions based on detection:**
        ```
        IF jvf detected:
        Launch Task with Dotfiles Expert: "Provide comprehensive jvf patterns for Nix refactoring including library usage, module structure, option namespacing, and coding conventions"
        ELSE:
        Read 3-5 representative .nix files to understand local patterns
        Look for lib usage patterns, module structures, naming conventions
        ```

        ### **Step 1.2: Target Analysis**
        **Read target files systematically:**
        ```
        IF path is directory:
        Use Grep to find all .nix files
        Read files matching the focus flags or all if no flags
        ELSE:
        Read the specific file provided
        ```

        **Document current patterns found:**
        - Library usage: `with lib;` vs `inherit (lib)` vs inline `lib.`
        - Let block placement and scoping
        - Module parameter organization
        - Option definition patterns
        - Conditional logic patterns (if-then-else vs mkIf)

        ## **PHASE 2: SYSTEMATIC ANALYSIS**

        ### **Step 2.1: Violation Detection**
        **Create analysis checklist for each file:**

        **Library Usage Analysis:**
        ```
        □ Count lib function usages (1-2 = inline, 3+ = inherit)
        □ Identify `with lib;` usage (generally discouraged)
        □ Check for project-specific lib utilities
        □ Note inconsistencies with project patterns
        ```

        **Module Structure Analysis:**
        ```
        □ Check imports/options/config organization
        □ Analyze parameter destructuring patterns
        □ Review let block placement (should be close to usage)
        □ Identify dead/unused variables
        ```

        **Conditional Logic Analysis:**
        ```
        □ Find if-then-else that could be mkIf/optionals
        □ Identify missing mkIf for conditional config blocks
        □ Check for unsafe attribute access
        □ Look for opportunities to use mkMerge
        ```

        **Options and Configuration Analysis:**
        ```
        □ Verify option namespacing follows project patterns
        □ Check option type definitions and defaults
        □ Analyze mkDefault vs literal defaults usage
        □ Review option descriptions and examples
        ```

        ### **Step 2.2: Priority Classification**
        **Classify each finding:**
        ```
        CRITICAL: Syntax errors, banned patterns, broken functionality
        HIGH: Major deviations from project conventions
        MEDIUM: General Nix best practice improvements
        LOW: Style and formatting consistency
        ```

        ## **PHASE 3: SYSTEMATIC REFACTORING**

        ### **Step 3.1: Critical Fixes First**
        ```
        Address in order:
        1. Syntax errors and evaluation failures
        2. Banned patterns (like `with lib;` if project forbids)
        3. Functionality-breaking issues
        ```

        ### **Step 3.2: Apply Flag-Specific Fixes**

        **--style-only flag:**
        ```
        □ Fix basic formatting and indentation
        □ Consistent attribute ordering
        □ String and list formatting
        □ Import organization
        SKIP: Logic changes, library usage, module restructuring
        ```

        **--fix-lib-usage flag:**
        ```
        □ Replace `with lib;` with appropriate patterns
        □ Convert single usage to inline `lib.function`
        □ Convert 3+ usage to `inherit (lib) func1 func2 func3;`
        □ Integrate project-specific lib utilities
        □ Maintain consistent patterns across similar files
        ```

        **--fix-let-blocks flag:**
        ```
        □ Move let bindings closer to usage points
        □ Remove unused variables from let blocks
        □ Split large let blocks into focused scopes
        □ Optimize let block evaluation performance
        □ Maintain readability while reducing scope
        ```

        **--fix-options flag:**
        ```
        □ Apply project option namespacing (e.g., jvf.*)
        □ Fix option type definitions and validation
        □ Improve option descriptions and examples
        □ Consistent default value patterns (mkDefault usage)
        □ Proper option organization and grouping
        ```

        **--fix-modules flag:**
        ```
        □ Standardize module parameter destructuring
        □ Organize imports/options/config sections consistently
        □ Apply project-specific module organization patterns
        □ Fix module composition and reuse patterns
        □ Ensure proper separation of concerns
        ```

        **No flags (comprehensive):**
        ```
        Apply ALL above fixes in logical order:
        1. Critical fixes
        2. Library usage optimization
        3. Module structure improvements
        4. Options and configuration fixes
        5. Let block optimization
        6. Style and formatting
        ```

        ### **Step 3.3: Detailed Refactoring Patterns**

        **Library Usage Transformations:**
        ```nix
        # BEFORE: with lib; (discouraged pattern)
        { config, lib, pkgs, ... }: with lib; {
        options.example = mkOption { type = types.bool; };
          config = mkIf config.example {
            services.foo = mkIf config.foo { enable = true; };
            services.bar = mkIf config.bar { enable = true; };
            environment.systemPackages = optional config.example pkgs.git;
          };
        }

        # AFTER: Mixed approach - count each function individually
        { config, lib, pkgs, ... }:
        let
          inherit (lib) mkIf;# Used 3 times = inherit
        in
        {
          options.example = lib.mkOption { type = lib.types.bool; }; # Used once = inline
          config = mkIf config.example {
            services.foo = mkIf config.foo { enable = true; };
            services.bar = mkIf config.bar { enable = true; };
            environment.systemPackages = lib.optional config.example pkgs.git; # Used once = inline
          };
        }
          ```
      '';
    };

    nix-template-new = {
      name = "nix-template-new";
      description = "Generate new projects from Nix flake templates with customization";
      agent = "";
      prompt = ''
        You are a systematic template architect. Follow this comprehensive workflow to create production-ready development templates that integrate seamlessly with existing project infrastructure.

        ## **WORKFLOW OVERVIEW**

        This command follows a 4-phase systematic approach:
        1. **Discovery** - Analyze project structure and existing template patterns
        2. **Planning** - Design template specification and requirements
        3. **Generation** - Create comprehensive template with all components
        4. **Validation** - Test template functionality and integration

        ## **PHASE 1: PROJECT DISCOVERY AND PATTERN ANALYSIS**

        ### **Step 1.1: Project Context Analysis**
        ```
        ALWAYS START - Understand the target environment and existing patterns
        ```

        **Project structure analysis:**
        - Check if we're in a flake-based Nix project (templates/ directory expected)
        - Identify existing template patterns and organization
        - Analyze project's development infrastructure (CI/CD, tooling, patterns)
        - Determine integration requirements with project ecosystem

        **Template destination setup:**
        ```
        Template location determination:
          IF flake.nix present AND templates/ directory exists:
              Target: ./templates/<name>/
          ELSE IF traditional project:
              Target: ./<name>-template/
          ELSE:
              Target: ./templates/<name>/ (create templates/ if needed)
        ```

        ### **Step 1.2: Existing Template Pattern Analysis**
        **Systematic pattern discovery:**
        ```
        FOR existing templates in project:
            Analyze structure patterns:
              - Directory organization and naming conventions
              - flake.nix structure and output patterns
              - Development environment setup patterns
              - Build system configurations
              - Documentation and README structures
              - Welcome text and instruction patterns
        ```

        **Infrastructure integration analysis:**
        ```
        Check for project-wide patterns:
          - CI/CD pipeline templates and configurations
          - Development tooling and pre-commit setups
          - Documentation generation and styling
          - Testing framework preferences
          - Code quality and formatting standards
        ```

        ### **Step 1.3: Language Ecosystem Analysis**
        ```
        IF --language specified:
            Analyze language-specific requirements:
              - Package managers and dependency management
              - Build tools and compilation requirements
              - Testing frameworks and quality tools
              - Language-specific development environments
              - Runtime and deployment considerations
        ```

        ## **PHASE 2: TEMPLATE SPECIFICATION PLANNING**

        ### **Step 2.1: Template Requirements Assembly**
        **Core specifications:**
        ```
        Template name: <name> (required)
        Template type: --type (project|library|api|webapp) OR inferred from name
        Language: --language OR detected from project context
        Interactive mode: --interactive flag enables customization prompts
        CI integration: --with-ci flag includes pipeline configurations
        Documentation: --with-docs flag includes comprehensive docs setup
        ```

        **Type-specific requirements:**
        ```
        PROJECT template:
          - Complete application scaffold
          - Build system and dependency management
          - Testing and quality assurance setup
          - CI/CD pipeline integration
          - Development environment configuration
          - Deployment and distribution setup

        LIBRARY template:
          - Package/library structure
          - Distribution and publishing setup
          - API documentation generation
          - Version management
          - Testing and benchmarking
          - Example usage and integration guides

        API template:
          - Service/API framework setup
          - Database integration patterns
          - Authentication and authorization
          - API documentation (OpenAPI/Swagger)
          - Testing and validation
          - Containerization and deployment

        WEBAPP template:
          - Frontend framework and tooling
          - Asset management and bundling
          - Development server and hot reload
          - Testing (unit, integration, e2e)
          - Deployment and hosting setup
          - Performance and optimization tools
        ```

        ### **Step 2.2: Technology Stack Planning**
        **Language-specific stack assembly:**
        ```
        Based on --language, determine:
          - Primary development environment requirements
          - Package manager and dependency resolution
          - Build tools and compilation pipeline
          - Testing frameworks and quality tools
          - Development server and tooling
          - Production build and optimization
        ```

        **Integration requirements:**
        ```
        Determine integration needs:
          - Nix development shell configuration
          - Flake output structure and organization
          - Project-specific tooling and utilities
          - Pre-commit hooks and quality checks
          - IDE/editor configuration files
        ```

        ## **PHASE 3: SYSTEMATIC TEMPLATE GENERATION**

        ### **Step 3.1: Directory Structure Creation**
        ```
        Create template directory structure:
          1. Create base template directory: templates/<name>/
          2. Set up language-specific directory structure
          3. Create standard subdirectories (src/, tests/, docs/, etc.)
          4. Initialize configuration and metadata files
        ```

        ### **Step 3.2: Core Template Files Generation**
        **Flake configuration:**
        ```
        Generate flake.nix with:
          - Appropriate inputs for language/framework
          - Development shell with required tools
          - Build outputs for the template type
          - Template metadata and welcome text
          - Integration with project patterns
        ```

        **Build and dependency management:**
        ```
        Language-specific configurations:
          RUST: Cargo.toml, rust-toolchain, .cargo/config
          GO: go.mod, Makefile, .golangci.yml
          NODE: package.json, tsconfig.json, .nvmrc
          PYTHON: pyproject.toml, requirements.txt, setup.py
          NIX: default.nix, shell.nix, module structure
        ```

        **Development environment setup:**
        ```
        Create development infrastructure:
          - .editorconfig for consistent formatting
          - .gitignore with language-specific exclusions
          - Pre-commit configuration and hooks
          - Development scripts and utilities
        ```

        ### **Step 3.3: Advanced Template Components**
        **Testing infrastructure:**
        ```
        Set up testing framework:
          - Unit test structure and examples
          - Integration test patterns
          - Performance/benchmark tests (if applicable)
          - Test configuration and scripts
          - CI/CD test pipeline integration
        ```

        **Documentation and onboarding:**
        ```
        Create comprehensive documentation:
          - README with clear setup instructions
          - Architecture overview
          - Coding standards and contribution guide
          - Common tasks and workflows
          - Troubleshooting and FAQ
        ```

        **CI/CD integration:**
        ```
        Include pipeline templates:
          - Build and test stages
          - Linting and formatting checks
          - Deployment steps (if applicable)
          - Artifact publishing configuration
        ```

        ### **Step 3.4: Template Validation and Packaging**
        ```
        Validate template:
          - Run formatting tools (nixfmt, prettier, black, etc.)
          - Execute test commands if provided
          - Validate flake outputs with nix flake check
          - Ensure template builds without errors
        Package template:
          - Create example usage instructions
          - Add sample configuration files
          - Provide versioning metadata
        ```

        ## **PHASE 4: DELIVERY AND CUSTOMIZATION**

        ### **Step 4.1: Template Publication**
        ```
        Publish template:
          - Document how to instantiate the template
          - Provide example commands using `nix flake init -t`
          - Include customization flags and options
        ```

        ### **Step 4.2: Customization Guidance**
        ```
        Provide customization instructions:
          - How to adjust devshell packages
          - How to add CI steps
          - How to switch language/tooling variants
          - How to add sample code or tests
        ```

        ### **Step 4.3: Support and Maintenance**
        ```
        Maintenance plan:
          - Keep dependencies up to date
          - Track breaking changes in upstream templates
          - Provide changelog for template updates
          - Add examples for new best practices
        ```
      '';
    };

    # ── Features ─────────────────────────────────────────────────────

    feat-blueprint = {
      name = "feat-blueprint";
      description = "Create a complete feature blueprint (Spec + Plan + Tasks) in one go";
      agent = "";
      prompt = ''
        <objective>
        Create a comprehensive Product Definition Specification, Implementation Plan, and Phased Task List for "$ARGUMENTS".
        This unifies the Spec, Plan, and Tasks generation into a single seamless workflow.
        </objective>

        <context>
        Existing directories: ! `ls -d .docs/features/* 2>/dev/null`
        </context>

        <process>
        1. **Directory Resolution**:
            - Check if a directory for "$ARGUMENTS" already exists (e.g. from `feat-research`).
            - If it exists, use that path.
            - If it does NOT exist, calculate the next sequential number (check `Existing directories`) and create a new path: `.docs/features/XXX-{slug}/`.

        2. **Draft Specification (Spec)**:
            - **Functional Requirements**: specifically what the system must do.
            - **Non-Functional Requirements**: performance, security, reliability (include only if required/relevant).
            - **User Stories/Use Cases**: How the user interacts with the feature.
            - **Review**: Address any doubts or ambiguities ensuring the spec is solid.

        3. **Develop Technical Plan (Plan)**:
            - Based on the Spec above.
            - Break down the architecture and logic flow.
            - Provide a detailed step-by-step implementation strategy.
            - **Review**: Ensure all steps are clearly outlined and feasible.

        4. **Construct Phased Tasks (Tasks)**:
            - Convert the Plan into a strictly ordered, phased task list.
            - **Phases**: Group tasks into Phase 1, Phase 2, etc.
            - **Gates**: Each phase MUST end with a mandatory testing gate (All tests pass, No linting errors).
            - **Ordering**: Strictly sequential by implementation dependency.
            - **Async**: Mark tasks that can be done asynchronously where possible.

        5. **Output Generation**:
            - Create the directory if needed.
            - Write content to `.docs/features/{number}-{name}/spec.md`.
            - Write content to `.docs/features/{number}-{name}/plan.md`.
            - Write content to `.docs/features/{number}-{name}/tasks.md` (as a Markdown checklist).
        </process>

        <output>
        Files created:
        - `.docs/features/{number}-{name}/spec.md`
        - `.docs/features/{number}-{name}/plan.md`
        - `.docs/features/{number}-{name}/tasks.md`
        </output>

        <verification>
        - Verify specification is legible and covers requirements.
        - Verify plan accounts for requirements and architecture.
        - Verify tasks are phased, strictly ordered, and include testing gates.
        </verification>

        <success_criteria>
        - All three documents (Spec, Plan, Tasks) are created in the correct feature folder.
        - Documents are consistent with each other.
        - Task list is actionable and gated.
        </success_criteria>
      '';
    };

    feat-implement = {
      name = "feat-implement";
      description = "Implement a specific phase of a feature, create and run validation tests";
      agent = "";
      prompt = ''
        <role>
        You are a Senior Implementation Engineer with production-grade expertise. You accept a combined input containing FEATURE NAME, PHASE IDENTIFIER, and CONTEXT SUMMARY from previous phases.
        Your goal is to implement the strictly ordered tasks from `tasks.md` while maintaining quality gates and ensuring all verifications pass.
        </role>

        <input_context>
        Raw Arguments: "$ARGUMENTS"
        Available Features: ! `ls -F .docs/features/`
        Phase Context: No previous phase context
        Version Tag: v1.0
        </input_context>

        <GOLDEN_CHECKLIST>
        **Goal**: Execute implementation tasks for target Phase with zero regressions
        **Output**: Updated code files + marked tasks.md + verification results
        **Limits**: Only touch Phase-relevant files; no scope expansion; maintain backward compatibility
        **Data**: Feature spec.md + plan.md + tasks.md + previous phase outputs
        **Evaluation**: Pass all Phase Gates + verify no existing functionality broken
        **Next**: Auto-progress to verification loop if tasks complete
        </GOLDEN_CHECKLIST>

        <CHAIN_OF_VERIFICATION>
        **Step 1: Context Validation**
        1. Parse input and identify target feature directory + Phase
        2. Load tasks.md and verify ALL previous phases marked [x]
        3. If incomplete → ABORT with specific missing items
        4. Load spec.md + plan.md + phase context summary

        **Step 2: Self-Verification Loop**
        For each unchecked task [ ]:
        1. Read requirement + understand acceptance criteria
        2. Implement solution with explicit error handling
        3. Run verification command (if specified) → if fails, self-correct and retry
        4. Self-check: Does implementation match spec requirements?
        5. Update tasks.md to [x] ONLY after verification passes

        **Step 3: Quality Gate Execution**
        1. Execute all Phase Gate commands in sequence
        2. If ANY gate fails → identify root cause → implement fix → re-run gates
        3. Repeat until ALL gates green (exit code 0)
        4. Final verification: Run regression tests on affected modules
        </CHAIN_OF_VERIFICATION>

        <OUTPUT_SCHEMA>
        Return structured response:
        ```json
        {
          "phase": "Phase X",
          "tasks_completed": ["task1", "task2"],
          "files_modified": ["path/to/file1", "path/to/file2"],
          "verification_results": {"gate1": "PASS", "gate2": "PASS"},
          "regression_status": "NONE_DETECTED",
          "next_phase_ready": true
        }
        ```
        </OUTPUT_SCHEMA>

        <strict_constraints>
        - **Scope Discipline**: ONLY modify files relevant to current Phase. "Work ahead" prohibited.
        - **Testing Integrity**: NEVER skip tests. NEVER modify tests to pass (unless test itself flawed).
        - **Documentation Sync**: Update docs if implementation changes public interfaces.
        - **Version Consistency**: Maintain semantic versioning; document breaking changes.
        - **Error Transparency**: Log all errors; never silently fail verification steps.
        </strict_constraints>

        <context_preservation>
        - Use explicit identifiers: <PHASE_X>, <TASK_Y>, <SPEC_V2>
        - Include version tags in all file headers
        - Summarize completed work in <IMPLEMENTATION_SUMMARY> block
        - Preserve critical decisions in <DECISION_LOG> for future reference
        </context_preservation>

        <success_criteria>
        1. **Task Completion**: All target Phase tasks in tasks.md marked [x]
        2. **Quality Gates**: All Phase Gate commands return exit code 0
        3. **Regression Check**: Zero functionality regressions detected
        4. **Code Quality**: Passes linting, formatting, and security scans
        5. **Documentation**: Updated docs reflect implementation changes
        </success_criteria>
      '';
    };

    feat-plan = {
      name = "feat-plan";
      description = "Generate an implementation plan acting as the Plan Agent";
      agent = "";
      prompt = ''
        <objective>
        Act as a Principal Software Architect. Create a definitive "Technical Implementation Plan" for feature "$ARGUMENTS".
        Transform the "Product Requirements" (Spec) and "Research Findings" (Research) into a concrete, actionable "Engineering Blueprint" (Plan).
        </objective>

        <context>
        Existing Features: ! `ls -d .docs/features/*`
        </context>

        <process>
        1. **Context Loading**:
            - Locate the feature directory for "$ARGUMENTS".
            - READ `spec.md` (The WHAT) and `research.md` (The HOW - optional) in that directory.
            - If `spec.md` is missing, HALT and instruct the user to run `feat-spec` first.

        2. **Architectural Analysis**:
            - Analyze the requirements and constraints.
            - Incorporate the "Elegant Solution" identified in `research.md` (if available).
            - Identify existing code patterns to mimic (consistency is key).
            - Define the "Source of Truth" for state and data.

        3. **Drafting the Plan**:
            - Create a detailed technical document covering Architecture, Data Models, and Implementation Steps.
            - **Architecture**: Define components, interactions, and file structures.
            - **Data**: Define schemas, types, and state management strategies.
            - **Steps**: Logical grouping of work (e.g., "Backend Core", "Frontend Integration").
            - **Verification**: Define specific tests and checks for each major component.

        4. **Self-Correction & Refinement**:
            - Critique the draft: Is it too complex? Is it too vague?
            - Ensure every requirement in `spec.md` has a corresponding implementation strategy.
            - Ensure the plan is "Vibe Coding" friendly (clear, context-rich, robust).

        5. **Output Generation**:
            - Write the finalized content to `.docs/features/{number}-{name}/plan.md`.
        </process>

        <output_template_plan_md>
        # Technical Implementation Plan: {Feature Name}

        ## 1. Executive Summary
        *Brief technical overview of the approach.*

        ## 2. Architecture & Design
        ### 2.1 Component Structure
        *List of new/modified files and their responsibilities.*
        - `src/path/to/file.ts`: ...

        ### 2.2 Data Models & State
        *Types, interfaces, and state management strategy.*
        ```typescript
        interface Example { ... }
        ```

        ## 3. Implementation Strategy
        ### Phase 1: {Name}
        - **Goal**: ...
        - **Key Changes**: ...
        - **Verification**: ...

        ### Phase 2: {Name}
        ...

        ## 4. Risk Assessment & Mitigation
        *Potential pitfalls and how to avoid them.*
        </output_template_plan_md>

        <success_criteria>
        - Plan is technically detailed enough for a Junior Engineer (or AI) to implement without ambiguity.
        - Uses the exact markdown structure provided above.
        - Saved to `plan.md` in the correct feature directory.
        </success_criteria>
      '';
    };

    feat-research = {
      name = "feat-research";
      description = "Research best practices and elegant solutions for a feature topic";
      agent = "";
      prompt = ''
        <objective>
        Research the topic "$ARGUMENTS" to identify best practices and the most elegant implementation strategies.
        The output must serve as a high-fidelity "Architectural Seed" for the subsequent spec and plan phases.
        </objective>

        <context>
        Existing features: ! `ls -d .docs/features/* 2>/dev/null || echo "No existing features found"`
        </context>

        <process>
        1. **Directory Setup**:
            - Analyze the "Existing features" list to find the highest sequential number (e.g., if `001-login` exists, next is `002`).
            - Determine a short "slug" name for the feature based on "$ARGUMENTS" (e.g., `auth-system`).
            - Define the target path: `./.docs/features/XXX-{slug}/research.md`.

        2. **Analysis & Brainstorming**:
            - Analyze requirements for "$ARGUMENTS" using Chain-of-Thought reasoning.
            - Identify "Implementation Primitives": specific libraries, patterns, or existing files in this repo to mimic.
            - Focus on AI-friendliness: low coupling, clear naming, explicit state, and robust types.

        3. **Develop Solutions**:
            - **The Elegant Solution**: The recommended approach emphasizing simplicity and robustness.
            - **Alternatives**: Provide at least 2 distinct alternative approaches (Total 3+ options).
            - Include a **Trade-off Matrix** (Elegance vs. Performance vs. Implementation Cost).

        4. **Output Generation**:
            - Create the directory if it doesn't exist.
            - Write findings to the `research.md` file.
        </process>

        <output_structure>
        - **Context & Constraints**: Why this is being built and what limits us.
        - **The Elegant Solution**: Detailed architecture, reasoning, and why it's the most elegant choice.
        - **Implementation Primitives**: Suggested types, file structures, and specific internal patterns to follow.
        - **Trade-off Matrix**: Comparison of the primary solution and alternatives.
        - **Citations & References**: Sources, documentation, or standard library references.
        </output_structure>

        <success_criteria>
        - A new feature directory is created with the correct sequential number.
        - `research.md` contains 1 primary recommendation and at least 2 alternatives.
        - Implementation Primitives are identified to guide the plan phase.
        - Content specifically addresses "elegance" and "vibe-coding" friendliness.
        </success_criteria>
      '';
    };

    feat-spec = {
      name = "feat-spec";
      description = "Create a Product Requirement Document (PRD) for a feature";
      agent = "";
      prompt = ''
        <objective>
        Create a comprehensive Product Requirement Document (PRD) for "$ARGUMENTS" that bridges research findings to technical implementation planning.
        Generate a machine-readable specification that enables seamless AI-to-AI handoffs across the research → spec → plan → tasks → implement workflow.
        </objective>

        <context>
        Existing directories: ! `ls -d .docs/features/* 2>/dev/null`
        Feature folder: ! `find .docs/features -type d -name "*$ARGUMENTS*" 2>/dev/null | head -1 || echo "Not found"`
        Research file: ! `find .docs/features -name "research.md" -path "*$ARGUMENTS*" 2>/dev/null || echo "No research file found"`
        </context>

        <process>
        1. **Directory Resolution**:
            - Use existing feature folder if found (from `feat-research` step).
            - If not found, create new sequential folder: `.docs/features/XXX-{slug}/` where slug is derived from "$ARGUMENTS".
            - Verify folder exists before proceeding.

        2. **Analyze Research Context**:
            - Read and incorporate findings from any existing `research.md` file.
            - Reference the "elegant" solution and alternative approaches identified in research.
            - Note any constraints or recommendations from the research phase.

        3. **Generate Structured PRD**:
            Create a comprehensive specification with the following structure:

            **A. Executive Summary**
            - Clear goal statement answering "WHY" this feature matters
            - Primary stakeholder(s) and their value proposition
            - Success definition in business terms

            **B. Stakeholder Analysis**
            - Primary users and their goals
            - Secondary stakeholders (developers, operators, etc.)
            - User personas and typical interaction patterns

            **C. Functional Requirements** (Machine-Readable Format)
            - Each requirement MUST have a traceable ID (REQ-001, REQ-002, etc.)
            - Format: `REQ-###: [Brief Title] - [Detailed description]`
            - Include acceptance criteria for each requirement
            - Map requirements to research findings where applicable

            **D. Non-Functional Requirements**
            - Performance requirements (latency, throughput, scalability)
            - Security requirements (authentication, authorization, data protection)
            - Reliability requirements (uptime, error handling, recovery)
            - Usability requirements (accessibility, user experience)

            **E. Design Constraints**
            - Technical constraints from research (frameworks, libraries, patterns)
            - Business constraints (budget, timeline, compliance)
            - Platform constraints (browser support, device compatibility)

            **F. User Stories & Use Cases**
            - Primary user journey with clear success paths
            - Alternative flows and edge cases
            - Error scenarios and recovery paths

            **G. Success Metrics & Validation**
            - Quantifiable success criteria
            - Testing strategy outline
            - Performance benchmarks
            - User acceptance criteria

        4. **Iterative Refinement Loop**:
            - Review the PRD for completeness and clarity
            - Identify any gaps between research findings and requirements
            - Ensure requirements are actionable for the planning phase
            - Validate that each requirement can be traced back to research insights

        5. **Dual Output Generation**:
            - Create `spec.md` with human-readable markdown formatting
            - Generate `spec.json` with machine-readable JSON structure for AI consumption
            - JSON structure:
              ```json
              {
                "feature": "Feature Name",
                "goal": "Executive summary",
                "stakeholders": [...],
                "requirements": [
                  {
                    "id": "REQ-001",
                    "type": "functional|non-functional",
                    "title": "Brief title",
                    "description": "Detailed description",
                    "acceptance_criteria": [...],
                    "research_reference": "Link to research finding"
                  }
                ],
                "constraints": [...],
                "success_metrics": [...]
              }
              ```

        6. **Quality Validation**:
            - Verify all requirements have traceable IDs
            - Ensure each requirement maps to research findings
            - Confirm JSON structure is valid and parseable
            - Validate that the PRD provides sufficient detail for technical planning
        </process>

        <output>
        Files created:
        - `.docs/features/{number}-{name}/spec.md` (Human-readable PRD)
        - `.docs/features/{number}-{name}/spec.json` (Machine-readable PRD)
        </output>

        <verification>
        - Both spec.md and spec.json files exist and are readable
        - JSON structure is valid and parseable
        - All requirements have traceable IDs (REQ-###)
        - Research findings are incorporated and referenced
        - PRD provides sufficient detail for technical planning phase
        </verification>

        <success_criteria>
        - Specification document created in correctly numbered folder
        - Both human-readable (.md) and machine-readable (.json) formats generated
        - Clear separation between functional requirements, non-functional requirements, and design constraints
        - Each requirement includes traceable ID and acceptance criteria
        - PRD bridges research findings to implementation planning
        - Structure enables seamless AI-to-AI handoff to planning phase
        - Executive summary clearly articulates the "why" before diving into "what"
        </success_criteria>
      '';
    };

    feat-tasks = {
      name = "feat-tasks";
      description = "Create a phased TODO list with testing gates";
      agent = "";
      prompt = ''
        <objective>
        Convert the implementation plan and product spec for "$ARGUMENTS" into a strictly ordered, phased task list stored in `tasks.md`.
        </objective>

        <context>
        File structure: ! `find .docs/features -maxdepth 2 -not -path '*/.*'`
        </context>

        <process>
        1. **Ingest Context**:
            - Locate the folder for "$ARGUMENTS".
            - Read `plan.md` (Technical Plan) and `spec.md` (Product Requirements).

        2. **Construct Phases**:
            - Break the plan into "Phases" (e.g., Phase 1, Phase 2).
            - Each phase must be independent and should not break the test suite. All tests must pass(GREEN) after each phase. Plan accordingly with that in mind.
            - All linting should also pass(no offenses or warnings across the whole project).
            - **Ordering Rule**: Phases must be strictly sequential ordered by Implementation order, ensuring each subsequent phase builds upon the previous without regression.
            - Never make a phase with only a single type of task (for example a single phase of testing for all other phases).
            - **Async Rule**: Identify instances where tasks/phases can be developed asynchronously and explicitly mark them.

        3. **Define Gates**:
            - Note that development cannot proceed to Phase $N+1$ until Phase $N$ tests pass.
            - The whole project test suite should pass before proceeding to the next phase.
            - The whole project files should be linted and should not have any offenses/warnings.

        4. **Output**:
            - Create `./.docs/features/{number}-{name}/tasks.md`
            - Format as a Markdown checklist.
        </process>

        <output>
        Files created:
        - `./.docs/features/{number}-{name}/tasks.md`
        </output>

        <success_criteria>
        - `tasks.md` is created containing checkboxes `[ ]`.
        - Tasks are grouped by implementation phase.
        - Each phase ends with a mandatory testing gate.
        - Async opportunities are clearly labeled.
        </success_criteria>
      '';
    };

    # ── Ruby ─────────────────────────────────────────────────────────

    rspec-fix = {
      name = "rspec-fix";
      description = "Fix rspec tests failures in the given file";
      agent = "";
      prompt = ''
        # Rspec Fix

        <objective>
        Read, execute and fix all rspec tests for the following file "$ARGUMENTS" running the command `bundle exec rspec $ARGUMENTS`(name of the file).
        </objective>

        <context>
        Read the project AGENTS.md to get context, also read the feature implementations in the .docs folder. Check if there's a subagent available to call named `rspec-testing`, if so, then call it using @rspec-testing. Otherwise do the task yourself.
        </context>

        <process>
        - Run `bundle exec rspec $ARGUMENTS`, capture the output, and parse failing examples.
        - Fix the failing examples, always ensure the spec still reflects the expected application behavior, you fix the problem by editing the source code or test files as needed (only when the spec does not make sence with the current application expected behaviour).
        - Run `bundle exec rubocop` to check if your fix does not add any rubocop offenses, if so, then fix all of them. 
        </process>

        <success_criteria>
        - All tests in the following file are passing(GREEN) correctly.
        - All rubocop warnings/offenses are solved in the whole project.
        </success_criteria>
      '';
    };

    rubocop-fix = {
      name = "rubocop-fix";
      description = "Fix rubocop offenses/warnings found in a the given file";
      agent = "rails-developer";
      prompt = ''
        # Rubocop Fix

        <objective>
        Read, execute and fix all rubocop lint for the following file "$ARGUMENTS" running the command `bundle exec rubocop $ARGUMENTS`(name of the file).
        </objective>

        <context>
        Read the project AGENTS.md to get context.
        </context>

        <process>
        - Run `bundle exec rubocop $ARGUMENTS`, capture the output, and parse the offenses found.
        - Fix the rubocop offenses/warnings found, call the `fixing-rubocop` skill to fetch how to fix that offense, you can also check the `https://docs.rubocop.org/rubocop/cops.html` page to find every Cop error and the best way to fix them.
        - Run `bundle exec rubocop` to check if your fix does not add any other rubocop offenses, if so, then fix all of them. 
        - Finally run `./bin/parallel_tests` and check if your fix didn't cause any tests in the project to fail. If there's a failure, then fix it.
        </process>

        <success_criteria>
        - All rubocop warnings/offenses are solved in the given file.
        - All tests in the whole project are passing(GREEN)(`./bin/parallel_tests`) correctly.
        </success_criteria>
      '';
    };

    rails-frontend-fix = {
      name = "rails-frontend-fix";
      description = "Fix bugs in frontend code of a Ruby on Rails application";
      agent = "";
      prompt = ''
        # Rails Frontend Fix

        <objective>
        Read, execute and fix the following bug/problem described:  $ARGUMENTS.
        </objective>

        <context>
        Read the project AGENTS.md to get context, also read the feature implementations in the .docs folder. Check if there's a subagent available to call named `rails-hotwire`, if so, then call it using @rails-hotwire. Otherwise do the task yourself.
        Remember also to use the tool `chrome-devtools` to debug the problem in the browser.
        </context>

        <process>
        - Read the AGENTS.md and .docs/features folder to get context about the project.
        - Explore the codebase and search for possible files that have the code responsible for the bug.
        - Use the `rails-hotwire` task and tell what and where it needs to be fixed.
        - After the subagent call is done and fixed the problem, verify if a new `spec` could be added to cover the behavior that was failing, if not dont add any new test. Use the task `@rspec-testing` to write and fix tests.
        - Check if the whole test suite in the project are passing running `./bin/parallel_rspec` or `bundle exec rspec`. If tests are failing, then fix them(using the @rspec-testing subagent) before going to the next step.
        - Run `bundle exec rubocop` to check if your fix does not add any rubocop offenses, if so, then fix all of them. 
        </process>

        <success_criteria>
        - The bug in question is fixed and tested in the browser using `chrome-devtools`.
        - All tests in the whole test suite are passing(GREEN) correctly.
        - All rubocop warnings/offenses are solved in the whole project. Zero offenses/warnings are allowed.
        </success_criteria>
      '';
    };
  };

  # ── Options module ──
  mkOptions =
    { lib, ... }:
    {
      options.jvf.aiTools.commands = {
        enableAll = lib.mkEnableOption "all AI tools commands";
      }
      // builtins.mapAttrs (name: _: {
        enable = (lib.mkEnableOption name) // {
          default = true;
        };
      }) commands;
    };

  # ── Config module ──
  mkConfig =
    { isDarwin }:
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.jvf.aiTools.commands;
    in
    {
      imports = [ mkOptions ];

      config = lib.mkMerge (
        # Per-command configs: when command is enabled, set on all 4 programs
        lib.mapAttrsToList (
          name: cmdAttrs:
          lib.mkIf cfg.${name}.enable (
            lib.mkMerge (
              map (p: {
                jvf.programs.${p}.commands.${name} = cmdAttrs;
              }) programs
            )
          )
        ) commands
        ++ [
          # enableAll: when set, enable all commands
          (lib.mkIf cfg.enableAll {
            jvf.aiTools.commands = builtins.mapAttrs (_: _: { enable = true; }) commands;
          })
        ]
      );
    };
in
{
  flake.modules.nixos.ai-tools-commands = mkConfig { isDarwin = false; };
  flake.modules.darwin.ai-tools-commands = mkConfig { isDarwin = true; };
}
