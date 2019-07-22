#!/bin/bash

# Used to collect statistics (min,max,avg and packet loss) of 
# packets traversing data plane paths in SDN architectures.

CONTROLLER_IP="${CONTROLLER_IP:-localhost}"
ONOS_USER="${ONOS_USER:-onos}"
ONOS_PASS="${ONOS_PASS:-rocks}"

DB_IP="${DB_IP:-172.17.0.4}"
DB_USER="${DB_USER:-postgres}"
DB_PASS="${DB_PASS:-qoe-db}"
DB_NAME="${DB_NAME:-qoe_db}"

# The amount of packets generated per second
GENERATION_RATE=5
# The total packets to be generated at each iteration
GENERATION_COUNT=10
# Total number of iterations
ITERATIONS=1

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

get_mac() {
	local mac=$(docker exec -i $1 bash -c "cat /sys/class/net/$2/address")
	echo $mac
}

generate() {
    local rate=$1
    local count=$2
	  docker exec -i mn.h1 nping -H -q1 --rate $rate -c $count --tcp -p 90 10.0.0.3
}

install_intent() {
  echo $(date) "Intent requested"
  local timestamp=$4
	curl -X POST -L -D resp_"${timestamp}".txt --user $ONOS_USER:$ONOS_PASS  \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' -d '{ 
    "type": "HostToHostIntent", 
    "appId": "org.onosproject.gui", 
    "priority":100,
    "one": "'"$1"'/None",
    "two": "'"$2"'/None",
    "selector": {
      "criteria": [
        { 
          "type": "'"$3"'",
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
  local timestamp=$1
  local location=$(grep -i Location resp_${timestamp}.txt | awk '{print $2}')
  location=${location%$'\r'}
  curl -X DELETE -G --user $ONOS_USER:$ONOS_PASS "${location}"
  $(rm resp_${timestamp}.txt)
}

insert_metric() {
  local type=$1
  local value=$2
  local uuid=$3
  if [ $value == "N/A" ]; then 
    value = -1
  fi
  query="insert into measure(datetime, \"parameter\", value, groupid) values(now(), '${type}', ${value}, '${uuid}');"
  export PGPASSWORD=${DB_PASS} && psql -h ${DB_IP} -U ${DB_USER} -d ${DB_NAME} -c "${query}"
}

main() {

    local uuid=$1

    # Check if required tools are installed in host
    if [ ! -f nmap_installed ]; then 
        install_nmap mn.h1
    fi

    # Send the install intent request to the controller
    mac_h1=$(get_mac mn.h1 h1-eth1)
    mac_h2=$(get_mac mn.h2 h2-eth1)
  
    intentDst=$(uuidgen | tail -c 12)
    install_intent $mac_h1 $mac_h2 "TCP_DST" $intentDst
    intentSrc=$(uuidgen | tail -c 12)
    install_intent $mac_h1 $mac_h2 "TCP_SRC" $intentSrc

    i=0
    while [ $i -lt $ITERATIONS ]
    do 
        generate $GENERATION_RATE $GENERATION_COUNT > results_tmp.txt
        datetime=$(grep -i at results_tmp.txt | awk '{print $8,$9,$10}')

        max_rtt=$(grep -i "max rtt" results_tmp.txt | awk '{print $3}')
        min_rtt=$(grep -i "max rtt" results_tmp.txt | awk '{print $7}')
        avg_rtt=$(grep -i "max rtt" results_tmp.txt | awk '{print $11}')

        lost=$(grep -i "rcvd" results_tmp.txt | awk '{print $12}')
        packet_loss=$(echo "$lost / $GENERATION_COUNT" | bc -l)

        insert_metric "MAX_RTT" ${max_rtt//ms} $uuid >/dev/null
        insert_metric "MIN_RTT" ${min_rtt//ms} $uuid >/dev/null
        insert_metric "AVG_RTT" ${avg_rtt//ms} $uuid >/dev/null
        insert_metric "PACKET_LOSS" ${packet_loss} $uuid >/dev/null

        echo "$GENERATION_COUNT packets generated at " $(date)
        i=$[$i+1]
        sleep 5
    done

    delete_intent "$intentDst"
    delete_intent "$intentSrc"

    rm results_tmp.txt
}
main $1

exit 0
