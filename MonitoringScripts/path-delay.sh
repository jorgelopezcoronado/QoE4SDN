#!/bin/bash

# Outputs the time delay between a flow request (using intents)
# and when the flow becomes operational.
#
# To run it in OSX is required to install 'coreutils' in order to use
# 'gdate' and create and alias for it.
#

CONTROLLER_IP="${CONTROLLER_IP:-localhost}"
ONOS_USER="${ONOS_USER:-onos}"
ONOS_PASS="${ONOS_PASS:-rocks}"

DB_IP="${DB_IP:-172.17.0.4}"
DB_USER="${DB_USER:-postgres}"
DB_PASS="${DB_PASS:-qoe-db}"
DB_NAME="${DB_NAME:-qoe_db}"

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

capture() {
	docker exec -d mn.h2 bash -c "tcpdump -tt -i h2-eth1 -c 1 tcp port 90 > capture.txt"
}

generate() {
	docker exec -i mn.h1 nping -c 2 --tcp -p 90 10.0.0.3
}

get_mac() {
	local mac=$(docker exec -i $1 bash -c "cat /sys/class/net/$2/address")
	echo $mac
}

install_intent() {
  echo $(date) "Intent requested"
	curl -X POST -L -D resp.txt -v --user $ONOS_USER:$ONOS_PASS  \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' -d '{ 
    "type": "HostToHostIntent", 
    "appId": "org.onosproject.gui", 
    "one": "'"$1"'/None",
    "two": "'"$2"'/None",
    "selector": {
      "criteria": [
        { 
          "type": "TCP_DST",
          "tcpPort": 90 
        }, 
        {
        "type": "IP_PROTO", 
        "protocol": 6
      }, 
        {
          "type" : "ETH_TYPE", 
          "ethType" : "0x0800" 
        }
  ]}
  }' http://"$CONTROLLER_IP":8181/onos/v1/intents &
}

delete_intent() {
  local location=$(grep -i Location resp.txt | awk '{print $2}')
  location=${location%$'\r'}
  curl -X DELETE -G --user $ONOS_USER:$ONOS_PASS "${location}"
  rm resp.txt
}

insert_metric() {
  local value=$1
  local uuid=$2
  query="insert into measure(datetime, \"parameter\", value, groupid) values(now(), 'PATH_DELAY', ${value}, '${uuid}');"
  docker run --rm -e PGPASSWORD=${DB_PASS} postgres psql -h ${DB_IP} -U ${DB_USER} -d ${DB_NAME} -c "${query}"
}

main() {

  local uuid=$1
  # Check if required tools are installed in hosts
  if [ ! -f nmap_installed ]; then 
	  install_nmap mn.h1
  fi

  if [ ! -f tcpdump_installed ]; then 
    install_tcpdump mn.h2
  fi

  # Start to capture before send the request to install intent
  capture

  # Send the install intent request to the controller
  mac_h1=$(get_mac mn.h1 h1-eth1)
  mac_h2=$(get_mac mn.h2 h2-eth1)
  
  if [[ $(uname) -eq "Darwin" ]]; then
   intent_req_date=$(date "+%s.%6N")
  else
    intent_req_date=$(date "+%s.%6N")
  fi

  install_intent $mac_h1 $mac_h2
  # Start the packet generation at host 1
  generate

  sleep 4

  # Finally process the output file from host 2 
  docker cp mn.h2:/go/src/github.com/letitbeat/packet-generator/capture.txt .
  echo "Package captured:"
  cat capture.txt

  date_captured=$(awk '{print $1}' capture.txt| tr "." " "| awk '{print $1"."$2}')
  
  diff=$(bc <<< "$date_captured - $intent_req_date")
  if [ "$diff -lt 1" ]; then
     diff=$(echo $diff*1000 | bc -l )
     echo "time diff:" ${diff} "ms"
  else
    echo "time diff:" ${diff}
  fi 
  rm capture.txt

  insert_metric $diff $uuid

  delete_intent
}

main $1
exit 0
