# tmuxp session definitions
# Pure data exports - no module boilerplate

{
  chat = {
    session_name = "chat";
    start_directory = "$HOME/Workspace";
    windows = [
      {
        window_name = "Chat";
        panes = [ "weechat" ];
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

  monitoring = {
    session_name = "monitoring";
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
    session_name = "homelab";
    start_directory = "$HOME/Workspace/homelab";
    windows = [
      {
        window_name = "Homelab";
        layout = "tiled";
        panes = [
          "clear"
          "clear"
          "clear"
        ];
      }
      {
        window_name = "Hermes";
        layout = "tiled";
        start_directory = "$HOME/Homelab/hermes";
        panes = [
          "clear"
        ];
      }
    ];
  };

  valoris = {
    session_name = "valoris";
    start_directory = "$HOME/Workspace/valoris";
    windows = [
      {
        window_name = "Valoris Main";
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
    session_name = "Valoris - Backend Sandbox $SESSION_ID";
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
    session_name = "Valoris - Frontend";
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

  aiWorkspace = {
    session_name = "ai-workspace";
    start_directory = "$HOME/Workspace/ai-workspace";
    windows = [
      {
        window_name = "AI Workspace";
        layout = "tiled";
        panes = [
          "clear"
          "clear"
          "clear"
        ];
      }
    ];
  };

  projects = {
    session_name = "projects";
    start_directory = "$HOME/Workspace";
    windows = [
      {
        window_name = "Projects";
        layout = "tiled";
        panes = [
          "clear"
        ];
      }
      {
        window_name = "Glyph";
        layout = "tiled";
        start_directory = "$HOME/Workspace/glyph";
        panes = [
          "clear"
        ];
      }
      {
        window_name = "Axion";
        layout = "tiled";
        start_directory = "$HOME/Workspace/axion";
        panes = [
          "clear"
        ];
      }
      {
        window_name = "Mordren";
        layout = "tiled";
        start_directory = "$HOME/Workspace/mordren";
        panes = [
          "clear"
        ];
      }
      {
        window_name = "Dramaturge";
        layout = "tiled";
        start_directory = "$HOME/Workspace/dramaturge";
        panes = [
          "clear"
        ];
      }
    ];
  };

  wealtho = {
    session_name = "wealtho";
    start_directory = "$HOME/Workspace/wealtho";
    windows = [
      {
        window_name = "Wealtho";
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
    session_name = "serve-analyzer";
    start_directory = "$HOME/Workspace/serve-analyzer";
    windows = [
      {
        window_name = "Serve Analyzer";
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
    session_name = "oratoria";
    start_directory = "$HOME/Workspace/oratoria";
    windows = [
      {
        window_name = "Oratoria";
        layout = "tiled";
        panes = [
          "clear"
        ];
      }
    ];
  };

  local-researcher = {
    session_name = "local-researcher";
    start_directory = "$HOME/Workspace/local-researcher";
    windows = [
      {
        window_name = "Local Researcher";
        layout = "tiled";
        panes = [
          "clear"
          "clear"
          "clear"
        ];
      }
    ];
  };

  work = {
    session_name = "work";
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
}
