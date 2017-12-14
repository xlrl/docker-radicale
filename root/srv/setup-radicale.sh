#!/bin/sh
set -e

echo "Setup: fix rights for radicale..."
chown radicale.radicale -R /var/radicale
echo "Setup: Done"
