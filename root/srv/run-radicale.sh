#!/bin/sh
set -e

# Clone Git repository if enabled
if [ -n "$GIT_REPOSITORY" ] && [ -n "$GIT_USERNAME" ] && [ -n "$GIT_EMAIL" ]; then
    echo "Setup: git configs enabled"
    git clone "$GIT_REPOSITORY" /var/radicale/collections
    git config --global user.name "$GIT_USERNAME"
    git config --global user.email "$GIT_EMAIL"
fi

echo "Setup: start radicale setup"
chown radicale:radicale -R /var/radicale

# Check if they are user to create 
if [ -n "$RADICALE_USER" ] && [ -n "$RADICALE_PASS" ]; then
    if [ -e /var/radicale/users ]; then
        echo "Setup: skip adding $RADICALE_USER, password file exists"
    else
        echo "Setup: add user $RADICALE_USER"
        htpasswd -B -b -c /var/radicale/users "$RADICALE_USER" "$RADICALE_PASS"
    fi 
fi

echo "Setup: done"
echo "Run radicale"

cd /var/radicale
python3 -m radicale --config=/var/radicale/config.ini
