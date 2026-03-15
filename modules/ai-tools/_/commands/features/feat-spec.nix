{ ... }:
{
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
}
