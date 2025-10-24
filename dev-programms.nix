{ config, pkgs, ... }:

{
  # Install firefox
  programs.firefox.enable = true;
  programs.vim.enable = true;
  
  # Allow nonfree packages like vscode
  nixpkgs.config.allowUnfree = true;
  
  environment.systemPackages = with pkgs; [
    # Add necesary packages for podman
    podman-compose
    # Commandline tools
    vim
    curl
    wget
    bmaptool
    rpiboot
    gcc
    clang_21
    parted
    ncdu
    git
    cmake
    automake

    # GUI tools
    rpi-imager
    gparted
    sourcegit
    (
      vscode-with-extensions.override {
        vscodeExtensions = with pkgs.vscode-extensions; [
          ms-python.python
          ms-vscode-remote.vscode-remote-extensionpack
          jnoortheen.nix-ide
        ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      	  {
            name = "docker";
            publisher = "docker";
            version = "0.18.0";
            sha256 = "a5XlZL7jExYPhz1HODCgvw29JTf7DNyUBFQWYe+4dmA=";
	        }
          {
            name = "vscode-containers";
            publisher = "ms-azuretools";
            version = "2.2.0";
            sha256 = "UxWsu7AU28plnT0QMdpPJrcYZIV09FeC+rmYKf39a6M=";
          }
          {
            name = "git-graph";
            publisher = "mhutchie";
            version = "1.30.0";
            sha256 = "sHeaMMr5hmQ0kAFZxxMiRk6f0mfjkg2XMnA4Gf+DHwA=";
          }
        ];
      }
    )
    
    # Other
    home-manager
  ];

  # Make sure that vscode uses wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Do some podman configuration.
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
  };
}
