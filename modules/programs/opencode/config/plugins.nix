# config/plugins.nix - Plugin, agent, and command configurations for OpenCode
_: {
  config = {
    jvf.programs.opencode.settings = {
      plugin = [
        "@tarquinen/opencode-dcp@3.1.9"
        "oh-my-openagent@3.17.4"
      ];
    };

    jvf.programs.opencode.ohMyOpenCodeSettings =
      let
        kimi = "kimi-for-coding/k2p5";
        glm = "zai-coding-plan/glm-5.1";
        geminiPro = "github-copilot/gemini-3.1-pro-preview";
        geminiFlash = "github-copilot/gemini-3-flash-preview";
        minimax = "minimax/MiniMax-M2.7";
        qwen = "bailian-coding-plan/qwen3.5-plus";
        gpt = "openai/gpt-5.4";
        codex = "openai/gpt-5.3-codex";
        models = {
          quick = {
            default = minimax;
            cheap = qwen;
            expensive = "github-copilot/grok-code-fast-1";
            alternative = "openrouter/openai/gpt-oss-120b";
          };
          coder = {
            default = glm;
            cheap = kimi;
            expensive = codex;
            alternative = minimax;
          };
          intelligent = {
            default = gpt;
            cheap = kimi;
            expensive = geminiPro;
            alternative = glm;
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
            ultrawork = {
              model = models.coder.default;
            };
          };
          hephaestus = {
            model = models.coder.expensive;
          };
          librarian = {
            model = models.quick.alternative;
          };
          explore = {
            model = models.quick.default;
            model_fallback = true;
            fallback_models = [
              models.quick.alternative
              models.quick.cheap
              models.quick.expensive
            ];
          };
          atlas = {
            model = models.coder.alternative;
          };
          prometheus = {
            model = models.intelligent.default;
          };
          metis = {
            model = models.intelligent.expensive;
          };
          momus = {
            model = models.intelligent.alternative;
          };
          oracle = {
            model = models.intelligent.default;
          };
          document-writer = {
            model = models.writer.default;
          };
          multimodal-looker = {
            model = models.looker.default;
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
            model = models.quick.cheap;
            fallback_models = [
              models.quick.expensive
              models.quick.alternative
              models.quick.default
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
            zai-coding-plan = 10;
            bailian-coding-plan = 3;
            minimax = 3;
          };
          modelConcurrency = 3;
          maxDepth = 10;
          maxDescendants = 50;
          messageStalenessTimeoutMs = 300000;
          taskTtlMs = 86400000;
          sessionGoneTimeoutMs = 60000;
          syncPollTimeoutMs = 30000;
          maxToolCalls = 100;
          circuitBreaker = {
            enabled = true;
            failure_threshold = 5;
            reset_timeout_seconds = 300;
          };
        };
        experimental = {
          dcp_for_compaction = true;
          dynamic_context_pruning = {
            enabled = true;
            notification = true;
            turn_protection = 3;
            protected_tools = [
              "task"
              "skill"
            ];
            strategies = {
              deduplication = {
                enabled = true;
                threshold = 0.8;
              };
              purge_errors = {
                enabled = true;
                max_age_seconds = 3600;
              };
            };
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
          preemptive_compaction = true;
          plugin_load_timeout_ms = 10000;
          safe_hook_creation = true;
          disable_omo_env = false;
          hashline_edit = true;
          model_fallback_title = true;
          max_tools = 50;
        };
        ralph_loop = {
          enabled = true;
          default_max_iterations = 1000;
          state_dir = ".sisyphus/ralph";
          default_strategy = "sequential";
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
          sources = [ ];
        };
        git_master = {
          commit_footer = false;
          include_co_authored_by = false;
          git_env_prefix = "GIT_";
        };
        runtime_fallback = {
          enabled = false;
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
          plugins = [ ];
          plugins_override = { };
        };
        google_auth = false;
        new_task_system_enabled = true;
        disabled_mcps = [ ];
        disabled_tools = [ ];
        mcp_env_allowlist = [ ];
        model_fallback = false;
        notification = {
          enabled = true;
          sound = true;
          desktop = true;
        };
        model_capabilities = {
          thinking = { };
          reasoning_effort = { };
        };
        openclaw = {
          enabled = false;
        };
        babysitting = {
          enabled = false;
          max_retries = 3;
          retry_delay_seconds = 5;
        };
        browser_automation_engine = {
          default = "playwright";
        };
        websearch = {
          default_engine = "exa";
          max_results = 10;
        };
        start_work = {
          enabled = true;
          auto_plan = true;
        };
        auto_update = {
          enabled = true;
          check_interval_hours = 24;
        };
        comment_checker = {
          enabled = true;
          check_on_commit = true;
        };
        sisyphus_agent = {
          enabled = true;
          model = models.coder.default;
        };
        _migrations = {
          version = 1;
          auto_migrate = true;
        };
      };
  };
}
