#!/usr/bin/env bash
# -*- coding: utf-8 -*-

set -e

echo " [+] Adding Kubernetes repo"
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://yum.kubernetes.io/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

echo " [+] Disabling SELinux enforcement"
[[ "$(getenforce)" != "Disabled" ]] && setenforce 0

echo " [+] Installing Kubernetes & Docker"
yum install -y docker kubelet kubeadm kubectl kubernetes-cni

echo " [+] Adding user 'vagrant' to Docker group"
usermod -a -G docker vagrant

echo " [+] Launching Kubelet and Docker"
systemctl enable docker && systemctl start docker
systemctl enable kubelet && systemctl start kubelet
