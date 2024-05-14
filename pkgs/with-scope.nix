{
  systemd,
  writeScriptBin,
  zsh,
}:
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

  unit_name="with-scope-%"

  if (( $#scope > 0 )) {
    # forbid multiple scope flags (each takes 2 slots in the array)
    (( $#scope != 2 )) && usage
    unit_name=''${scope[2]}
  }

  unit=''${unit_name//\%/$RANDOM}.scope

  TRAPEXIT() {
    ${systemd}/bin/systemctl --user stop $unit_name 2>/dev/null || true
  }

  set +e

  # no exec because of the trap
  ${systemd}/bin/systemd-run --user --scope --collect --unit=$unit $@

  exit $?
''
