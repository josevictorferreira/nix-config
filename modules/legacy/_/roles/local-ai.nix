{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.jvf.roles.localAi;

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
  imports = [
  ];

  options.jvf.roles.localAi = {
    enable = lib.mkEnableOption "Local AI development tools" // {
      description = ''
        Whether to enable local AI development tools.
        Configures:
        - Ollama for running LLMs locally with GPU acceleration
        - LMStudio for local AI model management (Linux only)
        - llama-cpp for local inference
      '';
    };

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

  config = lib.mkIf cfg.enable {
    users.users."${cfg.username}".packages = [
    ]
    ++ lib.optionals (!pkgs.stdenv.isDarwin) [
      lmstudio-rocm
      pkgs.llama-cpp-rocm
    ];
  };
}
