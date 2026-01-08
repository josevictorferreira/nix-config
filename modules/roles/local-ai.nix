{ config
, lib
, pkgs
, username
, ...
}:

let
  cfg = config.jvf.roles.localAi;
in
{
  imports = [
    ../programs/llm-proxy.nix
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
      default = username;
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
      pkgs.lmstudio
      pkgs.llama-cpp-rocm
      pkgs.upscayl
    ];
  };
}
