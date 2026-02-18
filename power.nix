{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.power;
  isLaptop = builtins.pathExists "/sys/class/power_supply/BAT0"
    || builtins.pathExists "/sys/class/power_supply/BAT1";
in {
  config = lib.mkMerge [
    # Laptop config
    (lib.mkIf isLaptop {
      # Enable TLP
      services.tlp.enable = true;

      # Configure battery care by default
      services.tlp.settings = {
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };

      # Install tlp package for tools
      environment.systemPackages = with pkgs; [ tlp ];
    })

    # Desktop config
    (lib.mkIf (!isLaptop) {
      # Enable tuned service
      services.tuned.enable = true;

      # Set the default power profile to performance
      services.tuned.ppdSettings.main.default = "performance";

      # Install tuned tools to allow cli interactions
      environment.systemPackages = with pkgs; [ tuned ];
    })
  ];

}
