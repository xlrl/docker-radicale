#!/usr/bin/python3
"""
Automatically update the Dockerfile to the latest base image
"""

from argparse import ArgumentParser
import json
import re
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
    names = {}
    log("Get latest Alpine Linux image tag...")
    for page in range(1, 20):
        url = f"https://hub.docker.com/v2/repositories/library/alpine/tags?page_size=100&page={page}"
        resp = requests.get(url, timeout=5000)

        if resp.status_code == 404:
            break  # seems as we don't have more pages

        assert resp.status_code == 200, f"Invalid status code {resp.status_code}"

        # print(resp.text)
        # with open("foo.json", "w") as file:
        #    file.write(resp.text)
        j = json.loads(resp.text)
        for result in j["results"]:
            name = result["name"]

            log(".")

            # print(name)

            tag_version = parse_tag_version(name)
            # print(tag_version)
            if tag_version is None:
                continue

            names[tag_version] = name

    latest_version = sorted(names.keys())[-1]
    latest_tag_name = names[latest_version]
    log(latest_tag_name)
    log(" ")

    m = re.search(r"FROM library/alpine:([^\s]+)", t)
    assert m is not None
    current_tag_name = m.group(1)
    current_version = parse_tag_version(current_tag_name)

    if current_version is None:
        pass
    elif latest_version < current_version:
        log(
            f"WARNING: current tag {current_tag_name} is newer than latest {latest_tag_name} "
        )

    t = t[: m.start(1)] + latest_tag_name + t[m.end(1) :]

    return t


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

    args = parser.parse_args()

    filepath = "Dockerfile"
    log(f"Patch {filepath}...")
    with open(filepath, "r", encoding="utf-8") as file:
        t = file.read()

    t_old = t

    if not args.keep_alpine_version:
        t = update_alpine(t)

    if t == t_old:
        logline("Unchanged")
    else:
        with open(filepath, "w", encoding="utf-8") as file:
            file.write(t)
        logline("Updated")


if __name__ == "__main__":
    main()
