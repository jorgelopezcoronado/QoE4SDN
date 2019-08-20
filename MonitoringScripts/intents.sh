#!/bin/bash

CONTROLLER_IP="${CONTROLLER_IP:-localhost}"
ONOS_USER="${ONOS_USER:-onos}"
ONOS_PASS="${ONOS_PASS:-rocks}"

install_intent() {
  echo $(date) "Intent requested"
  local host1=$1
  local host2=$2
  local type=$3
  local port=$4
  local identifier=$5

	curl -X POST -L -D resp_"${identifier}".txt --user $ONOS_USER:$ONOS_PASS  \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' -d '{ 
    "type": "HostToHostIntent", 
    "appId": "org.onosproject.gui", 
    "priority":100,
    "one": "'"$host1"'/None",
    "two": "'"$host2"'/None",
    "selector": {
      "criteria": [
        { 
          "type": "'"$type"'",
          "tcpPort": "'"$port"'" 
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
  local identifier=$1
  local location=$(grep -i Location resp_${identifier}.txt | awk '{print $2}')
  location=${location%$'\r'}
  curl -X DELETE -G --user $ONOS_USER:$ONOS_PASS "${location}"
  $(rm resp_${identifier}.txt)
}