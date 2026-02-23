# Aspect: roles-local-ai
# Bundles local AI development tools.
# Enables ollama, LMStudio, llama-cpp with GPU acceleration support.
{ ... }:
let
  mkOptions =
    { config, lib, ... }:
    {
      options.jvf.roles.local-ai = {
        enable = lib.mkEnableOption "local AI development tools";

        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for installing packages to.";
        };

        ollamaAcceleration = lib.mkOption {
          type = lib.types.enum [
            "rocm"
            "cuda"
            "none"
          ];
          default = "rocm";
          description = ''
            GPU acceleration to use for Ollama.
            Options: "rocm" (AMD), "cuda" (NVIDIA), or "none" (CPU only).
          '';
        };

        ollamaLoadModels = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            List of model names to preload on Ollama service start.
            These models will be downloaded and loaded into memory.
          '';
          example = [
            "dolphin-mixtral:8x7b"
            "qwen:14b"
            "llama3:8b"
            "deepseek-coder:6.7b"
          ];
        };
      };
    };

  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.roles.local-ai;

      # ROCm libraries needed for llama.cpp backend
      rocmLibs = with pkgs.rocmPackages; [
        clr
        clr.icd
        rocm-runtime
        hipblas
        rocblas
        rocsolver
      ];

      # Additional system libraries needed by the ROCm stack
      systemLibs = with pkgs; [
        stdenv.cc.cc.lib # libstdc++
        numactl # libnuma
        elfutils.out # libelf (need .out for the library)
        libdrm # libdrm
      ];

      # All extra libraries for the FHS environment
      allExtraLibs = rocmLibs ++ systemLibs;

      # Create a wrapped lmstudio that sets LD_LIBRARY_PATH for child processes
      # This includes both the bundled ROCm vendor libs and system libs
      lmstudio-rocm = pkgs.symlinkJoin {
        name = "lmstudio-rocm";
        paths = [ pkgs.lmstudio ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          # Wrap lm-studio with environment for ROCm
          # Set LD_LIBRARY_PATH to include:
          # 1. LM Studio's bundled vendor libs (expanded at runtime via $HOME)
          # 2. System ROCm and support libraries from nix store
          # 3. FHS paths for libraries inside the sandbox
          wrapProgram $out/bin/lm-studio \
            --run 'export LD_LIBRARY_PATH="$HOME/.lmstudio/extensions/backends/vendor/linux-llama-rocm-vendor-v3:${lib.makeLibraryPath allExtraLibs}:/usr/lib64:/usr/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"'

          # Wrap lms CLI as well
          wrapProgram $out/bin/lms \
            --run 'export LD_LIBRARY_PATH="$HOME/.lmstudio/extensions/backends/vendor/linux-llama-rocm-vendor-v3:${lib.makeLibraryPath allExtraLibs}:/usr/lib64:/usr/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"'
        '';
      };
    in
    {
      imports = [ mkOptions ];

      config = lib.mkIf cfg.enable {
        users.users."${cfg.username}".packages =
          [ ]
          ++ lib.optionals (!isDarwin) [
            lmstudio-rocm
            pkgs.llama-cpp-rocm
          ];
      };
    };
in
{
  flake.modules.nixos.roles-local-ai = mkConfig { isDarwin = false; };
  flake.modules.darwin.roles-local-ai = mkConfig { isDarwin = true; };
}
