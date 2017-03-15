#!/bin/bash

####################################################################
# This script discoveries the kafka cluster, create dashboard and 
# start influxdb and grafana.
###################################################################

TMP_FILE="tmp.json"
DASHBOARD_DIR="$PWD/.data/grafana/dashboards/"
DASHBOARD_PATH=$DASHBOARD_DIR"cluster.json"
INTERVAL=25
GRAFANA_HOST="http://admin:admin@a12c20ec4090011e79d540a75cb326ba-851496104.us-east-1.elb.amazonaws.com:3000"
INFLUXDB_HOST="http://root:root@100.68.195.141:8086"
ZOOKEEPER_HOST="54.145.157.84:2181/kafka-rts"

mkdir -p "$DASHBOARD_DIR"
CONFIGS=$(./discovery/build/scripts/discovery --zookeeper "$ZOOKEEPER_HOST" --dashboard "cluster" --dashboard-path $DASHBOARD_DIR --interval "$INTERVAL" --influxdb "$INFLUXDB_HOST")

echo '{"dashboard":'          >> $TMP_FILE 
echo "$(cat $DASHBOARD_PATH)" >> $TMP_FILE
echo ', "overwrite": true}'   >> $TMP_FILE

echo -e "Loading dashboard\n$(curl -H "Content-Type: application/json" --data @$TMP_FILE "$GRAFANA_HOST/api/dashboards/db")\nDone"
rm $TMP_FILE

./influxdb-loader/build/scripts/influxdb-loader influxdb-loader/conf/local-jmx.properties "$CONFIGS"
