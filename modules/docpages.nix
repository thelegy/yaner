{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.legy.docpages;
  page_cfgs = attrValues cfg.pages;

  perDocpageConfig =
    { name, ... }:
    {
      options = {
        tag = mkOption {
          type = types.str;
        };
        flake = mkOption {
          type = types.str;
        };
        target_dir = mkOption {
          type = types.str;
          default = cfg.target_dir;
        };
      };
      config = {
        tag = mkDefault name;
      };
    };

  flattenList = l: builtins.foldl' (x: y: x // y) { } l;

  docpageService = docpageCfg: {
    "docpage_${docpageCfg.tag}" = {
      description = "Generator for the docpage of ${docpageCfg.tag}";
      requires = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = with pkgs; [
        git
        nix
      ];
      environment."NIX_PATH" = "nixpkgs=${pkgs.src}";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        mkdir -p ${escapeShellArg docpageCfg.target_dir}
        ${pkgs.nix}/bin/nix build \
          --no-write-lock-file \
          --out-link ${escapeShellArg "${docpageCfg.target_dir}/${docpageCfg.tag}"} \
          ${escapeShellArg docpageCfg.flake}
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

  options.legy.docpages.pages = mkOption {
    type = with types; loaOf (submodule perDocpageConfig);
    default = { };
  };

  options.legy.docpages.target_dir = mkOption {
    type = types.str;
  };

  config = {
    systemd.services = flattenList (map docpageService page_cfgs);
    systemd.timers = flattenList (map docpageTimer page_cfgs);
  };

}
