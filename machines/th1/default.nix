{ mkMachine, ... }:

mkMachine {} ( { lib, pkgs, config, ... }: with lib; {

  system.stateVersion = "19.03";

  imports = [
    ./hardware-configuration.nix
  ];

  # Fix the LTE modem not being detected
  systemd.services.NetworkManager = let
    modemmanager = "ModemManager.service";
  in {
    after = [ modemmanager ];
    requires = [ modemmanager ];
  };
  systemd.services.ModemManager.path = [ pkgs.libqmi ];

  services.ratbagd.enable = true;

  wat.thelegy.hw-t470.enable = true;
  wat.thelegy.syncthing.enable = true;
  wat.thelegy.workstation.enable = true;

  wat.thelegy.backup = {
    enable = true;
    borgbaseRepo = "v0ggts06";
    extraExcludes = [
      "/home/.pre-repair-2020-11-19"
    ];
    extraReadWritePaths = [
      "/.backup-snapshots"
      "/nix/.backup-snapshots"
    ];
  };

  wat.thelegy.roc-client = {
    enable = true;
    serverAddress = head (splitString "/" config.wat.thelegy.wg-net.rtlan.nodes.y.address);
    localAddress = head (splitString "/" config.wat.thelegy.wg-net.rtlan.thisNode.address);
  };

  wat.thelegy.leg-net.enable = true;
  wat.thelegy.rtlan-net.enable = true;

  # Enable systemd-networkd in addition to NetworkManager
  systemd.network.enable = true;
  systemd.network.wait-online.enable = false;

  # Networking for containers
  networking = {
    nat = {
      enable  = true;
      internalInterfaces = ["ve-+"];
      externalInterface = "wlp4s0";
    };
    networkmanager.unmanaged = [ "interface-name:ve-*" ];
    modemmanager.fccUnlockScripts = [rec{
      id = "1199:9079";
      path = "${pkgs.modemmanager}/share/ModemManager/fcc-unlock.available.d/${id}";
    }];
  };
  services.resolved.enable = true;

  users.users.beinke.extraGroups = [ "dialout" "adbusers" ];

  programs.adb.enable = true;

  networking.firewall.allowedTCPPorts = [ 8000 ];

  nix.settings.trusted-users = [ "beinke" ];

  nix.buildMachines = [
    {
      hostName = "roborock";
      sshUser = "nix";
      system = "aarch64-linux";
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    }
    {
      hostName = "sirrah";
      sshUser = "nix";
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      speedFactor = 5;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      maxJobs = 24;
    }
  ];
  nix.distributedBuilds = true;

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

  hardware.bluetooth = {
    enable = true;
  };


  environment.systemPackages = with pkgs; [
    tcpdump
    itd
  ];

})
