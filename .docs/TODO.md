# TODO

- [ ] Add a proxy for llms, maybe cliproxy.
- [ ] Add a new template for the python/django/postgres flake.nix application.
- [ ] Update the current template for ruby on rails application flake.nix.
- [ ] Add a skill for every `mcp` tool that we're using.
- [ ] Add all the z-ai mcp tools available.
- [ ] Link each skill to use to each agent.
- [ ] Fix gemini-cli feat-implement command that's failing to be read.
- [ ] Create a new ai-tool command that actually parses the @.docs/rules and see what are the rules that will be useful for the current implementation.
- [ ] Create a new ai-tool command that actually improves the user prompt with the question `What would be your prompt if you wanted to get to the following result`.
- [ ] Create a new ai-tool that parses rubocop offenses(copy pasted or command run), and then automatically consult the rubocop docs page explaining why the offense happened and how to solve it, add it to the start of the prompt.
- [ ] Fix `weechat` program, when entering its not connecting to slack on nixos.
- [x] Improve the current `session-retrospective` command

# PLAN

## Features
- [ ] Research how to "sandbox" projects that use dependency tools like Postgres, and how to easily trigger multiple of them in parallel for Agentic use.

## Improvements
- [ ] Improve nix-darwin to start managing more stuff in the system, stuff like homebrew and mac configurations.

## Refactories
- [ ] Add a theme module where we can configure all different programs theming in a single place.


# DONE

Created: 2026-01-06

