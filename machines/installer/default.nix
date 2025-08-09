{ mkMachine, ... }:

mkMachine { } (
  {
    lib,
    pkgs,
    modulesPath,
    config,
    ...
  }:
  with lib;
  {

    imports = [
      (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    ];

    isoImage.isoBaseName = "nixos-thelegy";

    boot.kernelPackages = pkgs.linuxPackages;

    wat.thelegy.base.enable = true;

    services.greetd = {
      enable = true;
      restart = true;
      settings.default_session = {
        command = pkgs.writeScript "tmux-session" ''
          ${pkgs.tmux}/bin/tmux  \
            new -d -s greeter '${pkgs.htop}/bin/htop; zsh' \; \
            split-window -h -l 80 '${pkgs.procps}/bin/watch -t -c ${pkgs.inxi}/bin/inxi -MiBDpo -c2; zsh' 2>/dev/null
          ${pkgs.tmux}/bin/tmux attach -t greeter -r 2>/dev/null
        '';
        user = "root";
      };
    };

  }
)
