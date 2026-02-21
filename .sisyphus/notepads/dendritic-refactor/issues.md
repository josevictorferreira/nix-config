
## [Task 9] flake.modules merge conflict blocks import-tree on modules/aspects/
- **Problem**: Tasks 6-8 created aspects that each define `flake.modules.{nixos,darwin}.*` as plain attrsets. When import-tree imports all of them, flake-parts can't merge the definitions since `flake.modules` isn't a declared mergeable option.
- **Impact**: `nix flake check` fails, `nix fmt` fails, no formatter output
- **Workaround**: Import aspects explicitly instead of via import-tree
- **Fix needed**: Declare `flake.modules` as a proper flake-parts option with merge semantics, or refactor aspects to use `flakeModules` option
