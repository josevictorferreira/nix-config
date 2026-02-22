
## Phase 1 Learnings (2026-02-22)

### File Counts
- Task header claimed 21 programs but only 20 existed (btop thru zsh). Total was still 87 files since other categories compensated.
- Actual breakdown: programs=20, system=16, services=3, roles=12, hardware=4, desktop=17, ai-tools=7, remaining=8 → 87

### git mv
- All 87 `git mv` operations produced clean `R` (rename) status — perfect history preservation
- No content changes detected by git, confirming pure moves
- `git mv` handles creating the destination automatically if parent dirs exist, but dirs must be pre-created with `mkdir -p`

### Directory Structure
- `modules/core/` already had `options.nix` — `jvf.nix` coexists fine
- `modules/aspects/` now only has `assets/` subdir (for Phase 2)
- Empty program directories created by `mkdir -p` are fine since each gets a `default.nix`

### Verification Commands
- `find modules/ ... | wc -l` must account for `-not -path` exclusions when counting
- `git status --short | grep '^R'` cleanly confirms rename-only operations
