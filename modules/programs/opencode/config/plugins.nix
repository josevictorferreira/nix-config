# config/plugins.nix - Plugin, agent, and command configurations for OpenCode
_: {
  config = {
    jvf.programs.opencode.settings.plugin = [
      "@tarquinen/opencode-dcp@3.0.3"
      "oh-my-opencode@3.11.2"
      "mcpflow-router@0.3.2"
    ];

    jvf.programs.opencode.ohMyOpenCodeSettings = {
      disabled_commands = [ ];
      agents = {
        sisyphus = {
          model = "kimi-for-coding/k2p5";
          permission = {
            skill = {
              "*" = {
                "*" = "allow";
              };
            };
          };
        };
        hephaestus = {
          model = "zai-coding-plan/glm-5";
          variant = "thinker";
        };
        librarian = {
          model = "minimax/MiniMax-M2.5";
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
          model = "openrouter/openai/gpt-oss-120b";
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
          model = "zai-coding-plan/glm-5";
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
          model = "kimi-for-coding/k2p5";
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
        oracle = {
          model = "zai-coding-plan/glm-5";
          variant = "thinker";
          temperature = 1.0;
        };
        frontend-ui-ux-engineer = {
          model = "minimax/MiniMax-M2.5";
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
          model = "bailian-coding-plan/qwen3.5-plus";
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
          model = "bailian-coding-plan/qwen3.5-plus";
        };
        ultrabrain = {
          model = "kimi-for-coding/k2p5";
        };
        artistry = {
          model = "minimax/MiniMax-M2.5";
        };
        quick = {
          model = "openrouter/openai/gpt-oss-120b";
        };
        most-capable = {
          model = "zai-coding-plan/glm-5";
          variant = "thinker";
          temperature = 1.0;
        };
        writing = {
          model = "kimi-for-coding/kimi-k2-thinking";
        };
        business-logic = {
          model = "bailian-coding-plan/qwen3.5-plus";
        };
        general = {
          model = "kimi-for-coding/k2p5";
        };
      };
    };
  };
}
