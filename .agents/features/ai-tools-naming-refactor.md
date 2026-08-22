# AI Tools Naming and Organization Refactor

## Overview

This document outlines the proposed changes to improve naming conventions, organization, and tool assignments for the AI tools in `modules/common/ai-tools/`.

## Proposed Changes Table

| New Name | New Path | Old Name | Old Path | Proposed Tools | Not Needed? | Reason |
|----------|----------|----------|----------|----------------|-------------|--------|
| **skill-writer** | `agents/general/skill-writer.nix` | build-skill | `agents/build-skill.nix` | Read, Glob, Grep, Write, Edit | No | Creates new agent skills - needs read existing patterns, write new files |
| **code-reviewer** | `agents/general/code-reviewer.nix` | code-review | `agents/code-review.nix` | Read, Glob, Grep, Bash, BashOutput | No | Reviews code, runs tests - needs read-only + test execution |
| **documentation-writer** | `agents/general/documentation-writer.nix` | document | `agents/document.nix` | Read, Glob, Grep, Write, Edit, WebFetch | No | Creates docs - needs read code, write files, fetch external docs |
| **shadcn-ui-architect** | `agents/frontend/shadcn-ui-architect.nix` | shadcn-ui-plan | `agents/shadcn-ui-plan.nix` | Read, Glob, Grep, Write, Edit, Bash | No | Plans UI with shadcn - needs component generation |
| **ui-ux-architect** | `agents/frontend/ui-ux-architect.nix` | ui-ux-plan | `agents/ui-ux-plan.nix` | Read, Glob, Grep, WebFetch, WebSearch | No | Designs UX - needs research capabilities |
| **auditing-security** | `skills/auditing-security.nix` | auditing-security | `skills/auditing-security.nix` | Read, Grep, Glob | No | Security audits - read-only for safety |
| **creating-nix-modules** | `skills/creating-nix-modules.nix` | creating-nix-modules | `skills/creating-nix-modules.nix` | Read, Grep, Glob, Write | No | Creates modules - needs to read examples, write new code |
| **developing-containers** | `skills/developing-containers.nix` | developing-containers | `skills/developing-containers.nix` | Read, Grep, Glob, Bash, BashOutput | No | Container dev - needs to run docker/podman commands |
| **managing-flakes** | `skills/managing-flakes.nix` | managing-flakes | `skills/managing-flakes.nix` | Read, Grep, Glob, Bash, BashOutput | No | Flake management - needs nix command execution |
| **managing-rails-events** | `skills/managing-rails-events.nix` | managing-rails-events | `skills/managing-rails-events.nix` | Read, Write, Edit, Bash | No | Rails event store - needs code generation, test running |
| **pythonic-scraping-websites** | `skills/pythonic-scraping-websites.nix` | pythonic-scraping-websites | `skills/pythonic-scraping-websites.nix` | Read, Write, Bash, WebFetch | No | Python scraping - needs to write scripts, fetch web data |
| **ruby-stealth-scraping** | `skills/ruby-stealth-scraping.nix` | ruby-stealth-scraping | `skills/ruby-stealth-scraping.nix` | Read, Write, Bash, WebFetch | No | Ruby stealth scraping - needs browser automation |
| **writing-nix-code** | `skills/writing-nix-code.nix` | writing-nix-code | `skills/writing-nix-code.nix` | Read, Grep, Glob, Write, Edit | No | Nix code writing - needs to read patterns, write code |
| **add-and-format** | `commands/git/add-and-format.nix` | add-and-format | `commands/add-and-format.nix` | Bash, BashOutput | No | Git operations + formatting - needs command execution |
| **commit-changes** | `commands/git/commit-changes.nix` | commit-changes | `commands/commit-changes.nix` | Bash, BashOutput, Read, Grep | No | Git commits - needs git commands, can read for context |
| **deep-check** | `commands/general/deep-check.nix` | deep-check | `commands/deep-check.nix` | Bash, BashOutput, Read, Grep | No | Deep validation - needs multiple command execution |
| **dependency-audit** | `commands/general/dependency-audit.nix` | dependency-audit | `commands/dependency-audit.nix` | Bash, BashOutput, Read, Grep | No | Audits dependencies - needs to run audit tools |
| **flake-update** | `commands/nix/flake-update.nix` | flake-update | `commands/flake-update.nix` | Bash, BashOutput | No | Updates flakes - needs nix command execution |
| **implement-feature** | `commands/implementation/implement-feature.nix` | implement-feature | `commands/implement-feature.nix` | Read, Write, Edit, Bash, BashOutput, TodoWrite, TodoRead | No | Implements features - needs full code modification |
| **implement-fix** | `commands/implementation/implement-fix.nix` | implement-fix | `commands/implement-fix.nix` | Read, Write, Edit, Bash, BashOutput, TodoWrite, TodoRead | No | Implements fixes - needs full code modification |
| **implement-refactoring** | `commands/implementation/implement-refactoring.nix` | implement-refactoring | `commands/implement-refactoring.nix` | Read, Write, Edit, Bash, BashOutput, TodoWrite, TodoRead | No | Implements refactoring - needs full code modification |
| **implement-tests** | `commands/implementation/implement-tests.nix` | implement-tests | `commands/implement-tests.nix` | Read, Write, Edit, Bash, BashOutput | No | Implements tests - needs test file creation, test running |
| **nix-check** | `commands/nix/nix-check.nix` | nix-check | `commands/nix-check.nix` | Bash, BashOutput, Read, Grep | No | Nix validation - needs nix commands, can read for context |
| **nix-module-lint** | `commands/nix/nix-module-lint.nix` | nix-module-lint | `commands/nix-module-lint.nix` | Bash, BashOutput, Read, Grep | No | Lints nix modules - needs linting tools, read code |
| **nix-module-scaffold** | `commands/nix/nix-module-scaffold.nix` | nix-module-scaffold | `commands/nix-module-scaffold.nix` | Read, Write, Edit, Bash | No | Scaffolds modules - needs template reading, file writing |
| **nix-option-migrate** | `commands/nix/nix-option-migrate.nix` | nix-option-migrate | `commands/nix-option-migrate.nix` | Read, Write, Edit, Grep, Glob | No | Migrates options - needs find/replace across files |
| **nix-refactor** | `commands/nix/nix-refactor.nix` | nix-refactor | `commands/nix-refactor.nix` | Read, Write, Edit, Grep, Glob, Bash, BashOutput | No | Refactors nix - needs comprehensive code modification |
| **nix-template-new** | `commands/nix/nix-template-new.nix` | nix-template-new | `commands/nix-template-new.nix` | Read, Write, Edit, Glob | No | Creates from templates - needs template reading, writing |
| **style-audit** | `commands/general/style-audit.nix` | style-audit | `commands/style-audit.nix` | Bash, BashOutput, Read, Grep | No | Audits code style - needs style checkers, read code |
| **commit-msg** | `commands/git/commit-msg.nix` | commit-msg | `commands/commit-msg.nix` | Bash, BashOutput | **YES** | Redundant with `commit-changes` - both handle commits |
| **implement-change** | `commands/implementation/implement-change.nix` | implement-change | `commands/implement-change.nix` | Read, Write, Edit, Bash, BashOutput | **YES** | Too vague - redundant with specific implement-* commands |
| **do** | `commands/general/do.nix` | do | `commands/do.nix` | Bash, BashOutput | **YES** | Too vague - just passes through to Bash |
| **ask** | `commands/general/ask.nix` | ask | `commands/ask.nix` | AskUserQuestion | **YES** | Too vague - just asks user questions |

