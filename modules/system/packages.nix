# System-wide programs and packages. Only tools that root (or the whole system)
# needs live here; user-only applications belong in home.packages in
# modules/user.nix, project toolchains in a project devshell.

{ pkgs, ... }:

{
  # Allow nonfree packages like vscode
  nixpkgs.config.allowUnfree = true;

  # Enable vim (also the editor available to root)
  programs.vim.enable = true;
  # Enable fwupd to update firmware on supported devices.
  services.fwupd.enable = true;
  # Enable GVFS for mounting network shares in file managers
  services.gvfs.enable = true;

  # Installs wireshark with the capture-capable dumpcap wrapper for the wireshark group.
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };

  # Enable steam
  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    # Default command line tools
    curl
    wget
    parted
    ncdu
    git

    gparted
    wireguard-tools
    wg-netmanager
  ];
}
