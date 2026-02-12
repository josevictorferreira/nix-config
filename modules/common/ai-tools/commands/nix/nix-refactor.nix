{ config, lib, inputs, ... }:

let
  cfg = config.jvf.aiTools.commands."nix-refactor";
  commandOptions = {
    name = "Nix Refactor";
    description = "Systematic code refactoring with comprehensive safety checks and validation";
    tools = [ ];
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
  commandDef = inputs.lib.aiTools.mkCommandModule {
    name = "nix-refactor";
    inherit commandOptions;
  };
in
{
  options.jvf.aiTools.commands."nix-refactor" = commandDef.options;
  config = lib.mkIf cfg.enable commandDef.config;
}
