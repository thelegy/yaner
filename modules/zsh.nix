{ lib, mkTrivialModule, pkgs, ... }:
with lib;

mkTrivialModule {

  programs.zsh = {

    enable = true;

    shellInit = ''
      _exists () (( $+commands[$1] ))
    '';

    promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";

    shellAliases = {
      cal = "cal --monday";
      l = "ls -Alh";
      la = "ls -al";
      ll = "ls -l";
    };

    interactiveShellInit = ''
      _exists direnv && eval "$(direnv hook zsh)"
      _exists w3mman && alias man=w3mman

      export EDITOR=vi
      _exists vim && EDITOR=vim
      _exists nvim && EDITOR=nvim
      export VISUAL=$EDITOR

      hash -d yaner=~/repos/yaner

      tmp () (
        readonly tmpdir=$(mktemp -d ''${1:-})
        [[ -z $tmpdir ]] && exit 1
        TRAPEXIT() {
          rm -rf $tmpdir
        }
        cd $tmpdir
        zsh -is
      )

      cd () {
        if [[ $# != 1 || -z $1 || -d $1 || $1 == "-" ]]; then
          builtin cd $@
        elif _exists $1; then
          builtin cd ''${1:c:A:h}
        elif [[ -e $1 ]]; then
          builtin cd ''${1:h}
        else
          builtin cd $1
        fi
      }
    '';

  };

}
