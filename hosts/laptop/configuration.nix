{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  power.isLaptop = true;

  fileSystems."/mnt/share" = {
    device = "192.168.2.9:/mnt/share";
    fsType = "nfs";
    options = [
      "defaults"
      "x-systemd.mount-timeout=10"
      "x-systemd.idle-timeout=2min"
      "x-systemd.automount"
      "nofail"
      "noauto"
      "soft"
      "retrans=10"
      "retry=0"
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
