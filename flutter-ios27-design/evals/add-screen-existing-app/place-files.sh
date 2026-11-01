#!/usr/bin/env bash
# The app as it stands, plus the skill's foundation files it was built with.
set -eu
here="$(dirname "$0")"
cp -R "$here/files/." .
mkdir -p lib/core
cp -R "$here/../../assets/core/." lib/core/
