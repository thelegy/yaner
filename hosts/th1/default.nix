{ config, options, pkgs, ... }:

{

  imports = [
    ./hardware-configuration.nix
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

  users.users.beinke.packages = with pkgs; [
    bc  # For my battery script i use for my sway bar
  ];

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
      "/.snaps"
      "/dev"
      "/keybase"
      "/mnt"
      "/nix/store"
      "/opt/altera"
      "/proc"
      "/run"
      "/sys"
      "/tmp"
      "/var/cache"
      "/var/lib/docker"
      "/var/lib/systemd/coredump"
      "/var/log"
      "/var/tmp"

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
    repo = "ssh://bup@backup.0jb.de/~/th1";
  };

  hardware.cpu.intel.updateMicrocode = true;

  system.stateVersion = "19.03";

}
