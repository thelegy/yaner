{ config, options, pkgs, channels, ... }:

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

  environment.etc = with builtins; let
    toPinnedChannel = name: repo : { name="nix-channels/${name}"; value={source=repo; }; };
    pinnedChannels = listToAttrs (map (name: toPinnedChannel name channels."${name}") (attrNames channels));
  in pinnedChannels;

  users.users.beinke.packages = with pkgs; [
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
    repo = "borg@backup.0jb.de:.";
  };

  users.users.beinke.extraGroups = [ "dialout" ];


  system.stateVersion = "19.03";

}
