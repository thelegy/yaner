{ wat, ... }:
{
  flake.nixosModules.docpages = (
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let

      cfg = config.legy.docpages;
      page_cfgs = lib.attrValues cfg.pages;

      perDocpageConfig =
        { name, ... }:
        {
          options = {
            tag = lib.mkOption {
              type = lib.types.str;
            };
            flake = lib.mkOption {
              type = lib.types.str;
            };
            target_dir = lib.mkOption {
              type = lib.types.str;
              default = cfg.target_dir;
            };
          };
          config = {
            tag = lib.mkDefault name;
          };
        };

      flattenList = l: builtins.foldl' (x: y: x // y) { } l;

      docpageService = docpageCfg: {
        "docpage_${docpageCfg.tag}" = {
          description = "Generator for the docpage of ${docpageCfg.tag}";
          requires = [ "network-online.target" ];
          after = [ "network-online.target" ];
          path = [
            pkgs.git
            pkgs.nix
          ];
          environment."NIX_PATH" = "nixpkgs=${pkgs.path}";
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            mkdir -p ${lib.escapeShellArg docpageCfg.target_dir}
            ${pkgs.nix}/bin/nix build \
              --no-write-lock-file \
              --out-link ${lib.escapeShellArg "${docpageCfg.target_dir}/${docpageCfg.tag}"} \
              ${lib.escapeShellArg docpageCfg.flake}
          '';
        };
      };

      docpageTimer = docpageCfg: {
        "docpage_${docpageCfg.tag}" = {
          description = "Update timer for the generator of ${docpageCfg.tag}";
          wantedBy = [ "multi-user.target" ];
          requires = [ "network-online.target" ];
          after = [ "network-online.target" ];
          timerConfig = {
            Unit = "docpage_${docpageCfg.tag}.service";
            OnCalendar = "hourly";
            AccuracySec = "1h";
            RandomizedDelaySec = "1h";
          };
        };
      };

    in
    {

      options.legy.docpages.pages = lib.mkOption {
        type = lib.types.loaOf (lib.types.submodule perDocpageConfig);
        default = { };
      };

      options.legy.docpages.target_dir = lib.mkOption {
        type = lib.types.str;
      };

      config = {
        systemd.services = flattenList (map docpageService page_cfgs);
        systemd.timers = flattenList (map docpageTimer page_cfgs);
      };

    }

  );
}
