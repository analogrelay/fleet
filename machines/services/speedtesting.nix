{ ... }:

{
  services.iperf3 = {
    enable = true;
  };
  networking.firewall.allowedTCPPorts = [ 5201 ];
}
