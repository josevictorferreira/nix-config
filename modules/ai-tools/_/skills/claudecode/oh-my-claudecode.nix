{ lib, pkgs, isDarwin, npx, defaultBrowser, kebabToHuman, ... }:
{
  name = "oh-my-claudecode";
  programs = [ "claudecode" ];
  description = "Multi-agent orchestration layer for Claude Code. Enhances Claude Code with 'Magic Keywords' for advanced execution modes like autopilot, deep-interview, and ultrawork. Use this skill when the user wants to perform complex tasks that require high autonomy, parallel execution, or requirement clarification.";
  allowed-tools = [
    "Bash"
    "Read"
    "Write"
  ];
  prompt = ''
    # Oh My Claudecode (OMC)

    OMC transforms Claude Code into a "conductor" capable of fanning out work to specialized agents and managing complex workflows through specialized execution modes triggered by "Magic Keywords".

    ## First-time Setup
    Run the following command in your terminal to configure OMC:
    `omc setup`

    ## Magic Keywords & Execution Modes

    Use these keywords at the beginning of your response or within your plan to trigger OMC's advanced features:

    ### Autopilot Mode
    *   **Keyword:** `autopilot:`
    *   **Usage:** `autopilot: [task description]`
    *   **Effect:** Grants full autonomy. Claude will loop, self-correct, and continue until the task is verified and completed without further user intervention.

    ### Deep Interview
    *   **Keyword:** `deep-interview:` or `/deep-interview`
    *   **Usage:** `/deep-interview "I want to build a [feature]"`
    *   **Effect:** Starts a Socratic questioning session to clarify vague requirements and build a comprehensive technical spec before any code is written.

    ### Ultrawork
    *   **Keyword:** `ultrawork:`
    *   **Usage:** `ultrawork: [massive task]`
    *   **Effect:** Maximum parallel execution and context protection. Best for project-wide refactors, lint fixes, or large-scale migrations.

    ### Multi-Agent Orchestration (CCG)
    *   **Keyword:** `/ccg`
    *   **Usage:** `/ccg [task]`
    *   **Effect:** "Claude-Codex-Gemini" tri-model orchestration. Fans out work to multiple models (Codex for architecture, Gemini for UI/UX) working in parallel tmux panes.

    ## Other Commands
    *   `/omc-setup`: Re-run the configuration wizard for HUD and execution modes.
    *   `/omc-teams`: Manage and spawn specialized multi-agent teams.
    *   `omc hud`: (Terminal command) Launches the Heads-Up Display for real-time token and agent monitoring.

    ## When to use
    *   Use **Autopilot** for well-defined but multi-step tasks that you want to "set and forget".
    *   Use **Deep Interview** when the user's request is underspecified or high-level.
    *   Use **Ultrawork** for tasks that affect many files and can be parallelized.

    ## Implementation details
    OMC is installed via the `claudecode-omc` npm package. It uses `tmux` for parallel agents and `fzf` for selection.
  '';
}
