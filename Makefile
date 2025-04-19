.DEFAULT_GOAL := help

secrets: ## Edit the secrets file
	sops secrets/secrets.enc.yaml

rebuild: ## Rebuild NixOS configuration.
	@if [ "$(shell uname)" = "Darwin" ]; then \
		darwin-rebuild switch --flake .#macos-macbook --impure; \
	else \
		sudo nixos-rebuild switch --flake .#nixos-desktop --impure; \
	fi

clean: ## Clean up the Nix store.
	nix-collect-garbage -d

subtree_push: ## Push all commits to their repositories
	git subtree push --prefix=config/nvim git@github.com:josevictorferreira/.nvim.git main 2>/dev/null || true
	git subtree push --prefix=config/tmux git@github.com:josevictorferreira/.tmux.git main 2>/dev/null || true
	git subtree push --prefix=config/zsh git@github.com:josevictorferreira/.zsh.git main 2>/dev/null || true
	git subtree push --prefix=config/ghostty git@github.com:josevictorferreira/.ghostty.git main 2>/dev/null || true
	git subtree push --prefix=config/hypr git@github.com:josevictorferreira/.hypr.git main 2>/dev/null || true
	git subtree push --prefix=config/kitty git@github.com:josevictorferreira/.kitty.git main 2>/dev/null || true

help: ## Show this help.
	@printf "Usage: make [target]\n\nTARGETS:\n"; grep -F "##" $(MAKEFILE_LIST) | grep -Fv "grep -F" | grep -Fv "printf " | sed -e 's/\\$$//' | sed -e 's/##//' | column -t -s ":" | sed -e 's/^/    /'; printf "\n"
