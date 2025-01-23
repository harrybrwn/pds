#!/usr/bin/env bash

set -euo pipefail

if [ -d ./pdsls ]; then
    pushd ./pdsls
    git pull
    popd
else
    git clone git@github.com:notjuliet/pdsls.git
fi

docker image build -t harrybrwn/pdsls:latest -f Dockerfile ./pdsls/
