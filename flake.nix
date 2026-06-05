{
  description = "Tom's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    open-bamboo-networking = {
      url = "git+https://codeberg.org/TomSievers/open-bamboo-networking-nixos.git?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      mkHost =
        hostName: modulePath:
        nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = {
            inherit inputs hostName;
          };

          modules = [
            modulePath
            home-manager.nixosModules.home-manager
          ];
        };
    in
    {
      nixosConfigurations = {
        desktop = mkHost "desktop" ./hosts/desktop/configuration.nix;
        laptop = mkHost "laptop" ./hosts/laptop/configuration.nix;
        work = mkHost "work" ./hosts/work/configuration.nix;
      };
    };
}
