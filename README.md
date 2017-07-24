# storm-On-Docker-Swarm
Basic deploying apache storm on docker with docker swarm

baseUbuntu,storm,zookeeper:some docker file and enterpoint script

This guide reference [The joy of deploying Apache Storm on Docker Swarm](http://highscalability.com/blog/2016/4/25/the-joy-of-deploying-apache-storm-on-docker-swarm.html) in [Baqend Tech](http://www.baqend.com/).And we describe some of the detail and principles about every step in this tutorial.If you have already have a good use of Linux,Docker swarm and Apache storm,you can use script given in the article above for rapid deployment. This tutorial is targeted at beginner novice.We will manual configuration on each machine and you will be more clear understand the principle in the process of deployment .

So let’s begin :


#Overall Architecture 
![](1.png)

You’ll have 3 machines running Ubuntu Server 14.04, each of which will be running a Docker daemon with several containers inside. As shown in figure above ,we use ubuntu1 as manager of Docker swarm. The Nimbus and UI containers will be spawned on the manager node (Ubuntu 1).Beside ,remember to open port 8080 for UI container. 
When swarm is in place ,you’ll create an overlay network (stormnet) to enable communication between Docker container hosted on the different swarm nodes. Finally, you will set up a full-fledged storm cluster that uses the existing zookeeper ensemble for coordination and stormnet for inter-node communication. This involves discovery service of Docker swarm ,you can read [here](https://technologyconversations.com/2015/09/08/service-discovery-zookeeper-vs-etcd-vs-consul/).
We are using hostnames dmir1,dmir2 and dmir3 for the three Ubuntu machines. Using alias rather than an IP address can have better fault tolerance. At the time of the actual deployment ,remember to replace your own domain name. Three zookeeper severs are deployed here, of course,using one zookeeper is also possible. 

#Install Docker

Using your favorite way to connect three machines and install Docker on each machine. You can reference [here](https://docs.docker.com/engine/installation/linux/ubuntulinux/) to install Docker. After the installation is complete,we should test to ensure that the installation is successful.


#Create /etc/init.sh

Create the file used to configure the Docker swarm worker.

In the terminal ,type :

>sudo touch /etc/init.sh  
>sudo vim /etc/init.sh

and then paste the following and save:

>\#!/bin/bash  
>\# first script argument: the servers in the ZooKeeper ensemble:  
>ZOOKEEPER_SERVERS=$1  
>\# second script argument: the role of this node:   
>\# ("manager" for the Swarm manager node; leave empty else) ROLE=$2 # the IP  	
>address of this machine:  
>PRIVATE_IP=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print >$1}')  
>\# define label for the manager node: if [[ $ROLE == "manager" ]];then LABELS="--
>label server=manager";else LABELS="";fi  
>\# define default options for Docker Swarm:  
>echo "DOCKER_OPTS=\"-H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock --cluster>-advertise eth0:2375 $LABELS --cluster-store zk://$ZOOKEEPER_SERVERS\"" | sudo
>tee /etc/default/docker  
>\# restart the service to apply new options:  
>sudo service docker restart  
>echo "let's wait a little..."  
>sleep 10  
>\# make this machine join the Docker Swarm cluster:   
>docker run -d --restart=always swarm join --advertise=$PRIVATE_IP:2375 
>zk://$ZOOKEEPER_SERVERS  

In this shell file, we configure some detail for start a swarm worker. The first step , we defined three zookeeper server node ,through the ZOOKEEPER_SERVERS variable. The second step, we parse */sbin/ifconfig eth0* to get the IP address of the machine($PRIVATE_IP). The third step, we mark the label “manager ” for swarm manager node. The fourth step, modify */ect/default/docker*, including some content such as docker daemon listening port 2375,which can refer to the configuration of the docker on the [https://docs.docker.com/](https://docs.docker.com/). The fifth step, restart Docker service. The last step, *docker run* a swarm worker container ,and use zookeeper as the service discovery.  


#Create swarm worker

In the terminal of Ubuntu1 ,type :

>/bin/bash /etc/init.sh dmir1,dmir2,dmir3  manager

In the terminal of Ubuntu2 and Ubuntu3, type :

>/bin/bash /etc/init.sh dmir1,dmir2,dmir3

set up your DNS in such a way that the first hostname in the list (dmir1) points towards the manager on Ubuntu 1 and the other two hostnames (dmir2 and dmir3) point towards the other two machines, i.e. Ubuntu 2 and Ubuntu 3. 
Configure your security settings to allow connections between the machines on ports 2181, 2888, 3888 (zookeeper), 2375 (Docker Swarm) and 6627 (Storm, remote topology deployment).
If nothing has gone wrong, you should now have three Ubuntu servers, each running a Docker daemon. Ubuntu 1 should be reachable via dmir1 in your private network. Now, we can only configuration on Ubuntu1, it is going to be the only machine you will talk to from this point on.

#Start Docker swarm cluster and zookeeper server 

Using *docker ps* to perform a quick heal check. If Docker is installed correctly, the terminal will show a list of the running Docker container (exactly 1 for swarm and nothing else ) 

You are now good to launch one zookeeper node on every machine like this:

>docker -H tcp://dmir1:2375 run -d --restart=always -p 2181:2181 -p 2888:2888 -p 
>3888:3888 -v /var/lib/zookeeper:/var/lib/zookeeper -v /var/log/zookeeper:/var/log/zookeeper --name zk1 baqend/zookeeper dmir1,dmir2,dmir3 1  
>docker -H tcp://dmir2:2375 run -d --restart=always -p 2181:2181 -p 2888:2888 -p 3888:3888 -v /var/lib/zookeeper:/var/lib/zookeeper -v /var/log/zookeeper:/var/log/zookeeper --name zk2 baqend/zookeeper dmir1,dmir2,dmir3 2  
docker -H tcp://dmir3:2375 run -d --restart=always -p 2181:2181 -p 2888:2888 -p 3888:3888 -v /var/lib/zookeeper:/var/lib/zookeeper -v /var/log/zookeeper:/var/log/zookeeper --name zk3 baqend/zookeeper dmir1,dmir2,dmir3 3  

Here we using [baqend/zookeeper](https://hub.docker.com/r/baqend/zookeeper/) image on the docker hub.
By specifying the -H ... argument, we are able to launch the zookeeper containers on the different host machines. The -p commands expose the ports required by zookeeper per default. The two -v commands provide persistence in case of container failure by mapping the directories the zookeeper container uses to the corresponding host directories. The comma-separated list of hostnames tells zookeeper what servers are in the ensemble. This is the same for every node in the ensemble. The only variable is the zookeeper ID (second argument), because it is unique for every container.	

To check zookeeper health, you can do the following:

>docker -H tcp://dmir1:2375 exec -it zk1 bin/zkServer.sh status && docker -H 
>tcp://dmir2:2375 exec -it zk2 bin/zkServer.sh status && docker -H 
>tcp://dmir3:2375 exec -it zk3 bin/zkServer.sh status


Here related to Docker exec command and the zookeeper service status command bin/zkServer.sh status. If your cluster is healthy, every node will report whether it is the leader or one of the followers. If something goes wrong,likely due to $PRIVATE_IP can’t be parsed, then we recommended that removed the last step in the init.sh and manually *docker run* a swarm worker on each node.

>docker run -d --restart=always swarm join --advertise=$PRIVATE_IP:2375 
>zk://$ZOOKEEPER_SERVERS

After you start the zookeeper service ,you need to start the swarm manager:

>docker run -d --restart=always --label role=manager -p 2376:2375 swarm 
>manage zk://dmir1,dmir2,dmir3

Now the Swarm cluster is running. However, we still have to tell the Docker client about it. So finally, you only have to make sure that all future docker run statements are directed to the Swarm manager container (which will do the scheduling) and not against the local Docker daemon:

>cat << EOF | tee -a ~/.bash_profile  
>\# this node is the master and therefore should be able to talk to the Swarm 
>cluster:  
>export DOCKER_HOST=tcp://127.0.0.1:2376  
>EOF

This will do it for the current session and also make sure it will be done again when we log into the machine next time.
Now everything should be up and running. Type in *docker info* to check cluster status on the manager node. 

You should see 3 running workers similar to this:

![](2.png)

The important part is the line with Status: Healthy for each node. If you observe something like Status: Pending or if not all nodes show up, even though you are not experiencing any errors elsewhere, try restarting the manager container like so:

>docker restart $(docker ps -a --no-trunc --filter "label=role=manager)


#Setup the storm cluster 

First, create the overlay network stormnet. This network is guaranteed the mapping relationship between container and physical machine.you can reference [here](https://docs.docker.com/engine/userguide/networking/get-started-overlay/).

>docker network create --driver overlay stormnet  
>docker network ls  

This creates a network and detect if created successfully. If something goes wrong,maybe your swarm cluster is not running. It means that you should refer to the previous tutorial and guarantee every step is carefully finished.
Now, let’s start storm components, including UI, nimbus and supervisor.

First, start the UI:

>docker run -d --label cluster=storm --label role=ui -e constraint:server==manager -e STORM_ZOOKEEPER_SERVERS=dmir1,dmir2,dmir3 --net stormnet --restart=always --name ui -p 8080:8080 baqend/storm ui

and the nimbus :

>docker run -d --label cluster=storm --label role=nimbus -e 
>constraint:server==manager -e STORM_ZOOKEEPER_SERVERS=dmir1,dmir2,dmir3 --net 
>stormnet --restart=always --name nimbus -p 6627:6627 baqend/storm nimbus  


For specific configuration can refer to [baqend/storm](https://hub.docker.com/r/baqend/storm/). The -p commands expose the ports required by UI container and nimbus container default. The -net command specified the container under the stormnet, in order to communicate with the container on other physical machine. 
Note that nimbus parameter are added after baqend/storm, when we start nimbus container. This parameter is mark the nimbus container as the main container. This involves some  configuration of baqend/storm, you can view [here](https://github.com/Baqend/docker-storm).
To make sure that these are running on the manager node, we specified a *constraint : constraint : server==manager*. You can now access the Storm UI as though it would be running on the manager node, However, there are no supervisors running, yet.

Finally, start the supervisor, you can start supervisor on any machine. 

>docker run -d --label cluster=storm --label role=supervisor -e 
>affinity:role!=supervisor -e STORM_ZOOKEEPER_SERVERS=dmir1,dmir2,dmir3 --net 
>stormnet --restart=always baqend/storm supervisor -c supervisor.slots.ports=[6700]

Since we do not care where exactly the individual supervisors are running, we did not specify any constraints or container names here. However, in order to prevent two supervisors from being hosted on one machine, we did specify a label *affinity : affinity : role!=supervisor*. If you need more supervisor containers, you’ll have to add additional Swarm worker nodes (Ubuntu 4, Ubuntu 5, …). Besides, the *-c supervisor.slots.ports=[6700]* provided one port 6700 for supervisor. Of course you can provide any number of port for supervisor. But we recommend that you use only one port, because the container is essentially a process on physical machine , no matter how much the port resources are the same.
Have a look at the Storm UI and make sure that you have supervisors running.


#Topology Deployment

Deploying a topology can now be done from any server that has a Docker daemon running and is in the same network as the manager machine. The following command assumes that your topology fatjar is a file called topology.jar in your current working directory:

>docker -H tcp://127.0.0.1:2375 run -it --rm -v $(readlink -m topology.jar)
>:/topology.jar --net stormnet baqend/storm jar /topology.jar main.class arg1 arg2

This command will spawn a Docker container, deploy the topology and then remove the container. You should provide the *-H tcp://127.0.0.1:2375* argument to make sure the container is started on the machine you are currently working on; if you left the scheduling to Docker Swarm, the deployment might fail because the spawning host does not necessarily have the topology file.By the way, we use *readlink -m topology.jar* which produces an absolute path fortopology.jar, because relative paths are not supported. You can also provide an absolute path directly, though.
Last but most important , *--net stormnet* is necessary, because you spawn a new container for deploy the topology, so this new container must under the stormnet ,otherwise it will return a *unknownhost error*.


#Killing a Topology

Killing the topology can either be done via the Storm web UI interactively or, assuming the running topology is called runningTopology, like this:

>docker run -it --rm --net stormnet baqend/storm  kill runningTopology

The host argument -H ... is not required here, because the statement stands on its own and has no file dependencies.

#Topology Rebalance

Topology rebalance can either be done via the Storm web UI interactively or, assuming the running topology is called runningTopology, like this:

>docker run -it --rm –net stormnet baqend/storm  rebalance runningTopology -n arg

or:

>docker exec -it nimbus storm rebalance runningTopology -n arg

Of course , we need enough slot to support this operation.

#Shutting down the storm cluster

Since every Storm-related container is labelled with cluster=storm, you can kill all of them with the following statement:

>docker rm -f $(docker ps -a --no-trunc --filter "label=cluster=storm"

Finally, we finish our work. we stepped over how to [configure Docker Swarm for TLS](https://docs.docker.com/swarm/configure-tls/). If you are planning to use Docker Swarm in a business-critical application, you should definitely put some effort into this aspect of deployment.

You can use our [script](https://github.com/wendyshusband/storm-On-Docker-Swarm) for repid depolyment


