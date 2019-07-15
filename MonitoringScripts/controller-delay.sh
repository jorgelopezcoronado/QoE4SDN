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

# The amount of packets generated per second
GENERATION_RATE=5
# The total packets to be
GENERATION_COUNT=100

# Total number of iterations
ITERATIONS=5


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

insert_metric() {
  local type=$1
  local value=$2
  query="insert into measure(datetime, \"parameter\", value) values(now(), '${type}', ${value});"
  docker run --rm -e PGPASSWORD=${DB_PASS} postgres psql -h ${DB_IP} -U ${DB_USER} -d qoe-db -c "${query}"
}

send_request() {

    curl -o /dev/null -s -w '%{time_total}'  \
    --user $ONOS_USER:$ONOS_PASS \
    http://"$CONTROLLER_IP":8181/onos/v1/statistics
}

main() {
    # Check if required tools are installed in host
    if [ ! -f nmap_installed ]; then 
        install_nmap mn.h1
    fi

    generate $GENERATION_RATE $GENERATION_COUNT &
    
    i=0
    while [ $i -lt $ITERATIONS ]
    do
        delay=$(send_request)
        total=$(echo $delay*1000 | bc -l)    #let's convert to ms
        insert_metric 'CONTROLLER_DELAY' $total

        i=$[$i+1]
        sleep 2
    done
}

main

exit 0