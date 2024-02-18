{ mkMachine, ... }:

mkMachine {} ( { lib, pkgs, config, ... }: with lib; {

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
  services.syncthing.user = "lisa";

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
    packages = with pkgs; [
      xdg_utils
    ];
  };

  nix.settings.trusted-users = [ "beinke" "lisa" ];

  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  services.xserver.displayManager.defaultSession = "plasmawayland";

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-wlr ];
  };
  environment.sessionVariables.GTK_USE_PORTAL = "1";
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  programs.ssh.setXAuthLocation = true;

  hardware.bluetooth = {
    enable = true;
  };

  # Enable udev rules for mtp and such
  services.gvfs.enable = true;

  environment.systemPackages = let
    r-custom = pkgs.rWrapper.override {
        packages = with pkgs.rPackages; [
          rlang
          tidyverse
          rstatix
          ggpubr
          rcompanion
          xtable
        ];
      };
  in with pkgs; [
    anki-bin
    chromium
    element-desktop
    entr
    firefox
    fzf
    git-filter-repo
    git-revise
    itd
    mendeley
    mpv
    mumble
    obsidian
    r-custom
    spotify
    tcpdump
    telegram-desktop
    texlive.combined.scheme-full
    thunderbird
    viddy
    vscode
  ];

})
