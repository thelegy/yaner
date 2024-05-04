{ mkTrivialModule
, config
, options
, pkgs
, ... }:

mkTrivialModule {

  wat.thelegy.desktop.enable = true;
  wat.thelegy.steam.enable = true;
  wat.thelegy.irb-kerberos.enable = true;

  nixpkgs.config.allowUnfree = true;

  boot.kernel.sysctl = options.boot.kernel.sysctl.default // {
    "fs.inotify.max_user_watches" = 524288;
  };

  environment.systemPackages = [ pkgs.man-pages pkgs.man-pages-posix ];
  documentation.dev.enable = true;

  users.users.beinke = {
    packages = with pkgs; [
      alejandra
      anki-bin
      atopile
      cabal-install
      direnv
      element-desktop
      entr
      file
      fzf
      git-filter-repo
      git-revise
      joplin
      joplin-desktop
      kicad-small
      launch-cadquery
      ldns
      libfaketime
      lua-language-server
      mumble
      nil
      nixGL
      nixfmt-rfc-style
      nixpkgs-fmt
      pass
      preprocess-cancellation
      prusa-slicer
      pyright
      obsidian
      signal-desktop
      sops
      stack
      stylua
      tdesktop
      thunderbird
      vscode
    ];
  };

}
