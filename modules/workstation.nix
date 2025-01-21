{
  mkTrivialModule,
  config,
  options,
  pkgs,
  ...
}:
mkTrivialModule {
  wat.thelegy.cups.enable = true;
  wat.thelegy.desktop.enable = true;
  wat.thelegy.irb-kerberos.enable = true;
  wat.thelegy.steam.enable = true;

  nixpkgs.config.allowUnfree = true;

  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = lib.mkOverride 500 524288;
  };

  environment.systemPackages = [pkgs.man-pages pkgs.man-pages-posix];
  documentation.dev.enable = true;

  services.udev.packages = [
    pkgs.probe-rs-udev
  ];

  users.users.beinke = {
    packages = with pkgs; [
      alejandra
      anki-bin
      #atopile
      cabal-install
      direnv
      element-desktop
      entr
      file
      fzf
      git-filter-repo
      git-revise
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
      obsidian
      pass
      preprocess-cancellation
      prusa-slicer
      pyright
      signal-desktop
      sops
      stylua
      tdesktop
      thunderbird
      tinymist
      typst
      typst-languagetool
      typst-languagetool-lsp
      vscode
      zotero
    ];
  };
}
