{ config
, lib
, inputs
, ...
}:
let
  commandName = "feat-plan";
  cfg = config.jvf.aiTools.commands."${commandName}";
  commandDef = inputs.lib.aiTools.mkCommandModule {
    name = commandName;
    description = "Generate an implementation plan acting as the Plan Agent";
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
      - \`src/path/to/file.ts\`: ...

      ### 2.2 Data Models & State
      *Types, interfaces, and state management strategy.*
      \`\`\`typescript
      interface Example { ... }
      \`\`\`

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
in
{
  options.jvf.aiTools.commands."${commandName}" = commandDef.options;
  config = lib.mkIf cfg.enable commandDef.config;
}
