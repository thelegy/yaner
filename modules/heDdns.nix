{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.he-dns;
  cfgs = attrValues cfg;

  perDomainConfig = {name, ...}: {
    options = {
      domain = mkOption {
        type = types.str;
        default = "";
        description = ''
          The Domain to configure HE DDNS for.
        '';
      };
      keyfile = mkOption {
        type = types.str;
        description = ''
          Path to a file containing the HE DDNS password.
        '';
      };
      updateA = mkOption {
        type = types.bool;
        default = true;
        description = ''
          If to update the A record.
        '';
      };
      updateAAAA = mkOption {
        type = types.bool;
        default = true;
        description = ''
          If to update the AAAA record.
        '';
      };
      takeIPv6FromInterface = mkOption {
        type = types.str;
        default = "";
        example = "eth0";
        description = ''
          Get the ipv6 address from this interface. All interfaces are considered, when this is empty.
        '';
      };
      onCalendar = mkOption {
        type = with types; nullOr str;
        default = "*:00/10:00";
        example = "*:00/5:00";
        description = ''
          OnCalendar value for the systemd-timer. See SYSTEMD.TIME(7).
        '';
      };
      onBootSec = mkOption {
        type = with types; nullOr str;
        default = "1min";
        example = "5min";
        description = ''
          OnBootSec value for the systemd-timer. See SYSTEMD.TIME(7).
        '';
      };
      updateEndpoint = mkOption {
        type = types.str;
        default = "https://dyn.dns.he.net/nic/update";
        description = ''
          Update Url. Changes to this are very unlikely.
        '';
      };
    };
    config = {
      domain = mkDefault name;
    };
  };

  flattenList = l: builtins.foldl' (x: y: x//y) {} l;

  ddnsV4Script = domainCfg: flags: ''
    ${pkgs.curl}/bin/curl --silent ${flags} "${domainCfg.updateEndpoint}" -d "hostname=${domainCfg.domain}" -d "password=$(cat ${domainCfg.keyfile})"
    echo
  '';
  ddnsV6Script = domainCfg: flags: ''
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
    ${pkgs.curl}/bin/curl --silent ${flags} "${domainCfg.updateEndpoint}" -d "hostname=${domainCfg.domain}" -d "password=$(cat ${domainCfg.keyfile})" -d "myip=$myip"
    echo
  '';

  ddnsScript = domainCfg:
    # ipv6 does ip detection which might fail, so run ipv4 first
    (optionalString domainCfg.updateA (ddnsV4Script domainCfg "-4")) +
    (optionalString domainCfg.updateAAAA (ddnsV6Script domainCfg "-6"));

  ddnsService = domainCfg: optionalAttrs (domainCfg.updateAAAA || domainCfg.updateA) {
    "he-ddns-${domainCfg.domain}" = {
      description = "Hurricane Electric DDNS Update Service";
      requires = [ "network-online.target" ];
      after = [ "network-online.target" ];
      script = ddnsScript domainCfg;
    };
  };

  ddnsTimer = domainCfg: optionalAttrs (domainCfg.updateAAAA || domainCfg.updateA) {
    "he-ddns-${domainCfg.domain}" = {
      description = "Hurricane Electric DDNS Update Timer";
      wantedBy = [ "multi-user.target" ];
      requires = [ "network-online.target" ];
      after = [ "network-online.target" ];
      timerConfig = { Unit = "he-ddns-${domainCfg.domain}.service"; }
        // (optionalAttrs (!isNull domainCfg.onBootSec) { OnBootSec = domainCfg.onBootSec; })
        // (optionalAttrs (!isNull domainCfg.onCalendar) { OnCalendar = domainCfg.onCalendar; });
    };
  };

in {

  options.services.he-dns = mkOption {
    type = with types; loaOf (submodule perDomainConfig);
    default = {};
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
