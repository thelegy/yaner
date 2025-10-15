{
  config,
  lib,
  mkTrivialModule,
  pkgs,
  ...
}:
with lib;

let

  toml = pkgs.formats.toml { };

  direnvConfigFile = toml.generate "direnv.toml" {
    global.hide_env_diff = true;
  };
  direnvConfig = pkgs.runCommandLocal "direnv" { } ''
    mkdir $out
    cp ${direnvConfigFile} $out/direnv.toml
  '';

in
mkTrivialModule {

  programs.foot.enableZshIntegration = false;
  programs.starship = {
    enable = true;
    presets = [
      "nerd-font-symbols"
    ];
    settings = {
      nix_shell.impure_msg = "";
    };
  };

  programs.zsh = {

    enable = true;

    histSize = 1000000;

    shellInit = ''
      _exists () (( $+commands[$1] ))

      # Disable new-user configuration
      zsh-newuser-install() { :; }

      bindkey -e
    '';

    shellAliases = {
      cal = "cal --monday";
      diff = "diff --color=auto";
      ip = "ip --color=auto";
      l = "ls -Alh";
      la = "ls -al";
      lg = "lazygit";
      ll = "ls -l";
      rg = "rg -S";
      icat = "print; ncplayer -k -t0 -q -b pixel -s none";
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

      key[C-Left]=''${terminfo[kLFT5]}
      key[C-Right]=''${terminfo[kRIT5]}
      key[C-Up]=''${terminfo[kUP5]}
      key[C-Down]=''${terminfo[kDN5]}

      if {_exists direnv} {
        export DIRENV_CONFIG=${direnvConfig}
        eval "$(direnv hook zsh)"
        # Manually call the hook to ensure it is not run while the instant prompt is shown
        _direnv_hook
      }

      # OSS7 Integration, e.g. for foot
      _osc7-pwd () {
        emulate -L zsh # also sets localoptions for us
        setopt extendedglob
        local LC_ALL=C
        printf '\e]7;file://%s%s\e\' ''${(%):-%m} ''${PWD//(#m)([^@-Za-z&-;_~])/%''${(l:2::0:)$(([##16]#MATCH))}}
      }

      _osc7-pwd

      export MANPAGER='nvim +Man!'
      export MANWIDTH=999

      export EDITOR=vi
      _exists vim && EDITOR=vim
      _exists nvim && EDITOR=nvim
      export VISUAL=$EDITOR

      # extra navigation keys
      [[ -n "''${key[C-Left]}" ]] && bindkey ''${key[C-Left]} emacs-backward-word
      [[ -n "''${key[C-Right]}" ]] && bindkey ''${key[C-Right]} emacs-forward-word

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

      _chpwd-osc7-pwd () {
        (( ZSH_SUBSHELL )) || _osc7-pwd
      }
      autoload -U add-zsh-hook
      add-zsh-hook -Uz chpwd _chpwd-osc7-pwd

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

    '';

  };

}
