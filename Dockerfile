FROM ubuntu

ARG MAINTAINER=jdoe@example.org
ARG BUILD=concourse-1
ARG VERSION=1.0.0

LABEL maintainer=$MAINTAINER
LABEL build=$BUILD
LABEL version=$VERSION

COPY assets/* /opt/resource/

RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      ca-certificates \
      curl \
      jq; \
    apt-get clean all; \
    rm -rf /var/lib/apt/lists/*
