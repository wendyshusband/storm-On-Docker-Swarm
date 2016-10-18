#servers in the ZooKeeper ensemble: 
ZOOKEEPER_SERVERS=$1

#number of supervisors to add
NUMBER_SUPERVISOR=$2
# if no valid number was given: just assume 1 as default
if ! [[ $NUMBER_SUPERVISOR =~ ^[0-9]+ ]] ; then
   echo "no number was provided (\"$SUPERVISORS\"). Will proceed with 1 supervisor."
   NUMBER_SUPERVISOR=1
fi

# the IP address of this machine: 
PRIVATE_IP=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}');

# define default options for Docker Swarm: 
echo "DOCKER_OPTS=\"-H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock --cluster-advertise eth0:2375 $LABELS --cluster-store zk://$ZOOKEEPER_SERVERS\"" | sudo tee /etc/default/docker 

# restart the service to apply new options: 
sudo service docker restart
echo "let's wait a little..."
sleep 10

# make this machine join the Docker Swarm cluster: 
docker run -d --restart=always swarm join --advertise=$PRIVATE_IP:2375 zk://$ZOOKEEPER_SERVERS
docker ps

#add supervisor and worker   -e affinity:role!=supervisor 
for((i=0; i <= $NUMBER_SUPERVISOR; i++))
do
	docker run --label cluster=storm --label role=supervisor -e STORM_ZOOKEEPER_SERVERS=$ZOOKEEPER_SERVERS --net stormnet --restart=always wendyhusband/storm supervisor 
done

docker ps
