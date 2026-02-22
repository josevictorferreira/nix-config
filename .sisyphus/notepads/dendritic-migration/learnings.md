
## programs-opencode migration (2026-02-22)
- Multi-file module (6 files) consolidated into single aspect successfully
- Key pattern: `mkOpencodeOptions` separate function for options, `mkConfig { isDarwin }` for platform-specific config
- Module uses `inputs.lib.aiTools.*` helpers — `inputs` available as module argument in dendritic aspects
- `buildFHSEnv` only needed for Linux (glibc compat), Darwin uses direct exec
- Sub-modules (formatters, permission, lsp, provider, plugins) all set `config.jvf.programs.opencode.settings.*` — inlined directly into `jvf.programs.opencode.settings` block in config section
- `plugins.nix` also set `ohMyOpenCodeSettings` and `commands.mystatus` — these went as sibling config blocks
- Legacy `username` param defaulted to `username` specialArg; dendritic version defaults to "josevictor" string
