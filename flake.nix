{
  description = "Godot Nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs
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
      nixosModules = {
        default = self.nixosModules.godot-nix;
        godot-nix =
          { ... }:
          {
            imports = [
              # The config is HM / NixOS agnostic
              ./flake/homeManager.nix
            ];
          };
      };
    };
}
