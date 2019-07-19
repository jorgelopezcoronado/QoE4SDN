#!/bin/bash

# Used to export the data from "measure" table in CSV format.
# The data will be grouped by groupid and extracted all the 
# parameters from the measures.
#

DB_IP="${DB_IP:-172.17.0.4}"
DB_USER="${DB_USER:-postgres}"
DB_PASS="${DB_PASS:-qoe-db}"
DB_NAME="${DB_NAME:-qoe_db}"

output_file="measures.csv"

get_measures() {
        local query="select
                    max(datetime) DATETIME,
                    max(case when \"parameter\" = 'AVG_RTT' then value end) AVG_RTT,
                    max(case when \"parameter\" = 'MIN_RTT' then value end) MIN_RTT,
                    max(case when \"parameter\" = 'MAX_RTT' then value end) MAX_RTT,
                    max(case when \"parameter\" = 'PACKET_LOSS' then value end) PACKET_LOSS,
                    max(case when \"parameter\" = 'CONTROLLER_DELAY' then value end) CONTROLLER_DELAY,
                    max(case when \"parameter\" = 'MATCHED_PERCENTAGE' then value end) MATCHED_PERCENTAGE,
                    max(case when \"parameter\" = 'PATH_DELAY' then value end) PATH_DELAY,
                    max(case when \"parameter\" = 'UNUSED_RULE_PERCENTAGE' then value end) UNUSED_RULE_RATIO,
                    'LABEL'
                    from measure
                    group by groupid
                    order by datetime"
        docker run --rm -e PGPASSWORD=${DB_PASS} postgres psql -h ${DB_IP} -U ${DB_USER} -d ${DB_NAME} -t -A -F","  -c "${query}" >> $output_file
}

echo "groupid,AVG_RTT,MIN_RTT,MAX_RTT,PACKET_LOSS,CONTROLLER_DEALAY,MATCHED_PERCENTAGE,PATH_DELAY,UNUSED_RULE_RATIO,LABEL" > $output_file

get_measures

echo "Done, results exported to: $output_file"
