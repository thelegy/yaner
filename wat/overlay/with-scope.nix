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

  zparseopts -D -F - s:=scope -scope:=scope || usage

  # at least one positional argument is required
  (( $# < 1 )) && usage

  unit_name="with-scope-%"

  if (( $#scope > 0 )) {
    # forbid multiple scope flags (each takes 2 slots in the array)
    (( $#scope != 2 )) && usage
    unit_name=$scope[2]
  }

  random=$(${systemd}/bin/systemd-id128 new)
  unit=''${unit_name//\%/$random}.scope

  cleanup() {
    ${systemd}/bin/systemctl --user stop $unit 2>/dev/null || true
  }
  trap cleanup EXIT INT QUIT TERM

  set +e

  # no exec because of the trap
  ${systemd}/bin/systemd-run --user --scope --collect --unit=$unit $@

  exit $?
''
