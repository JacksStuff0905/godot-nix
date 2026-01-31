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

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.godot;
      description = "The package to use for godot-nix.";
    };

    output-dir = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/.config";
    };

    compiledPackage = lib.mkOption {
      type = lib.types.package;
    };
  };

  config.programs.godot-nix = {
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
