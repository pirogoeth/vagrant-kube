#!/usr/bin/env bash
# -*- coding: utf-8 -*-

set -e

docker info 2>&1 1>/dev/null
if [[ "$?" != "0" ]] ; then
    echo " [!] Something is wrong with the Docker install -- does $USER have permission to access the Docker daemon?"
    docker info
    exit 1
fi


