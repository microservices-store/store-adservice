FROM openjdk:8-slim as builder

WORKDIR /app

COPY ["build.gradle", "gradlew", "./"]
COPY gradle gradle
RUN chmod +x gradlew
RUN ./gradlew downloadRepos

COPY . .
RUN chmod +x gradlew
RUN ./gradlew installDist

FROM openjdk:8-slim
ARG REPO_NAME
ARG COMMIT_SHA
ARG SHORT_SHA
ARG PROJECT_ID
ARG BUILD_ID
ARG BRANCH_NAME
ARG TAG_NAME
ARG REVISION_ID
ARG BLDDATE

# Download Stackdriver Profiler Java agent
RUN apt-get -y update && apt-get install -qqy \
    wget \
    && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /opt/cprof && \
    wget -q -O- https://storage.googleapis.com/cloud-profiler/java/latest/profiler_java_agent.tar.gz \
    | tar xzv -C /opt/cprof && \
    rm -rf profiler_java_agent.tar.gz

RUN GRPC_HEALTH_PROBE_VERSION=v0.2.1 && \
    wget -qO/bin/grpc_health_probe https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-amd64 && \
    chmod +x /bin/grpc_health_probe

WORKDIR /app
COPY --from=builder /app .

LABEL REPO_NAME=$REPO_NAME \
    COMMIT_SHA=$COMMIT_SHA \
    SHORT_SHA=$SHORT_SHA \
    PROJECT_ID=$PROJECT_ID \
    BUILD_ID=$BUILD_ID \
    BRANCH_NAME=$BRANCH_NAME \
    TAG_NAME=$TAG_NAME \
    REVISION_ID=$REVISION_ID \
    BLDDATE=$BLDDATE
      
EXPOSE 9555
ENTRYPOINT ["/app/build/install/hipstershop/bin/AdService"]
