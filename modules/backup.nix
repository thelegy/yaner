{ mkModule
, lib
, liftToNamespace
, config
, ...
}: with lib;

mkModule {

  options = liftToNamespace {

    extraExcludes = mkOption {
      type = with types; listOf str;
      default = [];
    };

    repo = mkOption {
      type = types.str;
      default = "borg@backup.0jb.de:.";
    };

  };

  config = cfg: {

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
          "/nix/var/log"
          "/proc"
          "/root/.cache"
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
        ] ++ cfg.extraExcludes;
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
        repo = cfg.repo;
      };

  };

}
