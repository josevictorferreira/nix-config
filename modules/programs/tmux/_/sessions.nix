# tmuxp session definitions
# Pure data exports - no module boilerplate

{
  monitoring = {
    session_name = "📈 Monitoring";
    start_directory = "$HOME/.config/nix";
    windows = [
      {
        window_name = "Monitors";
        layout = "main-vertical";
        panes = [
          "k9s"
          "btop"
        ];
      }
    ];
  };

  homelab = {
    session_name = "🏠 Homelab";
    start_directory = "$HOME/Workspace/homelab";
    windows = [
      {
        window_name = "🏠 Homelab";
        layout = "tiled";
        panes = [
          "clear"
          "clear"
          "clear"
        ];
      }
      {
        window_name = "🧑🏻 Hermes";
        layout = "tiled";
        start_directory = "$HOME/Homelab/hermes";
        panes = [
          "clear"
        ];
      }
    ];
  };

  work = {
    session_name = "👨🏻‍🌾 Work";
    windows = [
      {
        window_name = "BoosterAgro";
        layout = "tiled";
        start_directory = "$HOME/Workspace/agrosmart/booster/boosteragro";
        panes = [
          "clear"
          "clear"
          "clear"
          "clear"
        ];
      }
      {
        window_name = "Nexus";
        layout = "tiled";
        start_directory = "$HOME/Workspace/agrosmart/nexus/nexus-backend";
        panes = [
          "clear"
          "clear"
          "clear"
          "clear"
        ];
      }
      {
        window_name = "BoosterPro";
        layout = "main-vertical";
        start_directory = "$HOME/Workspace/agrosmart/agrosmart-api";
        panes = [
          "clear"
          "clear"
          "clear"
        ];
      }
    ];
  };

  projects = {
    session_name = "👨🏻‍💻 Projects";
    start_directory = "$HOME/Workspace";
    windows = [
      {
        window_name = "👨🏻‍💻 Projects";
        layout = "tiled";
        panes = [
          "clear"
        ];
      }
    ];
  };

  aiWorkspace = {
    session_name = "🤖 AI Workspace";
    start_directory = "$HOME/Workspace/ai-workspace";
    windows = [
      {
        window_name = "🤖 AI Workspace";
        layout = "tiled";
        panes = [
          "clear"
          "clear"
          "clear"
        ];
      }
    ];
  };

  chat = {
    session_name = "🗨 Chat";
    start_directory = "$HOME/Workspace";
    windows = [
      {
        window_name = "🗨 Chat";
        panes = [ "weechat" ];
      }
    ];
  };

  valoris = {
    session_name = "🏘 Valoris";
    start_directory = "$HOME/Workspace/valoris";
    windows = [
      {
        window_name = "🏘 Valoris Main";
        layout = "tiled";
        panes = [
          "clear"
          "clear"
          "clear"
        ];
      }
    ];
  };

  valorisBackend = {
    session_name = "🏘 Valoris - Backend Sandbox $SESSION_ID";
    start_directory = "$HOME/Workspace/valoris";
    windows = [
      {
        window_name = "Sandbox $SESSION_ID";
        layout = "tiled";
        panes = [
          "./bin/dev_sandbox backend $SESSION_ID"
          "sleep 3 && ./bin/dev_sandbox backend $SESSION_ID"
          "sleep 6 && ./bin/dev_sandbox backend $SESSION_ID"
        ];
      }
    ];
  };

  valorisFrontend = {
    session_name = "🏘 Valoris - Frontend";
    start_directory = "$HOME/Workspace/valoris/frontend";
    windows = [
      {
        window_name = "Valoris Frontend";
        layout = "tiled";
        panes = [
          "nix develop"
          "sleep 2 && nix develop"
          "sleep 4 && nix develop"
        ];
      }
    ];
  };

  velox = {
    session_name = "💫 Velox";
    start_directory = "$HOME/Workspace/velox";
    windows = [
      {
        window_name = "💫 Velox";
        layout = "tiled";
        panes = [
          "clear"
        ];
      }
    ];
  };

  poise = {
    session_name = "👦 Poise";
    start_directory = "$HOME/Workspace/poise";
    windows = [
      {
        window_name = "👦 Poise";
        layout = "tiled";
        panes = [
          "clear"
        ];
      }
    ];
  };

  litersearch = {
    session_name = "📖 LiterSearch";
    start_directory = "$HOME/Workspace/litersearch";
    windows = [
      {
        window_name = "📖 LiterSearch";
        layout = "tiled";
        panes = [
          "clear"
        ];
      }
    ];
  };

  glyph = {
    session_name = "🪄 Glyph";
    start_directory = "$HOME/Workspace/glyph";
    windows = [
      {
        window_name = "🪄 Glyph";
        layout = "tiled";
        panes = [
          "clear"
        ];
      }
    ];
  };

  ideator = {
    session_name = "💡 Ideator";
    start_directory = "$HOME/Workspace/ideator";
    windows = [
      {
        window_name = "💡 Ideator";
        layout = "tiled";
        panes = [
          "clear"
        ];
      }
    ];
  };

  axion = {
    session_name = "🚘 Axion";
    start_directory = "$HOME/Workspace/axion";
    windows = [
      {
        window_name = "🚘 Axion";
        layout = "tiled";
        panes = [
          "clear"
        ];
      }
    ];
  };

  mordren = {
    session_name = "🧝🏼 Mordren";
    start_directory = "$HOME/Workspace/mordren";
    windows = [
      {
        window_name = "🧝🏼 Mordren";
        layout = "tiled";
        panes = [
          "clear"
        ];
      }
    ];
  };

  dramaturge = {
    session_name = "✏️ Dramaturge";
    start_directory = "$HOME/Workspace/dramaturge";
    windows = [
      {
        window_name = "✏️ Dramaturge";
        layout = "tiled";
        panes = [
          "clear"
        ];
      }
    ];
  };

  foyer = {
    session_name = "🌐 Foyer";
    start_directory = "$HOME/Workspace/foyer";
    windows = [
      {
        window_name = "🌐 Foyer";
        layout = "tiled";
        panes = [
          "clear"
        ];
      }
    ];
  };

  domus = {
    session_name = "🏚️ Domus";
    start_directory = "$HOME/Workspace/domus";
    windows = [
      {
        window_name = "🏚️ Domus";
        layout = "tiled";
        panes = [
          "clear"
        ];
      }
    ];
  };

  wealtho = {
    session_name = "🏦 Wealtho";
    start_directory = "$HOME/Workspace/wealtho";
    windows = [
      {
        window_name = "🏦 Wealtho";
        layout = "tiled";
        panes = [
          "clear"
          "clear"
          "clear"
        ];
      }
    ];
  };

  serve-analyzer = {
    session_name = "🎾 Serve Analyzer";
    start_directory = "$HOME/Workspace/serve-analyzer";
    windows = [
      {
        window_name = "🎾 Serve Analyzer";
        layout = "tiled";
        panes = [
          "clear"
          "clear"
          "clear"
        ];
      }
    ];
  };

  oratoria = {
    session_name = "💬 Oratoria";
    start_directory = "$HOME/Workspace/oratoria";
    windows = [
      {
        window_name = "💬 Oratoria";
        layout = "tiled";
        panes = [
          "clear"
        ];
      }
    ];
  };

  local-researcher = {
    session_name = "📚 Local Researcher";
    start_directory = "$HOME/Workspace/local-researcher";
    windows = [
      {
        window_name = "📚 Local Researcher";
        layout = "tiled";
        panes = [
          "clear"
          "clear"
          "clear"
        ];
      }
    ];
  };

  main = {
    session_name = "main";
    start_directory = "$HOME/.config/nix";
    windows = [
      {
        window_name = "NixConfig";
        layout = "main-vertical";
        panes = [
          "fastfetch"
          "clear"
          "clear"
        ];
      }
      {
        window_name = "Neovim";
        start_directory = "$HOME/.config/nvim";
        panes = [
          "clear"
          "clear"
        ];
      }
    ];
  };
}
