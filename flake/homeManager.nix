{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.godot-nix;

  toGodotConfig = attrs:
    lib.concatStringsSep "\n" (lib.mapAttrsToList (key: value:
      let
        formattedValue =
          if builtins.isBool value then (if value then "true" else "false")
          else if builtins.isInt value then toString value
          else if builtins.isFloat value then toString value
          # Default to string (wrapped in quotes)
          else "\"${toString value}\""; 
      in
        "${key} = ${formattedValue}"
    ) attrs);

  # 1. Define your enforced settings here
  nixGodotSettings = pkgs.writeText "nix-godot-overrides.cfg" (toGodotConfig cfg.compiledSettings);

  # 2. Create the merger script package
  mergerScript = pkgs.writeScriptBin "godot-config-merger" ''
    #!${pkgs.python3}/bin/python
    ${builtins.readFile ../util/configMerger.py}
  '';

  godotVersion = config.programs.godot-nix.package.version;
  godotShortVersion = "${pkgs.lib.versions.major godotVersion}.${pkgs.lib.versions.minor godotVersion}";

  configFileName = "editor_settings-${godotShortVersion}.tres";

  # 3. Create the Godot Wrapper
  # This creates a 'godot' command that runs the merger, then runs the real godot
  godotWrapped = pkgs.writeShellScriptBin "godot" ''
    # Ensure the config directory exists
    mkdir -p "$HOME/.config/godot"

    # Run the python merger
    # arg1: The mutable user file
    # arg2: The read-only nix file
    ${mergerScript}/bin/godot-config-merger \
      "$HOME/.config/godot/${configFileName}" \
      "${nixGodotSettings}"

    # Run the actual Godot binary
    exec ${config.programs.godot-nix.package}/bin/godot "$@"
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

    # It is best practice to allow the user to override the package
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.godot; # This assumes an overlay was applied (see below)
      description = "The package to use for godot-nix.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ godotWrapped ];
  };
}
