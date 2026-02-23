# Program Module Refactoring Plan

## Summary

**Why did the previous agent consolidate to single files?**

The dendritic pattern does NOT require single-file modules. The previous agent likely over-corrected when migrating from the old flat structure. The dendritic pattern says:
- Each aspect lives in its own directory (`modules/programs/<name>/`)
- `default.nix` is the entry point
- Co-location of related files IS encouraged

The agent conflated "one directory per program" with "one file per program." These are orthogonal concerns.

**When to split?**
- File >400 lines with distinct responsibility boundaries
- Multiple domains that change independently (LSP vs formatters vs plugins)
- Configuration vs implementation logic mixed
- Multiple people might edit different parts simultaneously

**When to keep single file?**
- File <200 lines
- Cohesive single purpose
- Simple data-only configuration
- No clear semantic boundaries for splitting

---

## Refactoring Assessment by Program

### Tier 1: High Priority Splits (Complex, Clear Boundaries)

#### 1. opencode (~1100 lines)
**Current:** Monolithic with 6 distinct configuration domains mixed together

**Proposed Structure:**
```
modules/programs/opencode/
├── default.nix          # Module entry point, exports
├── options.nix          # All jvf.programs.opencode options
├── wrapper.nix          # FHS environment and wrapper script
├── config/
│   ├── formatter.nix    # 6 formatter definitions (black, prettier, etc)
│   ├── lsp.nix          # 15 LSP server configurations
│   ├── permission.nix   # 50+ bash permission patterns
│   ├── provider.nix     # 5 providers, 30+ models
│   └── plugins.nix      # Inline plugin definitions
└── scripts/
    └── entry-point.nix  # Wrapper script template
```

**Benefits:**
- LSP/formatters change when adding new languages → separate file
- Provider configs change when new models released → separate file
- Permission patterns are security-critical → isolated for review
- Each config domain ~100-200 lines, manageable chunks

---

#### 2. zsh (~1023 lines)
**Current:** Options, external plugins, inline plugins, aliases, shell init all mixed

**Proposed Structure:**
```
modules/programs/zsh/
├── default.nix              # Entry point, mkConfig
├── options.nix              # All jvf.programs.zsh options
├── external-plugins.nix     # 6 GitHub-fetched plugins
├── inline-plugins/
│   ├── ai-shell-assist.nix
│   ├── als.nix
│   ├── base64.nix
│   ├── git-ai-commit.nix
│   ├── kubernetes.nix
│   ├── nix-utils.nix
│   ├── notes.nix
│   ├── run-livebook.nix
│   └── todo.nix
├── aliases/
│   ├── base.nix
│   ├── navigation.nix
│   ├── notes.nix
│   ├── dev.nix
│   ├── personal.nix
│   ├── k8s.nix
│   └── work.nix
└── shell-init/
    ├── environment.nix
    ├── completion.nix
    ├── history.nix
    └── keybindings.nix
```

**Benefits:**
- Plugins can be added/removed without touching core
- Alias categories match different workflows → separate ownership
- Shell init sections are independent concerns
- Easier to find "where do I add a new kubectl alias?"

---

#### 3. weechat (~455 lines)
**Current:** Settings, commands, scripts, Matrix plugin, filters all together

**Proposed Structure:**
```
modules/programs/weechat/
├── default.nix          # Entry point
├── options.nix          # All options definitions
├── settings.nix         # Default weechat settings (~150 lines)
├── commands.nix         # 16 extra weechat commands
├── matrix.nix           # weechat-matrix-rs Rust package
├── scripts.nix          # 11 weechat scripts + vimode derivation
├── filters.nix          # Discord/WhatsApp/Slack filters
└── init.nix             # Init script generation with secrets
```

**Benefits:**
- Matrix plugin is heavyweight dep → isolated
- Scripts change when adding new ones → separate
- Filters are domain-specific (chat platforms)
- Init script has security implications (secrets)

---

#### 4. claudecode (~387 lines)
**Current:** FHS, wrapper scripts, router config all mixed

**Proposed Structure:**
```
modules/programs/claudecode/
├── default.nix          # Entry point
├── options.nix          # All options
├── fhs/
│   ├── claude-code.nix      # FHS for claude-code
│   └── claude-router.nix    # FHS for claude-code-router
├── wrappers/
│   ├── claude-code.nix      # Wrapper script
│   └── claude-router.nix    # Router wrapper script
├── router-config.nix    # Extensive router settings (~150 lines)
└── mcp-config.nix       # Platform-specific MCP paths
```

**Benefits:**
- Router config is complex DSL → isolated
- FHS environments are boilerplate → grouped
- Wrapper scripts change for debugging → separate

---

#### 5. tmux (~433 lines)
**Current:** Config, tmuxp picker script, 9 session configs

**Proposed Structure:**
```
modules/programs/tmux/
├── default.nix              # Entry point
├── options.nix              # All options
├── config.nix               # tmux.conf content
├── tmuxp-picker.nix         # Dynamic session picker script
└── sessions/
    ├── chat.nix
    ├── main.nix
    ├── monitoring.nix
    ├── homelab.nix
    ├── valoris.nix
    ├── valoris-backend.nix
    ├── valoris-frontend.nix
    ├── ai-workspace.nix
    └── work.nix
```

