#!/bin/bash

####################################################################
# This script discoveries the kafka cluster, create dashboard and 
# start influxdb and grafana.
###################################################################

TMP_FILE="tmp.json"
DASHBOARD_DIR="$PWD/.data/grafana/dashboards/"
DASHBOARD_PATH=$DASHBOARD_DIR"cluster.json"
INTERVAL=25
GRAFANA_HOST="10.0.0.81:3000"
INFLUXDB_HOST="10.0.0.234:8086"
KAFKA_HOST="52.91.35.16:9092"
ZOOKEEPER_HOST="54.145.157.84:2181"

mkdir -p "$DASHBOARD_DIR"
CONFIGS=$(./discovery/build/scripts/discovery --zookeeper "$ZOOKEEPER_HOST" --dashboard "cluster" --dashboard-path $DASHBOARD_DIR --interval "$INTERVAL" --influxdb "$INFLUXDB_HOST")

echo '{"dashboard":'          >> $TMP_FILE 
echo "$(cat $DASHBOARD_PATH)" >> $TMP_FILE
echo ', "overwrite": true}'   >> $TMP_FILE

curl -H "Content-Type: application/json" --data @$TMP_FILE "$GRAFANA_HOST/api/dashboards/db"
rm $TMP_FILE

./influxdb-loader/build/scripts/influxdb-loader influxdb-loader/conf/local-jmx.properties "$CONFIGS"
