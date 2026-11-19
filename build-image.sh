#!/bin/sh
#
# Build the multi-arch radicale image using podman and tag it as
# localhost/xlrl/radicale:latest and localhost/xlrl/radicale:<version>.
# Never pushes; prints the push commands.
#
# Env:
#   PLATFORMS  comma separated target platforms
#              (default: linux/amd64,linux/arm64)
#
# Cross builds need QEMU user emulation (apt-get install qemu-user-binfmt).

set -eu

cd "$(dirname "$0")"

version=$(cat VERSION)
platforms=${PLATFORMS:-linux/amd64,linux/arm64}

# Map a podman platform to its binfmt_misc qemu entry name
qemu_arch() {
    case "$1" in
        linux/amd64) echo x86_64 ;;
        linux/386) echo i386 ;;
        linux/arm64*) echo aarch64 ;;
        linux/arm/*) echo arm ;;
        linux/ppc64le) echo ppc64le ;;
        linux/s390x) echo s390x ;;
        linux/riscv64) echo riscv64 ;;
        *) echo unknown ;;
    esac
}

# Abort early if a foreign platform cannot be emulated
check_emulation() {
    native=$(uname -m)
    missing=0
    for platform in $(echo "$1" | tr ',' ' '); do
        arch=$(qemu_arch "${platform}")
        if [ "${arch}" = "${native}" ]; then
            continue
        fi
        if [ "${arch}" = unknown ]; then
            echo "warning: cannot check emulation for ${platform}" >&2
            continue
        fi
        entry=/proc/sys/fs/binfmt_misc/qemu-${arch}
        if [ ! -r "${entry}" ] || ! grep -qx enabled "${entry}"; then
            echo "error: no qemu-${arch} binfmt entry for ${platform}" >&2
            missing=1
            continue
        fi
        interpreter=$(sed -n 's/^interpreter //p' "${entry}")
        if [ ! -x "${interpreter}" ]; then
            echo "error: interpreter ${interpreter} for ${platform} not found" >&2
            missing=1
        elif ! grep -q '^flags:.*F' "${entry}"; then
            echo "warning: qemu-${arch} lacks the F flag, rootless builds may fail" >&2
        fi
    done
    if [ "${missing}" -ne 0 ]; then
        echo "Install QEMU user emulation: sudo apt-get install qemu-user-binfmt" >&2
        exit 1
    fi
}

check_emulation "${platforms}"

image=localhost/xlrl/radicale
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

echo "Built ${image}:${version} and :latest (${platforms})"
echo "Push with:"
echo "  podman manifest push --all ${image}:${version} docker://<registry>/xlrl/radicale:${version}"
echo "  podman manifest push --all ${image}:latest docker://<registry>/xlrl/radicale:latest"
