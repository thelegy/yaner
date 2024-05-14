{
  systemd,
  writeScript,
  writeScriptBin,
  zsh,
}: let
  innerScript = writeScript "with-scope-inner" ''
    #!${zsh}/bin/zsh

    unit_name=''${$(</proc/self/cgroup)##*/}

    TRAPEXIT() {
      ${systemd}/bin/systemctl --user stop $unit_name 2>/dev/null || true
    }

    # No `exec`, as this will negate the effects of the trap
    $@
    exit $?
  '';
in
  writeScriptBin "with-scope" ''
    #!${zsh}/bin/zsh

    set -euo pipefail

    usage() {
      echo "Usage: $0 [-s/--scope <scope_name>] <command...>"
      exit 1
    }

    zparseopts -D -F -A opts - s:=scope -scope:=scope || usage

    # at least one positional argument is required
    (( $# < 1 )) && usage

    args=()

    if (( $#scope > 0 )) {
      # forbid multiple scope flags (each takes 2 slots in the array)
      (( $#scope != 2 )) && usage
      args+=("--unit=''${scope[2]}.scope")
    }

    exec ${systemd}/bin/systemd-run --user --scope --collect $args ${innerScript} $@
  ''
