#!/usr/bin/env bash
# -*- coding: utf-8 -*-

set -e

export GIMME_GO_VERSION=${GO_VERSION:-'1.7.3'}

[[ ! -z "$(which curl)" ]] || yum install -y curl

sudo curl -sL -o /usr/bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme
sudo chmod +x /usr/bin/gimme

hash -r

echo "Pre-installing Go version ${GIMME_GO_VERSION}"
eval "$(gimme)"
