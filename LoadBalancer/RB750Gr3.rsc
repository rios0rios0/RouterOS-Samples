# jul/22/2022 23:03:25 by RouterOS 6.47.10
#
# model = RB750Gr3
#
/interface bridge
add name="Default Bridge"
/interface ethernet
set [ find default-name=ether1 ] comment=bahialink name=1-WAN1
set [ find default-name=ether2 ] comment=lexcom name=2-WAN2
set [ find default-name=ether3 ] comment=localhost name=3-LAN
set [ find default-name=ether4 ] name=4-LAN
set [ find default-name=ether5 ] name=5-LAN
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/ip hotspot profile
set [ find default=yes ] html-directory=flash/hotspot
/ip pool
add name="Default Pool" ranges=10.10.10.2-10.10.10.254
/ip dhcp-server
add address-pool="Default Pool" disabled=no interface="Default Bridge" name=\
    "Default DHCP"
/interface bridge port
add bridge="Default Bridge" interface=3-LAN
add bridge="Default Bridge" interface=4-LAN
add bridge="Default Bridge" interface=5-LAN
/ip neighbor discovery-settings
set discover-interface-list=!dynamic
/ip address
add address=10.10.10.1/24 interface="Default Bridge" network=10.10.10.0
/ip dhcp-client
add disabled=no interface=1-WAN1 use-peer-dns=no use-peer-ntp=no
add disabled=no interface=2-WAN2 use-peer-dns=no use-peer-ntp=no
/ip dhcp-server network
add address=10.10.10.0/24 gateway=10.10.10.1
/ip dns
set servers=8.8.8.8,8.8.4.4
/ip firewall mangle
add action=mark-routing chain=prerouting comment=Balance1-WAN1 \
    dst-address-type=!local in-interface=!1-WAN1 new-routing-mark=Route1-WAN1 \
    passthrough=yes per-connection-classifier=both-addresses:2/0
add action=mark-routing chain=prerouting comment=Balance2-WAN2 \
    dst-address-type=!local in-interface=!2-WAN2 new-routing-mark=Route2-WAN2 \
    passthrough=yes per-connection-classifier=both-addresses:2/1
/ip firewall nat
add action=masquerade chain=srcnat comment=Mask1-WAN1 out-interface=1-WAN1
add action=masquerade chain=srcnat comment=Mask2-WAN2 out-interface=2-WAN2
/ip route
add check-gateway=ping comment=Balance1-WAN1 distance=2 gateway=10.0.0.1 \
    routing-mark=Route1-WAN1
add check-gateway=ping comment=Balance2-WAN2 distance=2 gateway=192.168.10.1 \
    routing-mark=Route2-WAN2
/system clock
set time-zone-name=America/Bahia
/system script
add dont-require-permissions=no name=AUTO-BALANCE owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="#\
    ################################################################\r\
    \n# Author: Ederson Pereira de Brito (www.bylltec.com.br)\r\
    \n# Posology: use every new DHCP-Client link\r\
    \n#################################################################\r\
    \n\r\
    \n:local cont 0;\r\
    \n:local qtdTotalLink 0;\r\
    \n:local qtdLinkPppoe  [/interface pppoe-client print count-only]\r\
    \n:put \"Found a total of \$qtdLinkPppoe link bridge em pppoe-client\"\r\
    \n:local qtdLink  [/ip dhcp-client print count-only]\r\
    \n:put \"Found a total of \$qtdLink link no dhcp-client\"\r\
    \n:delay 2s\r\
    \n:set qtdTotalLink  (\$qtdLinkPppoe+\$qtdLink)\r\
    \n\r\
    \n# PPoE-Client Configuration\r\
    \n:foreach p in=[/interface pppoe-client find ] do={\r\
    \n:local nomePppoe [/interface pppoe-client get \$p value-name=name];\r\
    \n:put \$nomePppoe\r\
    \n\r\
    \n:put \"Removing previous balancing configuration\"\r\
    \n/ip firewall nat remove [/ip firewall nat find comment=\"Mask\$nomePppoe\
    \"]\r\
    \n/ip firewall mangle remove [/ip firewall mangle find comment=\"Balance\$\
    nomePppoe\"]\r\
    \n/ip route remove [/ip route find comment=\"Balance\$nomePppoe\"]\r\
    \n\r\
    \n:delay 2s\r\
    \n/ip firewall nat add action=masquerade chain=srcnat comment=\"Mask\$nome\
    Pppoe\" out-interface=\$nomePppoe\r\
    \n/ip firewall mangle add action=mark-routing chain=prerouting comment=\"B\
    alance\$nomePppoe\" dst-address-type=!local in-interface=\"!\$nomePppoe\" \
    new-routing-mark=\"Route\$nomePppoe\" passthrough=yes per-connection-class\
    ifier=\"both-addresses:\$qtdTotalLink/\$cont\"\r\
    \n/ip route add check-gateway=ping comment=\"Balance\$nomePppoe\" distance\
    =2 gateway=\$nomePppoe routing-mark=\"Route\$nomePppoe\"\r\
    \n:set cont  (\$cont+1)\r\
    \n:put \"Link \$cont set up successfully\"\r\
    \n}\r\
    \n\r\
    \n# DHCP Configuration\r\
    \n:foreach h in=[/ip dhcp-client find ] do={\r\
    \n:global nomeEther [/ip dhcp-client get \$h value-name=interface];\r\
    \n:global ipGateway [/ip dhcp-client get \$h value-name=gateway];\r\
    \n\r\
    \n:put \"Removing previous balancing configuration\"\r\
    \n/ip firewall nat remove [/ip firewall nat find comment=\"Mask\$nomeEther\
    \"]\r\
    \n/ip firewall mangle remove [/ip firewall mangle find comment=\"Balance\$\
    nomeEther\"]\r\
    \n/ip route remove [/ip route find comment=\"Balance\$nomeEther\"]\r\
    \n\r\
    \n:delay 2s\r\
    \n/ip firewall nat add action=masquerade chain=srcnat comment=\"Mask\$nome\
    Ether\" out-interface=\$nomeEther\r\
    \n/ip firewall mangle add action=mark-routing chain=prerouting comment=\"B\
    alance\$nomeEther\" dst-address-type=!local in-interface=\"!\$nomeEther\" \
    new-routing-mark=\"Route\$nomeEther\" passthrough=yes per-connection-class\
    ifier=\"both-addresses:\$qtdTotalLink/\$cont\"\r\
    \n/ip route add check-gateway=ping comment=\"Balance\$nomeEther\" distance\
    =2 gateway=\$ipGateway routing-mark=\"Route\$nomeEther\"\r\
    \n:set cont  (\$cont+1)\r\
    \n:put \"Link \$cont set up successfully\"\r\
    \n}\r\
    \n"
