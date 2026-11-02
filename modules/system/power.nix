{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.power;
  isLaptop = cfg.isLaptop;
  logFile = "/var/log/power.log";
  batt = cfg.battery;
in
{
  # Set per host: detecting /sys/class/power_supply at evaluation time does not
  # work with flakes, because pure evaluation cannot see /sys.
  options.power = {
    isLaptop = mkEnableOption "laptop power management (tuned balanced profile, battery logging)";
    battery = mkOption {
      type = types.str;
      default = "BAT0";
      description = "Battery name under /sys/class/power_supply used for sleep logging.";
    };
  };

  config = lib.mkMerge [
    # Laptop config
    (lib.mkIf isLaptop {
      # # Enable TLP
      # services.tlp.enable = true;
      # services.power-profiles-daemon.enable = false;

      # # Configure battery care by default
      # services.tlp.settings = {
      #   START_CHARGE_THRESH_BAT0 = 75;
      #   STOP_CHARGE_THRESH_BAT0 = 80;
      # };

      # # Install tlp package for tools
      # environment.systemPackages = with pkgs; [ tlp ];

      services.tuned.enable = true;

      # Set the default power profile to balanced for laptops
      services.tuned.ppdSettings.main.default = "balanced";

      # Install tuned tools to allow cli interactions
      environment.systemPackages = with pkgs; [
        tuned
        coreutils
      ];

      # Enable dynamic tuning to allow automatic switching between power profiles based on power source
      services.tuned.settings.dynamic_tuning = true;
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
