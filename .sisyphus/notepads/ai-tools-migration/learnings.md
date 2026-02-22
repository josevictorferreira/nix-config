
## Phase 9 Task 1: Main ai-tools, rules, scripts migration

### Key Patterns
- Scripts that used `username` specialArg: replaced with option `username` (default "josevictor") in mkOptions
- Package options without defaults: use `lib.mkDefault` in config block to set internally-built packages
- `lib.mkMerge` needed when combining unconditional config (package defaults) with conditional configs (mkIf enable)
- Aggregator imports legacy sub-modules (mcp, agents, commands, skills) that aren't yet migrated

### Gotchas
- Can't use `//` (attrset merge) with `lib.mkIf` — must use `lib.mkMerge [ ... ]`
- Package options with `type = lib.types.package` can't have `default = null` — omit default and set via `lib.mkDefault` in config
- import-tree auto-imports all aspect files as flake-parts modules BUT doesn't auto-apply them to hosts — safe to create without conflicts
- nixf LSP warns about unused `isDarwin` and `pkgs` — these are pattern-mandated, ignore warnings

### Files Created
- `modules/aspects/ai-tools.nix` — aggregator + legacy sub-module imports
- `modules/aspects/ai-tools-rules.nix` — baseRule options + propagation to 4 AI consumers
- `modules/aspects/ai-tools-scripts.nix` — prompt-enhancer + rules-enforcer scripts

## Phase 9 Task 2: Skills migration (17 skills → 1 consolidated aspect)

### Approach
- Programmatic extraction: Python script parsed all 17 skill files, extracted `skillOptions` blocks verbatim, assembled consolidated module
- Much faster than manual copy-paste for 7000+ lines of content

### Key Patterns
- `mkSkillModule` factory replaced by inline `mkSkillConfig` helper in consolidated file
- `kebabToHuman` helper inlined (was `inputs.lib.strings.kebabToHuman`)
- PKG-dependent skills (browser-debug-tools, grafana, kubernetes-tools): `pkgs`, `npx`, `defaultBrowser` defined in top-level `let` block
- `isDarwin` used only for browser selection (Chrome on Darwin, Chromium on Linux)
- Each skill option: `"name".enable = (lib.mkEnableOption "name") // { default = true; };`

### Gotchas
- `name = skillName;` in extracted blocks needed replacement with `name = "actual-name";` (17 occurrences)
- Legacy grafana.nix has bug: uses `"\${skillName}"` (escaped dollar) creating literal `${skillName}` option name instead of `grafana`
- Our consolidated module fixes this by using `name = "grafana";` directly
- `inputs` not available in dendritic aspects — all `inputs.lib.aiTools.*` factory calls replaced with inline logic

### Files Created
- `modules/aspects/ai-tools-skills.nix` — 7235 lines, all 17 skills consolidated with dendritic export pattern

### Verification
- `nix flake check --show-trace`: PASS
- `nix eval .#nixosConfigurations.nixos-desktop.options.jvf.aiTools.skills.auditing-security.enable.default`: `true`
- All 17 skill names present in options attrset
