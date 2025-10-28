{ lib
, pkgs
, config
, ...
}:
let
  cfg = config.jvf.programs.btop;
  defaultConfig = {
    theme_background = false;
    truecolor = true;
    force_tty = false;
    presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:block,net:0:tty";
    vim_keys = false;
    rounded_corners = true;
    graph_symbol = "braille";
    graph_symbol_cpu = "default";
    graph_symbol_gpu = "default";
    graph_symbol_mem = "default";
    graph_symbol_net = "default";
    graph_symbol_proc = "default";
    shown_boxes = "proc cpu mem net";
    update_ms = 2000;
    proc_sorting = "cpu direct";
    proc_reversed = false;
    proc_tree = false;
    proc_colors = true;
    proc_gradient = true;
    proc_per_core = false;
    proc_mem_bytes = true;
    proc_cpu_graphs = true;
    proc_info_smaps = false;
    proc_left = false;
    proc_filter_kernel = false;
    proc_aggregate = false;
    cpu_graph_upper = "total";
    cpu_graph_lower = "total";
    show_gpu_info = "Auto";
    cpu_invert_lower = true;
    cpu_single_graph = false;
    cpu_bottom = false;
    show_uptime = true;
    check_temp = true;
    cpu_sensor = "Auto";
    show_coretemp = true;
    cpu_core_map = "";
    temp_scale = "celsius";
    base_10_sizes = true;
    show_cpu_freq = true;
    clock_format = "%X";
    background_update = true;
    custom_cpu_name = "";
    disks_filter = "";
    mem_graphs = true;
    mem_below_net = false;
    zfs_arc_cached = true;
    show_swap = true;
    swap_disk = true;
    show_disks = false;
    only_physical = true;
    use_fstab = true;
    zfs_hide_datasets = false;
    disk_free_priv = false;
    show_io_stat = true;
    io_mode = false;
    io_graph_combined = false;
    io_graph_speeds = "";
    net_download = 100;
    net_upload = 100;
    net_auto = true;
    net_sync = true;
    net_iface = "";
    base_10_bitrate = "Auto";
    show_battery = false;
    selected_battery = "Auto";
    show_battery_watts = true;
    log_level = "WARNING";
    nvml_measure_pcie_speeds = true;
    rsmi_measure_pcie_speeds = true;
    gpu_mirror_graph = true;
    custom_gpu_name0 = "";
    custom_gpu_name1 = "";
    custom_gpu_name2 = "";
    custom_gpu_name3 = "";
    custom_gpu_name4 = "";
    custom_gpu_name5 = "";
  };
in
{
  options.jvf.programs.btop = {
    enable = lib.mkEnableOption "btop, a modern resource monitor";
    package = lib.mkPackageOption pkgs "btop" { };
    settings = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.oneOf [
          lib.types.str
          lib.types.bool
          lib.types.int
        ]
      );
      description = lib.mdDoc "Configuration attribute set for btop. User settings are merged with the defaults.";
      default = defaultConfig;
      example = {
        color_theme = "tty";
        vim_keys = true;
      };
    };
  };

  config = lib.mkIf cfg.enable (
    let
      configFile = pkgs.writeTextFile {
        name = "btop.conf";
        text = lib.generators.toINIWithGlobalSection { } {
          globalSection = cfg.settings;
          sections = { };
        };
      };

      btop-wrapped = pkgs.writeShellApplication {
        name = "btop";
        runtimeInputs = [ cfg.package ];
        text = ''
          exec ${lib.getExe pkgs.btop} --config "${configFile}" "$@"
        '';
      };
    in
    {
      environment.systemPackages = [ btop-wrapped ];
    }
  );
}
