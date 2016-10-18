FROM wendyhusband/baseubuntu:latest
MAINTAINER wendyhusband

ARG BIN_VERSION=apache-storm-1.0.1

WORKDIR /usr/storm

#supervisor: work ports
EXPOSE 6700

#logviewer
EXPOSE 8000

#DRPC and remote deployment
EXPOSE 6627 3772 3773

#install
RUN alias python=python3; apt-get update -y; apt-get install -y python; wget -q -N http://mirrors.gigenet.com/apache/storm/${BIN_VERSION}/${BIN_VERSION}.tar.gz; tar --strip-components=1 -C /usr/storm -xvf ${BIN_VERSION}.tar.gz; rm ${BIN_VERSION}.tar.gz; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#add startup script
ADD startstorm.sh startstorm.sh
ADD cluster.xml log4j2/cluster.xml
ADD worker.xml log4j2/worker.xml
RUN chmod +x startstorm.sh

ENTRYPOINT ["/usr/storm/startstorm.sh"]