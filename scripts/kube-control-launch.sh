#!/usr/bin/env bash
# -*- coding: utf-8 -*-

set -e

outfile=`mktemp /tmp/kubeadm-XXXXXX`

echo " [+] Initializing Kubernetes master"
sudo kubeadm init 2>&1 1>${outfile}

if [[ "$?" != "0" ]] ; then
    echo " [!] Something went wrong while initializing the Kube master"
    echo -e ${cluster_info}
    exit 1
fi

cluster_creds="$(cat ${outfile} | tail -n 1)"
cluster_token="$(echo -e ${cluster_creds} | awk '{ split($3, a, "="); print a[2]; }')"
cluster_master="$(echo -e ${cluster_creds} | awk '{print $4}')"

echo " [+] Cluster token is ${cluster_token}"
echo " [+] Cluster master is at ${cluster_master} -- is this me? ($(hostname -f))"
