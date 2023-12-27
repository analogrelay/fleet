# Get the URL to the latest build of Edge
linkid=2093504
check_url="https://go.microsoft.com/fwlink/?linkid=$linkid"

version_url=$(curl -sSL -o /dev/null -X HEAD -w %{url_effective} $check_url)

# https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/75cd594e-97c6-4e68-aa22-a48c27fec349/MicrosoftEdge-120.0.2210.91.pkg