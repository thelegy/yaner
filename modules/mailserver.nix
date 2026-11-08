{ wat, ... }:
{
  flake.nixosModules.mailserver = wat.mkModule [ "mailserver" ] (
    {
      cfg,
      config,
      lib,
      ...
    }:

    let
      sops-secrets = config.sops.secrets;
    in
    {
      namespaceOptions = {

        useACMEHost = lib.mkOption {
          type = lib.types.str;
          default = config.networking.fqdn;
        };

        mailDomain = lib.mkOption {
          type = lib.types.str;
          default = "beinke.cloud";
        };

        imapServer = lib.mkOption {
          type = lib.types.str;
          default = "imap.beinke.cloud";
        };

        smtpServer = lib.mkOption {
          type = lib.types.str;
          default = "smtp.beinke.cloud";
        };

        autoconfigDomains = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ cfg.mailDomain ];
          # See https://wiki.mozilla.org/Thunderbird:Autoconfiguration
        };

        defaultQuota = lib.mkOption {
          type = lib.types.str;
          default = "5G";
        };

      };
      config =
        let
          autoconfigXml = ''
            <?xml version="1.0" encoding="UTF-8"?>

            <clientConfig version="1.1">
              <emailProvider id="${cfg.mailDomain}">
                <domain>${cfg.mailDomain}</domain>
                <displayName>%EMAILADDRESS%</displayName>
                <displayShortName>%EMAILLOCALPART%</displayShortName>
                <incomingServer type="imap">
                  <hostname>${cfg.imapServer}</hostname>
                  <port>993</port>
                  <socketType>SSL</socketType>
                  <authentication>password-cleartext</authentication>
                  <username>%EMAILADDRESS%</username>
                </incomingServer>
                <outgoingServer type="smtp">
                  <hostname>${cfg.smtpServer}</hostname>
                  <port>465</port>
                  <socketType>SSL</socketType>
                  <authentication>password-cleartext</authentication>
                  <username>%EMAILADDRESS%</username>
                </outgoingServer>
              </emailProvider>
            </clientConfig>
          '';
        in
        {

          wat.thelegy.acme.reloadUnits = [
            "dovecot.service"
            "postfix.service"
          ];

          sops.secrets = lib.pipe config.mailserver.accounts [
            lib.attrValues
            (map (x: x.useSopsHashedPassword))
            (lib.filter lib.isString)
            (lib.flip lib.genAttrs (sopsKey: { }))
          ];

          wat.thelegy.nginx.enable = true;
          services.nginx.virtualHosts."mail-autoconfig.localhost" = {
            locations."/mail/config-v1.1.xml".extraConfig = ''
              default_type application/xml;
              charset utf8;
              return 200 '${lib.replaceStrings [ "\n" ] [ "\\n" ] autoconfigXml}';
            '';
          };

          wat.thelegy.traefik.dynamicConfigs.mail = {
            http.services.mail-autoconfig = {
              loadBalancer.servers = [
                { url = "http://mail-autoconfig.localhost:${toString config.wat.thelegy.nginx.port}"; }
              ];
              loadBalancer.passHostHeader = false;
            };
            http.routers.snapcast = {
              rule =
                let
                  hosts_rule = lib.concatMapStringsSep " || " (x: "Host(`autoconfig.${x}`)") cfg.autoconfigDomains;
                in
                "( ${hosts_rule} ) && Path(`/mail/config-v1.1.xml`)";
              service = "mail-autoconfig";
            };
          };

          # Use optionalattrs because mkIf pushes the test down into undefined options
          mailserver = {
            enable = true;

            # Give the users a tool to manage their sive scripts
            enableManageSieve = true;

            fqdn = config.networking.fqdn;

            # As per the dovecot documentation the following is sane and ensures
            # the greatest level of compability with different clients.
            hierarchySeparator = "/";
            storage.directoryLayout = "fs";

            # How expensive is "_very_ expensive"?
            virusScanning = false;

            x509.useACMEHost = cfg.useACMEHost;
          };

          systemd.services.dovecot.serviceConfig = {
            SupplementaryGroups = [ "acme" ];
          };
          systemd.services.postfix.serviceConfig = {
            SupplementaryGroups = [ "acme" ];
          };

          # TODO: snappymail
          # TODO: dmarc-metrics-exporter
          # TODO: aid with dns config, e.g. generated zonefile, ect.

        };

      options = {

        mailserver.accounts = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule (
              { config, ... }:
              {
                options = {

                  useSopsHashedPassword = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    # Keep existing encrypted secret keys after the accounts rename.
                    default = "mailserver/loginAccounts/${config.name}/hashedPassword";
                  };

                };
                config = {

                  hashedPasswordFile = lib.mkIf (
                    !isNull config.useSopsHashedPassword
                  ) sops-secrets.${config.useSopsHashedPassword}.path;

                  quota = lib.mkDefault cfg.defaultQuota;

                };
              }
            )
          );
        };

      };
    }
  );
}
