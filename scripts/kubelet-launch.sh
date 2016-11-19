#!/usr/bin/env bash
# -*- coding: utf-8 -*-

set -e

etcdctl="/var/go/bin/etcdctl --no-sync"
etcd_endpoint="http://master.kube.dev:9301"

echo " [+] Fetching cluster information from etcd"
cluster_token=$(${etcdctl} --endpoint ${etcd_endpoint} get /cluster/token)
cluster_master=$(${etcdctl} --endpoint ${etcd_endpoint} get /cluster/ip)

if [[ -d "/etc/kubernetes" ]] ; then
    echo " [-] Clearing Kubernetes data"
    sudo kubeadm reset
    sudo rm -rf /etc/kubernetes
fi

echo " [+] Launching kubelet.service"
sudo systemctl start kubelet.service

echo " [+] Connection to cluster master! (addr: ${cluster_master}, token: ${cluster_token})"
sudo kubeadm join --token ${cluster_token} ${cluster_master}

exit 0
