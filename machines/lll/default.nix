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

  # imports = [
  #   ./hardware-configuration.nix
  # ];

  # Fix the LTE modem not being detected
  # systemd.services.NetworkManager = let
  #   modemmanager = "ModemManager.service";
  # in {
  #   after = [ modemmanager ];
  #   requires = [ modemmanager ];
  # };
  # systemd.services.ModemManager.path = [ pkgs.libqmi ];

  # services.ratbagd.enable = true;

  # wat.thelegy.hw-t470.enable = true;
  # wat.thelegy.syncthing.enable = true;
  wat.thelegy.workstation.enable = true;

  # wat.thelegy.backup = {
  #   enable = true;
  #   extraExcludes = [
  #     "/home/.pre-repair-2020-11-19"
  #   ];
  #   extraReadWritePaths = [
  #     "/.backup-snapshots"
  #     "/nix/.backup-snapshots"
  #   ];
  # };

  # wat.thelegy.roc-client = {
  #   enable = true;
  #   serverAddress = head (splitString "/" config.wat.thelegy.wg-net.rtlan.nodes.y.address);
  #   localAddress = head (splitString "/" config.wat.thelegy.wg-net.rtlan.thisNode.address);
  # };

  # boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  # boot.supportedFilesystems = [ "ntfs" ];

  # wat.thelegy.leg-net.enable = true;
  # wat.thelegy.wg-net.leg.nodes.roborock.endpoint = mkForce "localhost:2222";
  # wat.thelegy.rtlan-net.enable = true;

  # Enable systemd-networkd in addition to NetworkManager
  systemd.network.enable = true;
  systemd.network.wait-online.enable = false;

  # Networking for containers
  # networking = {
  #   nat = {
  #     enable  = true;
  #     internalInterfaces = ["ve-+"];
  #     externalInterface = "wlp4s0";
  #   };
  #   networkmanager.unmanaged = [ "interface-name:ve-*" ];
  #   networkmanager.fccUnlockScripts = [rec{
  #     id = "1199:9079";
  #     path = "${pkgs.modemmanager}/share/ModemManager/fcc-unlock.available.d/${id}";
  #   }];
  #   #networkmanager.wifi.backend = "iwd";
  # };
  services.resolved.enable = true;

  # users.users.beinke.extraGroups = [ "dialout" "adbusers" ];
  #
  # programs.adb.enable = true;

  # networking.firewall.allowedTCPPorts = [
  #   8000
  # ];
  # networking.firewall.allowedUDPPorts = [
  #   2223  # tunnelbore
  # ];

  # networking.nftables.firewall.rules.kdeconnect = {
  #   from = "all";
  #   to = [ "fw" ];
  #   allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
  #   allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
  # };

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

  # nix.buildMachines = [
  #   {
  #     hostName = "roborock";
  #     sshUser = "nix";
  #     system = "aarch64-linux";
  #     supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
  #   }
  #   {
  #     hostName = "sirrah";
  #     sshUser = "nix";
  #     systems = [
  #       "x86_64-linux"
  #       "aarch64-linux"
  #     ];
  #     speedFactor = 5;
  #     supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
  #     maxJobs = 48;
  #   }
  # ];
  # nix.distributedBuilds = true;

  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  services.xserver.displayManager.defaultSession = "plasmawayland";

  programs.sway.extraSessionCommands = ''
    export GTK_THEME=Blackbird
    export GTK_ICON_THEME=Tango
    export MOZ_ENABLE_WAYLAND=1
    export MOZ_USE_XINPUT2=1
    export XDG_SESSION_TYPE=wayland
    export XDG_CURRENT_DESKTOP=sway
  '';

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-wlr ];
  };
  environment.sessionVariables.GTK_USE_PORTAL = "1";

  programs.ssh.setXAuthLocation = true;

  hardware.bluetooth = {
    enable = true;
  };

  # Enable udev rules for mtp and such
  services.gvfs.enable = true;

  environment.systemPackages = with pkgs; [
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
    spotify
    tcpdump
    thunderbird
    viddy
    vscode
  ];

})
