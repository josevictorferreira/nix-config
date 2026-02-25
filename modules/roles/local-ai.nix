# Aspect: roles-local-ai
# Bundles local AI development tools.
# Enables ollama, LMStudio, llama-cpp with GPU acceleration support.
_:
let

  mkOptions =
    { config, lib, ... }:
    {
      options.jvf.roles.local-ai = {
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

  nixosModule =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.roles.local-ai;

      # ROCm libraries needed for llama.cpp backend
      rocmLibs = [
        pkgs.rocmPackages.clr
        pkgs.rocmPackages.clr.icd
        pkgs.rocmPackages.rocm-runtime
        pkgs.rocmPackages.hipblas
        pkgs.rocmPackages.rocblas
        pkgs.rocmPackages.rocsolver
      ];

      # Additional system libraries needed by the ROCm stack
      systemLibs = [
        pkgs.stdenv.cc.cc.lib # libstdc++
        pkgs.numactl # libnuma
        pkgs.elfutils.out # libelf (need .out for the library)
        pkgs.libdrm # libdrm
      ];

      # All extra libraries for the FHS environment
      allExtraLibs = rocmLibs ++ systemLibs;

      # Create a wrapped lmstudio that sets LD_LIBRARY_PATH for child processes
      lmstudio-rocm = pkgs.symlinkJoin {
        name = "lmstudio-rocm";
        paths = [ pkgs.lmstudio ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/lm-studio \
            --run 'export LD_LIBRARY_PATH="$HOME/.lmstudio/extensions/backends/vendor/linux-llama-rocm-vendor-v3:${lib.makeLibraryPath allExtraLibs}:/usr/lib64:/usr/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"'

          wrapProgram $out/bin/lms \
            --run 'export LD_LIBRARY_PATH="$HOME/.lmstudio/extensions/backends/vendor/linux-llama-rocm-vendor-v3:${lib.makeLibraryPath allExtraLibs}:/usr/lib64:/usr/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"'
        '';
      };
    in
    {
      imports = [ mkOptions ];

      config = {
        users.users."${cfg.username}".packages = [
          lmstudio-rocm
          pkgs.llama-cpp-rocm
        ];
      };
    };

  darwinModule =
    { ... }:
    {
      imports = [ mkOptions ];

      config = { };
    };
in
{
  flake.modules.nixos.roles-local-ai = nixosModule;
  flake.modules.darwin.roles-local-ai = darwinModule;
}
