{ wat, ... }:
{
  flake.nixosModules.heDdns = (
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let

      cfg = config.services.he-dns;
      cfgs = lib.attrValues cfg;

      perDomainConfig =
        { name, ... }:
        {
          options = {
            domain = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = ''
                The Domain to configure HE DDNS for.
              '';
            };
            keyfile = lib.mkOption {
              type = lib.types.str;
              description = ''
                Path to a file containing the HE DDNS password.
              '';
            };
            updateA = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                If to update the A record.
              '';
            };
            updateAAAA = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                If to update the AAAA record.
              '';
            };
            takeIPv6FromInterface = lib.mkOption {
              type = lib.types.str;
              default = "";
              example = "eth0";
              description = ''
                Get the ipv6 address from this interface. All interfaces are considered, when this is empty.
              '';
            };
            onCalendar = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = "*:00/10:00";
              example = "*:00/5:00";
              description = ''
                OnCalendar value for the systemd-timer. See SYSTEMD.TIME(7).
              '';
            };
            onBootSec = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = "1min";
              example = "5min";
              description = ''
                OnBootSec value for the systemd-timer. See SYSTEMD.TIME(7).
              '';
            };
            updateEndpoint = lib.mkOption {
              type = lib.types.str;
              default = "https://dyn.dns.he.net/nic/update";
              description = ''
                Update Url. Changes to this are very unlikely.
              '';
            };
          };
          config = {
            domain = lib.mkDefault name;
          };
        };

      flattenList = l: builtins.foldl' (x: y: x // y) { } l;

      ddnsV4Script = domainCfg: ''
        ${pkgs.curl}/bin/curl --silent -4 "${domainCfg.updateEndpoint}" -d "hostname=${domainCfg.domain}" -d "password=$(cat ${domainCfg.keyfile})"
        echo
      '';
      ddnsV6Script = domainCfg: ''
        # take the first global (should be routable) primary (to filter out privacy extension addresses) ipv6 address
        myip="$(${pkgs.iproute2}/bin/ip -json -6 address show scope global primary ${domainCfg.takeIPv6FromInterface} | ${pkgs.jq}/bin/jq --raw-output '.[0].addr_info | map(.local | strings) | .[0]')"
        # ensure we have a valid v6 address
        if ${pkgs.iproute2}/bin/ip route get "$myip" >/dev/null &>/dev/null
        then
          echo "Using IPv6 address $myip"
        else
          echo "No global primary ipv6 address available"
          exit 1
        fi
        ${pkgs.curl}/bin/curl --silent "${domainCfg.updateEndpoint}" -d "hostname=${domainCfg.domain}" -d "password=$(cat ${domainCfg.keyfile})" -d "myip=$myip"
        echo
      '';

      ddnsScript =
        domainCfg:
        # ipv6 does ip detection which might fail, so run ipv4 first
        (lib.optionalString domainCfg.updateA (ddnsV4Script domainCfg))
        + (lib.optionalString domainCfg.updateAAAA (ddnsV6Script domainCfg));

      ddnsService =
        domainCfg:
        lib.optionalAttrs (domainCfg.updateAAAA || domainCfg.updateA) {
          "he-ddns-${domainCfg.domain}" = {
            description = "Hurricane Electric DDNS Update Service";
            requires = [ "network-online.target" ];
            after = [ "network-online.target" ];
            script = ddnsScript domainCfg;
          };
        };

      ddnsTimer =
        domainCfg:
        lib.optionalAttrs (domainCfg.updateAAAA || domainCfg.updateA) {
          "he-ddns-${domainCfg.domain}" = {
            description = "Hurricane Electric DDNS Update Timer";
            wantedBy = [ "multi-user.target" ];
            requires = [ "network-online.target" ];
            after = [ "network-online.target" ];
            timerConfig = {
              Unit = "he-ddns-${domainCfg.domain}.service";
            }
            // (lib.optionalAttrs (!isNull domainCfg.onBootSec) { OnBootSec = domainCfg.onBootSec; })
            // (lib.optionalAttrs (!isNull domainCfg.onCalendar) { OnCalendar = domainCfg.onCalendar; });
          };
        };

    in
    {

      options.services.he-dns = lib.mkOption {
        type = lib.types.loaOf (lib.types.submodule perDomainConfig);
        default = { };
        description = ''
          Timer for updating HE DDNS Records.
          Documentation: https://dns.he.net/docs.html
        '';
      };

      config = {
        systemd.services = flattenList (map ddnsService cfgs);
        systemd.timers = flattenList (map ddnsTimer cfgs);
      };

    }

  );
}
