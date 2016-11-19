#!/usr/bin/env bash
# -*- coding: utf-8 -*-

set -e

echo " [+] Initializing Kubernetes master"
cluster_info="$(sudo kubeadm init)"

if [[ "$?" != "0" ]] ; then
    echo " [!] Something went wrong while initializing the Kube master"
    echo -e ${cluster_info}
    exit 1
fi

cluster_token="$(echo -e ${cluster_info} | tail -n 1 | awk '{print $4}')"
cluster_master="$(echo -e ${cluster_info} | tail -n 1 | awk '{print $5}')"

echo " [+] Cluster token is ${cluster_token}"
echo " [+] Cluster master is at ${cluster_master} -- is this me? ($(hostname -f))"
