#!/bin/bash

# Outputs the time delay between a flow request (using intents)
# and when the flow becomes operational.
#
# To run it in OSX is required to install 'coreutils' in order to use
# 'gdate' and create and alias for it.
#

source ./setup.sh
source ./intents.sh
source ./db.sh

capture() {
	docker exec -d mn.h2 bash -c "tcpdump -tt -i h2-eth1 -c 1 tcp port 80 > capture.txt"
}

generate() {
	docker exec -i mn.h1 nping -c 2 --tcp -p 80 10.0.0.3
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
  
  if [[ $(uname) == "Darwin" ]]; then
    intent_req_date=$(gdate "+%s.%6N")
  else
    intent_req_date=$(date "+%s.%6N")
  fi

  intentDst=$(uuidgen | tail -c 12)
  install_intent $mac_h1 $mac_h2 "TCP_DST" 80 ${intentDst}
  
  # Start the packet generation at host 1
  generate

  sleep 4

  # Finally process the output file from host 2 
  docker cp mn.h2:/go/src/github.com/letitbeat/packet-generator/capture.txt .
  echo "Package captured:"
  cat capture.txt

  date_captured=$(awk '{print $1}' capture.txt| tr "." " "| awk '{print $1"."$2}' | xargs)
  
  diff=$(bc <<< "$date_captured - $intent_req_date")

  if [[ ! -z "$date_captured" ]];then
          if [[  $(bc -l <<< "$diff < 1") -eq 1 ]]; then
                  diff=$(echo $diff*1000 | bc -l )
                  echo "time diff:" ${diff} "ms"
          else
                  echo "time diff:" ${diff}
          fi
  else
          diff=-1
          echo "time diff: -1"
  fi
  rm capture.txt

  insert_metric "PATH_DELAY" $diff $uuid

  delete_intent "$intentDst"
}

main $1
exit 0
