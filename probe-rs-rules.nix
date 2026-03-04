{ config, pkgs, ... }:

let
  probeRsRulesPkg = pkgs.writeTextFile {
    name = "probe-rs-udev-rules";
    text = builtins.readFile
      (builtins.fetchurl { url = "https://probe.rs/files/69-probe-rs.rules"; });
    destination = "/lib/udev/rules.d/69-probe-rs.rules";
  };
in {
  # Add the probe-rs udev rules to allow non-root access to supported devices
  services.udev.packages = [ probeRsRulesPkg ];

  # Add the plugdev group for users who need access to USB devices without root permissions (user need to add this group themselves)
  users.groups.plugdev = { };
}
