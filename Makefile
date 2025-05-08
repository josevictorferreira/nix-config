GREEN=\033[0;32m
CYAN=\033[0;36m
BOLD=\033[1m
RESET=\033[0m

.DEFAULT_GOAL := help

.PHONY: help secrets rebuild clean push_configs subtree_sync up_keys

GIT_BASE_ADDRESS := git@github.com:josevictorferreira
SUBTREES := nvim tmux zsh ghostty hypr kitty waybar

SUBTRESS := \
	nvim=$(GIT_BASE_ADDRESS)/.nvim.git@main \
	tmux=$(GIT_BASE_ADDRESS)/.tmux.git@main \
	zsh=$(GIT_BASE_ADDRESS)/.zsh.git@main \
	ghostty=$(GIT_BASE_ADDRESS)/.ghostty.git@main \
	hypr=$(GIT_BASE_ADDRESS)/.hypr.git@main \
	kitty=$(GIT_BASE_ADDRESS)/.kitty.git@main \
	waybar=$(GIT_BASE_ADDRESS)/.waybar.git@main

subtree_clean_check: ## Check if the git working tree is clean.
	@if ! git diff --quiet || ! git diff --cached --quiet; then \
		echo "❌ Git working tree is dirty. Please commit or stash your changes."; \
		exit 1; \
	else \
		echo "✅ Git working tree is clean.\n"; \
	fi

subtree_sync: subtree_clean_check ## Add or sync subtrees to the config directory.
	@for entry in $(SUBTRESS); do \
		name=$$(echo $$entry | cut -d= -f1); \
		repo=$$(echo $$entry | cut -d= -f2 | cut -d@ -f1,2); \
		branch=$$(echo $$entry | cut -d@ -f3); \
		echo -e "$(GREEN)--- 🔁 SYNC $$name ---$(RESET)"; \
		if [ ! -d "config/$$name" ]; then \
			echo -e "\uf149 $(CYAN)Adding $(BOLD)$$repo$(RESET) -> config/$$name (branch: $$branch)$(RESET)"; \
			git subtree add --prefix=config/$$name $$repo $$branch --squash; \
		else \
			echo -e "$(CYAN)\uf149 Pulling$(RESET) from $$repo (branch: $$branch)$(RESET)"; \
			git subtree pull --prefix=config/$$name $$repo $$branch || true; \
			echo -e "$(CYAN)\uf149 Pushing$(RESET) config/$$name to $$repo (branch: $$branch)$(RESET)"; \
			git subtree push --prefix=config/$$name $$repo $$branch || true; \
		fi; \
		echo -e "✅ $(GREEN)DONE.$(RESET)\n"; \
	done

up_keys: ## Update keys for secrets files
	sops updatekeys secrets/secrets.enc.yaml

secrets: ## Edit the secrets file
	sops secrets/secrets.enc.yaml

update: ## Update flake
	sudo nix flake update

rebuild: ## Rebuild NixOS configuration.
	@if [ "$(shell uname)" = "Darwin" ]; then \
		darwin-rebuild switch --flake .#macos-macbook --impure; \
	else \
		sudo nixos-rebuild switch --flake .#nixos-desktop --impure; \
	fi

clean: ## Clean up the Nix store.
	nix-collect-garbage -d

help: ## Show this help.
	@printf "Usage: make [target]\n\nTARGETS:\n"; grep -F "##" $(MAKEFILE_LIST) | grep -Fv "grep -F" | grep -Fv "printf " | sed -e 's/\\$$//' | sed -e 's/##//' | column -t -s ":" | sed -e 's/^/    /'; printf "\n"
