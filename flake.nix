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
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages."${system}";
      in
      {
        packages.default = pkgs.callPackage (
          { settings ? {} }:
          ((pkgs.lib.evalModules {
            specialArgs = { inherit pkgs; };
            modules = [
              ./flake/configure.nix
              {
                config.programs.godot-nix.enable = true;
                config.programs.godot-nix.settings = settings;
              }
            ];
          }).config.programs.godot-nix.compiledPackage
          )
        ) { };
      }
    )
    // {
      homeManagerModules = {
        default = self.homeManagerModules.godot-nix;
        godot-nix =
          { config, lib, ... }:
          {
            imports = [
              ./flake/configure.nix
            ];

            config = lib.mkIf config.programs.godot-nix.enable {
              home.packages = [ config.programs.godot-nix.compiledPackage ];
            };
          };
      };
      nixosModules = {
        default = self.nixosModules.godot-nix;
        godot-nix =
          { config, lib, ... }:
          {
            imports = [
              # The config is HM / NixOS agnostic
              ./flake/configure.nix
            ];

            config = lib.mkIf config.programs.godot-nix.enable {
              environment.systemPackages = [ config.programs.godot-nix.compiledPackage ];
            };
          };
      };
    };
}
