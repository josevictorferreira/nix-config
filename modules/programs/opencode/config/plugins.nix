# config/plugins.nix - Plugin, agent, and command configurations for OpenCode
{
  ...
}:
{
  config = {
    jvf.programs.opencode.settings.plugin = [
      "oh-my-opencode@3.8.4"
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
          model = "github-copilot/gpt-5.2-codex";
          variant = "medium";
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
          model = "openrouter/stepfun/step-3.5-flash";
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
          model = "github-copilot/gpt-5.2";
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
          model = "github-copilot/gemini-3-flash-preview";
        };
        ultrabrain = {
          model = "github-copilot/gpt-5.2";
        };
        artistry = {
          model = "github-copilot/gemini-3-pro-preview";
        };
        quick = {
          model = "zai-coding-plan/glm-5";
          variant = "fast";
        };
        most-capable = {
          model = "github-copilot/claude-opus-4.6";
        };
        writing = {
          model = "kimi-for-coding/kimi-k2-thinking";
        };
        business-logic = {
          model = "github-copilot/gemini-3-flash-preview";
        };
        general = {
          model = "kimi-for-coding/k2p5";
        };
      };
    };
  };
}
