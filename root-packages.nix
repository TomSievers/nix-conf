{ config, pkgs, ... }:

{
  # Install firefox
  programs.firefox.enable = true;
  programs.vim.enable = true;
  
  # Allow nonfree packages like vscode
  nixpkgs.config.allowUnfree = true;
  
  environment.systemPackages = with pkgs; [
    podman-compose
    # Default command line tools
    curl
    wget
    bmaptool
    rpiboot
    parted
    ncdu
    avrdude
    probe-rs-tools

    nixfmt-classic

    nerd-fonts.adwaita-mono
  ];
}
