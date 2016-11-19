#!/usr/bin/env bash
# -*- coding: utf-8 -*-

set -e

export GIMME_GO_VERSION=${GO_VERSION:-'1.7.3'}
export GOPATH=${GO_PATH:-"/var/go"}

[[ ! -d "${GOPATH}" ]] && mkdir -p /var/gopath

docker info 2>&1 1>/dev/null
if [[ "$?" != "0" ]] ; then
    echo " [!] Something is wrong with the Docker install -- does $USER have permission to access the Docker daemon?"
    docker info
    exit 1
fi

etcd_container="$(docker run -d -p 2380:2380 -p 4001:4001 -p 7001:7001 elcolio/etcd:latest)"
echo " [+] External etcd running on container: ${etcd_container}"

echo " [+] Installing etcdctl in Go environment"
eval "$(gimme)"
go get github.com/coreos/etcd/etcdctl
