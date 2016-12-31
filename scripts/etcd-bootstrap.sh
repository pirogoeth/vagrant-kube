#!/usr/bin/env bash
# -*- coding: utf-8 -*-

set -e

export GIMME_GO_VERSION=${GO_VERSION:-'1.7.3'}
export GOPATH=${GO_PATH:-'/var/go'}
export ETCD_CONTAINER=${ETCD_NAME:-'etcd_ext'}
export ROLE=${ETCD_ROLE:-'user'}

etcdctl="/var/go/bin/etcdctl --no-sync"
etcd_endpoint="http://master.kube.local:9301"

[[ ! -d "${GOPATH}" ]] && mkdir -p /var/gopath

echo " [+] Installing etcdctl in Go environment"
eval "$(gimme)"
go get github.com/coreos/etcd/etcdctl

if [[ "${ROLE}" == "master" ]] ; then
    docker info 2>&1 1>/dev/null
    if [[ "$?" != "0" ]] ; then
        echo " [!] Something is wrong with the Docker install -- does $USER have permission to access the Docker daemon?"
        docker info
        exit 1
    fi

    [[ -z "$(docker ps | grep ${ETCD_CONTAINER})" ]] && \
        etcd_container="$(docker run -d -p 9380:2380 -p 9301:4001 -p 9401:7001 elcolio/etcd:latest)" && \
        echo " [+] External etcd running on container: ${etcd_container}"

    echo " [+] Registering etcd container info on etcd"
    ${etcdctl} --endpoint ${etcd_endpoint} mkdir /self
    ${etcdctl} --endpoint ${etcd_endpoint} set /self/container ${etcd_container:-${ETCD_CONTAINER}}
fi
