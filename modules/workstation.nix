{ wat, ... }:
{
  flake.nixosModules.workstation = wat.mkModuleWrapped [ "workstation" ] (
    {
      cfg,
      flakes,
      lib,
      pkgs,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      inputs = flakes;
    in
    {
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
        packages = [
          pkgs.aichat
          pkgs.anki-bin
          #atopile
          pkgs.cabal-install
          (pkgs.mkOnDemand { pkg = pkgs.code-cursor; })
          pkgs.crush
          pkgs.direnv
          pkgs.discord
          pkgs.element-desktop
          # ente-desktop  # electron-41.10.6 is EOL
          pkgs.entr
          pkgs.file
          pkgs.fnm
          pkgs.fzf
          (pkgs.mkOnDemand { pkg = pkgs.gitbutler; })
          pkgs.git-filter-repo
          pkgs.git-revise
          pkgs.github-cli
          (pkgs.mkOnDemand { pkg = pkgs.kicad; })
          pkgs.kubectl
          pkgs.launch-cadquery
          pkgs.ldns
          pkgs.lens
          pkgs.libfaketime
          pkgs.lua-language-server
          pkgs.mqttx
          pkgs.mqttx-cli
          pkgs.mumble
          pkgs.nil
          pkgs.nixfmt
          pkgs.nixfmt-tree
          pkgs.obsidian
          pkgs.opencode
          pkgs.orca-slicer
          pkgs.pass
          pkgs.podman
          pkgs.podman-compose
          pkgs.podman-desktop
          pkgs.prusa-slicer
          pkgs.pyright
          pkgs.signal-desktop
          pkgs.sops
          pkgs.stylua
          pkgs.telegram-desktop
          pkgs.thunderbird
          pkgs.tinymist
          pkgs.typescript-language-server
          pkgs.typst
          pkgs.typst-languagetool
          pkgs.typst-languagetool-lsp
          pkgs.usbutils
          pkgs.virt-manager
          pkgs.vscode
          inputs.nixwrap.packages.${system}.wrap
        ];
      };

      programs.zsh.shellInit = ''
        eval "$(fnm env --use-on-cd)"
      '';
    }

  );
}
