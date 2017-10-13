#!/bin/sh

container_name=test
repository=gene42/gene42-phenotips-core
tag=latest

sudo docker rm "$container_name" > /dev/null

sudo docker build -t ${repository}:${tag} .

to_remove=$(sudo docker images | grep -i "<none>" | awk '{print $3}')
if [ "$to_remove" ]; then
    sudo docker rmi ${to_remove}
fi

