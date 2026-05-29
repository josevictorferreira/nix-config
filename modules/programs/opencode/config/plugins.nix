# config/plugins.nix - Plugin, agent, and command configurations for OpenCode
_: {
  config = {
    jvf.programs.opencode.settings = {
      plugin = [
        "@tarquinen/opencode-dcp@3.1.12"
        "oh-my-openagent@4.5.1"
        "@vectorize-io/opencode-hindsight"
      ];
    };

    jvf.programs.opencode.ohMyOpenCodeSettings =
      let
        kimi = "9router/kimi-k2.6";
        glm = "9router/glm-5.1";
        qwen = "9router/qwen3.6-plus";
        gpt = "9router/gpt-5.5";
        deepseekPro = "9router/deepseek-v4-pro";
        deepseek = "9router/deepseek-v4-flash";
        cheapFast = "9router/cheap-fast";
        minimax = "9router/minimax-m2.5";
        mimo = "9router/mimo-v2.5-pro";
        models = {
          quick = {
            default = cheapFast;
            cheap = cheapFast;
            expensive = deepseek;
            alternative = minimax;
          };
          coder = {
            default = glm;
            cheap = kimi;
            expensive = mimo;
            alternative = qwen;
          };
          intelligent = {
            default = gpt;
            cheap = glm;
            expensive = gpt;
            alternative = kimi;
          };
          looker = {
            default = qwen;
            cheap = qwen;
            expensive = kimi;
            alternative = kimi;
          };
          writer = {
            default = kimi;
            cheap = kimi;
            expensive = kimi;
            alternative = qwen;
          };
        };
      in
      {
        default_run_agent = "engineer";
        disabled_commands = [ ];
        disabled_agents = [ ];
        disabled_skills = [
          "git-master"
          "playwright"
          "dev-browser"
        ];
        agents = {
          hephaestus = {
            model = models.coder.expensive;
            fallback_models = [
              models.coder.expensive
              models.coder.default
              models.coder.alternative
            ];
          };
          librarian = {
            model = models.quick.cheap;
            fallback_models = [
              models.quick.cheap
              models.quick.default
              models.quick.alternative
              models.quick.expensive
            ];
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
            fallback_models = [
              models.coder.alternative
              models.coder.default
              models.coder.expensive
            ];
          };
          prometheus = {
            model = models.intelligent.default;
            fallback_models = [
              models.intelligent.default
              models.intelligent.expensive
              models.intelligent.alternative
              models.intelligent.cheap
            ];
          };
          metis = {
            model = models.intelligent.expensive;
            fallback_models = [
              models.intelligent.expensive
              models.intelligent.default
              models.intelligent.alternative
              models.intelligent.cheap
            ];
          };
          momus = {
            model = models.intelligent.alternative;
            fallback_models = [
              models.intelligent.alternative
              models.intelligent.default
              models.intelligent.expensive
              models.intelligent.cheap
            ];
          };
          oracle = {
            model = models.intelligent.default;
            variant = "xhigh";
            fallback_models = [
              models.intelligent.default
              models.intelligent.expensive
              models.intelligent.alternative
              models.intelligent.cheap
            ];
          };
          document-writer = {
            model = models.writer.default;
            fallback_models = [
              models.writer.default
              models.writer.expensive
              models.writer.alternative
              models.writer.cheap
            ];
          };
          multimodal-looker = {
            model = models.looker.default;
            fallback_models = [
              models.looker.default
              models.looker.expensive
              models.looker.alternative
              models.looker.cheap
            ];
          };
          ui-designer = {
            model = models.looker.default;
            fallback_models = [
              models.looker.default
              models.looker.expensive
              models.looker.alternative
              models.looker.cheap
            ];
          };
          product-manager = {
            model = models.intelligent.default;
            fallback_models = [
              models.intelligent.default
              models.intelligent.expensive
              models.intelligent.alternative
              models.intelligent.cheap
            ];
          };
          architect = {
            model = models.coder.expensive;
            fallback_models = [
              models.coder.expensive
              models.coder.default
              models.coder.alternative
              models.coder.cheap
            ];
          };
          devops = {
            model = models.coder.default;
            fallback_models = [
              models.coder.default
              models.coder.alternative
              models.coder.expensive
              models.coder.cheap
            ];
          };
          sisyphus = {
            model = models.coder.default;
            fallback_models = [
              models.coder.default
              models.coder.alternative
              models.coder.expensive
              models.coder.cheap
            ];
          };
          sisyphus-junior = {
            model = models.coder.default;
            fallback_models = [
              models.coder.default
              models.coder.alternative
              models.coder.expensive
              models.coder.cheap
            ];
          };
          build = {
            model = models.coder.default;
            fallback_models = [
              models.coder.default
              models.coder.alternative
              models.coder.expensive
              models.coder.cheap
            ];
          };
          plan = {
            model = models.intelligent.default;
            fallback_models = [
              models.intelligent.default
              models.intelligent.expensive
              models.intelligent.alternative
              models.intelligent.cheap
            ];
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
            model_fallback = true;
            fallback_models = [
              models.quick.cheap
              models.quick.expensive
              models.quick.alternative
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
            "9router" = 6;
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
          preemptive_compaction = false; # disabled: rely on DCP plugin (dcp_for_compaction) as the sole compactor
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
          state_dir = ".omo/ralph";
          default_strategy = "sequential";
        };
        disabled_hooks = [
          "rules-injector"
        ];
        hashline_edit = true;
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
          plugins = false;
          plugins_override = { };
        };
        new_task_system_enabled = true;
        disabled_mcps = [
          "chrome-devtools"
        ];
        disabled_tools = [ ];
        mcp_env_allowlist = [ ];
        model_fallback = true;
        notification = {
          enabled = true;
          sound = true;
          desktop = true;
        };
        openclaw = {
          enabled = false;
        };
        babysitting = {
          enabled = true;
          max_retries = 3;
          retry_delay_seconds = 5;
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
          disabled = false;
          default_builder_enabled = true;
          planner_enabled = true;
          replace_plan = true;
          tdd = true;
        };
        _migrations = {
          version = 1;
          auto_migrate = true;
        };
      };
  };
}
