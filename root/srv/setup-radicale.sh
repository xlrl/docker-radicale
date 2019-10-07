#!/bin/sh
set -e

echo "Setup: fix rights for radicale..."
chown radicale.radicale -R /var/radicale
echo "Setup: fix git settings..."
git config --global user.name radicale
git config --global user.email radicale@localhost
echo "Setup: Done"
