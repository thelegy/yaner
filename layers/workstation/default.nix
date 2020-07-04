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
      all-hies-latest
      direnv
      file
      fzf
      kicad
      ldns
      signal-desktop
      stack
      tdesktop
      thunderbird
      vscode
      ormolu
      mumble
    ];
  };

}
