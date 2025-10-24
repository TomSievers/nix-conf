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
          #donjayamanne.python-extension-pack
          ms-vscode-remote.vscode-remote-extensionpack
          #docker.docker
          #ms-azuretools.vscode-containers
          #mhutchie.git-graph
        ];
      }
    )
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
