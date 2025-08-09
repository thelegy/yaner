{ pkgs, config, ... }:

let
  json = pkgs.formats.json {};
  snapcast-stream-port = 1704;
  snapcast-control-port = 1705;
in
{

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    systemWide = true;
    alsa.enable = true;
    pulse.enable = true;
    configPackages = [
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

  #systemd.services.wireplumber.environment.WIREPLUMBER_DEBUG = "3";


  #environment.etc."pipewire/pipewire.conf.d/70-loopback.conf" = {
  #  source = json.generate "pipewire-loopback.conf" {
  #    "context.modules" = [
  #      {
  #        name = "libpipewire-module-loopback";
  #        args = {
  #          "node.description" = "Output proxy (stereo)";
  #          "audio.rate" = 44100;
  #          "capture.props" = {
  #            "node.name" = "output-proxy-stereo";
  #            "media.class" = "Audio/Sink";
  #            "audio.position" = "FL,FR";
  #          };
  #          "playback.props" = {
  #            "node.name" = "output-proxy-stereo-playback";
  #            "node.description" = "Output proxy (stereo) playback";
  #            "audio.position" = "FL,FR";
  #          };
  #        };
  #      }
  #      #{
  #      #  name = "libpipewire-module-loopback";
  #      #  args = {
  #      #    "node.description" = "Input proxy";
  #      #    "capture.props" = {
  #      #      "node.name" = "input-proxy-capture";
  #      #      "node.description" = "Input proxy capture";
  #      #      "audio.position" = "MONO";
  #      #    };
  #      #    "playback.props" = {
  #      #      "node.name" = "input-proxy";
  #      #      "media.class" = "Audio/Source";
  #      #      "audio.position" = "MONO";
  #      #    };
  #      #  };
  #      #}
  #    ];
  #  };
  #};

  #environment.etc."pipewire/pipewire.conf.d/80-network.conf" = {
  #  source = json.generate "pipewire-network.conf" {
  #    "context.modules" = [
  #      {
  #        name = "libpipewire-module-roc-source";
  #        args = {
  #          "source.name" = "input-network-stereo";
  #          "source.props" = {
  #            "node.name" = "Network input (stereo)";
  #          };
  #          "local.ip" = "0.0.0.0";
  #          "resampler.profile" = "none";
  #          "fec.code" = "rs8m";
  #          "sess.latency.msec" = 25;
  #          "local.source.port" = 10001;
  #          "local.repair.port" = 10002;
  #        };
  #      }
  #    ];
  #  };
  #};

  networking.nftables.firewall.rules.pipewire = {
    from = [ "insecure" "internal" ];
    to = [ "fw" ];
    allowedUDPPorts = [ 10001 10002 10011 10012 ];
  };

  networking.nftables.firewall.rules.snapcast = {
    from = [ "home" "tailscale" ];
    to = [ "fw" ];
    allowedTCPPorts = [
      1780  # snapcast-http
      1704  # snapcast-stream
      1705  # snapcast-control
    ];
  };

  users.users.beinke.extraGroups = [ "pipewire" ];

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

  services.spotifyd = {
    enable = false;
    # enable = true;
    config = ''
      [global]
      username_cmd = "cat $CREDENTIALS_DIRECTORY/user"
      password_cmd = "cat $CREDENTIALS_DIRECTORY/password"
      backend = "alsa"
      use_mpris = false
      device_name = "${config.networking.hostName}"
      device_type = "speaker"
    '';
  };

  systemd.services.spotifyd = {
    serviceConfig = {
      SupplementaryGroups = [ "pipewire" ];
      LoadCredential = [
        "user:/etc/secrets/spotify_user"
        "password:/etc/secrets/spotify_password"
      ];
    };
    environment = {
      SHELL = "/bin/sh";
      #PULSE_LOG = "4";
    };
  };

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
