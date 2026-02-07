# TODO

- [ ] Add a matrix integration to weechat
- [ ] Add a proxy for llms, maybe cliproxy.
- [ ] Add a new template for the python/django/postgres flake.nix application.
- [ ] Update the current template for ruby on rails application flake.nix.
- [ ] Create a new ai-tool command that actually improves the user prompt with the question `What would be your prompt if you wanted to get to the following result`.
- [ ] Create a new ai-tool that parses rubocop offenses(copy pasted or command run), and then automatically consult the rubocop docs page explaining why the offense happened and how to solve it, add it to the start of the prompt.
- [ ] Fix `weechat` program, when entering its not connecting to slack on nixos.
- [x] Improve the current `session-retrospective` command
- [x] Add a skill for every `mcp` tool that we're using. ✅ 2026-02-07 11:37
- [x] Add all the z-ai mcp tools available. ✅ 2026-02-07 11:37
- [x] Link each skill to use to each agent. ✅ 2026-02-07 11:37
- [x] Create a new ai-tool command that actually parses the @.docs/rules and see what are the rules that will be useful for the current implementation. ✅ 2026-02-07 11:37

# PLAN

## Features
- [ ] Research how to "sandbox" projects that use dependency tools like Postgres, and how to easily trigger multiple of them in parallel for Agentic use.

## Improvements
- [ ] Improve nix-darwin to start managing more stuff in the system, stuff like homebrew and mac configurations.

## Refactories
- [ ] Add a theme module where we can configure all different programs theming in a single place.


# DONE

Created: 2026-01-06

