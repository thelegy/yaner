{
  mkTrivialModule,
  config,
  lib,
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

  environment.systemPackages = [
    pkgs.man-pages
    pkgs.man-pages-posix
  ];
  documentation.dev.enable = true;

  services.udev.packages = [
    pkgs.probe-rs-udev
  ];

  virtualisation.containers.enable = true;

  programs.nix-ld.enable = true;

  users.users.beinke = {
    packages = with pkgs; [
      anki-bin
      #atopile
      cabal-install
      direnv
      element-desktop
      entr
      file
      fnm
      fzf
      gitbutler
      git-filter-repo
      git-revise
      kicad-small
      kubectl
      launch-cadquery
      ldns
      lens
      libfaketime
      lua-language-server
      mqttx
      mqttx-cli
      mumble
      nil
      nixGL
      nixfmt-rfc-style
      nixpkgs-fmt
      obsidian
      orca-slicer
      pass
      podman
      podman-desktop
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
      virt-manager
      vscode
      zotero
    ];
  };

  programs.zsh.shellInit = ''
    eval "$(fnm env --use-on-cd)"
  '';
}
