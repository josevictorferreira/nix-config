# Project Overview

This is a [NixOS](https://nixos.org/) configuration for a personal desktop and a macOS machine. It's designed for a development workflow with a strong focus on AI-powered tools. The configuration is managed using [Nix Flakes](https://nixos.wiki/wiki/Flakes) and is highly modular.

The core of the configuration is in the `flake.nix` file, which defines the inputs and outputs of the flake. The configuration is split into modules for different aspects of the system, such as hardware, programs, roles, and users.

A significant part of this project is the custom framework for integrating AI tools. This framework, located in `modules/common/ai-tools`, allows for the definition of AI "agents," "skills," and "commands" in a structured way. These definitions are then used to generate configuration files for the AI tools `opencode` and `claudecode`.

## Building and Running

To build and apply the configuration for NixOS, you can use the following command:

```bash
nixos-rebuild switch --flake .#nixos-desktop
```

For macOS, the command is:

```bash
darwin-rebuild switch --flake .#macos-macbook
```

## Development Conventions

The project follows the standard Nix conventions. The configuration is written in the Nix language and is organized into modules.

The AI tool framework has its own conventions. Agents, skills, and commands are defined in Nix files using helper functions from `modules/common/ai-tools/lib.nix`. These definitions are then used to generate Markdown files that are presumably consumed by the AI tools.
