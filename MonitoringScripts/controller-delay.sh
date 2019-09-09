#!/bin/bash

# Used to perform requests to the statistics endpoint available at ONOS.
# The time the controller takes to reply will be captured and stored 
# into the database.

# The amount of packets generated per second
GENERATION_RATE=5
# The total packets to be
GENERATION_COUNT=100

# Total number of iterations
ITERATIONS=1

source ./setup.sh
source ./intents.sh
source ./db.sh

generate() {
    local rate=$1
    local count=$2
	  docker exec -i mn.h1 nping -H -q1 --rate $rate -c $count --tcp -p 90 10.0.0.3
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
    install_intent $mac_h1 $mac_h2 "TCP_DST" 90 $intentDst
    intentSrc=$(uuidgen | tail -c 12)
    install_intent $mac_h1 $mac_h2 "TCP_SRC" 90 $intentSrc

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
