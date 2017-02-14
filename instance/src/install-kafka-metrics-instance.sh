#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/kafka-metrics-common.sh"

export GOPATH="$INSTALL_DIR/golang"

install_influxdb() {
    echo "Installing latest InfluxDB..."
    cd "$GOPATH/src"
    go get github.com/influxdata/influxdb
    cd $GOPATH/src/github.com/influxdata/
    go get ./...
    go install ./...
}

install_grafana() {
    echo "Installing latest Grafana..."
    cd "$GOPATH/src"
    go get github.com/grafana/grafana
    cd $GOPATH/src/github.com/grafana/grafana
    go run build.go setup              # (only needed once to install godep)
    $GOPATH/bin/godep restore          # (will pull down all golang lib dependencies in your current GOPATH)
    go run build.go build
    npm install
    npm install -g grunt-cli
    grunt --force
}

install_influxdb
install_grafana
