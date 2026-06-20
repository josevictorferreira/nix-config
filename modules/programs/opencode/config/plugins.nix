# config/plugins.nix - Plugin, agent, and command configurations for OpenCode
_: {
  config = {
    jvf.programs.opencode.settings = {
      plugin = [
        "@tarquinen/opencode-dcp@3.1.12"
        "oh-my-openagent@4.12.1"
        "@vectorize-io/opencode-hindsight"
      ];
    };

    jvf.programs.opencode.ohMyOpenCodeSettings =
      let
        kimi = "omniroute/kimi-k2.7-code";
        kimiCoder = "omniroute/kimi-coding";
        glm = "omniroute/glm-5.2";
        glmThinking = "omniroute/glm-5.2-max";
        qwen = "omniroute/qwen3.7-plus";
        gpt = "omniroute/gpt-5.5";
        gandalf = "omniroute/gandalf";
        radagast = "omniroute/radagast";
        saruman = "omniroute/saruman";
        legolas = "omniroute/legolas";
        deepseekPro = "omniroute/deepseek-v4-pro";
        deepseek = "omniroute/deepseek-v4-flash";
        minimax = "omniroute/minimax-m3";
        mimo = "omniroute/mimo-v2.5-pro";
        models = {
          quick = {
            default = legolas;
            cheap = legolas;
            expensive = deepseek;
            alternative = minimax;
          };
          coder = {
            default = kimiCoder;
            cheap = glm;
            expensive = mimo;
            alternative = qwen;
          };
          intelligent = {
            default = gandalf;
            cheap = glmThinking;
            expensive = saruman;
            alternative = radagast;
          };
          looker = {
            default = qwen;
            cheap = qwen;
            expensive = kimi;
            alternative = kimi;
          };
          writer = {
            default = kimi;
            cheap = qwen;
            expensive = radagast;
            alternative = mimo;
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
            model_fallback = true;
            fallback_models = [
              models.coder.expensive
              models.coder.default
              models.coder.alternative
            ];
          };
          librarian = {
            model = models.quick.cheap;
            model_fallback = true;
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
              models.quick.default
              models.quick.alternative
              models.quick.cheap
              models.quick.expensive
            ];
          };
          atlas = {
            model = models.intelligent.default;
            model_fallback = true;
            fallback_models = [
              models.intelligent.default
              models.coder.alternative
              models.coder.default
              models.coder.expensive
            ];
          };
          prometheus = {
            model = models.intelligent.default;
            model_fallback = true;
            fallback_models = [
              models.intelligent.default
              models.intelligent.cheap
              models.intelligent.expensive
              models.intelligent.alternative
            ];
          };
          metis = {
            model = models.intelligent.expensive;
            model_fallback = true;
            fallback_models = [
              models.intelligent.expensive
              models.intelligent.cheap
              models.intelligent.alternative
              models.intelligent.default
            ];
          };
          momus = {
            model = models.intelligent.alternative;
            model_fallback = true;
            fallback_models = [
              models.intelligent.alternative
              models.intelligent.cheap
              models.intelligent.default
              models.intelligent.expensive
            ];
          };
          oracle = {
            model = models.intelligent.default;
            model_fallback = true;
            fallback_models = [
              models.intelligent.default
              models.intelligent.expensive
              models.intelligent.alternative
              models.intelligent.cheap
            ];
          };
          document-writer = {
            model = models.writer.default;
            model_fallback = true;
            fallback_models = [
              models.writer.default
              models.writer.expensive
              models.writer.alternative
              models.writer.cheap
            ];
          };
          multimodal-looker = {
            model = models.looker.default;
            model_fallback = true;
            fallback_models = [
              models.looker.default
              models.looker.expensive
              models.looker.alternative
              models.looker.cheap
            ];
          };
          ui-designer = {
            model = models.looker.default;
            model_fallback = true;
            fallback_models = [
              models.looker.default
              models.looker.expensive
              models.looker.alternative
              models.looker.cheap
            ];
          };
          product-manager = {
            model = models.intelligent.default;
            model_fallback = true;
            fallback_models = [
              models.intelligent.default
              models.intelligent.expensive
              models.intelligent.alternative
              models.intelligent.cheap
            ];
          };
          architect = {
            model = models.coder.expensive;
            model_fallback = true;
            fallback_models = [
              models.coder.expensive
              models.coder.default
              models.coder.alternative
              models.coder.cheap
            ];
          };
          devops = {
            model = models.coder.default;
            model_fallback = true;
            fallback_models = [
              models.coder.default
              models.coder.alternative
              models.coder.expensive
              models.coder.cheap
            ];
          };
          sisyphus = {
            model = models.coder.default;
            model_fallback = true;
            fallback_models = [
              models.coder.default
              models.coder.alternative
              models.coder.expensive
              models.coder.cheap
            ];
          };
          sisyphus-junior = {
            model = models.coder.default;
            model_fallback = true;
            fallback_models = [
              models.coder.default
              models.coder.alternative
              models.coder.expensive
              models.coder.cheap
            ];
          };
          build = {
            model = models.coder.default;
            model_fallback = true;
            fallback_models = [
              models.coder.default
              models.coder.alternative
              models.coder.expensive
              models.coder.cheap
            ];
          };
          plan = {
            model = models.intelligent.default;
            model_fallback = true;
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
          defaultConcurrency = 8;
          staleTimeoutMs = 180000;
          providerConcurrency = {
            "omniroute" = 8;
          };
          maxDepth = 10;
          maxDescendants = 50;
          messageStalenessTimeoutMs = 300000;
          taskTtlMs = 86400000;
          sessionGoneTimeoutMs = 60000;
          maxToolCalls = 100;
          circuitBreaker = {
            enabled = true;
            failure_threshold = 3;
            reset_timeout_seconds = 300;
          };
        };
        experimental = {
          dcp_for_compaction = true;
          dynamic_context_pruning = {
            enabled = true;
            notification = "minimal";
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
        claude_code = {
          mcp = false;
          commands = false;
          skills = false;
          agents = false;
          hooks = false;
          plugins = false;
          plugins_override = { };
        };
        ralph_loop = {
          enabled = true;
          default_max_iterations = 1000;
          state_dir = ".omo/ralph";
          default_strategy = "continue";
        };
        disabled_hooks = [
          "rules-injector"
        ];
        hashline_edit = true;
        git_master = {
          commit_footer = false;
          include_co_authored_by = false;
        };
        runtime_fallback = {
          enabled = true;
          retry_on_errors = [
            400
            401
            403
            404
            429
            500
            502
            503
            504
          ];
          max_fallback_attempts = 3;
          cooldown_seconds = 15;
          timeout_seconds = 10;
          notify_on_fallback = true;
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
        auto_update = false;
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
      };
  };
}
