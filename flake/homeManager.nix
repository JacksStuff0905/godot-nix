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
    mkdir -p "${cfg.output-dir}/godot/"
    mkdir -p "${cfg.output-dir}/data"
    mkdir -p "${cfg.output-dir}/cache"
    mkdir -p "${cfg.output-dir}/state"

    ${mergerScript}/bin/godot-config-merger \
      "${cfg.output-dir}/godot/${configFileName}" \
      "${nixGodotSettings}"

    # Move the config
    export XDG_CONFIG_HOME="${cfg.output-dir}"
    export XDG_DATA_HOME="${cfg.output-dir}/data"
    export XDG_CACHE_HOME="${cfg.output-dir}/cache"
    export XDG_STATE_HOME="${cfg.output-dir}/state"

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
    home.packages = [ godotWrapped ];
  };
}
