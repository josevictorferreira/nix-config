GREEN=\033[0;32m
CYAN=\033[0;36m
BOLD=\033[1m
RESET=\033[0m

.DEFAULT_GOAL := help

.PHONY: help secrets rebuild clean push_configs up_keys lint format

lint: ## Lint the nix files.
	@echo "Running nix formatter check..."
	@nix fmt -- --check . || (echo "❌ Some files need formatting. Run 'make format' to fix." && exit 1)
	@echo "✅ All files are properly formatted."

format: ## Format the nix files.
	@echo "Formatting nix files..."
	@nix fmt .
	@echo "✅ Formatting complete."

up_keys: ## Update keys for secrets files
	sops updatekeys secrets/secrets.enc.yaml

secrets: ## Edit the secrets file
	sops secrets/secrets.enc.yaml

check: lint ## Check if the flake is valid.
	@bash -c "nix flake check --show-trace"

update: ## Update flake
	nix flake update

boot: ## Rebuild boot NixOS configuration.
	sudo nixos-rebuild boot --upgrade --flake .#zeh-pc

rebuild: ## Rebuild NixOS configuration.
	@if [ "$(shell uname)" = "Darwin" ]; then \
		sudo -H darwin-rebuild switch --flake .#zeh-mac --show-trace; \
	else \
		sudo -H nixos-rebuild switch --flake .#zeh-pc --show-trace && \
      (if [ -n "$${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then hyprctl reload >/dev/null 2>&1 || echo "ℹ️  Skipping hyprctl reload (Hyprland not reachable from this shell)"; else echo "ℹ️  Skipping hyprctl reload (Hyprland not reachable from this shell)"; fi) && \
      (notify-send "󱄅 NixOS Rebuild" "Rebuild finished with success\!  " 2>/dev/null || echo "✅ Rebuild completed"); \
	fi

rollback: ## Rollback NixOS configuration.
	sudo nixos-rebuild switch --rollback --flake .#zeh-pc

rebuildd: ## Rebuild only Nix Darwin config
	nix build .#darwinConfigurations.zeh-mac.system

clean: ## Clean up the Nix store.
	nix-collect-garbage -d

help: ## Show this help.
	@printf "Usage: make [target]\n\nTARGETS:\n"; grep -F "##" $(MAKEFILE_LIST) | grep -Fv "grep -F" | grep -Fv "printf " | sed -e 's/\\$$//' | sed -e 's/##//' | column -t -s ":" | sed -e 's/^/    /'; printf "\n"
