#!/bin/bash

####################################################################
# This script discoveries the kafka cluster, create dashboard and 
# start influxdb and grafana.
###################################################################

TMP_FILE="tmp.json"
DASHBOARD_DIR="$PWD/.data/grafana/dashboards/"
DASHBOARD_PATH=$DASHBOARD_DIR"cluster.json"
INTERVAL=25

if [ $# -lt 8 ]; then
  echo >&2 "$0: missing arguments"
  exit 2
fi

for (( i=1; i<="$#"; i++))
do
  case ${!i} in
    "--grafana")
      ((i++))
      GRAFANA_HOST=${!i}
      ;;
    "--influxdb")
      ((i++))
      INFLUXDB_HOST=${!i}
      ;;
    "--kafka")
      ((i++))
      KAFKA_HOST=${!i}
      ;;
    "--zookeeper")
      ((i++))
      ZOOKEEPER_HOST=${!i}
      ;;
  esac
done

mkdir -p "$DASHBOARD_DIR"
CONFIGS=$(./discovery/build/scripts/discovery --zookeeper "$ZOOKEEPER_HOST" --dashboard "cluster" --dashboard-path $DASHBOARD_DIR --interval "$INTERVAL" --influxdb "$INFLUXDB_HOST")

echo '{"dashboard":'          >> $TMP_FILE 
echo "$(cat $DASHBOARD_PATH)" >> $TMP_FILE
echo ', "overwrite": true}'   >> $TMP_FILE

curl -H "Content-Type: application/json" --data @$TMP_FILE "$GRAFANA_HOST/api/dashboards/db"
rm $TMP_FILE

./influxdb-loader/build/scripts/influxdb-loader influxdb-loader/conf/local-jmx.properties "$CONFIGS"
