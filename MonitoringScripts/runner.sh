#!/bin/bash

# Used to asynchronously run all the metrics collectors,
# this way we can farther relate all the collected metrics.


print_usage() {
    echo "$0 [options]"
    echo " "
    echo "options:"
    echo "-h, --help    show this help"
    echo "-c, --count=NUMBER   specify the number of times to execute metrics collectors"
    echo "                     default 1."
}

clean() {
    rm nmap_installed tcpdump_installed
}

run() {
    uuid=$(uuidgen)

    ./path-delay.sh $uuid  & 
    ./path-stats.sh $uuid  &
    ./controller-delay.sh $uuid &
    ./matched_ratio $uuid &
    ./unused_rule_percentage $uuid &
}

count=1
while test $# -gt 0; do
    case "$1" in
        -c|--count)
                shift
                if test $# -gt 0; then
                    count=$1
                else
                    echo "error: not a number provided"
                    print_usage
                    exit 1
                fi
                shift
                ;;
        -h|--help)
                print_usage
                exit 0
                ;;
        *)
            break
            ;;
    esac
done

i=0
while [ $i -lt $count ]; do
    run
    i=$[$i+1]
    sleep 15
done

clean
echo "Runner executed $count time(s)"
exit 0
