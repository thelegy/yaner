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
    let

      networkInterface = "enp6s0";
      macAddress = "60:cf:84:bf:a4:a0";

    in
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
      wat.thelegy.traefik = {
        enable = true;
        dnsProvider = "hurricane";
      };
      services.traefik.staticConfigOptions.entryPoints = {
        websecure.proxyProtocol.trustedIPs = [
          "192.168.5.0/24"
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

      systemd.network.enable = true;
      systemd.network.wait-online.enable = false;
      systemd.network.netdevs.br0 = {
        netdevConfig = {
          Name = "br0";
          Kind = "bridge";
          MACAddress = macAddress;
        };
      };

      systemd.network.networks.${networkInterface} = {
        name = "${networkInterface}";
        bridge = [ "br0" ];
        networkConfig.VLAN = [ "dmz" ];
      };
      systemd.network.networks.br0 = {
        name = "br0";
        DHCP = "yes";
        extraConfig = ''
          [CAKE]
          Bandwidth =
        '';
      };

      systemd.network.netdevs."dmz" = {
        netdevConfig = {
          Name = "dmz";
          Kind = "vlan";
        };
        vlanConfig = {
          Id = 5;
        };
      };
      systemd.network.networks."dmz" = {
        matchConfig.Name = "dmz";
        linkConfig.RequiredForOnline = "no";
        networkConfig = {
          DHCP = "no";
          LinkLocalAddressing = "no";
          IPv6AcceptRA = false;
          LLMNR = "no";
          MulticastDNS = false;
        };
      };

      networking.firewall.allowedTCPPorts = [ 28981 ];

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
            address = "192.168.9.105";
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
              PAPERLESS_TRUSTED_PROXIES = "192.168.9.105";
            };
          };
        };
      };

      wat.thelegy.traefik.dynamicConfigs.paperless-sibylle = {
        http.services.paperless-sibylle.loadBalancer = {
          servers = [ { url = "http://192.168.9.105:28981"; } ];
        };
        http.routers.paperless-sibylle = {
          rule = "Host(`docs.sibylle.beinke.cloud`)";
          service = "paperless-sibylle";
        };
      };

      environment.etc."traefik-ingress/nixos.toml" = {
        mode = "0644";
        source = (pkgs.formats.toml { }).generate "nixos.toml" {
          tcp.services.forever.loadBalancer = {
            servers = [ { address = "192.168.242.1:33030"; } ];
            proxyProtocol.version = 2;
          };
          tcp.routers.forever = {
            rule = "HostSNI(`*`)";
            tls.passthrough = true;
            entryPoints = [ "websecure" ];
            service = "forever";
          };
          # tcp.services.local.loadBalancer = {
          #   servers = [ { address = "127.0.0.1:33030"; } ];
          #   proxyProtocol.version = 2;
          # };
          # tcp.routers.local = {
          #   rule = "HostSNI(`*`)";
          #   # rule = lib.concatMapStringsSep " && " (x: "HostSNI(`${x}`)") [
          #   #   "audiobooks.beinke.cloud"
          #   # ];
          #   tls.passthrough = true;
          #   entryPoints = [ "websecure" ];
          #   service = "local";
          # };
          tcp.services.starblade.loadBalancer = {
            servers = [ { address = "192.168.9.105:443"; } ];
            proxyProtocol.version = 2;
          };
          tcp.routers.starblade = {
            rule = lib.concatMapStringsSep " || " (x: "HostSNI(`${x}`)") [
              "docs.sibylle.beinke.cloud"
            ];
            tls.passthrough = true;
            service = "starblade";
          };
          tcp.services.y.loadBalancer = {
            servers = [ { address = "192.168.1.3:443"; } ];
            proxyProtocol.version = 2;
          };
          tcp.routers.y = {
            rule = lib.concatMapStringsSep " || " (x: "HostSNI(`${x}`)") [
              "audiobooks.beinke.cloud"
            ];
            tls.passthrough = true;
            service = "y";
          };
          tcp.services.hass.loadBalancer = {
            servers = [ { address = "192.168.1.30:443"; } ];
            proxyProtocol.version = 2;
          };
          tcp.routers.hass = {
            rule = "HostSNI(`ha.0jb.de`)";
            tls.passthrough = true;
            service = "hass";
          };
        };
      };
      sops.secrets.ingress-traefik-env = {
        format = "yaml";
        mode = "0600";
        restartUnits = [ "container@ingress.service" ];
      };
      containers.ingress = {
        autoStart = true;
        privateNetwork = true;
        macvlans = [ "dmz" ];
        bindMounts."/etc/traefik" = {
          hostPath = "/etc/traefik-ingress";
          isReadOnly = true;
        };
        bindMounts.${config.sops.secrets.ingress-traefik-env.path} = {
          hostPath = config.sops.secrets.ingress-traefik-env.path;
          isReadOnly = true;
        };
        config = containerArgs: {
          imports = attrValues flakes.self.nixosModules ++ [
            flakes.homemanager.nixosModules.home-manager
            flakes.nix-index-database.nixosModules.nix-index
            flakes.nixos-nftables-firewall.nixosModules.default
            flakes.sops-nix.nixosModules.sops
          ];
          nixpkgs.pkgs = pkgs;
          system.stateVersion = "24.11";
          networking.interfaces.mv-dmz.useDHCP = true;
          networking.useHostResolvConf = false;
          services.resolved.enable = true;
          wat.thelegy.monitoring.enable = true;
          wat.thelegy.traefik = {
            enable = true;
            sopsCredentialsFile = null;
            dnsProvider = "hurricane";
          };
          networking.hosts."192.168.1.3" = [
            "loki.0jb.de"
            "prometheus.0jb.de"
          ];
          networking.firewall.allowedTCPPorts = [ 33030 ];
          systemd.services.traefik = {
            serviceConfig.EnvironmentFile = config.sops.secrets.ingress-traefik-env.path;
          };
          services.traefik.staticConfigOptions = {
            providers.file.directory = "/etc/traefik";
            entryPoints = {
              websecure_pp = {
                address = ":33030";
                asDefault = true;
                http.tls.certResolver = "letsencrypt";
                proxyProtocol.trustedIPs = [
                  "127.0.0.1/32"
                  "192.168.242.1/32"
                ];
              };
            };
          };
        };
      };

    }
  )
