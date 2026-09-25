{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./fedora-sideload.nix
    ../common.nix
  ];

  # TODO: set to the path of this repo's checkout on the desktop.
  # nixConf.flakeDir = "/etc/nixos/...";

  # Extra data disk at /data (because Arduino IDE).
  fileSystems."/data" = {
    device = "UUID=655194e4-7d22-4454-930a-295a5f599150";
    fsType = "ext4";
    options = [
      "defaults"
      "x-systemd.device-timeout=500ms"
      "x-systemd.automount"
      "nofail"
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
