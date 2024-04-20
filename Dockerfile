# SPDX-FileCopyrightText: 2024 Jens Erdmann
#
# SPDX-License-Identifier: MIT

# SCANOSS minr Image

FROM debian:testing-slim AS builder


ARG LDB_VERSION="4.1.1"
ARG MINR_VERSION="2.6.0"


RUN apt update \
 && apt install --no-install-recommends --assume-yes \
     ca-certificates \
     curl \
     gcc \
     make \
     unzip \
     # ldb build requirements
     zlib1g-dev \
     libgcrypt-dev \
 && rm -rf /var/lib/apt/lists/* \
 # Download external sources
 && curl -L -o /tmp/ldb.zip https://github.com/scanoss/ldb/archive/refs/tags/v${LDB_VERSION}.zip \
 && curl -L -o /tmp/minr.zip https://github.com/scanoss/minr/archive/refs/tags/v${MINR_VERSION}.zip \
 # build LDB
 && cd /tmp/ \
 && unzip /tmp/ldb.zip \
 && mv ldb-* ldb \
 && cd /tmp/ldb \
 && make all \
 # install LDB library
 && cp libldb.so /usr/lib \
 && cp -r src/ldb /usr/include \
 && cp src/ldb.h /usr/include \
 # build minir
 && cd /tmp \
 && unzip /tmp/minr.zip \
 && mv minr-* minr \
 && cd /tmp/minr \
 && make all


FROM debian:testing-slim

ARG SCANCODE_VERSION="32.1.0"

COPY --from=builder /tmp/ldb/libldb.so /usr/lib/
COPY --from=builder /tmp/ldb/ldb /usr/bin/
COPY --from=builder /tmp/minr/minr /usr/bin/
COPY --from=builder /tmp/minr/mz /usr/bin/

RUN apt update \
 && apt install --no-install-recommends --assume-yes \
     ca-certificates \
     # LDB runtime depenndencies
     libgcrypt20 \
     zlib1g \
     # minr runtime dependencies
     7zip \
     coreutils \
     curl \
     gzip \
     ruby \
     tar \
     unrar-free \
     unzip \
     xz-utils \
     # scancode
     jq \
     libgomp1 \
     python3-pip \
 && rm -rf /var/lib/apt/lists/* \
 # ldb runtime directory
 && mkdir -p /var/log/scanoss/ldb/ \
 # install scancode
 && pip install --break-system-packages scancode-toolkit==${SCANCODE_VERSION} \
 # verify versions
 && minr -v \
 && ldb --version \
 && scancode --version
