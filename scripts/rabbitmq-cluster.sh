#!/bin/bash

RABBITMQ_CLUSTER_VERSION=1.2.1

docker pull ci-server:5000/rabbitmq-cluster:$RABBITMQ_CLUSTER_VERSION
docker run -d --rm \
    --network=host \
    --name $HOSTNAME \
    -e RABBITMQ_NODENAME=rabbit@192.168.100.10 \
    -e RABBITMQ_ERLANG_COOKIE=AMZTTRGUNVAGMJZSCZRZ \
    -e "RABBITMQ_CLUSTER_NODES=rabbit@192.168.100.10, rabbit@192.168.100.11"  \
    ci-server:5000/rabbitmq-cluster:$RABBITMQ_CLUSTER_VERSION
