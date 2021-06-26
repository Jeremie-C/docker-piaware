FROM debian:buster-slim

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    BEAST_PORT=30005

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY rootfs/ /

RUN apt-get update && apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
  # S6 Install
  ca-certificates wget \
  # Required for build
  git build-essential cmake automake python3 python3-dev \
  libncurses6 libncurses-dev tcl tclx tcl-tls tcl-dev \
  itcl3 tcllib net-tools procps socat file && \
  # Chmod scripts
  chmod +x /scripts/*.sh && \
  # Healthcheck
  chmod +x /healthcheck.sh && \
  # tcllauncher
  git clone --depth 1 -b master https://github.com/flightaware/tcllauncher.git /src/tcllauncher && \
  pushd "/src/tcllauncher" && \
  autoconf && \
  ./configure --prefix=/opt/tcl && \
  make && \
  make install && \
  ldconfig && \
  popd && \  
  # piaware
  git clone --depth 1 -b master https://github.com/flightaware/piaware.git /src/piaware && \
  pushd "/src/piaware" && \
  make install && \
  cp -v /src/piaware/package/ca/*.pem /etc/ssl/ && \
  touch /etc/piaware.conf && \
  mkdir -p /run/piaware && \
  ldconfig && \
  popd && \
  # faup1090
  git clone --depth 1 -b master https://github.com/flightaware/dump1090.git /src/faup1090 && \
  pushd "/src/faup1090" && \
  bash -x /scripts/armv6-modifiy.sh ./Makefile && \
  make showconfig && \
  make faup1090 && \
  cp -v faup1090 /usr/lib/piaware/helpers/ && \
  ldconfig && \
  popd && \
  # mlat-client
  git clone https://github.com/mutability/mlat-client.git /src/mlat-client && \
  pushd /src/mlat-client && \
  BRANCH_MLAT_CLIENT=$(git tag --sort="-creatordate" | head -1) && \
  git checkout "$BRANCH_MLAT_CLIENT" && \
  ./setup.py install && \
  ldconfig && \
  popd && \
  ln -s /usr/local/bin/fa-mlat-client /usr/lib/piaware/helpers/ && \
  # Cleanup
  apt-get remove -y git build-essential python3-dev libncurses-dev \
  tcl-dev cmake automake file && \
  apt-get autoremove -y && \
  rm -rf /scripts /src /var/lib/apt/lists/*

ENTRYPOINT ["/init"]
EXPOSE 30105
HEALTHCHECK --start-period=60s --interval=300s CMD /healthcheck.sh
LABEL maintainer="Jeremie-C <Jeremie-C@users.noreply.github.com>"
