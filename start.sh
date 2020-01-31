#!/bin/bash

mkdir -p /tmp/host
docker run -d --gpus all --shm-size=1g --ulimit memlock=-1 --restart -p 8888:8888 -v /tmp/host:/tmp/host --name jupyter --restart always motbus3/jupyter-lab
docker logs -f motbus3/jupyterlab
