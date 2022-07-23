#################################################################
#Autor: Ederson Pereira de Brito
#posologias: usar a cada novo link pppoe-cliente ou dhcp-client
#
#www.bylltec.com.br
#################################################################
:local cont 0;
:local qtdTotalLink 0;
:local qtdLinkPppoe  [/interface pppoe-client print count-only]
:put "Localizamos total de $qtdLinkPppoe link bridge em pppoe-client"
:local qtdLink  [/ip dhcp-client print count-only]
:put "Localizamos total de $qtdLink link no dhcp-client"
:delay 2s
:set qtdTotalLink  ($qtdLinkPppoe+$qtdLink)
#configurando links pppoe-client
:foreach p in=[/interface pppoe-client find ] do={
:local nomePppoe [/interface pppoe-client get $p value-name=name];
:put $nomePppoe
:put "Removendo configuracao de balance anterior caso exista"
/ip firewall nat remove [/ip firewall nat find comment="Mascara$nomePppoe"]
/ip firewall mangle remove [/ip firewall mangle find comment="Balance$nomePppoe"]
/ip route remove [/ip route find comment="Balance$nomePppoe"]
:delay 2s
/ip firewall nat add action=masquerade chain=srcnat comment="Mascara$nomePppoe" out-interface=$nomePppoe
/ip firewall mangle add action=mark-routing chain=prerouting comment="Balance$nomePppoe" dst-address-type=!local in-interface="!$nomePppoe" new-routing-mark="rota$nomePppoe" passthrough=yes per-connection-classifier="both-addresses:$qtdTotalLink/$cont"
/ip route add check-gateway=ping comment="Balance$nomePppoe" distance=2 gateway=$nomePppoe routing-mark="rota$nomePppoe"
:set cont  ($cont+1)
:put "link $cont configurado no balance com sucesso"
}

#configurando links dhcp
:foreach h in=[/ip dhcp-client find ] do={
:global nomeEther [/ip dhcp-client get $h value-name=interface];
:global ipGateway [/ip dhcp-client get $h value-name=gateway];
:put "Removendo configuracao de balance anterior caso exista"
/ip firewall nat remove [/ip firewall nat find comment="Mascara$nomeEther"]
/ip firewall mangle remove [/ip firewall mangle find comment="Balance$nomeEther"]
/ip route remove [/ip route find comment="Balance$nomeEther"]
:delay 2s
/ip firewall nat add action=masquerade chain=srcnat comment="Mascara$nomeEther" out-interface=$nomeEther
/ip firewall mangle add action=mark-routing chain=prerouting comment="Balance$nomeEther" dst-address-type=!local in-interface="!$nomeEther" new-routing-mark="rota$nomeEther" passthrough=yes per-connection-classifier="both-addresses:$qtdTotalLink/$cont"
/ip route add check-gateway=ping comment="Balance$nomeEther" distance=2 gateway=$ipGateway routing-mark="rota$nomeEther"
:set cont  ($cont+1)
:put "link $cont configurado no balance com sucesso"
}
