{ config
, lib
, ...
}:

let
  cfg = config.jvf.services.ollama;
in
{
  options.jvf.services.ollama = {
    enable = lib.mkEnableOption "Ollama AI service" // {
      description = ''
        Whether to enable Ollama AI service for running LLMs locally.
        Configures GPU acceleration and preloads specific models.
      '';
    };

    acceleration = lib.mkOption {
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

    loadModels = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        List of model names to preload on Ollama service start.
        These models will be downloaded and loaded into memory.
      '';
      example = [
        "dolphin-mixtral:8x7b"
        "qwen:14b"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      inherit (cfg) acceleration loadModels;
    };
  };
}
