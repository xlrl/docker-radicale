#!/usr/bin/python3
"""
Automatically update the Dockerfile to the latest base image
"""

from argparse import ArgumentParser
import re
import subprocess
import requests


def log(msg):
    """
    Log text without newline
    """
    print(msg, flush=True, end="")


def logline(msg):
    """
    Log some tex with newline
    """
    print(msg, flush=True)


def parse_tag_version(tag_name: str) -> tuple:
    """
    Parse the tag string and return it is tuple of major, minor, micro
    """
    r = re.compile("^([0-9]+)[.]([0-9]+)[.]([0-9]+)$")

    m = r.match(tag_name)
    if m is None:
        return None

    major = int(m.group(1))
    minor = int(m.group(2))
    patch = int(m.group(3))

    return (major, minor, patch)


def update_alpine(t: str) -> str:
    """
    Find the latest Alpine Linux tag and update the Dockerfile.
    """
    log("Get latest Alpine Linux image tag...")
    latest_version: tuple[int, int, int] | None = None
    latest_tag_name = ""

    url: str | None = "https://hub.docker.com/v2/repositories/library/alpine/tags?page_size=100"
    while url:
        resp = requests.get(url, timeout=30)
        resp.raise_for_status()
        data = resp.json()

        for result in data["results"]:
            log(".")
            version = parse_tag_version(result["name"])
            if version is not None and (latest_version is None or version > latest_version):
                latest_version = version
                latest_tag_name = result["name"]

        url = data.get("next")

    assert latest_tag_name, "No semver tag found in Alpine tags response"
    log(f"{latest_tag_name} ")

    m = re.search(r"FROM [^\s]*alpine:([^\s]+)", t)
    assert m is not None
    current_tag_name = m.group(1)
    current_version = parse_tag_version(current_tag_name)

    if current_version is not None and latest_version is not None and latest_version < current_version:
        log(
            f"WARNING: current tag {current_tag_name} is newer than latest {latest_tag_name} "
        )

    t = t[: m.start(1)] + latest_tag_name + t[m.end(1) :]

    return t


def update_radicale(t: str) -> str:
    """
    Find the latest Radicale tag on GitHub and update the pyproject.toml.
    """
    log("Get latest Radicale tag...")
    latest_version: tuple[int, int, int] | None = None
    latest_tag_name = ""

    url: str | None = "https://api.github.com/repos/Kozea/Radicale/tags?per_page=100"
    while url:
        resp = requests.get(
            url, timeout=30, headers={"Accept": "application/vnd.github+json"}
        )
        resp.raise_for_status()
        data = resp.json()

        for result in data:
            log(".")
            tag_name = result["name"]
            version = parse_tag_version(
                tag_name[1:] if tag_name.startswith("v") else tag_name
            )
            if version is not None and (latest_version is None or version > latest_version):
                latest_version = version
                latest_tag_name = tag_name

        url = resp.links.get("next", {}).get("url")

    assert latest_tag_name, "No semver tag found in Radicale tags response"
    latest_version_str = latest_tag_name.lstrip("v")
    log(f"{latest_tag_name} ")

    m = re.search(r'"radicale==([^"]+)"', t)
    assert m is not None
    current_tag_name = m.group(1)
    current_version = parse_tag_version(current_tag_name)

    if current_version is not None and latest_version is not None and latest_version < current_version:
        log(
            f"WARNING: current tag {current_tag_name} is newer than latest {latest_version_str} "
        )

    t = t[: m.start(1)] + latest_version_str + t[m.end(1) :]

    return t


def patch_file(filepath: str, skip: bool, update_func) -> bool:
    """
    Read filepath, run update_func over its contents unless skip is set, and
    write the result back if it changed. Returns whether it changed.
    """
    log(f"Patch {filepath}...")
    with open(filepath, "r", encoding="utf-8") as file:
        t = file.read()

    t_old = t

    if not skip:
        t = update_func(t)

    changed = t != t_old

    if changed:
        with open(filepath, "w", encoding="utf-8") as file:
            file.write(t)
        logline("Updated")
    else:
        logline("Unchanged")

    return changed


def update_own_version(filepath: str, new_version: str) -> None:
    """
    Set the package version in filepath to new_version.
    """
    log(f"Patch {filepath}...")
    with open(filepath, "r", encoding="utf-8") as file:
        t = file.read()

    m = re.search(r'(?m)^version = "([^"]+)"', t)
    assert m is not None

    if m.group(1) == new_version:
        logline("Unchanged")
        return

    t = t[: m.start(1)] + new_version + t[m.end(1) :]

    with open(filepath, "w", encoding="utf-8") as file:
        file.write(t)
    logline("Updated")


def run_uv_lock(cwd: str) -> None:
    """
    Run "uv lock" in cwd to refresh its uv.lock file.
    """
    log(f"Run uv lock in {cwd}...")
    subprocess.run(["uv", "lock"], cwd=cwd, check=True, capture_output=True)
    logline("Done")


def main():
    """
    Well, main.
    """
    parser = ArgumentParser()
    parser.add_argument(
        "--keep-alpine-version",
        action="store_true",
        default=False,
        help="Do not try to find the latest Alpine Linux version",
    )
    parser.add_argument(
        "--keep-radicale-version",
        action="store_true",
        default=False,
        help="Do not try to find the latest Radicale version",
    )

    args = parser.parse_args()

    patch_file("Dockerfile", args.keep_alpine_version, update_alpine)

    radicale_changed = patch_file(
        "root/srv/pyproject.toml", args.keep_radicale_version, update_radicale
    )
    if radicale_changed:
        with open("root/srv/pyproject.toml", "r", encoding="utf-8") as file:
            t = file.read()
        m = re.search(r'"radicale==([^"]+)"', t)
        assert m is not None
        new_version = m.group(1)
        update_own_version("pyproject.toml", new_version)
        update_own_version("root/srv/pyproject.toml", new_version)

        run_uv_lock("root/srv")
        run_uv_lock(".")


if __name__ == "__main__":
    main()
