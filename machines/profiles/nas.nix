{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ samba nfs-utils ];

  networking.firewall.allowedTCPPorts = [
    # We're supporting NFSv4 only for now.
    2049 # nfsd

    # Open the FTP port for the cabinet.
    21 # ftp
  ];

  # Create share directories
  systemd.tmpfiles.rules = [
    "d /mnt/data/k3s/shares 2770 share share - -"
    "d /mnt/data/shares/hassbackup 2770 share share - -"
    "d /mnt/data/shares/public 2770 share share - -"
    "d /mnt/data/shares/public/downloads 2770 share share - -"
    "d /mnt/data/shares/homes/ashley 2750 ashley share - -"
    "d /mnt/data/shares/homes/mary 2750 mary share - -"
  ];

  # Configure Aria2c downloader
  services.aria2 = {
    enable = true;
    openPorts = true;
    rpcListenPort = 6800;
    extraArguments = "--rpc-listen-all";
    listenPortRange = [{
      from = 6881;
      to = 6999;
    }];
    downloadDir = "/mnt/data/shares/public/downloads";
  };

  # Configure samba
  services.samba = {
    enable = true;
    securityType = "user";
    openFirewall = true;
    extraConfig = ''
      workgroup = GAIA
      server string = ${config.networking.hostName}
      netbios name = ${config.networking.hostName}
      security = user
      guest account = nobody
    '';
    shares = {
      public = {
        path = "/mnt/data/shares/public";
        browsable = true;
        "read only" = false;
        "create mask" = "0775";
        "directory mask" = "0775";
        "force user" = "share";
        "force group" = "share";
      };
      homes = {
        path = "/mnt/data/shares/homes/%S";
        browsable = true;
        "read only" = false;
        "create mask" = "0700";
        "directory mask" = "0700";
      };
      k3s = {
        path = "/mnt/data/k3s/shares";
        browsable = true;
        "read only" = false;
        "create mask" = "0770";
        "directory mask" = "0770";
        "force user" = "root";
        "force group" = "wheel";
      };
      hassbackup = {
        path = "/mnt/data/shares/hassbackup";
        browsable = true;
        "read only" = false;
        "create mask" = "0775";
        "directory mask" = "0775";
        "force user" = "share";
        "force group" = "share";
      };
    };
  };

  # Configure nfs
  services.nfs.server = let
    exportOptions = "rw,all_squash,anonuid=${
        builtins.toString config.users.users.share.uid
      },anongid=${builtins.toString config.users.groups.share.gid}";
  in {
    enable = true;
    exports = ''
      /mnt/data/shares/public 127.0.0.1/8(${exportOptions})
      /mnt/data/shares/public 10.0.0.0/8(${exportOptions})
      /mnt/data/shares/public 192.168.0.0/16(${exportOptions})
      /mnt/data/k3s/shares 127.0.0.1/8(${exportOptions})
      /mnt/data/k3s/shares 10.0.0.0/8(${exportOptions})
      /mnt/data/k3s/shares 192.168.0.0/16(${exportOptions})
    '';
  };

  # Configure an FTP server that can only write to the cabinet consume directory
  # Start with a bind mount to create a directory that can be written to by the anonymous user
  fileSystems."/var/ftp/anon/consume" = {
    device = "/mnt/data/shares/public/cabinet/consume";
    options = [ "bind" ];
  };
  services.vsftpd = {
    enable = true;
    localUsers = false;
    writeEnable = true;
    anonymousUser = true;
    anonymousUmask = "000";
    anonymousUserHome = "/var/ftp/anon";
    anonymousUserNoPassword = true;
    anonymousUploadEnable = true;
    allowWriteableChroot = true;
  };
}
