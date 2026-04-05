# config/plugins.nix - Plugin, agent, and command configurations for OpenCode
_: {
  config = {
    jvf.programs.opencode.settings.plugin = [
      "@tarquinen/opencode-dcp@3.1.8"
      "oh-my-opencode@3.15.2"
    ];

    jvf.programs.opencode.ohMyOpenCodeSettings =
      let
        kimi = "kimi-for-coding/k2p5";
        glm = "zai-coding-plan/glm-5.1";
        opus = "github-copilot/claude-opus-4.6";
        sonnet = "github-copilot/claude-sonnet-4.6";
        geminiPro = "github-copilot/gemini-3.1-pro-preview";
        geminiFlash = "github-copilot/gemini-3-flash-preview";
        minimax = "minimax/MiniMax-M2.7";
        qwen = "alibaba-coding-plan/qwen3.5-plus";
        gpt = "openai/gpt-5.4";
        models = {
          quick = {
            default = "openrouter/inception/mercury-2";
            cheap = minimax;
            expensive = "github-copilot/grok-code-fast-1";
            alternative = "openrouter/openai/gpt-oss-120b";
          };
          coder = {
            default = minimax;
            cheap = kimi;
            expensive = sonnet;
            alternative = glm;
          };
          intelligent = {
            default = gpt;
            cheap = glm;
            expensive = opus;
            alternative = geminiPro;
          };
          looker = {
            default = geminiFlash;
            cheap = qwen;
            expensive = geminiPro;
            alternative = kimi;
          };
          writer = {
            default = kimi;
            cheap = "kimi-for-coding/k2-thinking";
            expensive = geminiFlash;
            alternative = qwen;
          };
        };
      in
      {
        disabled_commands = [ ];
        agents = {
          sisyphus = {
            model = models.coder.default;
            model_fallback = true;
            fallback_models = [
              models.coder.alternative
              models.coder.cheap
              models.coder.expensive
            ];
            tasks = {
              enabled = true;
            };
            permission = {
              skill = {
                "*" = {
                  "*" = "allow";
                };
              };
            };
          };
          hephaestus = {
            model = models.coder.expensive;
            model_fallback = true;
            fallback_models = [
              models.coder.default
              models.coder.alternative
              models.coder.cheap
            ];
          };
          librarian = {
            model = models.quick.alternative;
            model_fallback = true;
            fallback_models = [
              models.quick.default
              models.quick.cheap
              models.quick.expensive
            ];
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
            model = models.quick.default;
            model_fallback = true;
            fallback_models = [
              models.quick.alternative
              models.quick.cheap
              models.quick.expensive
            ];
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
            model = models.coder.alternative;
            temperature = 1.0;
            model_fallback = true;
            fallback_models = [
              models.coder.default
              models.coder.expensive
              models.coder.cheap
            ];
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
            model = models.intelligent.default;
            model_fallback = true;
            fallback_models = [
              models.intelligent.expensive
              models.intelligent.alternative
              models.intelligent.cheap
            ];
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
            model = models.intelligent.expensive;
            model_fallback = true;
            fallback_models = [
              models.intelligent.alternative
              models.intelligent.default
              models.intelligent.cheap
            ];
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
            model = models.intelligent.alternative;
            temperature = 1.0;
            model_fallback = true;
            fallback_models = [
              models.intelligent.default
              models.intelligent.expensive
              models.intelligent.cheap
            ];
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
            model = models.intelligent.default;
            temperature = 1.0;
            model_fallback = true;
            fallback_models = [
              models.intelligent.expensive
              models.intelligent.alternative
              models.intelligent.cheap
            ];
          };
          document-writer = {
            model = models.writer.default;
            model_fallback = true;
            fallback_models = [
              models.writer.expensive
              models.writer.alternative
              models.writer.cheap
            ];
            temperature = 1.0;
          };
          multimodal-looker = {
            model = models.looker.default;
            model_fallback = true;
            fallback_models = [
              models.looker.expensive
              models.looker.alternative
              models.looker.cheap
            ];
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
        categories = {
          visual-engineering = {
            model = models.looker.default;
            fallback_models = [
              models.looker.expensive
              models.looker.alternative
              models.looker.cheap
            ];
          };
          ultrabrain = {
            model = models.intelligent.expensive;
            fallback_models = [
              models.intelligent.default
              models.intelligent.alternative
              models.intelligent.cheap
            ];
          };
          artistry = {
            model = models.looker.expensive;
            fallback_models = [
              models.looker.default
              models.looker.alternative
              models.looker.cheap
            ];
          };
          deep = {
            model = models.intelligent.cheap;
            fallback_models = [
              models.intelligent.expensive
              models.intelligent.alternative
              models.intelligent.default
            ];
          };
          quick = {
            model = models.quick.default;
            fallback_models = [
              models.quick.alternative
              models.quick.cheap
              models.quick.expensive
            ];
          };
          most-capable = {
            model = models.intelligent.default;
            temperature = 1.0;
            fallback_models = [
              models.intelligent.expensive
              models.intelligent.alternative
              models.intelligent.cheap
            ];
          };
          writing = {
            model = models.writer.default;
            temperature = 1.0;
            fallback_models = [
              models.writer.expensive
              models.writer.alternative
              models.writer.cheap
            ];
          };
          business-logic = {
            model = models.intelligent.alternative;
            fallback_models = [
              models.intelligent.default
              models.intelligent.expensive
              models.intelligent.cheap
            ];
          };
          general = {
            model = models.coder.default;
            fallback_models = [
              models.coder.alternative
              models.coder.expensive
              models.coder.cheap
            ];
          };
          unspecified-low = {
            model = models.coder.cheap;
            fallback_models = [
              models.coder.default
              models.coder.alternative
              models.coder.expensive
            ];
          };
          unspecified-high = {
            model = models.coder.expensive;
            fallback_models = [
              models.coder.default
              models.coder.alternative
              models.coder.cheap
            ];
          };
        };
        background_task = {
          defaultConcurrency = 6;
          staleTimeoutMs = 180000;
          providerConcurrency = {
            github-copilot = 2;
            openrouter = 3;
            kimi-for-coding = 2;
            zai-coding-plan = 3;
            alibaba-coding-plan = 2;
            minimax = 3;
          };
        };
        experimental = {
          dcp_for_compaction = true;
          dynamic_context_pruning = {
            enabled = true;
          };
          task_system = true;
          auto_resume = true;
          aggressive_truncation = true;
          truncate_all_tool_outputs = true;
          strategies = {
            supersede_writes = {
              aggressive = true;
            };
          };
        };
        ralph_loop = {
          enabled = true;
          default_max_iterations = 1000;
        };
        disabled_hooks = [
          "rules-injector"
        ];
        hashline_edit = true;
        skills = {
          enable = [
          ];
          disable = [
            "git-master"
            "playwright"
            "playwright-cli"
            "dev-browser"
          ];
        };
        git_master = {
          commit_footer = false;
          include_co_authored_by = false;
        };
        runtime_fallback = {
          enabled = true;
          retry_on_errors = [
            400
            429
            503
            529
          ];
          max_fallback_attempts = 3;
          cooldown_seconds = 60;
          timeout_seconds = 25;
          notify_on_fallback = true;
        };
        claude_code = {
          mcp = false;
          commands = false;
          skills = false;
          agents = false;
          hooks = true;
        };
        google_auth = false;
      };
  };
}
