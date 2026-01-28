{
  settings,
  pkgs
} : 
let
  configHeader = "[gd_resource type=\"EditorSettings\" format=3]\n[resource]\n";
  configBody = pkgs.lib.generators.toINI { mkKeyValue = k: v: "${k} = ${builtins.toJSON v}"; } {
    "" = settings;
  };
in
  # Cleanup "[]" after toINI
  configHeader + (builtins.replaceStrings [ "[]\n" ] [ "" ] configBody)
