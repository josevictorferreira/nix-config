# Aspect: checks-theme
# perSystem checks for theme preset consistency.
#   theme-presets  — ensures all presets have required fields.
{ inputs, self, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    let
      coreModules = [
        self.modules.nixos.core-jvf
        self.modules.nixos.core-theme
        self.modules.nixos.home
      ];

      # ── Minimal system eval ───────────────────────────────────────────────────
      # We define a minimal module that just uses the theme system.
      evalSystem =
        modules:
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = coreModules ++ modules;
        };

      # ── Preset Check Assertion Logic ──────────────────────────────────────────
      # Check if preset has ALL required fields.
      checkPreset =
        name: preset:
        let
          requiredColors = [
            "background"
            "foreground"
            "cursor"
            "color0"
            "color1"
            "color2"
            "color3"
            "color4"
            "color5"
            "color6"
            "color7"
            "color8"
            "color9"
            "color10"
            "color11"
            "color12"
            "color13"
            "color14"
            "color15"
          ];
          missingColors = builtins.filter (c: !builtins.hasAttr c preset.colors) requiredColors;
          missingRoot = builtins.filter (f: !builtins.hasAttr f preset) [
            "fonts"
            "gtk"
            "rofiSemantic"
            "backgroundAlpha"
          ];
        in
        {
          check = (missingColors == [ ]) && (missingRoot == [ ]);
          name = name;
          message = "Preset ${name} missing fields: colors:${builtins.toString missingColors} root:${builtins.toString missingRoot}";
        };

      # ── Run Evaluations ───────────────────────────────────────────────────────
      nixosEval = evalSystem [{ jvf.core.host = "test-host"; }];

      presets = nixosEval.config.jvf.theme.presets;

      assertions = [
        (checkPreset "tokyonight-night" presets.tokyonight-night)
        (checkPreset "tokyonight-day" presets.tokyonight-day)
      ];

      failed = builtins.filter (a: !a.check) assertions;
    in
    {
      checks.theme-presets = pkgs.runCommand "theme-presets-check" { } ''
        ${
          if failed != [ ] then
            ''echo "Theme preset check failed: ${(builtins.head failed).message}"; exit 1''
          else
            "touch $out"
        }
      '';
    };
}