## Summary Statistics

- **Total Items:** 37 (6 agents + 8 skills + 23 commands)
- **Proposed to Keep:** 33
- **Proposed to Remove:** 4 (commit-msg, implement-change, do, ask)
- **Agents to Rename:** 5
- **Commands to Reorganize:** 20 into subdirectories

## Key Recommendations

1. **Remove 4 redundant commands** that are too vague or duplicate functionality
2. **Rename 5 agents** to follow role-based naming conventions
3. **Reorganize into subdirectories** by category (frontend, general, nix, git, implementation)
4. **Assign minimal tool sets** - start restrictive, expand as needed
5. **All agents should be Secondary** (workers) except potentially `code-reviewer` which could be Primary for orchestrating reviews

## Directory Structure After Refactor

```
modules/common/ai-tools/
├── agents/
│   ├── frontend/
│   │   ├── shadcn-ui-architect.nix
│   │   └── ui-ux-architect.nix
│   └── general/
│       ├── code-reviewer.nix
│       ├── documentation-writer.nix
│       └── skill-writer.nix
├── commands/
│   ├── git/
│   │   ├── add-and-format.nix
│   │   └── commit-changes.nix
│   ├── general/
│   │   ├── deep-check.nix
│   │   ├── dependency-audit.nix
│   │   └── style-audit.nix
│   ├── implementation/
│   │   ├── implement-feature.nix
│   │   ├── implement-fix.nix
│   │   ├── implement-refactoring.nix
│   │   └── implement-tests.nix
│   └── nix/
│       ├── flake-update.nix
│       ├── nix-check.nix
│       ├── nix-module-lint.nix
│       ├── nix-module-scaffold.nix
│       ├── nix-option-migrate.nix
│       ├── nix-refactor.nix
│       └── nix-template-new.nix
└── skills/
    ├── auditing-security.nix
    ├── creating-nix-modules.nix
    ├── developing-containers.nix
    ├── managing-flakes.nix
    ├── managing-rails-events.nix
    ├── pythonic-scraping-websites.nix
    ├── ruby-stealth-scraping.nix
    └── writing-nix-code.nix
```

## Implementation Priority

### High Priority:
1. Remove 4 redundant commands
2. Rename 5 agents to follow conventions
3. Move manage-release to commands (already exists as changelog)

### Medium Priority:
1. Reorganize into subdirectories
2. Update default.nix files to reflect new structure
3. Test all tools work with new paths

### Low Priority:
1. Enhance tool restrictions based on actual usage
2. Add cross-references between related tools
3. Create comprehensive documentation