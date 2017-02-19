# Kafka Metrics

## Overview

This docker container runs alongside with a container running Kafka and another running Zookeeper

It assumes the following scenario:
 - There is Kafka and Zookeeper running in Docker on the host machine
 - Kafka has its JMX enabled on port 19092
 - Kafka has its hostname set to "kafka"
 - Influx daemon is running on machine with ip IP and port 8086
 - Grafana is running and getting data from InfluxDB

## Usage
 - On the machine running Docker with Kafka and Zookeeper, run on the root of this project (kafka-metrics) to build the image:
  ```shell
  docker build --build-arg INFLUXDB_USERNAME=root --build-arg INFLUXDB_PASSWORD=root -t influxloader .
  ```
  Pass your InfluxDB username and password in build-arg

 - Before running Kafka, define the following env variables:
  ```shell
  JMX_PORT=19092
  KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote=true
     -Dcom.sun.management.jmxremote.authenticate=false
     -Dcom.sun.management.jmxremote.ssl=false
     -Djava.rmi.server.hostname= <host machine IP>
     -Djava.net.preferIPv4Stack=true -Dcom.sun.management.jmxremote.rmi.port=19092"
  ```

 - Ensure the kafka container has hostname as "kafka" for the internal network.
  To do it, add the following line in docker-compose:
    
    hostname: kafka
 
   OR, run kafka docker as:
  ```shell
    docker run -h kafka <kafka's image name>
  ```

 - Ensure the influxloader container will run on the same network as kafka container.
   To do it, discover the kafka's network name with:
  ```shell
    docker network ls
  ```
   Find the name of the kafka's network and run the influxloader image with:
  ```shell
    docker run --net=<kafka's network> influxloader IP
  ```
   Where IP is the ip where Influx daemon in running

 - On Grafana (localhost:3000), import your own dashboard or use the file dashboard.json to see the metrics
