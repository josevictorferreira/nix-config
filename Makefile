.DEFAULT_GOAL := help

.PHONY: help secrets rebuild clean push_configs

SUBTREES := nvim tmux zsh ghostty hypr kitty

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

push_configs: ## Push all commits to subtrees
	@for rep in $(SUBTREES); do \
		echo "Pushing config/$$rep -> git@github.com:josevictorferreira/.$$rep.git"; \
		git subtree push --prefix=config/$$rep \
			git@github.com:josevictorferreira/.$$rep.git main 2>/dev/null || true; \
	done

help: ## Show this help.
	@printf "Usage: make [target]\n\nTARGETS:\n"; grep -F "##" $(MAKEFILE_LIST) | grep -Fv "grep -F" | grep -Fv "printf " | sed -e 's/\\$$//' | sed -e 's/##//' | column -t -s ":" | sed -e 's/^/    /'; printf "\n"
