# https://downloads.getmonero.org/cli/monero-linux-x64-v0.17.1.9.tar.bz2

ARG MONERO_BRANCH=v0.17.1.9
ARG MONERO_HASH=0fb6f53b7b9b3b205151c652b6c9ca7e735f80bfe78427d1061f042723ee6381
ARG MONERO_ARCHIVE=monero-linux-x64-${MONERO_BRANCH}.tar.bz2
ARG MONERO_URL=https://downloads.getmonero.org/cli/${MONERO_ARCHIVE}

FROM ubuntu:rolling as staging
LABEL author="mike.k@blu-web.com"

WORKDIR /monero
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
        curl \
        ca-certificates \
        bzip2 && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*

ARG MONERO_BRANCH
ARG MONERO_HASH
ARG MONERO_ARCHIVE
ARG MONERO_URL
RUN curl "${MONERO_URL}" --output "${MONERO_ARCHIVE}" && \
    echo "${MONERO_HASH} ${MONERO_ARCHIVE}" | sha256sum --check --status && \
    tar -xjf "${MONERO_ARCHIVE}" "monero-x86_64-linux-gnu-${MONERO_BRANCH}/monerod" --strip-components=1

FROM ubuntu:rolling

# Lovingly taken from: https://stackoverflow.com/a/55043303
#   It might be overkill.
# We have hadolint ignore the apt-get upgrade here because we
#   want to ensure we're getting security fixes that might be
#   not yet be in the base container on Docker Hub.
# hadolint ignore=DL3005
RUN apt-get update && DEBIAN_FRONTEND=noninteractive \
    apt-get \
    -o Dpkg::Options::=--force-confold \
    -o Dpkg::Options::=--force-confdef \
    -y \
    --allow-downgrades \
    --allow-remove-essential \
    --allow-change-held-packages \
    upgrade && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN groupadd --system monero && useradd -r -g monero -d /monero -m monero
USER monero
WORKDIR /monero
COPY --chown=monero:monero --from=staging /monero/monerod /monero/monerod

EXPOSE 18080
EXPOSE 18089

# TODO: Set blockchain directory.
# TODO: Load config file.
ENTRYPOINT ["monerod", "--non-interactive"]
CMD ["--rpc-restricted-bind-ip=0.0.0.0", "--rpc-restricted-bind-port=18089", "--no-igd", "--no-zmq", "--enable-dns-blocklist"]