{ lib, mkTrivialModule, pkgs, ... }:
with lib;

mkTrivialModule {

  programs.zsh = {

    enable = true;

    histSize = 1000000;

    shellInit = ''
      _exists () (( $+commands[$1] ))
    '';

    promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";

    shellAliases = {
      cal = "cal --monday";
      l = "ls -Alh";
      la = "ls -al";
      ll = "ls -l";
      lg = "lazygit";
    };

    setOptions = [
      "GLOB_STAR_SHORT"
      "HIST_FCNTL_LOCK"
      "INC_APPEND_HISTORY"
      "HIST_FIND_NO_DUPS"
      "HIST_IGNORE_DUPS"
      "HIST_IGNORE_SPACE"
      "HIST_REDUCE_BLANKS"
      "AUTO_CONTINUE"
    ];

    interactiveShellInit = ''

      if {_exists direnv} {
        eval "$(direnv hook zsh)"
        # Manually call the hook to ensure it is not run while the instant prompt is shown
        _direnv_hook
      }

      # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
      # Initialization code that may require console input (password prompts, [y/n]
      # confirmations, etc.) must go above this block; everything else may go below.
      if [[ -r ''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh ]] {
        source ''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh
      }

      export MANPAGER='nvim +Man!'
      export MANWIDTH=999

      export EDITOR=vi
      _exists vim && EDITOR=vim
      _exists nvim && EDITOR=nvim
      export VISUAL=$EDITOR

      bindkey -e

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
        if [[ $# != 1 || -z $1 || -d $1 || $1 == "-" ]] {
          builtin cd $@
        } elif { _exists $1 } {
          builtin cd ''${1:c:A:h}
        } elif [[ -e $1 ]] {
          builtin cd ''${1:h}
        } else {
          builtin cd $1
        }
      }

      pastebin () {
        readonly pastebin='https://0x0.st'
        readonly cmdName=$0
        readonly usage="Usage: $cmdName [-s|--sign] [-h|--help] [FILENAME]"
        if { [[ ''${1:-} == '-s' || ''${1:-} == '--sign' ]] && _exists gpg } {
          shift
          readonly filter='gpg --clearsign --output -'
        }
        [[ $# > 1 ]] && echo $usage && return 1
        [[ ''${1:-} == '-h' || ''${1:-} == '--help' ]] && echo $usage && return 0
        ''${=filer:-cat} ''${1:-} | curl -F'file=@-' $pastebin
      }

      if [[ -f ~/.p10k.zsh ]] {
        source ~/.p10k.zsh
      }

    '';

  };

}
