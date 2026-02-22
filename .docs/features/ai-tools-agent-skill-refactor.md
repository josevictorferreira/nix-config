# Feature Plan: AI Tools Agent & Skill Refactoring

**Status:** Proposed
**Feature:** `ai-tools-agent-skill-refactor`
**Date:** 2024-12-12

## 1. Objective

Refactor the existing `ai-tools` module to better distinguish between **Agents** (personas with autonomous decision-making) and **Skills** (specialized knowledge bases or reusable procedures). This will improve the composability of the AI system, allowing General agents to "equip" specific knowledge domains on demand rather than requiring dedicated agents for every topic.

## 2. Rationale

Analysis of the current codebase reveals:
1.  **Expert Overload:** Many "Expert" agents (e.g., `Ethical Scraper`, `Rails Event Store Specialist`) are actually just defined by their knowledge prompts. They don't require a unique persona.
2.  **Procedural Commands:** Several commands define complex workflows (e.g., `changelog`, audits) that are effectively "Skills" that could be reused by agents for self-verification or complex task execution.
3.  **Composability:** Converting knowledge-heavy agents to skills allows a single agent to combine multiple domains (e.g., a "DevOps Agent" using both `container-engineering` and `nix-module-mastery` skills).

## 3. Scope of Changes

### 3.1. Agents to Skills Conversion

The following "Agents" will be converted into **Skills**. These files will be moved from `modules/common/ai-tools/agents/` to `modules/common/ai-tools/skills/` and refactored to match the Skill schema.

| Current Agent | New Skill Name | Description |
| :--- | :--- | :--- |
| `rails-event-store-specialist` | `rails-event-store-guide` | Library implementation guide and best practices. |
| `ethical-scraper` | `web-scraping-mastery` | Techniques for safe and effective web scraping (proxies, headers). |
| `container-expert` | `container-engineering` | Reference for Dockerfiles, Podman, and Compose patterns. |
| `flake-expert` | `nix-flake-mastery` | Deep knowledge of Nix flakes. |
| `module-expert` | `nix-module-mastery` | NixOS module system patterns and structure. |
| `nix-expert` | `nix-lang-mastery` | General Nix language patterns. |
| `documenter` | `documentation-writing` | Templates and guides for documentation. |
| `security-auditor` | `security-auditing` | Checklists and methodologies for security reviews. |

### 3.2. Commands Refactoring

The following commands will be evaluated for conversion or promotion.

| Command | Action | New Type | Reasoning |
| :--- | :--- | :--- | :--- |
| `changelog` | **Promote** | **Agent** (`Release Manager`) | Complex 4-phase systematic workflow. |
| `review` | **Deprecate** | **Alias** | Redundant with `code-reviewer` agent. |
| `nix-refactor` | **Convert** | **Skill** (`nix-refactoring`) | Systematic refactoring procedure. |
| `dependency-audit` | **Convert** | **Skill** (`dependency-analysis`) | Reusable audit procedure. |
| `style-audit` | **Convert** | **Skill** (`code-style-check`) | Reusable functional check. |

## 4. Implementation Plan

### Phase 1: Migration Setup
1.  Verify `modules/common/ai-tools/skills/` infrastructure supports the new volume of skills.
2.  Ensure `modules/common/ai-tools/lib.nix` (or equivalent) has helpers for defining these knowledge-heavy skills easily.

### Phase 2: Agent Migration
For each agent in the list above:
1.  Extract the prompt content (knowledge base).
2.  Create a new `.nix` file in `skills/`.
3.  Update the prompt to be "instructional" rather than "persona-based" (e.g., "Here is how to X..." instead of "You are an expert in X...").
4.  Remove the original agent file.
5.  Update `modules/common/ai-tools/agents/default.nix` and `skills/default.nix`.

### Phase 3: Command Refactoring
1.  Refactor `changelog` command into a dedicated `release-manager` agent (or update the prompt to be agent-style).
2.  Convert `nix-refactor`, `dependency-audit`, and `style-audit` into skills.
3.  Update the command definitions to optionally *use* these new skills if invoked via CLI, or allow agents to use them directly.

### Phase 4: Verification
1.  Run `make check` to validate Nix structure.
2.  Verify `opencode` and `claudecode` consumers correctly output the new skills configuration.
3.  Test loading the new skills in an agent session.

## 5. Success Metrics
- Reduction in total defined Agents (less clutter in Agent selector).
- Increase in available Skills.
- Successful use of `container-engineering` skill by a generic `General` agent.
