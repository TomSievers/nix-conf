{ config, lib, pkgs, ... }:

with lib;

let cfg = config.disks;
in {
  options.disks = {
    enableDataMount =
      mkEnableOption "Enable mount at /data (because Arduino IDE)";
  };

  config = mkMerge [
    # Optional extra data mount
    (mkIf cfg.enableDataMount {
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
    })
    {
      # Default NFS home mount
      fileSystems."/mnt/share" = {
        device = "192.168.2.9:/mnt/share";
        fsType = "nfs";
        options = [
          "defaults"
          "x-systemd.mount-timeout=10"
          "x-systemd.idle-timeout=2min"
          "x-systemd.automount"
          "nofail"
        ];
      };
    }
  ];
}

