# Issues

## T4: Conflict assertions self-reference
The wrappers translation layer sets `jvf.home.users.<u>.items` via `lib.mkMerge`.
Conflict assertions that check `config.jvf.home.users.<u>.items` see the translated
items too (NixOS module merge is lazy). Cannot distinguish wrappers-sourced vs
direct-sourced items at eval time. Deferred to T8 — will implement as integration
test that evaluates with conflicting modules.
