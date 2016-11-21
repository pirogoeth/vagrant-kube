#!/usr/bin/env bash
# -*- coding: utf-8 -*-

set -x

override=$(egrep "127.0.0.1\s+`hostname`" /etc/hosts)
( [[ ! -z "${override}" ]] && 
    sed -ie "/127.0.0.1\s\+`hostname`/d" /etc/hosts ) || true
