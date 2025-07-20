#!/usr/bin/env sh

set -ex

mkdir -p ./coverage
lcov -c -d ./src -o coverage/lcov.info.all
lcov -r coverage/lcov.info.all '*/include/*' '*/secrandom.h' -o coverage/lcov.info
genhtml -o coverage/html coverage/lcov.info
