FROM openjdk:7-jdk

COPY core /metrics/core
COPY discovery /metrics/discovery
COPY gradle /metrics/gradle
COPY influxdb-loader /metrics/influxdb-loader
COPY metrics-connect /metrics/metrics-connect
COPY metrics-reporter /metrics/metrics-reporter
COPY gradlew /metrics/
COPY metrics-agent /metrics/
COPY server.cfg /metrics/
COPY settings.gradle /metrics/
COPY start.sh /metrics/
COPY build.gradle /metrics/

WORKDIR /metrics
#RUN ./gradlew build
ENTRYPOINT ["./start.sh"]
