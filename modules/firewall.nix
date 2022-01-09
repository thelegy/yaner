{ mkTrivialModule
, ... }: mkTrivialModule {

  networking.services = {
    ssh = 22;
    dns-udp = { port = 53; type = "udp"; };
    dns-tcp = 53;
    dhcp-server = { port = 67; type = "udp"; };
    dhcpv6-client = { port = 546; type = "udp"; };
    http = 80;
    https = 443;
  };

  networking.firewall.enable = false;
  networking.nftables.stopRuleset = ''
    table inet filter {
      chain input {
        type filter hook input priority 0; policy drop
        iifname lo accept
        ct state {established, related} accept
        ip6 nexthdr icmpv6 icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } accept
        ip protocol icmp icmp type { destination-unreachable, router-advertisement, time-exceeded, parameter-problem } accept
        ip6 nexthdr icmpv6 icmpv6 type echo-request accept
        ip protocol icmp icmp type echo-request accept
        tcp dport 22 accept
        iifname { internal } tcp dport { 53 }
        iifname { internal } udp dport { 53, 67 }
        counter drop
      }
      chain forward {
        type filter hook forward priority 0; policy drop
        ct state {established, related} accept
        iifname { internal } oifname { eth0, ppp0, uplink } accept
        counter drop
      }
    }
  '';

  networking.nftables.firewall = {
    enable = true;
    zones = {

      fw = {
        localZone = true;
        interfaces = [ "lo" ];
      };

    };
    rules = {

      loopback = {
        insertionPoint = "early";
        from = [ "fw" ];
        to = [ "fw" ];
        verdict = "accept";
      };

      ssh = {
        insertionPoint = "early";
        from = "all";
        to = [ "fw" ];
        allowedServices = [ "ssh" ];
      };

    };
  };

}
