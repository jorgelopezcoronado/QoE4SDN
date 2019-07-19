#!/bin/bash

# Used to export the data from "measure" table in CSV format.
# The data will be grouped by groupid and extracted all the 
# parameters from the measures.
#

DB_IP="${DB_IP:-172.17.0.4}"
DB_USER="${DB_USER:-qoe_user}"
DB_PASS="${DB_PASS:-MPCLGP5432!}"
DB_NAME="${DB_NAME:-qoe_db}"

output_file="measures.csv"

get_measures() {
        local query="SELECT * FROM
				(
		    			SELECT
					max(datetime) datetime,
					max(case when \"parameter\" = 'AVG_RTT' then value end) avg_rtt,
					max(case when \"parameter\" = 'MIN_RTT' then value end) min_rtt,
					max(case when \"parameter\" = 'MAX_RTT' then value end) max_rtt,
					max(case when \"parameter\" = 'PACKET_LOSS' then value end) packet_loss,
					max(case when \"parameter\" = 'CONTROLLER_DELAY' then value end) controller_delay,
					max(case when \"parameter\" = 'MATCHED_PERCENTAGE' then value end) matched_percentage,
					max(case when \"parameter\" = 'PATH_DELAY' then value end) path_delay,
					max(case when \"parameter\" = 'UNUSED_RULE_PERCENTAGE' then value end) unused_rule_percentage,
					'LABEL' as label
					from measure
					group by groupid
					order by datetime
				) arranged_measures 
			WHERE 
			avg_rtt IS NOT NULL AND 
			min_rtt IS NOT NULL AND 
			max_rtt IS NOT NULL AND 
			packet_loss IS NOT NULL AND 
			controller_delay IS NOT NULL AND 
			matched_percentage IS NOT NULL AND 
			path_delay IS NOT NULL AND 
			unused_rule_percentage IS NOT NULL"
        #docker run --rm -e PGPASSWORD=${DB_PASS} postgres psql -h ${DB_IP} -U ${DB_USER} -d ${DB_NAME} -t -A -F","  -c "${query}" >> $output_file

        export PGPASSWORD=${DB_PASS} && psql -h ${DB_IP} -U ${DB_USER} -d ${DB_NAME} -t -A -F","  -c "${query}" >> $output_file
}

echo "groupid,AVG_RTT,MIN_RTT,MAX_RTT,PACKET_LOSS,CONTROLLER_DELAY,MATCHED_PERCENTAGE,PATH_DELAY,UNUSED_RULE_PRECENTAGE,LABEL" > $output_file

get_measures

echo "Done, results exported to: $output_file"
