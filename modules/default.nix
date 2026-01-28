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
    package = lib.mkIf cfg.mono (lib.mkDefault pkgs.godot-mono);

    compiledSettings = lib.mkIf cfg.enable (
      # Miscellaneous settings
      let
        flattenTree =
          sep: tree:
          let
            # Helper function carrying the current key path
            op =
              path: value:
              if lib.isAttrs value then
                # If it's a set, recurse into children and flatten the resulting lists
                lib.concatLists (lib.mapAttrsToList (k: v: op (path ++ [ k ]) v) value)
              else
                # Base case: Return the flattened key and value
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
