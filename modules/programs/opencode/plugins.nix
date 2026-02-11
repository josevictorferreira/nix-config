{
  lib,
  ...
}:

{
  config.jvf.programs.opencode.settings.plugin = [
    "opencode-antigravity-auth@1.4.6"
    "oh-my-opencode@3.5.2:"
    "@tarquinen/opencode-dcp@2.0.2"
  ];

  config.jvf.programs.opencode.ohMyOpenCodeSettings = {
    disabled_commands = [ ];
    agents = {
      sisyphus = {
        model = "kimi-for-coding/k2p5";
        temperature = 1.0;
        permission = {
          skill = {
            "*" = {
              "*" = "allow";
            };
          };
        };
      };
      hephaestus = {
        model = "github-copilot/gpt-5.2-codex";
        variant = "medium";
      };
      librarian = {
        model = "minimax/MiniMax-M2.1";
        temperature = 0.3;
        permission = {
          skill = {
            "*" = {
              "*" = "deny";
              "research-tools" = "allow";
            };
          };
        };
      };
      explore = {
        model = "github-copilot/grok-code-fast-1";
        permission = {
          skill = {
            "*" = {
              "*" = "deny";
              "research-tools" = "allow";
            };
          };
        };
      };
      atlas = {
        model = "kimi-for-coding/k2p5";
        temperature = 1.0;
        permission = {
          skill = {
            "*" = {
              "*" = "deny";
              "research-tools" = "allow";
            };
          };
        };
      };
      prometheus = {
        model = "github-copilot/gpt-5.2";
        permission = {
          skill = {
            "*" = {
              "*" = "deny";
              "research-tools" = "allow";
            };
          };
        };
      };
      metis = {
        model = "github-copilot/gemini-3-pro-preview";
        permission = {
          skill = {
            "*" = {
              "*" = "deny";
              "research-tools" = "allow";
            };
          };
        };
      };
      momus = {
        model = "kimi-for-coding/kimi-k2-thinking";
        temperature = 1.0;
        permission = {
          skill = {
            "*" = {
              "*" = "deny";
              "research-tools" = "allow";
            };
          };
        };
      };
      oracle = {
        model = "github-copilot/gpt-5.2";
      };
      frontend-ui-ux-engineer = {
        model = "minimax/MiniMax-M2.1";
        permission = {
          skill = {
            "*" = {
              "*" = "deny";
              "vision-tools" = "allow";
              "browser-debug-tools" = "allow";
            };
          };
        };
      };
      document-writer = {
        model = "kimi-for-coding/kimi-k2-thinking";
        temperature = 1.0;
      };
      multimodal-looker = {
        model = "github-copilot/gemini-3-flash-preview";
        permission = {
          skill = {
            "*" = {
              "*" = "deny";
              "vision-tools" = "allow";
            };
          };
        };
      };
    };
    experimental = {
      auto_resume = true;
      dcp_for_compaction = true;
      dynamic_context_pruning = {
        enabled = true;
      };
    };
    ralph_loop = {
      enabled = true;
      default_max_iterations = 1000;
    };
    disabled_hooks = [
      "rules-injector"
    ];
    claude_code = {
      mcp = false;
      commands = false;
      skills = false;
      agents = false;
      hooks = true;
    };
    google_auth = false;
    categories = {
      visual-engineering = {
        model = "github-copilot/gemini-3-pro-preview";
        temperature = 0.7;
      };
      ultrabrain = {
        model = "github-copilot/gpt-5.2";
        temperature = 0.1;
      };
      artistry = {
        model = "github-copilot/gemini-3-pro-preview";
        temperature = 0.9;
      };
      quick = {
        model = "zai-coding-plan/glm-4.7";
        variant = "fast";
        temperature = 0.3;
      };
      most-capable = {
        model = "github-copilot/claude-opus-4.5";
        temperature = 0.1;
      };
      writing = {
        model = "kimi-for-coding/kimi-k2-thinking";
        temperature = 0.5;
      };
      business-logic = {
        model = "github-copilot/gemini-3-flash-preview";
        temperature = 0.1;
      };
      general = {
        model = "kimi-for-coding/k2p5";
        temperature = 0.3;
      };
    };
  };

  config.jvf.programs.opencode.commands.mystatus = lib.mkDefault {
    name = "mystatus";
    agent = "general";
    description = "Query quota usage for all AI accounts";
    prompt = "Use the `mystatus` tool to query quota usage. Return the result as-is without modification.";
  };
}
