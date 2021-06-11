{ lib, writeScript, zsh, playerctl, ponymix }:

writeScript "media-volume" ''
  #!${zsh}/bin/zsh
  PATH=${playerctl}/bin:${ponymix}/bin
  playerctl_args=(--ignore-player=chromium)

  if [[ "$(playerctl $playerctl_args -l)" == "spotify" ]]; then
    # Change spotify volume
    if (( $1 >= 0 )); then
      ponymix --sink-input --device Spotify increase "$(($1 * 100))"
    else
      ponymix --sink-input --device Spotify decrease "$((- $1 * 100))"
    fi
  else
    # Change volume with playerctl
    cmd="$(($1))+"
    (( $1 < 0 )) && cmd="$((-$1))-"
    playerctl --ignore-player=chromium volume $cmd
  fi
''
