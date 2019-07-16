#!/bin/bash

# Used to asynchronously run all the metrics collectors,
# this way we can farther relate all the collected metrics.

uuid=$(uuidgen)

clean() {
    rm nmap_installed tcpdump_installed
}

main() {
    ./path-delay.sh $uuid  & 
    ./path-stats.sh $uuid  &
    ./controller-delay.sh $uuid &
    ./matched_ratio $uuid &

    clean
}

main
exit 0
