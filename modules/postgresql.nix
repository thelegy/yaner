{ wat, ... }:
{
  flake.nixosModules.postgresql = wat.mkModule [ "postgresql" ] (
    {
      cfg,
      lib,
      config,
      pkgs,
      ...
    }:

    {

      namespaceOptions = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable PostgreSQL backup functionality";
        };

        package = lib.mkOption {
          type = lib.types.package;
          description = "PostgreSQL package to use";
        };

        backupPath = lib.mkOption {
          type = lib.types.str;
          default = "/var/backups/postgresql";
          description = "Path where database dumps will be stored";
        };
      };

      config = lib.mkIf cfg.enable {
        # Enable and configure PostgreSQL service
        services.postgresql = {
          enable = true;
          package = cfg.package;
          settings.listen_addresses = lib.mkDefault "";
        };

        # PostgreSQL dump service for pre-backup
        systemd.services.postgresql-dump = {
          description = "Dump PostgreSQL databases before backup";
          serviceConfig = {
            Type = "oneshot";
            User = "postgres";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "postgresql-dump" ''
              set -euo pipefail

              # Create backup directory
              mkdir -p ${lib.escapeShellArg cfg.backupPath}

              # Dump all databases using the correct pg_dumpall from the finalPackage (with plugins)
              ${config.services.postgresql.finalPackage}/bin/pg_dumpall --clean --if-exists --file=${lib.escapeShellArg "${cfg.backupPath}/full_dump.sql"}

              echo "PostgreSQL dump completed: full_dump.sql"
            '';
          };
          partOf = [ "pre-backup.target" ];
          requiredBy = [ "pre-backup.target" ];
          unitConfig.StopWhenUnneeded = true;
        };

        # Ensure backup directory exists with proper permissions
        systemd.tmpfiles.rules = [
          "d ${cfg.backupPath} 0755 postgres postgres - -"
        ];

        # Exclude PostgreSQL data directories from backup
        wat.thelegy.backup.extraExcludes = [
          "var/lib/postgresql"
        ];
      };
    }

  );
}
