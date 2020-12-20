{ config, options, pkgs, ... }:

{

  imports = [
    ../desktop
    ../steam
  ];

  nixpkgs.config.allowUnfree = true;

  boot.kernel.sysctl = options.boot.kernel.sysctl.default // {
    "fs.inotify.max_user_watches" = 524288;
  };

  users.users.beinke = {
    packages = with pkgs; [
      cabal-install
      direnv
      file
      fzf
      git-revise
      ghcid
      haskell-language-server
      kicad
      ldns
      signal-desktop
      stack
      tdesktop
      thunderbird
      vscode
      mumble
    ];
  };

}
