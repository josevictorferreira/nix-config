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
    ''
      set -euo pipefail
      if [ ! -d "${targetDir}" ]; then
        ${pkgs.coreutils}/bin/mkdir -p "${targetDir}"
        ${pkgs.coreutils}/bin/chown -R ${username}:${group} "${targetDir}"
        GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -o StrictHostKeyChecking=accept-new" \
        runuser -u ${username} -- \
          ${pkgs.git}/bin/git clone --depth=1 ${repo} "${targetDir}"
      fi
    '';
in
{
  inherit cloneRepoText;
}
