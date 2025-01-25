{ lib, config, pkgs, mkTrivialModule, ... }:
with lib;

mkTrivialModule {

  wat.thelegy.emergencyStorage.enable = mkDefault true;
  wat.thelegy.firewall.enable = mkDefault true;
  wat.thelegy.homeManager.enable = true;
  wat.thelegy.hosts.enable = mkDefault true;
  wat.thelegy.monitoring.enable = mkDefault true;
  wat.thelegy.monitoring-smart.enable = mkDefault true;
  wat.thelegy.tailscale.enable = mkDefault true;
  wat.thelegy.zsh.enable = mkDefault true;

  boot.kernelPackages = mkDefault pkgs.linuxPackages_latest;

  # Restore systemd default
  services.logind.killUserProcesses = mkDefault true;

  sops.defaultSopsFile = config.wat.machines.${config.networking.hostName}."secrets.yaml".file;

  networking.domain = mkDefault "0jb.de";
  networking.search = [ "0jb.de" ];

  console = {
    font = "Lat2-Terminus16";
    keyMap = "de-latin1-nodeadkeys";
    # Gruvbox tty colors
    colors = [ "000000" "cc241d" "98971a" "d79921" "458588" "b16286" "689d6a" "a89984" "928374" "fb4934" "b8bb26" "fabd2f" "83a598" "d3869b" "8ec07c" "ebdbb2" ];
  };
  time.timeZone = "Europe/Berlin";

  boot.tmp.useTmpfs = true;

  services = {
    acpid.enable = mkDefault true;
    avahi.enable = mkDefault true;
  };

  services.openssh = mkDefault {
    enable = true;
    settings.PasswordAuthentication = true;
    settings.KbdInteractiveAuthentication = true;
  };

  hardware.rasdaemon.enable = mkDefault true;
  systemd.services.rasdaemon = {
    serviceConfig = {
      RestartSec = "20s";
      StartLimitIntervalSec = "1h";
      StartLimitBurst = 100;
    };
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="nvme", GROUP="disk"
  '';

  programs = {
    less.enable = true;
    mtr.enable = true;
    ssh.package = pkgs.opensshWithKerberos;
    tmux.enable = true;
  };

  environment.shellInit = ''
    PATH=~/.local/bin:$PATH
    export PATH
  '';

  documentation.man.generateCaches = mkDefault true;

  users.mutableUsers = false;
  users.users.beinke = {
    uid = 1000;
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    hashedPassword = "$6$rounds=424242$4XeOOipFMr154yFt$duKTFu2mSR9LnrGILjgumlxl8FltvCo9RBjhWi1N56avEVaAJym3LFlw3y2.JMCVYAO2ZpK75eF7B/7cSu5rR0";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAPiDlbJKEnmM2G8Br8Yj2M+cIEyTXqP4qJM6+gBQ1pm beinke@sirrah"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMCC4cFL1xcZOsIzXg1b/M4b89ofMKErNhg9s+0NdBVC beinke@th1"
    ];
    packages = with pkgs; [
      xdg-utils
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAPiDlbJKEnmM2G8Br8Yj2M+cIEyTXqP4qJM6+gBQ1pm beinke@sirrah"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMCC4cFL1xcZOsIzXg1b/M4b89ofMKErNhg9s+0NdBVC beinke@th1"
  ];

  nix.settings.auto-optimise-store = true;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  nix.package = pkgs.lix;

  environment.systemPackages = with pkgs; [
    git
    gnupg
    hdparm
    htop
    inxi-full
    kitty.terminfo
    lazygit
    lm_sensors
    neovim-thelegy
    reptyr
    ripgrep
    smartmontools
    tig
    w3m
    with-scope
  ];
}
