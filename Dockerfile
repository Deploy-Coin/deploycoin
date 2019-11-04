# daemon runs in the background
# run something like tail /var/log/Deploycoind/current to see the status
# be sure to run with volumes, ie:
# docker run -v $(pwd)/Deploycoind:/var/lib/Deploycoind -v $(pwd)/wallet:/home/Deploycoin --rm -ti Deploycoin:0.2.2
ARG base_image_version=0.10.0
FROM phusion/baseimage:$base_image_version

ADD https://github.com/just-containers/s6-overlay/releases/download/v1.21.2.2/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

ADD https://github.com/just-containers/socklog-overlay/releases/download/v2.1.0-0/socklog-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/socklog-overlay-amd64.tar.gz -C /

ARG DeployCOIN_BRANCH=master
ENV DeployCOIN_BRANCH=${DeployCOIN_BRANCH}

# install build dependencies
# checkout the latest tag
# build and install
RUN apt-get update && \
    apt-get install -y \
      build-essential \
      python-dev \
      gcc-4.9 \
      g++-4.9 \
      git cmake \
      libboost1.58-all-dev && \
    git clone https://github.com/Deploycoin/Deploycoin.git /src/Deploycoin && \
    cd /src/Deploycoin && \
    git checkout $DeployCOIN_BRANCH && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_CXX_FLAGS="-g0 -Os -fPIC -std=gnu++11" .. && \
    make -j$(nproc) && \
    mkdir -p /usr/local/bin && \
    cp src/DeployCoind /usr/local/bin/DeployCoind && \
    cp src/walletd /usr/local/bin/walletd && \
    cp src/zedwallet /usr/local/bin/zedwallet && \
    cp src/miner /usr/local/bin/miner && \
    strip /usr/local/bin/DeployCoind && \
    strip /usr/local/bin/walletd && \
    strip /usr/local/bin/zedwallet && \
    strip /usr/local/bin/miner && \
    cd / && \
    rm -rf /src/Deploycoin && \
    apt-get remove -y build-essential python-dev gcc-4.9 g++-4.9 git cmake libboost1.58-all-dev && \
    apt-get autoremove -y && \
    apt-get install -y  \
      libboost-system1.58.0 \
      libboost-filesystem1.58.0 \
      libboost-thread1.58.0 \
      libboost-date-time1.58.0 \
      libboost-chrono1.58.0 \
      libboost-regex1.58.0 \
      libboost-serialization1.58.0 \
      libboost-program-options1.58.0 \
      libicu55

# setup the Deploycoind service
RUN useradd -r -s /usr/sbin/nologin -m -d /var/lib/Deploycoind Deploycoind && \
    useradd -s /bin/bash -m -d /home/Deploycoin Deploycoin && \
    mkdir -p /etc/services.d/Deploycoind/log && \
    mkdir -p /var/log/Deploycoind && \
    echo "#!/usr/bin/execlineb" > /etc/services.d/Deploycoind/run && \
    echo "fdmove -c 2 1" >> /etc/services.d/Deploycoind/run && \
    echo "cd /var/lib/Deploycoind" >> /etc/services.d/Deploycoind/run && \
    echo "export HOME /var/lib/Deploycoind" >> /etc/services.d/Deploycoind/run && \
    echo "s6-setuidgid Deploycoind /usr/local/bin/DeployCoind" >> /etc/services.d/Deploycoind/run && \
    chmod +x /etc/services.d/Deploycoind/run && \
    chown nobody:nogroup /var/log/Deploycoind && \
    echo "#!/usr/bin/execlineb" > /etc/services.d/Deploycoind/log/run && \
    echo "s6-setuidgid nobody" >> /etc/services.d/Deploycoind/log/run && \
    echo "s6-log -bp -- n20 s1000000 /var/log/Deploycoind" >> /etc/services.d/Deploycoind/log/run && \
    chmod +x /etc/services.d/Deploycoind/log/run && \
    echo "/var/lib/Deploycoind true Deploycoind 0644 0755" > /etc/fix-attrs.d/Deploycoind-home && \
    echo "/home/Deploycoin true Deploycoin 0644 0755" > /etc/fix-attrs.d/Deploycoin-home && \
    echo "/var/log/Deploycoind true nobody 0644 0755" > /etc/fix-attrs.d/Deploycoind-logs

VOLUME ["/var/lib/Deploycoind", "/home/Deploycoin","/var/log/Deploycoind"]

ENTRYPOINT ["/init"]
CMD ["/usr/bin/execlineb", "-P", "-c", "emptyenv cd /home/Deploycoin export HOME /home/Deploycoin s6-setuidgid Deploycoin /bin/bash"]
