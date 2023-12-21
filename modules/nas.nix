{ config, lib, pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
        samba
        nfs-utils
    ];

    users.users.share = {
        uid = 1002;
        description = "Share User";
        shell = pkgs.zsh;
        isNormalUser = true;
        extraGroups = [ 
            "share"
        ];
    };

    # Create share directories
    systemd.tmpfiles.rules = [
        "d /mnt/data/k3s/shares 2770 share share - -"
        "d /mnt/data/shares/public 2770 share share - -"
        "d /mnt/data/shares/homes/ashley 2770 share share - -"
        "d /mnt/data/shares/homes/mary 2770 share share - -"
    ];

    # Configure samba
    services.samba = {
        enable = true;
        securityType = "user";
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
                "create mask" = "0770";
                "directory mask" = "0770";
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
        };
    };

    # Configure nfs
    services.nfs.server = {
        enable = true;
        exports = ''
            /mnt/data/shares/public 192.168.0.0/16(rw,all_squash,anonuid=1002,anongid=992) 100.64.0.0/10(rw,all_squash,anonuid=1002,anongid=992)
            /mnt/data/k3s/shares 192.168.0.0/16(rw,all_squash,anonuid=1002,anongid=992) 100.64.0.0/10(rw,all_squash,anonuid=1002,anongid=992)
        '';
    }
}