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

    networking.firewall.allowedTCPPorts = [
        2222 # sshd
    ];
}
