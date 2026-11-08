{ wat, ... }:
{
  flake.nixosModules.stalwart = wat.mkModuleWrapped [ "stalwart" ] (
    {
      cfg,
      config,
      lib,
      ...
    }:

    with lib;

    {
      options = {

        reportDomain = mkOption {
          description = "domain name for use in Delivery Status Notifications";
          type = types.str;
        };

      };

      config =
        let
          adminSecret = "stalwart-mail-admin";
          managementPort = 42929;
          managementURL = "[::1]:${toString managementPort}";
        in
        {
          services.stalwart = {
            enable = true;
            stateVersion = "26.05";
            openFirewall = true;
            settings = {
              server = {
                hostname = config.networking.fqdn;
                tls = {
                  enable = true;
                };
                listener = {
                  smtp = {
                    protocol = "smtp";
                    bind = "[::]:25";
                    tls.enable = true;
                  };
                  submission = {
                    protocol = "smtp";
                    bind = "[::]:465";
                    tls.implicit = true;
                  };
                  imaps = {
                    protocol = "imap";
                    bind = "[::]:993";
                    tls.implicit = true;
                  };
                  management = {
                    bind = managementURL;
                    protocol = "http";
                  };
                  managesieve = {
                    bind = "[::]:4190";
                    protocol = "managesieve";
                  };
                };
              };
              report.domain = cfg.reportDomain;
              lookup.default.hostname = config.networking.fqdn;
              # certificate.default =
              #   let
              #     acmePath = name: "%{file:/var/lib/acme/${config.wat.KoMa.acme.defaultCertName}/${name}}%";
              #   in
              #   {
              #     cert = acmePath "cert.pem";
              #     private-key = acmePath "key.pem";
              #     default = true;
              #   };
              authentication.fallback-admin = {
                user = "admin";
                secret = "%{file:${config.sops.secrets.${adminSecret}.path}}%";
              };
            };
          };

          users.users.stalwart.extraGroups = [ "acme" ];

          sops.secrets.${adminSecret} = {
            format = "yaml";
            mode = "0600";
            owner = "stalwart";
          };

          # systemd.services.stalwart = {
          #   reload =
          #     let
          #       stalwart-cli = "${config.services.stalwart.package}/bin/stalwart-cli";
          #     in
          #     ''
          #       export URL=http://${managementURL}
          #       export CREDENTIALS=$(cat ${config.sops.secrets.${adminSecret}.path})
          #       ${stalwart-cli} server reload-config
          #     '';
          #       # ${stalwart-cli} server reload-certificates
          #   restartIfChanged = true;
          # };

          wat.thelegy.traefik.dynamicConfigs.stalwart =
            let
              inherit (config.networking) fqdn;
            in
            {
              http.services.stalwart.loadBalancer = {
                servers = [ { url = "http://${managementURL}"; } ];
              };
              http.routers.stalwart = {
                rule = "Host(`stalwart.${fqdn}`)";
                middlewares = [ "oidc-host@file" ];
                service = "stalwart";
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
