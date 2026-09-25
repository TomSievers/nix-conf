{
  description = "Tom's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    open-bamboo-networking = {
      url = "git+https://codeberg.org/TomSievers/open-bamboo-networking-nixos.git?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    probe-rs-rules = {
      url = "github:jneem/probe-rs-rules";
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
        let
          overlays = [
            (final: prev: {
              minicom = prev.minicom.overrideAttrs (old: {
                patches = (old.patches or [ ]) ++ [
                  ./patches/minicom-glibc-baudrate-fix.patch
                ];
              });
            })
            (final: prev: {
              unstable = import inputs.nixpkgs-unstable {
                inherit system;
                config.allowUnfree = true;
              };
            })
          ];
        in
        nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = {
            inherit inputs system hostName;
          };

          modules = [
            { nixpkgs.overlays = overlays; }
            modulePath
            home-manager.nixosModules.home-manager
            inputs.probe-rs-rules.nixosModules.${system}.default
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
