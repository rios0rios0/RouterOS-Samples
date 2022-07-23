# jan/16/2020 01:55:16 by RouterOS 6.43.8
#
# model = RouterBOARD 750 r2
#
/interface bridge
add name="Ponte de Seguran\E7a"
/interface ethernet
set [ find default-name=ether1 ] name="Entrada do Provedor"
set [ find default-name=ether2 ] name="Sa\EDda 01 - Aberta"
set [ find default-name=ether3 ] name="Sa\EDda 02 - Protegida"
set [ find default-name=ether4 ] name="Sa\EDda 03 - Protegida"
set [ find default-name=ether5 ] name="Sa\EDda 04 - Protegida"
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/ip firewall layer7-protocol
add name=Google regexp="^.+(google.com).*\$"
add name=Youtube regexp="^.+(youtube.com).*\$"
/ip hotspot profile
set [ find default=yes ] html-directory=flash/hotspot
/ip pool
add name="Pilha Aberta" ranges=172.31.0.2
add name="Pilha Protegida" ranges=172.31.1.3-172.31.1.254
/ip dhcp-server
add address-pool="Pilha Aberta" disabled=no interface="Sa\EDda 01 - Aberta" \
    name="DHCP Aberto"
add address-pool="Pilha Protegida" disabled=no interface=\
    "Ponte de Seguran\E7a" name="DHCP Protegido"
/interface bridge port
add bridge="Ponte de Seguran\E7a" interface="Sa\EDda 04 - Protegida"
add bridge="Ponte de Seguran\E7a" interface="Sa\EDda 03 - Protegida"
add bridge="Ponte de Seguran\E7a" interface="Sa\EDda 02 - Protegida"
/ip address
add address=172.31.0.1/24 interface="Sa\EDda 01 - Aberta" network=172.31.0.0
add address=172.31.1.1/24 interface="Ponte de Seguran\E7a" network=172.31.1.0
/ip dhcp-client
add dhcp-options=hostname,clientid disabled=no interface=\
    "Entrada do Provedor"
/ip dhcp-server network
add address=172.31.0.0/24 gateway=172.31.0.1
add address=172.31.1.0/24 gateway=172.31.1.1
/ip firewall address-list
add address=assetsnffrgf-a.akamaihd.net list=JW
add address=download-a.akamaihd.net list=JW
add address=jw.org list=JW
add address=tv.jw.org list=JW
add address=wol.jw.org list=JW
add address=mediator.jw.org list=JW
add address=172.31.1.2 list=JW
add address=172.31.0.2 list=JW
add address=e.crashlytics.com list=JW
add address=api.hag27.com list=JW
/ip firewall filter
add action=accept chain=forward comment="JW List" dst-address-list=JW
add action=accept chain=forward dst-address=192.168.1.254
add action=accept chain=forward dst-address-type="" src-address=192.168.1.254 \
    src-address-type=""
add action=accept chain=forward dst-address=200.160.0.8
add action=accept chain=forward src-address=200.160.0.8
add action=accept chain=forward dst-address=177.71.206.0/24
add action=accept chain=forward src-address=177.71.206.0/24
add action=reject chain=forward comment="HTTPS Block" dst-port=443 protocol=\
    tcp reject-with=icmp-network-unreachable src-address=!172.31.0.2
add action=reject chain=forward comment="Push Notify Block" dst-port=2195 \
    protocol=tcp reject-with=icmp-network-unreachable src-address=!172.31.0.2
add action=reject chain=forward comment="Block Layer 7 Google" dst-address=\
    !172.31.0.2 layer7-protocol=Google reject-with=icmp-network-unreachable \
    src-address=!172.31.0.2
add action=reject chain=forward comment="Block Layer 7 Youtube" dst-address=\
    !172.31.0.2 layer7-protocol=Youtube reject-with=icmp-network-unreachable \
    src-address=!172.31.0.2
add action=reject chain=forward comment="Block All Trafic" dst-address=\
    !172.31.0.2 dst-address-list=!JW log=yes log-prefix=blocked reject-with=\
    icmp-network-unreachable src-address=!172.31.0.2 src-address-list=!JW
/ip firewall nat
add action=masquerade chain=srcnat
add action=dst-nat chain=dstnat dst-address=172.31.1.2 to-addresses=\
    172.31.0.2
add action=src-nat chain=srcnat src-address=172.31.0.2 to-addresses=\
    172.31.1.2
add action=redirect chain=dstnat comment="Redirect to WebProxy" dst-port=80 \
    protocol=tcp to-ports=8080
/ip proxy
set enabled=yes
/ip proxy access
add comment=wol.jw.org dst-host=wol.jw.org
add comment=tv.jw.org dst-host=tv.jw.org
add comment=jw.org dst-host=jw.org
add action=deny comment="Redirect to jw.org" disabled=yes redirect-to=jw.org \
    src-address=!172.31.0.2
/system clock
set time-zone-name=America/Sao_Paulo
/tool sniffer
set file-name=test streaming-enabled=yes streaming-server=172.31.1.254
