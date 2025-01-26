{ lib, pkgs, config, ... }:
with lib;

let
  rocSourcePortOut = 10001;
  rocRepairPortOut = 10002;
  rocSourcePortIn = 10011;
  rocRepairPortIn = 10012;
  clients = [ "sirrah" "th1" ];
  snapcast-stream-port = 1704;
  snapcast-control-port = 1705;
in {

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    systemWide = true;
    alsa.enable = true;
    pulse.enable = true;
    configPackages = [
      (pkgs.writeTextDir "30-defaults.conf" ''
        context,properties = {
          default.clock.rate = 48000
          default.clock.allowed-rates = [ 48000, ]
        }
      '')
      (pkgs.writeTextDir "50-proxy-output-2_0.conf" ''
        context.modules = [
          {
            name = libpipewire-module-combine-stream
            args = {
              combine.mode = sink
              node.name = "proxy-output-2_0"
              node.description = "Output Proxy 2.0"
              combine.latency-compensate = false   # if true, match latencies by adding delays
              combine.props = {
                audio.position = [ FL FR ]
              }
              stream.props = {
              }
              stream.rules = [
                {
                  matches = [ { media.class = "Audio/Sink" } ]
                  actions = { create-stream = { } }
                }
              ]
            }
          }
        ]
      '')
      (pkgs.writeTextDir "50-proxy-input-2_0.conf" ''
        context.modules = [
          {
            name = libpipewire-module-combine-stream
            args = {
              combine.mode = source
              node.name = "proxy-input-2_0"
              node.description = "Input Proxy 2.0"
              combine.latency-compensate = false   # if true, match latencies by adding delays
              combine.props = {
                audio.channels = 2
                audio.position = [ FL FR ]
              }
              stream.props = {
              }
              stream.rules = [
                {
                  matches = [
                    { node.name = "alsa_input.usb-JABRA_GN_2000_MS_USB-00.mono-fallback" }
                    { node.name = "alsa_input.usb-0b0e_Jabra_Link_380_08C8C2EBE145-00.mono-fallback" }
                  ]
                  actions = { create-stream = { } }
                }
              ]
            }
          }
        ]
      '')
      (pkgs.writeTextDir "60-roc-receiver-2_0.conf" ''
        context.modules = [
          {
            name = libpipewire-module-roc-source
            args = {
              local.ip = ${head (splitString "/" config.wat.thelegy.wg-net.rtlan.thisNode.address)}
              resampler.profile = medium
              sess.latency.msec = 60
              local.source.port = ${toString rocSourcePortOut}
              local.repair.port = ${toString rocRepairPortOut}
              source.name = "ROC Source"
              source.props = {
                node.name = "roc-source"
                target.object = "proxy-output-2_0"
              }
            }
          }
        ]
      '')
      (pkgs.writeTextDir "60-roc-sender-2_0.conf" ''
        context.modules = [
        ${concatMapStringsSep "\n" (client: ''
          {
            name = libpipewire-module-roc-sink
            args = {
              remote.ip = ${head (splitString "/" config.wat.thelegy.wg-net.rtlan.nodes.${client}.address)}
              remote.source.port = ${toString rocSourcePortIn}
              remote.repair.port = ${toString rocRepairPortIn}
              sink.props = {
                node.name = "roc-sink-${client}"
                media.class = "Stream/Input/Audio"
              }
            }
          },
        '') clients}
        ]
      '')
      (pkgs.writeTextDir "share/pipewire/pipewire.conf.d/70-snapcast.conf" ''
        context.modules = [
          {
            name = libpipewire-module-pipe-tunnel
            args = {
              tunnel.mode = "sink"
              pipe.filename = "/run/pipewire/snapfifo"
              audio.format = S16LE
              audio.rate = 48000
              audio.channels = 2
              stream.props = {
                node.name = "Snapcast"
                audio.position = "FL,FR"
              }
            }
          }
        ]
      '')
    ];
  };
  systemd.services.pipewire.wantedBy = [ "multi-user.target" ];

  # systemd.services.pipewire.environment.PIPEWIRE_DEBUG = "W,mod.combine*:D,mod.roc-sink:D";
  # systemd.services.wireplumber.environment.WIREPLUMBER_DEBUG = "3";

  systemd.services.wireplumber.postStart = ''
    ${pkgs.coreutils}/bin/sleep 5s
    ${concatMapStringsSep "\n" (client: ''
      ${pkgs.pipewire}/bin/pw-link proxy-input-2_0:capture_FL roc-sink-${client}:send_FL || true
      ${pkgs.pipewire}/bin/pw-link proxy-input-2_0:capture_FR roc-sink-${client}:send_FR || true
    '') clients}
  '';

  networking.nftables.firewall = {

    rules.rtlan-audio-server = {
      from = [ "rtlan" ];
      to = [ "fw" ];
      allowedUDPPorts = [ rocSourcePortOut rocRepairPortOut ];
    };

    rules.snapcast = {
      from = [ "home" "tailscale" ];
      to = [ "fw" ];
      allowedTCPPorts = [
        1780  # snapcast-http
        1704  # snapcast-stream
        1705  # snapcast-control
      ];
    };

  };

  users.users.beinke = {
    extraGroups = [ "pipewire" ];
    packages = with pkgs; [
      pulseaudio
      pulsemixer
    ];
  };

  services.snapserver = {
    enable = true;
    port = snapcast-stream-port;
    streams.default = {
      type = "pipe";
      location = "/run/pipewire/snapfifo";
      query = {
        mode = "read";
      };
    };
    tcp = {
      enable = true;
      port = snapcast-control-port;
    };
  };
  systemd.services.snapserver.serviceConfig.SupplementaryGroups = [ "pipewire" ];

  services.nginx.virtualHosts."snapcast.0jb.de" = {
    forceSSL = true;
    useACMEHost = config.networking.fqdn;
    listenAddresses = [ "192.168.1.3" ];
    locations."/" = {
      alias = "${pkgs.snapweb}/";
    };
    locations."/jsonrpc" = {
      proxyPass = "http://localhost:1780/jsonrpc";
      proxyWebsockets = true;
    };
    locations."/stream" = {
      proxyPass = "http://localhost:1780/stream";
      proxyWebsockets = true;
    };
  };

  #services.spotifyd = {
  #  enable = true;
  #  config = ''
  #    [global]
  #    username_cmd = "cat $CREDENTIALS_DIRECTORY/user"
  #    password_cmd = "cat $CREDENTIALS_DIRECTORY/password"
  #    backend = "alsa"
  #    use_mpris = false
  #    device_name = "${config.networking.hostName}"
  #    device_type = "speaker"
  #  '';
  #};

  #systemd.services.spotifyd = {
  #  serviceConfig = {
  #    SupplementaryGroups = [ "pipewire" ];
  #    LoadCredential = [
  #      "user:/etc/secrets/spotify_user"
  #      "password:/etc/secrets/spotify_password"
  #    ];
  #  };
  #  environment = {
  #    SHELL = "/bin/sh";
  #    #PULSE_LOG = "4";
  #  };
  #};

  systemd.services.wdr2 = let
    # streamUrl = "https://www1.wdr.de/radio/player/radioplayer104~_layout-popupVersion.html";
    streamUrl = "https://wdrhf.akamaized.net/hls/live/2027966/wdr2rheinland/master.m3u8";
    # streamUrl = "https://playerservices.streamtheworld.com/api/livestream-redirect/VERONICA.mp3?dist=veronica_web&ttag=talpa_consent:0&gdpr=0&gdpr_consent=";
  in {
    enable =  true;
    serviceConfig = {
      DynamicUser = true;
      ExecStart = "${pkgs.mpv}/bin/mpv --script=${pkgs.mpv_autospeed} -af scaletempo --ao=alsa --no-terminal ${streamUrl}";
      SupplementaryGroups = [ "pipewire" ];
      Restart = "always";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
