# Hardware access for embedded development. The tools themselves come from
# project devshells; this only installs the udev rules so they work without root.

{ pkgs, ... }:

{
  # probe-rs udev rules (from the probe-rs-rules flake input).
  hardware.probe-rs.enable = true;

  users.groups.plugdev = { };

  services.udev.packages = with pkgs; [
    stlink
    openocd
  ];
}
