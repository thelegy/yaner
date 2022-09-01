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

  environment.systemPackages = [ pkgs.man-pages pkgs.man-pages-posix ];
  documentation.dev.enable = true;

  users.users.beinke = {
    packages = with pkgs; [
      cabal-install
      direnv
      file
      fzf
      git-filter-repo
      git-revise
      ghcid
      haskell-language-server
      kicad
      ldns
      libfaketime
      signal-desktop
      stack
      tdesktop
      thunderbird
      vscode
      mumble
    ];
  };

}
