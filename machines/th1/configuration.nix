{ config, pkgs, ... }:

{

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

  services.ratbagd.enable = true;

  # Enable the borg backup
  services.borgbackup.jobs.offsite = {
    archiveBaseName = "${config.networking.hostName}";
    startAt = "hourly";
    compression = "auto,zstd,22";
    appendFailedSuffix = true;
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat /etc/secrets/borg_passphrase";
    };
    exclude = [
      "/dev"
      "/mnt"
      "/nix/store"
      "/proc"
      "/run"
      "/sys"
      "/tmp"
      "/var/cache"
      "/var/lib/docker"
      "/var/lib/systemd/coredump"
      "/var/log"
      "/var/tmp"

      "/home/.pre-repair-2020-11-19"

      "sh:/home/**/.stack-work"
      "sh:/home/*/.cabal"
      "sh:/home/*/.cache"
      "sh:/home/*/.stack"
      "sh:/home/*/.thunderbird"
    ];
    extraCreateArgs = "--stats";
    paths = [ "/" ];
    prune = {
      keep = {
        hourly = 2;
        daily = 14;
        weekly = 6 ;
        monthly = 12;
      };
    };
    extraPruneArgs = "--list";
    repo = "borg@backup.0jb.de:.";
  };

  # Networking for containers
  networking = {
    nat = {
      enable  = true;
      internalInterfaces = ["ve-+"];
      externalInterface = "wlp4s0";
    };
    networkmanager.unmanaged = [ "interface-name:ve-*" ];
    networkmanager.wifi.backend = "iwd";
  };
  services.resolved.enable = true;

  users.users.beinke.extraGroups = [ "dialout" "adbusers" ];

  programs.adb.enable = true;

  networking.firewall.allowedTCPPorts = [ 8000 ];

  nix.trustedUsers = [ "beinke" ];

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
    gtkUsePortal = true;
  };

  services.pipewire = {
    enable = true;
    pulse.enable = false;
  };

  hardware.bluetooth = {
    enable = true;
    hsphfpd.enable = true;
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

  environment.systemPackages = with pkgs; [ tcpdump ];

  system.stateVersion = "19.03";

}
