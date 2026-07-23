#!/bin/sh
#
# Build the radicale image using podman and tag it as
# docker.io/xlrl/radicale:latest and docker.io/xlrl/radicale:<version>.

set -eu

cd "$(dirname "$0")"

version=$(sed -n 's/^version = "\(.*\)"/\1/p' pyproject.toml)

image=docker.io/xlrl/radicale

podman build \
    --tag "${image}:latest" \
    --tag "${image}:${version}" \
    .
