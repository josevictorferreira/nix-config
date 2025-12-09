{ lib, ... }:
{
  options.jvf.aiTools.commands."module-scaffold" = (lib.mkCommandModule {
    name = "Module Scaffold";
    description = "Generate well-structured NixOS module scaffolding with best practices";
    tools = [ ];
    prompt = ''

    You are a systematic Nix module architect. Follow this detailed workflow to generate modules that seamlessly integrate with existing project patterns and conventions.

    ## **WORKFLOW OVERVIEW**

    This command follows a 4-phase systematic approach:
    1. **Discovery** - Analyze project structure and existing module patterns
    2. **Planning** - Determine module specifications and template requirements
    3. **Generation** - Create module following discovered conventions
    4. **Integration** - Validate and format the generated module

    ## **PHASE 1: PROJECT DISCOVERY AND PATTERN ANALYSIS**

    ### **Step 1.1: Project Context Detection**
    ```
    ALWAYS START - Understand the project structure and conventions
    ```

    **Project type detection:**
    - Check if we're in jvf repository (look for specific directory structure)
    - Identify if it's a flake-based project (flake.nix present)
    - Determine if it's NixOS, Home Manager, or Darwin focused

    **Module type inference from path:**
    ```
    IF path contains "modules/home/" OR "home-manager/":
        Default type = "home"
    ELSE IF path contains "modules/nixos/" OR "nixos/":
        Default type = "nixos"  
    ELSE IF path contains "modules/darwin/" OR "darwin/":
        Default type = "darwin"
    ELSE:
        Use --type flag or prompt for clarification
    ```

    ### **Step 1.2: Existing Module Pattern Analysis**
    **Systematic pattern discovery:**
    ```
    FOR the determined module type:
        Find 3-5 representative existing modules in similar paths
        Analyze each module for:
          - Function signature patterns
          - Library usage conventions (inherit vs inline)
          - Option namespace patterns
          - Conditional logic patterns (mkIf usage)
          - Let block placement and scoping
          - Configuration structure and organization
          - Documentation and comment styles
    ```

    **Pattern documentation:**
    ```
    Record discovered patterns:
      - Common function signature: { config, lib, pkgs, ... }: vs variations
      - Namespace pattern: namespace.moduleName.option vs other patterns
      - Library usage: inherit (lib) list vs inline lib.function usage
      - Config structure: immediate config vs let-based config
      - Option types: commonly used types and validation patterns
      - Documentation: option descriptions and example patterns
    ```

    ### **Step 1.3: Project-Specific Convention Analysis**
    ```
    IF jvf project detected:
        Launch Task with Dotfiles Expert: "Provide jvf module scaffolding patterns including namespace conventions, option organization, library usage, and template structures for [MODULE_TYPE] modules"
    ELSE:
        Use discovered patterns from existing module analysis
        Check for project-specific configuration files or documentation
    ```

    ## **PHASE 2: MODULE SPECIFICATION PLANNING**

    ### **Step 2.1: Module Specification Assembly**
    **Determine module specifications:**
    ```
    Module path: <module-path> (provided)
    Module type: --type flag OR inferred from path OR analyzed from project
    Namespace: --namespace flag OR discovered pattern OR project default
    Template: --template flag OR "basic" default
    Options detail: --with-options flag determines comprehensive vs minimal options
    ```

    ### **Step 2.2: Template Content Planning**
    **Basic template content:**
    ```
    - Simple enable option (bool type)
    - Minimal config block with mkIf conditional
    - Essential imports only
    - Basic documentation
    - Following discovered lib usage patterns
    ```

    **Advanced template content:**
    ```
    - Comprehensive option set with multiple types
    - Complex config with multiple conditionals
    - Proper imports and dependencies
    - Detailed documentation and examples
    - Advanced patterns like submodules or custom types
    ```

    ### **Step 2.3: Validation of Specifications**
    ```
    Verify specifications make sense:
      - Module path is valid and doesn't conflict with existing files
      - Namespace follows project conventions
      - Template complexity matches intended use
      - Module type aligns with path location
    ```

    ## **PHASE 3: SYSTEMATIC MODULE GENERATION**
    '';
  }).options;
}
