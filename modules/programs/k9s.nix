{
  lib,
  pkgs,
  config,
  username,
  ...
}:
let
  cfg = config.jvf.programs.k9s;

  defaultSettings = {
    liveViewAutoRefresh = false;
    refreshRate = 2;
    maxConnRetry = 5;
    defaultView = "pods";
    readOnly = false;
    noExitOnCtrlC = false;
    ui = {
      enableMouse = false;
      headless = false;
      logoless = false;
      crumbsless = false;
      reactive = false;
      noIcons = false;
      defaultsToFullScreen = false;
      skin = "tokyonight";
    };
    skipLatestRevCheck = false;
    disablePodCounting = false;
    shellPod = {
      image = "busybox:1.35.0";
      namespace = "default";
      limits = {
        cpu = "100m";
        memory = "100Mi";
      };
    };
    imageScans = {
      enable = false;
      exclusions = {
        namespaces = [ ];
        labels = { };
      };
    };
    logger = {
      tail = 150;
      buffer = 10000;
      sinceSeconds = -1;
      textWrap = true;
      showTime = false;
      disableAutoscroll = true;
    };
    thresholds = {
      cpu = {
        critical = 90;
        warn = 70;
      };
      memory = {
        critical = 90;
        warn = 70;
      };
    };
  };

  defaultAliases = {
    dp = "deployments";
    jo = "jobs";
    cr = "clusterroles";
    crb = "clusterrolebindings";
    ro = "roles";
    rb = "rolebindings";
    np = "networkpolicies";
    na = "namespaces";
    prod = "namespaces production";
    stag = "namespaces staging";
    self = "namespaces self-hosted";
    ctx = "contexts";
    home = "contexts homelab";
    sec = "secrets all";
    cm = "configmap";
    ss = "statefulset";
  };

  tokyonight-skin =
    let
      foreground = "#c0caf5";
      background = "#24283b";
      current_line = "#8c6c3e";
      selection = "#364a82";
      comment = "#565f89";
      cyan = "#7dcfff";
      green = "#9ece6a";
      yellow = "#e0af68";
      orange = "#ff9e64";
      magenta = "#bb9af7";
      blue = "#7aa2f7";
      red = "#f7768e";
    in
    {
      k9s = {
        body = {
          fgColor = foreground;
          bgColor = "default";
          logoColor = blue;
        };
        prompt = {
          fgColor = foreground;
          bgColor = background;
          suggestColor = orange;
        };
        info = {
          fgColor = magenta;
          sectionColor = foreground;
        };
        dialog = {
          fgColor = foreground;
          bgColor = "default";
          buttonFgColor = foreground;
          buttonBgColor = magenta;
          buttonFocusFgColor = background;
          buttonFocusBgColor = foreground;
          labelFgColor = comment;
          fieldFgColor = foreground;
        };
        frame = {
          border = {
            fgColor = selection;
            focusColor = foreground;
          };
          menu = {
            fgColor = foreground;
            keyColor = magenta;
            numKeyColor = magenta;
          };
          crumbs = {
            fgColor = background;
            bgColor = cyan;
            activeColor = yellow;
          };
          status = {
            newColor = magenta;
            modifyColor = blue;
            addColor = green;
            errorColor = red;
            highlightcolor = orange;
            killColor = comment;
            completedColor = comment;
          };
          title = {
            fgColor = foreground;
            bgColor = "default";
            highlightColor = blue;
            counterColor = magenta;
            filterColor = magenta;
          };
        };
        views = {
          charts = {
            bgColor = "default";
            defaultDialColors = [
              blue
              red
            ];
            defaultChartColors = [
              blue
              red
            ];
          };
          table = {
            fgColor = foreground;
            bgColor = "default";
            cursorFgColor = background;
            cursorBgColor = foreground;
            markColor = "darkgoldenrod";
            header = {
              fgColor = foreground;
              bgColor = "default";
              sorterColor = cyan;
            };
          };
          xray = {
            fgColor = foreground;
            bgColor = "default";
            cursorColor = current_line;
            graphicColor = blue;
            showIcons = true;
          };
          yaml = {
            keyColor = magenta;
            colonColor = blue;
            valueColor = foreground;
          };
          logs = {
            fgColor = foreground;
            bgColor = "default";
            indicator = {
              fgColor = foreground;
              bgColor = selection;
            };
          };
          help = {
            fgColor = foreground;
            bgColor = "default";
            indicator = {
              fgColor = red;
              bgColor = selection;
            };
          };
        };
      };
    };
in
{
  options.jvf.programs.k9s = {
    enable = lib.mkEnableOption "k9s, a terminal-based UI for Kubernetes";
    package = lib.mkPackageOption pkgs "k9s" { };

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to install the configuration";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = defaultSettings;
      description = lib.mdDoc "Configuration for k9s, written to config.yaml.";
    };

    aliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = defaultAliases;
      description = lib.mdDoc "Short name aliases for Kubernetes resources.";
    };

    skins = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = {
        tokyonight = tokyonight-skin;
      };
      description = lib.mdDoc "Theme/skin definitions for k9s.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      sessionVariables = {
        K9S_CONFIG_DIR = "$HOME/.config/k9s";
      };
    };

    jvf.wrappers.users.${cfg.username}.programs.k9s = {
      packages = [
        cfg.package
      ];
      configs = {
        "config.yaml" = cfg.settings;
        "aliases.yaml" = cfg.aliases;
        "skins.yaml" = cfg.skins;
      };
    };
  };
}
