#!/bin/bash

NAME=jupyter
IMG=nvidia-tf2-cv2:latest
#IMG=nvcr.io/nvidia/tensorflow:20.01-tf2-py3

docker stop -t0 $NAME
mkdir -p /tmp/host
#docker run -d --gpus all --shm-size=1g --ulimit memlock=-1 --restart always -p 8888:8000 -v /tmp/host:/tmp/host --name $NAME $IMG
docker run -d --rm --gpus all --shm-size=1g --ulimit memlock=-1 -p 8888:8000 -v /tmp/host:/tmp/host --name $NAME $IMG
sleep 4
echo -n "User:"
read username
echo -n "Password: "
read -s password
echo
docker exec -u 0 $NAME bash -c "echo -e \"$password\n$password\" | passwd $username "
docker logs -f $NAME
