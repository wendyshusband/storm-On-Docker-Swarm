ZK=$1

docker run -d --label cluster=storm --label role=supervisor -e STORM_ZOOKEEPER_SERVERS=$ZK --net stormnet --restart=always wendyhusband/storm supervisor -c supervisor.slots.ports=[6700]