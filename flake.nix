{
  description = "Godot Nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    {
      homeManagerModules = {
        default = self.homeManagerModules.godot-nix;
        godot-nix =
          { ... }:
          {
            imports = [
              ./flake/homeManager.nix
            ];
          };
      };
    };
}
