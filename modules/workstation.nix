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
      anki-bin
      cabal-install
      launch-cadquery
      direnv
      file
      fzf
      git-filter-repo
      git-revise
      kicad-small
      joplin
      joplin-desktop
      ldns
      libfaketime
      nixpkgs-fmt
      pass
      preprocess-cancellation
      prusa-slicer
      pyright
      rnix-lsp
      signal-desktop
      sops
      stack
      tdesktop
      thunderbird
      vscode
      mumble
    ];
  };

}
