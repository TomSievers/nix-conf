{ config, pkgs, ... }:

{
  # Add Zsh as a user shell
  programs.zsh = {
    enable = true;
    ohMyZsh.enable = true;
    ohMyZsh.theme = "lambda";
    autosuggestions.enable = true;
  };

  # Create default user
  users.users.tom = {
    isNormalUser = true;
    description = "Tom S.";
    extraGroups = [ "networkmanager" "wheel" "dialout" ];
    shell = pkgs.zsh;
    createHome = true;
  };
}
