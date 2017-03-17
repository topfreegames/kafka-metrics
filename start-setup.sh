#!/bin/bash

####################################################################
# This script discoveries the kafka cluster, create dashboard and
# start influxdb and grafana.
###################################################################

TMP_FILE="tmp.json"
DASHBOARD_DIR="$PWD/.data/grafana/dashboards"
DASHBOARD_PATH="$DASHBOARD_DIR/kafka-metrics.json"

echo "Grafana $GRAFANA_HOST, InfluxDB $INFLUXDB_HOST."

## Create metrics database on influx
curl -XPOST "$INFLUXDB_HOST/query" --data-urlencode 'q=CREATE DATABASE "metrics"'

mkdir -p "$DASHBOARD_DIR"
## Create dashboard by discovering kafka cluster
./discovery/build/scripts/discovery --zookeeper "$ZOOKEEPER_HOST" --dashboard "kafka-metrics" --dashboard-path $DASHBOARD_DIR --interval 25 --influxdb "$INFLUXDB_HOST"

## Build dashboard config file
echo '{"dashboard":'        >  $TMP_FILE
cat $DASHBOARD_PATH         >> $TMP_FILE
echo ', "overwrite": true}' >> $TMP_FILE

## Create InfluxDB data source
curl "$GRAFANA_HOST/api/datasources" -s -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '{"access" : "proxy", "basicAuth" : true, "basicAuthPassword" : "'$AUTH_PASSWORD'", "basicAuthUser" : "'$AUTH_USERNAME'", "database" : "metrics", "id" : 1, "isDefault" : false, "name" : "Kafka Metrics InfluxDB", "orgId" : 1, "password" : "'$INFLUXDB_PASSWORD'", "user" : "'$INFLUXDB_USERNAME'", "secureJsonFields" : {}, "type" : "influxdb", "typeLogoUrl" : "", "url" : "'$INFLUXDB_HOST'", "withCredentials" : false}'

## Send dashboard config file to Grafana
echo -e "Loading dashboard\n$(curl -H "Content-Type: application/json" --data @$TMP_FILE "$GRAFANA_HOST/api/dashboards/db")\nDone"
rm $TMP_FILE
