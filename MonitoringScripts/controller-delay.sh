#!/bin/bash

# Used to perform requests to the statistics endpoint available ONOS
# the time the controller takes to reply will be captured and stored 
# in database.

CONTROLLER_IP="${CONTROLLER_IP:-localhost}"
ONOS_USER="${ONOS_USER:-onos}"
ONOS_PASS="${ONOS_PASS:-rocks}"

DB_IP="${DB_IP:-172.17.0.4}"
DB_USER="${DB_USER:-postgres}"
DB_PASS="${DB_PASS:-qoe-db}"
DB_NAME="${DB_NAME:-qoe_db}"

# The amount of packets generated per second
GENERATION_RATE=5
# The total packets to be
GENERATION_COUNT=100

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
	curl -X POST -L -D resp_$timestamp.txt --user $ONOS_USER:$ONOS_PASS  \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' -d '{ 
    "type": "HostToHostIntent", 
    "appId": "org.onosproject.gui", 
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
  local location=$(grep -i Location resp_$timestamp.txt | awk '{print $2}')
  location=${location%$'\r'}
  curl -X DELETE -G --user $ONOS_USER:$ONOS_PASS "${location}"
  
  rm resp_$timestamp.txt
}

insert_metric() {
  local type=$1
  local value=$2
  local uuid=$3
  query="insert into measure(datetime, \"parameter\", value, groupid) values(now(), '${type}', ${value}, '${uuid}');"
  export PGPASSWORD=${DB_PASS} && postgres psql -h ${DB_IP} -U ${DB_USER} -d ${DB_NAME} -c "${query}"
}

send_request() {

    curl -o /dev/null -s -w '%{time_total}'  \
    --user $ONOS_USER:$ONOS_PASS \
    http://"$CONTROLLER_IP":8181/onos/v1/statistics
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

    generate $GENERATION_RATE $GENERATION_COUNT &
    
    i=0
    while [ $i -lt $ITERATIONS ]
    do
        delay=$(send_request)
        total=$(echo $delay*1000 | bc -l)    #let's convert to ms
        insert_metric 'CONTROLLER_DELAY' $total $uuid

        i=$[$i+1]
        sleep 2
    done

    delete_intent "$intentDst"
    delete_intent "$intentSrc"
}

main $1

exit 0
