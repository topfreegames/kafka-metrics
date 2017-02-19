#!/bin/sh

if [ -z "$1" ]; then
  echo 'Missing hostname where InfluxDB is running'
else 
  echo 'Creating database "metrics"'
  curl -XPOST "http://$1:8086/query" --data-urlencode 'q=CREATE DATABASE "metrics"'
  echo 'Starting InfluxDB Loader'
  echo "influxdb.url=http://$1:8086" >> influxdb-loader/conf/local-jmx.properties
  ./influxdb-loader/build/scripts/influxdb-loader influxdb-loader/conf/local-jmx.properties
fi
