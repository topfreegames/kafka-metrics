#!/bin/bash

####################################################################
# This script discoveries the kafka cluster, create dashboard and 
# start influxdb and grafana.
###################################################################

TMP_FILE="tmp.json"
CLUSTER_CONFIG="cluster.properties"
DASHBOARD_DIR="$PWD/.data/grafana/dashboards"
DASHBOARD_PATH="$DASHBOARD_DIR/cluster.json"
INTERVAL=25
#GRAFANA_HOST="$1"
#INFLUXDB_HOST="$2"
GRAFANA_HOST="http://admin:admin@grafana:3000"
INFLUXDB_HOST="http://root:root@influxdb:8086"
ZOOKEEPER_HOST="54.145.157.84:2181/kafka-rts"

mkdir -p "$DASHBOARD_DIR"
./discovery/build/scripts/discovery --zookeeper "$ZOOKEEPER_HOST" --dashboard "cluster" --dashboard-path $DASHBOARD_DIR --interval "$INTERVAL" --influxdb "$INFLUXDB_HOST" > $CLUSTER_CONFIG

echo '{"dashboard":'        >  $TMP_FILE
cat $DASHBOARD_PATH         >> $TMP_FILE
echo ', "overwrite": true}' >> $TMP_FILE

echo -e "Loading dashboard\n$(curl -H "Content-Type: application/json" --data @$TMP_FILE "$GRAFANA_HOST/api/dashboards/db")\nDone"
rm $TMP_FILE

./influxdb-loader/build/scripts/influxdb-loader "$CLUSTER_CONFIG"
