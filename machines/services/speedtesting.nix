{ pkgs, ... }:

let
  textfileDir = "/var/lib/prometheus-textfile";
  promFile = "${textfileDir}/speedtest.prom";

  speedtestScript = pkgs.writeShellScript "speedtest-to-prom" ''
    set -euo pipefail

    tmp="${promFile}.tmp.$$"
    trap 'rm -f "$tmp"' EXIT

    if result=$(${pkgs.speedtest-cli}/bin/speedtest-cli --json 2>/dev/null); then
      download=$(echo "$result" | ${pkgs.jq}/bin/jq -r '.download')
      upload=$(echo "$result" | ${pkgs.jq}/bin/jq -r '.upload')
      ping_seconds=$(echo "$result" | ${pkgs.jq}/bin/jq -r '.ping / 1000')
      server_id=$(echo "$result" | ${pkgs.jq}/bin/jq -r '.server.id')
      server_name=$(echo "$result" | ${pkgs.jq}/bin/jq -r '.server.sponsor')
      isp=$(echo "$result" | ${pkgs.jq}/bin/jq -r '.client.isp')
      timestamp=$(date +%s)

      cat > "$tmp" <<PROM
    # HELP speedtest_download_bits_per_second Download speed in bits per second
    # TYPE speedtest_download_bits_per_second gauge
    speedtest_download_bits_per_second{server_id="$server_id",server_name="$server_name",isp="$isp"} $download
    # HELP speedtest_upload_bits_per_second Upload speed in bits per second
    # TYPE speedtest_upload_bits_per_second gauge
    speedtest_upload_bits_per_second{server_id="$server_id",server_name="$server_name",isp="$isp"} $upload
    # HELP speedtest_ping_seconds Latency in seconds
    # TYPE speedtest_ping_seconds gauge
    speedtest_ping_seconds{server_id="$server_id",server_name="$server_name",isp="$isp"} $ping_seconds
    # HELP speedtest_up Whether the last speedtest was successful
    # TYPE speedtest_up gauge
    speedtest_up 1
    # HELP speedtest_run_timestamp_seconds Unix timestamp of the last speedtest run
    # TYPE speedtest_run_timestamp_seconds gauge
    speedtest_run_timestamp_seconds $timestamp
    PROM
    else
      cat > "$tmp" <<PROM
    # HELP speedtest_up Whether the last speedtest was successful
    # TYPE speedtest_up gauge
    speedtest_up 0
    PROM
    fi

    mv "$tmp" "${promFile}"
  '';
in
{
  services.iperf3 = {
    enable = true;
  };
  networking.firewall.allowedTCPPorts = [ 5201 ];

  # Ensure the textfile collector directory exists
  systemd.tmpfiles.rules = [
    "d ${textfileDir} 0755 root root -"
  ];

  systemd.services.speedtest = {
    description = "Run speedtest-cli and export Prometheus metrics";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = speedtestScript;
      ReadWritePaths = [ textfileDir ];
      TimeoutStartSec = 120;
    };
  };

  systemd.timers.speedtest = {
    description = "Hourly internet speed test";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      RandomizedDelaySec = "5m";
      Persistent = true;
    };
  };
}
