#!/usr/bin/env bash

APP_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
cd ${APP_DIR}

echo "installing local pip build"
python setup.py sdist
pip2 install --no-binary :all: dist/syncloud-owncloud-*.tar.gz