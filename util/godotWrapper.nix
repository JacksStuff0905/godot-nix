{
  pkgs,
  editorSettings,
  godotPkg,
}:
let
  configHeader = "[gd_resource type=\"EditorSettings\" format=3]\n[resource]\n";
  configBody = pkgs.lib.generators.toINI { mkKeyValue = k: v: "${k} = ${builtins.toJSON v}"; } {
    "" = editorSettings;
  };

  # Cleanup "[]" after toINI
  configFile = pkgs.writeText "${configFileName}" (
    configHeader + (builtins.replaceStrings [ "[]\n" ] [ "" ] configBody)
  );


in
pkgs.writeShellScriptBin "godot-nix" ''
  CONF_HASH=$(basename ${configFile})
  export XDG_CONFIG_HOME="/tmp/godot-nix-config/$CONF_HASH"

  TARGET_FILE="$XDG_CONFIG_HOME/godot/${configFileName}"

  if [ ! -f "$TARGET_FILE" ]; then
    mkdir -p "$(dirname "$TARGET_FILE")"
    cp "${configFile}" "$TARGET_FILE"
    chmod +w "$TARGET_FILE"
  fi

  exec "${godotBin}" "$@"
''
