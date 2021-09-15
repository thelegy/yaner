{ mkMachine, ... }:

mkMachine {} ({ lib, pkgs, config, ... }: with lib; let

  networkInterface = "enp1s0";

in {

  imports = [
    ./hardwareConfiguration.nix
  ];

  wat.thelegy.base.enable = true;
  wat.thelegy.hass.enable = true;

  services.openssh.forwardX11 = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  boot.initrd.availableKernelModules = [ "r8169" ];
  boot.initrd.preLVMCommands = mkOrder 300 "ip link set ${networkInterface} up; sleep 5";
  boot.initrd.network.enable = true;
  boot.initrd.network.ssh = {
    enable = true;
    hostKeys = [ "/etc/secrets/initrd_ed25519_host_key" ];
  };

  wat.installer = {
    enable = true;
    installDisk = "/dev/disk/by-id/ata-SanDisk_SDSSDP128G_141350402051";
    efiId = "CBC7-7164";
    luksUuid = "101359d3-6a37-4ad7-be51-e8335dd4046b";
    swapUuid = "d0b261e3-eb15-4778-8b5a-f9804a6ae02e";
  };

  services.logind.lidSwitch = "ignore";

  networking.useDHCP = false;

  # Dnssec is currently broken
  # TODO: reasearch and fix the cause
  services.resolved.dnssec = "false";

  systemd.network = {
    enable = true;
    netdevs.br0 = {
      netdevConfig = {
        Name = "br0";
        Kind = "bridge";
        MACAddress = "3c:97:0e:4c:04:62";
      };
    };
    networks.${networkInterface} = {
      name = "${networkInterface}";
      bridge = [ "br0" ];
    };
    networks.br0 = {
      name = "br0";
      DHCP = "yes";
      extraConfig = ''
        [CAKE]
        Bandwidth =
      '';
    };
  };


})
