#!/bin/bash

docker build -t docker-dns-dhcp .
docker run -it --rm --net=host docker-dns-dhcp
