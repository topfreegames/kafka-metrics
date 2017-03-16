# Kafka Metrics

## Overview
This is a system for real-time aggregation of metrics from large distributed systems. Rather than replacing existing 
monitoring solutions it fulfills the role of `real-time distributed aggregation` element to combine metrics from 
multiple systems, with some out-of-the-box features for data streams pipelines based on Apache Kafka.

### Contents

1. [Overview](#overview)
	- [Architecture](#overview)
	- [Basic Scenario](#scenario0) 
	- [Multi-Server Scenario](#scenario1)
	- [Multi-Data-Centre Scenario](#scenario3) 
	- [Multi-Enviornment Scenario](#scenario2)
2. [Quick Start](#quick-start)
3. [Modules Reference](#modules-reference)
 	- [Cluster Discovery Tool](#usage-discovery)
 	- [InfluxDB Loader](#usage-loader) 
    - [Metrics Connect](#usage-connect)
 	- [Metrics Agent](#metrics-agent)
 	- [TopicReporter](#usage-reporter)
	    - [Usage in Kafka Broker, Kafka Prism, Kafka Producer (pre 0.8.2), Kafka Consumer (pre 0.9)](#usage-reporter-kafka-old)
	    - [Usage in Kafka NEW Producer (0.8.2+) and Consumer (0.9+)](#usage-reporter-kafka-new)
	    - [Usage in any application using dropwizard metrics (formerly yammer metrics)](#usage-reporter-dropwizard)
    - [Usage in Samza](#usage-samza)
4. [Configuration](#configuration)
    - [InfluxDB Configuration](#configuration-influxdb)
    - [JMX Scanner Configuration](#configuration-scanner)
    - [Metrics Producer Configuration](#configuration-producer)
    - [Metrics Consumer Configuration](#configuration-consumer)
5. [Operations & Troubleshooting](#operations)
6. [Development](#development)

<a name="overview">
## Overview
</a>

Kafka Metrics is a set of libraries and runtime modules that can be deployed in various configurations and can be used 
as an **A)** out-of-the-box monitoring for data streams infrastructures built with Apache Kafka including automatic discovery
 and configuration for existing Kafka clusters **B)** a framework for monitoring distributed systems in general using Apache Kafka infrastructure as a transport layer.

The aim of the design is to have small composable modules that can be deployed by configuration to cover use cases ranging 
from quick, non-intrusive inspection of existing Kafka clusters and stream pipelines, to massive-scale purpose-built 
monitoring, detection and alerting infrastructure for distributed systems in general.

It uses InfluxDB as the time series back-end and comes with, but is not limited to Grafana front-end and Kapactior
alerting on top of that.

![overview](doc/metrics.png)

There are several ways of how the aggregation of metrics is achieved using one or more modules.  

<a name="scenario0">
### Basic Scenario
</a>

For smaller systems consisting of components on the same network or simply a localhost, direct JMX scanner tasks can be 
configured for each JMX Application. This method doesn't require to include any extra code in the monitored applications 
as long as they already expose JMX MBeans and in a local environment the kafka topic can also be omitted.

![scenario0](doc/kafka-metrics-scenario0.png)

<a name="scenario1">
### Multi-Server Scenario
</a>

For bigger systems, where metrics from several hosts need to be aggregated or in cases where more fault-tolerant 
collection of metrics is required, a combination of pluggable TopicReproter or JMX Metrics Agent and a Kafka Topic can 
be deployed by configuration. The JMX Scanner used in the basic scenario is replaced with InfluxDB Loader which is a 
kafka consumer that reads measurements from the metrics topic and writes them into the InfluxDB.


![scenario1](doc/kafka-metrics-scenario1.png)

<a name="scenario2">
### Multi-Data-Centre Scenario
</a>

For multi-DC, potentially global deployments, where metrics from several disparate clusters need to be collected, each 
cluster has its agent which publishes into a local metrics topic and one of the existing mirroring components 
(Kafka Prism, Kafka Mirror Maker, ...) is deployed to aggregate local metrics topic into a single aggregated stream 
providing a real-time monitoring of the entire system.

![scenario2](doc/kafka-metrics-scenario2.png)

<a name="scenario3">
### Multi-Environment Scenario
</a>

Finally, in the heterogeneous environments, where different kinds of application and infrastructure stacks exist, 
firstly any JMX-Enabled or YAMMER-Enabled application can be plugged by configuration. 

***For non-JVM applications or for JVM applications that do not expose JMX MBeans, there is a work in progress to have 
REST Metrics Agent which can receive http put requests and which can be deployed in all scenarios either with or without 
the metrics topic.***

![scenario3](doc/kafka-metrics-scenario3.png)


<a name="quick-start">
## Quick-start example with existing Kafka cluster using discovery module and auto-generated dashboard 
</a>

First we need to build the project from source which requires at least `java 1.7` installed on your system:

    ./gradlew build 

There is a docker-compose.yml file that contains grafana, influxdb and kapactior images and a small script
that starts and integrates them together:

    ./docker-instance.sh

Grafana UI should be now exposed at `http://localhost:3000` - under Data Sources tab there should also be one item 
 named 'Kafka Metrics InfluxDB'. The next command will discover all topics the brokers on a local kafka broker 
 by looking into the zookeeper but you can replace the zookeeper connect string with your own:

    ./discovery/build/scripts/discovery --zookeeper "127.0.0.1:2181" --dashboard "my-kafka-cluster" \
        --dashboard-path $PWD/.data/grafana/dashboards --interval 25 \
        --influxdb  "http://root:root@localhost:8086" | ./influxdb-loader/build/scripts/influxdb-loader

The dashboard should be now accessible on this url:

    http://localhost:3000/dashboard/file/my-kafka-cluster.json

For a cluster of 3 brokers it might look like this:
 
![screenshot](doc/discovery-example-3-brokers.png)

<a name="modules-reference">
## Modules Reference
</a>

<a name="usage-discovery">
### Cluster Discovery Tool
</a>

Metrics Discovery tool can be used for generating configs and dashboards for existing Kafka Clusters. It uses
Zookeeper Client and generates Grafana dashboards as json files and configurations for other Kafka Metrics modules
into the STDOUT. The output configuration can be piped into one of the runtime modules, e.g. InfluxDBLoader 
or Metrics Agent. It is a Java Application and first has to be built with the following command:

    ./gradlew :discovery:build

#### Example usage for local Kafka cluster and InfluxDB

    ./discovery/build/scripts/discovery \
        --zookeeper "localhost:2181" \
        --dashboard "local-kafka-cluster" \
        --dashboard-path "./.data/grafana/dashboards" \
        --influxdb "http://root:root@localhost:8086" | ./influxdb-loader/build/scripts/influxdb-loader

The above command discovers all the brokers that are part of the cluster and configures an influxdb-loader
 using local instance of InfluxDB. It also generates a dashboard for the discovered cluster which
 will be stored in the default Kafka Metrics instance.

#### Example usage for remote Kafka cluster with Metrics Agent 

On the Kafka Cluster:

    ./discovery/build/scripts/discovery \
        --zookeeper "<SEED-ZK-HOST>:<ZK-PORT>" \
        --dashboard "remote-kafka-cluster" \
        --topic "metrics" | ./metrics-agent/build/scripts/metrics-agent

On the Kafka Metrics instance:
 
    ./discovery/build/scripts/discovery \
        --zookeeper "<SEED-ZK-HOST>:<ZK-PORT>" \
        --topic "metrics" \
        --dashboard "remote-kafka-cluster" \
        --dashboard-path "./.data/grafana/dashboards" \
        --influxdb "http://root:root@localhost:8086" | ./influxdb-loader/build/scripts/influxdb-loader


<a name="usage-loader">
### InfluxDB Loader Usage
</a>

InfluxDB Loader is a Java application which writes measurements into InfluxDB backend which can be configured
to scan the measurements from any number of JMX ports oand Kafka metrics topics.  
In versions 0.9.+, the topic input functionality is replaced by the Metrics Connect module which utilizes Kafka Connect 
framework. To build an executable jar, run the following command:

    ./gradlew :influxdb-loader:build

Once built, the loader can be launched with `./influxdb-loader/build/scripts/influxdb-loader` by passing it 
path to properties file containing the following configuration:
    - [InfluxDB Configuration](#configuration-influxdb) (required)
    - [JMX Scanner Configuration](#configuration-scanner) (at least one scanner or consumer is required)
    - [Metrics Consumer Configuration](#configuration-consumer) (at least on scanner or consumer is required)

There is a few example config files under `influxdb-loader/conf` which explain how JMX scanners can be added.
If you have a Kafka Broker running locally which has a JMX Server listening on port 19092 and a docker instances of  
InfluxDB and Grafana running locally, you can use the following script and config file to collect the broker metrics:

    ./influxdb-loader/build/scripts/influxdb-loader influxdb-loader/conf/local-jmx.properties

<a name="usage-connect">
### Metrics Connect Usage
</a>

This module builds on Kafka Connect framework. The connector is jar that needs to be first built: 

    ./gradlew :metrics-connect:build

The command above generates a jar that needs to be in the classpath of Kafka Connect which can be achieved
by copying the jar into `libs` directory of the kafka installation:

    cp ./metrics-connect/build/lib/metrics-connect-*.jar $KAFKA_HOME/libs

Now you can launch for example kafka connect standalone connector with the following example configurations:

    "$KAFKA_HOME/bin/connect-standalone.sh" "metrics-connect.properties" "influxdb-sink.properties" "hdfs-sink.properties"

First, `metrics-connect.properties` is the connect worker configuration which doesn't specify any connectors
but says that all connectors will use MeasurementConverter to deserialize measurement objects.

    bootstrap.servers=localhost:9092
    key.converter=org.apache.kafka.connect.storage.StringConverter
    value.converter=io.amient.kafka.metrics.MeasurementConverter
    ...

The second configuration file is a sink connector that loads the measurements to InfluxDB, for example:

    name=metrics-influxdb-sink
    connector.class=io.amient.kafka.metrics.InfluxDbSinkConnector
    topics=metric
    ...

The third configuration file is a sink connector that loads the measurements to hdfs, for example as parquet files:

    name=metrics-hdfs-sink
    topics=metrics
    connector.class=io.confluent.connect.hdfs.HdfsSinkConnector
    format.class=io.confluent.connect.hdfs.parquet.ParquetFormat
    partitioner.class=io.confluent.connect.hdfs.partitioner.TimeBasedPartitioner
    path.format='d'=YYYY'-'MM'-'dd/
    partition.duration.ms=86400000
    locale=en
    timezone=Etc/GMT+1
    ...

<a name="usage-connect">
## Metrics Connect Usage
</a>

This module builds on Kafka Connect framework. The connector is jar that needs to be first built: 

```
./gradlew :metrics-connect:build
```

The command above generates a jar that needs to be in the classpath of Kafka Connect which can be achieved
by copying the jar into `libs` directory of the kafka installation:

```
cp ./metrics-connect/build/lib/metrics-connect-*.jar $KAFKA_HOME/libs
```