**Benefits:**
- Sessions are independent → add/remove without touching core
- Session configs are data-only → easy to edit
- tmuxp picker is script logic → isolated

---

### Tier 2: Medium Priority (Could Split, Not Urgent)

#### 6. k9s (~320 lines)
**Current:** Settings, aliases, TokyoNight skin, cluster configs

**Proposed Structure:**
```
modules/programs/k9s/
├── default.nix          # Entry point
├── options.nix          # Options
├── settings.nix         # Default settings (~65 lines)
├── aliases.nix          # Default aliases (~15 lines)
├── skins/
│   └── tokyonight.nix   # Full color theme (~110 lines)
└── clusters/
    ├── ze-homelab.nix
    └── agrosmart-eks.nix
```

**Benefits:**
- Skin is large data blob → isolated
- Cluster configs are org-specific → easy to add/remove

---

#### 7. gemini (~210 lines)
**Current:** Options, FHS wrapper, auto-update script

**Proposed Structure:**
```
modules/programs/gemini/
├── default.nix          # Entry point
├── options.nix          # Options
├── wrapper.nix          # FHS environment + npm wrapper script
└── settings.nix         # Default gemini CLI settings
```

**Benefits:**
- Wrapper is 70 lines of script → isolated
- Settings are pure data → separate

---

#### 8. droid (~176 lines)
**Current:** Options, FHS, install script

**Proposed Structure:**
```
modules/programs/droid/
├── default.nix          # Entry point
├── options.nix          # Options
├── wrapper.nix          # FHS + install script
└── settings.nix         # Default settings + custom models
```

**Benefits:**
- Install script is 40 lines → isolated
- Custom models list (~30 lines) → separate for updates

---

### Tier 3: Keep Single File (Simple, Cohesive)

#### 9. git (~273 lines)
**Assessment:** Options and config are tightly coupled. Single responsibility.
**Verdict:** KEEP SINGLE FILE. Well-organized internally.

---

#### 10. starship (~114 lines)
**Assessment:** Pure data (starshipSettings) + simple conditional config
**Verdict:** KEEP SINGLE FILE. Moving settings to separate file adds indirection without benefit.

---

#### 11. alacritty (~141 lines)
**Assessment:** Simple terminal config, single defaultConfig attrset
**Verdict:** KEEP SINGLE FILE. Could extract defaultConfig to settings.nix but minimal gain.

---

#### 12. ghostty (~110 lines)
**Assessment:** Simple terminal config, toConfigFormat helper
**Verdict:** KEEP SINGLE FILE. toConfigFormat is small utility.

---

#### 13. btop (~158 lines)
**Assessment:** Options + single large default settings attrset
**Verdict:** KEEP SINGLE FILE or extract settings.nix if settings grow beyond 100 lines.

---

#### 14. neovim (~102 lines)
**Assessment:** Minimal wrapper, mostly package lists
**Verdict:** KEEP SINGLE FILE. Could extract lsp-servers.nix, formatters.nix if lists grow.

---

#### 15. cursor (~101 lines)
**Assessment:** AI tool options + simple config generation
**Verdict:** KEEP SINGLE FILE. Similar to cursor, but smaller than claudecode.

---

#### 16. steam (~50 lines)
**Assessment:** Very simple, platform-gated NixOS module usage
**Verdict:** KEEP SINGLE FILE. No meaningful split points.

---

#### 17. easyeffects (~35 lines)
**Assessment:** Trivial package + repo clone
**Verdict:** KEEP SINGLE FILE.

---

#### 18. ck-search (~92 lines)
**Assessment:** Custom Rust package build
**Verdict:** KEEP SINGLE FILE. Single responsibility.

---

#### 19. mistral-vibe (~138 lines)
**Assessment:** Custom Python package build
**Verdict:** KEEP SINGLE FILE. Could extract python-deps.nix if deps reused elsewhere.

---

## Implementation Priority

**Phase 1 (Immediate Value):**
1. opencode - Most complex, clearest boundaries
2. zsh - Most cross-cutting concerns
3. weechat - Security-sensitive Matrix plugin isolation

**Phase 2 (Nice to Have):**
4. claudecode
5. tmux
6. k9s

**Phase 3 (If Needed):**
7. gemini
8. droid
9. Others - Only if they grow significantly

---

## Common Patterns

### Export Pattern for Split Files

All helper files should follow this pattern:

```nix
# modules/programs/opencode/config/lsp.nix
{ lib, pkgs, ... }:
{
  # Pure data/config, no module boilerplate
  lspServers = {
    # ... definitions
  };
}
```

Then import in default.nix:

```nix
{ config, lib, pkgs, ... }:
let
  lspConfig = import ./config/lsp.nix { inherit lib pkgs; };
in
{
  # Use lspConfig.lspServers
}
```

### Options Separation

All programs with >5 options should have options.nix:

```nix
# modules/programs/opencode/options.nix
{ config, lib, pkgs, ... }:
{
  options.jvf.programs.opencode = {
    # All option definitions
  };
}
```

Then import:

```nix
imports = [ ./options.nix ];
```

---

## Success Criteria

After refactoring, each module should:
- [ ] default.nix < 200 lines (excluding imports)
- [ ] Each sub-file has single, clear responsibility
- [ ] `nix flake check` passes
- [ ] No functional changes (pure reorganization)
- [ ] Easier to locate specific config sections
