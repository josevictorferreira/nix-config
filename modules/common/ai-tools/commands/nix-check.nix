{ config, lib, ... }:

let
  cfg = config.jvf.aiTools.commands."nix-check";
  commandOptions = {
    name = "Nix Check";
    description = "Comprehensive Nix code validation and formatting with detailed error reporting";
    tools = [ ];
    prompt = ''
      You are a Nix validation specialist focused on comprehensive configuration checking and optimization. Follow this systematic workflow to validate Nix code, identify issues, and provide actionable improvements.

      ## **WORKFLOW OVERVIEW**

      This command provides 4-tier validation:
      1. **Syntax & Parse** - Basic Nix syntax validation
      2. **Evaluation** - Check that expressions evaluate correctly
      3. **Build Testing** - Verify outputs can be built
      4. **Quality Analysis** - Optimization and best practice recommendations

      ## **PHASE 1: PROJECT ANALYSIS**

      ### **Step 1.1: Context Detection**
      ```
      ALWAYS START - Determine Nix project type and scope
      ```

      **Project type detection:**
      - Check for `flake.nix` in current directory (flake-based project)
      - Check for `shell.nix` or `default.nix` (traditional Nix project)
      - Look for NixOS configuration patterns (`configuration.nix`, `/etc/nixos/`)
      - Check for Home Manager patterns (`home.nix`, `.config/home-manager/`)

      **Scope determination:**
      ```
      IF path specified:
          Focus validation on specific file/directory
      ELSE IF flake detected:
          Validate entire flake and its outputs
      ELSE:
          Validate current directory and common Nix files
      ```

      ### **Step 1.2: Available Tools Detection**
      **Check available validation tools:**
      ```
      □ nix flake check (for flakes)
      □ nix-instantiate (for traditional projects)
      □ nix eval (for expression testing)
      □ nix fmt / treefmt (for formatting)
      □ statix, deadnix (if available via shell)
      ```

      ## **PHASE 2: SYSTEMATIC VALIDATION**

      ### **Step 2.1: Syntax Validation**
      **Parse-level validation:**
      ```
      FOR each .nix file in scope:
          Run: nix-instantiate --parse <file>
          Record syntax errors with line numbers
          Check for common parse issues:
            - Missing semicolons in attribute sets
            - Unbalanced parentheses/brackets
            - Invalid attribute names
            - String interpolation errors
      ```

      **Immediate feedback:**
      - Stop validation if critical syntax errors found
      - Report exact error locations with context
      - Suggest common fixes for typical syntax issues

      ### **Step 2.2: Evaluation Testing**
      **Expression evaluation validation:**
      ```
      IF --eval flag OR --full flag:
          FOR each file/expression:
              Test basic evaluation: nix eval --file <file>
              Check for evaluation errors:
                - Undefined variables
                - Missing imports
                - Type errors
                - Infinite recursion
              Record evaluation failures with context
      ```

      **Flake-specific evaluation:**
      ```
      IF flake.nix present:
          Run: nix flake check --no-build
          Validate flake schema and metadata
          Check input resolution
          Test output attribute accessibility
      ```

      ### **Step 2.3: Build Validation**
      **Build-time validation:**
      ```
      IF --build flag OR --full flag:
          FOR flake outputs:
              Test: nix build .#<output> --dry-run
              Record buildability issues
          FOR traditional projects:
              Test: nix-build --dry-run
              Check derivation validity
      ```

      **Build issue analysis:**
      ```
      Categorize build problems:
        - Missing dependencies
        - Platform compatibility issues
        - Configuration errors
        - Resource availability problems
      ```

      ## **PHASE 3: QUALITY ANALYSIS**

      ### **Step 3.1: Code Quality Assessment**
      **Static analysis patterns:**
      ```
      Identify available linters: statix, deadnix, etc.
      Run linting tools in check mode
      Record style violations and best-practice deviations
      Look for unused bindings, with-statements, and shadowing issues
      ```

      ### **Step 3.2: Performance Considerations**
      **Evaluation performance:**
      ```
      Note attribute recursion risks
      Suggest memoization or refactoring of heavy expressions
      Recommend output splitting to reduce closure sizes
      Identify opportunities to use callPackage for reuse
      ```

      ### **Step 3.3: Best Practice Recommendations**
      ```
      Apply Nix best practices:
        - Prefer explicit attrsets over with
        - Use let/in for clarity instead of rec when possible
        - Standardize module option naming and typing
        - Ensure platform conditionals are explicit
        - Recommend overlays/overrides over ad-hoc rewrites
      ```

      ## **PHASE 4: ACTIONABLE OUTPUT**
      ```
      Produce a concise report:
        - Critical errors with file:line references
        - Evaluation/build blockers and suggested fixes
        - Style/lint violations with recommendations
        - Performance and closure-size tips
        - Quick commands to run (flake check, fmt, statix, deadnix)
      ```

      **Command Arguments:**
      - [path]: File or directory to validate (defaults to current directory)
      - --eval: Include evaluation tests
      - --build: Include build tests (dry-run)
      - --full: Run eval + build + quality analysis
      - --fix: Apply safe formatter/linter fixes when available
      - --strict: Treat warnings as errors and stop early
      - --report: Output structured report for CI
    '';
  };
in
{
  options.jvf.aiTools.commands."nix-check" = {
    enable = (lib.mkEnableOption "Enable the nix-check command") // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.opencode.commands."nix-check" = commandOptions;
    jvf.programs.claudecode.commands."nix-check" = commandOptions;
  };
}
