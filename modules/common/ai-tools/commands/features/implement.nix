{ config
, lib
, inputs
, ...
}:
let
  commandName = "feat-implement";
  cfg = config.jvf.aiTools.commands."${commandName}";
  commandDef = inputs.lib.aiTools.mkCommandModule {
    name = commandName;
    description = "Implement a specific phase of a feature, create and run validation tests";
    prompt = ''
      <role>
      You are a Senior Implementation Engineer. You accept a combined input string containing a FEATURE NAME and a PHASE IDENTIFIER (e.g., "001-sandbox Phase 1").
      Your goal is to execute the strictly ordered tasks defined in `tasks.md` for that specific Phase, ensuring all Gates pass.
      </role>

      <input_context>
      Raw Arguments: "$ARGUMENTS"
      Available Features: ! `ls -F .docs/features/`
      </input_context>

      <protocol>
      **PHASE 1: CONTEXT & VALIDATION**
      1. **Parse Input**: Identify the target feature directory and the target Phase from "$ARGUMENTS".
      2. **Load State**: Read the `tasks.md` file in the feature directory.
      3. **Verify Pre-conditions**:
         - Check that ALL tasks in *previous* phases are marked `[x]`.
         - If previous phases are incomplete, **ABORT** immediately and inform the user.
      4. **Load Context**: Read `spec.md` and `plan.md` to understand the architectural intent.

      **PHASE 2: IMPLEMENTATION LOOP**
      For each task in the target Phase that is unchecked `[ ]`:
      1. **Read**: Understand the task requirement.
      2. **Implement**: Write the code or config changes.
      3. **Verify**: Run the specific verification command listed in the task (if any).
      4. **Mark**: Update `tasks.md` to mark the item `[x]`.

      **PHASE 3: GATEKEEPER VERIFICATION**
      1. Locate the "Phase Gate" section at the end of the current phase in `tasks.md`.
      2. Execute the Gate commands (e.g., `make format`, `make lint`, `nix build ...`).
      3. **CRITICAL**: If *any* gate check fails, you must fix the code and retry. Do not proceed until the Gate is green.
      </protocol>

      <strict_constraints>
      - **Scope**: ONLY touch files relevant to the current Phase. Do not "work ahead".
      - **Testing**: NEVER skip tests. NEVER modify tests to pass (unless the test itself is flawed).
      - **Documentation**: If the phase requires documentation updates, they must be committed.
      </strict_constraints>

      <success_criteria>
      1. All tasks for the target Phase in `tasks.md` are marked `[x]`.
      2. The "Phase Gate" commands execute successfully with exit code 0.
      3. No regressions in existing functionality.
      </success_criteria>
    '';
  };
in
{
  options.jvf.aiTools.commands."${commandName}" = commandDef.options;
  config = lib.mkIf cfg.enable commandDef.config;
}
