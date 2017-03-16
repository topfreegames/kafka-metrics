FROM openjdk:latest

COPY core/src /metrics/core/src
COPY core/build.gradle /metrics/core/

COPY discovery/src /metrics/discovery/src
COPY discovery/build.gradle /metrics/discovery/

COPY gradle /metrics/gradle

COPY influxdb-loader/src /metrics/influxdb-loader/src
COPY influxdb-loader/build.gradle /metrics/influxdb-loader/

COPY metrics-agent /metrics/metrics-agent
COPY metrics-agent/build.gradle /metrics/metrics-agent/

COPY metrics-connect/src /metrics/metrics-connect/src
COPY metrics-connect/build.gradle /metrics/metrics-connect/

COPY metrics-reporter/src /metrics/metrics-reporter/src
COPY metrics-reporter/build.gradle /metrics/metrics-reporter/

COPY gradlew /metrics/
COPY settings.gradle /metrics/
COPY start.sh /metrics/
COPY build.gradle /metrics/

WORKDIR /metrics
RUN ./gradlew build
CMD ["./start.sh"]
