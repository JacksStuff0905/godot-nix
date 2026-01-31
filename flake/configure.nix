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
              let
                escaped = lib.replaceStrings [ "\\" "\"" ] [ "\\\\" "\\\"" ] (toString value);
              in
              "\"${escaped}\"";
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
    configDir="$(readlink -f "${cfg.outputDir}")"

    mkdir -p "$configDir/godot/"
    mkdir -p "$configDir/data"
    mkdir -p "$configDir/cache"
    mkdir -p "$configDir/state"

    ${mergerScript}/bin/godot-config-merger \
      "$configDir/godot/${configFileName}" \
      "${nixGodotSettings}"

    # Move the config
    export XDG_CONFIG_HOME="$configDir"
    export XDG_DATA_HOME="$configDir/data"
    export XDG_CACHE_HOME="$configDir/cache"
    export XDG_STATE_HOME="$configDir/state"

    ${lib.getExe cfg.package} "$@"
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
    programs.godot-nix.compiledPackage = godotWrapped;
  };
}
