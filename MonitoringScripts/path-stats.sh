#!/bin/bash

# Used to collect statistics (min,max,avg and packet loss) of 
# packets traversing data plane paths in SDN architectures.

# The amount of packets generated per second
GENERATION_RATE=5
# The total packets to be generated at each iteration
GENERATION_COUNT=10
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
