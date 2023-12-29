# 2023-12-28 15:41:47 by RouterOS 7.12.1
# software id = SMCM-TX9U
#
# model = RB5009UG+S+
# serial number = HFB09B7RXAZ
/interface bridge
add name=local
/interface list
add comment="WAN interface(s)" name=wan
add comment="LAN interfaces" name=lan
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/ip dhcp-server option
add code=12 name=hostname
/ip pool
add name=dhcp_pool0 ranges=192.168.10.0/24
/ip dhcp-server
add address-pool=dhcp_pool0 interface=local lease-time=10m name=dhcp1
/interface bridge port
add bridge=local interface=ether2
add bridge=local interface=ether3
add bridge=local interface=ether4
add bridge=local interface=ether5
add bridge=local interface=ether6
add bridge=local interface=ether7
add bridge=local interface=ether8
/interface list member
add interface=ether1 list=wan
add interface=ether2 list=lan
add interface=ether3 list=lan
add interface=ether4 list=lan
add interface=ether5 list=lan
add interface=ether6 list=lan
add interface=ether7 list=lan
add interface=ether8 list=lan
/ip address
add address=192.168.1.1/16 interface=local network=192.168.0.0
/ip dhcp-client
add interface=ether1
/ip dhcp-server lease
add address=192.168.2.1 comment=avalanche.node.analogrelay.net mac-address=\
    74:56:3C:75:F4:26
add address=192.168.2.2 comment=shinra.node.analogrelay.net mac-address=\
    7C:C2:C6:45:A8:30
add address=192.168.3.1 comment=sephiroth.node.analogrelay.net mac-address=\
    F8:4D:89:5E:3C:4D
add address=192.168.2.4 comment=cid.node.analogrelay.net mac-address=\
    00:11:32:24:87:9D
add address=192.168.3.2 client-id=1:d4:5d:64:d3:5f:82 comment=\
    cloud.node.analogrelay.net mac-address=D4:5D:64:D3:5F:82 server=dhcp1
add address=192.168.1.3 comment=wutai.node.analogrelay.net mac-address=\
    C4:41:1E:36:EB:30
add address=192.168.1.2 comment=midgar.node.analogrelay.net mac-address=\
    E8:9F:80:1C:6C:68
add address=192.168.2.11 comment=jessie.node.analogrelay.net mac-address=\
    E4:5F:01:46:2A:77 server=dhcp1
add address=192.168.2.10 client-id=\
    ff:52:e8:67:8e:0:2:0:0:ab:11:c8:6e:88:7c:b7:f:81:d1 comment=\
    reno.node.analogrelay.net mac-address=B8:27:EB:0C:A3:D8 server=dhcp1
/ip dhcp-server network
add address=192.168.0.0/16 gateway=192.168.1.1
/ip firewall filter
add action=accept chain=input comment="accept established,related" \
    connection-state=established,related
add action=drop chain=input connection-state=invalid
add action=accept chain=input comment="allow ICMP" in-interface=ether1 \
    protocol=icmp
add action=accept chain=input comment="allow Winbox" in-interface=ether1 \
    port=8291 protocol=tcp
add action=accept chain=input comment="allow SSH" in-interface=ether1 port=22 \
    protocol=tcp
add action=drop chain=input in-interface=ether1
/ip firewall nat
add action=masquerade chain=srcnat out-interface=ether1
/ip ssh
set always-allow-password-login=yes host-key-type=ed25519 strong-crypto=yes
/system clock
set time-zone-name=America/Los_Angeles
/system note
set show-at-login=no
