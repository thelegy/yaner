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
              PAPERLESS_TRUSTED_PROXIES = "192.168.1.3";
            };
          };
        };
      };

      environment.etc."traefik/nixos.toml" = {
        mode = "0644";
        source = (pkgs.formats.toml { }).generate "nixos.toml" {
          http.routers.audiobooks = {
            rule = "Host(`audiobooks.beinke.cloud`)";
            service = "audiobooks";
          };
          http.services.audiobooks.loadBalancer = {
            servers = [ { url = "https://audiobooks.beinke.cloud"; } ];
          };
          http.routers.paperless-sibylle = {
            rule = "Host(`docs.sibylle.beinke.cloud`)";
            service = "paperless-sibylle";
          };
          http.services.paperless-sibylle.loadBalancer.servers = [ { url = "http://192.168.9.105:28981"; } ];
          tls.stores.default.defaultGeneratedCert = {
            resolver = "letsencrypt";
            domain = rec {
              main = "ingress.0jb.de";
              sans = [
                main
                "beinke.cloud"
                "*.beinke.cloud"
                "die-cloud.org"
                "*.die-cloud.org"
                "janbeinke.com"
                "*.janbeinke.com"
                "thelegy.de"
                "*.thelegy.de"
              ];
            };
          };
        };
      };
      sops.secrets.traefik-env = {
        format = "yaml";
        mode = "0600";
        restartUnits = [ "container@ingress.service" ];
      };
      containers.ingress = {
        autoStart = true;
        privateNetwork = true;
        macvlans = [ "dmz" ];
        bindMounts."/etc/traefik" = {
          hostPath = "/etc/traefik";
          isReadOnly = true;
        };
        bindMounts.${config.sops.secrets.traefik-env.path} = {
          hostPath = config.sops.secrets.traefik-env.path;
          isReadOnly = true;
        };
        config = containerArgs: {
          nixpkgs.pkgs = pkgs;
          system.stateVersion = "24.11";
          networking.interfaces.mv-dmz.useDHCP = true;
          networking.useHostResolvConf = false;
          services.resolved.enable = true;
          networking.firewall.allowedTCPPorts = [
            80
            443
          ];
          networking.firewall.allowedUDPPorts = [
            443
          ];
          users.users.acme = {
            home = "/var/lib/acme";
            homeMode = "755";
            group = "acme";
            isSystemUser = true;
          };
          users.groups.acme = { };
          systemd.services.traefik = {
            serviceConfig.EnvironmentFile = config.sops.secrets.traefik-env.path;
          };
          services.traefik = {
            enable = true;
            staticConfigOptions = {
              providers.file.directory = "/etc/traefik";
              entryPoints = {
                web = {
                  address = ":80";
                  http.redirections.entryPoint = {
                    to = "websecure";
                    scheme = "https";
                    permanent = true;
                  };
                  observability = {
                    accessLogs = false;
                    metrics = false;
                    tracing = false;
                  };
                };
                websecure = {
                  address = ":443";
                  asDefault = true;
                  http = {
                    tls = { };
                  };
                  http3 = true;
                };
              };
              certificatesResolvers = rec {
                letsencrypt.acme = {
                  email = "mail+letsencrypt@0jb.de";
                  storage = "/var/lib/traefik/acme.json";
                  keyType = "EC256";
                  caServer = "https://acme-v02.api.letsencrypt.org/directory";
                  dnsChallenge = {
                    provider = "hurricane";
                  };
                };
                letsencrypt-staging = recursiveUpdate letsencrypt {
                  acme.storage = "/var/lib/traefik/acme-staging.json";
                  acme.caServer = "https://acme-staging-v02.api.letsencrypt.org/directory";
                };
              };
            };
          };
        };
      };

    }
  )
