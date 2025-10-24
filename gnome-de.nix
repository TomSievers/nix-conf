{ config, pkgs, ... }:

{
  # Make sure that XWayland is enabled to allow compatibility
  programs.xwayland.enable = true;

  # Configure Xserver for gnome desktop while using Wayland (I known confusing right?)
  services.xserver.enable = true;
  services.xserver.displayManager.gdm = {
    enable = true;
    wayland = true;
  };
  services.xserver.desktopManager.gnome.enable = true;

  # Setup the keyboard keymap
  services.xserver.xkb.layout = "us";
  # Make consoles use xkb config to only need to set the language once.
  console.useXkbConfig = true;
}
