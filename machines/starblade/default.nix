{ mkMachine, flakes, ... }:
mkMachine
  {
    nixpkgs = flakes.nixpkgs-stable;
  }
  (
    {
      lib,
      pkgs,
      config,
      ...
    }:
    with lib;

    {

      system.stateVersion = "24.11";

      imports = [
        ./hardware-configuration.nix
        ./installer.nix
      ];

      hardware.cpu.amd.updateMicrocode = true;
      powerManagement.cpuFreqGovernor = "schedutil";

      wat.thelegy.base.enable = true;
      wat.thelegy.backup = {
        enable = true;
        borgbaseRepo = "wx7058j2";
        extraExcludes = [
          "var/lib/libvirt/images"
          "storage/ollama"
        ];
      };

      boot.kernelPackages = pkgs.linuxPackages;
      boot.initrd.availableKernelModules = [ "igc" ];
      boot.initrd.network.enable = true;
      boot.initrd.network.ssh = {
        enable = true;
        hostKeys = [ "/etc/secrets/initrd_ed25519_host_key" ];
      };

      boot.swraid.mdadmConf = ''
        MAILADDR admin@janbeinke.com
      '';

      networking.useDHCP = false;
      networking.interfaces.enp6s0.useDHCP = true;

      systemd.network.enable = true;
      systemd.network.wait-online.enable = false;
      systemd.network.netdevs.br0 = {
        netdevConfig = {
          Name = "br0";
          Kind = "bridge";
        };
      };
      systemd.network.networks.br0 = {
        name = "br0";
        DHCP = "yes";
      };

      networking.hostId = "5e64b0b4";
      fileSystems."/storage" = {
        fsType = "zfs";
        device = "spinningrust";
      };

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = [
          pkgs.rocmPackages.rocm-runtime
          # pkgs.rocmPackages.rocblas # core linear algebra (likely required)
          # pkgs.rocmPackages.hipblas # HIP wrapper around BLAS
          # pkgs.rocmPackages.miopen-hip # deep learning ops (required by many models)
        ];
      };

      hardware.amdgpu.opencl.enable = true;

      nixpkgs.config.rocmSupport = true;

      systemd.tmpfiles.rules = [
        "d /storage/ollama 0750 ollama ollama -"
        "d /storage/paperless-sibylle 0750 paperless paperless"
      ];

      services.ollama = {
        enable = true;
        home = "/storage/ollama";
        user = "ollama";
        package = pkgs.pkgs-unstable.ollama;
        environmentVariables = {
          # OLLAMA_DEBUG = "1";
        };
        # rocmOverrideGfx = "9.0.0";
      };

      environment.systemPackages = with pkgs; [
        cilium-cli
        kubectl
      ];

      networking.nftables.firewall.rules.fwd = {
        to = "all";
        from = "all";
        verdict = "accept";
      };

      wat.thelegy.libvirtd.enable = true;
      users.groups.libvirt = { };
      users.users.beinke.extraGroups = [ "libvirt" ];

      users.groups.paperless-sibylle.gid = 1550;
      users.users.paperless-sibylle = {
        isSystemUser = true;
        uid = 1550;
        group = "paperless-sibylle";
      };
      containers.paperless-sibylle = {
        autoStart = true;
        ephemeral = true;
        bindMounts."/var/lib/paperless" = {
          hostPath = "/storage/paperless-sibylle";
          isReadOnly = false;
        };
        config = containerArgs: {
          nixpkgs.pkgs = pkgs;
          system.stateVersion = "24.11";
          environment.systemPackages = [
            containerArgs.config.services.paperless.manage
          ];
          users.groups.paperless-sibylle = config.users.groups.paperless-sibylle;
          users.users.paperless-sibylle = config.users.users.paperless-sibylle;
          services.paperless = {
            enable = true;
            user = "paperless-sibylle";
            address = "192.168.1.2";
            settings = {
              PAPERLESS_CONSUMER_IGNORE_PATTERN = [
                ".DS_STORE/*"
                "desktop.ini"
              ];
              PAPERLESS_OCR_LANGUAGE = "deu+eng";
              PAPERLESS_OCR_USER_ARGS = {
                optimize = 1;
                pdfa_image_compression = "lossless";
              };
              PAPERLESS_URL = "https://docs.sibylle.beinke.cloud";
              PAPERLESS_TRUSTED_PROXIES = "192.168.1.3";
            };
          };
        };
      };

    }
  )
