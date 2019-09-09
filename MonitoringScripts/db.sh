#!/bin/bash

# Implements methods to interact with the database (postgresql).
# Intended to be used as "library"

# Connection parameters
DB_IP="${DB_IP:-172.17.0.4}"
DB_USER="${DB_USER:-postgres}"
DB_PASS="${DB_PASS:-qoe-db}"
DB_NAME="${DB_NAME:-qoe_db}"

insert_metric() {
  local type=$1
  local value=$(echo $2 | xargs)
  local uuid=$3
  if [ "$value" == "N/A"] || [ -z "$value" ]; then 
    value=-1
  fi
  query="insert into measure(datetime, \"parameter\", value, groupid) values(now(), '${type}', ${value}, '${uuid}');"
  export PGPASSWORD=${DB_PASS} && psql -h ${DB_IP} -U ${DB_USER} -d ${DB_NAME} -c "${query}"
}