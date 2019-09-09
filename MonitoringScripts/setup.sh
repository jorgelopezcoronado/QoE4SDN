#!/bin/bash

# Implements methods to install the tools required by the monitoring scripts 
# in the simulated hosts.
# Intended to be used as "library".

set_tz() {
  local container=$1
  docker exec $container cp /usr/share/zoneinfo/Europe/Paris /etc/localtime
}

install_nmap() {
  local container=$1
  set_tz $container
  docker exec -it $container bash -c "apt-get install nmap -y"
  touch nmap_installed
}

install_tcpdump() {
  local container=$1
  set_tz $container 
	docker exec $container bash -c "apt-get install tcpdump -y"
	touch tcpdump_installed
}

get_mac() {
	local mac=$(docker exec -i $1 bash -c "cat /sys/class/net/$2/address")
	echo $mac
}