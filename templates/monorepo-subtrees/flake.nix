{
  description = "Monorepo template with subtree helpers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Defaults can be overridden via env vars when using the shell
        backendRepo = ''${SUBTREE_BACKEND_REPO:-git@github.com:your-org/your-backend.git};
        frontendRepo = ''${SUBTREE_FRONTEND_REPO:-git@github.com:your-org/your-frontend.git};

        subtreeFunctions = pkgs.writeScriptBin "subtree-helpers" ''
          #!${pkgs.bash}/bin/bash

          backendRepo="${backendRepo}"
        frontendRepo="${frontendRepo}"

        RED="\033[0;31m"
        GREEN="\033[0;32m"
        YELLOW="\033[1;33m"
        BLUE="\033[0;34m"
        NC="\033[0m"

        print_info()    { echo -e "''${BLUE}[INFO]''${NC} $1";
        }
        print_success() { echo -e "''${GREEN}[SUCCESS]''${NC} $1"; }
        print_warning() { echo -e "''${YELLOW}[WARNING]''${NC} $1"; }
        print_error()   { echo -e "''${RED}[ERROR]''${NC} $1"; }

        update-backend() {
        print_info "Updating backend subtree from ${backendRepo}..."
        git subtree pull --prefix = backend "${backendRepo}" main - -squash
          if [ $? -eq 0 ];
        then
        print_success "Backend subtree updated successfully!"
        else
        print_error "Failed to update backend subtree"
        return 1
        fi
        }

        update-frontend() {
        print_info "Updating frontend subtree from ${frontendRepo}..."
        git subtree pull --prefix = frontend "${frontendRepo}" main - -squash
          if [ $? -eq 0 ];
        then
        print_success "Frontend subtree updated successfully!"
        else
        print_error "Failed to update frontend subtree"
        return 1
        fi
        }

        update-all() {
        print_info "Updating all subtrees..."
        update-backend
        update-frontend
        print_success "All subtrees updated!"
        }

        push-backend() {
        print_info "Pushing backend changes to ${backendRepo}..."
        git subtree push --prefix = backend "${backendRepo}" main
          if [ $? -eq 0 ];
        then
        print_success "Backend changes pushed successfully!"
        else
        print_error "Failed to push backend changes"
        return 1
        fi
        }

        push-frontend() {
        print_info "Pushing frontend changes to ${frontendRepo}..."
        git subtree push --prefix = frontend "${frontendRepo}" main
          if [ $? -eq 0 ];
        then
        print_success "Frontend changes pushed successfully!"
        else
        print_error "Failed to push frontend changes"
        return 1
        fi
        }

        push-all() {
        print_info "Pushing changes to all subtrees..."
        push-backend
        push-frontend
        print_success "All changes pushed!"
        }

        subtree-status() {
        print_info "Checking subtree status..."
        echo -e "\n''${BLUE}Recent subtree-related commits:''${NC}"
        git log --oneline --grep = "subtree" - n 5
          echo - e "\n''${BLUE}Current subtree references:''${NC}"
          git
          ls-tree
          HEAD
          backend / frontend /
        echo - e "\n''${BLUE}Subtree remotes:''${NC}"
          echo "Backend: ${backendRepo}"
          echo "Frontend: ${frontendRepo}"
          }

          subtree-help() {
          echo -e "''${BLUE}Monorepo Subtree Management''${NC}"
          echo -e "''${BLUE}============================''${NC}"
          echo "Available commands:"
          echo "  update-backend    - Update backend subtree from remote"
          echo "  update-frontend   - Update frontend subtree from remote"
          echo "  update-all        - Update both subtrees"
          echo "  push-backend      - Push backend changes to remote"
          echo "  push-frontend     - Push frontend changes to remote"
          echo "  push-all          - Push changes to both remotes"
          echo "  subtree-status    - Check current subtree status"
          echo "  subtree-help      - Show this help message"
          echo ""
          echo "Env overrides:"
          echo "  SUBTREE_BACKEND_REPO   (default: ${backendRepo})"
          echo "  SUBTREE_FRONTEND_REPO  (default: ${frontendRepo})"
          }

          export -f update-backend update-frontend update-all
          export -f push-backend push-frontend push-all
          export -f subtree-status subtree-help
          export -f print_info print_success print_warning print_error
          '';
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            git
            bash
            subtreeFunctions
          ];

          shellHook = ''
          echo -e "\033[0;34m[Monorepo]\033[0m Entering development shell..."
          echo -e "\033[0;34m[Monorepo]\033[0m Available subtree commands:"
          echo "  update-all      - Update both subtrees"
          echo "  push-all        - Push changes to both remotes"
          echo "  subtree-status  - Check subtree status"
          echo "  subtree-help    - Show all available commands"
          echo ""
          echo -e "\033[0;32mTip:\033[0m Run 'subtree-help' for detailed command information"
          echo ""

          source ${subtreeFunctions}/bin/subtree-helpers

          alias up='update-all'
          alias push='push-all'
          alias status='subtree-status'
          alias shelp='subtree-help'

          export SUBTREE_BACKEND_REPO="${backendRepo}"
          export SUBTREE_FRONTEND_REPO="${frontendRepo}"

          export -f update-backend update-frontend update-all
          export -f push-backend push-frontend push-all
          export -f subtree-status subtree-help
          export -f print_info print_success print_warning print_error
          '';
        };

        apps = {
          update-all = flake-utils.lib.mkApp {
            drv = pkgs.writeScriptBin "update-all-subtrees" ''
          #!${pkgs.bash}/bin/bash
          source ${subtreeFunctions}/bin/subtree-helpers
          update-all
          '';
            name = "update-all";
            exePath = "/bin/update-all-subtrees";
          };

          push-all = flake-utils.lib.mkApp {
            drv = pkgs.writeScriptBin "push-all-subtrees" ''
          #!${pkgs.bash}/bin/bash
          source ${subtreeFunctions}/bin/subtree-helpers
          push-all
          '';
            name = "push-all";
            exePath = "/bin/push-all-subtrees";
          };

          subtree-status = flake-utils.lib.mkApp {
            drv = pkgs.writeScriptBin "subtree-status" ''
          #!${pkgs.bash}/bin/bash
          source ${subtreeFunctions}/bin/subtree-helpers
          subtree-status
          ''            ;
            name = "subtree-status";
            exePath = "/bin/subtree-status";
          };
        };

        packages.default = subtreeFunctions;
      });
}












