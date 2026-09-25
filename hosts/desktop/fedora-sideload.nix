{ config, pkgs, ... }:

{
  boot.loader = {
    systemd-boot = {
      extraEntries = {
        "fedora42.conf" = ''
          title Fedora42
          efi /efi/fedora/grubx64.efi
          sort-key z_fedora
        '';
      };
    };
  };
}
