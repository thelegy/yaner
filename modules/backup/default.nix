{ mkModule
, lib
, pkgs
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

    extraReadWritePaths = mkOption {
      type = with types; listOf str;
      default = [ "/.backup-snapshots" ];
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
      preHook = ''
        ${pkgs.callPackage ./snapshot.nix {}}
        cd /.backup
      '';
      readWritePaths = [ "/.backup" ] ++ cfg.extraReadWritePaths;
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
      extraCreateArgs = "--stats --exclude-caches";
      paths = [ "." ];
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

    systemd.tmpfiles.rules = [
      "d /.backup 0700 root root - -"
    ] ++ (map (x: "d ${x} 0700 root root - -") cfg.extraReadWritePaths);

  };

}
