# docker-radicale
The Radicale CalDAV/CardDAV server as a Docker image.

## Quickstart
Create the radicale data directory containing a minimal configuraion. We assume the directory _/srv/radicale_.

Minimal configuration _/srv/radicale/radicale.ini_:
```ini
[auth]
type = htpasswd
htpasswd_filename = /srv/radicale/users
# encryption method used in the htpasswd file
htpasswd_encryption = bcrypt

[server]
hosts = 0.0.0.0:8000

[storage]
filesystem_folder = /srv/radicale/collections
```

Run the docker image, and connect it to the HTTP port 80:
```shell
docker run  -v /srv/radicale:/var/radicale -p80:8000  -n radicale xlrl/radicale
```

Create some users:
```shell
# Create a new htpasswd file with the user "user1"
docker exec radicale htpasswd -B -c /var/radicale/users user1
New password:
Re-type new password:
# Add another user
docker exec radicale htpasswd -B -c /var/radicale/users user2
New password:
Re-type new password:
```

Now point your web browser to the address of the docker server. You should
be presented with the Radicale login.

## Configuration using docker-compose

__TODO__

## Version your changes using __GIT__
