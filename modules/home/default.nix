# Aspect: home
# Per-user home file materialization — option schema + sugar shortcuts + _compiled output.
# Activation scripts (T2) are included here.
_:
let
  # ── Option definitions only (no config values set here) ──────────────────
  mkHomeOption =
    { lib, ... }:
    let
      itemSpecSubmodule = lib.types.submodule (_: {
        options = {
          kind = lib.mkOption {
            type = lib.types.enum [
              "file"
              "dir"
            ];
            description = "Whether the target is a regular file or a directory tree.";
          };

          mode = lib.mkOption {
            type = lib.types.enum [
              "copy"
              "link"
              "seed"
            ];
            default = "copy";
            description = ''
              Materialization mode:
                copy — copy from store into home (replace-on-rebuild)
                link — symlink from home into store (always-current)
                seed — copy only if target does not exist (one-shot bootstrap)
            '';
          };

          source = lib.mkOption {
            type = lib.types.nullOr (
              lib.types.oneOf [
                lib.types.path
                lib.types.package
                lib.types.str
              ]
            );
            default = null;
            description = "Store path, derivation, or string store path to use as content source.";
          };

          text = lib.mkOption {
            type = lib.types.nullOr lib.types.lines;
            default = null;
            description = "Inline text content (file only).";
          };

          json = lib.mkOption {
            type = lib.types.nullOr lib.types.attrs;
            default = null;
            description = "Attrset to serialize as JSON.";
          };

          yaml = lib.mkOption {
            type = lib.types.nullOr lib.types.attrs;
            default = null;
            description = "Attrset to serialize as YAML.";
          };

          toml = lib.mkOption {
            type = lib.types.nullOr lib.types.attrs;
            default = null;
            description = "Attrset to serialize as TOML.";
          };

          ini = lib.mkOption {
            type = lib.types.nullOr lib.types.attrs;
            default = null;
            description = "Attrset to serialize as INI.";
          };

          preserve = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Sub-paths to preserve from previous installation (dir only).";
          };

          postInstall = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Shell script to run after installing this item.";
          };
        };
      });

      userSubmodule = lib.types.submodule (_: {
        options.items = lib.mkOption {
          type = lib.types.attrsOf itemSpecSubmodule;
          default = { };
          description = "Items to materialize keyed by relative target path under $HOME.";
        };
      });
    in
    {
      options.jvf.home = {
        # ── Multi-user namespace ────────────────────────────────────────────────
        users = lib.mkOption {
          type = lib.types.attrsOf userSubmodule;
          default = { };
          description = "Per-user item sets keyed by username.";
        };

        # ── Sugar: default-user shortcuts ───────────────────────────────────────
        files = lib.mkOption {
          type = lib.types.attrsOf itemSpecSubmodule;
          default = { };
          description = ''
            Shortcut: items for the default user (config.jvf.core.username).
            Keys are relative paths under $HOME.
          '';
        };

        xdg = {
          config = lib.mkOption {
            type = lib.types.attrsOf itemSpecSubmodule;
            default = { };
            description = "Shortcut: items installed under $HOME/.config/<rel>.";
          };

          data = lib.mkOption {
            type = lib.types.attrsOf itemSpecSubmodule;
            default = { };
            description = "Shortcut: items installed under $HOME/.local/share/<rel>.";
          };

          state = lib.mkOption {
            type = lib.types.attrsOf itemSpecSubmodule;
            default = { };
            description = "Shortcut: items installed under $HOME/.local/state/<rel>.";
          };

          cache = lib.mkOption {
            type = lib.types.attrsOf itemSpecSubmodule;
            default = { };
            description = "Shortcut: items installed under $HOME/.cache/<rel>.";
          };
        };

        # ── Compiled output (set exclusively by mkHomeConfig, never by consumers) ─
        _compiled = lib.mkOption {
          type = lib.types.attrs;
          readOnly = true;
          internal = true;
          description = "Compiled item lists per user. Do not set manually.";
        };
      };
    };

  # ── Platform-aware implementation (imports mkHomeOption) ─────────────────
  mkHomeConfig =
    { isDarwin }:
    { lib
    , config
    , pkgs
    , ...
    }:
    let
      defaultUser = config.jvf.core.username;

      # Sanitize a relative target path to a safe store name segment
      sanitizeRel = rel: builtins.replaceStrings [ "/" " " "." ] [ "-" "-" "-" ] rel;

      # Resolve item content to a Nix store path
      resolveSource =
        userName: relTarget: item:
        let
          s = sanitizeRel relTarget;
        in
        if item.source != null then
          item.source
        else if item.text != null then
          pkgs.writeText "jvf-home-${userName}-${s}" item.text
        else if item.json != null then
          (pkgs.formats.json { }).generate "jvf-home-${s}.json" item.json
        else if item.yaml != null then
          (pkgs.formats.yaml { }).generate "jvf-home-${s}.yaml" item.yaml
        else if item.toml != null then
          (pkgs.formats.toml { }).generate "jvf-home-${s}.toml" item.toml
        else if item.ini != null then
          (pkgs.formats.ini { }).generate "jvf-home-${s}.ini" item.ini
        else
          throw "jvf.home: item '${relTarget}' for user '${userName}' has no content source (source/text/json/yaml/toml/ini)";

      # Compile a single user's items to a list with absolute paths
      compileUserItems =
        userName: userCfg:
        let
          home =
            config.users.users.${userName}.home
              or (if isDarwin then "/Users/${userName}" else "/home/${userName}");
        in
        {
          items = lib.mapAttrsToList
            (relTarget: item: {
              targetRel = relTarget;
              targetAbs = "${home}/${relTarget}";
              inherit (item)
                kind
                mode
                preserve
                postInstall
                ;
              sourcePath = resolveSource userName relTarget item;
            })
            userCfg.items;
        };

      # Expand sugar shortcuts into items for the default user
      sugarItems =
        lib.mapAttrs (_rel: item: item) config.jvf.home.files
        // lib.mapAttrs' (rel: item: lib.nameValuePair ".config/${rel}" item) config.jvf.home.xdg.config
        // lib.mapAttrs' (rel: item: lib.nameValuePair ".local/share/${rel}" item) config.jvf.home.xdg.data
        // lib.mapAttrs' (rel: item: lib.nameValuePair ".local/state/${rel}" item) config.jvf.home.xdg.state
        // lib.mapAttrs' (rel: item: lib.nameValuePair ".cache/${rel}" item) config.jvf.home.xdg.cache;

      hasSugar =
        config.jvf.home.files != { }
        || config.jvf.home.xdg.config != { }
        || config.jvf.home.xdg.data != { }
        || config.jvf.home.xdg.state != { }
        || config.jvf.home.xdg.cache != { };

      # Final per-user items after merging sugar into the default user
      effectiveUsers =
        if !hasSugar then
          config.jvf.home.users
        else
          let
            existing = (config.jvf.home.users.${defaultUser} or { items = { }; }).items;
          in
          config.jvf.home.users
          // {
            ${defaultUser}.items = existing // sugarItems;
          };

      # ── Compile-time assertions ─────────────────────────────────────────────

      # No target may be a path-prefix of another target for the same user
      overlapAssertions = lib.flatten (
        lib.mapAttrsToList
          (
            userName: userCfg:
              let
                keys = lib.attrNames userCfg.items;
                pairs = lib.flatten (map (a: map (b: { inherit a b; }) keys) keys);
                conflicting = lib.filter
                  (
                    p: p.a != p.b && (lib.hasPrefix (p.a + "/") p.b || lib.hasPrefix (p.b + "/") p.a)
                  )
                  pairs;
              in
              map
                (p: {
                  assertion = false;
                  message = "jvf.home: user '${userName}' has overlapping targets '${p.a}' and '${p.b}'";
                })
                conflicting
          )
          effectiveUsers
      );

      # preserve must be [] when kind == "file"
      preserveAssertions = lib.flatten (
        lib.mapAttrsToList
          (
            userName: userCfg:
              lib.mapAttrsToList
                (relTarget: item: {
                  assertion = !(item.kind == "file" && item.preserve != [ ]);
                  message = "jvf.home: item '${relTarget}' for user '${userName}' has kind=file but preserve is non-empty (only valid for kind=dir)";
                })
                userCfg.items
          )
          effectiveUsers
      );

      # Exactly one of source/text/json/yaml/toml/ini must be non-null
      contentAssertions = lib.flatten (
        lib.mapAttrsToList
          (
            userName: userCfg:
              lib.mapAttrsToList
                (
                  relTarget: item:
                    let
                      count = builtins.length (
                        lib.filter (x: x != null) [
                          item.source
                          item.text
                          item.json
                          item.yaml
                          item.toml
                          item.ini
                        ]
                      );
                    in
                    {
                      assertion = count == 1;
                      message =
                        if count == 0 then
                          "jvf.home: item '${relTarget}' for user '${userName}' has no content source — set exactly one of: source, text, json, yaml, toml, ini"
                        else
                          "jvf.home: item '${relTarget}' for user '${userName}' has ${toString count} content sources — set exactly one of: source, text, json, yaml, toml, ini";
                    }
                )
                userCfg.items
          )
          effectiveUsers
      );

      # link + preserve: symlinks ignore preserve, warn via assertion
      linkPreserveAssertions = lib.flatten (
        lib.mapAttrsToList
          (
            userName: userCfg:
              lib.mapAttrsToList
                (relTarget: item: {
                  assertion = !(item.mode == "link" && item.preserve != [ ]);
                  message = "jvf.home: item '${relTarget}' for user '${userName}' has mode=link with preserve set — preserve is ignored for symlinks";
                })
                userCfg.items
          )
          effectiveUsers
      );
    in
    let
      # ── Activation script generation ────────────────────────────────────────

      mkUserActivation =
        userName: compiledUserCfg:
        let
          home =
            config.users.users.${userName}.home
              or (if isDarwin then "/Users/${userName}" else "/home/${userName}");
          group = config.users.users.${userName}.group or (if isDarwin then "staff" else "users");
          isDarwinStr = if isDarwin then "1" else "0";
        in
        "(\n"
        + ''
          set -euo pipefail
          USER_NAME=${lib.escapeShellArg userName}
          GROUP_NAME=${lib.escapeShellArg group}
          HOME_DIR=${lib.escapeShellArg home}
          IS_DARWIN=${isDarwinStr}
        ''
        + lib.concatMapStringsSep "\n"
          (
            item:
            let
              target = lib.escapeShellArg item.targetAbs;
              src = lib.escapeShellArg (toString item.sourcePath);
              preserveScript = lib.concatMapStringsSep "\n"
                (sub: ''
                  if [ -n "$BACKUP_DIR" ] && [ -e "$BACKUP_DIR/${sub}" ]; then
                    echo "[jvf.home] Restoring preserved: ${sub}"
                    rm -rf ${lib.escapeShellArg item.targetAbs}/${sub}
                    cp -r "$BACKUP_DIR/${sub}" ${lib.escapeShellArg item.targetAbs}/${sub}
                    chown -R "$USER_NAME:$GROUP_NAME" ${lib.escapeShellArg item.targetAbs}/${sub}
                  fi
                '')
                item.preserve;
              postInstallScript = lib.optionalString (item.postInstall != "") ''
                TARGET_PATH=${target}
                BACKUP_DIR="${"$"}{BACKUP_DIR:-}"
                ${item.postInstall}
              '';
            in
            if item.mode == "link" then
              ''
                echo "[jvf.home] Linking ${item.targetRel} -> ${item.sourcePath}"
                mkdir -p "$(dirname ${target})"
                ln -sfn ${src} ${target}
              ''
            else if item.kind == "file" then
              (
                if item.mode == "seed" then
                  ''
                    if [ ! -e ${target} ]; then
                      echo "[jvf.home] Seeding ${item.targetRel}"
                      mkdir -p "$(dirname ${target})"
                      cp ${src} ${target}
                      chown "$USER_NAME:$GROUP_NAME" ${target}
                      chmod 644 ${target}
                      TARGET_PATH=${target}
                      BACKUP_DIR=""
                      ${item.postInstall}
                    else
                      echo "[jvf.home] Skipping (seed) ${item.targetRel} -- already exists"
                    fi
                  ''
                else
                  ''
                    echo "[jvf.home] Copying file ${item.targetRel}"
                    mkdir -p "$(dirname ${target})"
                    cp ${src} ${target}.tmp
                    chown "$USER_NAME:$GROUP_NAME" ${target}.tmp
                    chmod 644 ${target}.tmp
                    if [ -e ${target} ] && diff -q ${target}.tmp ${target} >/dev/null 2>&1; then
                      echo "[jvf.home] Unchanged ${item.targetRel}, skipping"
                      rm -f ${target}.tmp
                    else
                      mv -f ${target}.tmp ${target}
                      TARGET_PATH=${target}
                      BACKUP_DIR=""
                      ${item.postInstall}
                    fi
                  ''
              )
            else
              (
                # kind == dir
                if item.mode == "seed" then
                  ''
                    if [ ! -d ${target} ]; then
                      echo "[jvf.home] Seeding dir ${item.targetRel}"
                      mkdir -p ${target}
                      cp -rL ${src}/. ${target}/
                      chown -R "$USER_NAME:$GROUP_NAME" ${target}
                      find ${target} -type d -exec chmod 755 {} \;
                      find ${target} -type f -exec chmod 644 {} \;
                      TARGET_PATH=${target}
                      BACKUP_DIR=""
                      ${item.postInstall}
                    else
                      echo "[jvf.home] Skipping (seed) dir ${item.targetRel} -- already exists"
                    fi
                  ''
                else
                  ''
                    echo "[jvf.home] Syncing dir ${item.targetRel}"
                    TARGET_TMP=${target}.tmp
                    rm -rf "$TARGET_TMP"
                    mkdir -p "$TARGET_TMP"
                    cp -rL ${src}/. "$TARGET_TMP/"
                    chown -R "$USER_NAME:$GROUP_NAME" "$TARGET_TMP"
                    find "$TARGET_TMP" -type d -exec chmod 755 {} \;
                    find "$TARGET_TMP" -type f -exec chmod 644 {} \;
                    if [ -d ${target} ] && diff -r -q "$TARGET_TMP" ${target} >/dev/null 2>&1; then
                      echo "[jvf.home] Dir ${item.targetRel} unchanged, skipping"
                      rm -rf "$TARGET_TMP"
                    else
                      BACKUP_DIR=""
                      if [ -e ${target} ] && [ ! -L ${target} ]; then
                        BACKUP_TIMESTAMP=$(date +%s)
                        BACKUP_DIR=${target}.backup.$BACKUP_TIMESTAMP
                        echo "[jvf.home] Backing up ${item.targetRel} -> $BACKUP_DIR"
                        rm -rf ${target}.backup.*
                        mv -f ${target} "$BACKUP_DIR"
                      fi
                      rm -rf ${target}
                      mv -f "$TARGET_TMP" ${target}
                      ${preserveScript}
                      TARGET_PATH=${target}
                      ${item.postInstall}
                    fi
                  ''
              )
          )
          compiledUserCfg.items
        + "\n)";

      # Check if a compiled user has any items
      hasItems = compiledUserCfg: (compiledUserCfg.items or [ ]) != [ ];

      compiledUsers = lib.mapAttrs (userName: userCfg: compileUserItems userName userCfg) effectiveUsers;
    in
    {
      imports = [ mkHomeOption ];
      config = lib.mkMerge (
        [
          {
            # Wire sugar shortcuts into the default user's items namespace
            jvf.home.users = lib.mkIf hasSugar {
              ${defaultUser}.items = sugarItems;
            };

            # Compiled output with platform-correct absolute paths
            jvf.home._compiled.users = compiledUsers;

            assertions = overlapAssertions ++ preserveAssertions ++ contentAssertions ++ linkPreserveAssertions;
          }
        ]
        ++ lib.optional isDarwin {
          system.activationScripts.postActivation.text = lib.concatStringsSep "\n" (
            lib.flatten (
              lib.mapAttrsToList
                (
                  userName: compiledUserCfg:
                    if !(hasItems compiledUserCfg) then [ ] else [ (mkUserActivation userName compiledUserCfg) ]
                )
                compiledUsers
            )
          );
        }
        ++ lib.optional (!isDarwin) {
          system.activationScripts = lib.mkMerge (
            lib.mapAttrsToList
              (
                userName: compiledUserCfg:
                  if !(hasItems compiledUserCfg) then
                    { }
                  else
                    {
                      "jvf-home-${userName}" = {
                        supportsDryActivation = true;
                        deps = [ "users" ];
                        text = mkUserActivation userName compiledUserCfg;
                      };
                    }
              )
              compiledUsers
          );
        }
      );
    };
in
{
  flake.modules.nixos.home = mkHomeConfig { isDarwin = false; };
  flake.modules.darwin.home = mkHomeConfig { isDarwin = true; };
}
