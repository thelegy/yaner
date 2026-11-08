{ wat, ... }:
{
  flake.nixosModules.syncthing = wat.mkModuleWrapped [ "syncthing" ] (
    {
      cfg,
      config,
      lib,
      pkgs,
      ...
    }:
    with lib;

    {
      options = {

        passwordFile = mkOption {
          type = types.nullOr types.str;
          default = null;
        };

      };
      config =
        let
          inherit (config.services.syncthing)
            user
            group
            configDir
            dataDir
            package
            ;
          port = 8384;
        in
        {

          systemd.tmpfiles.rules = [ "d ${dataDir} 0700 ${user} ${group}" ];

          services.syncthing = {
            enable = true;
            openDefaultPorts = true;
            guiAddress = mkForce "127.0.0.1:${toString port}";

            user = mkDefault "beinke";
            group = mkDefault "users";
            dataDir = mkDefault "/srv/sync";

            overrideDevices = false;
            overrideFolders = false;
            settings = {
              options = {
                urAccepted = -1;
                crashReportingEnabled = false;
              };
              defaults = {
                folder = {
                  path = dataDir;
                };
              };
            };
          };

          systemd.services.syncthing = {
            confinement = {
              enable = true;
            };
            serviceConfig = {
              BindPaths = [ dataDir ];
              BindReadOnlyPaths = [
                "/etc/resolv.conf"
                "/etc/passwd"
                "/etc/ssl/certs/ca-certificates.crt"
                "/etc/static/ssl/certs/ca-certificates.crt"
              ];
              ExecStartPre = [
                "+${package}/bin/syncthing generate --home=${configDir} --no-port-probing"
                "+${pkgs.coreutils}/bin/chown ${user} ${configDir}/config.xml"
              ];
              ExecStartPost = [
                "${pkgs.coreutils}/bin/sleep 10"
                "+${package}/bin/syncthing cli --home=${configDir} config gui user set ''"
              ];
            };
          };

          systemd.services.syncthing-init.serviceConfig.Group = "syncthing-api";

          users.groups.syncthing-api = { };

          environment.systemPackages = [ package ];

          wat.thelegy.backup.extraExcludes = [ "/srv/sync/replica" ];

          networking.nftables.chains.output_lo.syncthing.rules = [
            "tcp dport ${toString port} meta skuid != { root, traefik } meta skgid != { syncthing-api } reject"
          ];

          wat.thelegy.traefik.dynamicConfigs.syncthing =
            let
              inherit (config.networking) fqdn;
            in
            {
              http.services.syncthing.loadBalancer = {
                servers = [ { url = "http://127.0.0.1:${toString port}"; } ];
                passHostHeader = false;
              };
              http.routers.syncthing = {
                rule = "Host(`syncthing.${fqdn}`)";
                middlewares = [ "oidc-host@file" ];
                service = "syncthing";
                tls.certResolver = "letsencrypt";
                tls.domains = [
                  {
                    main = "*.${fqdn}";
                  }
                ];
              };
            };

        };
    }

  );
}
