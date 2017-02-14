#!/usr/bin/env bash

./gradlew :influxdb-loader:build
./influxdb-loader/build/scripts/influxdb-loader influxdb-loader/conf/local-jmx.properties
