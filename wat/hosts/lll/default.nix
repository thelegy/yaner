{ mkMachine, ... }:

mkMachine { } (
  {
    lib,
    pkgs,
    config,
    ...
  }:
  {

    system.stateVersion = "23.11";

    imports = [
      ./hardware-configuration.nix
    ];

    wat.installer.btrfs = {
      enable = true;
      luks.enable = true;
      installDisk = "/dev/disk/by-id/ata-SanDisk_SDSSDA120G_163905458411";
      swapSize = "8GiB";
    };

    wat.thelegy.workstation.enable = true;

    wat.thelegy.syncthing.enable = true;
    services.syncthing.user = "peter";

    wat.thelegy.backup = {
      enable = true;
      borgbaseRepo = "u02zl465";
      extraReadWritePaths = [
        "/.backup-snapshots"
        "/nix/.backup-snapshots"
      ];
    };

    # Enable systemd-networkd in addition to NetworkManager
    systemd.network.enable = true;
    systemd.network.wait-online.enable = false;

    services.resolved.enable = true;

    users.users.lisa = {
      uid = 1001;
      isNormalUser = true;
      #extraGroups = [ "wheel" ];
      shell = pkgs.zsh;
      hashedPassword = "$6$rounds=424242$n6onp6FmPbfv1VFb$tLW/WVJicio45CYydrhlRKZwmPMOnFZX7YdH8l1gm4Wja7VBVD5pmvG11UB.58m8Lh8DaClF10L.FtRJfKG7R0";
      packages = [
        pkgs.xdg-utils
      ];
    };

    users.users.peter = {
      uid = 1002;
      isNormalUser = true;
      #extraGroups = [ "wheel" ];
      shell = pkgs.zsh;
      hashedPassword = "$6$rounds=424242$4dgdzqgZPjX9ZH0U$.UMfnUAG2LXFCuuyrKCwH2ORViJ2hZK4coYW1ZzpACjhDsIexhRGHVuOmD/6A5B8/c8ndbdX5jZxfA8NxCcXI0";
      packages = [
        pkgs.xdg-utils
      ];
    };

    nix.settings.trusted-users = [
      "beinke"
      "lisa"
    ];

    programs.ssh.setXAuthLocation = true;

    hardware.bluetooth = {
      enable = true;
    };

    # Enable udev rules for mtp and such
    services.gvfs.enable = true;

    environment.systemPackages =
      let
        # r-custom = pkgs.rWrapper.override {
        #   packages = [
        #     pkgs.rPackages.rlang
        #     pkgs.rPackages.tidyverse
        #     pkgs.rPackages.rstatix
        #     pkgs.rPackages.ggpubr
        #     pkgs.rPackages.rcompanion
        #     pkgs.rPackages.xtable
        #   ];
        # };
      in
      [
        pkgs.anki-bin
        pkgs.chromium
        pkgs.element-desktop
        pkgs.entr
        pkgs.firefox
        pkgs.fzf
        pkgs.git-filter-repo
        pkgs.git-revise
        # mendeley
        pkgs.mpv
        # mumble
        pkgs.obsidian
        # r-custom
        pkgs.spotify
        pkgs.tcpdump
        pkgs.telegram-desktop
        # texlive.combined.scheme-full
        # thunderbird
        pkgs.viddy
        pkgs.vscode
      ];

  }
)
