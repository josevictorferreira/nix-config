# config/plugins.nix - Plugin, agent, and command configurations for OpenCode
_: {
  config = {
    jvf.programs.opencode.settings.plugin = [
      "@tarquinen/opencode-dcp@3.1.9"
      "oh-my-openagent@3.17.4"
    ];

    jvf.programs.opencode.ohMyOpenCodeSettings =
      let
        kimi = "kimi-for-coding/k2p5";
        glm = "zai-coding-plan/glm-5.1";
        geminiPro = "github-copilot/gemini-3.1-pro-preview";
        geminiFlash = "github-copilot/gemini-3-flash-preview";
        minimax = "minimax/MiniMax-M2.7";
        qwen = "alibaba-coding-plan/qwen3.5-plus";
        gpt = "openai/gpt-5.4";
        codex = "openai/gpt-5.3-codex";
        models = {
          quick = {
            default = "inception/mercury-2";
            cheap = minimax;
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
              edit = "allow";
              bash = "allow";
              webfetch = "allow";
              task = "allow";
              doom_loop = "allow";
              external_directory = "allow";
            };
            variant = "coder";
            category = "general";
            description = "Primary implementation agent for autonomous task execution";
            mode = "default";
            color = "blue";
            top_p = 1.0;
            maxTokens = 16384;
            thinking = { };
            reasoningEffort = { };
            textVerbosity = "default";
            providerOptions = { };
            ultrawork = { };
            compaction = { };
          };
          hephaestus = {
            model = models.coder.expensive;
            model_fallback = true;
            fallback_models = [
              models.coder.default
              models.coder.alternative
              models.coder.cheap
            ];
            variant = "coder";
            category = "general";
            description = "Heavy-duty build and compilation agent";
            mode = "default";
            color = "red";
            top_p = 1.0;
            maxTokens = 16384;
            thinking = { };
            reasoningEffort = { };
            textVerbosity = "default";
            providerOptions = { };
            ultrawork = { };
            compaction = { };
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
              edit = "deny";
              bash = "allow";
              webfetch = "allow";
              task = "allow";
              doom_loop = "deny";
              external_directory = "deny";
            };
            variant = "quick";
            category = "general";
            description = "Library and documentation research agent";
            mode = "default";
            color = "green";
            top_p = 1.0;
            maxTokens = 16384;
            thinking = { };
            reasoningEffort = { };
            textVerbosity = "default";
            providerOptions = { };
            ultrawork = { };
            compaction = { };
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
              edit = "deny";
              bash = "allow";
              webfetch = "allow";
              task = "allow";
              doom_loop = "deny";
              external_directory = "deny";
            };
            variant = "quick";
            category = "general";
            description = "Codebase exploration and search agent";
            mode = "default";
            color = "cyan";
            top_p = 1.0;
            maxTokens = 16384;
            thinking = { };
            reasoningEffort = { };
            textVerbosity = "default";
            providerOptions = { };
            ultrawork = { };
            compaction = { };
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
              edit = "deny";
              bash = "allow";
              webfetch = "allow";
              task = "allow";
              doom_loop = "deny";
              external_directory = "deny";
            };
            variant = "coder";
            category = "general";
            description = "Architecture and structural analysis agent";
            mode = "default";
            color = "magenta";
            top_p = 1.0;
            maxTokens = 16384;
            thinking = { };
            reasoningEffort = { };
            textVerbosity = "default";
            providerOptions = { };
            ultrawork = { };
            compaction = { };
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
              edit = "deny";
              bash = "allow";
              webfetch = "allow";
              task = "allow";
              doom_loop = "deny";
              external_directory = "deny";
            };
            variant = "intelligent";
            category = "general";
            description = "Planning and task decomposition agent";
            mode = "default";
            color = "yellow";
            top_p = 1.0;
            maxTokens = 16384;
            thinking = { };
            reasoningEffort = { };
            textVerbosity = "default";
            providerOptions = { };
            ultrawork = { };
            compaction = { };
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
              edit = "deny";
              bash = "allow";
              webfetch = "allow";
              task = "allow";
              doom_loop = "deny";
              external_directory = "deny";
            };
            variant = "intelligent";
            category = "general";
            description = "Wisdom and strategic counsel agent";
            mode = "default";
            color = "white";
            top_p = 1.0;
            maxTokens = 16384;
            thinking = { };
            reasoningEffort = { };
            textVerbosity = "default";
            providerOptions = { };
            ultrawork = { };
            compaction = { };
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
              edit = "deny";
              bash = "allow";
              webfetch = "allow";
              task = "allow";
              doom_loop = "deny";
              external_directory = "deny";
            };
            variant = "intelligent";
            category = "general";
            description = "Critique and review agent";
            mode = "default";
            color = "red";
            top_p = 1.0;
            maxTokens = 16384;
            thinking = { };
            reasoningEffort = { };
            textVerbosity = "default";
            providerOptions = { };
            ultrawork = { };
            compaction = { };
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
            variant = "intelligent";
            category = "general";
            description = "Deep analysis and prediction agent";
            mode = "default";
            color = "purple";
            top_p = 1.0;
            maxTokens = 16384;
            thinking = { };
            reasoningEffort = { };
            textVerbosity = "default";
            providerOptions = { };
            ultrawork = { };
            compaction = { };
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
            variant = "writer";
            category = "general";
            description = "Documentation and content creation agent";
            mode = "default";
            color = "green";
            top_p = 1.0;
            maxTokens = 16384;
            thinking = { };
            reasoningEffort = { };
            textVerbosity = "default";
            providerOptions = { };
            ultrawork = { };
            compaction = { };
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
              edit = "deny";
              bash = "allow";
              webfetch = "allow";
              task = "allow";
              doom_loop = "deny";
              external_directory = "deny";
            };
            variant = "looker";
            category = "general";
            description = "Visual analysis and multimodal inspection agent";
            mode = "default";
            color = "cyan";
            top_p = 1.0;
            maxTokens = 16384;
            thinking = { };
            reasoningEffort = { };
            textVerbosity = "default";
            providerOptions = { };
            ultrawork = { };
            compaction = { };
          };
          build = {
            model = models.coder.cheap;
            model_fallback = true;
            fallback_models = [
              models.coder.default
              models.coder.alternative
              models.coder.expensive
            ];
            variant = "coder";
            category = "general";
            description = "Build and compilation agent";
            permission = {
              edit = "deny";
              bash = "allow";
              webfetch = "allow";
              task = "allow";
              doom_loop = "deny";
              external_directory = "deny";
            };
          };
          plan = {
            model = models.intelligent.default;
            model_fallback = true;
            fallback_models = [
              models.intelligent.expensive
              models.intelligent.alternative
              models.intelligent.cheap
            ];
            variant = "intelligent";
            category = "general";
            description = "Planning and task decomposition agent";
            permission = {
              edit = "deny";
              bash = "allow";
              webfetch = "allow";
              task = "allow";
              doom_loop = "deny";
              external_directory = "deny";
            };
          };
          sisyphus-junior = {
            model = models.coder.cheap;
            model_fallback = true;
            fallback_models = [
              models.coder.default
              models.coder.alternative
              models.coder.expensive
            ];
            variant = "coder";
            category = "general";
            description = "Junior implementation agent for delegated tasks";
            permission = {
              edit = "allow";
              bash = "allow";
              webfetch = "allow";
              task = "allow";
              doom_loop = "allow";
              external_directory = "allow";
            };
          };
          "OpenCode-Builder" = {
            model = models.coder.default;
            model_fallback = true;
            fallback_models = [
              models.coder.alternative
              models.coder.cheap
              models.coder.expensive
            ];
            variant = "coder";
            category = "general";
            description = "OpenCode configuration builder agent";
            permission = {
              edit = "deny";
              bash = "allow";
              webfetch = "allow";
              task = "allow";
              doom_loop = "deny";
              external_directory = "deny";
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
          plugins = [ ];
          plugins_override = { };
        };
        google_auth = false;
        new_task_system_enabled = true;
        default_run_agent = "sisyphus";
        disabled_mcps = [ ];
        disabled_agents = [ ];
        disabled_tools = [ ];
        mcp_env_allowlist = [ ];
        model_fallback = {
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
        tmux = {
          enabled = true;
          session_prefix = "omo-";
        };
        sisyphus = {
          tasks = {
            enabled = true;
            auto_create = true;
            auto_complete = true;
          };
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
