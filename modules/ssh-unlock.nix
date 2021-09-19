{ mkModule, lib, liftToNamespace, pkgs, ... }:
with lib;

mkModule {
  options = liftToNamespace {

    interface = mkOption {
      description = ''
        Name of the interface that dhcp should be configured for in the initrd.
      '';
      type = types.str;
    };

    hostKeyFiles = mkOption {
      description = ''
        Host key files to copy into the unencrypted initrd and allow ssh
        access in the initrd from.
      '';
      type = with types; listOf str;
      default = [ "/etc/secrets/initrd_ed25519_host_key" ];
    };

  };
  config = cfg: let
    udhcpcScript = pkgs.writeScript "udhcp-script" ''
      #!/bin/sh
      if [ "$1" = bound ]; then
        ip address add "$ip/$mask" dev "$interface"
        if [ -n "$mtu" ]; then
          ip link set mtu "$mtu" dev "$interface"
        fi
        if [ -n "$staticroutes" ]; then
          echo "$staticroutes" \
            | sed -r "s@(\S+) (\S+)@ ip route add \"\1\" via \"\2\" dev \"$interface\" ; @g" \
            | sed -r "s@ via \"0\.0\.0\.0\"@@g" \
            | /bin/sh
        fi
        if [ -n "$router" ]; then
          ip route add "$router" dev "$interface" # just in case if "$router" is not within "$ip/$mask" (e.g. Hetzner Cloud)
          ip route add default via "$router" dev "$interface"
        fi
        if [ -n "$dns" ]; then
          rm -f /etc/resolv.conf
          for server in $dns; do
            echo "nameserver $server" >> /etc/resolv.conf
          done
        fi
      fi
    '';
  in {

    boot.initrd.preLVMCommands = mkOrder 300 ''
      ip link set ${cfg.interface} up;
      # `{1..10}` is not ash syntax and `1 .. 10` will break with other shells
      for i in 1 2 3 4 5 6 7 8 9 10; do
        echo Run udhcpc: $i
        udhcpc --quit --now -i ${cfg.interface} -O staticroutes --script ${udhcpcScript} || continue
        echo udhcpc ran successfull
        break
      done
    '';

    boot.initrd.network.enable = true;
    boot.initrd.network.ssh = {
      enable = true;
      hostKeys = cfg.hostKeyFiles;
    };

  };
}
