# Aspect: programs-btop
# Defines jvf.programs.btop options for btop resource monitor.
# NixOS: btop-rocm default, full config with wrappers.
# Darwin: btop default, full config with wrappers.
let
  # Pure btop theme generator -- parameterized by colors attrset
  mkBtopThemeText = colors: ''
    theme[main_bg]="#${colors.background}"
    theme[main_fg]="#${colors.foreground}"
    theme[title]="#${colors.color4}"
    theme[hi_fg]="#${colors.color1}"
    theme[selected_bg]="#${colors.color8}"
    theme[selected_fg]="#${colors.foreground}"
    theme[inactive_fg]="#${colors.color8}"
    theme[graph_text]="#${colors.color8}"
    theme[meter_bg]="#${colors.color8}"
    theme[proc_misc]="#${colors.color8}"
    theme[cpu_box]="#${colors.color2}"
    theme[mem_box]="#${colors.color1}"
    theme[net_box]="#${colors.color6}"
    theme[proc_box]="#${colors.color5}"
    theme[div_line]="#${colors.color8}"
  '';
  mkBtopOptions =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      defaultPackage = "btop";
    in
    {
      options.jvf.programs.btop = {
        package = lib.mkPackageOption pkgs defaultPackage { };
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to configure btop.";
        };
        settings = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.oneOf [
              lib.types.str
              lib.types.bool
              lib.types.int
            ]
          );
          description = "Configuration attribute set for btop. User settings are merged with the defaults.";
          default = {
            color_theme = "onedark";
            theme_background = true;
            truecolor = true;
            force_tty = false;
            presets = "cpu:0:braille,mem:0:braille,gpu0:0:braille";
            vim_keys = true;
            rounded_corners = true;
            graph_symbol = "braille";
            graph_symbol_cpu = "default";
            graph_symbol_gpu = "default";
            graph_symbol_mem = "default";
            graph_symbol_net = "default";
            graph_symbol_proc = "default";
            shown_boxes = "cpu mem gpu0";
            update_ms = 2000;
            proc_sorting = "memory";
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
            enable_gpu = true;
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
          example = {
            color_theme = "tty";
            vim_keys = true;
          };
        };
      };
    };

  btopModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.programs.btop;
      defaultPkg = if pkgs.stdenv.isDarwin then pkgs.btop else pkgs.btop-rocm;
      colors = config.jvf.theme.colors;
      darkPreset = config.jvf.theme.presets.tokyonight-night;
      lightPreset = config.jvf.theme.presets.tokyonight-day;

      btopTheme = mkBtopThemeText colors;

      # Build merged btop config directory via symlinkJoin
      # Custom INI generator that handles Booleans (pkgs.formats.ini doesn't support them)
      toIni =
        attrs:
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            n: v: "${n}=${if lib.isBool v then (if v then "true" else "false") else toString v}"
          ) attrs
        );
      btopConfigDir = pkgs.symlinkJoin {
        name = "btop-config";
        paths = [
          (pkgs.writeTextDir "btop.conf" (toIni (cfg.settings // { color_theme = "jvf-active"; })))
          (pkgs.writeTextDir "vertical-compact.conf" (
            toIni (
              cfg.settings
              // {
                color_theme = "jvf-active";
                presets = "cpu:0:braille,mem:0:braille,gpu0:0:braille";
                shown_boxes = "cpu mem gpu0";
                show_disks = false;
                show_battery = false;
              }
            )
          ))
          (pkgs.writeTextDir "themes/jvf-active.theme" btopTheme)
        ];
      };

      # Profile artifacts for dual-theme runtime switching
      darkBtopArtifact = pkgs.writeTextDir "tokyonight-night.theme" (mkBtopThemeText darkPreset.colors);
      lightBtopArtifact = pkgs.writeTextDir "tokyonight-day.theme" (mkBtopThemeText lightPreset.colors);
    in
    {
      imports = [ mkBtopOptions ];

      config = {
        jvf.programs.btop.package = lib.mkDefault defaultPkg;
        jvf.home.users.${cfg.username}.items = {
          ".config/btop" = {
            kind = "dir";
            mode = "copy";
            source = btopConfigDir;
          };
        };
        # Profile artifacts for dual-theme runtime switching
        jvf.theme.profileArtifacts.dark.btop = darkBtopArtifact;
        jvf.theme.profileArtifacts.light.btop = lightBtopArtifact;
      };
    };
in
{
  flake.modules.nixos.programs-btop = btopModule;
  flake.modules.darwin.programs-btop = btopModule;
}
