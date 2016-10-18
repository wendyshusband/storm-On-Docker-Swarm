#!/bin/bash

#using on ubuntu14.04

#Update your apt sources
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8D5A09DC9B929006;
apt-get update; 
apt-get install apt-transport-https ca-certificates;
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D;
echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" | tee -a /etc/apt/sources.list.d/docker.list;
apt-get update;
apt-get purge lxc-docker;
apt-cache policy docker-engine;

#To install the linux-image-extra-* packages:
apt-get update -y;
apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual;

#install
apt-get update;
apt-get install docker-engine;
service docker start;
docker info;

#Adjust memory and swap accounting

#reboot
#reboot;
