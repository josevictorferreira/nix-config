{ pkgs
, ...
}:

let
  cloneRepoText =
    { username
    , group
    , repo
    , targetDir
    ,
    }:
    let
      # Use runuser on Linux, sudo on macOS
      runAsUserCmd = if pkgs.stdenv.isDarwin then "sudo -u ${username}" else "runuser -u ${username}";
    in
    ''
      set -euo pipefail
      if [ ! -d "${targetDir}" ]; then
        ${pkgs.coreutils}/bin/mkdir -p "${targetDir}"
        ${pkgs.coreutils}/bin/chown -R ${username}:${group} "${targetDir}"
        GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -o StrictHostKeyChecking=accept-new" \
        ${runAsUserCmd} -- \
          ${pkgs.git}/bin/git clone --depth=1 ${repo} "${targetDir}"
      fi
    '';
in
{
  inherit cloneRepoText;
}
