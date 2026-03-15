{ ... }:
{
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
}
