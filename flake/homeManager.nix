{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.godot-nix;

  toGodotConfig =
    attrs:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        key: value:
        let
          formattedValue =
            if builtins.isBool value then
              (if value then "true" else "false")
            else if builtins.isInt value then
              toString value
            else if builtins.isFloat value then
              toString value
            else
              "\"${toString value}\"";
        in
        "${key} = ${formattedValue}"
      ) attrs
    );

  nixGodotSettings = pkgs.writeText "nix-godot-overrides.cfg" (toGodotConfig cfg.compiledSettings);

  mergerScript = pkgs.writeScriptBin "godot-config-merger" ''
    #!${pkgs.python3}/bin/python
    ${builtins.readFile ../util/configMerger.py}
  '';

  godotVersion = config.programs.godot-nix.package.version;
  godotShortVersion = "${pkgs.lib.versions.major godotVersion}.${pkgs.lib.versions.minor godotVersion}";

  configFileName = "editor_settings-${godotShortVersion}.tres";

  godotWrapped = pkgs.writeShellScriptBin "godot" ''
    mkdir -p "$HOME/.config/godot"

    ${mergerScript}/bin/godot-config-merger \
      "$HOME/.config/godot/${configFileName}" \
      "${nixGodotSettings}"

    ${lib.getExe config.programs.godot-nix.package} "$@"
  '';
in
{
  imports = [
    ../modules/default.nix
  ];

  options.programs.godot-nix = {
    enable = lib.mkEnableOption "godot-nix";

    compiledSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };

  };

  config = lib.mkIf cfg.enable {
    home.packages = [ godotWrapped ];
  };
}
