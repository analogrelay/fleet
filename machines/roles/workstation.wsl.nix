{ ... }:

{
    services.openssh = {
        enable = true;
        listenAddresses = [ 
            {
                addr = "0.0.0.0";
                port = 22;
            }
        ];
    };

    networking.firewall.allowedTCPPorts = [
        22 # sshd
    ];
}