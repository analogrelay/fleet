{ ... }:

{
  services.iperf3 = {
    enable = true;
    openFirewall = true;
    port = 7575;
  };
}
