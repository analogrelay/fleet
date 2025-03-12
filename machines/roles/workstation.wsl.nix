{ ... }:

{
    services.openssh = {
        enable = true;
        listenAddresses = [ 
            {
                addr = "0.0.0.0";
                port = 2222;
            }
        ];
    };

    programs.nix-ld.enable = true;

    networking.firewall.allowedTCPPorts = [
        2222 # sshd
    ];
}
