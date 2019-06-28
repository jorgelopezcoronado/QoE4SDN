#!/bin/bash

# Used to collect statistics (min,max,avg and packet loss) of 
# packets traversing data plane paths in SDN architectures.

CONTROLLER_IP="${CONTROLLER_IP:-localhost}"
ONOS_USER="${ONOS_USER:-onos}"
ONOS_PASS="${ONOS_PASS:-rocks}"

# The amount of packets generated per second
GENERATION_RATE=5
# The total packets to be generated at each iteration
GENERATION_COUNT=10
# Total number of iterations
ITERATIONS=10

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

generate() {
    local rate=$1
    local count=$2
	docker exec -i mn.h1 nping -H -q1 --rate $rate -c $count --tcp -p 90 10.0.0.3
}

install_intent() {
  echo $(date) "Intent requested"
	curl -X POST -L -D resp.txt --user $ONOS_USER:$ONOS_PASS  \
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

main() {

    # Check if required tools are installed in host
    if [ ! -f nmap_installed ]; then 
        install_nmap mn.h1
    fi

    i=0
    while [ $i -lt $ITERATIONS ]
    do 
        generate $GENERATION_RATE $GENERATION_COUNT > results_tmp.txt
        datetime=$(grep -i at results_tmp.txt | awk '{print $8,$9,$10}')
        max_min_avg=$(grep -i "max rtt" results_tmp.txt | awk '{print $1,$3,$5,$7,$9,$11}')
        totals=$(grep -i "rcvd" results_tmp.txt | awk '{print $3,$4,$7,$8,$11,$12}')
        echo "${datetime} ${max_min_avg} ${totals}" >> results.txt
        echo "10 packets generated at " $(date)
        i=$[$i+1]
        sleep 5
    done

    rm results_tmp.txt
}
main
cat results.txt

exit 0
