# commandcode-proxy

OpenAI Chat Completions ⇄ Command Code translation proxy. Runs as a user-level
systemd / launchd service on `127.0.0.1:18080` (configurable via
`jvf.programs.commandcode-proxy.{port,bind}`). Lets opencode, pi, and any
other OpenAI-compatible client reach Command Code through
`@ai-sdk/openai-compatible` without each one shipping a custom CC adapter.

## Why this exists

Command Code (`https://api.commandcode.ai/alpha/generate`) is neither
OpenAI- nor Anthropic-compatible. It speaks a custom envelope around the
Vercel AI SDK stream protocol, no `@ai-sdk/*` provider package matches it,
and the existing community client (`pi-commandcode-provider` on npm) only
adapts CC for pi — not for opencode or other clients we use here.

The proxy translates one shape into the other so we get a single integration
point and the existing opencode-to-pi provider translator in
`modules/programs/pi/_/provider.nix` auto-mirrors CC into pi for free.

## File layout

```
modules/programs/commandcode-proxy/
├── AGENTS.md            # this file
├── default.nix          # dendritic aspect: options + systemd/launchd service
└── _/                   # excluded from import-tree (leading underscore)
    ├── package.nix      # buildGoModule derivation
    └── src/
        ├── go.mod
        └── main.go      # the proxy itself, single file, stdlib only
```

## CC API contract (the parts that drove this implementation)

### Endpoint and auth

Only one endpoint exists: `POST https://api.commandcode.ai/alpha/generate`.
**No `/models` endpoint** — model lists are hardcoded in clients (see
`ccModelIDs` in `_/src/main.go`).

Auth header: `Authorization: Bearer <apiKey>`, where the key lives in
`~/.commandcode/auth.json` (`.apiKey`, prefixed `user_`, non-expiring).
The proxy also honors `COMMANDCODE_API_KEY` env override.

Required CLI-fingerprint headers (server gates on these but accepts
multiple versions — `0.24.1` and `0.25.7` both work as of writing):

```
x-command-code-version: 0.25.7
x-cli-environment:      cli
x-project-slug:         commandcode-proxy
x-taste-learning:       false
x-co-flag:              false
x-session-id:           <fresh UUID v4 per request>
```

### Request envelope

```jsonc
{
  "config": {
    "workingDir": "...", "date": "YYYY-MM-DD", "environment": "...",
    "structure":     [],          // MUST be array (null → 400)
    "isGitRepo":     false,
    "currentBranch": "", "mainBranch": "", "gitStatus": "",
    "recentCommits": []           // MUST be array (null → 400)
  },
  "memory": "", "taste": "", "skills": null,
  "permissionMode": "standard",
  "params": {
    "model":      "...",
    "messages":   [...],          // see role/content rules below
    "tools":      [...],          // {type:"function", name, description, input_schema}
    "system":     "...",
    "max_tokens": 32000,
    "stream":     true
  }
}
```

### Message role / content rules (the asymmetric Vercel-vs-Anthropic quirk)

`params.messages[].role` accepts **only** `"user"` and `"assistant"`. The
Vercel-style `"tool"` role is rejected by the validator with HTTP 400.

Content shapes accepted per role:

- **`user`** — string OR array of: `text` / `image` / `document` /
  `search_result` / `tool_result` / `web_search_tool_result` /
  `web_fetch_tool_result`. Tool results live here.
- **`assistant`** — array of: `text` / `thinking` / `redacted_thinking` /
  `reasoning` / `tool_use` (Anthropic) **or** `tool-call` (Vercel) /
  `server_tool_use`.

**Asymmetric quirk**: tool **calls** accept *both* `tool_use` (Anthropic,
`{id, name, input}`) and `tool-call` (Vercel, `{toolCallId, toolName,
input}`). Tool **results** accept **only** `tool_result` (Anthropic,
underscored, with `tool_use_id` and string-or-array `content`). The
hyphenated Vercel `tool-result` form is rejected.

The proxy emits Vercel `tool-call` on the assistant side (matches what
opencode/pi sends through `@ai-sdk/openai-compatible`) and Anthropic
`tool_result` on the user side (forced because CC rejects anything else).
See the `case "tool":` branch in `_/src/main.go`.

`pi-commandcode-provider` on npm emits the Vercel form for *both*, which
means it's silently broken against current CC for multi-turn tool use.
We chose not to depend on it.

### Stream response

Newline-separated JSON (no `data:` prefix from server). Event sequence:

```
start → start-step → text-start → text-delta* → text-end →
finish-step → finish
```

Plus `tool-call`, `reasoning-delta`, `reasoning-end`, `error` interleaved as
the model emits them. The proxy re-emits each as an OpenAI `data: <json>\n\n`
chunk for the downstream client, dropping `reasoning-*` events (OpenAI Chat
Completions has no `reasoning` field).

### Error envelope from CC

```jsonc
{
  "success": false,
  "error": {
    "code":    "BAD_REQUEST" | "FORBIDDEN" | "UNAUTHORIZED" | ...,
    "status":  400 | 401 | 403 | ...,
    "message": "<human-readable reason>",
    "docs":    "https://commandcode.ai/docs/reference/errors/..."
  }
}
```

The proxy re-wraps these into OpenAI's `{"error":{"message",type,code}}`
JSON envelope (`Content-Type: application/json`) so AI-SDK clients
surface CC's actual `message` text instead of "Invalid error response
format / Gateway request failed".

### Other CC behaviors worth knowing

- CC injects its own ~38KB coding-agent system prompt server-side
  regardless of what you send; client `system` content appends to (does
  not replace) CC's prompt. The injected prompt is cached on CC's side, so
  reported `inputTokenDetails.cacheReadTokens` covers ~8K tokens of
  amortized cost per request.
- API keys don't expire. `~/.commandcode/auth.json` is preserved across
  rebuilds by the sibling `programs/command-code/default.nix` module
  (`preserve = ["auth.json", ...]`).

## Testing and operations

```sh
# Build the binary (uses the flake's pinned pkgs)
nix build --impure --no-link --print-out-paths --expr \
  "(builtins.getFlake (toString ./.)).nixosConfigurations.nixos-desktop.pkgs.callPackage ./modules/programs/commandcode-proxy/_/package.nix {}"

# Run locally (no service)
$out/bin/commandcode-proxy -port 18080 -bind 127.0.0.1

# Tail service logs (after nixos-rebuild switch)
journalctl --user -u commandcode-proxy -f

# Health + models
curl -s http://127.0.0.1:18080/healthz
curl -s http://127.0.0.1:18080/v1/models | jq '.data | length'   # → 18

# Round-trip smoke test
curl -s -X POST http://127.0.0.1:18080/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"claude-haiku-4-5-20251001","stream":false,"max_tokens":20,
       "messages":[{"role":"user","content":"reply ok"}]}'
```

## Client-side gotcha (not a proxy bug, but bites users)

The AI SDK's `ModelMessage` schema validates messages **client-side before
the request leaves**. If a model emits a `tool-call` for a tool the
client doesn't have registered (e.g. pi receiving a call for opencode's
`explore` sub-agent), AI SDK throws `"Invalid prompt: The messages do
not match the ModelMessage[] schema"` — proxy logs won't show this
because the request never arrived.

Workaround: use opencode for agent-heavy prompts (it ships `explore` and
friends). Pi handles `read`/`bash`/`edit`/`write` flows fine.

## Version bumps

Bump `ccVersion` in `_/src/main.go` if CC ever rejects requests as too old.
We've verified `0.24.1` and `0.25.7` both work; pinning to the latest
known-good is the cheap default.
