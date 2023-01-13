{ mkMachine, ... }:

mkMachine {} ( { pkgs, config, ... }: {

  imports = [
    ./hardware-configuration.nix
    ../../layers/t470
    ../../layers/laptop
    ../../layers/irb-kerberos
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

  wat.thelegy.workstation.enable = true;

  wat.thelegy.backup = {
    enable = true;
    extraExcludes = [
      "/home/.pre-repair-2020-11-19"
    ];
    extraReadWritePaths = [
      "/.backup-snapshots"
      "/nix/.backup-snapshots"
    ];
  };

  wat.thelegy.leg-net.enable = true;

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
    networkmanager.enableFccUnlock = true;
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
      hostName = "janpc";
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

  services.pipewire = {
    enable = true;
    pulse.enable = false;
  };

  hardware.bluetooth = {
    enable = true;
  };

  services.printing = {
    enable = true;
    drivers = [pkgs.cups-kyocera-ecosys-m552x-p502x];
  };
  hardware.printers.ensurePrinters = [{
    name = "dimitri";
    model = "Kyocera/Kyocera ECOSYS P5021cdw.PPD";
    deviceUri = "socket://192.168.1.29:9100";
  }];

  environment.systemPackages = with pkgs; [
    tcpdump
    itd
  ];

  system.stateVersion = "19.03";

})
