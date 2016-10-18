#!/bin/bash

# remove all containers with the right label:
docker rm -f $(docker ps -a --no-trunc --filter "label=cluster=storm" | awk '{if(NR>1)print $1;}')