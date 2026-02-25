# Default k9s settings
# Pure data export - no module boilerplate
_:
{
  settings = {
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
      sinceSeconds = 3600;
      textWrap = true;
      showTime = false;
      disableAutoscroll = false;
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

  aliases = {
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
}
