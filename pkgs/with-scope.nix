{
  writeScriptBin,
  zsh,
  systemd
}:

writeScriptBin "with-scope" ''
  #!${zsh}/bin/zsh

  set -euo pipefail

  usage() {
    echo "Usage: $0 <unit_name> <command...>"
    exit 1
  }

  (( $# <= 2 )) && usage

  unit_name=$1.scope

  if [[ ! -v WITH_SCOPE_INNER ]] {
    WITH_SCOPE_INNER=1 exec ${systemd}/bin/systemd-run --user --scope --unit=$unit_name --collect $0 $@
    exit 0  # impossible because of the exec
  }

  shift  # shift past the unit name

  TRAPEXIT() {
    ${systemd}/bin/systemctl --user stop $unit_name 2>/dev/null || true
  }

  $@
  exit $?
''
