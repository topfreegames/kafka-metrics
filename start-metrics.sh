#!/bin/bash

####################################################################
# This script discoveries the kafka cluster, create dashboard and 
# start influxdb and grafana.
###################################################################

DASHBOARD_DIR="$PWD/.data/grafana/dashboards"

mkdir -p "$DASHBOARD_DIR"
./discovery/build/scripts/discovery --zookeeper "$ZOOKEEPER_HOST" --dashboard "cluster" --dashboard-path $DASHBOARD_DIR --interval 25 --influxdb "$INFLUXDB_HOST" | ./influxdb-loader/build/scripts/influxdb-loader
