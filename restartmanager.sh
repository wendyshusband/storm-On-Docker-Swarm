#!/bin/bash

# restart the manager:
docker restart $(docker ps -a --no-trunc --filter "label=role=manager" | awk '{if(NR>1)print $1;}')