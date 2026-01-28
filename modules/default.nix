{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.programs.godot-nix;
in
{
  options.programs.godot-nix = {
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };

    mono = lib.mkEnableOption "mono support";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.godot;
      description = "The package to use for godot-nix.";
    };
  };

  config.programs.godot-nix = {
    package = if (cfg.mono) then (lib.mkDefault pkgs.godot-mono) else cfg.package;

    compiledSettings = lib.mkIf cfg.enable (
      # Miscellaneous settings
      let
        flattenTree =
          sep: tree:
          let
            op =
              path: value:
              if lib.isAttrs value then
                lib.concatLists (lib.mapAttrsToList (k: v: op (path ++ [ k ]) v) value)
              else
                [
                  {
                    name = builtins.concatStringsSep sep path;
                    value = value;
                  }
                ];
          in
          op [ ] tree;

        resultList = flattenTree "/" cfg.settings;
      in
      builtins.listToAttrs resultList
    );
  };
}
