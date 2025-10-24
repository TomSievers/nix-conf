{ config, pkgs, ... }:

{
  # Add Zsh as a user shell
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;

    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild switch";
    };

    histSize = 2000;
    histFile = "$HOME/.zsh_history";
    setOptions = [
      "HIST_IGNORE_ALL_DUPS"
    ];

    # Shell visuals
    ohMyZsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "amuse";
    };
  };

  users.defaultUserShell = pkgs.zsh;

  # Create default user
  users.users.tom = {
    isNormalUser = true;
    description = "Tom S.";
    extraGroups = [ "networkmanager" "wheel" "dialout" ];
    createHome = true;
  };
}
