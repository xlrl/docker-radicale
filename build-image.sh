#!/bin/sh
#
# Build the multi-arch radicale image using podman and tag it as
# docker.io/xlrl/radicale:latest and docker.io/xlrl/radicale:<version>.
#
# Env:
#   PLATFORMS  comma separated target platforms
#              (default: linux/amd64,linux/arm64)
#
# Cross builds need qemu-user-static (apt-get install qemu-user-static).

set -eu

cd "$(dirname "$0")"

version=$(sed -n 's/^version = "\(.*\)"/\1/p' pyproject.toml)
platforms=${PLATFORMS:-linux/amd64,linux/arm64}

image=docker.io/xlrl/radicale
manifest="${image}:${version}"

# Start from a fresh manifest list
if podman manifest exists "${manifest}"; then
    podman manifest rm "${manifest}"
fi

podman build \
    --platform "${platforms}" \
    --manifest "${manifest}" \
    .

podman tag "${manifest}" "${image}:latest"
